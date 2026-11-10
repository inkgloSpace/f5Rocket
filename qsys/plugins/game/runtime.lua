local rapidjson = require("rapidjson")

local DIAGNOSTIC_MODE_CHOICES = { "TIMER ONLY", "MINIMAL RENDER", "FULL GAME" }
local DIAGNOSTIC_MODE_VALUES = {
  ["TIMER ONLY"] = true,
  ["MINIMAL RENDER"] = true,
  ["FULL GAME"] = true
}

local gameState = CreateGameState()
local activeDiagnosticMode = "FULL GAME"
local measurementTicks = 0
local measurementStartedAt = 0
local timerTickCount = 0
local lastRawBytes = 0
local lastEncodedBytes = 0
local lastTickStage = "IDLE"
local minimalMotionX = 0
local minimalMotionDirection = 1

local MINIMAL_MOTION_MIN = 0
local MINIMAL_MOTION_MAX = GAME_CONFIG.LogicalWidth - GAME_CONFIG.PlayerWidth
local MINIMAL_MOTION_STEP = GAME_CONFIG.PlayerSpeed

GameLegend = {
  DrawChrome = false,
  IconData = ""
}

-- Keep the single timer globally scoped so Q-SYS Lua GC cannot remove it.
GameTimer = Timer.New()

local function UpdateStatus(text)
  Controls.Status.String = text
end

local function SelectedDiagnosticMode()
  local selected = Controls.DiagnosticMode.String
  if DIAGNOSTIC_MODE_VALUES[selected] == nil then
    selected = "FULL GAME"
    Controls.DiagnosticMode.String = selected
  end
  return selected
end

local function RunningStatus()
  if activeDiagnosticMode == "FULL GAME" and gameState.paused then
    return "PAUSED / FULL GAME"
  end
  return "RUNNING / " .. activeDiagnosticMode
end

local function ResetMinimalMotion()
  minimalMotionX = MINIMAL_MOTION_MIN
  minimalMotionDirection = 1
end

local function UpdateMinimalMotion()
  minimalMotionX = minimalMotionX + minimalMotionDirection * MINIMAL_MOTION_STEP

  if minimalMotionX >= MINIMAL_MOTION_MAX then
    minimalMotionX = MINIMAL_MOTION_MAX
    minimalMotionDirection = -1
  elseif minimalMotionX <= MINIMAL_MOTION_MIN then
    minimalMotionX = MINIMAL_MOTION_MIN
    minimalMotionDirection = 1
  end
end

local function AssignSvgToViewportUnsafe(svg)
  lastRawBytes = #svg
  if lastRawBytes > GAME_CONFIG.MaxRawSvgBytes then
    lastTickStage = "PAYLOAD"
    error(
      "SVG " .. tostring(lastRawBytes) .. " B > " ..
      tostring(GAME_CONFIG.MaxRawSvgBytes) .. " B",
      0
    )
  end

  lastTickStage = "BASE64"
  local encodedSvg = Crypto.Base64Encode(svg)
  lastEncodedBytes = #encodedSvg

  lastTickStage = "LEGEND"
  GameLegend.IconData = encodedSvg
  Controls.Viewport.Legend = rapidjson.encode(GameLegend)
end

local function RenderSelectedFrameUnsafe()
  lastTickStage = "SVG"
  local svg
  if activeDiagnosticMode == "TIMER ONLY" then
    svg = BuildTimerOnlySvg()
  elseif activeDiagnosticMode == "MINIMAL RENDER" then
    svg = BuildMinimalDiagnosticSvg(minimalMotionX)
  else
    svg = BuildGameSvg(gameState)
  end
  AssignSvgToViewportUnsafe(svg)
end

local function UpdateTelemetryControlsUnsafe()
  lastTickStage = "TELEMETRY"
  Controls.SvgBytes.String = tostring(lastRawBytes)
  Controls.SvgBase64Bytes.String = tostring(lastEncodedBytes)

  if activeDiagnosticMode == "FULL GAME" then
    Controls.ActiveEnemies.String = tostring(CountActiveEnemies(gameState))
    Controls.ActivePlayerBullets.String = tostring(CountActivePlayerBullets(gameState))
  else
    Controls.ActiveEnemies.String = "0"
    Controls.ActivePlayerBullets.String = "0"
  end
end

local function ResetMeasurement()
  measurementTicks = 0
  measurementStartedAt = Timer.Now()
  Controls.MeasuredHz.String = "MEASURING"
end

local function CompleteTickTelemetryUnsafe()
  timerTickCount = timerTickCount + 1
  measurementTicks = measurementTicks + 1

  local now = Timer.Now()
  local elapsed = now - measurementStartedAt
  if elapsed >= 1 then
    lastTickStage = "TELEMETRY"
    Controls.MeasuredHz.String = string.format("%.1f Hz", measurementTicks / elapsed)
    UpdateTelemetryControlsUnsafe()
    measurementTicks = 0
    measurementStartedAt = now
  end

  lastTickStage = "DONE"
end

local function HandleRuntimeError(errorMessage)
  GameTimer:Stop()
  gameState.running = false
  gameState.paused = false
  Controls.Pause.Boolean = false

  local message = "ERROR @ " .. tostring(lastTickStage) .. ": " .. tostring(errorMessage)
  UpdateStatus(message)
  print("[f5Rocket] Tick error @ " .. tostring(lastTickStage) .. ": " .. tostring(errorMessage))
end

local function RenderImmediateProtected()
  local success, errorMessage = pcall(function()
    RenderSelectedFrameUnsafe()
    UpdateTelemetryControlsUnsafe()
    lastTickStage = "DONE"
  end)

  if not success then
    HandleRuntimeError(errorMessage)
    return false
  end
  return true
end

local function UpdateFullGameStateUnsafe()
  lastTickStage = "INPUT"
  local leftPressed = Controls.Left.Boolean
  local rightPressed = Controls.Right.Boolean
  local upPressed = Controls.Up.Boolean
  local downPressed = Controls.Down.Boolean
  local firePressed = Controls.Fire.Boolean

  if not gameState.running or gameState.paused then
    return
  end

  lastTickStage = "PLAYER"
  UpdatePlayer(
    gameState,
    leftPressed,
    rightPressed,
    upPressed,
    downPressed
  )
  if firePressed then
    FirePlayerBullet(gameState)
  end

  lastTickStage = "BULLETS"
  UpdatePlayerBullets(gameState)

  lastTickStage = "ENEMIES"
  UpdateEnemies(gameState)

  lastTickStage = "COLLISION"
  CheckPlayerBulletEnemyCollisions(gameState)

  lastTickStage = "BACKGROUND"
  gameState.backgroundOffset = (
    gameState.backgroundOffset + GAME_CONFIG.BackgroundScrollPerTick
  ) % GAME_CONFIG.LogicalHeight
  gameState.ticks = gameState.ticks + 1
  gameState.time = gameState.ticks * GAME_CONFIG.UpdateInterval
end

local function GameTickUnsafe()
  if activeDiagnosticMode == "TIMER ONLY" then
    lastTickStage = "INPUT"
    -- Deliberately no game update and no per-tick Viewport.Legend assignment.
  elseif activeDiagnosticMode == "MINIMAL RENDER" then
    lastTickStage = "PLAYER"
    UpdateMinimalMotion()
    RenderSelectedFrameUnsafe()
  else
    UpdateFullGameStateUnsafe()
    RenderSelectedFrameUnsafe()
  end

  CompleteTickTelemetryUnsafe()
end

local function StartGame()
  GameTimer:Stop()
  ResetGameState(gameState)
  ResetEnemies(gameState)
  ResetMinimalMotion()
  timerTickCount = 0
  gameState.running = true
  gameState.paused = false
  Controls.Pause.Boolean = false
  activeDiagnosticMode = SelectedDiagnosticMode()
  ResetMeasurement()

  if RenderImmediateProtected() then
    print(string.format(
      "[f5Rocket] Start payload / %s: gameplay definitions %d B, deferred background definitions %d B, SVG %d B, Base64 %d B, guard %d B",
      activeDiagnosticMode,
      GameplayAssetDefinitionBytes(),
      LargeBackgroundAssetDefinitionBytes(),
      lastRawBytes,
      lastEncodedBytes,
      GAME_CONFIG.MaxRawSvgBytes
    ))
    UpdateStatus(RunningStatus())
    GameTimer:Start(GAME_CONFIG.UpdateInterval)
  end
end

local function ApplyDiagnosticModeChange()
  local wasRunning = gameState.running
  GameTimer:Stop()
  activeDiagnosticMode = SelectedDiagnosticMode()
  gameState.paused = false
  Controls.Pause.Boolean = false
  ResetMinimalMotion()
  timerTickCount = 0
  ResetMeasurement()

  if RenderImmediateProtected() then
    if wasRunning then
      UpdateStatus(RunningStatus())
      GameTimer:Start(GAME_CONFIG.UpdateInterval)
    else
      Controls.MeasuredHz.String = "0.0 Hz"
      UpdateStatus("READY / " .. activeDiagnosticMode)
    end
  end
end

GameTimer.EventHandler = function()
  local success, errorMessage = pcall(GameTickUnsafe)
  if not success then
    HandleRuntimeError(errorMessage)
  end
end

Controls.Start.EventHandler = function(control)
  if control.Boolean then
    StartGame()
  end
end

Controls.Pause.EventHandler = function(control)
  if not gameState.running or activeDiagnosticMode ~= "FULL GAME" then
    control.Boolean = false
    return
  end

  gameState.paused = control.Boolean
  UpdateStatus(RunningStatus())
  RenderImmediateProtected()
end

Controls.DiagnosticMode.EventHandler = function()
  ApplyDiagnosticModeChange()
end

Controls.DiagnosticMode.Choices = DIAGNOSTIC_MODE_CHOICES
activeDiagnosticMode = SelectedDiagnosticMode()
ResetGameState(gameState)
ResetEnemies(gameState)
ResetMinimalMotion()
Controls.Pause.Boolean = false
Controls.MeasuredHz.String = "0.0 Hz"
UpdateStatus("READY / " .. AssetAvailabilitySummary())

local missingAssets = MissingAssetList()
if missingAssets ~= "" then
  print("[f5Rocket] Missing PNG assets; definition-based SVG fallbacks active: " .. missingAssets)
end

RenderImmediateProtected()

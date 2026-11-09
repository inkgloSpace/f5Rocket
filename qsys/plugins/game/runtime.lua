local rapidjson = require("rapidjson")

local gameState = CreateGameState()
local measurementTicks = 0
local measurementStartedAt = 0

GameLegend = {
  DrawChrome = false,
  IconData = ""
}

-- Keep the timer globally scoped so Q-SYS Lua garbage collection cannot remove it.
GameTimer = Timer.New()

local function UpdateStatus(text)
  Controls.Status.String = text
end

local function RenderGameFrameUnsafe()
  local svg = BuildGameSvg(gameState)
  local encodedSvg = Crypto.Base64Encode(svg)

  GameLegend.IconData = encodedSvg
  Controls.Viewport.Legend = rapidjson.encode(GameLegend)

  return #svg, #encodedSvg
end

local function RenderGameFrame()
  local success, rawBytes, encodedBytes = pcall(RenderGameFrameUnsafe)
  if not success then
    GameTimer:Stop()
    gameState.running = false
    Controls.Pause.Boolean = false
    UpdateStatus("ERROR: " .. tostring(rawBytes))
    print("[f5Rocket] Render error: " .. tostring(rawBytes))
    return false
  end

  Controls.SvgBytes.String = tostring(rawBytes)
  Controls.SvgBase64Bytes.String = tostring(encodedBytes)
  Controls.ActiveEnemies.String = tostring(CountActiveEnemies(gameState))
  Controls.ActivePlayerBullets.String = tostring(CountActivePlayerBullets(gameState))
  return true
end

local function ResetMeasurement()
  measurementTicks = 0
  measurementStartedAt = Timer.Now()
  Controls.MeasuredHz.String = "MEASURING"
end

local function UpdateMeasurement()
  measurementTicks = measurementTicks + 1
  local now = Timer.Now()
  local elapsed = now - measurementStartedAt
  if elapsed >= 1 then
    Controls.MeasuredHz.String = string.format("%.1f Hz", measurementTicks / elapsed)
    measurementTicks = 0
    measurementStartedAt = now
  end
end

local function StartGame()
  GameTimer:Stop()
  ResetGameState(gameState)
  ResetEnemies(gameState)
  gameState.running = true
  gameState.paused = false
  Controls.Pause.Boolean = false
  ResetMeasurement()

  if RenderGameFrame() then
    UpdateStatus("RUNNING")
    GameTimer:Start(GAME_CONFIG.UpdateInterval)
  end
end

local function UpdateGameState()
  if not gameState.running or gameState.paused then
    return
  end

  UpdatePlayer(
    gameState,
    Controls.Left.Boolean,
    Controls.Right.Boolean,
    Controls.Up.Boolean,
    Controls.Down.Boolean
  )

  if Controls.Fire.Boolean then
    FirePlayerBullet(gameState)
  end

  UpdatePlayerBullets(gameState)
  UpdateEnemies(gameState)
  CheckPlayerBulletEnemyCollisions(gameState)

  gameState.backgroundOffset = (
    gameState.backgroundOffset + GAME_CONFIG.BackgroundScrollPerTick
  ) % GAME_CONFIG.LogicalHeight
  gameState.ticks = gameState.ticks + 1
  gameState.time = gameState.ticks * GAME_CONFIG.UpdateInterval
end

GameTimer.EventHandler = function()
  UpdateGameState()
  if RenderGameFrame() then
    UpdateMeasurement()
  end
end

Controls.Start.EventHandler = function(control)
  if control.Boolean then
    StartGame()
  end
end

Controls.Pause.EventHandler = function(control)
  if not gameState.running then
    control.Boolean = false
    return
  end

  gameState.paused = control.Boolean
  if gameState.paused then
    UpdateStatus("PAUSED")
  else
    UpdateStatus("RUNNING")
  end
  RenderGameFrame()
end

ResetGameState(gameState)
ResetEnemies(gameState)
Controls.Pause.Boolean = false
Controls.MeasuredHz.String = "0.0 Hz"
UpdateStatus("READY / " .. AssetAvailabilitySummary())

local missingAssets = MissingAssetList()
if missingAssets ~= "" then
  print("[f5Rocket] Missing PNG assets; SVG fallbacks active: " .. missingAssets)
end

RenderGameFrame()

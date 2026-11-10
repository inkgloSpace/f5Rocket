local rapidjson = require("rapidjson")

local gameState = CreateGameState()
local tickCount = 0
local measurementTicks = 0
local measurementStartedAt = 0
local lastRawBytes = 0
local lastEncodedBytes = 0

GameLegend = {
  DrawChrome = false,
  IconData = ""
}

BackgroundLegend = {
  DrawChrome = false,
  IconData = ""
}

-- Keep the single timer globally scoped so Q-SYS Lua GC cannot remove it.
GameTimer = Timer.New()

local function AssignStageBackground(stageIndex)
  local svg, assetId = BuildStageBackgroundSvg(stageIndex)
  local encodedSvg = Crypto.Base64Encode(svg)
  BackgroundLegend.IconData = encodedSvg
  Controls.BackgroundViewport.Legend = rapidjson.encode(BackgroundLegend)
  print(
    "[f5Rocket] Background changed: " .. STAGE_PROFILES[stageIndex].Name ..
    " / " .. assetId .. " / " .. tostring(#svg) .. " B raw / " ..
    tostring(#encodedSvg) .. " B Base64"
  )
end

local function RenderGameFrame()
  local svg = BuildGameSvg(gameState)
  lastRawBytes = #svg

  if lastRawBytes > GAME_CONFIG.MaxRawSvgBytes then
    error(
      "SVG " .. tostring(lastRawBytes) .. " B > " ..
      tostring(GAME_CONFIG.MaxRawSvgBytes) .. " B",
      0
    )
  end

  local encodedSvg = Crypto.Base64Encode(svg)
  lastEncodedBytes = #encodedSvg
  GameLegend.IconData = encodedSvg
  Controls.Viewport.Legend = rapidjson.encode(GameLegend)
end

local function UpdateSceneTelemetry()
  Controls.SvgBytes.String = tostring(lastRawBytes)
  Controls.SvgBase64Bytes.String = tostring(lastEncodedBytes)
  Controls.ActiveEnemies.String = tostring(CountActiveEnemies(gameState))
  Controls.ActivePlayerBullets.String = tostring(CountActivePlayerBullets(gameState))
end

local function ResetMeasurement()
  measurementTicks = 0
  measurementStartedAt = Timer.Now()
  Controls.MeasuredHz.String = "MEASURING"
end

-- Mobile diagonals and the original physical/pin controls feed the same
-- booleans. Returning scalars avoids allocating an input table every tick.
local function ReadGameInput()
  local up = Controls.Up.Boolean or
    Controls.UpLeft.Boolean or Controls.UpRight.Boolean
  local down = Controls.Down.Boolean or
    Controls.DownLeft.Boolean or Controls.DownRight.Boolean
  local left = Controls.Left.Boolean or
    Controls.UpLeft.Boolean or Controls.DownLeft.Boolean
  local right = Controls.Right.Boolean or
    Controls.UpRight.Boolean or Controls.DownRight.Boolean
  local fire = Controls.Fire.Boolean or Controls.AutoFire.Boolean

  return up, down, left, right, fire
end

local function UpdateGameState()
  if not gameState.running or gameState.paused then
    return
  end

  UpdateParallax(gameState)

  if gameState.gameOver then
    AdvanceGameOverAnimation(gameState)
    return
  end

  if gameState.stagePhase == "CLEAR" then
    UpdateExplosions(gameState)
    local nextStage = AdvanceStageClear(gameState)
    if nextStage ~= nil then
      ResetEnemies(gameState)
      ResetParallax(gameState, nextStage)
      AssignStageBackground(nextStage)
    end
    return
  end

  local upPressed, downPressed, leftPressed, rightPressed, firePressed =
    ReadGameInput()

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

  UpdatePlayerBullets(gameState)
  if gameState.stagePhase == "WAVE" then
    UpdateEnemies(gameState)
    UpdateEnemyFire(gameState)
  elseif gameState.stagePhase == "BOSS" then
    UpdateBoss(gameState)
  end
  UpdateEnemyBullets(gameState)

  if gameState.stagePhase == "WAVE" then
    CheckPlayerBulletEnemyCollisions(gameState)
  elseif gameState.stagePhase == "BOSS" then
    CheckPlayerBulletBossCollisions(gameState)
  end
  CheckEnemyBulletPlayerCollisions(gameState)
  if gameState.stagePhase == "WAVE" then
    CheckEnemyPlayerCollisions(gameState)
  elseif gameState.stagePhase == "BOSS" then
    CheckBossPlayerCollision(gameState)
  end

  if gameState.gameOver then
    AdvanceGameOverAnimation(gameState)
    return
  end


  if gameState.stagePhase == "WAVE" and StageThresholdReached(gameState) then
    BeginBossPhase(gameState)
    SpawnBoss(gameState)
  elseif gameState.stagePhase == "CLEAR" then
    UpdateExplosions(gameState)
    return
  end

  UpdateExplosions(gameState)
  gameState.ticks = gameState.ticks + 1
  gameState.time = gameState.ticks * GAME_CONFIG.UpdateInterval
end

local function StartGame()
  GameTimer:Stop()
  Controls.Pause.Boolean = false
  ResetGameState(gameState)
  EnterStage(gameState, 1)
  ResetEnemies(gameState)
  ResetParallax(gameState, 1)
  gameState.running = true
  gameState.paused = false
  tickCount = 0
  ResetMeasurement()
  AssignStageBackground(1)
  RenderGameFrame()
  UpdateSceneTelemetry()
  Controls.Status.String = "RUNNING"
  GameTimer:Start(GAME_CONFIG.UpdateInterval)
end

local function StopGame()
  GameTimer:Stop()
  gameState.running = false
  gameState.paused = false
  Controls.Pause.Boolean = false
  Controls.Status.String = "STOPPED"
end

local function PauseGame()
  if not gameState.running or gameState.gameOver or gameState.gameClear then
    Controls.Pause.Boolean = false
    return
  end

  GameTimer:Stop()
  gameState.paused = true
  RenderGameFrame()
  UpdateSceneTelemetry()
  Controls.MeasuredHz.String = "PAUSED"
  Controls.Status.String = "PAUSED"
end

local function ResumeGame()
  if not gameState.running then
    Controls.Pause.Boolean = false
    return
  end

  gameState.paused = false
  ResetMeasurement()
  RenderGameFrame()
  UpdateSceneTelemetry()
  Controls.Status.String = "RUNNING"
  GameTimer:Start(GAME_CONFIG.UpdateInterval)
end

GameTimer.EventHandler = function()
  UpdateGameState()
  RenderGameFrame()

  tickCount = tickCount + 1
  measurementTicks = measurementTicks + 1

  local now = Timer.Now()
  local elapsed = now - measurementStartedAt
  if elapsed >= 1 then
    Controls.MeasuredHz.String = string.format("%.1f Hz", measurementTicks / elapsed)
    UpdateSceneTelemetry()
    measurementTicks = 0
    measurementStartedAt = now
  end
end

Controls.Run.EventHandler = function(control)
  if control.Boolean then
    StartGame()
  else
    StopGame()
  end
end

Controls.Pause.EventHandler = function(control)
  if not Controls.Run.Boolean or gameState.gameOver or gameState.gameClear then
    control.Boolean = false
    return
  end

  if control.Boolean then
    PauseGame()
  else
    ResumeGame()
  end
end

ResetGameState(gameState)
EnterStage(gameState, 1)
ResetEnemies(gameState)
ResetParallax(gameState, 1)
GameTimer:Stop()
Controls.Run.Boolean = false
Controls.Pause.Boolean = false
Controls.MeasuredHz.String = "0.0 Hz"
AssignStageBackground(1)
RenderGameFrame()
UpdateSceneTelemetry()
Controls.Status.String = "READY"

local missingAssets = MissingAssetList()
if missingAssets ~= "" then
  print("[f5Rocket] Missing PNG assets; definition-based SVG fallbacks active: " .. missingAssets)
end

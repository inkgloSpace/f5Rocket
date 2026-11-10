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

-- Keep the single timer globally scoped so Q-SYS Lua GC cannot remove it.
GameTimer = Timer.New()

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
  tickCount = 0
  measurementTicks = 0
  measurementStartedAt = Timer.Now()
  Controls.MeasuredHz.String = "MEASURING"
end

local function UpdateGameState()
  if not gameState.running then
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

local function StartGame()
  GameTimer:Stop()
  ResetGameState(gameState)
  ResetEnemies(gameState)
  gameState.running = true
  ResetMeasurement()
  RenderGameFrame()
  UpdateSceneTelemetry()
  Controls.Status.String = "RUNNING"
  GameTimer:Start(GAME_CONFIG.UpdateInterval)
end

local function StopGame()
  GameTimer:Stop()
  gameState.running = false
  Controls.Status.String = "STOPPED"
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

ResetGameState(gameState)
ResetEnemies(gameState)
GameTimer:Stop()
Controls.Run.Boolean = false
Controls.MeasuredHz.String = "0.0 Hz"
RenderGameFrame()
UpdateSceneTelemetry()
Controls.Status.String = "READY"

local missingAssets = MissingAssetList()
if missingAssets ~= "" then
  print("[f5Rocket] Missing PNG assets; definition-based SVG fallbacks active: " .. missingAssets)
end

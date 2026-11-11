local rapidjson = require("rapidjson")

local gameState = CreateGameState()
local backgroundRenderCounter = 0
local recentHorizontalIntent = 0
local recentHorizontalTicks = 0
local recentVerticalIntent = 0
local recentVerticalTicks = 0
local syntheticHorizontalIntent = 0
local syntheticHorizontalHold = 0
local syntheticVerticalIntent = 0
local syntheticVerticalHold = 0

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

local function RenderBackgroundFrame()
  local svg = BuildStageBackgroundSvg(
    gameState.stageIndex,
    gameState.backgroundScrollY
  )
  local rawBytes = #svg

  if rawBytes > GAME_CONFIG.MaxRawBackgroundSvgBytes then
    error(
      "Background SVG " .. tostring(rawBytes) .. " B > " ..
      tostring(GAME_CONFIG.MaxRawBackgroundSvgBytes) .. " B",
      0
    )
  end

  local encodedSvg = Crypto.Base64Encode(svg)
  BackgroundLegend.IconData = encodedSvg
  Controls.BackgroundViewport.Legend = rapidjson.encode(BackgroundLegend)
end

local function RenderGameFrame()
  local svg = BuildGameSvg(gameState)
  local rawBytes = #svg

  if rawBytes > GAME_CONFIG.MaxRawSvgBytes then
    error(
      "SVG " .. tostring(rawBytes) .. " B > " ..
      tostring(GAME_CONFIG.MaxRawSvgBytes) .. " B",
      0
    )
  end

  GameLegend.IconData = Crypto.Base64Encode(svg)
  Controls.Viewport.Legend = rapidjson.encode(GameLegend)
end

local function ResetCardinalChordAssist()
  recentHorizontalIntent = 0
  recentHorizontalTicks = 0
  recentVerticalIntent = 0
  recentVerticalTicks = 0
  syntheticHorizontalIntent = 0
  syntheticHorizontalHold = 0
  syntheticVerticalIntent = 0
  syntheticVerticalHold = 0
end

-- Mobile diagonals and the original physical/pin controls feed the same
-- booleans. Returning scalars avoids allocating an input table every tick.
local function ReadGameInput()
  local rawUp = Controls.Up.Boolean
  local rawDown = Controls.Down.Boolean
  local rawLeft = Controls.Left.Boolean
  local rawRight = Controls.Right.Boolean
  local diagonalUp = Controls.UpLeft.Boolean or Controls.UpRight.Boolean
  local diagonalDown = Controls.DownLeft.Boolean or Controls.DownRight.Boolean
  local diagonalLeft = Controls.UpLeft.Boolean or Controls.DownLeft.Boolean
  local diagonalRight = Controls.UpRight.Boolean or Controls.DownRight.Boolean
  local explicitDiagonal = diagonalUp or diagonalDown

  local horizontalIntent = 0
  if rawLeft then
    horizontalIntent = horizontalIntent - 1
  end
  if rawRight then
    horizontalIntent = horizontalIntent + 1
  end

  local verticalIntent = 0
  if rawUp then
    verticalIntent = verticalIntent - 1
  end
  if rawDown then
    verticalIntent = verticalIntent + 1
  end

  local anyHorizontal = rawLeft or rawRight
  local anyVertical = rawUp or rawDown

  if explicitDiagonal then
    ResetCardinalChordAssist()
  else
    -- A synthetic axis is valid only while the second, real axis remains
    -- held. Any real input on the synthetic axis replaces the latch.
    if syntheticHorizontalIntent ~= 0 and
        (verticalIntent ~= syntheticHorizontalHold or anyHorizontal) then
      syntheticHorizontalIntent = 0
      syntheticHorizontalHold = 0
    end
    if syntheticVerticalIntent ~= 0 and
        (horizontalIntent ~= syntheticVerticalHold or anyVertical) then
      syntheticVerticalIntent = 0
      syntheticVerticalHold = 0
    end

    -- Detect a cardinal slide only when the current axis is unambiguous and
    -- the orthogonal axis has fully released. True simultaneous inputs skip
    -- this path and resolve directly below.
    if syntheticHorizontalIntent == 0 and not anyHorizontal and
        verticalIntent ~= 0 and recentHorizontalTicks > 0 then
      syntheticHorizontalIntent = recentHorizontalIntent
      syntheticHorizontalHold = verticalIntent
    end
    if syntheticVerticalIntent == 0 and not anyVertical and
        horizontalIntent ~= 0 and recentVerticalTicks > 0 then
      syntheticVerticalIntent = recentVerticalIntent
      syntheticVerticalHold = horizontalIntent
    end

    -- Only a solo cardinal press opens a grace window. Seeing both axes at
    -- once proves true simultaneous input and clears stale detection state.
    if horizontalIntent ~= 0 and not anyVertical then
      recentHorizontalIntent = horizontalIntent
      recentHorizontalTicks = GAME_CONFIG.CardinalChordGraceTicks
    elseif anyHorizontal then
      recentHorizontalIntent = 0
      recentHorizontalTicks = 0
    elseif recentHorizontalTicks > 0 then
      recentHorizontalTicks = recentHorizontalTicks - 1
      if recentHorizontalTicks <= 0 then
        recentHorizontalIntent = 0
      end
    end

    if verticalIntent ~= 0 and not anyHorizontal then
      recentVerticalIntent = verticalIntent
      recentVerticalTicks = GAME_CONFIG.CardinalChordGraceTicks
    elseif anyVertical then
      recentVerticalIntent = 0
      recentVerticalTicks = 0
    elseif recentVerticalTicks > 0 then
      recentVerticalTicks = recentVerticalTicks - 1
      if recentVerticalTicks <= 0 then
        recentVerticalIntent = 0
      end
    end
  end

  local up = rawUp or diagonalUp or syntheticVerticalIntent < 0
  local down = rawDown or diagonalDown or syntheticVerticalIntent > 0
  local left = rawLeft or diagonalLeft or syntheticHorizontalIntent < 0
  local right = rawRight or diagonalRight or syntheticHorizontalIntent > 0
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
      backgroundRenderCounter = 0
      RenderBackgroundFrame()
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
  ResetCardinalChordAssist()
  Controls.Pause.Boolean = false
  ResetGameState(gameState)
  EnterStage(gameState, 1)
  ResetEnemies(gameState)
  ResetParallax(gameState, 1)
  gameState.running = true
  gameState.paused = false
  backgroundRenderCounter = 0
  RenderBackgroundFrame()
  RenderGameFrame()
  Controls.Status.String = "RUNNING"
  GameTimer:Start(GAME_CONFIG.UpdateInterval)
end

local function StopGame()
  GameTimer:Stop()
  ResetCardinalChordAssist()
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
  Controls.Status.String = "PAUSED"
end

local function ResumeGame()
  if not gameState.running then
    Controls.Pause.Boolean = false
    return
  end

  ResetCardinalChordAssist()
  gameState.paused = false
  backgroundRenderCounter = 0
  RenderBackgroundFrame()
  RenderGameFrame()
  Controls.Status.String = "RUNNING"
  GameTimer:Start(GAME_CONFIG.UpdateInterval)
end

GameTimer.EventHandler = function()
  UpdateGameState()
  UpdateBackgroundScroll(gameState)

  backgroundRenderCounter = backgroundRenderCounter + 1
  if backgroundRenderCounter >= GAME_CONFIG.BackgroundRenderDivider then
    backgroundRenderCounter = 0
    RenderBackgroundFrame()
  end

  RenderGameFrame()
end

Controls.Run.EventHandler = function(control)
  if control.Boolean then
    StartGame()
    control.Boolean = false
  end
end

Controls.Pause.EventHandler = function(control)
  if not gameState.running or gameState.gameOver or gameState.gameClear then
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
ResetCardinalChordAssist()
GameTimer:Stop()
Controls.Run.Boolean = false
Controls.Pause.Boolean = false
backgroundRenderCounter = 0
RenderBackgroundFrame()
RenderGameFrame()
Controls.Status.String = "READY"

local missingAssets = MissingAssetList()
if missingAssets ~= "" then
  print("[f5Rocket] Missing PNG assets; definition-based SVG fallbacks active: " .. missingAssets)
end

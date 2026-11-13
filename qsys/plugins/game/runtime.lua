local rapidjson = require("rapidjson")

local gameState = CreateGameState()
local renderPhase = 0
local backgroundRenderPending = false
local lastGameSvg = nil
local lastBackgroundSvg = nil
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

local lastTimerNow = nil
local performanceTicks = 0
local slowTickCount = 0
local slowLogCooldownTicks = 0
local maxTickGapMs = 0
local maxSimulationMs = 0
local maxGameBuildMs = 0
local maxGameBase64Ms = 0
local maxGameJsonMs = 0
local maxGamePublishMs = 0
local maxGameRenderMs = 0
local maxBackgroundBuildMs = 0
local maxBackgroundBase64Ms = 0
local maxBackgroundJsonMs = 0
local maxBackgroundPublishMs = 0
local maxBackgroundRenderMs = 0
local maxTotalCallbackMs = 0
local maxGameRawBytes = 0
local maxBackgroundRawBytes = 0

local function ElapsedMilliseconds(startedAt)
  return (Timer.Now() - startedAt) * 1000
end

local function ResetPerformanceWindow()
  performanceTicks = 0
  slowTickCount = 0
  slowLogCooldownTicks = 0
  maxTickGapMs = 0
  maxSimulationMs = 0
  maxGameBuildMs = 0
  maxGameBase64Ms = 0
  maxGameJsonMs = 0
  maxGamePublishMs = 0
  maxGameRenderMs = 0
  maxBackgroundBuildMs = 0
  maxBackgroundBase64Ms = 0
  maxBackgroundJsonMs = 0
  maxBackgroundPublishMs = 0
  maxBackgroundRenderMs = 0
  maxTotalCallbackMs = 0
  maxGameRawBytes = 0
  maxBackgroundRawBytes = 0
end

local function ResetPerformanceTiming()
  ResetPerformanceWindow()
  lastTimerNow = Timer.Now()
end

local function RenderBackgroundFrame()
  local renderStartedAt = Timer.Now()
  local buildStartedAt = renderStartedAt
  local svg = BuildStageBackgroundSvg(
    gameState.stageIndex,
    gameState.backgroundScrollY
  )
  local rawBytes = #svg
  local buildMs = ElapsedMilliseconds(buildStartedAt)

  if rawBytes > GAME_CONFIG.MaxRawBackgroundSvgBytes then
    error(
      "Background SVG " .. tostring(rawBytes) .. " B > " ..
      tostring(GAME_CONFIG.MaxRawBackgroundSvgBytes) .. " B",
      0
    )
  end

  local base64Ms = 0
  local jsonMs = 0
  local publishMs = 0
  if svg ~= lastBackgroundSvg then
    local base64StartedAt = Timer.Now()
    local encodedSvg = Crypto.Base64Encode(svg)
    base64Ms = ElapsedMilliseconds(base64StartedAt)

    local jsonStartedAt = Timer.Now()
    BackgroundLegend.IconData = encodedSvg
    local legend = rapidjson.encode(BackgroundLegend)
    BackgroundLegend.IconData = ""
    jsonMs = ElapsedMilliseconds(jsonStartedAt)

    local publishStartedAt = Timer.Now()
    Controls.BackgroundViewport.Legend = legend
    publishMs = ElapsedMilliseconds(publishStartedAt)
    lastBackgroundSvg = svg
  end
  local renderMs = ElapsedMilliseconds(renderStartedAt)

  return buildMs, base64Ms, jsonMs, publishMs, renderMs, rawBytes
end

local function RenderGameFrame()
  local renderStartedAt = Timer.Now()
  local buildStartedAt = renderStartedAt
  local svg = BuildGameSvg(gameState)
  local rawBytes = #svg
  local buildMs = ElapsedMilliseconds(buildStartedAt)

  if rawBytes > GAME_CONFIG.MaxRawSvgBytes then
    error(
      "SVG " .. tostring(rawBytes) .. " B > " ..
      tostring(GAME_CONFIG.MaxRawSvgBytes) .. " B",
      0
    )
  end

  local base64Ms = 0
  local jsonMs = 0
  local publishMs = 0
  if svg ~= lastGameSvg then
    local base64StartedAt = Timer.Now()
    local encodedSvg = Crypto.Base64Encode(svg)
    base64Ms = ElapsedMilliseconds(base64StartedAt)

    local jsonStartedAt = Timer.Now()
    GameLegend.IconData = encodedSvg
    local legend = rapidjson.encode(GameLegend)
    GameLegend.IconData = ""
    jsonMs = ElapsedMilliseconds(jsonStartedAt)

    local publishStartedAt = Timer.Now()
    Controls.Viewport.Legend = legend
    publishMs = ElapsedMilliseconds(publishStartedAt)
    lastGameSvg = svg
  end
  local renderMs = ElapsedMilliseconds(renderStartedAt)

  return buildMs, base64Ms, jsonMs, publishMs, renderMs, rawBytes
end

local function UpdatePerformanceDiagnostics(
    tickGapMs,
    simulationMs,
    gameBuildMs,
    gameBase64Ms,
    gameJsonMs,
    gamePublishMs,
    gameRenderMs,
    gameRawBytes,
    backgroundBuildMs,
    backgroundBase64Ms,
    backgroundJsonMs,
    backgroundPublishMs,
    backgroundRenderMs,
    backgroundRawBytes,
    totalCallbackMs,
    publishedLayer)
  performanceTicks = performanceTicks + 1
  maxTickGapMs = math.max(maxTickGapMs, tickGapMs)
  maxSimulationMs = math.max(maxSimulationMs, simulationMs)
  maxGameBuildMs = math.max(maxGameBuildMs, gameBuildMs)
  maxGameBase64Ms = math.max(maxGameBase64Ms, gameBase64Ms)
  maxGameJsonMs = math.max(maxGameJsonMs, gameJsonMs)
  maxGamePublishMs = math.max(maxGamePublishMs, gamePublishMs)
  maxGameRenderMs = math.max(maxGameRenderMs, gameRenderMs)
  maxBackgroundBuildMs = math.max(maxBackgroundBuildMs, backgroundBuildMs)
  maxBackgroundBase64Ms = math.max(maxBackgroundBase64Ms, backgroundBase64Ms)
  maxBackgroundJsonMs = math.max(maxBackgroundJsonMs, backgroundJsonMs)
  maxBackgroundPublishMs = math.max(maxBackgroundPublishMs, backgroundPublishMs)
  maxBackgroundRenderMs = math.max(maxBackgroundRenderMs, backgroundRenderMs)
  maxTotalCallbackMs = math.max(maxTotalCallbackMs, totalCallbackMs)
  maxGameRawBytes = math.max(maxGameRawBytes, gameRawBytes)
  maxBackgroundRawBytes = math.max(maxBackgroundRawBytes, backgroundRawBytes)

  local slowStep =
    simulationMs > GAME_CONFIG.PerfSlowStepMs or
    gameRenderMs > GAME_CONFIG.PerfSlowStepMs or
    gameBuildMs > GAME_CONFIG.PerfSlowStepMs or
    gameBase64Ms > GAME_CONFIG.PerfSlowStepMs or
    gameJsonMs > GAME_CONFIG.PerfSlowStepMs or
    gamePublishMs > GAME_CONFIG.PerfSlowStepMs or
    backgroundRenderMs > GAME_CONFIG.PerfSlowStepMs or
    backgroundBuildMs > GAME_CONFIG.PerfSlowStepMs or
    backgroundBase64Ms > GAME_CONFIG.PerfSlowStepMs or
    backgroundJsonMs > GAME_CONFIG.PerfSlowStepMs or
    backgroundPublishMs > GAME_CONFIG.PerfSlowStepMs
  local slowTick =
    tickGapMs > GAME_CONFIG.PerfSlowTickGapMs or
    totalCallbackMs > GAME_CONFIG.PerfSlowCallbackMs or
    slowStep

  if slowLogCooldownTicks > 0 then
    slowLogCooldownTicks = slowLogCooldownTicks - 1
  end

  if slowTick then
    slowTickCount = slowTickCount + 1
    if slowLogCooldownTicks <= 0 then
      print(string.format(
        "[f5Rocket perf] layer=%s gap=%.1f sim=%.1f " ..
        "game=%.1f[%.1f/%.1f/%.1f/%.1f] " ..
        "bg=%.1f[%.1f/%.1f/%.1f/%.1f] " ..
        "total=%.1f bytes=%d/%d stage=%s phase=%s boss=%s exp=%d",
        publishedLayer,
        tickGapMs,
        simulationMs,
        gameRenderMs,
        gameBuildMs,
        gameBase64Ms,
        gameJsonMs,
        gamePublishMs,
        backgroundRenderMs,
        backgroundBuildMs,
        backgroundBase64Ms,
        backgroundJsonMs,
        backgroundPublishMs,
        totalCallbackMs,
        gameRawBytes,
        backgroundRawBytes,
        gameState.stageName,
        gameState.stagePhase,
        tostring(gameState.boss.active),
        CountActiveExplosions(gameState)
      ))
      slowLogCooldownTicks = GAME_CONFIG.PerfSlowLogIntervalTicks
    end
  end

  if performanceTicks >= GAME_CONFIG.PerfSummaryTicks then
    print(string.format(
      "[f5Rocket perf] summary maxGap=%.1f maxSim=%.1f " ..
      "maxGame=%.1f(%.1f/%.1f/%.1f/%.1f) " ..
      "maxBg=%.1f(%.1f/%.1f/%.1f/%.1f) maxTotal=%.1f " ..
      "slow=%d maxBytes=%d/%d",
      maxTickGapMs,
      maxSimulationMs,
      maxGameRenderMs,
      maxGameBuildMs,
      maxGameBase64Ms,
      maxGameJsonMs,
      maxGamePublishMs,
      maxBackgroundRenderMs,
      maxBackgroundBuildMs,
      maxBackgroundBase64Ms,
      maxBackgroundJsonMs,
      maxBackgroundPublishMs,
      maxTotalCallbackMs,
      slowTickCount,
      maxGameRawBytes,
      maxBackgroundRawBytes
    ))
    ResetPerformanceWindow()
  end
end

local function ResetVisualScheduler(firstPhase)
  renderPhase = firstPhase or 0
  backgroundRenderPending = false
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
      -- Publish the new stage background on this tick instead of issuing a
      -- background and gameplay Legend update back-to-back.
      backgroundRenderPending = true
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

  UpdatePlayerBurstState(gameState)

  if firePressed then
    FirePlayerBullet(gameState)
  end

  UpdatePlayerBullets(gameState)
  if gameState.stagePhase == "WAVE" then
    UpdateEnemies(gameState)
    UpdateEnemyFire(gameState)
  elseif gameState.stagePhase == "BOSS" then
    UpdateDrainingEnemies(gameState)
    UpdateBoss(gameState)
  end
  UpdateEnemyBullets(gameState)

  if gameState.stagePhase == "WAVE" then
    CheckPlayerBulletEnemyCollisions(gameState)
  elseif gameState.stagePhase == "BOSS" then
    CheckPlayerBulletEnemyCollisions(gameState)
    CheckPlayerBulletBossCollisions(gameState)
  end
  CheckEnemyBulletPlayerCollisions(gameState)
  if gameState.stagePhase == "WAVE" then
    CheckEnemyPlayerCollisions(gameState)
  elseif gameState.stagePhase == "BOSS" then
    CheckEnemyPlayerCollisions(gameState)
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
  ResetVisualScheduler(0)
  RenderBackgroundFrame()
  RenderGameFrame()
  ResetPerformanceTiming()
  GameTimer:Start(GAME_CONFIG.UpdateInterval)
end

local function StopGame()
  GameTimer:Stop()
  ResetCardinalChordAssist()
  gameState.running = false
  gameState.paused = false
  Controls.Pause.Boolean = false
  lastTimerNow = nil
end

local function PauseGame()
  if not gameState.running or gameState.gameOver or gameState.gameClear then
    Controls.Pause.Boolean = false
    return
  end

  GameTimer:Stop()
  gameState.paused = true
  RenderGameFrame()
end

local function ResumeGame()
  if not gameState.running then
    Controls.Pause.Boolean = false
    return
  end

  ResetCardinalChordAssist()
  gameState.paused = false
  -- The paused overlay is removed immediately. Begin with the background
  -- phase so it catches up on the first resumed timer tick without a second
  -- Legend assignment in the same callback.
  ResetVisualScheduler(GAME_CONFIG.BackgroundRenderPhase)
  RenderGameFrame()
  ResetPerformanceTiming()
  GameTimer:Start(GAME_CONFIG.UpdateInterval)
end

GameTimer.EventHandler = function()
  local callbackStartedAt = Timer.Now()
  local tickGapMs = 0
  if lastTimerNow ~= nil then
    tickGapMs = (callbackStartedAt - lastTimerNow) * 1000
  end
  lastTimerNow = callbackStartedAt

  local simulationStartedAt = Timer.Now()
  UpdateGameState()
  UpdateBackgroundScroll(gameState)
  local simulationMs = ElapsedMilliseconds(simulationStartedAt)

  local gameBuildMs = 0
  local gameBase64Ms = 0
  local gameJsonMs = 0
  local gamePublishMs = 0
  local gameRenderMs = 0
  local gameRawBytes = 0
  local backgroundBuildMs = 0
  local backgroundBase64Ms = 0
  local backgroundJsonMs = 0
  local backgroundPublishMs = 0
  local backgroundRenderMs = 0
  local backgroundRawBytes = 0
  local publishedLayer = "none"
  local frozen = gameState.gameOverFrozen or gameState.campaignFrozen

  if frozen then
    gameBuildMs,
      gameBase64Ms,
      gameJsonMs,
      gamePublishMs,
      gameRenderMs,
      gameRawBytes = RenderGameFrame()
    publishedLayer = "game-final"
  elseif backgroundRenderPending then
    backgroundBuildMs,
      backgroundBase64Ms,
      backgroundJsonMs,
      backgroundPublishMs,
      backgroundRenderMs,
      backgroundRawBytes = RenderBackgroundFrame()
    backgroundRenderPending = false
    renderPhase = 0
    publishedLayer = "background-stage"
  else
    local currentPhase = renderPhase
    renderPhase = renderPhase + 1
    if renderPhase >= GAME_CONFIG.RenderCycleTicks then
      renderPhase = 0
    end

    if currentPhase == GAME_CONFIG.BackgroundRenderPhase then
      backgroundBuildMs,
        backgroundBase64Ms,
        backgroundJsonMs,
        backgroundPublishMs,
        backgroundRenderMs,
        backgroundRawBytes = RenderBackgroundFrame()
      publishedLayer = "background"
    else
      gameBuildMs,
        gameBase64Ms,
        gameJsonMs,
        gamePublishMs,
        gameRenderMs,
        gameRawBytes = RenderGameFrame()
      publishedLayer = "game"
    end
  end

  local totalCallbackMs = ElapsedMilliseconds(callbackStartedAt)
  UpdatePerformanceDiagnostics(
    tickGapMs,
    simulationMs,
    gameBuildMs,
    gameBase64Ms,
    gameJsonMs,
    gamePublishMs,
    gameRenderMs,
    gameRawBytes,
    backgroundBuildMs,
    backgroundBase64Ms,
    backgroundJsonMs,
    backgroundPublishMs,
    backgroundRenderMs,
    backgroundRawBytes,
    totalCallbackMs,
    publishedLayer
  )

  -- The final frozen scene has now been assigned. Run remains an independent
  -- control handler, so stopping this one timer removes idle render work
  -- without preventing a clean restart.
  if gameState.gameOverFrozen or gameState.campaignFrozen then
    GameTimer:Stop()
  end
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
ResetVisualScheduler(0)
ResetPerformanceWindow()
lastTimerNow = nil
RenderBackgroundFrame()
RenderGameFrame()

local missingAssets = MissingAssetList()
if missingAssets ~= "" then
  print("[f5Rocket] Missing PNG assets; definition-based SVG fallbacks active: " .. missingAssets)
end

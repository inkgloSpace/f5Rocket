local function GetStageProfile(stateOrIndex)
  local index = stateOrIndex
  if type(stateOrIndex) == "table" then
    index = stateOrIndex.stageIndex
  end
  return STAGE_PROFILES[index]
end

local function UpdateBackgroundScroll(state)
  local profile = GetStageProfile(state)
  local nextY = state.backgroundScrollY + profile.BackgroundScrollSpeed
  if nextY >= GAME_CONFIG.BackgroundTileHeight then
    nextY = nextY - GAME_CONFIG.BackgroundTileHeight
  end
  state.backgroundScrollY = nextY
end

local function DeactivateOrdinaryEnemies(state)
  for index = 1, GAME_CONFIG.MaxEnemies do
    state.enemies[index].active = false
  end
end

local function DeactivateEnemyBullets(state)
  for index = 1, GAME_CONFIG.MaxEnemyBullets do
    state.enemyBullets[index].active = false
  end
end

local function DeactivatePlayerBullets(state)
  for index = 1, GAME_CONFIG.MaxPlayerBullets do
    state.playerBullets[index].active = false
  end
end

local function EnterStage(state, stageIndex)
  local profile = STAGE_PROFILES[stageIndex]
  state.stageIndex = stageIndex
  state.stageName = profile.Name
  state.stageScore = 0
  state.stagePhase = "WAVE"
  state.stageTransitionTicks = 0
  state.backgroundScrollY = 0
  state.gameClear = false
  state.campaignFrozen = false
  state.boss.active = false
  DeactivatePlayerBullets(state)
  DeactivateEnemyBullets(state)
end

local function StageThresholdReached(state)
  local profile = GetStageProfile(state)
  return state.stagePhase == "WAVE" and
    state.stageScore >= profile.ScoreThreshold
end

local function BeginBossPhase(state)
  state.stagePhase = "BOSS"
  DeactivateOrdinaryEnemies(state)
  DeactivateEnemyBullets(state)
end

local function BeginStageClear(state)
  state.stagePhase = "CLEAR"
  state.stageTransitionTicks = GAME_CONFIG.StageClearTicks
  DeactivateOrdinaryEnemies(state)
  DeactivateEnemyBullets(state)
  if state.stageIndex == 3 then
    state.gameClear = true
  end
end

-- Returns the next stage index exactly once when a miniboss clear delay ends.
local function AdvanceStageClear(state)
  if state.campaignFrozen then
    return nil
  end

  if state.stageTransitionTicks > 0 then
    state.stageTransitionTicks = state.stageTransitionTicks - 1
  end

  if state.stageTransitionTicks > 0 then
    return nil
  end

  if state.stageIndex < 3 then
    local nextStage = state.stageIndex + 1
    EnterStage(state, nextStage)
    return nextStage
  end

  state.campaignFrozen = true
  return nil
end

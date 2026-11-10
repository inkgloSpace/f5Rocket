local PARALLAX_LAYER_FAR = 1
local PARALLAX_LAYER_MID = 2
local PARALLAX_LAYER_NEAR = 3

local function ParallaxLayerSettings(profile, layer)
  if layer == PARALLAX_LAYER_FAR then
    return profile.FarCount, profile.FarSpeedMin, profile.FarSpeedMax, 4
  elseif layer == PARALLAX_LAYER_MID then
    return profile.MidCount, profile.MidSpeedMin, profile.MidSpeedMax, 16
  end
  return profile.NearCount, profile.NearSpeedMin, profile.NearSpeedMax, 24
end

local function ConfigureParallaxItem(item, stageIndex, layer, initialPosition)
  local profile = PARALLAX_PROFILES[stageIndex]
  local _, minimumSpeed, maximumSpeed, margin =
    ParallaxLayerSettings(profile, layer)
  local layerSeed = layer * 23
  local speedStep = (
    item.slot * 7 + item.cycle * 5 + stageIndex * 3 + layerSeed
  ) % 7

  item.x = (
    item.slot * 47 + item.cycle * 31 + stageIndex * 19 + layerSeed
  ) % GAME_CONFIG.LogicalWidth

  if initialPosition then
    item.y = (
      item.slot * (61 + layerSeed) + stageIndex * 41
    ) % GAME_CONFIG.LogicalHeight
  else
    item.y = -margin - (
      item.slot * 17 + item.cycle * 13 + stageIndex * 11
    ) % 96
  end

  item.speed = minimumSpeed +
    (maximumSpeed - minimumSpeed) * speedStep / 6
  item.variant = 1 + (
    item.slot + item.cycle + stageIndex + layer
  ) % 2

  if layer == PARALLAX_LAYER_FAR then
    item.driftX = 0
  else
    item.driftX = (
      (item.slot + item.cycle + stageIndex) % 3 - 1
    ) * 0.25
  end

  -- Keep the flight lane comparatively clean while allowing sparse edge
  -- streaks to provide the strongest foreground speed cue.
  if layer == PARALLAX_LAYER_NEAR and item.x > 112 and item.x < 208 then
    item.x = (item.x + 128) % GAME_CONFIG.LogicalWidth
  end
end

local function ResetParallaxLayer(pool, maximum, activeCount, stageIndex, layer)
  for index = 1, maximum do
    local item = pool[index]
    item.active = index <= activeCount
    item.cycle = 0
    if item.active then
      ConfigureParallaxItem(item, stageIndex, layer, true)
    end
  end
end

local function ResetParallax(state, stageIndex)
  local profile = PARALLAX_PROFILES[stageIndex]
  ResetParallaxLayer(
    state.parallax.far,
    GAME_CONFIG.MaxFarParallax,
    profile.FarCount,
    stageIndex,
    PARALLAX_LAYER_FAR
  )
  ResetParallaxLayer(
    state.parallax.mid,
    GAME_CONFIG.MaxMidParallax,
    profile.MidCount,
    stageIndex,
    PARALLAX_LAYER_MID
  )
  ResetParallaxLayer(
    state.parallax.near,
    GAME_CONFIG.MaxNearParallax,
    profile.NearCount,
    stageIndex,
    PARALLAX_LAYER_NEAR
  )
end

local function ParallaxSpeedMultiplier(state)
  if state.gameOver then
    return GAME_CONFIG.GameOverParallaxMultiplier
  elseif state.gameClear then
    return GAME_CONFIG.GameClearParallaxMultiplier
  elseif state.stagePhase == "CLEAR" then
    return GAME_CONFIG.StageClearParallaxMultiplier
  elseif state.stagePhase == "BOSS" then
    return GAME_CONFIG.BossParallaxMultiplier
  end
  return 1
end

local function UpdateParallaxLayer(
    pool,
    maximum,
    state,
    layer,
    multiplier
  )
  local _, _, _, margin =
    ParallaxLayerSettings(PARALLAX_PROFILES[state.stageIndex], layer)

  for index = 1, maximum do
    local item = pool[index]
    if item.active then
      item.x = item.x + item.driftX * multiplier
      item.y = item.y + item.speed * multiplier

      if item.x < -margin then
        item.x = GAME_CONFIG.LogicalWidth + margin
      elseif item.x > GAME_CONFIG.LogicalWidth + margin then
        item.x = -margin
      end

      if item.y > GAME_CONFIG.LogicalHeight + margin then
        item.cycle = item.cycle + 1
        ConfigureParallaxItem(
          item,
          state.stageIndex,
          layer,
          false
        )
      end
    end
  end
end

local function UpdateParallax(state)
  local multiplier = ParallaxSpeedMultiplier(state)
  UpdateParallaxLayer(
    state.parallax.far,
    GAME_CONFIG.MaxFarParallax,
    state,
    PARALLAX_LAYER_FAR,
    multiplier
  )
  UpdateParallaxLayer(
    state.parallax.mid,
    GAME_CONFIG.MaxMidParallax,
    state,
    PARALLAX_LAYER_MID,
    multiplier
  )
  UpdateParallaxLayer(
    state.parallax.near,
    GAME_CONFIG.MaxNearParallax,
    state,
    PARALLAX_LAYER_NEAR,
    multiplier
  )
end

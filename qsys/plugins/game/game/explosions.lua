local function ScheduleExplosion(state, x, y, delayTicks)
  for index = 1, GAME_CONFIG.MaxExplosions do
    local explosion = state.explosions[index]
    if not explosion.active then
      explosion.active = true
      explosion.x = math.floor(x)
      explosion.y = math.floor(y)
      explosion.frame = 1
      explosion.frameTicksRemaining = GAME_CONFIG.ExplosionFrameTicks
      explosion.delayTicks = delayTicks or 0
      return true
    end
  end

  return false
end


local function SpawnExplosion(state, x, y)
  return ScheduleExplosion(state, x, y, 0)
end

local function UpdateExplosions(state)
  for index = 1, GAME_CONFIG.MaxExplosions do
    local explosion = state.explosions[index]
    if explosion.active then
      if explosion.delayTicks > 0 then
        explosion.delayTicks = explosion.delayTicks - 1
      else
        explosion.frameTicksRemaining = explosion.frameTicksRemaining - 1

        if explosion.frameTicksRemaining <= 0 then
          explosion.frame = explosion.frame + 1
          if explosion.frame > GAME_CONFIG.ExplosionFrames then
            explosion.active = false
          else
            explosion.frameTicksRemaining = GAME_CONFIG.ExplosionFrameTicks
          end
        end
      end
    end
  end
end

local function AdvanceGameOverAnimation(state)
  if state.gameOverFrozen then
    return
  end

  UpdateExplosions(state)
  state.gameOverTicks = state.gameOverTicks + 1
  if state.gameOverTicks >= GAME_CONFIG.GameOverAnimationTicks then
    state.gameOverFrozen = true
  end
end

local function CountActiveExplosions(state)
  local count = 0
  for index = 1, GAME_CONFIG.MaxExplosions do
    if state.explosions[index].active then
      count = count + 1
    end
  end
  return count
end

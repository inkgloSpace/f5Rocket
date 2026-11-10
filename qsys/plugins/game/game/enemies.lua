local function EnemyFireDelay(enemy, initialSpawn, profile)
  if initialSpawn then
    return math.floor(profile.EnemyFireIntervalTicks / 3) +
      (enemy.slot - 1) * 12
  end

  local stagger = (
    enemy.slot * 7 + enemy.cycle * 11
  ) % GAME_CONFIG.EnemyFireStaggerTicks
  return profile.EnemyFireIntervalTicks + stagger
end

local function RecycleEnemy(state, enemy)
  local profile = GetStageProfile(state)
  enemy.cycle = enemy.cycle + 1
  local horizontalRange = GAME_CONFIG.LogicalWidth - enemy.width
  enemy.x = (enemy.slot * 53 + enemy.cycle * 29) % horizontalRange
  enemy.y = -enemy.height - ((enemy.slot * 37 + enemy.cycle * 11) % 160)
  enemy.fireCooldown = EnemyFireDelay(enemy, false, profile)
  enemy.active = true
end

local function ResetEnemies(state)
  local profile = GetStageProfile(state)
  local horizontalRange = GAME_CONFIG.LogicalWidth - GAME_CONFIG.EnemyWidth

  for index = 1, GAME_CONFIG.MaxEnemies do
    local enemy = state.enemies[index]
    enemy.active = index <= profile.EnemyCount
    enemy.cycle = 0
    enemy.x = ((index - 1) * 73 + 20) % horizontalRange
    enemy.y = 48 - (index - 1) * 96
    enemy.fireCooldown = EnemyFireDelay(enemy, true, profile)
  end
end

local function UpdateEnemies(state)
  local profile = GetStageProfile(state)
  local playerCenterX = state.player.x + state.player.width / 2
  local maximumX = GAME_CONFIG.LogicalWidth - GAME_CONFIG.EnemyWidth

  for index = 1, GAME_CONFIG.MaxEnemies do
    local enemy = state.enemies[index]
    if enemy.active then
      local enemyCenterX = enemy.x + enemy.width / 2
      local deltaX = playerCenterX - enemyCenterX

      if deltaX > 0 then
        enemy.x = enemy.x + math.min(deltaX, profile.EnemySteerSpeed)
      elseif deltaX < 0 then
        enemy.x = enemy.x - math.min(-deltaX, profile.EnemySteerSpeed)
      end

      enemy.x = math.max(0, math.min(maximumX, enemy.x))
      enemy.y = enemy.y + profile.EnemyVerticalSpeed

      if enemy.y > GAME_CONFIG.LogicalHeight then
        RecycleEnemy(state, enemy)
      end
    end
  end
end

local function UpdateEnemyFire(state)
  if not state.player.alive then
    return
  end

  local profile = GetStageProfile(state)
  for index = 1, GAME_CONFIG.MaxEnemies do
    local enemy = state.enemies[index]
    if enemy.active then
      if enemy.fireCooldown > 0 then
        enemy.fireCooldown = enemy.fireCooldown - 1
      end

      if enemy.fireCooldown <= 0 and
          enemy.y > 20 and
          enemy.y < state.player.y - GAME_CONFIG.EnemyFireSafetyDistance then
        if FireEnemyAimedBullet(state, enemy, profile.EnemyBulletSpeed) then
          enemy.fireCooldown = EnemyFireDelay(enemy, false, profile)
        else
          enemy.fireCooldown = GAME_CONFIG.EnemyFireRetryTicks
        end
      end
    end
  end
end

local function CountActiveEnemies(state)
  local count = 0
  for index = 1, GAME_CONFIG.MaxEnemies do
    if state.enemies[index].active then
      count = count + 1
    end
  end
  return count
end

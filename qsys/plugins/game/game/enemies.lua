local function RecycleEnemy(enemy)
  enemy.cycle = enemy.cycle + 1
  local horizontalRange = GAME_CONFIG.LogicalWidth - enemy.width
  enemy.x = (enemy.slot * 53 + enemy.cycle * 29) % horizontalRange
  enemy.y = -enemy.height - ((enemy.slot * 37 + enemy.cycle * 11) % 160)
  enemy.active = true
end

local function ResetEnemies(state)
  local horizontalRange = GAME_CONFIG.LogicalWidth - GAME_CONFIG.EnemyWidth

  for index = 1, GAME_CONFIG.MaxEnemies do
    local enemy = state.enemies[index]
    enemy.active = index <= GAME_CONFIG.InitialEnemyCount
    enemy.cycle = 0
    enemy.x = ((index - 1) * 73 + 20) % horizontalRange
    enemy.y = 48 - (index - 1) * 96
  end
end

local function UpdateEnemies(state)
  for index = 1, GAME_CONFIG.MaxEnemies do
    local enemy = state.enemies[index]
    if enemy.active then
      enemy.y = enemy.y + GAME_CONFIG.EnemySpeed
      if enemy.y > GAME_CONFIG.LogicalHeight then
        RecycleEnemy(enemy)
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

local function CreateGameState()
  local state = {
    running = false,
    paused = false,
    score = 0,
    time = 0,
    ticks = 0,
    backgroundOffset = 0,
    player = {},
    enemies = {},
    playerBullets = {},
    enemyBullets = {},
    explosions = {}
  }

  for index = 1, GAME_CONFIG.MaxEnemies do
    state.enemies[index] = {
      active = false,
      x = 0,
      y = 0,
      width = GAME_CONFIG.EnemyWidth,
      height = GAME_CONFIG.EnemyHeight,
      slot = index,
      cycle = 0
    }
  end

  for index = 1, GAME_CONFIG.MaxPlayerBullets do
    state.playerBullets[index] = {
      active = false,
      x = 0,
      y = 0,
      width = GAME_CONFIG.PlayerBulletWidth,
      height = GAME_CONFIG.PlayerBulletHeight
    }
  end

  for index = 1, GAME_CONFIG.MaxExplosions do
    state.explosions[index] = {
      active = false,
      x = 0,
      y = 0,
      frame = 1,
      ticksRemaining = 0
    }
  end

  return state
end

local function ResetGameState(state)
  state.running = false
  state.paused = false
  state.score = 0
  state.time = 0
  state.ticks = 0
  state.backgroundOffset = 0

  state.player.x = math.floor((GAME_CONFIG.LogicalWidth - GAME_CONFIG.PlayerWidth) / 2)
  state.player.y = GAME_CONFIG.PlayerStartY
  state.player.width = GAME_CONFIG.PlayerWidth
  state.player.height = GAME_CONFIG.PlayerHeight
  state.player.direction = "idle"
  state.player.fireCooldown = 0

  for index = 1, GAME_CONFIG.MaxEnemies do
    local enemy = state.enemies[index]
    enemy.active = false
    enemy.x = 0
    enemy.y = 0
    enemy.cycle = 0
  end

  for index = 1, GAME_CONFIG.MaxPlayerBullets do
    local bullet = state.playerBullets[index]
    bullet.active = false
    bullet.x = 0
    bullet.y = 0
  end

  for index = 1, GAME_CONFIG.MaxExplosions do
    local explosion = state.explosions[index]
    explosion.active = false
    explosion.x = 0
    explosion.y = 0
    explosion.frame = 1
    explosion.ticksRemaining = 0
  end
end

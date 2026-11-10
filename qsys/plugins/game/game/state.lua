local function CreateGameState()
  local state = {
    running = false,
    gameOver = false,
    gameOverTicks = 0,
    gameOverFrozen = false,
    gameClear = false,
    campaignFrozen = false,
    stageIndex = 1,
    stageName = "EASY",
    stageScore = 0,
    stagePhase = "WAVE",
    stageTransitionTicks = 0,
    score = 0,
    time = 0,
    ticks = 0,
    player = {},
    boss = {
      active = false,
      bossType = "",
      assetId = "",
      label = "",
      x = 0,
      y = 0,
      width = 0,
      height = 0,
      hp = 0,
      maxHp = 0,
      direction = 1,
      fireCooldown = 0,
      patternTick = 0,
      volleyCount = 0,
      entered = false
    },
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
      cycle = 0,
      fireCooldown = 0
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

  for index = 1, GAME_CONFIG.MaxEnemyBullets do
    state.enemyBullets[index] = {
      active = false,
      x = 0,
      y = 0,
      vx = 0,
      vy = 0,
      width = GAME_CONFIG.EnemyBulletWidth,
      height = GAME_CONFIG.EnemyBulletHeight
    }
  end

  for index = 1, GAME_CONFIG.MaxExplosions do
    state.explosions[index] = {
      active = false,
      x = 0,
      y = 0,
      frame = 1,
      frameTicksRemaining = 0,
      delayTicks = 0
    }
  end

  return state
end

local function ResetGameState(state)
  state.running = false
  state.gameOver = false
  state.gameOverTicks = 0
  state.gameOverFrozen = false
  state.gameClear = false
  state.campaignFrozen = false
  state.stageIndex = 1
  state.stageName = "EASY"
  state.stageScore = 0
  state.stagePhase = "WAVE"
  state.stageTransitionTicks = 0
  state.score = 0
  state.time = 0
  state.ticks = 0

  state.player.x = math.floor((GAME_CONFIG.LogicalWidth - GAME_CONFIG.PlayerWidth) / 2)
  state.player.y = GAME_CONFIG.PlayerStartY
  state.player.width = GAME_CONFIG.PlayerWidth
  state.player.height = GAME_CONFIG.PlayerHeight
  state.player.direction = "idle"
  state.player.fireCooldown = 0
  state.player.alive = true

  local boss = state.boss
  boss.active = false
  boss.bossType = ""
  boss.assetId = ""
  boss.label = ""
  boss.x = 0
  boss.y = 0
  boss.width = 0
  boss.height = 0
  boss.hp = 0
  boss.maxHp = 0
  boss.direction = 1
  boss.fireCooldown = 0
  boss.patternTick = 0
  boss.volleyCount = 0
  boss.entered = false

  for index = 1, GAME_CONFIG.MaxEnemies do
    local enemy = state.enemies[index]
    enemy.active = false
    enemy.x = 0
    enemy.y = 0
    enemy.cycle = 0
    enemy.fireCooldown = 0
  end

  for index = 1, GAME_CONFIG.MaxEnemyBullets do
    local bullet = state.enemyBullets[index]
    bullet.active = false
    bullet.x = 0
    bullet.y = 0
    bullet.vx = 0
    bullet.vy = 0
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
    explosion.frameTicksRemaining = 0
    explosion.delayTicks = 0
  end
end

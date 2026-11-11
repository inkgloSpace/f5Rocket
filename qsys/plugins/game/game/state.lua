local function CreateGameState()
  local state = {
    running = false,
    paused = false,
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
    backgroundScrollY = 0,
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
    explosions = {},
    parallax = {
      far = {},
      mid = {},
      near = {}
    }
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

  for index = 1, GAME_CONFIG.MaxFarParallax do
    state.parallax.far[index] = {
      active = false,
      x = 0,
      y = 0,
      speed = 0,
      variant = 1,
      slot = index,
      cycle = 0,
      driftX = 0
    }
  end

  for index = 1, GAME_CONFIG.MaxMidParallax do
    state.parallax.mid[index] = {
      active = false,
      x = 0,
      y = 0,
      speed = 0,
      variant = 1,
      slot = index,
      cycle = 0,
      driftX = 0
    }
  end

  for index = 1, GAME_CONFIG.MaxNearParallax do
    state.parallax.near[index] = {
      active = false,
      x = 0,
      y = 0,
      speed = 0,
      variant = 1,
      slot = index,
      cycle = 0,
      driftX = 0
    }
  end

  return state
end

local function ResetGameState(state)
  state.running = false
  state.paused = false
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
  state.backgroundScrollY = 0

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


  local function ResetParallaxPool(pool, maximum)
    for index = 1, maximum do
      local item = pool[index]
      item.active = false
      item.x = 0
      item.y = 0
      item.speed = 0
      item.variant = 1
      item.cycle = 0
      item.driftX = 0
    end
  end

  ResetParallaxPool(state.parallax.far, GAME_CONFIG.MaxFarParallax)
  ResetParallaxPool(state.parallax.mid, GAME_CONFIG.MaxMidParallax)
  ResetParallaxPool(state.parallax.near, GAME_CONFIG.MaxNearParallax)
end

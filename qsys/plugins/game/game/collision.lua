local function BoxesOverlap(first, second)
  return first.x < second.x + second.width and
    first.x + first.width > second.x and
    first.y < second.y + second.height and
    first.y + first.height > second.y
end

local function ExplosionXForObject(object)
  return object.x + (object.width - GAME_CONFIG.ExplosionWidth) / 2
end

local function ExplosionYForObject(object)
  return object.y + (object.height - GAME_CONFIG.ExplosionHeight) / 2
end

local function KillPlayer(state)
  local player = state.player
  if not player.alive then
    return false
  end

  player.alive = false
  SpawnExplosion(
    state,
    ExplosionXForObject(player),
    ExplosionYForObject(player)
  )
  state.gameOver = true
  state.gameOverTicks = 0
  state.gameOverFrozen = false
  return true
end

local function CheckPlayerBulletEnemyCollisions(state)
  local profile = GetStageProfile(state)
  for bulletIndex = 1, GAME_CONFIG.MaxPlayerBullets do
    local bullet = state.playerBullets[bulletIndex]
    if bullet.active then
      for enemyIndex = 1, GAME_CONFIG.MaxEnemies do
        local enemy = state.enemies[enemyIndex]
        if enemy.active and BoxesOverlap(bullet, enemy) then
          local explosionX = ExplosionXForObject(enemy)
          local explosionY = ExplosionYForObject(enemy)
          bullet.active = false
          SpawnExplosion(state, explosionX, explosionY)
          RecycleEnemy(state, enemy)
          state.score = state.score + profile.EnemyScore
          state.stageScore = state.stageScore + profile.EnemyScore
          break
        end
      end
    end
  end
end

local function CheckPlayerBulletBossCollisions(state)
  local boss = state.boss
  if not boss.active then
    return
  end

  for bulletIndex = 1, GAME_CONFIG.MaxPlayerBullets do
    local bullet = state.playerBullets[bulletIndex]
    if bullet.active and BoxesOverlap(bullet, boss) then
      bullet.active = false
      boss.hp = boss.hp - 1
      if boss.hp <= 0 then
        boss.hp = 0
        DefeatBoss(state)
        return
      end
    end
  end
end

local function CheckEnemyBulletPlayerCollisions(state)
  if not state.player.alive then
    return
  end

  for bulletIndex = 1, GAME_CONFIG.MaxEnemyBullets do
    local bullet = state.enemyBullets[bulletIndex]
    if bullet.active and BoxesOverlap(bullet, state.player) then
      bullet.active = false
      KillPlayer(state)
      return
    end
  end
end

local function CheckEnemyPlayerCollisions(state)
  if not state.player.alive then
    return
  end

  for enemyIndex = 1, GAME_CONFIG.MaxEnemies do
    local enemy = state.enemies[enemyIndex]
    if enemy.active and BoxesOverlap(enemy, state.player) then
      local explosionX = ExplosionXForObject(enemy)
      local explosionY = ExplosionYForObject(enemy)

      if KillPlayer(state) then
        SpawnExplosion(state, explosionX, explosionY)
        RecycleEnemy(state, enemy)
      end
      return
    end
  end
end

local function CheckBossPlayerCollision(state)
  if not state.player.alive or not state.boss.active then
    return
  end

  if BoxesOverlap(state.boss, state.player) then
    KillPlayer(state)
  end
end

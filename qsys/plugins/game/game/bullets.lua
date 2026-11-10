local function FirePlayerBullet(state)
  local player = state.player
  if not player.alive or player.fireCooldown > 0 then
    return false
  end

  for index = 1, GAME_CONFIG.MaxPlayerBullets do
    local bullet = state.playerBullets[index]
    if not bullet.active then
      bullet.active = true
      bullet.x = math.floor(player.x + (player.width - bullet.width) / 2)
      bullet.y = player.y - bullet.height
      player.fireCooldown = GAME_CONFIG.FireIntervalTicks
      return true
    end
  end

  return false
end

local function FireEnemyVectorBullet(state, startX, startY, vx, vy)
  if not state.player.alive then
    return false
  end

  for index = 1, GAME_CONFIG.MaxEnemyBullets do
    local bullet = state.enemyBullets[index]
    if not bullet.active then
      bullet.active = true
      bullet.x = math.floor(startX - bullet.width / 2)
      bullet.y = math.floor(startY)
      bullet.vx = vx
      bullet.vy = vy
      return true
    end
  end

  return false
end

local function FireEnemyAimedBullet(state, source, bulletSpeed)
  local startX = source.x + source.width / 2
  local startY = source.y + source.height
  local targetX = state.player.x + state.player.width / 2
  local targetY = state.player.y + state.player.height / 2
  local dx = targetX - startX
  local dy = targetY - startY
  local distance = math.sqrt(dx * dx + dy * dy)

  if distance < 0.0001 then
    dx = 0
    dy = 1
    distance = 1
  end

  return FireEnemyVectorBullet(
    state,
    startX,
    startY,
    dx / distance * bulletSpeed,
    dy / distance * bulletSpeed
  )
end

local function UpdatePlayerBullets(state)
  for index = 1, GAME_CONFIG.MaxPlayerBullets do
    local bullet = state.playerBullets[index]
    if bullet.active then
      bullet.y = bullet.y - GAME_CONFIG.PlayerBulletSpeed
      if bullet.y + bullet.height < 0 then
        bullet.active = false
      end
    end
  end
end

local function UpdateEnemyBullets(state)
  for index = 1, GAME_CONFIG.MaxEnemyBullets do
    local bullet = state.enemyBullets[index]
    if bullet.active then
      bullet.x = bullet.x + bullet.vx
      bullet.y = bullet.y + bullet.vy

      if bullet.x < -bullet.width or
          bullet.x > GAME_CONFIG.LogicalWidth or
          bullet.y < -bullet.height or
          bullet.y > GAME_CONFIG.LogicalHeight then
        bullet.active = false
      end
    end
  end
end

local function CountActiveEnemyBullets(state)
  local count = 0
  for index = 1, GAME_CONFIG.MaxEnemyBullets do
    if state.enemyBullets[index].active then
      count = count + 1
    end
  end
  return count
end

local function CountActivePlayerBullets(state)
  local count = 0
  for index = 1, GAME_CONFIG.MaxPlayerBullets do
    if state.playerBullets[index].active then
      count = count + 1
    end
  end
  return count
end

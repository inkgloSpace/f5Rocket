local function FirePlayerBullet(state)
  local player = state.player
  if player.fireCooldown > 0 then
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

local function CountActivePlayerBullets(state)
  local count = 0
  for index = 1, GAME_CONFIG.MaxPlayerBullets do
    if state.playerBullets[index].active then
      count = count + 1
    end
  end
  return count
end

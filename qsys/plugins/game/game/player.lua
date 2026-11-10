local function ClampInteger(value, minimum, maximum)
  if value < minimum then
    return minimum
  end
  if value > maximum then
    return maximum
  end
  return math.floor(value)
end

local function UpdatePlayer(state, leftPressed, rightPressed, upPressed, downPressed)
  local player = state.player
  if not player.alive then
    return
  end

  local horizontal = 0
  local vertical = 0

  if leftPressed then
    horizontal = horizontal - 1
  end
  if rightPressed then
    horizontal = horizontal + 1
  end
  if upPressed then
    vertical = vertical - 1
  end
  if downPressed then
    vertical = vertical + 1
  end

  local movement = GAME_CONFIG.PlayerSpeed
  if horizontal ~= 0 and vertical ~= 0 then
    movement = GAME_CONFIG.PlayerDiagonalSpeed
  end

  player.x = ClampInteger(
    player.x + horizontal * movement,
    0,
    GAME_CONFIG.LogicalWidth - player.width
  )
  player.y = ClampInteger(
    player.y + vertical * movement,
    0,
    GAME_CONFIG.LogicalHeight - player.height
  )

  if horizontal < 0 then
    player.direction = "left"
  elseif horizontal > 0 then
    player.direction = "right"
  else
    player.direction = "idle"
  end

  if player.fireCooldown > 0 then
    player.fireCooldown = player.fireCooldown - 1
  end
end

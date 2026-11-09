local STARFIELD = {
  { 12, 18, 1 }, { 48, 52, 2 }, { 86, 31, 1 }, { 130, 74, 1 },
  { 176, 22, 2 }, { 224, 64, 1 }, { 282, 36, 1 }, { 308, 92, 2 },
  { 28, 126, 1 }, { 70, 158, 1 }, { 112, 112, 2 }, { 154, 174, 1 },
  { 202, 138, 1 }, { 248, 186, 2 }, { 296, 146, 1 }, { 18, 226, 2 },
  { 58, 268, 1 }, { 104, 214, 1 }, { 146, 286, 2 }, { 190, 242, 1 },
  { 236, 304, 1 }, { 278, 258, 2 }, { 314, 326, 1 }, { 34, 362, 1 },
  { 82, 414, 2 }, { 126, 348, 1 }, { 170, 438, 1 }, { 216, 382, 2 },
  { 260, 456, 1 }, { 302, 402, 1 }, { 54, 472, 1 }, { 244, 18, 1 }
}

local function AppendBackground(parts, state)
  if AssetAvailable("background_tile") then
    local offset = state.backgroundOffset
    AppendAssetUse(parts, "background_tile", 0, offset - GAME_CONFIG.LogicalHeight)
    AppendAssetUse(parts, "background_tile", 0, offset)
    return
  end

  for index = 1, #STARFIELD do
    local star = STARFIELD[index]
    local y = (star[2] + state.backgroundOffset) % GAME_CONFIG.LogicalHeight
    local color = "#7088a8"
    if star[3] == 2 then
      color = "#d7f7ff"
    end
    parts[#parts + 1] = "<rect x=\"" .. tostring(star[1]) .. "\" y=\"" ..
      tostring(y) .. "\" width=\"" .. tostring(star[3]) .. "\" height=\"" ..
      tostring(star[3]) .. "\" fill=\"" .. color .. "\"/>"
  end
end

local function AppendEnemy(parts, enemy)
  if AppendAssetUse(parts, "enemy_01", enemy.x, enemy.y) then
    return
  end

  parts[#parts + 1] = "<g transform=\"translate(" .. tostring(enemy.x) .. " " ..
    tostring(enemy.y) .. ")\"><rect width=\"28\" height=\"28\" fill=\"#ff5c68\"/>" ..
    "<path d=\"M4 8H24L20 24H8Z\" fill=\"#791f3d\"/>" ..
    "<text x=\"14\" y=\"19\" fill=\"#ffffff\" font-family=\"monospace\" font-size=\"10\" text-anchor=\"middle\">E</text></g>"
end

local function AppendPlayerBullet(parts, bullet)
  if not AppendAssetUse(parts, "bullet_player", bullet.x, bullet.y) then
    parts[#parts + 1] = "<rect x=\"" .. tostring(bullet.x) .. "\" y=\"" ..
      tostring(bullet.y) .. "\" width=\"6\" height=\"12\" fill=\"#ffe66d\"/>"
  end
end

local function AppendEnemyBullet(parts, bullet)
  if not AppendAssetUse(parts, "bullet_enemy", bullet.x, bullet.y) then
    parts[#parts + 1] = "<rect x=\"" .. tostring(bullet.x) .. "\" y=\"" ..
      tostring(bullet.y) .. "\" width=\"6\" height=\"8\" fill=\"#ff9b45\"/>"
  end
end

local function AppendPlayer(parts, player)
  local assetId = ResolvePlayerAsset(player.direction)
  if assetId ~= nil and AppendAssetUse(parts, assetId, player.x, player.y) then
    return
  end

  parts[#parts + 1] = "<g transform=\"translate(" .. tostring(player.x) .. " " ..
    tostring(player.y) .. ")\"><polygon points=\"16,0 31,36 20,31 16,40 12,31 1,36\" fill=\"#46e6e1\"/>" ..
    "<rect x=\"13\" y=\"15\" width=\"6\" height=\"16\" fill=\"#ffffff\"/>" ..
    "<text x=\"16\" y=\"28\" fill=\"#07101f\" font-family=\"monospace\" font-size=\"8\" text-anchor=\"middle\">P</text></g>"
end

local function AppendExplosion(parts, explosion)
  local assetId = "explosion_0" .. tostring(explosion.frame)
  if not AppendAssetUse(parts, assetId, explosion.x, explosion.y) then
    parts[#parts + 1] = "<g transform=\"translate(" .. tostring(explosion.x) .. " " ..
      tostring(explosion.y) .. ")\"><path d=\"M16 0L20 11L32 16L20 21L16 32L12 21L0 16L12 11Z\" fill=\"#ff9b45\"/></g>"
  end
end

local function BuildGameSvg(state)
  local parts = {
    "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 320 480\" width=\"320\" height=\"480\" shape-rendering=\"crispEdges\">",
    "<rect width=\"320\" height=\"480\" fill=\"#07101f\"/>",
    "<defs>",
    ASSET_DEFINITIONS,
    "</defs>"
  }

  AppendBackground(parts, state)

  for index = 1, GAME_CONFIG.MaxEnemies do
    local enemy = state.enemies[index]
    if enemy.active then
      AppendEnemy(parts, enemy)
    end
  end

  for index = 1, #state.enemyBullets do
    local bullet = state.enemyBullets[index]
    if bullet.active then
      AppendEnemyBullet(parts, bullet)
    end
  end

  for index = 1, GAME_CONFIG.MaxPlayerBullets do
    local bullet = state.playerBullets[index]
    if bullet.active then
      AppendPlayerBullet(parts, bullet)
    end
  end

  AppendPlayer(parts, state.player)

  for index = 1, GAME_CONFIG.MaxExplosions do
    local explosion = state.explosions[index]
    if explosion.active then
      AppendExplosion(parts, explosion)
    end
  end

  parts[#parts + 1] = "<rect x=\"0\" y=\"0\" width=\"320\" height=\"30\" fill=\"#07101f\"/>"
  parts[#parts + 1] = "<text x=\"8\" y=\"20\" fill=\"#d7f7ff\" font-family=\"monospace\" font-size=\"12\">SCORE " ..
    tostring(state.score) .. "</text>"
  parts[#parts + 1] = "<text x=\"312\" y=\"20\" fill=\"#46e6e1\" font-family=\"monospace\" font-size=\"12\" text-anchor=\"end\">f5Rocket</text>"

  if state.paused then
    parts[#parts + 1] = "<rect x=\"78\" y=\"214\" width=\"164\" height=\"52\" fill=\"#07101f\" stroke=\"#ff9b45\"/>"
    parts[#parts + 1] = "<text x=\"160\" y=\"246\" fill=\"#ff9b45\" font-family=\"monospace\" font-size=\"18\" text-anchor=\"middle\">PAUSED</text>"
  elseif not state.running then
    parts[#parts + 1] = "<text x=\"160\" y=\"246\" fill=\"#d7f7ff\" font-family=\"monospace\" font-size=\"14\" text-anchor=\"middle\">PRESS START</text>"
  end

  parts[#parts + 1] = "</svg>"
  return table.concat(parts)
end

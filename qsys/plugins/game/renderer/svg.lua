local SVG_ROOT_OPEN =
  "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 320 480\" width=\"320\" height=\"480\" shape-rendering=\"crispEdges\">"

-- Asset and fallback definitions are assembled once when the plugin runtime
-- initializes. Per-frame serialization only emits positions, state, and HUD.
local GAME_SVG_PREFIX = SVG_ROOT_OPEN .. "<defs>" .. STATIC_RENDER_DEFINITIONS ..
  "</defs><rect width=\"320\" height=\"480\" fill=\"#07101f\"/>"

local function AppendBackground(parts, state)
  local offset = state.backgroundOffset
  AppendTranslatedUse(parts, "fallback_starfield", 0, offset - GAME_CONFIG.LogicalHeight)
  AppendTranslatedUse(parts, "fallback_starfield", 0, offset)
end

local function AppendEnemy(parts, enemy)
  AppendSpriteUse(parts, "enemy_01", "fallback_enemy", enemy.x, enemy.y)
end

local function AppendPlayerBullet(parts, bullet)
  AppendSpriteUse(parts, "bullet_player", "fallback_player_bullet", bullet.x, bullet.y)
end

local function AppendEnemyBullet(parts, bullet)
  AppendSpriteUse(parts, "bullet_enemy", "fallback_enemy_bullet", bullet.x, bullet.y)
end

local function AppendPlayer(parts, player)
  AppendDefinitionUse(parts, ResolvePlayerDefinition(player.direction), player.x, player.y)
end

local function AppendExplosion(parts, explosion)
  local assetId = "explosion_0" .. tostring(explosion.frame)
  AppendSpriteUse(parts, assetId, "fallback_explosion", explosion.x, explosion.y)
end

local function BuildGameSvg(state)
  local parts = { GAME_SVG_PREFIX }

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

  if not state.running then
    parts[#parts + 1] = "<text x=\"160\" y=\"246\" fill=\"#d7f7ff\" font-family=\"monospace\" font-size=\"14\" text-anchor=\"middle\">ENABLE RUN</text>"
  end

  parts[#parts + 1] = "</svg>"
  return table.concat(parts)
end

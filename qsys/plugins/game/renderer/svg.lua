local SVG_ROOT_OPEN =
  "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 320 480\" width=\"320\" height=\"480\" shape-rendering=\"crispEdges\">"

-- Asset and fallback definitions are assembled once when the plugin runtime
-- initializes. Per-frame serialization only emits positions, state, and HUD.
local GAME_SVG_PREFIX = SVG_ROOT_OPEN .. "<defs>" .. STATIC_RENDER_DEFINITIONS ..
  "</defs><rect width=\"320\" height=\"480\" fill=\"#07101f\"/>"

local TIMER_ONLY_SVG = SVG_ROOT_OPEN ..
  "<rect width=\"320\" height=\"480\" fill=\"#07101f\"/>" ..
  "<text x=\"160\" y=\"224\" fill=\"#46e6e1\" font-family=\"monospace\" font-size=\"16\" text-anchor=\"middle\">TIMER ONLY</text>" ..
  "<text x=\"160\" y=\"248\" fill=\"#d7f7ff\" font-family=\"monospace\" font-size=\"10\" text-anchor=\"middle\">VIEWPORT HELD STATIC</text></svg>"

local MINIMAL_SVG_PREFIX = SVG_ROOT_OPEN .. "<defs>" .. FALLBACK_PLAYER_DEFINITION ..
  "</defs><rect width=\"320\" height=\"480\" fill=\"#07101f\"/>" ..
  "<text x=\"160\" y=\"24\" fill=\"#46e6e1\" font-family=\"monospace\" font-size=\"12\" text-anchor=\"middle\">MINIMAL RENDER</text>" ..
  "<use href=\"#fallback_player\" x=\""
local MINIMAL_SVG_SUFFIX = "\" y=\"220\"/></svg>"

local function AppendBackground(parts, state)
  local definitionId = "fallback_starfield"
  if AssetAvailable("background_tile") then
    definitionId = "background_tile"
  end

  local offset = state.backgroundOffset
  AppendTranslatedUse(parts, definitionId, 0, offset - GAME_CONFIG.LogicalHeight)
  AppendTranslatedUse(parts, definitionId, 0, offset)
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

  if state.paused then
    parts[#parts + 1] = "<rect x=\"78\" y=\"214\" width=\"164\" height=\"52\" fill=\"#07101f\" stroke=\"#ff9b45\"/>"
    parts[#parts + 1] = "<text x=\"160\" y=\"246\" fill=\"#ff9b45\" font-family=\"monospace\" font-size=\"18\" text-anchor=\"middle\">PAUSED</text>"
  elseif not state.running then
    parts[#parts + 1] = "<text x=\"160\" y=\"246\" fill=\"#d7f7ff\" font-family=\"monospace\" font-size=\"14\" text-anchor=\"middle\">PRESS START</text>"
  end

  parts[#parts + 1] = "</svg>"
  return table.concat(parts)
end

local function BuildTimerOnlySvg()
  return TIMER_ONLY_SVG
end

local function BuildMinimalDiagnosticSvg(motionX)
  return MINIMAL_SVG_PREFIX .. tostring(math.floor(motionX)) .. MINIMAL_SVG_SUFFIX
end

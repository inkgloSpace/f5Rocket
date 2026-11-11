local SVG_ROOT_OPEN =
  "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 320 480\" width=\"320\" height=\"480\" shape-rendering=\"crispEdges\">"

-- The dynamic frame is intentionally transparent. Stage artwork lives in the
-- low-frequency BackgroundViewport and is never copied into this prefix.
local GAME_SVG_PREFIX = SVG_ROOT_OPEN .. "<defs>" ..
  DYNAMIC_GAMEPLAY_DEFINITIONS .. PARALLAX_SVG_DEFINITIONS .. "</defs>"

local FALLBACK_BACKGROUND_COLORS = {
  [1] = "#083b69",
  [2] = "#32145f",
  [3] = "#090d2a"
}

local function BuildStageBackgroundSvg(stageIndex)
  local profile = STAGE_PROFILES[stageIndex]
  local asset = ASSETS[profile.BackgroundAsset]
  local parts = { SVG_ROOT_OPEN }

  if asset ~= nil and asset.Available then
    parts[#parts + 1] = "<image href=\"" .. asset.DataUri ..
      "\" width=\"320\" height=\"480\" preserveAspectRatio=\"none\"/>"
  else
    parts[#parts + 1] = "<rect width=\"320\" height=\"480\" fill=\"" ..
      FALLBACK_BACKGROUND_COLORS[stageIndex] .. "\"/>"
    for index = 1, 28 do
      local x = (index * 47 + stageIndex * 19) % GAME_CONFIG.LogicalWidth
      local y = (index * 83 + stageIndex * 31) % GAME_CONFIG.LogicalHeight
      local size = 1 + (index % 2)
      parts[#parts + 1] = "<rect x=\"" .. tostring(x) .. "\" y=\"" ..
        tostring(y) .. "\" width=\"" .. tostring(size) .. "\" height=\"" ..
        tostring(size) .. "\" fill=\"#d7f7ff\"/>"
    end
  end

  parts[#parts + 1] = "</svg>"
  return table.concat(parts), profile.BackgroundAsset
end

local function AppendEnemy(parts, state, enemy)
  AppendDefinitionUse(parts, GetStageProfile(state).EnemyDefinition, enemy.x, enemy.y)
end

local function AppendPlayerBullet(parts, bullet)
  AppendDefinitionUse(parts, "player_bullet_visible", bullet.x, bullet.y)
end

local function AppendEnemyBullet(parts, bullet)
  AppendDefinitionUse(parts, "enemy_bullet_visible", bullet.x, bullet.y)
end

local function AppendPlayer(parts, player)
  local renderX = player.x - math.floor(
    (GAME_CONFIG.PlayerRenderWidth - player.width) / 2
  )
  local renderY = player.y - (GAME_CONFIG.PlayerRenderHeight - player.height)
  AppendDefinitionUse(parts, ResolvePlayerDefinition(player.direction), renderX, renderY)
end

local function AppendExplosion(parts, explosion)
  local assetId = "explosion_0" .. tostring(explosion.frame)
  AppendSpriteUse(parts, assetId, "fallback_explosion", explosion.x, explosion.y)
end

local function AppendBoss(parts, boss)
  AppendDefinitionUse(parts, ResolveBossDefinition(boss.bossType), boss.x, boss.y)
end

local function AppendHud(parts, state)
  local profile = GetStageProfile(state)
  local scoreText = string.format("%06d", state.score)

  parts[#parts + 1] = "<rect x=\"0\" y=\"0\" width=\"320\" height=\"31\" fill=\"#07101f\"/>"
  parts[#parts + 1] = "<text x=\"7\" y=\"19\" fill=\"#46e6e1\" font-family=\"monospace\" font-size=\"10\">Q-SYS</text>"
  parts[#parts + 1] = "<text x=\"160\" y=\"19\" fill=\"#d7f7ff\" font-family=\"monospace\" font-size=\"10\" text-anchor=\"middle\">" ..
    state.stageName .. "</text>"
  parts[#parts + 1] = "<text x=\"313\" y=\"19\" fill=\"#d7f7ff\" font-family=\"monospace\" font-size=\"10\" text-anchor=\"end\">SCORE " ..
    scoreText .. "</text>"

  if state.stagePhase == "WAVE" and not state.gameOver then
    local progress = math.min(state.stageScore, profile.ScoreThreshold)
    parts[#parts + 1] = "<text x=\"160\" y=\"44\" fill=\"#d7f7ff\" font-family=\"monospace\" font-size=\"9\" text-anchor=\"middle\">" ..
      tostring(progress) .. " / " .. tostring(profile.ScoreThreshold) .. "</text>"
  elseif state.stagePhase == "BOSS" and state.boss.active then
    local hpWidth = math.floor(120 * state.boss.hp / state.boss.maxHp)
    parts[#parts + 1] = "<text x=\"160\" y=\"44\" fill=\"#ff9bd5\" font-family=\"monospace\" font-size=\"9\" text-anchor=\"middle\">" ..
      state.boss.label .. "</text>"
    parts[#parts + 1] = "<rect x=\"100\" y=\"50\" width=\"120\" height=\"7\" fill=\"#33142a\" stroke=\"#d7f7ff\"/>"
    parts[#parts + 1] = "<rect x=\"100\" y=\"50\" width=\"" ..
      tostring(hpWidth) .. "\" height=\"7\" fill=\"#ff3d9b\"/>"
  end
end

local function AppendCenteredOverlay(parts, title, score, prompt)
  parts[#parts + 1] = "<rect x=\"36\" y=\"184\" width=\"248\" height=\"116\" fill=\"#07101f\" stroke=\"#ff5c9d\"/>"
  parts[#parts + 1] = "<text x=\"160\" y=\"218\" fill=\"#ff5c9d\" font-family=\"monospace\" font-size=\"18\" text-anchor=\"middle\">" ..
    title .. "</text>"
  parts[#parts + 1] = "<text x=\"160\" y=\"250\" fill=\"#d7f7ff\" font-family=\"monospace\" font-size=\"11\" text-anchor=\"middle\">FINAL SCORE " ..
    string.format("%06d", score) .. "</text>"
  parts[#parts + 1] = "<text x=\"160\" y=\"278\" fill=\"#46e6e1\" font-family=\"monospace\" font-size=\"9\" text-anchor=\"middle\">" ..
    prompt .. "</text>"
end

local function BuildGameSvg(state)
  local parts = { GAME_SVG_PREFIX }

  AppendFarParallax(parts, state)
  AppendMidParallax(parts, state)
  AppendNearParallax(parts, state)

  for index = 1, GAME_CONFIG.MaxEnemies do
    local enemy = state.enemies[index]
    if enemy.active then
      AppendEnemy(parts, state, enemy)
    end
  end

  if state.boss.active then
    AppendBoss(parts, state.boss)
  end

  for index = 1, GAME_CONFIG.MaxEnemyBullets do
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

  for index = 1, GAME_CONFIG.MaxExplosions do
    local explosion = state.explosions[index]
    if explosion.active and explosion.delayTicks <= 0 then
      AppendExplosion(parts, explosion)
    end
  end

  if state.player.alive then
    AppendPlayer(parts, state.player)
  end

  AppendHud(parts, state)

  if state.gameOver then
    AppendCenteredOverlay(parts, "GAME OVER", state.score, "PRESS RUN TO RESTART")
  elseif state.gameClear then
    AppendCenteredOverlay(parts, "MISSION COMPLETE", state.score, "PRESS RUN TO RESTART")
  elseif state.paused then
    parts[#parts + 1] = "<rect x=\"78\" y=\"205\" width=\"164\" height=\"62\" fill=\"#07101f\" stroke=\"#f5a623\"/>"
    parts[#parts + 1] = "<text x=\"160\" y=\"244\" fill=\"#f5a623\" font-family=\"monospace\" font-size=\"18\" text-anchor=\"middle\">PAUSED</text>"
  elseif state.stagePhase == "CLEAR" then
    parts[#parts + 1] = "<rect x=\"60\" y=\"205\" width=\"200\" height=\"62\" fill=\"#07101f\" stroke=\"#46e6e1\"/>"
    parts[#parts + 1] = "<text x=\"160\" y=\"244\" fill=\"#46e6e1\" font-family=\"monospace\" font-size=\"18\" text-anchor=\"middle\">STAGE CLEAR</text>"
  elseif not state.running then
    parts[#parts + 1] = "<text x=\"160\" y=\"246\" fill=\"#d7f7ff\" font-family=\"monospace\" font-size=\"14\" text-anchor=\"middle\">PRESS RUN</text>"
  end

  parts[#parts + 1] = "</svg>"
  return table.concat(parts)
end

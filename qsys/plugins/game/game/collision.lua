local function BoxesOverlap(first, second)
  return first.x < second.x + second.width and
    first.x + first.width > second.x and
    first.y < second.y + second.height and
    first.y + first.height > second.y
end

local function CheckPlayerBulletEnemyCollisions(state)
  for bulletIndex = 1, GAME_CONFIG.MaxPlayerBullets do
    local bullet = state.playerBullets[bulletIndex]
    if bullet.active then
      for enemyIndex = 1, GAME_CONFIG.MaxEnemies do
        local enemy = state.enemies[enemyIndex]
        if enemy.active and BoxesOverlap(bullet, enemy) then
          bullet.active = false
          RecycleEnemy(enemy)
          state.score = state.score + GAME_CONFIG.EnemyScore
          break
        end
      end
    end
  end
end

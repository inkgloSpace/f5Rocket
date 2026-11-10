local function ResetBoss(state)
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
end

local function SpawnBoss(state)
  local stageProfile = GetStageProfile(state)
  local profile = BOSS_PROFILES[stageProfile.BossType]
  local boss = state.boss

  boss.active = true
  boss.bossType = stageProfile.BossType
  boss.assetId = profile.Asset
  boss.label = profile.Label
  boss.width = profile.Width
  boss.height = profile.Height
  boss.x = math.floor((GAME_CONFIG.LogicalWidth - boss.width) / 2)
  boss.y = -boss.height
  boss.hp = profile.MaxHp
  boss.maxHp = profile.MaxHp
  boss.direction = 1
  boss.fireCooldown = profile.FireIntervalTicks
  boss.patternTick = 0
  boss.volleyCount = 0
  boss.entered = false
end

local function FireBossFan(state, boss, shotCount, bulletSpeed)
  local startX = boss.x + boss.width / 2
  local startY = boss.y + boss.height
  local centerIndex = (shotCount + 1) / 2

  for index = 1, shotCount do
    local angle = (index - centerIndex) * 0.24
    FireEnemyVectorBullet(
      state,
      startX,
      startY,
      math.sin(angle) * bulletSpeed,
      math.cos(angle) * bulletSpeed
    )
  end
end

local function FireBossPattern(state, boss, profile)
  boss.volleyCount = boss.volleyCount + 1

  if boss.bossType == "MINI_EASY" then
    FireEnemyAimedBullet(state, boss, profile.BulletSpeed)
  elseif boss.bossType == "MINI_MEDIUM" then
    FireBossFan(state, boss, 3, profile.BulletSpeed)
    if boss.volleyCount % 3 == 0 then
      FireEnemyAimedBullet(state, boss, profile.BulletSpeed)
    end
  else
    if boss.hp > boss.maxHp / 2 then
      FireBossFan(state, boss, 3, profile.BulletSpeed)
      if boss.volleyCount % 3 == 0 then
        FireEnemyAimedBullet(state, boss, profile.BulletSpeed)
      end
    else
      FireBossFan(state, boss, 5, profile.BulletSpeed)
      if boss.volleyCount % 2 == 0 then
        FireEnemyAimedBullet(state, boss, profile.BulletSpeed)
      end
    end
  end
end

local function UpdateBoss(state)
  local boss = state.boss
  if not boss.active then
    return
  end

  local profile = BOSS_PROFILES[boss.bossType]
  boss.patternTick = boss.patternTick + 1

  if not boss.entered then
    boss.y = boss.y + profile.EntrySpeed
    if boss.y >= profile.EntryY then
      boss.y = profile.EntryY
      boss.entered = true
    end
    return
  end

  local moveSpeed = profile.MoveSpeed
  if boss.bossType == "FINAL" and boss.hp <= boss.maxHp / 2 then
    moveSpeed = profile.EnragedMoveSpeed
  end

  boss.x = boss.x + boss.direction * moveSpeed
  local maximumX = GAME_CONFIG.LogicalWidth - boss.width
  if boss.x <= 0 then
    boss.x = 0
    boss.direction = 1
  elseif boss.x >= maximumX then
    boss.x = maximumX
    boss.direction = -1
  end

  boss.fireCooldown = boss.fireCooldown - 1
  if boss.fireCooldown <= 0 and state.player.alive then
    FireBossPattern(state, boss, profile)
    if boss.bossType == "FINAL" and boss.hp <= boss.maxHp / 2 then
      boss.fireCooldown = profile.EnragedFireIntervalTicks
    else
      boss.fireCooldown = profile.FireIntervalTicks
    end
  end
end

local function DefeatBoss(state)
  local boss = state.boss
  if not boss.active then
    return false
  end

  local profile = BOSS_PROFILES[boss.bossType]
  local leftX = boss.x + boss.width * 0.2 - GAME_CONFIG.ExplosionWidth / 2
  local rightX = boss.x + boss.width * 0.8 - GAME_CONFIG.ExplosionWidth / 2
  local centerX = boss.x + boss.width / 2 - GAME_CONFIG.ExplosionWidth / 2
  local upperY = boss.y + boss.height * 0.3 - GAME_CONFIG.ExplosionHeight / 2
  local centerY = boss.y + boss.height / 2 - GAME_CONFIG.ExplosionHeight / 2

  ScheduleExplosion(state, leftX, upperY, 0)
  ScheduleExplosion(state, rightX, upperY, 3)
  ScheduleExplosion(state, centerX, centerY, 6)
  ScheduleExplosion(state, centerX, centerY, 9)

  state.score = state.score + profile.Reward
  boss.active = false
  BeginStageClear(state)
  return true
end

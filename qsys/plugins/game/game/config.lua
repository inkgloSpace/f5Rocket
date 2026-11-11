local GAME_CONFIG = {
  LogicalWidth = 320,
  LogicalHeight = 480,
  UpdateHz = 30,
  UpdateInterval = 1 / 30,

  -- Project safety budget, not an official Q-SYS limit. Oversized dynamic
  -- frames are rejected before Base64 encoding or Viewport.Legend assignment.
  MaxRawSvgBytes = 64 * 1024,
  MaxRawBackgroundSvgBytes = 64 * 1024,
  BackgroundTileHeight = 480,

  -- One 30 Hz timer drives simulation every tick. Visual publication follows
  -- GAME, GAME, BACKGROUND phases for 20 Hz / 10 Hz output without overlap.
  RenderCycleTicks = 3,
  BackgroundRenderPhase = 2,

  -- Lightweight Q-SYS Debug Output diagnostics. Normal frames stay silent;
  -- the summary cadence is 10 seconds at 30 Hz.
  PerfSlowTickGapMs = 100,
  PerfSlowCallbackMs = 30,
  PerfSlowStepMs = 20,
  PerfSlowLogIntervalTicks = 30,
  PerfSummaryTicks = 300,

  PlayerWidth = 40,
  PlayerHeight = 48,
  PlayerRenderWidth = 56,
  PlayerRenderHeight = 84,
  PlayerSpeed = 5,
  PlayerDiagonalSpeed = 4,
  CardinalChordGraceTicks = 4,
  PlayerStartY = 414,

  PlayerBulletWidth = 6,
  PlayerBulletHeight = 14,
  PlayerBulletSpeed = 10,
  FireIntervalTicks = 5,
  MaxBurstShots = 5,
  BurstCooldownTicks = 30,
  BurstResetTicks = 15,

  EnemyWidth = 34,
  EnemyHeight = 34,
  EnemyFireStaggerTicks = 16,
  EnemyFireSafetyDistance = 72,
  EnemyFireRetryTicks = 5,

  EnemyBulletWidth = 6,
  EnemyBulletHeight = 14,

  ExplosionWidth = 44,
  ExplosionHeight = 44,
  ExplosionFrames = 3,
  ExplosionFrameTicks = 3,
  GameOverAnimationTicks = 9,
  StageClearTicks = 45,

  MaxEnemies = 8,
  MaxPlayerBullets = 24,
  MaxEnemyBullets = 32,
  MaxExplosions = 12,

  MaxFarParallax = 24,
  MaxMidParallax = 12,
  MaxNearParallax = 8,
  BossParallaxMultiplier = 0.35,
  StageClearParallaxMultiplier = 0.20,
  GameOverParallaxMultiplier = 0.15,
  GameClearParallaxMultiplier = 0.10
}

local PARALLAX_PROFILES = {
  [1] = {
    Name = "EASY",
    FarCount = 20,
    FarSpeedMin = 0.25,
    FarSpeedMax = 0.40,
    MidCount = 6,
    MidSpeedMin = 0.60,
    MidSpeedMax = 0.90,
    NearCount = 2,
    NearSpeedMin = 1.20,
    NearSpeedMax = 1.50
  },
  [2] = {
    Name = "MEDIUM",
    FarCount = 18,
    FarSpeedMin = 0.35,
    FarSpeedMax = 0.55,
    MidCount = 10,
    MidSpeedMin = 0.90,
    MidSpeedMax = 1.30,
    NearCount = 4,
    NearSpeedMin = 1.80,
    NearSpeedMax = 2.20
  },
  [3] = {
    Name = "HARD",
    FarCount = 16,
    FarSpeedMin = 0.45,
    FarSpeedMax = 0.70,
    MidCount = 10,
    MidSpeedMin = 1.20,
    MidSpeedMax = 1.70,
    NearCount = 6,
    NearSpeedMin = 2.50,
    NearSpeedMax = 3.20
  }
}

local STAGE_PROFILES = {
  [1] = {
    Name = "EASY",
    EnemyCount = 4,
    EnemyVerticalSpeed = 1.8,
    EnemySteerSpeed = 0.6,
    EnemyFireIntervalTicks = 75,
    EnemyBulletSpeed = 3.2,
    EnemyScore = 100,
    ScoreThreshold = 5000,
    EnemyAsset = "enemy_easy",
    EnemyDefinition = "enemy_easy_down",
    BackgroundAsset = "background_easy_loop",
    BackgroundScrollSpeed = 0.65,
    BossType = "MINI_EASY"
  },
  [2] = {
    Name = "MEDIUM",
    EnemyCount = 5,
    EnemyVerticalSpeed = 2.2,
    EnemySteerSpeed = 0.9,
    EnemyFireIntervalTicks = 55,
    EnemyBulletSpeed = 3.8,
    EnemyScore = 200,
    ScoreThreshold = 10000,
    EnemyAsset = "enemy_medium",
    EnemyDefinition = "enemy_medium_down",
    BackgroundAsset = "background_medium_loop",
    BackgroundScrollSpeed = 0.85,
    BossType = "MINI_MEDIUM"
  },
  [3] = {
    Name = "HARD",
    EnemyCount = 6,
    EnemyVerticalSpeed = 2.6,
    EnemySteerSpeed = 1.2,
    EnemyFireIntervalTicks = 40,
    EnemyBulletSpeed = 4.5,
    EnemyScore = 300,
    ScoreThreshold = 15000,
    EnemyAsset = "enemy_hard",
    EnemyDefinition = "enemy_hard_down",
    BackgroundAsset = "background_hard_loop",
    BackgroundScrollSpeed = 1.05,
    BossType = "FINAL"
  }
}

local BOSS_PROFILES = {
  MINI_EASY = {
    Asset = "mini_boss_easy",
    Label = "MINI BOSS 1",
    Width = 72,
    Height = 56,
    MaxHp = 20,
    EntryY = 55,
    EntrySpeed = 2,
    MoveSpeed = 1,
    FireIntervalTicks = 75,
    BulletSpeed = 3.2,
    Reward = 2500
  },
  MINI_MEDIUM = {
    Asset = "mini_boss_medium",
    Label = "MINI BOSS 2",
    Width = 88,
    Height = 64,
    MaxHp = 40,
    EntryY = 52,
    EntrySpeed = 2,
    MoveSpeed = 1.5,
    FireIntervalTicks = 55,
    BulletSpeed = 3.8,
    Reward = 5000
  },
  FINAL = {
    Asset = "final_boss",
    Label = "FINAL BOSS",
    Width = 120,
    Height = 80,
    MaxHp = 80,
    EntryY = 40,
    EntrySpeed = 2,
    MoveSpeed = 1.5,
    EnragedMoveSpeed = 2.4,
    FireIntervalTicks = 45,
    EnragedFireIntervalTicks = 28,
    BulletSpeed = 4.5,
    Reward = 15000
  }
}

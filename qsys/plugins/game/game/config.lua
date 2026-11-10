local GAME_CONFIG = {
  LogicalWidth = 320,
  LogicalHeight = 480,
  UpdateHz = 30,
  UpdateInterval = 1 / 30,

  -- Project safety budget, not an official Q-SYS limit. Oversized dynamic
  -- frames are rejected before Base64 encoding or Viewport.Legend assignment.
  MaxRawSvgBytes = 64 * 1024,

  PlayerWidth = 32,
  PlayerHeight = 40,
  PlayerSpeed = 4,
  PlayerDiagonalSpeed = 3,
  PlayerStartY = 420,

  PlayerBulletWidth = 6,
  PlayerBulletHeight = 12,
  PlayerBulletSpeed = 9,
  FireIntervalTicks = 5,

  EnemyWidth = 28,
  EnemyHeight = 28,
  EnemySpeed = 2,
  InitialEnemyCount = 4,
  EnemyScore = 100,

  BackgroundScrollPerTick = 1,

  MaxEnemies = 8,
  MaxPlayerBullets = 24,
  MaxEnemyBullets = 0,
  MaxExplosions = 8
}

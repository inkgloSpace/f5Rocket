import { CONFIG, POOL_SIZES, STRESS_LEVELS } from "./config.js";

function makeEnemyPool(count) {
  const enemies = [];

  for (let index = 0; index < count; index += 1) {
    enemies.push({
      active: false,
      synthetic: false,
      x: 0,
      y: 0,
      width: 30,
      height: 28,
      velocityY: 60,
      slot: index,
    });
  }

  return enemies;
}

function makeBulletPool(count, owner) {
  const bullets = [];

  for (let index = 0; index < count; index += 1) {
    bullets.push({
      active: false,
      synthetic: false,
      owner,
      x: 0,
      y: 0,
      width: owner === "player" ? 4 : 6,
      height: owner === "player" ? 12 : 8,
      velocityY: owner === "player" ? -300 : 150,
      slot: index,
    });
  }

  return bullets;
}

function makeExplosionPool(count) {
  const explosions = [];

  for (let index = 0; index < count; index += 1) {
    explosions.push({
      active: false,
      x: 0,
      y: 0,
      width: 32,
      height: 32,
      age: 0,
      duration: 0.3,
      frame: 0,
    });
  }

  return explosions;
}

function makeStars(count) {
  const stars = [];
  let seed = 0x5f3759df;

  for (let index = 0; index < count; index += 1) {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    const x = seed % CONFIG.logicalWidth;
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    const y = seed % CONFIG.logicalHeight;
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    const layer = seed % 3;

    stars.push({
      x,
      y,
      initialY: y,
      size: layer === 2 ? 2 : 1,
      velocityY: 15 + layer * 15,
      brightness: 0.42 + layer * 0.23,
    });
  }

  return stars;
}

function clearPool(pool) {
  for (let index = 0; index < pool.length; index += 1) {
    pool[index].active = false;
    pool[index].synthetic = false;
  }
}

function resetStars(stars) {
  for (let index = 0; index < stars.length; index += 1) {
    stars[index].y = stars[index].initialY;
  }
}

function configureNormalEnemy(game) {
  const enemy = game.enemies[0];
  enemy.active = true;
  enemy.synthetic = false;
  enemy.x = 145;
  enemy.y = 42;
  enemy.velocityY = 60;
}

export function createGame() {
  const game = {
    running: true,
    paused: false,
    score: 0,
    time: 0,
    stressLevel: 1,
    respawnSerial: 0,
    player: {
      x: 144,
      y: 420,
      width: 32,
      height: 40,
      speed: 120,
      direction: 0,
      fireCooldown: 0,
      fireInterval: 0.18,
    },
    enemies: makeEnemyPool(POOL_SIZES.enemies),
    playerBullets: makeBulletPool(POOL_SIZES.playerBullets, "player"),
    enemyBullets: makeBulletPool(POOL_SIZES.enemyBullets, "enemy"),
    explosions: makeExplosionPool(POOL_SIZES.explosions),
    background: {
      tileOffset: 0,
      stars: makeStars(64),
    },
  };

  configureNormalEnemy(game);
  return game;
}

export function restartGame(game) {
  game.running = true;
  game.paused = false;
  game.score = 0;
  game.time = 0;
  game.stressLevel = 1;
  game.respawnSerial = 0;
  game.player.x = 144;
  game.player.y = 420;
  game.player.direction = 0;
  game.player.fireCooldown = 0;
  game.background.tileOffset = 0;

  clearPool(game.enemies);
  clearPool(game.playerBullets);
  clearPool(game.enemyBullets);
  clearPool(game.explosions);
  resetStars(game.background.stars);
  configureNormalEnemy(game);
}

export function togglePause(game) {
  if (game.running) {
    game.paused = !game.paused;
  }
}

function configureSyntheticEnemy(enemy, index) {
  const usableWidth = CONFIG.logicalWidth - enemy.width;
  enemy.active = true;
  enemy.synthetic = true;
  enemy.x = (index * 53 + 17) % usableWidth;
  enemy.y = 30 + (index % 8) * 44;
  enemy.velocityY = 42 + (index % 4) * 6;
}

function configureSyntheticBullet(bullet, index, total, owner) {
  const usableWidth = CONFIG.logicalWidth - bullet.width;
  bullet.active = true;
  bullet.synthetic = true;
  bullet.x = (index * 29 + (owner === "player" ? 11 : 23)) % usableWidth;
  bullet.y = 58 + ((index * 37) % 380);

  if (owner === "player") {
    bullet.velocityY = -150 - (index % 3) * 30;
  } else {
    bullet.velocityY = 105 + (index % 3) * 30;
  }

  // Keep this argument explicit to mirror a future Lua setup loop.
  if (total === 0) {
    bullet.active = false;
  }
}

export function setStressLevel(game, level) {
  const settings = STRESS_LEVELS[level];

  if (!settings) {
    return;
  }

  clearPool(game.enemies);
  clearPool(game.playerBullets);
  clearPool(game.enemyBullets);
  clearPool(game.explosions);
  game.stressLevel = level;

  if (level === 1) {
    configureNormalEnemy(game);
    return;
  }

  for (let index = 0; index < settings.enemies; index += 1) {
    configureSyntheticEnemy(game.enemies[index], index);
  }

  const playerBulletCount = Math.ceil(settings.bullets * 2 / 3);
  const enemyBulletCount = settings.bullets - playerBulletCount;

  for (let index = 0; index < playerBulletCount; index += 1) {
    configureSyntheticBullet(game.playerBullets[index], index, settings.bullets, "player");
  }

  for (let index = 0; index < enemyBulletCount; index += 1) {
    configureSyntheticBullet(game.enemyBullets[index], index, settings.bullets, "enemy");
  }
}

function updateBackground(game, deltaSeconds) {
  const background = game.background;
  background.tileOffset = (background.tileOffset + 30 * deltaSeconds) % CONFIG.logicalHeight;

  for (let index = 0; index < background.stars.length; index += 1) {
    const star = background.stars[index];
    star.y += star.velocityY * deltaSeconds;

    if (star.y >= CONFIG.logicalHeight) {
      star.y -= CONFIG.logicalHeight;
    }
  }
}

function updatePlayer(game, controls, deltaSeconds) {
  const player = game.player;
  let moveX = 0;
  let moveY = 0;

  if (controls.left) {
    moveX -= 1;
  }
  if (controls.right) {
    moveX += 1;
  }
  if (controls.up) {
    moveY -= 1;
  }
  if (controls.down) {
    moveY += 1;
  }

  if (moveX !== 0 && moveY !== 0) {
    moveX *= 0.70710678;
    moveY *= 0.70710678;
  }

  player.x = Math.round(player.x + moveX * player.speed * deltaSeconds);
  player.y = Math.round(player.y + moveY * player.speed * deltaSeconds);
  player.x = Math.max(0, Math.min(CONFIG.logicalWidth - player.width, player.x));
  player.y = Math.max(0, Math.min(CONFIG.logicalHeight - player.height, player.y));
  player.direction = moveX < 0 ? -1 : moveX > 0 ? 1 : 0;
}

function spawnPlayerBullet(game) {
  const pool = game.playerBullets;

  for (let index = 0; index < pool.length; index += 1) {
    const bullet = pool[index];

    if (!bullet.active) {
      bullet.active = true;
      bullet.synthetic = false;
      bullet.x = Math.round(game.player.x + game.player.width / 2 - bullet.width / 2);
      bullet.y = game.player.y - bullet.height;
      bullet.velocityY = -300;
      return true;
    }
  }

  return false;
}

function updateFiring(game, controls, deltaSeconds) {
  const player = game.player;
  player.fireCooldown = Math.max(0, player.fireCooldown - deltaSeconds);

  if (controls.fire && player.fireCooldown <= 0) {
    if (spawnPlayerBullet(game)) {
      player.fireCooldown = player.fireInterval;
    }
  }
}

function respawnEnemy(game, enemy) {
  game.respawnSerial += 1;
  enemy.x = (enemy.slot * 67 + game.respawnSerial * 37) % (CONFIG.logicalWidth - enemy.width);
  enemy.y = enemy.synthetic ? -enemy.height - (enemy.slot % 5) * 16 : -enemy.height;
}

function updateEnemies(game, deltaSeconds) {
  for (let index = 0; index < game.enemies.length; index += 1) {
    const enemy = game.enemies[index];

    if (!enemy.active) {
      continue;
    }

    enemy.y += enemy.velocityY * deltaSeconds;

    if (enemy.y > CONFIG.logicalHeight) {
      respawnEnemy(game, enemy);
    }
  }
}

function updateBulletPool(pool, deltaSeconds) {
  for (let index = 0; index < pool.length; index += 1) {
    const bullet = pool[index];

    if (!bullet.active) {
      continue;
    }

    bullet.y += bullet.velocityY * deltaSeconds;

    if (bullet.velocityY < 0 && bullet.y + bullet.height < 0) {
      if (bullet.synthetic) {
        bullet.y = CONFIG.logicalHeight + (bullet.slot % 7) * 12;
      } else {
        bullet.active = false;
      }
    } else if (bullet.velocityY > 0 && bullet.y > CONFIG.logicalHeight) {
      if (bullet.synthetic) {
        bullet.y = -bullet.height - (bullet.slot % 7) * 12;
      } else {
        bullet.active = false;
      }
    }
  }
}

function updateExplosions(game, deltaSeconds) {
  for (let index = 0; index < game.explosions.length; index += 1) {
    const explosion = game.explosions[index];

    if (!explosion.active) {
      continue;
    }

    explosion.age += deltaSeconds;
    explosion.frame = Math.min(2, Math.floor(explosion.age / explosion.duration * 3));

    if (explosion.age >= explosion.duration) {
      explosion.active = false;
    }
  }
}

export function updateGame(game, controls, deltaSeconds) {
  if (!game.running || game.paused) {
    return;
  }

  game.time += deltaSeconds;
  updateBackground(game, deltaSeconds);
  updatePlayer(game, controls, deltaSeconds);
  updateFiring(game, controls, deltaSeconds);
  updateEnemies(game, deltaSeconds);
  updateBulletPool(game.playerBullets, deltaSeconds);
  updateBulletPool(game.enemyBullets, deltaSeconds);
  updateExplosions(game, deltaSeconds);
}

function countActive(pool) {
  let count = 0;

  for (let index = 0; index < pool.length; index += 1) {
    if (pool[index].active) {
      count += 1;
    }
  }

  return count;
}

export function getActiveCounts(game) {
  const enemies = countActive(game.enemies);
  const playerBullets = countActive(game.playerBullets);
  const enemyBullets = countActive(game.enemyBullets);
  const explosions = countActive(game.explosions);
  const bullets = playerBullets + enemyBullets;

  return {
    enemies,
    playerBullets,
    enemyBullets,
    bullets,
    explosions,
    totalVisuals: 1 + game.background.stars.length + enemies + bullets + explosions,
  };
}

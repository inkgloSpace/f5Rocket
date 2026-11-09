import { CONFIG, STRESS_LEVELS } from "./config.js";

function integer(value) {
  return Math.round(value);
}

function escapeAttribute(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll('"', "&quot;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;");
}

function imageNode(entry, width, height) {
  return `<image href="${escapeAttribute(entry.dataUri)}" x="0" y="0" width="${width}" height="${height}" preserveAspectRatio="none"/>`;
}

function hasEmbeddedPng(entry) {
  return entry.available && entry.mimeType === "image/png" && entry.dataUri.startsWith("data:image/png;base64,");
}

function addBackground(parts, game, assets) {
  parts.push('<rect width="320" height="480" fill="#07101f"/>');

  if (hasEmbeddedPng(assets.background.tile)) {
    const offset = integer(game.background.tileOffset);
    parts.push(`<g transform="translate(0 ${offset - CONFIG.logicalHeight})">${imageNode(assets.background.tile, 320, 480)}</g>`);
    parts.push(`<g transform="translate(0 ${offset})">${imageNode(assets.background.tile, 320, 480)}</g>`);
    return;
  }

  parts.push('<g id="starfield" fill="#c9ffff">');
  const stars = game.background.stars;

  for (let index = 0; index < stars.length; index += 1) {
    const star = stars[index];
    parts.push(`<rect x="${star.x}" y="${integer(star.y)}" width="${star.size}" height="${star.size}" opacity="${star.brightness.toFixed(2)}"/>`);
  }

  parts.push("</g>");
}

function addDecorations(parts) {
  parts.push(
    '<g id="decorations" fill="none" stroke="#2b5770" stroke-width="1" opacity="0.24">',
    '<path d="M0 120H320M0 240H320M0 360H320"/>',
    '<path d="M80 0V480M160 0V480M240 0V480"/>',
    "</g>",
    '<rect x="3" y="3" width="314" height="474" fill="none" stroke="#46e6e1" stroke-width="1" opacity="0.2"/>'
  );
}

function addEnemyPlaceholder(parts, enemy) {
  const testLabel = enemy.synthetic
    ? '<text x="15" y="19" fill="#fff2cb" font-size="6" text-anchor="middle">TEST</text>'
    : '<text x="15" y="19" fill="#fff2cb" font-size="6" text-anchor="middle">ENEMY</text>';

  parts.push(
    `<g transform="translate(${integer(enemy.x)} ${integer(enemy.y)})">`,
    '<polygon points="15,27 2,8 8,3 15,7 22,3 28,8" fill="#ff496c" stroke="#ffd15c" stroke-width="1"/>',
    '<rect x="11" y="0" width="8" height="18" fill="#c91f4e"/>',
    testLabel,
    "</g>"
  );
}

function addEnemies(parts, game, assets) {
  parts.push('<g id="enemies">');

  for (let index = 0; index < game.enemies.length; index += 1) {
    const enemy = game.enemies[index];

    if (!enemy.active) {
      continue;
    }

    if (hasEmbeddedPng(assets.enemy.basic)) {
      parts.push(`<g transform="translate(${integer(enemy.x)} ${integer(enemy.y)})">${imageNode(assets.enemy.basic, enemy.width, enemy.height)}</g>`);
    } else {
      addEnemyPlaceholder(parts, enemy);
    }
  }

  parts.push("</g>");
}

function addBulletPool(parts, pool, asset, color, testColor) {
  for (let index = 0; index < pool.length; index += 1) {
    const bullet = pool[index];

    if (!bullet.active) {
      continue;
    }

    const x = integer(bullet.x);
    const y = integer(bullet.y);

    if (hasEmbeddedPng(asset)) {
      parts.push(`<g transform="translate(${x} ${y})">${imageNode(asset, bullet.width, bullet.height)}</g>`);
    } else {
      const fill = bullet.synthetic ? testColor : color;
      parts.push(`<rect x="${x}" y="${y}" width="${bullet.width}" height="${bullet.height}" fill="${fill}"/>`);
    }
  }
}

function addBullets(parts, game, assets) {
  parts.push('<g id="enemy-bullets">');
  addBulletPool(parts, game.enemyBullets, assets.bullet.enemy, "#ff6b59", "#ff9b45");
  parts.push('</g><g id="player-bullets">');
  addBulletPool(parts, game.playerBullets, assets.bullet.player, "#8dfff2", "#ffd15c");
  parts.push("</g>");
}

function playerAssetForDirection(player, assets) {
  if (player.direction < 0 && hasEmbeddedPng(assets.player.left)) {
    return assets.player.left;
  }
  if (player.direction > 0 && hasEmbeddedPng(assets.player.right)) {
    return assets.player.right;
  }
  return assets.player.idle;
}

function addPlayer(parts, game, assets) {
  const player = game.player;
  const asset = playerAssetForDirection(player, assets);
  const x = integer(player.x);
  const y = integer(player.y);

  parts.push(`<g id="player" transform="translate(${x} ${y})">`);

  if (hasEmbeddedPng(asset)) {
    parts.push(imageNode(asset, player.width, player.height));
  } else {
    parts.push(
      '<polygon points="16,0 22,14 31,30 21,27 16,39 11,27 1,30 10,14" fill="#46e6e1" stroke="#f4f1df" stroke-width="1"/>',
      '<rect x="13" y="11" width="6" height="18" fill="#147a93"/>',
      '<rect x="11" y="30" width="10" height="5" fill="#ff9b45"/>',
      '<text x="16" y="23" fill="#07101f" font-size="6" font-weight="700" text-anchor="middle">P1</text>'
    );
  }

  parts.push("</g>");
}

function addExplosions(parts, game, assets) {
  parts.push('<g id="explosions">');

  for (let index = 0; index < game.explosions.length; index += 1) {
    const explosion = game.explosions[index];

    if (!explosion.active) {
      continue;
    }

    const x = integer(explosion.x);
    const y = integer(explosion.y);
    const frameAsset = assets.explosion[explosion.frame];
    parts.push(`<g transform="translate(${x} ${y})">`);

    if (frameAsset && hasEmbeddedPng(frameAsset)) {
      parts.push(imageNode(frameAsset, explosion.width, explosion.height));
    } else {
      const radius = 5 + explosion.frame * 4;
      parts.push(`<rect x="${16 - radius}" y="${16 - radius}" width="${radius * 2}" height="${radius * 2}" fill="#ffd15c" stroke="#ff496c" stroke-width="3"/>`);
    }

    parts.push("</g>");
  }

  parts.push("</g>");
}

function addHud(parts, game) {
  const score = String(game.score).padStart(6, "0");
  const stressLabel = STRESS_LEVELS[game.stressLevel].label;

  parts.push(
    '<g id="hud" font-family="monospace">',
    '<rect x="8" y="8" width="116" height="24" fill="#07101f" stroke="#2b5770" stroke-width="1" opacity="0.9"/>',
    `<text x="15" y="24" fill="#f4f1df" font-size="11" font-weight="700">SCORE ${score}</text>`,
    '<text x="312" y="23" fill="#46e6e1" font-size="9" text-anchor="end">30 HZ</text>'
  );

  if (game.stressLevel > 1) {
    parts.push(
      '<rect x="94" y="452" width="132" height="18" fill="#3b1f18" stroke="#ff9b45" stroke-width="1"/>',
      `<text x="160" y="464" fill="#ffcf96" font-size="8" font-weight="700" text-anchor="middle">${stressLabel}</text>`
    );
  }

  if (game.paused) {
    parts.push(
      '<rect x="58" y="208" width="204" height="64" fill="#07101f" stroke="#46e6e1" stroke-width="2"/>',
      '<text x="160" y="237" fill="#f4f1df" font-size="18" font-weight="700" text-anchor="middle">PAUSED</text>',
      '<text x="160" y="255" fill="#8fa4bb" font-size="8" text-anchor="middle">PRESS P TO RESUME</text>'
    );
  }

  parts.push("</g>");
}

export function renderGameSvg(game, assets) {
  const parts = [
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 480" width="320" height="480" shape-rendering="crispEdges" aria-label="f5Rocket generated game scene">',
  ];

  addBackground(parts, game, assets);
  addDecorations(parts);
  addEnemies(parts, game, assets);
  addBullets(parts, game, assets);
  addPlayer(parts, game, assets);
  addExplosions(parts, game, assets);
  addHud(parts, game);
  parts.push("</svg>");
  return parts.join("");
}

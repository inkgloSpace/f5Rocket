const ASSET_PATHS = Object.freeze({
  player: Object.freeze({
    idle: "assets/player/player_idle.png",
    left: "assets/player/player_left.png",
    right: "assets/player/player_right.png",
  }),
  enemy: Object.freeze({
    basic: "assets/enemy/enemy_01.png",
  }),
  bullet: Object.freeze({
    player: "assets/bullet/player_bullet.png",
    enemy: "assets/bullet/enemy_bullet.png",
  }),
  explosion: Object.freeze([
    "assets/explosion/explosion_01.png",
    "assets/explosion/explosion_02.png",
    "assets/explosion/explosion_03.png",
  ]),
  background: Object.freeze({
    tile: "assets/background/background_tile.png",
  }),
});

function createEntry(path) {
  return {
    path,
    available: false,
    width: 0,
    height: 0,
  };
}

export function createAssetCatalog() {
  return {
    player: {
      idle: createEntry(ASSET_PATHS.player.idle),
      left: createEntry(ASSET_PATHS.player.left),
      right: createEntry(ASSET_PATHS.player.right),
    },
    enemy: {
      basic: createEntry(ASSET_PATHS.enemy.basic),
    },
    bullet: {
      player: createEntry(ASSET_PATHS.bullet.player),
      enemy: createEntry(ASSET_PATHS.bullet.enemy),
    },
    explosion: [
      createEntry(ASSET_PATHS.explosion[0]),
      createEntry(ASSET_PATHS.explosion[1]),
      createEntry(ASSET_PATHS.explosion[2]),
    ],
    background: {
      tile: createEntry(ASSET_PATHS.background.tile),
    },
  };
}

function collectEntries(catalog) {
  return [
    catalog.player.idle,
    catalog.player.left,
    catalog.player.right,
    catalog.enemy.basic,
    catalog.bullet.player,
    catalog.bullet.enemy,
    catalog.explosion[0],
    catalog.explosion[1],
    catalog.explosion[2],
    catalog.background.tile,
  ];
}

function probeImage(entry) {
  return new Promise((resolve) => {
    const image = new Image();

    image.onload = function onLoad() {
      entry.available = true;
      entry.width = image.naturalWidth;
      entry.height = image.naturalHeight;
      resolve(true);
    };

    image.onerror = function onError() {
      // Missing artwork is expected during Phase 1; SVG placeholders remain active.
      entry.available = false;
      resolve(false);
    };

    image.src = entry.path;
  });
}

export function loadAssetCatalog(catalog) {
  const entries = collectEntries(catalog);
  const probes = [];

  for (let index = 0; index < entries.length; index += 1) {
    probes.push(probeImage(entries[index]));
  }

  return Promise.all(probes).then(function summarize(results) {
    let loaded = 0;

    for (let index = 0; index < results.length; index += 1) {
      if (results[index]) {
        loaded += 1;
      }
    }

    return { loaded, total: entries.length };
  });
}

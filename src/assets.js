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

function createEntry(path, values = {}) {
  return Object.freeze({
    path,
    available: values.available === true,
    status: values.status || "pending",
    mimeType: values.mimeType || "",
    dataUri: values.dataUri || "",
    sourceBytes: values.sourceBytes || 0,
    encodedBytes: values.encodedBytes || 0,
    dataUriBytes: values.dataUriBytes || 0,
    width: values.width || 0,
    height: values.height || 0,
    error: values.error || "",
  });
}

function buildCatalog(entries) {
  return Object.freeze({
    player: Object.freeze({
      idle: entries[0],
      left: entries[1],
      right: entries[2],
    }),
    enemy: Object.freeze({
      basic: entries[3],
    }),
    bullet: Object.freeze({
      player: entries[4],
      enemy: entries[5],
    }),
    explosion: Object.freeze([entries[6], entries[7], entries[8]]),
    background: Object.freeze({
      tile: entries[9],
    }),
  });
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

export function createAssetCatalog() {
  return buildCatalog([
    createEntry(ASSET_PATHS.player.idle),
    createEntry(ASSET_PATHS.player.left),
    createEntry(ASSET_PATHS.player.right),
    createEntry(ASSET_PATHS.enemy.basic),
    createEntry(ASSET_PATHS.bullet.player),
    createEntry(ASSET_PATHS.bullet.enemy),
    createEntry(ASSET_PATHS.explosion[0]),
    createEntry(ASSET_PATHS.explosion[1]),
    createEntry(ASSET_PATHS.explosion[2]),
    createEntry(ASSET_PATHS.background.tile),
  ]);
}

function isPngBuffer(buffer) {
  const bytes = new Uint8Array(buffer);
  const signature = [137, 80, 78, 71, 13, 10, 26, 10];

  if (bytes.length < signature.length) {
    return false;
  }

  for (let index = 0; index < signature.length; index += 1) {
    if (bytes[index] !== signature[index]) {
      return false;
    }
  }

  return true;
}

function bufferToBase64(buffer) {
  const bytes = new Uint8Array(buffer);
  const chunkSize = 0x8000;
  let binary = "";

  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    const chunk = bytes.subarray(offset, Math.min(offset + chunkSize, bytes.length));
    binary += String.fromCharCode(...chunk);
  }

  return btoa(binary);
}

function readImageDimensions(dataUri) {
  return new Promise((resolve, reject) => {
    const image = new Image();

    image.onload = function onLoad() {
      resolve({ width: image.naturalWidth, height: image.naturalHeight });
    };

    image.onerror = function onError() {
      reject(new Error("PNG could not be decoded"));
    };

    image.src = dataUri;
  });
}

async function prepareEntry(entry) {
  try {
    // One fetch and one Base64 conversion per configured PNG, outside the game loop.
    const response = await fetch(entry.path);

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    const buffer = await response.arrayBuffer();

    if (!isPngBuffer(buffer)) {
      throw new Error("File is not a valid PNG");
    }

    const mimeType = "image/png";
    const base64 = bufferToBase64(buffer);
    const dataUri = `data:${mimeType};base64,${base64}`;
    const dimensions = await readImageDimensions(dataUri);

    return createEntry(entry.path, {
      available: true,
      status: "ready",
      mimeType,
      dataUri,
      sourceBytes: buffer.byteLength,
      encodedBytes: base64.length,
      dataUriBytes: dataUri.length,
      width: dimensions.width,
      height: dimensions.height,
    });
  } catch (error) {
    return createEntry(entry.path, {
      status: "missing",
      error: error instanceof Error ? error.message : String(error),
    });
  }
}

export function summarizeAssetCatalog(catalog) {
  const entries = collectEntries(catalog);
  const missing = [];
  let loaded = 0;
  let pending = 0;
  let sourceBytes = 0;
  let encodedBytes = 0;
  let dataUriBytes = 0;

  for (let index = 0; index < entries.length; index += 1) {
    const entry = entries[index];

    if (entry.available) {
      loaded += 1;
      sourceBytes += entry.sourceBytes;
      encodedBytes += entry.encodedBytes;
      dataUriBytes += entry.dataUriBytes;
    } else if (entry.status === "pending") {
      pending += 1;
    } else {
      missing.push(Object.freeze({ path: entry.path, error: entry.error }));
    }
  }

  return Object.freeze({
    ready: pending === 0,
    loaded,
    total: entries.length,
    pending,
    sourceBytes,
    encodedBytes,
    dataUriBytes,
    missing: Object.freeze(missing),
  });
}

export async function loadAssetCatalog(catalog) {
  const entries = collectEntries(catalog);
  const probes = [];

  for (let index = 0; index < entries.length; index += 1) {
    probes.push(prepareEntry(entries[index]));
  }

  const preparedEntries = await Promise.all(probes);
  const preparedCatalog = buildCatalog(preparedEntries);

  return Object.freeze({
    catalog: preparedCatalog,
    summary: summarizeAssetCatalog(preparedCatalog),
  });
}

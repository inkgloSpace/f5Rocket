import {
  CONFIG,
  RENDER_STEP_MS,
  UPDATE_STEP_MS,
  UPDATE_STEP_SECONDS,
} from "./config.js";
import {
  createAssetCatalog,
  loadAssetCatalog,
  summarizeAssetCatalog,
} from "./assets.js";
import {
  createDebugMonitor,
  estimateBase64Bytes,
  getRenderMode,
  measureUtf8Bytes,
} from "./debug.js";
import {
  createGame,
  getActiveCounts,
  restartGame,
  setStressLevel,
  togglePause,
  updateGame,
} from "./game.js";
import { createKeyboardInput } from "./input.js";
import { renderGameSvg } from "./renderer-svg.js";

const viewport = document.querySelector("#gameViewport");
const debugPanel = document.querySelector("#debugPanel");
const game = createGame();
const input = createKeyboardInput(window);
const debugMonitor = createDebugMonitor(debugPanel);
const controls = { left: false, right: false, up: false, down: false, fire: false };

let assets = createAssetCatalog();
let assetSummary = summarizeAssetCatalog(assets);
let debugVisible = CONFIG.debugMode;
let previousTime = performance.now();
let updateAccumulator = 0;
let renderAccumulator = RENDER_STEP_MS;
let lastSvg = "";
let lastDiagnostics = {
  svgRawBytes: 0,
  svgBase64Bytes: 0,
  generationMs: 0,
};
let lastDebugRefresh = Number.NEGATIVE_INFINITY;

debugMonitor.setVisible(debugVisible);

function consumeOneShotControls() {
  if (input.consume("restart")) {
    restartGame(game);
  }
  if (input.consume("pause")) {
    togglePause(game);
  }
  if (input.consume("debug")) {
    debugVisible = !debugVisible;
    debugMonitor.setVisible(debugVisible);
  }
  if (input.consume("stress1")) {
    setStressLevel(game, 1);
  }
  if (input.consume("stress2")) {
    setStressLevel(game, 2);
  }
  if (input.consume("stress3")) {
    setStressLevel(game, 3);
  }
  if (input.consume("stress4")) {
    setStressLevel(game, 4);
  }
}

function copyContinuousControls() {
  controls.left = input.isDown("left");
  controls.right = input.isDown("right");
  controls.up = input.isDown("up");
  controls.down = input.isDown("down");
  controls.fire = input.isDown("fire");
}

function runFixedUpdate() {
  const started = performance.now();
  consumeOneShotControls();
  copyContinuousControls();
  updateGame(game, controls, UPDATE_STEP_SECONDS);
  debugMonitor.recordUpdate(performance.now() - started);
}

function renderFrame(now) {
  const generationStarted = performance.now();
  const svg = renderGameSvg(game, assets);
  const generationMs = performance.now() - generationStarted;
  const svgRawBytes = measureUtf8Bytes(svg);

  lastSvg = svg;
  lastDiagnostics = {
    svgRawBytes,
    svgBase64Bytes: estimateBase64Bytes(svgRawBytes),
    generationMs,
  };
  viewport.innerHTML = svg;
  debugMonitor.recordRender(generationMs);

  if (now - lastDebugRefresh >= 200) {
    debugMonitor.refresh(game, getActiveCounts(game), lastDiagnostics, assetSummary);
    lastDebugRefresh = now;
  }
}

function scheduler(now) {
  let elapsed = now - previousTime;
  previousTime = now;

  if (elapsed > CONFIG.maxFrameDeltaMs) {
    elapsed = CONFIG.maxFrameDeltaMs;
  }

  debugMonitor.recordScheduler(elapsed);
  updateAccumulator += elapsed;
  renderAccumulator += elapsed;

  let updates = 0;
  while (updateAccumulator >= UPDATE_STEP_MS && updates < CONFIG.maxUpdatesPerSchedulerFrame) {
    runFixedUpdate();
    updateAccumulator -= UPDATE_STEP_MS;
    updates += 1;
  }

  if (updates === CONFIG.maxUpdatesPerSchedulerFrame && updateAccumulator >= UPDATE_STEP_MS) {
    updateAccumulator %= UPDATE_STEP_MS;
  }

  if (renderAccumulator >= RENDER_STEP_MS) {
    renderFrame(now);
    renderAccumulator %= RENDER_STEP_MS;
  }

  window.requestAnimationFrame(scheduler);
}

function copyAssetSummary() {
  const missing = [];

  for (let index = 0; index < assetSummary.missing.length; index += 1) {
    const item = assetSummary.missing[index];
    missing.push({ path: item.path, error: item.error });
  }

  return {
    ready: assetSummary.ready,
    loaded: assetSummary.loaded,
    total: assetSummary.total,
    pending: assetSummary.pending,
    sourceBytes: assetSummary.sourceBytes,
    encodedBytes: assetSummary.encodedBytes,
    dataUriBytes: assetSummary.dataUriBytes,
    missing,
  };
}

function getPublicDiagnostics() {
  return {
    svgRawBytes: lastDiagnostics.svgRawBytes,
    svgBase64Bytes: lastDiagnostics.svgBase64Bytes,
    generationMs: lastDiagnostics.generationMs,
    renderMode: getRenderMode(assetSummary),
    objectCounts: getActiveCounts(game),
    assets: copyAssetSummary(),
  };
}

function benchmarkStressLevels(iterations = 120) {
  const numericIterations = Number(iterations);
  const sampleCount = Math.max(10, Math.min(1000, Math.floor(numericIterations) || 120));
  const benchmarkGame = createGame();
  const results = [];

  for (let level = 1; level <= 4; level += 1) {
    setStressLevel(benchmarkGame, level);

    for (let warmup = 0; warmup < 10; warmup += 1) {
      renderGameSvg(benchmarkGame, assets);
    }

    let svg = "";
    const started = performance.now();

    for (let iteration = 0; iteration < sampleCount; iteration += 1) {
      svg = renderGameSvg(benchmarkGame, assets);
    }

    const elapsed = performance.now() - started;
    const rawBytes = measureUtf8Bytes(svg);
    results.push({
      level,
      iterations: sampleCount,
      svgRawBytes: rawBytes,
      svgBase64Bytes: estimateBase64Bytes(rawBytes),
      averageGenerationMs: elapsed / sampleCount,
      objectCounts: getActiveCounts(benchmarkGame),
    });
  }

  return {
    renderMode: getRenderMode(assetSummary),
    assets: copyAssetSummary(),
    results,
  };
}

document.addEventListener("visibilitychange", function resetClockAfterTabSleep() {
  if (!document.hidden) {
    previousTime = performance.now();
    updateAccumulator = 0;
    renderAccumulator = RENDER_STEP_MS;
  }
});

window.addEventListener("beforeunload", function disposeInput() {
  input.destroy();
});

// The bridge returns strings and copied diagnostics, never mutable runtime objects.
window.__f5Rocket = Object.freeze({
  config: Object.freeze({
    logicalWidth: CONFIG.logicalWidth,
    logicalHeight: CONFIG.logicalHeight,
    updateHz: CONFIG.updateHz,
    renderHz: CONFIG.renderHz,
  }),

  getSnapshot() {
    return {
      running: game.running,
      paused: game.paused,
      time: game.time,
      player: { x: game.player.x, y: game.player.y },
      stressLevel: game.stressLevel,
      diagnostics: getPublicDiagnostics(),
    };
  },

  getSvg() {
    return lastSvg;
  },

  getDiagnostics: getPublicDiagnostics,
  benchmarkStressLevels,
});

renderFrame(performance.now());
loadAssetCatalog(assets).then(function onAssetsPrepared(result) {
  assets = result.catalog;
  assetSummary = result.summary;
  lastDebugRefresh = Number.NEGATIVE_INFINITY;
  renderFrame(performance.now());
});
window.requestAnimationFrame(scheduler);

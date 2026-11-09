import {
  CONFIG,
  RENDER_STEP_MS,
  UPDATE_STEP_MS,
  UPDATE_STEP_SECONDS,
} from "./config.js";
import { createAssetCatalog, loadAssetCatalog } from "./assets.js";
import { createDebugMonitor } from "./debug.js";
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
const assets = createAssetCatalog();
const game = createGame();
const input = createKeyboardInput(window);
const debugMonitor = createDebugMonitor(debugPanel);
const controls = { left: false, right: false, up: false, down: false, fire: false };

let debugVisible = CONFIG.debugMode;
let assetSummary = { loaded: 0, total: 10 };
let previousTime = performance.now();
let updateAccumulator = 0;
let renderAccumulator = RENDER_STEP_MS;
let lastSvgBytes = 0;
let lastDebugRefresh = Number.NEGATIVE_INFINITY;

debugMonitor.setVisible(debugVisible);

function measureUtf8Bytes(text) {
  if (typeof TextEncoder !== "undefined") {
    return new TextEncoder().encode(text).length;
  }
  return text.length;
}

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
  const started = performance.now();
  const svg = renderGameSvg(game, assets);
  viewport.innerHTML = svg;
  lastSvgBytes = measureUtf8Bytes(svg);
  debugMonitor.recordRender(performance.now() - started);

  if (now - lastDebugRefresh >= 200) {
    debugMonitor.refresh(game, getActiveCounts(game), lastSvgBytes, assetSummary);
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

// This small test bridge is intentionally state-oriented, like a future Q-SYS control probe.
window.__f5Rocket = {
  config: CONFIG,
  game,
  getSnapshot() {
    return {
      running: game.running,
      paused: game.paused,
      time: game.time,
      player: { x: game.player.x, y: game.player.y },
      stressLevel: game.stressLevel,
      counts: getActiveCounts(game),
      svgBytes: lastSvgBytes,
    };
  },
};

renderFrame(performance.now());
loadAssetCatalog(assets).then(function onAssetsProbed(summary) {
  assetSummary = summary;
});
window.requestAnimationFrame(scheduler);

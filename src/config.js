export const CONFIG = Object.freeze({
  logicalWidth: 320,
  logicalHeight: 480,
  updateHz: 30,
  renderHz: 30,
  debugMode: true,
  maxFrameDeltaMs: 250,
  maxUpdatesPerSchedulerFrame: 5,
});

export const UPDATE_STEP_SECONDS = 1 / CONFIG.updateHz;
export const UPDATE_STEP_MS = 1000 / CONFIG.updateHz;
export const RENDER_STEP_MS = 1000 / CONFIG.renderHz;

// These fixed scene sizes are deliberate: a Lua port can preallocate the same tables.
export const POOL_SIZES = Object.freeze({
  enemies: 48,
  playerBullets: 128,
  enemyBullets: 64,
  explosions: 24,
});

export const STRESS_LEVELS = Object.freeze({
  1: Object.freeze({ enemies: 1, bullets: 0, label: "NORMAL" }),
  2: Object.freeze({ enemies: 10, bullets: 20, label: "TEST 10 / 20" }),
  3: Object.freeze({ enemies: 20, bullets: 50, label: "TEST 20 / 50" }),
  4: Object.freeze({ enemies: 40, bullets: 120, label: "TEST 40 / 120" }),
});

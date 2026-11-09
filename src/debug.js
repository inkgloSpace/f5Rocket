import { CONFIG, STRESS_LEVELS } from "./config.js";

function formatSize(bytes) {
  if (bytes < 1024) {
    return `${bytes} B`;
  }
  return `${(bytes / 1024).toFixed(1)} KB`;
}

function average(total, count) {
  return count > 0 ? total / count : 0;
}

export function createDebugMonitor(panel) {
  const fields = {
    stress: panel.querySelector("#stressBadge"),
    target: panel.querySelector("#metricTarget"),
    measured: panel.querySelector("#metricMeasured"),
    frameTime: panel.querySelector("#metricFrameTime"),
    workTime: panel.querySelector("#metricWorkTime"),
    player: panel.querySelector("#metricPlayer"),
    enemies: panel.querySelector("#metricEnemies"),
    bullets: panel.querySelector("#metricBullets"),
    explosions: panel.querySelector("#metricExplosions"),
    objects: panel.querySelector("#metricObjects"),
    svgSize: panel.querySelector("#metricSvgSize"),
    assets: panel.querySelector("#metricAssets"),
  };

  let periodStart = performance.now();
  let updateCount = 0;
  let renderCount = 0;
  let schedulerCount = 0;
  let totalUpdateMs = 0;
  let totalRenderMs = 0;
  let totalSchedulerMs = 0;
  let measuredUpdateFps = 0;
  let measuredRenderFps = 0;
  let measuredUpdateMs = 0;
  let measuredRenderMs = 0;
  let measuredSchedulerMs = 0;

  fields.target.textContent = `${CONFIG.updateHz} / ${CONFIG.renderHz} Hz`;

  function rollPeriod(now) {
    const elapsed = now - periodStart;

    if (elapsed < 1000) {
      return;
    }

    const scale = 1000 / elapsed;
    measuredUpdateFps = updateCount * scale;
    measuredRenderFps = renderCount * scale;
    measuredUpdateMs = average(totalUpdateMs, updateCount);
    measuredRenderMs = average(totalRenderMs, renderCount);
    measuredSchedulerMs = average(totalSchedulerMs, schedulerCount);

    updateCount = 0;
    renderCount = 0;
    schedulerCount = 0;
    totalUpdateMs = 0;
    totalRenderMs = 0;
    totalSchedulerMs = 0;
    periodStart = now;
  }

  return {
    setVisible(visible) {
      panel.hidden = !visible;
    },

    recordScheduler(deltaMs) {
      schedulerCount += 1;
      totalSchedulerMs += deltaMs;
      rollPeriod(performance.now());
    },

    recordUpdate(durationMs) {
      updateCount += 1;
      totalUpdateMs += durationMs;
    },

    recordRender(durationMs) {
      renderCount += 1;
      totalRenderMs += durationMs;
    },

    refresh(game, counts, svgBytes, assetSummary) {
      fields.stress.textContent = STRESS_LEVELS[game.stressLevel].label;
      fields.measured.textContent = `${measuredUpdateFps.toFixed(1)} / ${measuredRenderFps.toFixed(1)} Hz`;
      fields.frameTime.textContent = `${measuredSchedulerMs.toFixed(2)} ms`;
      fields.workTime.textContent = `${measuredUpdateMs.toFixed(3)} / ${measuredRenderMs.toFixed(3)} ms`;
      fields.player.textContent = `${game.player.x}, ${game.player.y}`;
      fields.enemies.textContent = String(counts.enemies);
      fields.bullets.textContent = `${counts.bullets} (${counts.playerBullets}P / ${counts.enemyBullets}E)`;
      fields.explosions.textContent = String(counts.explosions);
      fields.objects.textContent = String(counts.totalVisuals);
      fields.svgSize.textContent = formatSize(svgBytes);
      fields.assets.textContent = `${assetSummary.loaded} / ${assetSummary.total}`;
    },
  };
}

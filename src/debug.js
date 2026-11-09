import { CONFIG, STRESS_LEVELS } from "./config.js";

export function formatSize(bytes) {
  if (bytes < 1024) {
    return `${bytes} B`;
  }
  return `${(bytes / 1024).toFixed(1)} KB`;
}

export function measureUtf8Bytes(text) {
  if (typeof TextEncoder !== "undefined") {
    return new TextEncoder().encode(text).length;
  }
  return text.length;
}

export function estimateBase64Bytes(rawBytes) {
  return rawBytes === 0 ? 0 : 4 * Math.ceil(rawBytes / 3);
}

export function getRenderMode(assetSummary) {
  return assetSummary.loaded > 0 ? "EMBEDDED PNG / SVG" : "SVG PLACEHOLDERS";
}

function average(total, count) {
  return count > 0 ? total / count : 0;
}

function missingAssetMessage(assetSummary) {
  if (!assetSummary.ready) {
    return `Preparing ${assetSummary.pending} configured PNG assets…`;
  }

  if (assetSummary.missing.length === 0) {
    return "All configured PNG assets are cached as embedded data URIs.";
  }

  const paths = [];
  for (let index = 0; index < assetSummary.missing.length; index += 1) {
    paths.push(assetSummary.missing[index].path);
  }
  return `Missing PNG: ${paths.join(", ")}`;
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
    svgRaw: panel.querySelector("#metricSvgRaw"),
    svgBase64: panel.querySelector("#metricSvgBase64"),
    assetData: panel.querySelector("#metricAssetData"),
    assets: panel.querySelector("#metricAssets"),
    renderMode: panel.querySelector("#metricRenderMode"),
    assetStatus: panel.querySelector("#assetStatus"),
  };

  let periodStart = performance.now();
  let updateCount = 0;
  let renderCount = 0;
  let schedulerCount = 0;
  let totalUpdateMs = 0;
  let totalGenerationMs = 0;
  let totalSchedulerMs = 0;
  let measuredUpdateFps = 0;
  let measuredRenderFps = 0;
  let measuredUpdateMs = 0;
  let measuredGenerationMs = 0;
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
    measuredGenerationMs = average(totalGenerationMs, renderCount);
    measuredSchedulerMs = average(totalSchedulerMs, schedulerCount);

    updateCount = 0;
    renderCount = 0;
    schedulerCount = 0;
    totalUpdateMs = 0;
    totalGenerationMs = 0;
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

    recordRender(generationMs) {
      renderCount += 1;
      totalGenerationMs += generationMs;
    },

    refresh(game, counts, diagnostics, assetSummary) {
      fields.stress.textContent = STRESS_LEVELS[game.stressLevel].label;
      fields.measured.textContent = `${measuredUpdateFps.toFixed(1)} / ${measuredRenderFps.toFixed(1)} Hz`;
      fields.frameTime.textContent = `${measuredSchedulerMs.toFixed(2)} ms`;
      fields.workTime.textContent = `${measuredUpdateMs.toFixed(3)} / ${measuredGenerationMs.toFixed(3)} ms`;
      fields.player.textContent = `${game.player.x}, ${game.player.y}`;
      fields.enemies.textContent = String(counts.enemies);
      fields.bullets.textContent = `${counts.bullets} (${counts.playerBullets}P / ${counts.enemyBullets}E)`;
      fields.explosions.textContent = String(counts.explosions);
      fields.objects.textContent = String(counts.totalVisuals);
      fields.svgRaw.textContent = formatSize(diagnostics.svgRawBytes);
      fields.svgBase64.textContent = formatSize(diagnostics.svgBase64Bytes);
      fields.assetData.textContent = formatSize(assetSummary.dataUriBytes);
      fields.assets.textContent = `${assetSummary.loaded} / ${assetSummary.total}`;
      fields.renderMode.textContent = getRenderMode(assetSummary);
      fields.assetStatus.textContent = missingAssetMessage(assetSummary);
      fields.assetStatus.title = fields.assetStatus.textContent;
    },
  };
}

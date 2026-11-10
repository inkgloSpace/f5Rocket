# f5Rocket

f5Rocket is a semi-8-bit vertical arcade airplane shooter with a local browser simulator and a separate modular Q-SYS production plugin. The browser remains the fast visual-iteration environment; the Q-SYS plugin now contains the first bounded playable Lua slice.

This is deliberately a **Q-SYS rendering and gameplay simulator**, not the start of a conventional web-game stack. It uses plain HTML, CSS, vanilla JavaScript modules, and one generated SVG scene. There is no framework, Canvas renderer, WebGL, npm dependency, or build step.

## Repository and local preview

- Local checkout: `~/Desktop/f5Rocket`
- GitHub: `https://github.com/inkgloSpace/f5Rocket.git`
- Logical viewport: `320 × 480` (2:3 portrait)
- Simulation target: fixed `30 Hz`
- Render target: capped `30 Hz`

Start the standard-library server:

```bash
cd ~/Desktop/f5Rocket
python3 tools/serve.py
```

Then open [http://localhost:8080](http://localhost:8080). Optional flags are `--host` and `--port`.

## Controls

| Key | Action |
| --- | --- |
| Arrow keys / WASD | Move, including diagonals |
| Space | Fire; hold for repeat fire |
| Enter | Start/restart the normal scene |
| P | Pause/resume |
| D | Move right as part of WASD |
| F3 | Toggle the debug panel |
| 1 | Normal scene: 1 enemy |
| 2 | Synthetic load: 10 enemies / 20 bullets |
| 3 | Synthetic load: 20 enemies / 50 bullets |
| 4 | Synthetic load: 40 enemies / 120 bullets |

## Rendering architecture

The browser follows the planned Q-SYS data flow closely:

```text
plain game state
→ fixed-step update
→ SVG string generation
→ one 320 × 480 viewport
```

PNG preparation follows a separate startup-only path:

```text
PNG file
→ one startup fetch
→ one Base64 conversion
→ immutable data:image/png;base64,... cache entry
→ cached string copied into SVG <image href="...">
```

The SVG renderer only consumes state and the immutable asset catalog; it does not calculate gameplay or re-read/re-encode PNG files. Scene order is background, decoration, enemies, enemy bullets, player bullets, player, explosions, then HUD. Sprite positions are rounded to integer logical pixels, and the browser scales the fixed SVG with pixelated image rendering.

The generated SVG is self-contained when PNGs are present. The production Q-SYS flow uses Lua, allowlists only active gameplay PNGs for SVG `<defs>`, caches geometric fallbacks, emits every sprite and scrolling starfield tile with `<use href="#...">`, Base64-encodes the complete SVG once, rapidjson-encodes the Button legend payload, and assigns it through dynamic `IconData`. Large or feature-deferred PNGs may remain in generated asset data without being copied into every 30 Hz frame.

Telemetry reports raw UTF-8 SVG bytes, the mathematically correct Base64 SVG length (`4 × ceil(raw bytes / 3)`), unique cached PNG data-URI bytes, active objects, and average browser SVG generation time. Raw SVG size already includes every embedded PNG data URI used by the scene; the separate asset metric counts each configured cached asset once.

**Browser performance is not equivalent to Q-SYS Core performance.** The telemetry and synthetic scene controls estimate SVG payload growth and browser-side work only. The Q-SYS compatibility probe has validated 64 reused fixture sprites at 30 Hz in Designer 10.5.0, but real artwork and physical Core performance still require separate measurement.

## PNG asset conventions

Artwork is intentionally not bundled. Add user-supplied PNGs at these paths:

```text
assets/player/player_idle.png
assets/player/player_left.png
assets/player/player_right.png
assets/enemy/enemy_01.png
assets/bullet/player_bullet.png
assets/bullet/enemy_bullet.png
assets/explosion/explosion_01.png
assets/explosion/explosion_02.png
assets/explosion/explosion_03.png
assets/background/background_tile.png
```

At browser startup, `src/assets.js` fetches every configured path once. For Q-SYS, `python3 qsys/tools/build.py game` validates the same root PNGs and deterministically generates Lua Base64 data before building the plugin. Missing files keep debug placeholders active in both environments. See [`assets/README.md`](assets/README.md) for sizing and replacement notes.

## SVG inspection bridge

Open the browser console while the preview is running:

```js
window.__f5Rocket.getSvg()
window.__f5Rocket.getDiagnostics()
window.__f5Rocket.benchmarkStressLevels(120)
```

`getSvg()` returns the exact current SVG string. Diagnostics return copied values rather than mutable game or asset objects. The benchmark measures SVG string generation only for stress levels 1–4; it does not write benchmark scenes into the live viewport.

## Source map

- `src/config.js` — logical resolution, timing, pool sizes, and load levels
- `src/game.js` — deterministic game state and fixed-step updates
- `src/input.js` — keyboard state and one-shot commands
- `src/renderer-svg.js` — complete SVG string generation
- `src/assets.js` — startup PNG loading, Base64 encoding, immutable metadata, and missing-file summary
- `src/debug.js` — browser telemetry presentation
- `src/main.js` — capped scheduler and module wiring
- `tools/serve.py` — dependency-free local HTTP server
- `qsys/plugins/compat/` — frozen SVG/IconData regression probe
- `qsys/plugins/game/` — modular production Lua game and SVG renderer
- `qsys/tools/build.py` — deterministic multi-target plugin and PNG asset builder

## Current limitations

- The browser prototype still omits collision scoring; the Q-SYS production slice implements player-bullet/enemy AABB scoring independently.
- The production slice has one recycling enemy type and no enemy weapons, lives, bosses, power-ups, sound, or progression.
- The current PNG pack is temporary. Its large full-screen background remains available as a visual reference but is excluded from the Q-SYS 30 Hz frame in favor of the reusable starfield tile.
- Q-SYS Designer validation does not establish physical Core CPU or final artwork payload limits.
- Browser input is keyboard-only; Q-SYS input uses plugin controls.

## Development phases

1. **Local technical prototype:** browser movement, fire pooling, scrolling background, generated SVG, placeholders, and telemetry.
2. **Q-SYS compatibility probe:** completed in Designer 10.5.0; 64 `<use href>` instances remained stable at 30 Hz.
3. **Production playable slice (current):** modular Lua movement, bullets, one enemy type, AABB collision, score, generated SVG, and bounded pools.
4. **Artwork integration:** iterate the user PNG pack, keep dynamic definitions allowlisted, and measure real payloads before enabling each asset group.
5. **Core validation and gameplay growth:** verify physical Core limits before adding enemy weapons, patterns, explosions, lives, or progression.

# f5Rocket

f5Rocket is a semi-8-bit vertical arcade airplane shooter prototype for a future Q-SYS plugin. This first phase runs in a local browser so gameplay, timing, generated SVG, and user-supplied PNG artwork can be iterated quickly.

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

The generated SVG is self-contained when PNGs are present. The eventual Q-SYS flow will replace JavaScript with Lua, serialize the same kind of SVG scene, Base64-encode the complete SVG, rapidjson-encode the Button legend payload, and assign it through dynamic `IconData`.

Telemetry reports raw UTF-8 SVG bytes, the mathematically correct Base64 SVG length (`4 × ceil(raw bytes / 3)`), unique cached PNG data-URI bytes, active objects, and average browser SVG generation time. Raw SVG size already includes every embedded PNG data URI used by the scene; the separate asset metric counts each configured cached asset once.

**Browser performance is not equivalent to Q-SYS Core performance.** The telemetry and synthetic scene controls estimate SVG payload growth and browser-side work only. The compatibility probe described in [`qsys/README.md`](qsys/README.md) is required before choosing a Q-SYS scene budget.

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

At startup, `src/assets.js` fetches every configured path once. Valid PNG bytes are converted once to complete data URIs and stored with immutable metadata. Available PNGs become self-contained SVG `<image>` nodes; unavailable files are listed in the debug asset summary, leave the labeled SVG placeholders active, and do not stop the game. See [`assets/README.md`](assets/README.md) for sizing and replacement notes.

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
- `qsys/README.md` — intentionally small future plugin plan

## Current limitations

- The player and enemy do not collide; score and explosions are structural placeholders.
- There is one recycling enemy behavior and no enemy weapons in the normal scene.
- Embedded PNG data URIs and Base64 SVG `IconData` have not yet been validated inside Q-SYS Designer/Core.
- Browser SVG timing, memory, and payload limits cannot establish the final Core scene budget.
- Input is keyboard-only in this phase.

## Development phases

1. **Local technical prototype (current):** fixed-step movement, fire pooling, scrolling background, generated SVG, placeholders, asset probes, and load telemetry.
2. **Q-SYS compatibility probe (next):** one user PNG embedded in dynamic SVG, moved at approximately 30 Hz through Button `IconData`.
3. **Cross-environment parity:** compare supported SVG/PNG forms, payload size, timing stability, and lower 20/15 Hz modes.
4. **Gameplay slice:** collisions, enemy patterns, explosions, score, and finalized user artwork.
5. **Plugin packaging:** complete controls/properties/pages, runtime Lua, operational safeguards, and installation testing.

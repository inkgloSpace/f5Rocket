# Q-SYS workspace

This directory contains two separate include-based Q-SYS plugins:

- `f5Rocket_Compat.qplug` is frozen regression infrastructure for the validated SVG renderer path.
- `f5Rocket.qplug` is the production game plugin and the only place where gameplay should grow.

Q-SYS Designer 10.5.0 has validated the production renderer direction for 60 seconds at 30.0 Hz with 64 visible sprites: SVG `<defs>`, one PNG `<image href="data:image/png;base64,...">`, and repeated `<use href="#...">` instances. No xlink production mode is planned unless a later regression requires it.

## Directory ownership

```text
qsys/plugins/compat/   editable compatibility-probe source
qsys/plugins/game/     editable production-game source
qsys/dist/             generated Designer-installable plugins
qsys/tools/            deterministic build and asset tooling
qsys/compat/           compatibility fixture, procedure, and results
```

Both source trees use conventional Q-SYS/QSC `--[[ #include "file.lua" ]]` directives. The generated `.qplug` files are distribution artifacts, not editable source.

## Build commands

From the repository root:

```bash
python3 qsys/tools/build.py compat
python3 qsys/tools/build.py game
python3 qsys/tools/build.py all
```

Running without a target also builds all plugins:

```bash
python3 qsys/tools/build.py
```

VS Code provides matching build tasks, with **f5Rocket: Build All Q-SYS Plugins** as the default.

Generated artifacts:

```text
qsys/dist/f5Rocket_Compat.qplug
qsys/dist/f5Rocket.qplug
qsys/plugins/game/generated/assets_data.lua
```

**Never manually edit generated files.** The builder resolves includes recursively, rejects missing/circular/escaping includes, validates available PNG signatures and IHDR dimensions, Base64-encodes each source PNG once, and emits deterministic output without timestamps.

## Compatibility regression plugin

- Source: [`plugins/compat/plugin.lua`](plugins/compat/plugin.lua)
- Distribution: [`dist/f5Rocket_Compat.qplug`](dist/f5Rocket_Compat.qplug)
- Plugin ID: `3c2b6895-8b9b-5d60-9f5f-12f94d8c46f9`
- Page: `Probe`

Its 1/8/16/32/64-instance benchmark, INLINE comparison, 30/20/15 Hz rates, and syntax switches remain intact. Treat it as a renderer regression tool; do not add game logic to it. The confirmed result and repeatable test procedure are in [`compat/README.md`](compat/README.md).

## Production game plugin

- Source: [`plugins/game/plugin.lua`](plugins/game/plugin.lua)
- Distribution: [`dist/f5Rocket.qplug`](dist/f5Rocket.qplug)
- Plugin ID: `fdb75e48-50b5-5b21-8104-5da52ab51f13`
- Version: `0.1.1`
- Page: `Game`
- Logical viewport: 320×480
- Fixed update/render target: 30 Hz

The first slice implements Start, Pause, simultaneous four-direction input, cooldown-limited fire, bounded player bullets, deterministic recycling enemies, bullet/enemy AABB collision, and score. It intentionally omits enemy bullets, bosses, power-ups, lives, sound, menus, and progression.

Production controls are `Viewport`, `Start`, `Pause`, `Left`, `Right`, `Up`, `Down`, `Fire`, `DiagnosticMode`, `MeasuredHz`, `SvgBytes`, `SvgBase64Bytes`, `ActiveEnemies`, `ActivePlayerBullets`, and `Status`.

`DiagnosticMode` isolates runtime failure domains without rebuilding the plugin:

- `TIMER ONLY` runs the one 30 Hz timer and its one-second measurement window without game updates or per-tick `Viewport.Legend` writes.
- `MINIMAL RENDER` moves one definition-based fallback sprite and refreshes IconData at 30 Hz.
- `FULL GAME` runs the complete first playable slice and is the default.

Every timer callback has one protected boundary. If input, state update, SVG generation, Base64 encoding, Legend encoding/assignment, or telemetry fails, the timer stops and `Status` reports the precise stage. Engineering readouts are refreshed approximately once per second; only the viewport changes at 30 Hz.

For runtime regression isolation in Designer, run each mode for 60 seconds in this order: `TIMER ONLY`, `MINIMAL RENDER`, then `FULL GAME`. If the timer test passes but minimal rendering freezes, investigate IconData/SVG assignment. If both diagnostic modes pass but the full game freezes, use the reported stage to investigate game-state logic. A clean pass in all three modes confirms the stabilized fallback, telemetry, and protected-tick path in that environment.

## Shared PNG asset pipeline

The browser and Q-SYS game share only the root artwork files:

```text
assets/player/
assets/enemy/
assets/bullet/
assets/explosion/
assets/background/
assets/hud/
```

The game build reads the expected PNGs from those folders and generates `plugins/game/generated/assets_data.lua`. Handwritten [`plugins/game/renderer/assets.lua`](plugins/game/renderer/assets.lua) owns XML-safe IDs, logical display dimensions, availability checks, cached `<defs>` construction, and player-direction fallback rules.

Missing PNGs are expected and do not fail the build. Generated entries remain unavailable, Q-SYS debug output lists them, and the renderer uses obvious SVG geometry plus a deterministic starfield. These fallbacks are cached once in `<defs>` and placed with `<use href>` just like PNG-backed sprites; their geometry is not expanded per object or recalculated per frame. Invalid files at an expected PNG path do fail the build.

## Production renderer

Every frame follows one fixed path:

```text
game state
→ cached PNG definitions in <defs>
→ sprite <use href="#assetId"> or <use href="#fallbackId"> instances
→ one complete 320×480 SVG string
→ one Crypto.Base64Encode(svg)
→ one rapidjson Button Legend
→ one Controls.Viewport.Legend assignment
```

The PNG definitions, fallback definitions, and deterministic 320×480 starfield tile are prepared once. The scrolling background places two tile instances and changes only their integer translations. Runtime performs no filesystem access, network access, or PNG encoding.

## Game modules

- `game/config.lua`: resolution, 30 Hz interval, movement, projectile, scoring, and pool limits
- `game/state.lua`: state creation/reset and bounded table allocation
- `game/player.lua`: integer movement, viewport constraints, direction, and cooldown
- `game/bullets.lua`: player-bullet allocation, motion, recycling, and count
- `game/enemies.lua`: deterministic initial placement, downward motion, recycling, and count
- `game/collision.lua`: player-bullet versus enemy AABB checks and scoring
- `renderer/assets.lua`: shared artwork metadata, cached definitions, and asset selection
- `renderer/svg.lua`: complete background-to-HUD frame serialization
- `runtime.lua`: Q-SYS controls, one protected Timer callback, diagnostic modes, state orchestration, centralized IconData, staged errors, and throttled telemetry

## Installation and validation

Build the desired target, copy the corresponding file from `qsys/dist/` into the Q-SYS Designer user plugin directory, restart Designer, and add it from User plugins. Validate the compatibility probe separately from the production game.

Designer testing does not replace a physical Core test. User PNG sizes, Core CPU behavior, timer stability, and practical production payload limits remain hardware-dependent.

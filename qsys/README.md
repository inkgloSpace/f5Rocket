# Q-SYS workspace

This directory contains three separate include-based Q-SYS plugins:

- `f5Rocket_Compat.qplug` is frozen regression infrastructure for the validated SVG renderer path.
- `f5Rocket.qplug` is the production game plugin and the only place where gameplay should grow.
- `f5Rocket_RuntimeProbe.qplug` isolates timer, SVG-string, and IconData lifecycle behavior without game or asset dependencies.

Q-SYS Designer 10.5.0 has validated the production renderer direction for 60 seconds at 30.0 Hz with 64 visible sprites: SVG `<defs>`, one PNG `<image href="data:image/png;base64,...">`, and repeated `<use href="#...">` instances. No xlink production mode is planned unless a later regression requires it.

## Directory ownership

```text
qsys/plugins/compat/   editable compatibility-probe source
qsys/plugins/game/     editable production-game source
qsys/plugins/runtime_probe/ editable isolated-runtime source
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
python3 qsys/tools/build.py runtime_probe
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
qsys/dist/f5Rocket_RuntimeProbe.qplug
qsys/plugins/game/generated/assets_data.lua
```

**Never manually edit generated files.** The builder resolves includes recursively, rejects missing/circular/escaping includes, validates available PNG signatures and IHDR dimensions, Base64-encodes each source PNG once, and emits deterministic output without timestamps.

## Compatibility regression plugin

- Source: [`plugins/compat/plugin.lua`](plugins/compat/plugin.lua)
- Distribution: [`dist/f5Rocket_Compat.qplug`](dist/f5Rocket_Compat.qplug)
- Plugin ID: `3c2b6895-8b9b-5d60-9f5f-12f94d8c46f9`
- Page: `Probe`

Its 1/8/16/32/64-instance benchmark, INLINE comparison, 30/20/15 Hz rates, and syntax switches remain intact. Treat it as a renderer regression tool; do not add game logic to it. The confirmed result and repeatable test procedure are in [`compat/README.md`](compat/README.md).

## Runtime lifecycle probe

- Source: [`plugins/runtime_probe/plugin.lua`](plugins/runtime_probe/plugin.lua)
- Distribution: [`dist/f5Rocket_RuntimeProbe.qplug`](dist/f5Rocket_RuntimeProbe.qplug)
- Plugin ID: `c84db0f2-6a9e-4f45-9cd7-15b0d5c4c09e`
- Version: `0.1.0`
- Page: `Probe`

This plugin follows the known-good compatibility probe lifecycle: one globally scoped timer, a Toggle `Run` control, reset-before-start behavior, and no `pcall` wrapper. It deliberately contains no game modules, state pools, PNGs, asset data, background, collision, payload guard, or production diagnostic lifecycle.

All three runtime-probe stages—TIMER, SVG, and ICONDATA—have passed at 30 Hz in Q-SYS Designer 10.5.0. Keep this plugin frozen as runtime regression infrastructure.

Run the manual matrix in Q-SYS Designer 10.5.0:

1. **Test A — TIMER:** select `TIMER`, enable `Run`, and wait 60 seconds. QDS should remain responsive, `TickCount` should increase, `MeasuredHz` should remain near 30 Hz, and the viewport should remain static.
2. **Test B — SVG:** select `SVG`, enable `Run`, and wait 60 seconds. QDS should remain responsive and counters should advance. The tiny SVG is generated at 30 Hz but deliberately is not encoded or assigned, so the viewport should not animate.
3. **Test C — ICONDATA:** select `ICONDATA`, enable `Run`, and wait 60 seconds. A small rectangle should move horizontally through the one dynamic viewport near 30 Hz while QDS remains responsive.

Interpretation:

- TIMER freezes: investigate the runtime/timer/control lifecycle.
- TIMER passes and SVG freezes: investigate per-tick Lua computation or string generation.
- TIMER and SVG pass but ICONDATA freezes: investigate dynamic `Viewport.Legend`/`IconData` updates.
- All three pass: the production freeze comes from code above this minimal runtime layer.

## Production game plugin

- Source: [`plugins/game/plugin.lua`](plugins/game/plugin.lua)
- Distribution: [`dist/f5Rocket.qplug`](dist/f5Rocket.qplug)
- Plugin ID: `fdb75e48-50b5-5b21-8104-5da52ab51f13`
- Version: `0.2.0`
- Page: `Game`
- Logical viewport: 320×480
- Fixed update/render target: 30 Hz

The first slice implements a Toggle Run lifecycle, simultaneous four-direction input, cooldown-limited fire, bounded player bullets, deterministic recycling enemies, bullet/enemy AABB collision, and score. It intentionally omits Pause during runtime stabilization, along with enemy bullets, bosses, power-ups, lives, sound, menus, and progression.

Production controls are `Viewport`, `Run`, `Left`, `Right`, `Up`, `Down`, `Fire`, `Status`, `MeasuredHz`, `SvgBytes`, `SvgBase64Bytes`, `ActiveEnemies`, and `ActivePlayerBullets`. `Run` is a Toggle; movement and fire remain Momentary controls read directly during each timer tick.

The production lifecycle now directly follows the proven probes:

- Enabling `Run` stops the timer, resets game state and enemies, renders one initial frame, reports `RUNNING`, and starts the single timer at 30 Hz.
- Disabling `Run` stops the timer, sets `gameState.running` false, and reports `STOPPED`.
- Each timer tick reads input, updates the existing game state, renders and assigns one frame, then updates visible telemetry only when the approximately one-second measurement window closes.
- No production diagnostic mode, Pause control, stage machine, or whole-tick `pcall` remains. Those diagnostics belong to the separate runtime probe.

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

The game build reads the expected PNGs from those folders and generates `plugins/game/generated/assets_data.lua`. Handwritten [`plugins/game/renderer/assets.lua`](plugins/game/renderer/assets.lua) owns XML-safe IDs, logical display dimensions, availability checks, cached `<defs>` construction, player-direction fallback rules, and the explicit runtime-definition allowlist.

Generation and 30 Hz embedding are separate concerns: all manifest PNGs remain available in generated Lua data, while the current dynamic game SVG embeds only `player_idle`, `player_left`, `player_right`, `enemy_01`, and `bullet_player`. Enemy bullets and explosions are deferred until those features are active. `background_tile` remains generated but is deliberately excluded from the dynamic definition set.

Missing PNGs are expected and do not fail the build. Generated entries remain unavailable, Q-SYS debug output lists them, and the renderer uses obvious SVG geometry plus a deterministic starfield. These fallbacks are cached once in `<defs>` and placed with `<use href>` just like PNG-backed sprites; their geometry is not expanded per object or recalculated per frame. Invalid files at an expected PNG path do fail the build.

## Production renderer

Every frame follows one fixed path:

```text
game state
→ allowlisted gameplay PNG definitions in <defs>
→ sprite <use href="#assetId"> or <use href="#fallbackId"> instances
→ one complete 320×480 SVG string
→ one Crypto.Base64Encode(svg)
→ one rapidjson Button Legend
→ one Controls.Viewport.Legend assignment
```

The selected PNG definitions, fallback definitions, and deterministic 320×480 starfield tile are prepared once. The scrolling background always places two lightweight fallback tile instances and changes only their integer translations. The current full-screen background PNG is never copied into the 30 Hz SVG. Runtime performs no filesystem access, network access, or PNG encoding.

Project engineering targets are below 32 KB raw SVG and below 48 KB after SVG Base64 encoding. These are not official Q-SYS limits. A centralized 64 KB raw-frame guard rejects an oversized SVG before Base64 encoding or `Viewport.Legend` assignment and reports `ERROR @ PAYLOAD` instead of sending it to Designer. Start-up debug output records gameplay definition bytes, deferred background definition bytes, current SVG bytes, Base64 bytes, and the guard value.

## Future background artwork

The eventual runtime background should use small repeating ocean tiles—ideally 32×32 or 64×64—plus small island and cloud sprites. Each asset should appear once in `<defs>`, repeat through `<use href>`, and scroll with integer coordinates or transforms. A large 320×480 PNG may remain a visual reference, but it should not be embedded again inside every dynamic 30 Hz frame.

## Game modules

- `game/config.lua`: resolution, 30 Hz interval, movement, projectile, scoring, and pool limits
- `game/state.lua`: state creation/reset and bounded table allocation
- `game/player.lua`: integer movement, viewport constraints, direction, and cooldown
- `game/bullets.lua`: player-bullet allocation, motion, recycling, and count
- `game/enemies.lua`: deterministic initial placement, downward motion, recycling, and count
- `game/collision.lua`: player-bullet versus enemy AABB checks and scoring
- `renderer/assets.lua`: shared artwork metadata, cached definitions, and asset selection
- `renderer/svg.lua`: complete background-to-HUD frame serialization
- `runtime.lua`: proven Toggle lifecycle, one Timer callback, state orchestration, centralized IconData, and one-second telemetry

## Installation and validation

Build the desired target, copy the corresponding file from `qsys/dist/` into the Q-SYS Designer user plugin directory, restart Designer, and add it from User plugins. Validate the compatibility probe separately from the production game.

Designer testing does not replace a physical Core test. User PNG sizes, Core CPU behavior, timer stability, and practical production payload limits remain hardware-dependent.

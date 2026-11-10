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
- Version: `0.5.0`
- Page: `Game`
- Logical viewport: 320×480; Q-SYS display size: 480×720
- Fixed update/render target: 30 Hz

The current slice keeps the proven Toggle Run lifecycle and implements a three-stage campaign: Easy near orbit, Medium AV-tech asteroid space, and the Hard Q-Core arena. Each wave has a stage-local score threshold, a deterministic boss, a 45-tick clear transition, and a static stage background. A bounded three-layer SVG parallax overlay supplies motion without re-encoding the full-screen PNG. The campaign ends with MISSION COMPLETE at a minimum cumulative score of 52,500. One-hit death and Run OFF/ON restart semantics remain unchanged.

Production controls are `BackgroundViewport`, `Viewport`, `Run`, `Pause`, `Up`, `Down`, `Left`, `Right`, `Fire`, `UpLeft`, `UpRight`, `DownLeft`, `DownRight`, `AutoFire`, `Status`, `MeasuredHz`, `SvgBytes`, `SvgBase64Bytes`, `ActiveEnemies`, and `ActivePlayerBullets`. The two viewport controls overlap at 480×720 while both SVGs retain `viewBox="0 0 320 480"`. `BackgroundViewport` is the lower static layer; `Viewport` is the transparent 30 Hz gameplay layer. `Run`, `Pause`, and `AutoFire` are Toggles; all direction and manual-fire controls are Momentary.

The four diagonal controls and AutoFire form a smartphone-friendly UCI pad without replacing the original simultaneous engine inputs. Each tick OR-combines the mobile diagonals with `Up`, `Down`, `Left`, and `Right`, and combines `Fire` with `AutoFire`. Contradictory axes still cancel inside the existing player movement code, diagonal speed remains normalized, and the existing fire cooldown remains authoritative.

`Run`, `Pause`, `Up`, `Down`, `Left`, `Right`, and `Fire` are also available as Q-SYS input control pins through **Properties → Control Pins**. These pins use the same Control objects as the panel buttons: an external HIGH holds a Momentary movement/fire input, while the Run and Pause Boolean values follow their Toggle semantics. Telemetry and viewport controls are not exposed as pins.

Campaign tuning is centralized and deterministic:

| Stage | Enemies | Wave threshold | Enemy score | Boss HP | Boss reward |
| --- | ---: | ---: | ---: | ---: | ---: |
| Easy | 4 | 5,000 | 100 | 20 | 2,500 |
| Medium | 5 | 10,000 | 200 | 40 | 5,000 |
| Hard | 6 | 15,000 | 300 | 80 | 15,000 |

The Easy boss uses single aimed shots. The Medium boss uses a three-shot fan with an occasional aimed shot. The Final boss uses a three-shot fan above half HP and switches to a faster five-shot fan pattern at or below half HP. All bullets reuse the same 32-entry enemy pool; all defeat effects reuse the 12-entry explosion pool.

The production lifecycle now directly follows the proven probes:

- Enabling `Run` stops the timer, resets game state and enemies, renders one initial frame, reports `RUNNING`, and starts the single timer at 30 Hz.
- Disabling `Run` stops the timer, sets `gameState.running` false, and reports `STOPPED`.
- Enabling `Pause` while Run is active stops that same timer without resetting state, renders one paused frame, and reports `PAUSED`. Disabling Pause resets only the measurement window and resumes the same state. Stopping or starting a game clears Pause.
- Each timer tick reads input, updates the existing game state, renders and assigns one transparent gameplay frame, then updates visible telemetry only when the approximately one-second measurement window closes.
- The background Legend is encoded and assigned only at initialization, new-game reset, and stage transition. It is never touched by the timer hot path.
- FAR, MID, and NEAR parallax objects are preallocated, update inside the existing timer, and render as lightweight `<use>` instances before all gameplay objects. Boss, clear, death, and completion phases reduce their speed rather than stopping them.
- No production diagnostic mode, whole-tick `pcall`, or additional timer exists. Runtime diagnostics belong to the separate runtime probe.

## Shared PNG asset pipeline

The browser and Q-SYS game share only the root artwork files:

```text
assets/player/
assets/enemy/
assets/boss/
assets/bullet/
assets/explosion/
assets/background/
assets/branding/
```

The game build reads the expected PNGs from those folders and generates `plugins/game/generated/assets_data.lua`. Handwritten [`plugins/game/renderer/assets.lua`](plugins/game/renderer/assets.lua) owns XML-safe IDs, logical display dimensions, availability checks, cached `<defs>` construction, player-direction fallback rules, and the explicit runtime-definition allowlist.

Generation and 30 Hz embedding are separate concerns. Generated data exposes dynamic-gameplay, static-background, branding, and compatibility-alias groups. The dynamic definitions contain the three player states, three stage enemies, both bullets, three explosion frames, two minibosses, and the final boss. The three full-screen backgrounds are available only to the static background builder. `enemy_01` and `background_tile` remain compatibility aliases and do not drive the campaign.

Each enemy and boss sprite has one reusable downward-facing wrapper definition with a centralized 180-degree transform. Hostile instances select those wrappers and never repeat rotation markup.

Enemy and boss shots use one reusable 12×20 SVG definition with a dark silhouette, magenta body, orange inner glow, and white core. The original enemy-bullet PNG remains in the generated manifest for compatibility, but normal hostile shots render as `<use href="#enemy_bullet_visible">` so the projectile stays legible over all three stage palettes.

Missing PNGs do not fail the build. Dynamic sprites fall back to cached SVG definitions; missing stage backgrounds use a deterministic static fallback generated only when that background is assigned. Invalid files at an expected PNG path do fail the build.

## Production renderer

Every frame follows one fixed path:

```text
stage change → one background SVG/image → BackgroundViewport.IconData

game state → allowlisted gameplay PNG definitions in <defs>
→ FAR / MID / NEAR geometry <use> instances
→ sprite <use href="#assetId"> or fallback instances
→ one transparent 320×480 gameplay SVG
→ one Crypto.Base64Encode(svg) per frame
→ one Controls.Viewport.Legend assignment per frame
```

The selected gameplay PNG, fallback, and parallax definitions are prepared once. No stage background data URI or opaque full-screen rectangle is present in the dynamic SVG. The static background SVG contains exactly one phase background and is only rebuilt at lifecycle boundaries. Runtime performs no filesystem access, network access, or PNG encoding.

Parallax profiles are intentionally distinct: Easy uses 20/6/2 slow blue star/tech/near objects; Medium uses 18/10/4 faster purple asteroid objects; Hard uses 16/10/6 aggressive mechanical and cyan-magenta energy objects. The maximum active count is 32 `<use>` nodes. Speed multipliers are 0.35 for bosses, 0.20 for stage clear, 0.15 for game over, and 0.10 for mission complete.

With hybrid parallax active, the current pack produces representative dynamic frames around 44 KB raw and 59 KB after SVG Base64 encoding. Parallax itself adds approximately 3.2–3.5 KB and no more than 32 active `<use>` nodes. These are project observations, not official Q-SYS limits. A centralized 64 KB raw-frame guard rejects an oversized gameplay SVG before Base64 encoding or `Viewport.Legend` assignment. Static background payloads are reported separately when assigned and are not subject to the dynamic guard.

## Game modules

- `game/config.lua`: resolution, 30 Hz interval, movement, projectile, scoring, and pool limits
- `game/state.lua`: state creation/reset and bounded table allocation
- `game/player.lua`: integer movement, viewport constraints, direction, and cooldown
- `game/bullets.lua`: bounded player/enemy bullet allocation, fixed-vector enemy aiming, motion, and recycling
- `game/stages.lua`: campaign phase transitions, thresholds, score reset, and bounded-pool cleanup
- `game/parallax.lua`: deterministic preallocated FAR/MID/NEAR state, recycling, and phase speed multipliers
- `game/enemies.lua`: profile-driven placement, pursuit steering, staggered fire cooldowns, recycling, and count
- `game/explosions.lua`: bounded three-frame animation allocation and game-over animation timing
- `game/bosses.lua`: preallocated boss state, deterministic movement/fire patterns, rewards, and multi-explosion defeat
- `game/collision.lua`: normal/boss/player AABB collision and campaign scoring rules
- `renderer/assets.lua`: shared artwork metadata, cached definitions, and asset selection
- `renderer/parallax_svg.lua`: stage-specific reusable geometry and ordered parallax `<use>` serialization
- `renderer/svg.lua`: static background serialization plus transparent gameplay/HUD frame serialization
- `runtime.lua`: proven Toggle lifecycle, one Timer callback, stage orchestration, two centralized Legends, and one-second telemetry

## Installation and validation

Build the desired target, copy the corresponding file from `qsys/dist/` into the Q-SYS Designer user plugin directory, restart Designer, and add it from User plugins. Validate the compatibility probe separately from the production game.

Designer testing does not replace a physical Core test. User PNG sizes, Core CPU behavior, timer stability, and practical production payload limits remain hardware-dependent.

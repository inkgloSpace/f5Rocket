# Q-SYS workspace

This directory contains the modular source, deterministic build tool, installable distribution, and test evidence for the first f5Rocket Q-SYS compatibility probe. It is intentionally not a port of the browser game.

## Directory ownership

```text
qsys/plugin/   editable Q-SYS Lua source; this is the source of truth
qsys/dist/     generated Designer-installable plugin
qsys/tools/    dependency-free build tooling
qsys/compat/   compatibility fixture, procedure, and result records
```

The source uses conventional Q-SYS/QSC `--[[ #include "file.lua" ]]` directives. This keeps the files usable with include-aware split-plugin workflows such as Qanvas while producing the single `.qplug` file expected by Q-SYS Designer. These directives are compile-time composition, not runtime Lua `require()` or filesystem access.

## Build

From the repository root:

```bash
cd ~/Desktop/f5Rocket
python3 qsys/tools/build.py
```

The build starts at `qsys/plugin/plugin.lua`, resolves includes relative to their containing files, and writes `qsys/dist/f5Rocket_Compat.qplug`. It detects missing files and circular includes and emits deterministic output without timestamps.

**Never manually edit `qsys/dist/f5Rocket_Compat.qplug`.** Change the modular files under `qsys/plugin/`, rebuild, inspect the generated diff, and commit both source and distribution artifact.

## Source modules

- `plugin.lua`: small entry point and include graph
- `info.lua`: stable plugin identity and metadata
- `pages.lua`: `Probe` page population
- `properties.lua`: intentionally empty design-time property population
- `controls.lua`: viewport, operator controls, and diagnostic readouts
- `layout.lua`: panel graphics and control layout only
- `compat.lua`: fixture data, probe constants, and conservative SVG construction
- `runtime.lua`: Timer, event handlers, telemetry, Legend encoding, and `IconData` assignment

Opening a file under `qsys/plugin/` in Qanvas should allow its split-plugin workflow to locate the sibling `plugin.lua` entry point and follow the standard include graph. No custom module loader is used.

## Compatibility plugin

- Distribution: [`dist/f5Rocket_Compat.qplug`](dist/f5Rocket_Compat.qplug)
- Source entry point: [`plugin/plugin.lua`](plugin/plugin.lua)
- Page: `Probe`
- Plugin name: `f5Rocket~Compatibility Probe`
- Version: `0.1.0`
- Stable repository-specific ID: `3c2b6895-8b9b-5d60-9f5f-12f94d8c46f9`
- Viewport control: `Viewport`

The plugin isolates this path:

```text
cached Base64 PNG
→ data:image/png;base64,...
→ runtime-generated 320×480 SVG
→ Base64 SVG
→ rapidjson Button Legend
→ Viewport.IconData
```

It contains one 16×16 test PNG, rendered at 32×32 logical pixels and moved horizontally by integer Lua coordinates. No runtime file access, network access, PNG encoding, game state, enemies, bullets, collision, or scoring is present.

## Install in Q-SYS Designer

1. Build the distribution and close any older copy of the probe in Q-SYS Designer.
2. Copy `qsys/dist/f5Rocket_Compat.qplug` into the user plugin directory under `Documents/QSC/Q-Sys Designer/Plugins/`, or double-click the `.qplug` file if manual installation is enabled on the workstation.
3. Start or restart Q-SYS Designer so it reloads user plugins.
4. Find **f5Rocket > Compatibility Probe** under the User plugins category and drag it into a new design.
5. Open its control panel and select the `Probe` page.
6. Emulate the design for an initial functional check.
7. Repeat the complete matrix on a physical Core; Designer Emulate success is not a substitute for a Core result.

Detailed test steps and a blank results table are in [`compat/README.md`](compat/README.md).

## What the controls test

- `Run` starts/stops one persistent Q-SYS Timer.
- `Rate` switches the same timer between exact intervals `1/30`, `1/20`, and `1/15` seconds.
- `ImageSyntax` changes only the SVG namespace/image attribute between `href` and `xlink:href`.
- `Reset` stops the timer, restores x=0 and counters, and renders one known initial frame while preserving rate and syntax.
- `RequestedHz` and `MeasuredHz` compare the selected interval with successful render ticks measured using `Timer.Now()`.
- `SvgBytes` and `SvgBase64Bytes` report the exact strings used in the current Legend update.
- `LastRenderMs` uses `os.clock()` and is CPU/process-time diagnostic data, not wall-clock frame latency.

## Later plugin work

Only after this probe is recorded in Designer and on a Core should the real game plugin be split further. Likely future modules include `game/state.lua`, `game/player.lua`, `game/enemies.lua`, `game/bullets.lua`, `game/collision.lua`, `renderer/svg.lua`, and `renderer/assets.lua`.

Browser results remain relative scene diagnostics; they are not Q-SYS Core performance evidence.

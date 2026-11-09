# Q-SYS workspace

This directory contains the modular source, deterministic build tool, installable distribution, and test evidence for the f5Rocket Q-SYS compatibility probes. It is intentionally not a port of the browser game.

The original inline PNG-in-SVG path is confirmed working in Q-SYS Designer 10.5.0 at approximately 30 Hz with `<image href="data:image/png;base64,...">`. Version 0.2.0 retains that baseline and adds an SVG `<defs>` plus `<use>` sprite-reuse benchmark.

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

VS Code also provides the default build task **f5Rocket: Build Q-SYS Plugin**, available through the standard build-task shortcut.

The build starts at `qsys/plugin/plugin.lua`, resolves includes relative to their containing files, and writes `qsys/dist/f5Rocket_Compat.qplug`. It detects missing files and circular includes and emits deterministic output without timestamps.

**Never manually edit `qsys/dist/f5Rocket_Compat.qplug`.** Change the modular files under `qsys/plugin/`, rebuild, inspect the generated diff, and commit both source and distribution artifact.

## Source modules

- `plugin.lua`: small entry point and include graph
- `info.lua`: stable plugin identity and metadata
- `pages.lua`: `Probe` page population
- `properties.lua`: intentionally empty design-time property population
- `controls.lua`: viewport, benchmark controls, and diagnostic readouts
- `layout.lua`: panel graphics and control layout only
- `compat.lua`: fixture data, render-mode constants, deterministic grid, cached scene fragments, SVG generation, and payload comparison
- `runtime.lua`: Timer, event handlers, telemetry, Legend encoding, and `IconData` assignment

Opening a file under `qsys/plugin/` in Qanvas should allow its split-plugin workflow to locate the sibling `plugin.lua` entry point and follow the standard include graph. No custom module loader is used.

## Compatibility plugin

- Distribution: [`dist/f5Rocket_Compat.qplug`](dist/f5Rocket_Compat.qplug)
- Source entry point: [`plugin/plugin.lua`](plugin/plugin.lua)
- Page: `Probe`
- Plugin name: `f5Rocket~Compatibility Probe`
- Version: `0.2.0`
- Stable repository-specific ID: `3c2b6895-8b9b-5d60-9f5f-12f94d8c46f9`
- Viewport control: `Viewport`

The plugin isolates this path:

```text
cached Base64 PNG
→ INLINE images or one <defs> image plus repeated <use>
→ runtime-generated 320×480 SVG
→ Base64 SVG
→ rapidjson Button Legend
→ Viewport.IconData
```

It contains one 16×16 test PNG rendered at 32×32 logical pixels. A deterministic grid of 1, 8, 16, 32, or 64 instances moves horizontally using one integer parent-group transform. No runtime file access, network access, PNG encoding, game state, enemies, bullets, collision, or scoring is present.

## Install in Q-SYS Designer

1. Build the distribution and close any older copy of the probe in Q-SYS Designer.
2. Copy `qsys/dist/f5Rocket_Compat.qplug` into the user plugin directory under `Documents/QSC/Q-Sys Designer/Plugins/`, or double-click the `.qplug` file if manual installation is enabled on the workstation.
3. Start or restart Q-SYS Designer so it reloads user plugins.
4. Find **f5Rocket > Compatibility Probe** under the User plugins category and drag it into a new design.
5. Open its control panel and select the `Probe` page.
6. Run the 30 Hz matrix in [`compat/README.md`](compat/README.md).
7. Repeat successful Designer tests on a physical Core; Designer success is not a substitute for a Core result.

## What the controls test

- `Run` starts/stops one persistent Q-SYS Timer.
- `Rate` switches the same timer between exact intervals `1/30`, `1/20`, and `1/15` seconds.
- `RenderMode` selects repeated inline PNG nodes or one definition with repeated uses.
- `InstanceCount` selects a deterministic grid of 1, 8, 16, 32, or 64 sprites.
- `ImageSyntax` retains the original inline `<image>` `href` versus `xlink:href` compatibility capability. Use `href` for the validated baseline.
- `UseSyntax` selects `<use href="#compatSprite">` or `<use xlink:href="#compatSprite">`; it matters only in `DEFS+USE` mode.
- `Reset` stops the timer, restores the motion offset and counters, rebuilds cached comparison data, and renders one known initial frame while preserving selections.
- `PayloadSavings` compares the raw DEFS+USE scene against the equivalent INLINE scene at offset zero. It is recalculated only when configuration changes or Reset occurs.
- `RequestedHz`, `MeasuredHz`, `SvgBytes`, `SvgBase64Bytes`, and `LastRenderMs` retain the original telemetry behavior.

## Later plugin work

Only after sprite reuse is recorded in Designer and on a Core should the real game plugin be split further. Likely future modules include `game/state.lua`, `game/player.lua`, `game/enemies.lua`, `game/bullets.lua`, `game/collision.lua`, `renderer/svg.lua`, and `renderer/assets.lua`.

Browser and static payload results are diagnostics; they are not Q-SYS Core performance evidence.

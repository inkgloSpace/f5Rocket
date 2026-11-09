# Q-SYS workspace

This directory now contains the first standalone Q-SYS compatibility probe. It is intentionally not a port of the browser game.

## Compatibility plugin

- Plugin: [`f5Rocket_Compat.qplug`](f5Rocket_Compat.qplug)
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

1. Close any older copy of this probe in Q-SYS Designer.
2. Copy `f5Rocket_Compat.qplug` into the user plugin directory under `Documents/QSC/Q-Sys Designer/Plugins/`, or double-click the `.qplug` file for manual installation if that behavior is enabled on the workstation.
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

Only after this probe is recorded in Designer and on a Core should the project start the real game `.qplug`. The eventual plugin can then add properties, controls, Lua game state, bounded pools, and the full renderer based on verified syntax/rate/payload constraints.

Browser results remain relative scene diagnostics; they are not Q-SYS Core performance evidence.

# f5Rocket

f5Rocket is a semi-8-bit vertical arcade shooter implemented as a production Q-SYS plugin. The campaign advances through Easy, Medium, and Hard stages, two minibosses, and a final boss.

## Target

- Q-SYS Designer and Q-SYS Core
- 320 × 480 logical game coordinates
- 480 × 720 plugin display
- Fixed 30 Hz update and dynamic-render rate

## Build

From the repository root:

```bash
python3 qsys/tools/build.py
```

`python3 qsys/tools/build.py game` is also accepted. Both commands validate the PNG manifest, regenerate Lua asset data, resolve the Q-SYS include graph, and write:

```text
qsys/dist/f5Rocket.qplug
```

Generated files must not be edited manually.

## Controls

- `Run`: momentary start/restart pulse
- `Pause`: pause/resume toggle
- `Up`, `Down`, `Left`, `Right`: cardinal movement
- `Fire`: held fire using the normal cooldown
- `UL`, `UR`, `DL`, `DR`: touch-friendly diagonal movement
- `AutoFire`: continuous fire using the normal cooldown

Q-SYS input pins are exposed for `Run`, `Pause`, `Up`, `Down`, `Left`, `Right`, and `Fire`. Physical inputs can be combined in the same tick. Cardinal chord assist preserves diagonal intent for touch interfaces.

## Gameplay

- Easy wave: 5,000 stage points, then Mini Boss 1
- Medium wave: 10,000 stage points, then Mini Boss 2
- Hard wave: 15,000 stage points, then the Final Boss
- Regular enemies award 100, 200, or 300 points by stage
- Bosses award 2,500, 5,000, and 15,000 points
- Player death leads to Game Over; defeating the Final Boss leads to Mission Complete

## Rendering architecture

The plugin uses two aligned Button controls:

- `BackgroundViewport` receives a phase background only at initialization, restart, or stage transition.
- `Viewport` receives the transparent gameplay overlay at 30 Hz.

Frames are assembled as conservative SVG strings. PNG sprites are embedded once in `<defs>` and placed with `<use href>`. The complete SVG is Base64-encoded once per frame and assigned through `Viewport.Legend.IconData`. A 64 KiB raw-SVG guard protects the hot rendering path.

The player uses optimized 160 × 240 PNG sources, renders at 56 × 84 logical pixels, and retains a 40 × 48 collision box. Projectiles are lightweight reusable SVG definitions.

## Repository layout

```text
assets/                       Production PNG artwork
qsys/plugins/game/             Authoritative modular Lua source
qsys/plugins/game/generated/   Deterministic generated asset data
qsys/tools/build.py            Production build tool
qsys/dist/f5Rocket.qplug       Generated installable plugin
.vscode/tasks.json             Default production build task
asset_map.json                 Machine-readable asset/runtime metadata
README_ASSETS.txt              Human-readable asset inventory
```

See [qsys/README.md](qsys/README.md) for source-module and Q-SYS validation details.

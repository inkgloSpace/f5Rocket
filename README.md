# f5Rocket

f5Rocket is a semi-8-bit vertical arcade shooter implemented as a production Q-SYS plugin. The campaign advances through Easy, Medium, and Hard stages, two minibosses, and a final boss.

## Target

- Q-SYS Designer and Q-SYS Core
- 320 × 480 logical game coordinates
- 480 × 720 plugin display
- Fixed 30 Hz gameplay update/render rate
- 15 Hz seamless stage-background render rate from the same timer

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
- `Fire`: held fire using the shared burst limiter
- `UL`, `UR`, `DL`, `DR`: touch-friendly diagonal movement
- `AutoFire`: continuous fire using the same burst limiter as manual Fire

Q-SYS input pins are exposed for `Run`, `Pause`, `Up`, `Down`, `Left`, `Right`, and `Fire`. Physical inputs can be combined in the same tick. Cardinal chord assist preserves diagonal intent for touch interfaces.

Player fire supports up to five rapid shots per burst. A complete burst triggers a one-second recovery cooldown. If no successful shot occurs for 0.5 seconds, a partial burst resets automatically. Manual Fire and AutoFire share this limiter.

## Gameplay

- Easy wave: 5,000 stage points, then Mini Boss 1
- Medium wave: 10,000 stage points, then Mini Boss 2
- Hard wave: 15,000 stage points, then the Final Boss
- Regular enemies award 100, 200, or 300 points by stage
- Bosses award 2,500, 5,000, and 15,000 points
- Player death leads to Game Over; defeating the Final Boss leads to Mission Complete

## Rendering architecture

The plugin uses two aligned Button controls driven by one 30 Hz timer:

- `BackgroundViewport` renders the vertically looping stage background at 15 Hz.
- `Viewport` receives the transparent gameplay overlay at 30 Hz.

Each stage background is a seamless 320 × 480 portrait PNG. Its SVG embeds the tile once in `<defs>` and uses two integer-positioned `<use href>` instances to cover the 320 × 480 logical viewport while scrolling downward. The stages progress from the bright alien-controlled upper atmosphere, through a purple asteroid field, into the enemy headquarters. Gameplay frames use the same conservative definitions/reuse strategy. Separate 64 KiB raw-SVG guards protect both rendering paths.

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

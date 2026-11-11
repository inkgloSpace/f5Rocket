# f5Rocket Q-SYS plugin

The authoritative production source is `qsys/plugins/game/`. The installable artifact is generated from that modular source; never edit `qsys/dist/f5Rocket.qplug` manually.

## Source

```text
qsys/plugins/game/
├── plugin.lua              Include-based entry point
├── info.lua                Plugin identity and version
├── controls.lua            UI controls and input-pin metadata
├── layout.lua              480 × 720 game presentation and controls
├── pages.lua               Game page
├── properties.lua          Design-time properties
├── runtime.lua             Timer, input, lifecycle, and Legend assignment
├── game/                   State and deterministic gameplay modules
├── renderer/               SVG asset, parallax, and frame rendering
└── generated/              Generated PNG data; do not edit
```

The game modules cover configuration, state, player movement, bullets, enemies, bosses, collision, explosions, stages, and parallax. Rendering remains separate from gameplay state.

## Build

Run from the repository root:

```bash
python3 qsys/tools/build.py
```

The optional `game` argument is equivalent:

```bash
python3 qsys/tools/build.py game
```

The standard-library-only builder:

1. validates each manifest file as PNG with a valid IHDR;
2. writes deterministic `qsys/plugins/game/generated/assets_data.lua`;
3. recursively expands `--[[ #include "file.lua" ]]` directives;
4. rejects missing files, include cycles, and source-tree escapes;
5. writes `qsys/dist/f5Rocket.qplug` without timestamps.

## Generated asset data

The asset generator separates dynamic gameplay sprites from seamless stage-background tiles. Dynamic PNG definitions are embedded in the 30 Hz gameplay SVG once and reused with `<use href>`. Each 320 × 240 background PNG is embedded once in its own SVG `<defs>` block and repeated through three `<use href>` instances.

The player PNGs are optimized 160 × 240 sources. They render at 56 × 84 logical pixels while collision and movement continue to use a 40 × 48 box. Player and hostile projectiles are reusable 6 × 14 SVG definitions, so no projectile PNG payload is required.

## Runtime architecture

- One global `GameTimer` at 30 Hz
- Momentary `Run` starts or restarts the campaign
- Toggle `Pause` stops and restarts the same timer without resetting state
- 320 × 480 logical coordinates displayed at 480 × 720
- Scrolling `BackgroundViewport` plus transparent dynamic `Viewport`
- Gameplay SVG and `Viewport.Legend` update at 30 Hz
- A render divider of 2 updates the background SVG and `BackgroundViewport.Legend` at 15 Hz
- Deterministic stage, boss, parallax, pool, and input logic
- One gameplay SVG build, Base64 encode, and `Viewport.Legend` assignment per game frame
- Separate 64 KiB raw-SVG safety guards for gameplay and background frames

## Controls and input pins

The page provides Run, Pause, eight-direction touch movement, Fire, AutoFire, and Status. Input pins are exposed for:

```text
Run
Pause
Up
Down
Left
Right
Fire
```

Movement and Fire inputs are sampled inside the game tick. Their controls have no runtime event handlers, so simultaneous physical input remains supported.

## Asset constraints

- Keep hot-frame PNGs compact; their data URIs are repeated inside each dynamic SVG payload.
- Keep the 320 × 240 seamless stage tiles out of the 30 Hz gameplay frame.
- Preserve the optimized player sources unless a deliberate asset-pipeline change is made.
- Update `qsys/tools/build.py`, `renderer/assets.lua`, `asset_map.json`, and `README_ASSETS.txt` together when changing the manifest.

## Validation checklist

1. Run `python3 qsys/tools/build.py` twice and confirm identical output hashes.
2. Load `qsys/dist/f5Rocket.qplug` in Q-SYS Designer.
3. Confirm the Easy background and READY state.
4. Test Run restart, Pause/resume, movement, diagonal controls, Fire, and AutoFire.
5. Exercise all three waves, both minibosses, the final boss, Game Over, and Mission Complete.
6. Confirm stage backgrounds scroll downward without a seam, pause with the game, and reset at stage changes.
7. Confirm gameplay remains at 30 Hz while the background updates at 15 Hz.
8. Confirm gameplay and background frames remain under their 64 KiB raw guards.

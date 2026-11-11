# f5Rocket Q-SYS plugin

The authoritative production source is `qsys/plugins/game/`. The installable artifact is generated from that modular source; never edit `qsys/dist/f5Rocket.qplug` manually.

## Source

```text
qsys/plugins/game/
├── plugin.lua              Include-based entry point
├── info.lua                Plugin identity and version
├── controls.lua            UI controls and input-pin metadata
├── layout.lua              Three 480 × 720 page layouts
├── pages.lua               Game, Controls, and About pages
├── properties.lua          Design-time properties
├── runtime.lua             Timer, input, lifecycle, and Legend assignment
├── game/                   State and deterministic gameplay modules
├── renderer/               SVG asset, parallax, and frame rendering
└── generated/              Generated PNG data; do not edit

qsys/control-scripts/
└── f5Rocket_USB_Keyboard.lua
                             Standalone Core USB-A HID keyboard controller
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

The asset generator separates dynamic gameplay sprites from seamless stage-background tiles. At runtime, each 30 Hz gameplay frame embeds only the PNG definitions it actually needs: one current player direction when alive, one current-stage enemy when visible, one active boss when present, and only the unique visible explosion frames. Every required asset is defined at most once per frame, while repeated objects reuse it through `<use href>`. Each 320 × 480 portrait background PNG is embedded once in its own SVG `<defs>` block and repeated through two `<use href>` instances.

The visual progression is Easy/upper atmosphere, Medium/outer space and asteroids, then Hard/inside the alien headquarters. The alien insignia belongs to the enemy faction; the Q-SYS/F5 rocket remains the player hero.

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
- Static SVG fallbacks, projectile geometry, and parallax definitions are prebuilt once
- Dynamic PNG `<image>` definitions are prebuilt individually, then selected per frame
- Per-stage background SVG prefixes are prebuilt; each 15 Hz frame appends only two tile positions
- Fully frozen Game Over and Mission Complete states stop the same `GameTimer` after the final visible frame is assigned; `Run` can still restart normally

This keeps simulation and gameplay rendering at 30 Hz and background rendering at 15 Hz while removing the former all-assets DataURI payload from ordinary frames. Fixed object pools, collision loops, gameplay timing, and the single-timer lifecycle remain unchanged.

## Controls and input pins

The plugin UI is split into three pages:

- Page 1 — `Game`: only the aligned 480 × 720 background and gameplay viewports.
- Page 2 — `Controls`: neutral-grey structural background, panels, and borders with distinct functional colors retained for Run, Pause, eight-direction touch movement, Fire, and AutoFire.
- Page 3 — `About`: the same neutral-grey page background as Controls, with static text-only description, operating help, control options, version, and project URL, and no visible GroupBox or card sections.

Controls and About use the same explicit neutral-grey full-page background instead of relying on Q-SYS Designer theme defaults. Controls retains neutral structural panels plus distinct functional button colors and high-contrast legends. About uses only one borderless background surface and static typography; it has no visible GroupBox or card sections.

The former Status text control was intentionally removed because READY, PAUSED, Game Over, Mission Complete, and stage feedback are already rendered inside the gameplay viewport. Input pins remain exposed for:

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

For Q-SYS Designer Emulate on Windows, `tools/f5Rocket_Keyboard.exe` connects to QRC at `127.0.0.1:1710`; its tracked source is `tools/f5Rocket_Keyboard.cpp`, and `.github/workflows/build-keyboard-bridge.yml` rebuilds the executable. Both the Windows bridge and the Core USB controller require the plugin component Code Name `f5Rocket`; the Core path also requires Script Access.

## Core USB HID keyboard controller

A physical keyboard connected to a Core USB-A host port can control the game through:

```text
qsys/control-scripts/f5Rocket_USB_Keyboard.lua
```

This is a standalone Q-SYS Control Script and is not embedded into `f5Rocket.qplug`.

Requirements:

1. Remove the Q-SYS `USB Input` component from the design.
2. Set the f5Rocket plugin component **Code Name** to `f5Rocket`.
3. Set f5Rocket **Script Access** to `All`.
4. Add a Q-SYS Control Script component to the schematic.
5. Paste/use `f5Rocket_USB_Keyboard.lua` in the Control Script.
6. Run the design on the physical Core.
7. Connect a standard USB HID keyboard to a Core USB-A host port.

The script uses:

```text
UsbMonitor.New("input")
Usb.New(devnode)
Component.New("f5Rocket")
```

The script enumerates the component controls with `pairs(game)`, stores them as `gameControls[string.lower(tostring(name))]`, and resolves all controls through `GetGameControl(name)`. This case-insensitive lookup is intentional and must not be replaced by direct component member access.

The implementation uses raw numeric Linux/Q-SYS key codes to avoid dependency on potentially different `Usb.Key.*` enum names:

```text
ESC       1
W        17
P        25
ENTER    28
A        30
S        31
D        32
SPACE    57
KP_ENTER 96
UP      103
LEFT    105
RIGHT   106
DOWN    108
```

Only numeric Type `1` keyboard events are processed. Event values are interpreted as:

```text
0 = release
1 = press
2 = repeat / held
```

Repeat events return without changing state or generating duplicate command actions. `deviceKeyStates[devnode]` records each endpoint independently, while `globalKeyCounts[code]`, `IsKeyDown()`, `IncrementKey()`, and `DecrementKey()` combine them globally. `RefreshContinuousControls()` then preserves true simultaneous input such as `W + D + Space`.

Keyboard mapping:

```text
W / Up Arrow       Up
S / Down Arrow     Down
A / Left Arrow     Left
D / Right Arrow    Right
Space              Fire
Enter / KP Enter   Run
Esc                Stop
P                  Pause toggle
```

Enter/KP Enter, Esc, and P act only on the global up-to-down transition. Therefore multiple event endpoints cannot duplicate Run, Stop, or Pause commands. Esc writes `Run = false`; Enter/KP Enter writes `Run = true`; P toggles Pause.

On USB keyboard removal, `ReleaseDeviceKeys(devnode)` decrements every held global key count, refreshes movement/Fire, and then removes the corresponding `Usb` object. This prevents latched gameplay input.

For this project, do **not** use the Q-SYS `USB Input` component alongside this direct Lua HID controller. It must be removed so the proven `UsbMonitor.New("input")` / `Usb.New(devnode)` path owns keyboard input.

## Player firing limits

- Normal shot interval: 5 ticks
- Maximum burst: 5 successful shots
- Full-burst cooldown: 30 ticks / 1 second
- Partial-burst reset: 15 ticks / 0.5 second without a successful shot

Manual Fire and AutoFire both use the same `FirePlayerBullet` path. Failed fire requests do not increment the burst counter.

## Asset constraints

- Keep hot-frame PNGs compact; their data URIs are repeated inside each dynamic SVG payload.
- Keep the 320 × 480 seamless stage tiles out of the 30 Hz gameplay frame.
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
9. On a real Core, test the USB HID keyboard script with W/A/S/D, arrows, Space, Enter, P, simultaneous keys, and unplug/replug cleanup.

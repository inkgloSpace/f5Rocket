# f5Rocket Q-SYS sprite-reuse compatibility benchmark

This directory contains the deterministic fixture and test procedure for the generated [`../dist/f5Rocket_Compat.qplug`](../dist/f5Rocket_Compat.qplug). The editable source lives under [`../plugin/`](../plugin/), with [`../plugin/plugin.lua`](../plugin/plugin.lua) as its include-based entry point.

The baseline `<image href="data:image/png;base64,...">` path is confirmed working in Q-SYS Designer 10.5.0 at approximately 30 Hz. This benchmark asks whether the same renderer supports one PNG in `<defs>` followed by repeated `<use>` instances, and whether the resulting payload reduction remains stable during dynamic `IconData` refresh.

This is not the game plugin.

## Fixture

[`fixture.png`](fixture.png) is a deterministic semi-8-bit airplane marker:

- Dimensions: 16×16 RGBA
- PNG size: 157 bytes
- Base64 size: 212 characters/bytes
- SHA-256: `dd7b2706ac8ff988b633aa93bc0136b4458c7f0da670e2811c546f28c207af2a`
- Runtime display size: 32×32 logical pixels
- Classification: **COMPATIBILITY TEST ASSET — NOT PRODUCTION ART**

The plugin includes the byte-identical Base64 PNG as a Lua constant. It never reads, regenerates, decodes, or re-encodes the PNG at runtime.

## Render strategies

`RenderMode = INLINE` is the known-good control. It repeats the complete data URI for every instance:

```xml
<g transform="translate(OFFSET 0)">
  <image href="data:image/png;base64,..." x="18" y="88" width="32" height="32" preserveAspectRatio="none"/>
  ...
</g>
```

`ImageSyntax` retains the earlier `href` versus `xlink:href` image test. Keep it at `href` for the validated baseline.

`RenderMode = DEFS+USE` stores the PNG once and references it from every instance:

```xml
<defs>
  <image id="compatSprite" href="data:image/png;base64,..." width="32" height="32" preserveAspectRatio="none"/>
</defs>
<g transform="translate(OFFSET 0)">
  <use href="#compatSprite" x="18" y="88"/>
  ...
</g>
```

The definition always uses the already validated PNG `href` syntax. `UseSyntax` changes only the reference nodes:

- `href` emits `<use href="#compatSprite" .../>` without an xlink namespace.
- `xlink:href` adds `xmlns:xlink="http://www.w3.org/1999/xlink"` and emits `<use xlink:href="#compatSprite" .../>`.

Use `xlink:href` only if Q-SYS rejects `<use href>`. `UseSyntax` has no effect in `INLINE` mode.

## Layout and animation

`InstanceCount` supports `1`, `8`, `16`, `32`, and `64`. Instances occupy a deterministic eight-column grid. At the maximum count and motion offset, the rightmost sprite ends at logical x=318 and the lowest sprite ends at logical y=400, inside the 320×480 viewport.

The grid is cached when configuration changes. Every timer tick changes one integer `motionOffset` from 0 through 16 and inserts it into the parent group transform, so `IconData` continues changing without rebuilding individual positions.

## Payload telemetry

The runtime path remains:

```text
cached scene fragments + current motionOffset
→ one SVG string
→ Crypto.Base64Encode(svg) once
→ SvgBytes / SvgBase64Bytes
→ rapidjson-encoded reusable Button Legend
→ Controls.Viewport.Legend
```

`PayloadSavings` is the raw-byte reduction of DEFS+USE compared with INLINE at the same instance count, using motion offset zero and the selected syntax controls. The comparison is rebuilt only when configuration changes or Reset occurs, never on every timer tick.

Q-SYS debug output also reports the expected PNG payload occurrence count. INLINE has one occurrence per instance; DEFS+USE has exactly one.

## Static payload benchmark

These values use the exact version 0.2.0 SVG structure, `href` for both image and use syntax, and motion offset zero. A two-digit live offset adds one raw byte; the live telemetry is authoritative for the current frame.

| Mode | Instances | Raw SVG bytes | Base64 SVG bytes | PNG Base64 occurrences | Raw savings vs INLINE |
|---|---:|---:|---:|---:|---:|
| INLINE | 1 | 789 | 1,052 | 1 | — |
| INLINE | 8 | 2,992 | 3,992 | 8 | — |
| INLINE | 16 | 5,517 | 7,356 | 16 | — |
| INLINE | 32 | 10,567 | 14,092 | 32 | — |
| INLINE | 64 | 20,667 | 27,556 | 64 | — |
| DEFS+USE | 1 | 847 | 1,132 | 1 | -7.4% |
| DEFS+USE | 8 | 1,139 | 1,520 | 1 | 61.9% |
| DEFS+USE | 16 | 1,480 | 1,976 | 1 | 73.2% |
| DEFS+USE | 32 | 2,162 | 2,884 | 1 | 79.5% |
| DEFS+USE | 64 | 3,526 | 4,704 | 1 | 82.9% |

The one-instance DEFS+USE scene is larger because `<defs>` adds fixed overhead. Reuse becomes increasingly advantageous as instance count grows.

## Timing modes

One globally scoped `ProbeTimer = Timer.New()` is created at startup. The selected rate restarts that same timer with:

- `30 Hz` → `1 / 30` seconds
- `20 Hz` → `1 / 20` seconds
- `15 Hz` → `1 / 15` seconds

`MeasuredHz` counts successful render ticks over approximately one-second windows measured with `Timer.Now()`. `LastRenderMs` uses `os.clock()`, which reports CPU/process-time semantics and must not be interpreted as precise wall-clock frame latency.

## Q-SYS test sequence

1. Build and install the plugin using [`../README.md`](../README.md).
2. Open `Probe`; confirm defaults are `INLINE`, `16`, image `href`, use `href`, rate `30 Hz`, and status `IDLE`.
3. Run `INLINE / 1 / 30 Hz` for at least 30 seconds. Record visibility, stable motion, measured rate, payloads, render time, and CPU observation.
4. Repeat INLINE at `16`, `32`, and `64` instances.
5. Select `DEFS+USE` with `UseSyntax = href`; repeat counts `1`, `16`, `32`, and `64` at 30 Hz.
6. Confirm DEFS+USE shows every requested sprite, all instances move together, and its PNG payload count in debug output is one.
7. Compare `SvgBytes`, `SvgBase64Bytes`, and `PayloadSavings` with the static table. Small size changes from a two-digit offset are expected.
8. Only if `<use href>` fails, change `UseSyntax` to `xlink:href` and repeat the failing case.
9. After the 30 Hz matrix, use 20 Hz and 15 Hz to distinguish syntax/rendering failure from update-rate pressure.
10. Press Reset and confirm motion, ticks, and measurement counters reset while selected mode/count/syntax/rate remain selected.
11. Watch debug output for `[f5Rocket Compat] Render error:` and preserve the full error text.
12. Repeat successful Designer tests on a physical Core.

## Results

Primary validation uses 30 Hz and PNG `ImageSyntax = href`. Fill the xlink rows only if `<use href>` fails.

| Environment | QDS/Core version | Mode | Use syntax | Instances | Requested Hz | Measured Hz | All sprites visible | Motion stable | Raw SVG bytes | Base64 bytes | Savings | CPU observation | Notes |
|---|---|---|---|---:|---:|---:|---|---|---:|---:|---:|---|---|
|  |  | INLINE | N/A | 1 | 30 |  |  |  |  |  | N/A |  |  |
|  |  | INLINE | N/A | 16 | 30 |  |  |  |  |  | N/A |  |  |
|  |  | INLINE | N/A | 32 | 30 |  |  |  |  |  | N/A |  |  |
|  |  | INLINE | N/A | 64 | 30 |  |  |  |  |  | N/A |  |  |
|  |  | DEFS+USE | href | 1 | 30 |  |  |  |  |  |  |  |  |
|  |  | DEFS+USE | href | 16 | 30 |  |  |  |  |  |  |  |  |
|  |  | DEFS+USE | href | 32 | 30 |  |  |  |  |  |  |  |  |
|  |  | DEFS+USE | href | 64 | 30 |  |  |  |  |  |  |  |  |

## Success criteria

- INLINE remains visible and stable at the known-good 30 Hz baseline.
- DEFS+USE displays every requested instance using at least one use-reference syntax.
- The entire group moves without missing, duplicated, or stale sprites.
- TickCount and measured rate continue without stalls.
- Payload reduction follows the expected trend without runaway CPU behavior.
- Reset and runtime configuration changes work without creating another timer.

Designer success does not replace a physical Core test. Only Q-SYS testing can establish `<use>` support, actual `IconData` refresh behavior, Core CPU impact, timer stability, and practical payload limits.

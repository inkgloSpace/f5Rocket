# Q-SYS PNG-in-SVG compatibility fixture

This directory defines the first payload to reproduce in Lua. It is documentation only; it is not a complete `.qplug` and contains no production artwork.

## Intended transformation

```text
PNG bytes
→ Base64 PNG
→ data:image/png;base64,...
→ embedded inside SVG <image>
→ complete SVG string
→ Base64 SVG
→ rapidjson-encoded Button Legend
→ Button IconData
```

The browser's prepared asset entry corresponds to the first three steps. `window.__f5Rocket.getSvg()` returns the exact output of the SVG step, and `getDiagnostics()` reports the UTF-8 byte count plus the expected Base64 SVG length.

## Conservative probe scene

The first Lua fixture should generate this shape, replacing `{PNG_BASE64}` and integer `x` with runtime values:

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 480" width="320" height="480" shape-rendering="crispEdges">
  <rect width="320" height="480" fill="#07101f"/>
  <g transform="translate({x} 420)">
    <image href="data:image/png;base64,{PNG_BASE64}" x="0" y="0" width="32" height="40" preserveAspectRatio="none"/>
  </g>
</svg>
```

No external image path, CSS animation, filter, mask, script, or `<foreignObject>` belongs in the probe. Lua should cache the Base64 PNG/data URI before the timer starts; each approximately 30 Hz tick should change only the integer position, rebuild the small SVG string, Base64-encode that SVG, and update the one viewport Button.

## Results to record in Q-SYS Designer/Core

1. Accepted SVG data-URI syntax and whether `href` needs an alternate attribute on the target Q-SYS version.
2. Exact rapidjson Button Legend structure and `IconData` assignment behavior.
3. Stable refresh rates at 30 Hz, 20 Hz, and 15 Hz.
4. Core CPU, Lua execution time, memory behavior, and practical raw/Base64 payload limits.
5. Visual scaling and crisp integer-coordinate motion in the 320×480 viewport.

Browser results are parity diagnostics, not Core performance evidence.

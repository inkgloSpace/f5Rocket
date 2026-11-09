# Future Q-SYS workspace

This directory is reserved for the future Q-SYS plugin. Phase 1 intentionally contains no `.qplug` implementation: browser gameplay should remain easy to iterate while the first Core/Designer compatibility assumptions are still unverified.

## Planned plugin structure

The future `.qplug` will define the standard pieces explicitly:

- `PluginInfo` for identity, version, and metadata
- `GetProperties` for configurable timing/debug options
- `GetControls` for one game viewport Button plus only necessary operator controls
- `GetPages` for the plugin UI page definition
- `GetControlLayout` for the portrait viewport and supporting controls
- runtime Lua containing simple game-state tables, fixed-step updates, pooling, and SVG generation
- one primary 320×480 game viewport Button
- dynamic Button `IconData`, updated from a serialized/Base64 SVG scene
- a deliberate PNG-in-SVG compatibility result before committing to the full asset pipeline
- a Q-SYS `Timer` targeting approximately 30 Hz, with 20 Hz and 15 Hz fallback tests

The Lua state and renderer should remain separate, matching `src/game.js` and `src/renderer-svg.js`. The runtime should use arrays/tables, explicit loops, integer sprite placement, simple transforms, and bounded pools.

## First Q-SYS milestone: compatibility probe

Build only this vertical slice:

```text
1 player PNG
→ embedded in a dynamically generated 320×480 SVG
→ moved each timer tick at approximately 30 Hz
→ SVG serialized and Base64-encoded
→ displayed through one Button's IconData
```

Measure and record:

1. Whether the target Q-SYS version accepts the selected PNG reference form inside SVG (data URI or another supported representation).
2. Whether dynamic `IconData` refreshes reliably at approximately 30 Hz.
3. Core CPU impact, Lua execution time, memory behavior, and practical SVG/Base64 payload size.
4. Visual crispness and coordinate parity at 320×480.
5. Behavior at 20 Hz and 15 Hz before choosing the production update/render rate.

Browser results are useful for relative scene-size comparisons only; they are not Q-SYS Core performance evidence.

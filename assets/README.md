# Artwork drop zone

All production artwork will be supplied by the project owner as PNG files. No third-party or generated replacement artwork belongs here.

Expected filenames:

```text
player/player_idle.png
player/player_left.png
player/player_right.png
enemy/enemy_01.png
bullet/player_bullet.png
bullet/enemy_bullet.png
explosion/explosion_01.png
explosion/explosion_02.png
explosion/explosion_03.png
background/background_tile.png
```

The current logical placeholder sizes are 32×40 for the player, 30×28 for the enemy, 4×12 for a player bullet, 6×8 for an enemy bullet, and 32×32 for explosions. Source PNGs can use another native size because SVG sets their logical display size; artwork with matching aspect ratios will be easiest to validate.

Missing files are expected during development. `src/assets.js` fetches each configured file once at startup, validates its PNG signature, converts it once to a complete `data:image/png;base64,...` URI, and freezes the prepared entry. `src/renderer-svg.js` reads only that cached string during gameplay and swaps only that sprite's labeled SVG placeholder for an `<image>` node.

Each prepared entry records its source path, availability, MIME type, data URI, source byte count, Base64 character count, full data-URI byte count, and decoded dimensions. Missing entries include a diagnostic error but never stop the game.

Keep PNGs optimized and avoid renaming them without updating the explicit manifest. Repeated sprites reuse the same cached JavaScript string, while each SVG `<image>` still carries a self-contained data URI as required for the intended Q-SYS payload. Q-SYS PNG-in-SVG behavior and usable payload sizes still need to be measured in the compatibility probe.

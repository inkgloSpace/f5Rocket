# Artwork drop zone

All production artwork will be supplied by the project owner as PNG files. This root tree is shared by the browser prototype and the Q-SYS production build; do not maintain a second manually duplicated Q-SYS artwork folder. No third-party or generated replacement artwork belongs here.

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

The Q-SYS logical sizes are 32×40 for the player, 28×28 for the enemy, 6×12 for a player bullet, 6×8 for an enemy bullet, 32×32 for explosions, and 320×480 for the background tile. Source PNGs can use another native size because SVG sets their logical display size; artwork with matching aspect ratios will be easiest to validate.

Missing files are expected during development. `src/assets.js` handles browser preparation. For Q-SYS, `python3 qsys/tools/build.py game` validates each available PNG signature and IHDR, Base64-encodes it once, and generates `qsys/plugins/game/generated/assets_data.lua`. Missing entries are generated as unavailable and keep SVG debug fallbacks active; invalid files at an expected PNG path fail the build.

Each generated Q-SYS entry records its source path, availability, MIME type, data URI, source byte count, Base64 character count, and decoded dimensions. The generated Lua file is committed for reproducible installation but must never be edited manually.

Keep PNGs optimized and avoid renaming them without updating both explicit manifests. The Q-SYS renderer places each available PNG once in SVG `<defs>` and emits repeated `<use href="#assetId">` instances. This path is validated in Q-SYS Designer 10.5.0; real artwork payloads and physical Core cost still need measurement.

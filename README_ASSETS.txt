f5Rocket production asset inventory

Stage backgrounds are vertically seamless production tiles rendered only in BackgroundViewport. Each tile is embedded once in SVG <defs> and repeated with three <use href> instances. Dynamic gameplay PNGs use the same definitions/reuse principle in the transparent gameplay viewport.

path | PNG pixels | bytes | logical use
assets/background/background_easy_loop.png | 320x240 | 32729 | seamless Easy scrolling tile; BackgroundViewport only
assets/background/background_medium_loop.png | 320x240 | 39704 | seamless Medium scrolling tile; BackgroundViewport only
assets/background/background_hard_loop.png | 320x240 | 36099 | seamless Hard scrolling tile; BackgroundViewport only
assets/boss/mini_boss_easy.png | 72x56 | 2323 | dynamic sprite, 72x56
assets/boss/mini_boss_medium.png | 88x64 | 2944 | dynamic sprite, 88x64
assets/boss/final_boss.png | 120x80 | 4149 | dynamic sprite, 120x80
assets/enemy/enemy_easy.png | 34x34 | 1465 | dynamic Easy enemy, 34x34
assets/enemy/enemy_medium.png | 34x34 | 805 | dynamic Medium enemy, 34x34
assets/enemy/enemy_hard.png | 34x34 | 797 | dynamic Hard enemy, 34x34
assets/explosion/explosion_01.png | 44x44 | 1273 | dynamic explosion frame, 44x44
assets/explosion/explosion_02.png | 44x44 | 2918 | dynamic explosion frame, 44x44
assets/explosion/explosion_03.png | 44x44 | 4220 | dynamic explosion frame, 44x44
assets/player/player_idle.png | 160x240 | 3174 | render 56x84; collision 40x48
assets/player/player_left.png | 160x240 | 3018 | render 56x84; collision 40x48
assets/player/player_right.png | 160x240 | 3198 | render 56x84; collision 40x48

Player source pixels, logical render dimensions, and collision dimensions are intentionally independent. The 160x240 source and 56x84 render envelope both use a 2:3 aspect ratio.

Player and hostile bullets have no PNG assets. They are reusable 6x14 SVG geometry with separate cyan/white and magenta/white palettes; the same 6x14 dimensions are used for collision.

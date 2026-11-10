local ASSET_MANIFEST = {
  { Id = "player_idle", Source = "assets/player/player_idle.png", Width = 40, Height = 48 },
  { Id = "player_left", Source = "assets/player/player_left.png", Width = 40, Height = 48 },
  { Id = "player_right", Source = "assets/player/player_right.png", Width = 40, Height = 48 },
  { Id = "enemy_easy", Source = "assets/enemy/enemy_easy.png", Width = 34, Height = 34 },
  { Id = "enemy_medium", Source = "assets/enemy/enemy_medium.png", Width = 34, Height = 34 },
  { Id = "enemy_hard", Source = "assets/enemy/enemy_hard.png", Width = 34, Height = 34 },
  { Id = "bullet_player", Source = "assets/bullet/player_bullet.png", Width = 10, Height = 22 },
  { Id = "bullet_enemy", Source = "assets/bullet/enemy_bullet.png", Width = 10, Height = 16 },
  { Id = "explosion_01", Source = "assets/explosion/explosion_01.png", Width = 44, Height = 44 },
  { Id = "explosion_02", Source = "assets/explosion/explosion_02.png", Width = 44, Height = 44 },
  { Id = "explosion_03", Source = "assets/explosion/explosion_03.png", Width = 44, Height = 44 },
  { Id = "mini_boss_easy", Source = "assets/boss/mini_boss_easy.png", Width = 72, Height = 56 },
  { Id = "mini_boss_medium", Source = "assets/boss/mini_boss_medium.png", Width = 88, Height = 64 },
  { Id = "final_boss", Source = "assets/boss/final_boss.png", Width = 120, Height = 80 },
  { Id = "background_easy", Source = "assets/background/background_easy.png", Width = 320, Height = 480 },
  { Id = "background_medium", Source = "assets/background/background_medium.png", Width = 320, Height = 480 },
  { Id = "background_hard", Source = "assets/background/background_hard.png", Width = 320, Height = 480 },
  { Id = "qsys_q_mark", Source = "assets/branding/qsys_q_mark.png", Width = 64, Height = 64 },
  { Id = "enemy_01", Source = "assets/enemy/enemy_01.png", Width = 34, Height = 34 },
  { Id = "background_tile", Source = "assets/background/background_tile.png", Width = 320, Height = 480 }
}

local DYNAMIC_GAMEPLAY_ASSETS = GENERATED_DYNAMIC_GAMEPLAY_ASSET_IDS
local STATIC_BACKGROUND_ASSETS = GENERATED_STATIC_BACKGROUND_ASSET_IDS
local BRANDING_ASSETS = GENERATED_BRANDING_ASSET_IDS

local FALLBACK_PLAYER_DEFINITION =
  "<g id=\"fallback_player\"><polygon points=\"20,0 39,44 25,38 20,48 15,38 1,44\" fill=\"#46e6e1\"/>" ..
  "<rect x=\"16\" y=\"17\" width=\"8\" height=\"20\" fill=\"#ffffff\"/></g>"

local FALLBACK_ENEMY_DEFINITION =
  "<g id=\"fallback_enemy\"><rect width=\"34\" height=\"34\" fill=\"#ff5c68\"/>" ..
  "<path d=\"M5 9H29L24 29H10Z\" fill=\"#791f3d\"/></g>"

local FALLBACK_PLAYER_BULLET_DEFINITION =
  "<g id=\"fallback_player_bullet\"><rect width=\"10\" height=\"22\" fill=\"#5ffcff\"/></g>"

local FALLBACK_ENEMY_BULLET_DEFINITION =
  "<g id=\"fallback_enemy_bullet\"><rect width=\"10\" height=\"16\" fill=\"#ff6b9d\"/></g>"

local FALLBACK_EXPLOSION_DEFINITION =
  "<g id=\"fallback_explosion\"><path d=\"M22 0L27 15L44 22L27 29L22 44L17 29L0 22L17 15Z\" fill=\"#ff9b45\"/></g>"

local FALLBACK_BOSS_EASY_DEFINITION =
  "<g id=\"fallback_boss_easy\"><rect width=\"72\" height=\"56\" fill=\"#42d9ff\"/>" ..
  "<rect x=\"12\" y=\"12\" width=\"48\" height=\"32\" fill=\"#135f8a\"/></g>"

local FALLBACK_BOSS_MEDIUM_DEFINITION =
  "<g id=\"fallback_boss_medium\"><rect width=\"88\" height=\"64\" fill=\"#ba65ff\"/>" ..
  "<rect x=\"14\" y=\"14\" width=\"60\" height=\"36\" fill=\"#572080\"/></g>"

local FALLBACK_BOSS_FINAL_DEFINITION =
  "<g id=\"fallback_boss_final\"><rect width=\"120\" height=\"80\" fill=\"#ff3d9b\"/>" ..
  "<rect x=\"18\" y=\"16\" width=\"84\" height=\"48\" fill=\"#4a1038\"/></g>"

local ASSETS = {}
local DYNAMIC_DEFINITION_PARTS = {}
local RUNTIME_DEFINITION_AVAILABLE = {}
local MISSING_ASSET_PATHS = {}
local availableAssetCount = 0

for index = 1, #ASSET_MANIFEST do
  local metadata = ASSET_MANIFEST[index]
  local generated = GENERATED_ASSET_DATA[metadata.Id]
  local available = generated ~= nil and generated.Available and generated.DataUri ~= ""

  ASSETS[metadata.Id] = {
    Id = metadata.Id,
    Source = metadata.Source,
    Width = metadata.Width,
    Height = metadata.Height,
    Available = available,
    DataUri = available and generated.DataUri or "",
    SourceBytes = available and generated.SourceBytes or 0,
    EncodedBytes = available and generated.EncodedBytes or 0
  }

  if available then
    availableAssetCount = availableAssetCount + 1
    if DYNAMIC_GAMEPLAY_ASSETS[metadata.Id] then
      DYNAMIC_DEFINITION_PARTS[#DYNAMIC_DEFINITION_PARTS + 1] =
        "<image id=\"" .. metadata.Id .. "\" href=\"" .. generated.DataUri ..
        "\" width=\"" .. tostring(metadata.Width) .. "\" height=\"" ..
        tostring(metadata.Height) .. "\" preserveAspectRatio=\"none\"/>"
      RUNTIME_DEFINITION_AVAILABLE[metadata.Id] = true
    end
  else
    MISSING_ASSET_PATHS[#MISSING_ASSET_PATHS + 1] = metadata.Source
  end
end

local function RuntimeSourceId(assetId, fallbackId)
  if RUNTIME_DEFINITION_AVAILABLE[assetId] then
    return assetId
  end
  return fallbackId
end

local ENEMY_ORIENTATION_DEFINITIONS = table.concat({
  "<g id=\"enemy_easy_down\"><use href=\"#" .. RuntimeSourceId("enemy_easy", "fallback_enemy") ..
    "\" transform=\"rotate(180 17 17)\"/></g>",
  "<g id=\"enemy_medium_down\"><use href=\"#" .. RuntimeSourceId("enemy_medium", "fallback_enemy") ..
    "\" transform=\"rotate(180 17 17)\"/></g>",
  "<g id=\"enemy_hard_down\"><use href=\"#" .. RuntimeSourceId("enemy_hard", "fallback_enemy") ..
    "\" transform=\"rotate(180 17 17)\"/></g>"
})

local BOSS_ORIENTATION_DEFINITIONS = table.concat({
  "<g id=\"boss_mini_easy_down\"><use href=\"#" ..
    RuntimeSourceId("mini_boss_easy", "fallback_boss_easy") ..
    "\" transform=\"rotate(180 36 28)\"/></g>",
  "<g id=\"boss_mini_medium_down\"><use href=\"#" ..
    RuntimeSourceId("mini_boss_medium", "fallback_boss_medium") ..
    "\" transform=\"rotate(180 44 32)\"/></g>",
  "<g id=\"boss_final_down\"><use href=\"#" ..
    RuntimeSourceId("final_boss", "fallback_boss_final") ..
    "\" transform=\"rotate(180 60 40)\"/></g>"
})

local DYNAMIC_GAMEPLAY_DEFINITIONS = table.concat(DYNAMIC_DEFINITION_PARTS) ..
  FALLBACK_PLAYER_DEFINITION .. FALLBACK_ENEMY_DEFINITION ..
  FALLBACK_PLAYER_BULLET_DEFINITION .. FALLBACK_ENEMY_BULLET_DEFINITION ..
  FALLBACK_EXPLOSION_DEFINITION .. FALLBACK_BOSS_EASY_DEFINITION ..
  FALLBACK_BOSS_MEDIUM_DEFINITION .. FALLBACK_BOSS_FINAL_DEFINITION ..
  ENEMY_ORIENTATION_DEFINITIONS .. BOSS_ORIENTATION_DEFINITIONS

local function AssetAvailable(assetId)
  local asset = ASSETS[assetId]
  return asset ~= nil and asset.Available
end

local function RuntimeDefinitionAvailable(assetId)
  return RUNTIME_DEFINITION_AVAILABLE[assetId] == true
end

local function AppendDefinitionUse(parts, definitionId, x, y)
  parts[#parts + 1] = "<use href=\"#" .. definitionId .. "\" x=\"" ..
    tostring(math.floor(x)) .. "\" y=\"" .. tostring(math.floor(y)) .. "\"/>"
end

local function AppendSpriteUse(parts, assetId, fallbackId, x, y)
  AppendDefinitionUse(parts, RuntimeSourceId(assetId, fallbackId), x, y)
end

local function ResolvePlayerDefinition(direction)
  if direction == "left" and RuntimeDefinitionAvailable("player_left") then
    return "player_left"
  end
  if direction == "right" and RuntimeDefinitionAvailable("player_right") then
    return "player_right"
  end
  return RuntimeSourceId("player_idle", "fallback_player")
end

local function ResolveBossDefinition(bossType)
  if bossType == "MINI_EASY" then
    return "boss_mini_easy_down"
  elseif bossType == "MINI_MEDIUM" then
    return "boss_mini_medium_down"
  end
  return "boss_final_down"
end

local function AssetAvailabilitySummary()
  return tostring(availableAssetCount) .. "/" .. tostring(#ASSET_MANIFEST) .. " ASSETS"
end

local function DynamicGameplayDefinitionBytes()
  return #DYNAMIC_GAMEPLAY_DEFINITIONS
end

local function MissingAssetList()
  return table.concat(MISSING_ASSET_PATHS, ", ")
end

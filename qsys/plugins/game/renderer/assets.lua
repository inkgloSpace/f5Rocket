local ASSET_MANIFEST = {
  { Id = "player_idle", Source = "assets/player/player_idle.png", Width = 32, Height = 40 },
  { Id = "player_left", Source = "assets/player/player_left.png", Width = 32, Height = 40 },
  { Id = "player_right", Source = "assets/player/player_right.png", Width = 32, Height = 40 },
  { Id = "enemy_01", Source = "assets/enemy/enemy_01.png", Width = 28, Height = 28 },
  { Id = "bullet_player", Source = "assets/bullet/player_bullet.png", Width = 6, Height = 12 },
  { Id = "bullet_enemy", Source = "assets/bullet/enemy_bullet.png", Width = 6, Height = 8 },
  { Id = "explosion_01", Source = "assets/explosion/explosion_01.png", Width = 32, Height = 32 },
  { Id = "explosion_02", Source = "assets/explosion/explosion_02.png", Width = 32, Height = 32 },
  { Id = "explosion_03", Source = "assets/explosion/explosion_03.png", Width = 32, Height = 32 },
  { Id = "background_tile", Source = "assets/background/background_tile.png", Width = 320, Height = 480 }
}

-- Only assets used by the current 30 Hz playable slice belong in its SVG.
-- Large backgrounds and feature-deferred sprites remain generated and cached,
-- but are not copied into every dynamic frame.
local GAMEPLAY_ASSET_IDS = {
  player_idle = true,
  player_left = true,
  player_right = true,
  enemy_01 = true,
  bullet_player = true
}

local LARGE_BACKGROUND_ASSET_IDS = {
  background_tile = true
}

local STARFIELD = {
  { 12, 18, 1 }, { 48, 52, 2 }, { 86, 31, 1 }, { 130, 74, 1 },
  { 176, 22, 2 }, { 224, 64, 1 }, { 282, 36, 1 }, { 308, 92, 2 },
  { 28, 126, 1 }, { 70, 158, 1 }, { 112, 112, 2 }, { 154, 174, 1 },
  { 202, 138, 1 }, { 248, 186, 2 }, { 296, 146, 1 }, { 18, 226, 2 },
  { 58, 268, 1 }, { 104, 214, 1 }, { 146, 286, 2 }, { 190, 242, 1 },
  { 236, 304, 1 }, { 278, 258, 2 }, { 314, 326, 1 }, { 34, 362, 1 },
  { 82, 414, 2 }, { 126, 348, 1 }, { 170, 438, 1 }, { 216, 382, 2 },
  { 260, 456, 1 }, { 302, 402, 1 }, { 54, 472, 1 }, { 244, 18, 1 }
}

-- Fallback geometry is definition-based so the no-artwork path exercises the
-- same Q-SYS <defs>/<use href> mechanism as production PNG sprites.
local FALLBACK_PLAYER_DEFINITION =
  "<g id=\"fallback_player\"><polygon points=\"16,0 31,36 20,31 16,40 12,31 1,36\" fill=\"#46e6e1\"/>" ..
  "<rect x=\"13\" y=\"15\" width=\"6\" height=\"16\" fill=\"#ffffff\"/>" ..
  "<text x=\"16\" y=\"28\" fill=\"#07101f\" font-family=\"monospace\" font-size=\"8\" text-anchor=\"middle\">P</text></g>"

local FALLBACK_ENEMY_DEFINITION =
  "<g id=\"fallback_enemy\"><rect width=\"28\" height=\"28\" fill=\"#ff5c68\"/>" ..
  "<path d=\"M4 8H24L20 24H8Z\" fill=\"#791f3d\"/>" ..
  "<text x=\"14\" y=\"19\" fill=\"#ffffff\" font-family=\"monospace\" font-size=\"10\" text-anchor=\"middle\">E</text></g>"

local FALLBACK_PLAYER_BULLET_DEFINITION =
  "<g id=\"fallback_player_bullet\"><rect width=\"6\" height=\"12\" fill=\"#ffe66d\"/></g>"

local FALLBACK_ENEMY_BULLET_DEFINITION =
  "<g id=\"fallback_enemy_bullet\"><rect width=\"6\" height=\"8\" fill=\"#ff9b45\"/></g>"

local FALLBACK_EXPLOSION_DEFINITION =
  "<g id=\"fallback_explosion\"><path d=\"M16 0L20 11L32 16L20 21L16 32L12 21L0 16L12 11Z\" fill=\"#ff9b45\"/></g>"

local FALLBACK_STARFIELD_PARTS = { "<g id=\"fallback_starfield\">" }
for index = 1, #STARFIELD do
  local star = STARFIELD[index]
  local color = "#7088a8"
  if star[3] == 2 then
    color = "#d7f7ff"
  end
  FALLBACK_STARFIELD_PARTS[#FALLBACK_STARFIELD_PARTS + 1] =
    "<rect x=\"" .. tostring(star[1]) .. "\" y=\"" .. tostring(star[2]) ..
    "\" width=\"" .. tostring(star[3]) .. "\" height=\"" ..
    tostring(star[3]) .. "\" fill=\"" .. color .. "\"/>"
end
FALLBACK_STARFIELD_PARTS[#FALLBACK_STARFIELD_PARTS + 1] = "</g>"
local FALLBACK_STARFIELD_DEFINITION = table.concat(FALLBACK_STARFIELD_PARTS)

local GAMEPLAY_FALLBACK_DEFINITIONS = table.concat({
  FALLBACK_PLAYER_DEFINITION,
  FALLBACK_ENEMY_DEFINITION,
  FALLBACK_PLAYER_BULLET_DEFINITION,
  FALLBACK_STARFIELD_DEFINITION
})

-- Retained for the future enemy-bullet/explosion features, but intentionally
-- excluded from the current dynamic frame definition set.
local DEFERRED_FALLBACK_DEFINITIONS = table.concat({
  FALLBACK_ENEMY_BULLET_DEFINITION,
  FALLBACK_EXPLOSION_DEFINITION
})

local ASSETS = {}
local GAMEPLAY_ASSET_DEFINITION_PARTS = {}
local LARGE_BACKGROUND_ASSET_DEFINITION_PARTS = {}
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
    DataUri = available and generated.DataUri or ""
  }

  if available then
    availableAssetCount = availableAssetCount + 1
    local definition =
      "<image id=\"" .. metadata.Id .. "\" href=\"" .. generated.DataUri ..
      "\" width=\"" .. tostring(metadata.Width) .. "\" height=\"" ..
      tostring(metadata.Height) .. "\" preserveAspectRatio=\"none\"/>"

    if GAMEPLAY_ASSET_IDS[metadata.Id] then
      GAMEPLAY_ASSET_DEFINITION_PARTS[#GAMEPLAY_ASSET_DEFINITION_PARTS + 1] = definition
      RUNTIME_DEFINITION_AVAILABLE[metadata.Id] = true
    elseif LARGE_BACKGROUND_ASSET_IDS[metadata.Id] then
      LARGE_BACKGROUND_ASSET_DEFINITION_PARTS[#LARGE_BACKGROUND_ASSET_DEFINITION_PARTS + 1] = definition
    end
  else
    MISSING_ASSET_PATHS[#MISSING_ASSET_PATHS + 1] = metadata.Source
  end
end

local GAMEPLAY_ASSET_DEFINITIONS = table.concat(GAMEPLAY_ASSET_DEFINITION_PARTS)
local LARGE_BACKGROUND_ASSET_DEFINITIONS = table.concat(LARGE_BACKGROUND_ASSET_DEFINITION_PARTS)
local STATIC_RENDER_DEFINITIONS = GAMEPLAY_ASSET_DEFINITIONS .. GAMEPLAY_FALLBACK_DEFINITIONS

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

local function AppendTranslatedUse(parts, definitionId, x, y)
  parts[#parts + 1] = "<use href=\"#" .. definitionId ..
    "\" transform=\"translate(" .. tostring(math.floor(x)) .. " " ..
    tostring(math.floor(y)) .. ")\"/>"
end

local function AppendSpriteUse(parts, assetId, fallbackId, x, y)
  if RuntimeDefinitionAvailable(assetId) then
    AppendDefinitionUse(parts, assetId, x, y)
  else
    AppendDefinitionUse(parts, fallbackId, x, y)
  end
end

local function ResolvePlayerDefinition(direction)
  if direction == "left" and RuntimeDefinitionAvailable("player_left") then
    return "player_left"
  end
  if direction == "right" and RuntimeDefinitionAvailable("player_right") then
    return "player_right"
  end
  if RuntimeDefinitionAvailable("player_idle") then
    return "player_idle"
  end
  return "fallback_player"
end

local function AssetAvailabilitySummary()
  return tostring(availableAssetCount) .. "/" .. tostring(#ASSET_MANIFEST) .. " ASSETS"
end

local function GameplayAssetDefinitionBytes()
  return #GAMEPLAY_ASSET_DEFINITIONS
end

local function LargeBackgroundAssetDefinitionBytes()
  return #LARGE_BACKGROUND_ASSET_DEFINITIONS
end

local function MissingAssetList()
  return table.concat(MISSING_ASSET_PATHS, ", ")
end

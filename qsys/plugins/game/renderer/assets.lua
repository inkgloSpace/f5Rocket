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

local ASSETS = {}
local ASSET_DEFINITION_PARTS = {}
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
    ASSET_DEFINITION_PARTS[#ASSET_DEFINITION_PARTS + 1] =
      "<image id=\"" .. metadata.Id .. "\" href=\"" .. generated.DataUri ..
      "\" width=\"" .. tostring(metadata.Width) .. "\" height=\"" ..
      tostring(metadata.Height) .. "\" preserveAspectRatio=\"none\"/>"
  else
    MISSING_ASSET_PATHS[#MISSING_ASSET_PATHS + 1] = metadata.Source
  end
end

local ASSET_DEFINITIONS = table.concat(ASSET_DEFINITION_PARTS)

local function AssetAvailable(assetId)
  local asset = ASSETS[assetId]
  return asset ~= nil and asset.Available
end

local function AppendAssetUse(parts, assetId, x, y)
  if not AssetAvailable(assetId) then
    return false
  end

  parts[#parts + 1] = "<use href=\"#" .. assetId .. "\" x=\"" ..
    tostring(math.floor(x)) .. "\" y=\"" .. tostring(math.floor(y)) .. "\"/>"
  return true
end

local function ResolvePlayerAsset(direction)
  if direction == "left" and AssetAvailable("player_left") then
    return "player_left"
  end
  if direction == "right" and AssetAvailable("player_right") then
    return "player_right"
  end
  if AssetAvailable("player_idle") then
    return "player_idle"
  end
  return nil
end

local function AssetAvailabilitySummary()
  return tostring(availableAssetCount) .. "/" .. tostring(#ASSET_MANIFEST) .. " ASSETS"
end

local function MissingAssetList()
  return table.concat(MISSING_ASSET_PATHS, ", ")
end

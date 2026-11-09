local RATE_CHOICES = { "30 Hz", "20 Hz", "15 Hz" }
local RATE_INTERVALS = {
  ["30 Hz"] = 1 / 30,
  ["20 Hz"] = 1 / 20,
  ["15 Hz"] = 1 / 15
}
local RATE_VALUES = {
  ["30 Hz"] = 30,
  ["20 Hz"] = 20,
  ["15 Hz"] = 15
}

local IMAGE_SYNTAX_CHOICES = { "href", "xlink:href" }
local USE_SYNTAX_CHOICES = { "href", "xlink:href" }
local RENDER_MODE_CHOICES = { "INLINE", "DEFS+USE" }
local INSTANCE_COUNT_CHOICES = { "1", "8", "16", "32", "64" }
local INSTANCE_COUNT_VALUES = {
  ["1"] = 1,
  ["8"] = 8,
  ["16"] = 16,
  ["32"] = 32,
  ["64"] = 64
}

local SPRITE_ID = "compatSprite"
local SPRITE_SIZE = 32
local GRID_COLUMNS = 8
local GRID_X = 18
local GRID_Y = 88
local GRID_STEP_X = 36
local GRID_STEP_Y = 40
local MOTION_MIN = 0
local MOTION_MAX = 16
local MOTION_STEP = 2

-- COMPATIBILITY TEST ASSET - NOT PRODUCTION ART
-- Deterministic 16 x 16 RGBA PNG, cached as Base64 once in this source file.
local PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAZElEQVR42mNgwAPcnj38D8IM5ACYZrINAWn68vE+GJNsAMxWZANIMgTd+UQZgEsTUYaRqhmvi8jSRJUwwGbA/9muYEy27egGkBQTID7MAGxyRLkE2QUkJ2WYZmRXkKwZF5+qAADR8ySMsISOUwAAAABJRU5ErkJggg=="
local PNG_DATA_URI = "data:image/png;base64," .. PNG_BASE64

local function SpritePosition(index)
  local zeroBased = index - 1
  local column = zeroBased % GRID_COLUMNS
  local row = math.floor(zeroBased / GRID_COLUMNS)
  local x = GRID_X + column * GRID_STEP_X
  local y = GRID_Y + row * GRID_STEP_Y
  return x, y
end

local function PrepareCompatScene(renderMode, instanceCount, imageSyntax, useSyntax)
  local rootNamespace = ""
  local definitions = ""
  local instances = {}

  if renderMode == "DEFS+USE" then
    definitions = "<defs><image id=\"" .. SPRITE_ID .. "\" href=\"" .. PNG_DATA_URI ..
      "\" width=\"32\" height=\"32\" preserveAspectRatio=\"none\"/></defs>"

    local useAttribute = "href"
    if useSyntax == "xlink:href" then
      rootNamespace = " xmlns:xlink=\"http://www.w3.org/1999/xlink\""
      useAttribute = "xlink:href"
    end

    for index = 1, instanceCount do
      local x, y = SpritePosition(index)
      instances[index] = "<use " .. useAttribute .. "=\"#" .. SPRITE_ID .. "\" x=\"" ..
        tostring(x) .. "\" y=\"" .. tostring(y) .. "\"/>"
    end
  else
    local imageAttribute = "href"
    if imageSyntax == "xlink:href" then
      rootNamespace = " xmlns:xlink=\"http://www.w3.org/1999/xlink\""
      imageAttribute = "xlink:href"
    end

    for index = 1, instanceCount do
      local x, y = SpritePosition(index)
      instances[index] = "<image " .. imageAttribute .. "=\"" .. PNG_DATA_URI .. "\" x=\"" ..
        tostring(x) .. "\" y=\"" .. tostring(y) ..
        "\" width=\"32\" height=\"32\" preserveAspectRatio=\"none\"/>"
    end
  end

  return {
    Prefix = "<svg xmlns=\"http://www.w3.org/2000/svg\"" .. rootNamespace ..
      " viewBox=\"0 0 320 480\" width=\"320\" height=\"480\" shape-rendering=\"crispEdges\">" ..
      "<rect width=\"320\" height=\"480\" fill=\"#07101f\"/>" ..
      "<text x=\"160\" y=\"24\" fill=\"#46e6e1\" font-family=\"monospace\" font-size=\"12\" text-anchor=\"middle\">f5Rocket Q-SYS COMPAT</text>" ..
      definitions .. "<g transform=\"translate(",
    Suffix = " 0)\">" .. table.concat(instances) .. "</g>" ..
      "<text x=\"160\" y=\"470\" fill=\"#ff9b45\" font-family=\"monospace\" font-size=\"8\" text-anchor=\"middle\">COMPATIBILITY TEST ASSET - NOT PRODUCTION ART</text>" ..
      "</svg>"
  }
end

local function BuildCompatSvg(scene, motionOffset)
  return scene.Prefix .. tostring(motionOffset) .. scene.Suffix
end

local function CalculatePayloadSavings(instanceCount, imageSyntax, useSyntax)
  local inlineScene = PrepareCompatScene("INLINE", instanceCount, imageSyntax, useSyntax)
  local reuseScene = PrepareCompatScene("DEFS+USE", instanceCount, imageSyntax, useSyntax)
  local inlineBytes = #BuildCompatSvg(inlineScene, MOTION_MIN)
  local reuseBytes = #BuildCompatSvg(reuseScene, MOTION_MIN)
  local savings = ((inlineBytes - reuseBytes) / inlineBytes) * 100
  return savings, inlineBytes, reuseBytes
end

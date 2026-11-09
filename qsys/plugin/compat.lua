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
local SYNTAX_CHOICES = { "href", "xlink:href" }

local LOGICAL_WIDTH = 320
local LOGICAL_HEIGHT = 480
local SPRITE_SIZE = 32
local SPRITE_Y = 420
local SPRITE_STEP = 4
local MAX_SPRITE_X = LOGICAL_WIDTH - SPRITE_SIZE

-- COMPATIBILITY TEST ASSET - NOT PRODUCTION ART
-- Deterministic 16 x 16 RGBA PNG, cached as Base64 once in this source file.
local PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAZElEQVR42mNgwAPcnj38D8IM5ACYZrINAWn68vE+GJNsAMxWZANIMgTd+UQZgEsTUYaRqhmvi8jSRJUwwGbA/9muYEy27egGkBQTID7MAGxyRLkE2QUkJ2WYZmRXkKwZF5+qAADR8ySMsISOUwAAAABJRU5ErkJggg=="
local PNG_DATA_URI = "data:image/png;base64," .. PNG_BASE64

local function BuildCompatSvg(spriteX, syntax)
  local rootNamespace = ""
  local imageAttribute = "href"

  if syntax == "xlink:href" then
    rootNamespace = " xmlns:xlink=\"http://www.w3.org/1999/xlink\""
    imageAttribute = "xlink:href"
  end

  return "<svg xmlns=\"http://www.w3.org/2000/svg\"" .. rootNamespace ..
    " viewBox=\"0 0 320 480\" width=\"320\" height=\"480\" shape-rendering=\"crispEdges\">" ..
    "<rect width=\"320\" height=\"480\" fill=\"#07101f\"/>" ..
    "<text x=\"160\" y=\"24\" fill=\"#46e6e1\" font-family=\"monospace\" font-size=\"12\" text-anchor=\"middle\">f5Rocket Q-SYS COMPAT</text>" ..
    "<g transform=\"translate(" .. tostring(spriteX) .. " " .. tostring(SPRITE_Y) .. ")\">" ..
    "<image " .. imageAttribute .. "=\"" .. PNG_DATA_URI .. "\" x=\"0\" y=\"0\" width=\"32\" height=\"32\" preserveAspectRatio=\"none\"/>" ..
    "</g>" ..
    "<text x=\"160\" y=\"470\" fill=\"#ff9b45\" font-family=\"monospace\" font-size=\"8\" text-anchor=\"middle\">COMPATIBILITY TEST ASSET - NOT PRODUCTION ART</text>" ..
    "</svg>"
end

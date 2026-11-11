local currentPage = props["page_index"].Value

local COLORS = {
  Background = { 96, 96, 96 },
  Panel = { 112, 112, 112 },
  PanelStroke = { 145, 145, 145 },
  Text = { 238, 238, 238 },
  MutedText = { 205, 205, 205 },
  Button = { 128, 128, 128 },
  ButtonSecondary = { 112, 112, 112 },
  ButtonHighlight = { 150, 150, 150 },
  ButtonText = { 32, 32, 32 },
  AboutText = { 128, 128, 128 },
  AboutMuted = { 150, 150, 150 }
}

local function AddPageBackground()
  table.insert(graphics, {
    Type = "GroupBox",
    Text = "",
    Position = { 0, 0 },
    Size = { 480, 720 },
    Fill = COLORS.Background,
    StrokeWidth = 0,
    CornerRadius = 0
  })
end

local function AddGroup(text, x, y, width, height)
  table.insert(graphics, {
    Type = "GroupBox",
    Text = text,
    Position = { x, y },
    Size = { width, height },
    Fill = COLORS.Panel,
    Color = COLORS.Text,
    StrokeColor = COLORS.PanelStroke,
    StrokeWidth = 1,
    CornerRadius = 8,
    FontSize = 12,
    HTextAlign = "Left"
  })
end

local function AddStaticText(text, x, y, width, height, fontSize, color, bold)
  table.insert(graphics, {
    Type = "Text",
    Text = text,
    Position = { x, y },
    Size = { width, height },
    FontSize = fontSize,
    FontStyle = bold and "Bold" or "Regular",
    Color = color or COLORS.Text,
    HTextAlign = "Left",
    VTextAlign = "Top",
    WordWrap = true
  })
end

local function AddButton(name, prettyName, x, y, width, height, legend, color, style, offColor)
  local buttonLayout = {
    PrettyName = prettyName,
    Style = "Button",
    ButtonStyle = style or "Momentary",
    ButtonVisualStyle = "Flat",
    Position = { x, y },
    Size = { width, height },
    Color = color,
    TextColor = COLORS.ButtonText,
    Legend = legend,
    FontSize = 11,
    CornerRadius = 6
  }

  if offColor ~= nil then
    buttonLayout.OffColor = offColor
    buttonLayout.UnlinkOffColor = true
  end

  layout[name] = buttonLayout
end

if currentPage == 1 then
  -- Declaring and laying out the background first keeps the transparent
  -- gameplay surface above it.
  layout["BackgroundViewport"] = {
    PrettyName = "Game~Background Viewport",
    Style = "Button",
    ButtonStyle = "Momentary",
    ButtonVisualStyle = "Flat",
    Position = { 0, 0 },
    Size = { 480, 720 },
    Color = COLORS.Background,
    StrokeWidth = 0,
    CornerRadius = 0,
    Padding = 0,
    Margin = 0,
    ZOrder = 0
  }

  layout["Viewport"] = {
    PrettyName = "Game~Viewport",
    Style = "Button",
    ButtonStyle = "Momentary",
    ButtonVisualStyle = "Flat",
    Position = { 0, 0 },
    Size = { 480, 720 },
    StrokeWidth = 0,
    CornerRadius = 0,
    Padding = 0,
    Margin = 0,
    ZOrder = 1
  }

elseif currentPage == 2 then
  AddPageBackground()
  AddStaticText("f5ROCKET CONTROLS", 24, 16, 432, 28, 18, COLORS.Text, true)

  AddGroup("SYSTEM", 24, 54, 432, 100)
  AddButton("Run", "Controls~Run", 44, 92, 184, 42, "RUN", COLORS.ButtonHighlight, "Momentary")
  AddButton(
    "Pause", "Controls~Pause", 252, 92, 184, 42, "PAUSE",
    COLORS.ButtonHighlight, "Toggle", COLORS.ButtonSecondary
  )

  AddGroup("MOVEMENT", 24, 174, 432, 280)
  AddButton("UpLeft", "Controls~Up Left", 96, 216, 80, 58, "UL", COLORS.Button)
  AddButton("Up", "Controls~Up", 200, 216, 80, 58, "UP", COLORS.Button)
  AddButton("UpRight", "Controls~Up Right", 304, 216, 80, 58, "UR", COLORS.Button)
  AddButton("Left", "Controls~Left", 96, 294, 80, 58, "LEFT", COLORS.Button)
  AddButton("Right", "Controls~Right", 304, 294, 80, 58, "RIGHT", COLORS.Button)
  AddButton("DownLeft", "Controls~Down Left", 96, 372, 80, 58, "DL", COLORS.Button)
  AddButton("Down", "Controls~Down", 200, 372, 80, 58, "DOWN", COLORS.Button)
  AddButton("DownRight", "Controls~Down Right", 304, 372, 80, 58, "DR", COLORS.Button)

  AddGroup("WEAPONS", 24, 474, 432, 120)
  AddButton("Fire", "Controls~Fire", 44, 514, 184, 58, "FIRE", COLORS.ButtonHighlight, "Momentary")
  AddButton(
    "AutoFire", "Controls~Auto Fire", 252, 514, 184, 58, "AUTO FIRE",
    COLORS.ButtonHighlight, "Toggle", COLORS.ButtonSecondary
  )

  AddGroup("INPUT HELP", 24, 614, 432, 86)
  AddStaticText(
    "WASD / ARROWS  MOVE     SPACE  FIRE\nENTER  RUN / RESTART      P  PAUSE\n5-SHOT BURST - 1 SEC RECOVERY",
    44, 638, 392, 52, 10, COLORS.MutedText, false
  )

elseif currentPage == 3 then
  -- About intentionally uses typography only: no page background GroupBox,
  -- section GroupBoxes, cards, or runtime controls.
  AddStaticText("f5Rocket", 24, 24, 432, 40, 28, COLORS.AboutText, true)
  AddStaticText("Version " .. PluginInfo.Version, 24, 70, 432, 20, 12, COLORS.AboutMuted, false)
  AddStaticText(
    "Semi-8-bit vertical arcade shooter for Q-SYS",
    24, 104, 432, 34, 14, COLORS.AboutText, false
  )

  AddStaticText("HOW TO PLAY", 24, 164, 432, 24, 14, COLORS.AboutText, true)
  AddStaticText(
    "Pilot the F5 rocket through three stages:\n" ..
    "- Upper atmosphere\n- Asteroid field\n- Alien headquarters\n\n" ..
    "RUN starts or restarts the game. Move with the directional controls. " ..
    "FIRE shoots; AUTO FIRE continuously requests fire. Five rapid shots " ..
    "trigger a one-second recovery. PAUSE freezes gameplay.",
    24, 196, 432, 190, 12, COLORS.AboutText, false
  )

  AddStaticText("CONTROL OPTIONS", 24, 418, 432, 24, 14, COLORS.AboutText, true)
  AddStaticText(
    "- Plugin Controls page\n" ..
    "- Windows keyboard bridge for QDS Emulate\n" ..
    "- USB HID keyboard connected to a Q-SYS Core",
    24, 450, 432, 82, 12, COLORS.AboutText, false
  )

  AddStaticText("PROJECT & DETAILED SETUP", 24, 574, 432, 24, 14, COLORS.AboutText, true)
  AddStaticText(
    "Project source, setup instructions, and documentation:\n" ..
    "https://github.com/inkgloSpace/f5Rocket",
    24, 606, 432, 72, 12, COLORS.AboutText, false
  )
end

local currentPage = props["page_index"].Value

local COLORS = {
  Background = { 7, 16, 31 },
  Panel = { 11, 27, 48 },
  PanelStroke = { 38, 77, 106 },
  Text = { 215, 247, 255 },
  MutedText = { 145, 184, 204 },
  Movement = { 70, 120, 180 },
  Run = { 70, 230, 225 },
  Pause = { 245, 166, 35 },
  Fire = { 255, 92, 157 }
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

local function AddButton(name, prettyName, x, y, width, height, legend, color, style)
  layout[name] = {
    PrettyName = prettyName,
    Style = "Button",
    ButtonStyle = style or "Momentary",
    ButtonVisualStyle = "Flat",
    Position = { x, y },
    Size = { width, height },
    Color = color,
    Legend = legend,
    FontSize = 11,
    CornerRadius = 6
  }
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
  AddButton("Run", "Controls~Run", 44, 92, 184, 42, "RUN", COLORS.Run, "Momentary")
  AddButton("Pause", "Controls~Pause", 252, 92, 184, 42, "PAUSE", COLORS.Pause, "Toggle")

  AddGroup("MOVEMENT", 24, 174, 432, 280)
  AddButton("UpLeft", "Controls~Up Left", 96, 216, 80, 58, "UL", COLORS.Movement)
  AddButton("Up", "Controls~Up", 200, 216, 80, 58, "UP", COLORS.Movement)
  AddButton("UpRight", "Controls~Up Right", 304, 216, 80, 58, "UR", COLORS.Movement)
  AddButton("Left", "Controls~Left", 96, 294, 80, 58, "LEFT", COLORS.Movement)
  AddButton("Right", "Controls~Right", 304, 294, 80, 58, "RIGHT", COLORS.Movement)
  AddButton("DownLeft", "Controls~Down Left", 96, 372, 80, 58, "DL", COLORS.Movement)
  AddButton("Down", "Controls~Down", 200, 372, 80, 58, "DOWN", COLORS.Movement)
  AddButton("DownRight", "Controls~Down Right", 304, 372, 80, 58, "DR", COLORS.Movement)

  AddGroup("WEAPONS", 24, 474, 432, 120)
  AddButton("Fire", "Controls~Fire", 44, 514, 184, 58, "FIRE", COLORS.Fire, "Momentary")
  AddButton("AutoFire", "Controls~Auto Fire", 252, 514, 184, 58, "AUTO FIRE", COLORS.Fire, "Toggle")

  AddGroup("INPUT HELP", 24, 614, 432, 86)
  AddStaticText(
    "WASD / ARROWS  MOVE     SPACE  FIRE\nENTER  RUN / RESTART      P  PAUSE\n5-SHOT BURST - 1 SEC RECOVERY",
    44, 638, 392, 52, 10, COLORS.MutedText, false
  )

elseif currentPage == 3 then
  AddPageBackground()
  AddStaticText("f5Rocket", 24, 22, 432, 40, 28, COLORS.Run, true)
  AddStaticText("Version " .. PluginInfo.Version, 24, 66, 432, 20, 12, COLORS.MutedText, false)
  AddStaticText(
    "Semi-8-bit vertical arcade shooter for Q-SYS",
    24, 96, 432, 34, 14, COLORS.Text, false
  )

  AddGroup("HOW TO PLAY", 24, 152, 432, 228)
  AddStaticText(
    "Pilot the F5 rocket through three stages:\n" ..
    "- Upper atmosphere\n- Asteroid field\n- Alien headquarters\n\n" ..
    "RUN starts or restarts the game. Move with the directional controls. " ..
    "FIRE shoots; AUTO FIRE continuously requests fire. Five rapid shots " ..
    "trigger a one-second recovery. PAUSE freezes gameplay.",
    44, 188, 392, 172, 12, COLORS.Text, false
  )

  AddGroup("CONTROL OPTIONS", 24, 400, 432, 126)
  AddStaticText(
    "- Plugin Controls page\n" ..
    "- Windows keyboard bridge for QDS Emulate\n" ..
    "- USB HID keyboard connected to a Q-SYS Core",
    44, 436, 392, 72, 12, COLORS.Text, false
  )

  AddGroup("PROJECT & DETAILED SETUP", 24, 548, 432, 132)
  AddStaticText(
    "Project source, setup instructions, and documentation:\n" ..
    "https://github.com/inkgloSpace/f5Rocket",
    44, 584, 392, 72, 12, COLORS.Text, false
  )
end

local currentPage = props["page_index"].Value

if currentPage == 1 then
  table.insert(graphics, {
    Type = "Header",
    Text = "f5Rocket - Production Game Slice",
    Position = { 8, 8 },
    Size = { 558, 24 },
    FontSize = 16,
    HTextAlign = "Center"
  })

  table.insert(graphics, {
    Type = "GroupBox",
    Text = "320 x 480 game viewport",
    Position = { 8, 38 },
    Size = { 320, 480 },
    Fill = { 7, 16, 31 },
    StrokeWidth = 1
  })

  table.insert(graphics, {
    Type = "GroupBox",
    Text = "Controls and telemetry",
    Position = { 338, 38 },
    Size = { 228, 480 },
    Fill = { 238, 241, 245 },
    StrokeWidth = 1
  })

  local function AddLabel(text, y)
    table.insert(graphics, {
      Type = "Text",
      Text = text,
      Position = { 350, y },
      Size = { 100, 18 },
      FontSize = 9,
      HTextAlign = "Right"
    })
  end

  AddLabel("Diagnostic", 280)
  AddLabel("Measured", 362)
  AddLabel("SVG bytes", 390)
  AddLabel("Base64 bytes", 418)
  AddLabel("Enemies", 446)
  AddLabel("Player bullets", 474)

  layout["Viewport"] = {
    PrettyName = "Game~Viewport",
    Style = "Button",
    ButtonStyle = "Momentary",
    ButtonVisualStyle = "Flat",
    Position = { 8, 38 },
    Size = { 320, 480 },
    Color = { 7, 16, 31 },
    StrokeWidth = 0,
    CornerRadius = 0,
    Padding = 0,
    Margin = 0
  }

  layout["Start"] = {
    PrettyName = "Game~Start",
    Style = "Button",
    ButtonStyle = "Trigger",
    ButtonVisualStyle = "Flat",
    Position = { 350, 68 },
    Size = { 96, 32 },
    Color = { 70, 230, 225 },
    Legend = "START"
  }

  layout["Pause"] = {
    PrettyName = "Game~Pause",
    Style = "Button",
    ButtonStyle = "Toggle",
    ButtonVisualStyle = "Flat",
    Position = { 458, 68 },
    Size = { 96, 32 },
    Color = { 255, 155, 69 },
    Legend = "PAUSE"
  }

  local function AddButton(name, x, y, width, height, legend)
    layout[name] = {
      PrettyName = "Game~" .. name,
      Style = "Button",
      ButtonStyle = "Momentary",
      ButtonVisualStyle = "Flat",
      Position = { x, y },
      Size = { width, height },
      Color = { 70, 120, 180 },
      Legend = legend
    }
  end

  AddButton("Up", 424, 116, 56, 42, "UP")
  AddButton("Left", 356, 164, 56, 42, "LEFT")
  AddButton("Down", 424, 164, 56, 42, "DOWN")
  AddButton("Right", 492, 164, 56, 42, "RIGHT")
  AddButton("Fire", 356, 220, 192, 42, "FIRE")

  layout["DiagnosticMode"] = {
    PrettyName = "Game~DiagnosticMode",
    Style = "ComboBox",
    Position = { 458, 278 },
    Size = { 96, 22 }
  }

  layout["Status"] = {
    PrettyName = "Game~Status",
    Style = "Text",
    Position = { 350, 310 },
    Size = { 204, 36 },
    IsReadOnly = true,
    FontSize = 9,
    HTextAlign = "Center",
    VTextAlign = "Center"
  }

  local function AddReadout(name, y)
    layout[name] = {
      PrettyName = "Game~" .. name,
      Style = "Text",
      Position = { 458, y },
      Size = { 96, 22 },
      IsReadOnly = true,
      FontSize = 9,
      HTextAlign = "Right"
    }
  end

  AddReadout("MeasuredHz", 360)
  AddReadout("SvgBytes", 388)
  AddReadout("SvgBase64Bytes", 416)
  AddReadout("ActiveEnemies", 444)
  AddReadout("ActivePlayerBullets", 472)
end

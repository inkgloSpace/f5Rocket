local currentPage = props["page_index"].Value

if currentPage == 1 then
  table.insert(graphics, {
    Type = "Header",
    Text = "f5Rocket - Three-Stage Space Campaign",
    Position = { 8, 8 },
    Size = { 742, 24 },
    FontSize = 16,
    HTextAlign = "Center"
  })

  table.insert(graphics, {
    Type = "GroupBox",
    Text = "320 x 480 logical / 480 x 720 display",
    Position = { 8, 38 },
    Size = { 480, 720 },
    Fill = { 7, 16, 31 },
    StrokeWidth = 1
  })

  table.insert(graphics, {
    Type = "GroupBox",
    Text = "Controls and telemetry",
    Position = { 500, 38 },
    Size = { 250, 720 },
    Fill = { 238, 241, 245 },
    StrokeWidth = 1
  })

  -- BackgroundViewport is declared before Viewport in controls.lua and laid
  -- out first here so the transparent gameplay Button remains the top layer.
  layout["BackgroundViewport"] = {
    PrettyName = "Game~Background Viewport",
    Style = "Button",
    ButtonStyle = "Momentary",
    ButtonVisualStyle = "Flat",
    Position = { 8, 38 },
    Size = { 480, 720 },
    Color = { 7, 16, 31 },
    StrokeWidth = 0,
    CornerRadius = 0,
    Padding = 0,
    Margin = 0
  }

  layout["Viewport"] = {
    PrettyName = "Game~Viewport",
    Style = "Button",
    ButtonStyle = "Momentary",
    ButtonVisualStyle = "Flat",
    Position = { 8, 38 },
    Size = { 480, 720 },
    StrokeWidth = 0,
    CornerRadius = 0,
    Padding = 0,
    Margin = 0
  }

  layout["Run"] = {
    PrettyName = "Game~Run",
    Style = "Button",
    ButtonStyle = "Toggle",
    ButtonVisualStyle = "Flat",
    Position = { 514, 68 },
    Size = { 105, 34 },
    Color = { 70, 230, 225 },
    Legend = "RUN"
  }

  layout["Pause"] = {
    PrettyName = "Game~Pause",
    Style = "Button",
    ButtonStyle = "Toggle",
    ButtonVisualStyle = "Flat",
    Position = { 631, 68 },
    Size = { 105, 34 },
    Color = { 245, 166, 35 },
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

  AddButton("UpLeft", 514, 120, 64, 44, "UL")
  AddButton("Up", 586, 120, 64, 44, "UP")
  AddButton("UpRight", 658, 120, 64, 44, "UR")
  AddButton("Left", 514, 170, 64, 44, "LEFT")
  AddButton("Right", 658, 170, 64, 44, "RIGHT")
  AddButton("DownLeft", 514, 220, 64, 44, "DL")
  AddButton("Down", 586, 220, 64, 44, "DOWN")
  AddButton("DownRight", 658, 220, 64, 44, "DR")
  AddButton("Fire", 514, 278, 105, 46, "FIRE")

  layout["AutoFire"] = {
    PrettyName = "Game~Auto Fire",
    Style = "Button",
    ButtonStyle = "Toggle",
    ButtonVisualStyle = "Flat",
    Position = { 631, 278 },
    Size = { 105, 46 },
    Color = { 255, 92, 157 },
    Legend = "AUTO FIRE"
  }

  layout["Status"] = {
    PrettyName = "Game~Status",
    Style = "Text",
    Position = { 514, 342 },
    Size = { 222, 50 },
    IsReadOnly = true,
    FontSize = 9,
    HTextAlign = "Center",
    VTextAlign = "Center"
  }

  local function AddLabel(text, y)
    table.insert(graphics, {
      Type = "Text",
      Text = text,
      Position = { 512, y },
      Size = { 110, 20 },
      FontSize = 9,
      HTextAlign = "Right"
    })
  end

  local function AddReadout(name, y)
    layout[name] = {
      PrettyName = "Game~" .. name,
      Style = "Text",
      Position = { 630, y },
      Size = { 106, 22 },
      IsReadOnly = true,
      FontSize = 9,
      HTextAlign = "Right"
    }
  end

  AddLabel("Measured", 424)
  AddLabel("SVG bytes", 454)
  AddLabel("Base64 bytes", 484)
  AddLabel("Enemies", 514)
  AddLabel("Player bullets", 544)

  AddReadout("MeasuredHz", 422)
  AddReadout("SvgBytes", 452)
  AddReadout("SvgBase64Bytes", 482)
  AddReadout("ActiveEnemies", 512)
  AddReadout("ActivePlayerBullets", 542)
end

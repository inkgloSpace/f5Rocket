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

  AddButton("Up", 594, 120, 60, 44, "UP")
  AddButton("Left", 522, 170, 60, 44, "LEFT")
  AddButton("Down", 594, 170, 60, 44, "DOWN")
  AddButton("Right", 666, 170, 60, 44, "RIGHT")
  AddButton("Fire", 522, 228, 204, 46, "FIRE")

  layout["Status"] = {
    PrettyName = "Game~Status",
    Style = "Text",
    Position = { 514, 292 },
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

  AddLabel("Measured", 374)
  AddLabel("SVG bytes", 404)
  AddLabel("Base64 bytes", 434)
  AddLabel("Enemies", 464)
  AddLabel("Player bullets", 494)

  AddReadout("MeasuredHz", 372)
  AddReadout("SvgBytes", 402)
  AddReadout("SvgBase64Bytes", 432)
  AddReadout("ActiveEnemies", 462)
  AddReadout("ActivePlayerBullets", 492)
end

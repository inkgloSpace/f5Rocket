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

  AddLabel("Measured", 346)
  AddLabel("SVG bytes", 374)
  AddLabel("Base64 bytes", 402)
  AddLabel("Enemies", 430)
  AddLabel("Player bullets", 458)

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

  layout["Run"] = {
    PrettyName = "Game~Run",
    Style = "Button",
    ButtonStyle = "Toggle",
    ButtonVisualStyle = "Flat",
    Position = { 350, 68 },
    Size = { 204, 32 },
    Color = { 70, 230, 225 },
    Legend = "RUN"
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

  layout["Status"] = {
    PrettyName = "Game~Status",
    Style = "Text",
    Position = { 350, 278 },
    Size = { 204, 48 },
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

  AddReadout("MeasuredHz", 344)
  AddReadout("SvgBytes", 372)
  AddReadout("SvgBase64Bytes", 400)
  AddReadout("ActiveEnemies", 428)
  AddReadout("ActivePlayerBullets", 456)
end

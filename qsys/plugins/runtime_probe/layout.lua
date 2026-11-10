local currentPage = props["page_index"].Value

if currentPage == 1 then
  table.insert(graphics, {
    Type = "Header",
    Text = "f5Rocket Runtime Lifecycle Probe",
    Position = { 8, 8 },
    Size = { 540, 24 },
    FontSize = 16,
    HTextAlign = "Center"
  })

  table.insert(graphics, {
    Type = "GroupBox",
    Text = "320 x 480 logical viewport",
    Position = { 8, 38 },
    Size = { 320, 480 },
    Fill = { 7, 16, 31 },
    StrokeWidth = 1
  })

  table.insert(graphics, {
    Type = "GroupBox",
    Text = "Runtime isolation",
    Position = { 338, 38 },
    Size = { 210, 480 },
    Fill = { 238, 241, 245 },
    StrokeWidth = 1
  })

  local function AddLabel(text, y)
    table.insert(graphics, {
      Type = "Text",
      Text = text,
      Position = { 350, y },
      Size = { 76, 18 },
      FontSize = 9,
      HTextAlign = "Right"
    })
  end

  AddLabel("Stage", 116)
  AddLabel("Ticks", 230)
  AddLabel("Measured", 258)
  AddLabel("SVG bytes", 286)

  layout["Viewport"] = {
    PrettyName = "Runtime Probe~Viewport",
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
    PrettyName = "Runtime Probe~Run",
    Style = "Button",
    ButtonStyle = "Toggle",
    ButtonVisualStyle = "Flat",
    Position = { 350, 68 },
    Size = { 186, 32 },
    Color = { 70, 230, 225 },
    Legend = "RUN"
  }

  layout["Stage"] = {
    PrettyName = "Runtime Probe~Stage",
    Style = "ComboBox",
    Position = { 434, 114 },
    Size = { 102, 22 }
  }

  layout["Status"] = {
    PrettyName = "Runtime Probe~Status",
    Style = "Text",
    Position = { 350, 158 },
    Size = { 186, 46 },
    IsReadOnly = true,
    FontSize = 9,
    HTextAlign = "Center",
    VTextAlign = "Center"
  }

  local function AddReadout(name, y)
    layout[name] = {
      PrettyName = "Runtime Probe~" .. name,
      Style = "Text",
      Position = { 434, y },
      Size = { 102, 22 },
      IsReadOnly = true,
      FontSize = 9,
      HTextAlign = "Right"
    }
  end

  AddReadout("TickCount", 228)
  AddReadout("MeasuredHz", 256)
  AddReadout("SvgBytes", 284)
end

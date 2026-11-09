local currentPage = props["page_index"].Value

if currentPage == 1 then
  table.insert(graphics, {
    Type = "Header",
    Text = "f5Rocket SVG Sprite Reuse / IconData Benchmark",
    Position = { 8, 8 },
    Size = { 580, 24 },
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
    Text = "Benchmark controls and measurements",
    Position = { 338, 38 },
    Size = { 250, 480 },
    Fill = { 238, 241, 245 },
    StrokeWidth = 1
  })

  local function AddLabel(text, y)
    table.insert(graphics, {
      Type = "Text",
      Text = text,
      Position = { 350, y },
      Size = { 96, 18 },
      FontSize = 9,
      HTextAlign = "Right"
    })
  end

  AddLabel("Rate", 112)
  AddLabel("Render mode", 140)
  AddLabel("Instances", 168)
  AddLabel("Image syntax", 196)
  AddLabel("Use syntax", 224)
  AddLabel("Status", 250)
  AddLabel("Requested", 314)
  AddLabel("Measured", 342)
  AddLabel("Ticks", 370)
  AddLabel("SVG bytes", 398)
  AddLabel("Base64 bytes", 426)
  AddLabel("Savings", 454)
  AddLabel("Render time", 482)

  layout["Viewport"] = {
    PrettyName = "Probe~Viewport",
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
    PrettyName = "Probe~Run",
    Style = "Button",
    ButtonStyle = "Toggle",
    ButtonVisualStyle = "Flat",
    Position = { 350, 68 },
    Size = { 106, 30 },
    Color = { 70, 230, 225 },
    Legend = "RUN"
  }

  layout["Reset"] = {
    PrettyName = "Probe~Reset",
    Style = "Button",
    ButtonStyle = "Trigger",
    ButtonVisualStyle = "Flat",
    Position = { 466, 68 },
    Size = { 110, 30 },
    Color = { 255, 155, 69 },
    Legend = "RESET"
  }

  local function AddChoice(name, y)
    layout[name] = {
      PrettyName = "Probe~" .. name,
      Style = "ComboBox",
      Position = { 454, y },
      Size = { 122, 22 }
    }
  end

  AddChoice("Rate", 110)
  AddChoice("RenderMode", 138)
  AddChoice("InstanceCount", 166)
  AddChoice("ImageSyntax", 194)
  AddChoice("UseSyntax", 222)

  layout["Status"] = {
    PrettyName = "Probe~Status",
    Style = "Text",
    Position = { 350, 270 },
    Size = { 226, 32 },
    IsReadOnly = true,
    FontSize = 9,
    HTextAlign = "Center",
    VTextAlign = "Center"
  }

  local function AddReadout(name, y)
    layout[name] = {
      PrettyName = "Probe~" .. name,
      Style = "Text",
      Position = { 454, y },
      Size = { 122, 22 },
      IsReadOnly = true,
      FontSize = 9,
      HTextAlign = "Right"
    }
  end

  AddReadout("RequestedHz", 312)
  AddReadout("MeasuredHz", 340)
  AddReadout("TickCount", 368)
  AddReadout("SvgBytes", 396)
  AddReadout("SvgBase64Bytes", 424)
  AddReadout("PayloadSavings", 452)
  AddReadout("LastRenderMs", 480)
end

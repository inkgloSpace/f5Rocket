local currentPage = props["page_index"].Value

if currentPage == 1 then
  table.insert(graphics, {
    Type = "Header",
    Text = "f5Rocket PNG-in-SVG / IconData Probe",
    Position = { 8, 8 },
    Size = { 532, 24 },
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
    Text = "Probe controls and measurements",
    Position = { 338, 38 },
    Size = { 202, 480 },
    Fill = { 238, 241, 245 },
    StrokeWidth = 1
  })

  local function AddLabel(text, y)
    table.insert(graphics, {
      Type = "Text",
      Text = text,
      Position = { 350, y },
      Size = { 82, 18 },
      FontSize = 10,
      HTextAlign = "Right"
    })
  end

  AddLabel("Rate", 122)
  AddLabel("Image syntax", 154)
  AddLabel("Status", 202)
  AddLabel("Requested", 262)
  AddLabel("Measured", 294)
  AddLabel("Ticks", 326)
  AddLabel("SVG bytes", 358)
  AddLabel("Base64 bytes", 390)
  AddLabel("Render time", 422)

  table.insert(graphics, {
    Type = "Text",
    Text = "COMPATIBILITY TEST ASSET - NOT PRODUCTION ART",
    Position = { 350, 476 },
    Size = { 178, 32 },
    FontSize = 8,
    HTextAlign = "Center"
  })

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
    Position = { 350, 74 },
    Size = { 82, 32 },
    Color = { 70, 230, 225 },
    Legend = "RUN"
  }

  layout["Reset"] = {
    PrettyName = "Probe~Reset",
    Style = "Button",
    ButtonStyle = "Trigger",
    ButtonVisualStyle = "Flat",
    Position = { 442, 74 },
    Size = { 82, 32 },
    Color = { 255, 155, 69 },
    Legend = "RESET"
  }

  layout["Rate"] = {
    PrettyName = "Probe~Rate",
    Style = "ComboBox",
    Position = { 440, 120 },
    Size = { 84, 22 }
  }

  layout["ImageSyntax"] = {
    PrettyName = "Probe~Image Syntax",
    Style = "ComboBox",
    Position = { 440, 152 },
    Size = { 84, 22 }
  }

  layout["Status"] = {
    PrettyName = "Probe~Status",
    Style = "Text",
    Position = { 350, 220 },
    Size = { 174, 34 },
    IsReadOnly = true,
    FontSize = 9,
    HTextAlign = "Center",
    VTextAlign = "Center"
  }

  local function AddReadout(name, y)
    layout[name] = {
      PrettyName = "Probe~" .. name,
      Style = "Text",
      Position = { 440, y },
      Size = { 84, 22 },
      IsReadOnly = true,
      FontSize = 9,
      HTextAlign = "Right"
    }
  end

  AddReadout("RequestedHz", 260)
  AddReadout("MeasuredHz", 292)
  AddReadout("TickCount", 324)
  AddReadout("SvgBytes", 356)
  AddReadout("SvgBase64Bytes", 388)
  AddReadout("LastRenderMs", 420)
end

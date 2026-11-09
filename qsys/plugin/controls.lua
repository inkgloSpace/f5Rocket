table.insert(controls, {
  Name = "Viewport",
  ControlType = "Button",
  ButtonType = "Momentary",
  DefaultValue = false,
  Count = 1
})

table.insert(controls, {
  Name = "Run",
  ControlType = "Button",
  ButtonType = "Toggle",
  DefaultValue = false,
  Count = 1
})

table.insert(controls, {
  Name = "Rate",
  ControlType = "Text",
  DefaultValue = "30 Hz",
  Count = 1
})

table.insert(controls, {
  Name = "ImageSyntax",
  ControlType = "Text",
  DefaultValue = "href",
  Count = 1
})

table.insert(controls, {
  Name = "Reset",
  ControlType = "Button",
  ButtonType = "Trigger",
  DefaultValue = false,
  Count = 1
})

table.insert(controls, {
  Name = "Status",
  ControlType = "Text",
  DefaultValue = "IDLE",
  Count = 1
})

table.insert(controls, {
  Name = "RequestedHz",
  ControlType = "Text",
  DefaultValue = "30 Hz",
  Count = 1
})

table.insert(controls, {
  Name = "MeasuredHz",
  ControlType = "Text",
  DefaultValue = "0.0 Hz",
  Count = 1
})

table.insert(controls, {
  Name = "TickCount",
  ControlType = "Text",
  DefaultValue = "0",
  Count = 1
})

table.insert(controls, {
  Name = "SvgBytes",
  ControlType = "Text",
  DefaultValue = "0",
  Count = 1
})

table.insert(controls, {
  Name = "SvgBase64Bytes",
  ControlType = "Text",
  DefaultValue = "0",
  Count = 1
})

table.insert(controls, {
  Name = "LastRenderMs",
  ControlType = "Text",
  DefaultValue = "0.000 ms CPU",
  Count = 1
})

local currentPage = props["page_index"].Value

if currentPage == 1 then
  table.insert(graphics, {
    Type = "GroupBox",
    Text = "",
    Position = { 8, 8 },
    Size = { 480, 720 },
    Fill = { 7, 16, 31 },
    StrokeWidth = 1
  })

  table.insert(graphics, {
    Type = "GroupBox",
    Text = "Controls",
    Position = { 500, 8 },
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
    Position = { 8, 8 },
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
    Position = { 8, 8 },
    Size = { 480, 720 },
    StrokeWidth = 0,
    CornerRadius = 0,
    Padding = 0,
    Margin = 0
  }

  layout["Run"] = {
    PrettyName = "Game~Run",
    Style = "Button",
    ButtonStyle = "Momentary",
    ButtonVisualStyle = "Flat",
    Position = { 514, 38 },
    Size = { 105, 34 },
    Color = { 70, 230, 225 },
    Legend = "RUN"
  }

  layout["Pause"] = {
    PrettyName = "Game~Pause",
    Style = "Button",
    ButtonStyle = "Toggle",
    ButtonVisualStyle = "Flat",
    Position = { 631, 38 },
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

  AddButton("UpLeft", 514, 90, 64, 44, "UL")
  AddButton("Up", 586, 90, 64, 44, "UP")
  AddButton("UpRight", 658, 90, 64, 44, "UR")
  AddButton("Left", 514, 140, 64, 44, "LEFT")
  AddButton("Right", 658, 140, 64, 44, "RIGHT")
  AddButton("DownLeft", 514, 190, 64, 44, "DL")
  AddButton("Down", 586, 190, 64, 44, "DOWN")
  AddButton("DownRight", 658, 190, 64, 44, "DR")
  AddButton("Fire", 514, 248, 105, 46, "FIRE")

  layout["AutoFire"] = {
    PrettyName = "Game~Auto Fire",
    Style = "Button",
    ButtonStyle = "Toggle",
    ButtonVisualStyle = "Flat",
    Position = { 631, 248 },
    Size = { 105, 46 },
    Color = { 255, 92, 157 },
    Legend = "AUTO FIRE"
  }

  layout["Status"] = {
    PrettyName = "Game~Status",
    Style = "Text",
    Position = { 514, 312 },
    Size = { 222, 50 },
    IsReadOnly = true,
    FontSize = 9,
    HTextAlign = "Center",
    VTextAlign = "Center"
  }

end

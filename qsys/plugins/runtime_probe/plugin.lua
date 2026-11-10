-- f5Rocket isolated Q-SYS runtime lifecycle probe
-- Modular source entry point. Build qsys/dist/f5Rocket_RuntimeProbe.qplug.

--[[ #include "info.lua" ]]

function GetPages(props)
  local pages = {}

  --[[ #include "pages.lua" ]]

  return pages
end

function GetProperties()
  local props = {}

  --[[ #include "properties.lua" ]]

  return props
end


function RectifyProperties(props)
  return props
end

function GetControls(props)
  local controls = {}

  --[[ #include "controls.lua" ]]

  return controls
end

function GetControlLayout(props)
  local layout = {}
  local graphics = {}

  --[[ #include "layout.lua" ]]

  return layout, graphics
end

if Controls then
  --[[ #include "runtime.lua" ]]
end

-- f5Rocket production Q-SYS game plugin
-- Modular source entry point. Build qsys/dist/f5Rocket.qplug for Designer.

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
  --[[ #include "game/config.lua" ]]
  --[[ #include "generated/assets_data.lua" ]]
  --[[ #include "renderer/assets.lua" ]]
  --[[ #include "game/state.lua" ]]
  --[[ #include "game/player.lua" ]]
  --[[ #include "game/bullets.lua" ]]
  --[[ #include "game/stages.lua" ]]
  --[[ #include "game/parallax.lua" ]]
  --[[ #include "game/enemies.lua" ]]
  --[[ #include "game/explosions.lua" ]]
  --[[ #include "game/bosses.lua" ]]
  --[[ #include "game/collision.lua" ]]
  --[[ #include "renderer/parallax_svg.lua" ]]
  --[[ #include "renderer/svg.lua" ]]
  --[[ #include "runtime.lua" ]]
end

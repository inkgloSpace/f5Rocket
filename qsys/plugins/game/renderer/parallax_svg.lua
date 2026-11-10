local PARALLAX_SVG_DEFINITIONS = table.concat({
  -- Easy: calm blue/white stars, tiny technical fragments, sparse cyan passes.
  "<g id=\"parallax_easy_star_dim\"><rect width=\"1\" height=\"1\" fill=\"#78bdf2\"/></g>",
  "<g id=\"parallax_easy_star_bright\"><circle cx=\"1\" cy=\"1\" r=\"1\" fill=\"#e8fbff\"/></g>",
  "<g id=\"parallax_easy_tech_a\"><rect width=\"5\" height=\"2\" fill=\"#55d9ff\"/><rect x=\"2\" y=\"-2\" width=\"1\" height=\"6\" fill=\"#8af4ff\"/></g>",
  "<g id=\"parallax_easy_tech_b\"><polygon points=\"0,2 3,0 7,2 3,4\" fill=\"#4a8fce\"/></g>",
  "<g id=\"parallax_easy_near_a\"><rect width=\"2\" height=\"12\" fill=\"#66f5ff\"/></g>",
  "<g id=\"parallax_easy_near_b\"><polygon points=\"0,0 5,2 2,7\" fill=\"#8fd9ed\"/></g>",

  -- Medium: purple/cyan stars plus visibly larger asteroid fragments.
  "<g id=\"parallax_medium_star_dim\"><rect width=\"1\" height=\"1\" fill=\"#9b64d9\"/></g>",
  "<g id=\"parallax_medium_star_bright\"><circle cx=\"1\" cy=\"1\" r=\"1\" fill=\"#61efff\"/></g>",
  "<g id=\"parallax_asteroid_small\"><polygon points=\"1,0 6,1 8,5 5,8 0,6\" fill=\"#70448f\" stroke=\"#b47ada\"/></g>",
  "<g id=\"parallax_asteroid_medium\"><polygon points=\"2,0 9,1 12,6 8,11 2,10 0,4\" fill=\"#4f315f\" stroke=\"#d052ad\"/></g>",
  "<g id=\"parallax_medium_near_rock\"><polygon points=\"2,0 11,2 14,8 8,12 0,9\" fill=\"#563260\" stroke=\"#ad62bd\"/></g>",
  "<g id=\"parallax_medium_particle\"><circle cx=\"2\" cy=\"2\" r=\"2\" fill=\"#ff54c8\"/></g>",

  -- Hard: dark mechanical debris and fast cyan/magenta energy fragments.
  "<g id=\"parallax_hard_star_dim\"><rect width=\"1\" height=\"1\" fill=\"#46506d\"/></g>",
  "<g id=\"parallax_hard_star_bright\"><rect width=\"2\" height=\"2\" fill=\"#ff4eb7\"/></g>",
  "<g id=\"parallax_hard_mech_a\"><path d=\"M0 1H9V4H6V7H2V4H0Z\" fill=\"#272d4f\" stroke=\"#4bd9e8\"/></g>",
  "<g id=\"parallax_hard_mech_b\"><rect width=\"11\" height=\"3\" fill=\"#39234e\"/><rect x=\"7\" y=\"3\" width=\"3\" height=\"5\" fill=\"#e348a5\"/></g>",
  "<g id=\"parallax_energy_streak\"><rect width=\"3\" height=\"18\" fill=\"#45f4ff\"/></g>",
  "<g id=\"parallax_data_fragment\"><rect width=\"7\" height=\"3\" fill=\"#ff4eb7\"/><rect x=\"2\" y=\"3\" width=\"2\" height=\"7\" fill=\"#6bdcff\"/></g>"
})

local PARALLAX_RENDER_PROFILES = {
  [1] = {
    Far = { "parallax_easy_star_dim", "parallax_easy_star_bright" },
    Mid = { "parallax_easy_tech_a", "parallax_easy_tech_b" },
    Near = { "parallax_easy_near_a", "parallax_easy_near_b" }
  },
  [2] = {
    Far = { "parallax_medium_star_dim", "parallax_medium_star_bright" },
    Mid = { "parallax_asteroid_small", "parallax_asteroid_medium" },
    Near = { "parallax_medium_near_rock", "parallax_medium_particle" }
  },
  [3] = {
    Far = { "parallax_hard_star_dim", "parallax_hard_star_bright" },
    Mid = { "parallax_hard_mech_a", "parallax_hard_mech_b" },
    Near = { "parallax_energy_streak", "parallax_data_fragment" }
  }
}

local function AppendParallaxLayer(parts, pool, maximum, definitions)
  for index = 1, maximum do
    local item = pool[index]
    if item.active then
      AppendDefinitionUse(
        parts,
        definitions[item.variant],
        item.x,
        item.y
      )
    end
  end
end

local function AppendFarParallax(parts, state)
  AppendParallaxLayer(
    parts,
    state.parallax.far,
    GAME_CONFIG.MaxFarParallax,
    PARALLAX_RENDER_PROFILES[state.stageIndex].Far
  )
end

local function AppendMidParallax(parts, state)
  AppendParallaxLayer(
    parts,
    state.parallax.mid,
    GAME_CONFIG.MaxMidParallax,
    PARALLAX_RENDER_PROFILES[state.stageIndex].Mid
  )
end

local function AppendNearParallax(parts, state)
  AppendParallaxLayer(
    parts,
    state.parallax.near,
    GAME_CONFIG.MaxNearParallax,
    PARALLAX_RENDER_PROFILES[state.stageIndex].Near
  )
end

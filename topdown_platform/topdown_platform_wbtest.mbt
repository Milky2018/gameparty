///|
fn visual(path : String) -> ImageVisualDef {
  { path, scale: 1.0, y_offset: 0.0 }
}

///|
fn strip(path : String) -> SpriteAnimDef {
  {
    image: path,
    frame_width: 480.0,
    frame_height: 480.0,
    columns: 4,
    frame_count: 12,
    fps: 12.0,
    scale: 1.35,
  }
}

///|
fn test_plugin() -> TopDownPluginDef {
  let legend : Map[Char, TileOrSpawnRule] = Map::new()
  legend.set('.', {
    kind: Floor,
    floor_image: Some(
      visual("assets/top-down-summer/Top-Down Simple Summer_Ground 01.png"),
    ),
    prop_image: None,
    blocks: false,
    actor_spawn_tag: None,
  })
  legend.set('#', {
    kind: Wall,
    floor_image: Some(
      visual("assets/top-down-summer/Top-Down Simple Summer_Ground 05.png"),
    ),
    prop_image: Some(
      visual("assets/top-down-summer/Top-Down Simple Summer_Prop - Rock 01.png"),
    ),
    blocks: true,
    actor_spawn_tag: None,
  })
  legend.set('P', {
    kind: PlayerSpawn,
    floor_image: Some(
      visual("assets/top-down-summer/Top-Down Simple Summer_Ground 02.png"),
    ),
    prop_image: None,
    blocks: false,
    actor_spawn_tag: None,
  })
  legend.set('A', {
    kind: ActorSpawn,
    floor_image: Some(
      visual("assets/top-down-summer/Top-Down Simple Summer_Ground 03.png"),
    ),
    prop_image: None,
    blocks: false,
    actor_spawn_tag: Some("lane_left"),
  })
  let sprites : DirectionalSprites = {
    up: strip("assets/assassin/Back - Running.png"),
    down: strip("assets/assassin/Front - Running.png"),
    left: strip("assets/assassin/Left - Running.png"),
    right: strip("assets/assassin/Right - Running.png"),
  }
  {
    meta: { id: "test", name: "test", version: "0.1.0" },
    map: {
      tile_size: 64.0,
      default_floor_image: visual(
        "assets/top-down-summer/Top-Down Simple Summer_Ground 01.png",
      ),
      rows: ["########", "#P....A#", "########"],
      legend,
    },
    player_archetype_id: "player",
    archetypes: [
      { id: "player", move_speed: 120.0, radius: 20.0, sprites },
      { id: "npc", move_speed: 0.0, radius: 18.0, sprites },
    ],
    actor_spawns: [
      { archetype_id: "npc", spawn_tag: Some("lane_left"), facing: Down },
    ],
    ui_theme: {
      title: "test",
      font_path: "assets/shared/fonts/mgs1codec.ttf",
      font_family: "MGS1Codec",
      hud_color_css: "rgb(220,235,250)",
      control_hint: "WASD move  ESC quit",
    },
    hooks: None,
  }
}

///|
test "validate_plugin accepts a complete core plugin" {
  assert_eq(validate_plugin(test_plugin()), None)
}

///|
test "validate_plugin reports missing legend entries" {
  let plugin = test_plugin()
  let broken : TopDownPluginDef = {
    meta: plugin.meta,
    map: {
      tile_size: plugin.map.tile_size,
      rows: ["????"],
      legend: plugin.map.legend,
      default_floor_image: plugin.map.default_floor_image,
    },
    player_archetype_id: plugin.player_archetype_id,
    archetypes: plugin.archetypes,
    actor_spawns: plugin.actor_spawns,
    ui_theme: plugin.ui_theme,
    hooks: plugin.hooks,
  }
  assert_true(validate_plugin(broken) is Some(_))
}

///|
test "validate_plugin rejects unknown actor spawn tag" {
  let plugin = test_plugin()
  let broken : TopDownPluginDef = {
    meta: plugin.meta,
    map: plugin.map,
    player_archetype_id: plugin.player_archetype_id,
    archetypes: plugin.archetypes,
    actor_spawns: [
      { archetype_id: "npc", spawn_tag: Some("missing"), facing: Down },
    ],
    ui_theme: plugin.ui_theme,
    hooks: plugin.hooks,
  }
  assert_true(validate_plugin(broken) is Some(_))
}

///|
test "validate_plugin requires exactly one player spawn" {
  let plugin = test_plugin()
  let legend = plugin.map.legend
  let broken : TopDownPluginDef = {
    meta: plugin.meta,
    map: {
      tile_size: plugin.map.tile_size,
      rows: ["########", "#.....A#", "########"],
      legend,
      default_floor_image: plugin.map.default_floor_image,
    },
    player_archetype_id: plugin.player_archetype_id,
    archetypes: plugin.archetypes,
    actor_spawns: plugin.actor_spawns,
    ui_theme: plugin.ui_theme,
    hooks: plugin.hooks,
  }
  assert_true(validate_plugin(broken) is Some(_))
}

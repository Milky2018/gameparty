///|
fn visual(path : String) -> @topdown_platform.ImageVisualDef {
  { path, scale: 1.0, y_offset: 0.0 }
}

///|
fn strip(path : String) -> @topdown_platform.SpriteAnimDef {
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
  let legend : Map[Char, @topdown_platform.TileOrSpawnRule] = Map::new()
  legend.set('.', {
    kind: @topdown_platform.Floor,
    floor_image: Some(
      visual("assets/top-down-summer/Top-Down Simple Summer_Ground 01.png"),
    ),
    prop_image: None,
    blocks: false,
    actor_spawn_tag: None,
  })
  legend.set('#', {
    kind: @topdown_platform.Wall,
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
    kind: @topdown_platform.PlayerSpawn,
    floor_image: Some(
      visual("assets/top-down-summer/Top-Down Simple Summer_Ground 02.png"),
    ),
    prop_image: None,
    blocks: false,
    actor_spawn_tag: None,
  })
  legend.set('A', {
    kind: @topdown_platform.ActorSpawn,
    floor_image: Some(
      visual("assets/top-down-summer/Top-Down Simple Summer_Ground 03.png"),
    ),
    prop_image: None,
    blocks: false,
    actor_spawn_tag: Some("villager_a"),
  })
  let sprites : @topdown_platform.DirectionalSprites = {
    up: strip("assets/assassin/Back - Running.png"),
    down: strip("assets/assassin/Front - Running.png"),
    left: strip("assets/assassin/Left - Running.png"),
    right: strip("assets/assassin/Right - Running.png"),
  }
  {
    meta: { id: "dialogue_test", name: "Dialogue Test", version: "0.1.0" },
    map: {
      tile_size: 64.0,
      default_floor_image: visual(
        "assets/top-down-summer/Top-Down Simple Summer_Ground 01.png",
      ),
      rows: ["#####", "#PA.#", "#####"],
      legend,
    },
    player_archetype_id: "player",
    archetypes: [
      { id: "player", move_speed: 120.0, radius: 20.0, sprites },
      { id: "villager", move_speed: 0.0, radius: 18.0, sprites },
    ],
    npcs: [
      {
        id: "mira",
        archetype_id: "villager",
        spawn_tag: "villager_a",
        facing: @topdown_platform.Down,
        display_name: "Mira",
        dialogue_id: "welcome",
      },
    ],
    dialogues: [
      {
        id: "welcome",
        lines: [
          { speaker: "Mira", text: "Welcome to the courtyard." },
          { speaker: "Player", text: "The new dialogue layer works." },
        ],
      },
    ],
    settings: {
      interaction_radius: 90.0,
      interact_prompt: "E TALK",
      advance_hint: "SPACE next  ESC close",
    },
    ui_theme: {
      title: "test",
      font_path: "assets/shared/fonts/mgs1codec.ttf",
      font_family: "MGS1Codec",
      hud_color_css: "rgb(220,235,250)",
      control_hint: "WASD move  E talk  ESC quit",
    },
    dialogue_theme: {
      prompt_color_css: "rgb(255,212,120)",
      speaker_color_css: "rgb(255,244,166)",
      text_color_css: "rgb(236,240,250)",
      hint_color_css: "rgb(180,210,255)",
      panel_color: { r: 23U, g: 28U, b: 39U, a: 0.92 },
    },
    hooks: None,
  }
}

///|
test "validate_plugin accepts a complete dialogue plugin" {
  assert_eq(validate_plugin(test_plugin()), None)
}

///|
test "validate_plugin rejects npc with missing dialogue" {
  let plugin = test_plugin()
  let broken_npcs : Array[NpcDef] = [
    {
      id: "mira",
      archetype_id: "villager",
      spawn_tag: "villager_a",
      facing: @topdown_platform.Down,
      display_name: "Mira",
      dialogue_id: "missing",
    },
  ]
  let broken : TopDownPluginDef = {
    meta: plugin.meta,
    map: plugin.map,
    player_archetype_id: plugin.player_archetype_id,
    archetypes: plugin.archetypes,
    npcs: broken_npcs,
    dialogues: plugin.dialogues,
    settings: plugin.settings,
    ui_theme: plugin.ui_theme,
    dialogue_theme: plugin.dialogue_theme,
    hooks: plugin.hooks,
  }
  assert_true(validate_plugin(broken) is Some(_))
}

///|
test "validate_plugin requires unique npc spawn tags" {
  let plugin = test_plugin()
  let broken_npcs : Array[NpcDef] = [
    plugin.npcs[0],
    {
      id: "echo",
      archetype_id: "villager",
      spawn_tag: "villager_a",
      facing: @topdown_platform.Up,
      display_name: "Echo",
      dialogue_id: "welcome",
    },
  ]
  let broken : TopDownPluginDef = {
    meta: plugin.meta,
    map: plugin.map,
    player_archetype_id: plugin.player_archetype_id,
    archetypes: plugin.archetypes,
    npcs: broken_npcs,
    dialogues: plugin.dialogues,
    settings: plugin.settings,
    ui_theme: plugin.ui_theme,
    dialogue_theme: plugin.dialogue_theme,
    hooks: plugin.hooks,
  }
  assert_true(validate_plugin(broken) is Some(_))
}

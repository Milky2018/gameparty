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
    enemy_spawn_tag: None,
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
    enemy_spawn_tag: None,
  })
  legend.set('P', {
    kind: PlayerSpawn,
    floor_image: Some(
      visual("assets/top-down-summer/Top-Down Simple Summer_Ground 02.png"),
    ),
    prop_image: None,
    blocks: false,
    enemy_spawn_tag: None,
  })
  legend.set('S', {
    kind: EnemySpawn,
    floor_image: Some(
      visual("assets/top-down-summer/Top-Down Simple Summer_Ground 03.png"),
    ),
    prop_image: None,
    blocks: false,
    enemy_spawn_tag: Some("lane_left"),
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
      rows: ["########", "#P....S#", "########"],
      legend,
    },
    archetypes: [
      {
        id: "player",
        ai_mode: Chase,
        preferred_range: 0.0,
        max_hp: 5,
        move_speed: 120.0,
        radius: 20.0,
        touch_damage: 1,
        score_value: 0,
        sprites,
        drop_table_id: None,
        primary_skill_id: Some("shot"),
        secondary_skill_id: None,
      },
      {
        id: "enemy",
        ai_mode: HoldDistance,
        preferred_range: 120.0,
        max_hp: 2,
        move_speed: 90.0,
        radius: 18.0,
        touch_damage: 1,
        score_value: 10,
        sprites,
        drop_table_id: Some("common"),
        primary_skill_id: None,
        secondary_skill_id: None,
      },
    ],
    skills: [
      {
        id: "shot",
        kind: Projectile,
        cooldown: 0.2,
        damage: 1,
        range: 240.0,
        projectile_speed: 300.0,
        projectile_radius: 5.0,
      },
    ],
    waves: [
      {
        id: 1,
        start_delay: 0.0,
        entries: [
          {
            archetype_id: "enemy",
            count: 3,
            spawn_interval: 0.2,
            spawn_tag: Some("lane_left"),
          },
        ],
      },
    ],
    drops: [
      {
        id: "common",
        chance: 1.0,
        items: [
          {
            id: "coin",
            image: "assets/top-down-summer/Top-Down Simple Summer_Prop - Treasure Chest.png",
            weight: 1,
            heal: 0,
            score_bonus: 10,
          },
        ],
      },
    ],
    progression: { run_seconds: 120.0, player_archetype_id: "player" },
    ui_theme: {
      title: "test",
      font_path: "assets/shared/fonts/ThaleahFat.ttf",
      font_family: "ThaleahFat",
      hud_color_css: "rgb(220,235,250)",
      control_hint: "WASD move  LMB primary  SPACE secondary  ESC quit",
    },
    hooks: None,
  }
}

///|
test "validate_plugin accepts a complete plugin" {
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
    archetypes: plugin.archetypes,
    skills: plugin.skills,
    waves: plugin.waves,
    drops: plugin.drops,
    progression: plugin.progression,
    ui_theme: plugin.ui_theme,
    hooks: plugin.hooks,
  }
  assert_true(validate_plugin(broken) is Some(_))
}

///|
test "choose_drop_item respects singleton table" {
  let table : DropTableDef = {
    id: "single",
    chance: 1.0,
    items: [{ id: "only", image: "x.png", weight: 2, heal: 0, score_bonus: 0 }],
  }
  assert_true(choose_drop_item(table) is Some({ id: "only", .. }))
}

///|
test "validate_plugin rejects unknown wave spawn tag" {
  let plugin = test_plugin()
  let broken_waves : Array[WaveDef] = [
    {
      id: 1,
      start_delay: 0.0,
      entries: [
        {
          archetype_id: "enemy",
          count: 1,
          spawn_interval: 0.2,
          spawn_tag: Some("unknown_tag"),
        },
      ],
    },
  ]
  let broken : TopDownPluginDef = {
    meta: plugin.meta,
    map: plugin.map,
    archetypes: plugin.archetypes,
    skills: plugin.skills,
    waves: broken_waves,
    drops: plugin.drops,
    progression: plugin.progression,
    ui_theme: plugin.ui_theme,
    hooks: plugin.hooks,
  }
  let err = validate_plugin(broken).unwrap_or("")
  assert_true(err.contains("spawn_tag"))
}

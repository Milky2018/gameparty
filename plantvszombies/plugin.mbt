///|
fn visual(
  path : String,
  scale? : Double = 1.0,
  y_offset? : Double = 0.0,
) -> @topdown_platform.ImageVisualDef {
  { path, scale, y_offset }
}

///|
fn sprite_strip(
  image : String,
  scale? : Double = 2.2,
  fps? : Double = 10.0,
) -> @topdown_platform.SpriteAnimDef {
  {
    image,
    frame_width: 480.0,
    frame_height: 480.0,
    columns: 4,
    frame_count: 12,
    fps,
    scale,
  }
}

///|
fn floor_rule(path : String) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.Floor,
    floor_image: Some(visual(path)),
    prop_image: None,
    blocks: false,
    enemy_spawn_tag: None,
  }
}

///|
fn wall_rule(
  floor : String,
  prop : String,
) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.Wall,
    floor_image: Some(visual(floor)),
    prop_image: Some(visual(prop, scale=1.12, y_offset=-8.0)),
    blocks: true,
    enemy_spawn_tag: None,
  }
}

///|
fn player_spawn_rule(path : String) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.PlayerSpawn,
    floor_image: Some(visual(path)),
    prop_image: None,
    blocks: false,
    enemy_spawn_tag: None,
  }
}

///|
fn lane_spawn_rule(
  path : String,
  lane_tag : String,
) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.EnemySpawn,
    floor_image: Some(visual(path)),
    prop_image: None,
    blocks: false,
    enemy_spawn_tag: Some(lane_tag),
  }
}

///|
fn build_legend() -> Map[Char, @topdown_platform.TileOrSpawnRule] {
  let legend : Map[Char, @topdown_platform.TileOrSpawnRule] = Map::new()
  let ground = "assets/top-down-summer/Top-Down Simple Summer_Ground 43.png"
  legend.set('.', floor_rule(ground))
  legend.set(',', floor_rule(ground))
  legend.set('P', player_spawn_rule(ground))
  legend.set('1', lane_spawn_rule(ground, "lane1"))
  legend.set('2', lane_spawn_rule(ground, "lane2"))
  legend.set('3', lane_spawn_rule(ground, "lane3"))
  legend.set('4', lane_spawn_rule(ground, "lane4"))
  legend.set('5', lane_spawn_rule(ground, "lane5"))
  legend.set(
    '#',
    wall_rule(
      ground, "assets/top-down-summer/Top-Down Simple Summer_Prop - Rock 02.png",
    ),
  )
  legend.set(
    'H',
    wall_rule(
      ground, "assets/top-down-summer/Top-Down Simple Summer_Prop - House.png",
    ),
  )
  legend.set(
    'T',
    wall_rule(
      ground, "assets/top-down-summer/Top-Down Simple Summer_Prop - Tree Small.png",
    ),
  )
  legend
}

///|
fn gardener_sprites() -> @topdown_platform.DirectionalSprites {
  {
    up: sprite_strip("assets/assassin/Back - Running.png"),
    down: sprite_strip("assets/assassin/Front - Running.png"),
    left: sprite_strip("assets/assassin/Left - Running.png"),
    right: sprite_strip("assets/assassin/Right - Running.png"),
  }
}

///|
fn zombie_sprites() -> @topdown_platform.DirectionalSprites {
  {
    up: sprite_strip("assets/thug/Back - Running.png"),
    down: sprite_strip("assets/thug/Front - Running.png"),
    left: sprite_strip("assets/thug/Left - Running.png"),
    right: sprite_strip("assets/thug/Right - Running.png"),
  }
}

///|
fn conehead_sprites() -> @topdown_platform.DirectionalSprites {
  {
    up: sprite_strip("assets/robber/Back - Running.png"),
    down: sprite_strip("assets/robber/Front - Running.png"),
    left: sprite_strip("assets/robber/Left - Running.png"),
    right: sprite_strip("assets/robber/Right - Running.png"),
  }
}

///|
pub let plugin : @topdown_platform.TopDownPluginDef = {
  meta: { id: "plantvszombies", name: "Plants VS Zombies TD", version: "2.0.0" },
  map: {
    tile_size: 64.0,
    default_floor_image: visual(
      "assets/top-down-summer/Top-Down Simple Summer_Ground 43.png",
    ),
    rows: [
      "####################", "#1................##", "#..TTT....,........#", "#2................##",
      "#..TTT....H........#", "#3.......P.........#", "#..TTT....,........#", "#4................##",
      "#..TTT....,........#", "#5................##", "####################",
    ],
    legend: build_legend(),
  },
  archetypes: [
    {
      id: "gardener",
      ai_mode: @topdown_platform.Chase,
      preferred_range: 0.0,
      max_hp: 14,
      move_speed: 165.0,
      radius: 20.0,
      touch_damage: 0,
      score_value: 0,
      sprites: gardener_sprites(),
      drop_table_id: None,
      primary_skill_id: Some("pea_shot"),
      secondary_skill_id: Some("shovel_smash"),
    },
    {
      id: "zombie",
      ai_mode: @topdown_platform.Chase,
      preferred_range: 0.0,
      max_hp: 6,
      move_speed: 78.0,
      radius: 19.0,
      touch_damage: 2,
      score_value: 30,
      sprites: zombie_sprites(),
      drop_table_id: Some("sun"),
      primary_skill_id: Some("zombie_bite"),
      secondary_skill_id: None,
    },
    {
      id: "conehead",
      ai_mode: @topdown_platform.HoldDistance,
      preferred_range: 120.0,
      max_hp: 10,
      move_speed: 72.0,
      radius: 20.0,
      touch_damage: 2,
      score_value: 55,
      sprites: conehead_sprites(),
      drop_table_id: Some("sun"),
      primary_skill_id: Some("spore_glob"),
      secondary_skill_id: None,
    },
  ],
  skills: [
    {
      id: "pea_shot",
      kind: @topdown_platform.Projectile,
      cooldown: 0.32,
      damage: 2,
      range: 315.0,
      projectile_speed: 440.0,
      projectile_radius: 4.0,
    },
    {
      id: "shovel_smash",
      kind: @topdown_platform.Melee,
      cooldown: 0.5,
      damage: 4,
      range: 46.0,
      projectile_speed: 0.0,
      projectile_radius: 0.0,
    },
    {
      id: "zombie_bite",
      kind: @topdown_platform.Melee,
      cooldown: 0.95,
      damage: 2,
      range: 38.0,
      projectile_speed: 0.0,
      projectile_radius: 0.0,
    },
    {
      id: "spore_glob",
      kind: @topdown_platform.Projectile,
      cooldown: 1.25,
      damage: 2,
      range: 230.0,
      projectile_speed: 260.0,
      projectile_radius: 5.0,
    },
  ],
  waves: [
    {
      id: 1,
      start_delay: 1.0,
      entries: [
        {
          archetype_id: "zombie",
          count: 4,
          spawn_interval: 0.95,
          spawn_tag: Some("lane2"),
        },
        {
          archetype_id: "zombie",
          count: 4,
          spawn_interval: 0.95,
          spawn_tag: Some("lane4"),
        },
      ],
    },
    {
      id: 2,
      start_delay: 1.2,
      entries: [
        {
          archetype_id: "zombie",
          count: 7,
          spawn_interval: 0.78,
          spawn_tag: Some("lane1"),
        },
        {
          archetype_id: "conehead",
          count: 4,
          spawn_interval: 1.15,
          spawn_tag: Some("lane5"),
        },
      ],
    },
    {
      id: 3,
      start_delay: 1.4,
      entries: [
        {
          archetype_id: "zombie",
          count: 8,
          spawn_interval: 0.72,
          spawn_tag: Some("lane3"),
        },
        {
          archetype_id: "conehead",
          count: 6,
          spawn_interval: 0.95,
          spawn_tag: Some("lane2"),
        },
      ],
    },
  ],
  drops: [
    {
      id: "sun",
      chance: 0.46,
      items: [
        {
          id: "sun_small",
          image: "assets/top-down-summer/Top-Down Simple Summer_Prop - Bushes Small.png",
          weight: 6,
          heal: 1,
          score_bonus: 16,
        },
        {
          id: "sun_big",
          image: "assets/top-down-summer/Top-Down Simple Summer_Prop - Treasure Chest.png",
          weight: 3,
          heal: 2,
          score_bonus: 28,
        },
      ],
    },
  ],
  progression: { run_seconds: 300.0, player_archetype_id: "gardener" },
  ui_theme: {
    title: "PLANTS VS ZOMBIES TD",
    font_path: "assets/shared/fonts/ThaleahFat.ttf",
    font_family: "ThaleahFat",
    hud_color_css: "rgb(235,246,227)",
    control_hint: "WASD move  LMB pea shot  SPACE shovel  ESC quit",
  },
  hooks: None,
}

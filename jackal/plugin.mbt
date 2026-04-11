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
  scale? : Double = 2.35,
  fps? : Double = 12.0,
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
fn summer_floor(path : String) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.Floor,
    floor_image: Some(visual(path)),
    prop_image: None,
    blocks: false,
    enemy_spawn_tag: None,
  }
}

///|
fn summer_wall(
  floor : String,
  prop : String,
) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.Wall,
    floor_image: Some(visual(floor)),
    prop_image: Some(visual(prop, scale=1.18, y_offset=-8.0)),
    blocks: true,
    enemy_spawn_tag: None,
  }
}

///|
fn summer_player_spawn(path : String) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.PlayerSpawn,
    floor_image: Some(visual(path)),
    prop_image: None,
    blocks: false,
    enemy_spawn_tag: None,
  }
}

///|
fn summer_enemy_spawn(
  path : String,
  spawn_tag : String,
) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.EnemySpawn,
    floor_image: Some(visual(path)),
    prop_image: None,
    blocks: false,
    enemy_spawn_tag: Some(spawn_tag),
  }
}

///|
fn build_legend() -> Map[Char, @topdown_platform.TileOrSpawnRule] {
  let legend : Map[Char, @topdown_platform.TileOrSpawnRule] = Map::new()
  let base_floor = "assets/top-down-summer/Top-Down Simple Summer_Ground 43.png"
  legend.set('.', summer_floor(base_floor))
  legend.set(',', summer_floor(base_floor))
  legend.set('P', summer_player_spawn(base_floor))
  legend.set('N', summer_enemy_spawn(base_floor, "north"))
  legend.set('W', summer_enemy_spawn(base_floor, "west"))
  legend.set('E', summer_enemy_spawn(base_floor, "east"))
  legend.set('S', summer_enemy_spawn(base_floor, "south"))
  legend.set(
    '#',
    summer_wall(
      base_floor, "assets/top-down-summer/Top-Down Simple Summer_Prop - Rock 02.png",
    ),
  )
  legend.set(
    'T',
    summer_wall(
      base_floor, "assets/top-down-summer/Top-Down Simple Summer_Prop - Tree Small.png",
    ),
  )
  legend.set(
    'B',
    summer_wall(
      base_floor, "assets/top-down-summer/Top-Down Simple Summer_Prop - Wooden Crate.png",
    ),
  )
  legend
}

///|
fn commando_sprites() -> @topdown_platform.DirectionalSprites {
  {
    up: sprite_strip("assets/assassin/Back - Running.png"),
    down: sprite_strip("assets/assassin/Front - Running.png"),
    left: sprite_strip("assets/assassin/Left - Running.png"),
    right: sprite_strip("assets/assassin/Right - Running.png"),
  }
}

///|
fn scout_sprites() -> @topdown_platform.DirectionalSprites {
  {
    up: sprite_strip("assets/robber/Back - Running.png"),
    down: sprite_strip("assets/robber/Front - Running.png"),
    left: sprite_strip("assets/robber/Left - Running.png"),
    right: sprite_strip("assets/robber/Right - Running.png"),
  }
}

///|
fn grunt_sprites() -> @topdown_platform.DirectionalSprites {
  {
    up: sprite_strip("assets/thug/Back - Running.png"),
    down: sprite_strip("assets/thug/Front - Running.png"),
    left: sprite_strip("assets/thug/Left - Running.png"),
    right: sprite_strip("assets/thug/Right - Running.png"),
  }
}

///|
pub let plugin : @topdown_platform.TopDownPluginDef = {
  meta: { id: "jackal", name: "Jackal Reloaded", version: "2.0.0" },
  map: {
    tile_size: 64.0,
    default_floor_image: visual(
      "assets/top-down-summer/Top-Down Simple Summer_Ground 43.png",
    ),
    rows: [
      "####################", "#N...,,,....T....E.#", "#..####.B..####....#", "#..#..#....#..#....#",
      "#..#..#..TT.#..#...#", "#..#..#....#..#....#", "#..####....####....#", "#....W....P....S...#",
      "#..####....####....#", "#..#..#....#..#....#", "#..#..#....#..#....#", "####################",
    ],
    legend: build_legend(),
  },
  archetypes: [
    {
      id: "commando",
      ai_mode: @topdown_platform.Chase,
      preferred_range: 0.0,
      max_hp: 12,
      move_speed: 190.0,
      radius: 20.0,
      touch_damage: 0,
      score_value: 0,
      sprites: commando_sprites(),
      drop_table_id: None,
      primary_skill_id: Some("rifle_burst"),
      secondary_skill_id: Some("combat_knife"),
    },
    {
      id: "scout",
      ai_mode: @topdown_platform.HoldDistance,
      preferred_range: 210.0,
      max_hp: 4,
      move_speed: 135.0,
      radius: 18.0,
      touch_damage: 1,
      score_value: 40,
      sprites: scout_sprites(),
      drop_table_id: Some("standard"),
      primary_skill_id: Some("scout_shot"),
      secondary_skill_id: None,
    },
    {
      id: "grunt",
      ai_mode: @topdown_platform.Chase,
      preferred_range: 0.0,
      max_hp: 7,
      move_speed: 105.0,
      radius: 20.0,
      touch_damage: 2,
      score_value: 60,
      sprites: grunt_sprites(),
      drop_table_id: Some("standard"),
      primary_skill_id: Some("grunt_slash"),
      secondary_skill_id: None,
    },
    {
      id: "rocketeer",
      ai_mode: @topdown_platform.Wander,
      preferred_range: 0.0,
      max_hp: 9,
      move_speed: 120.0,
      radius: 20.0,
      touch_damage: 2,
      score_value: 95,
      sprites: commando_sprites(),
      drop_table_id: Some("elite"),
      primary_skill_id: Some("rocket_bolt"),
      secondary_skill_id: None,
    },
  ],
  skills: [
    {
      id: "rifle_burst",
      kind: @topdown_platform.Projectile,
      cooldown: 0.24,
      damage: 2,
      range: 320.0,
      projectile_speed: 490.0,
      projectile_radius: 4.0,
    },
    {
      id: "combat_knife",
      kind: @topdown_platform.Melee,
      cooldown: 0.34,
      damage: 3,
      range: 46.0,
      projectile_speed: 0.0,
      projectile_radius: 0.0,
    },
    {
      id: "scout_shot",
      kind: @topdown_platform.Projectile,
      cooldown: 1.05,
      damage: 1,
      range: 280.0,
      projectile_speed: 350.0,
      projectile_radius: 4.0,
    },
    {
      id: "grunt_slash",
      kind: @topdown_platform.Melee,
      cooldown: 0.82,
      damage: 2,
      range: 42.0,
      projectile_speed: 0.0,
      projectile_radius: 0.0,
    },
    {
      id: "rocket_bolt",
      kind: @topdown_platform.Projectile,
      cooldown: 1.2,
      damage: 3,
      range: 300.0,
      projectile_speed: 300.0,
      projectile_radius: 5.0,
    },
  ],
  waves: [
    {
      id: 1,
      start_delay: 1.0,
      entries: [
        {
          archetype_id: "scout",
          count: 6,
          spawn_interval: 0.7,
          spawn_tag: Some("north"),
        },
        {
          archetype_id: "grunt",
          count: 3,
          spawn_interval: 0.95,
          spawn_tag: Some("west"),
        },
      ],
    },
    {
      id: 2,
      start_delay: 1.2,
      entries: [
        {
          archetype_id: "scout",
          count: 8,
          spawn_interval: 0.55,
          spawn_tag: Some("east"),
        },
        {
          archetype_id: "grunt",
          count: 5,
          spawn_interval: 0.8,
          spawn_tag: Some("south"),
        },
      ],
    },
    {
      id: 3,
      start_delay: 1.5,
      entries: [
        {
          archetype_id: "grunt",
          count: 7,
          spawn_interval: 0.65,
          spawn_tag: Some("west"),
        },
        {
          archetype_id: "rocketeer",
          count: 4,
          spawn_interval: 1.0,
          spawn_tag: Some("east"),
        },
      ],
    },
  ],
  drops: [
    {
      id: "standard",
      chance: 0.42,
      items: [
        {
          id: "ammo_box",
          image: "assets/top-down-summer/Top-Down Simple Summer_Prop - Wooden Crate.png",
          weight: 6,
          heal: 0,
          score_bonus: 20,
        },
        {
          id: "field_kit",
          image: "assets/top-down-summer/Top-Down Simple Summer_Prop - Campfire.png",
          weight: 4,
          heal: 2,
          score_bonus: 0,
        },
      ],
    },
    {
      id: "elite",
      chance: 0.68,
      items: [
        {
          id: "intel_case",
          image: "assets/top-down-summer/Top-Down Simple Summer_Prop - Treasure Chest.png",
          weight: 5,
          heal: 0,
          score_bonus: 75,
        },
        {
          id: "advanced_kit",
          image: "assets/top-down-summer/Top-Down Simple Summer_Prop - Bushes Small.png",
          weight: 3,
          heal: 3,
          score_bonus: 10,
        },
      ],
    },
  ],
  progression: { run_seconds: 360.0, player_archetype_id: "commando" },
  ui_theme: {
    title: "JACKAL RELOADED",
    font_path: "assets/shared/fonts/ThaleahFat.ttf",
    font_family: "ThaleahFat",
    hud_color_css: "rgb(236,245,255)",
    control_hint: "WASD move  LMB fire  SPACE knife  ESC quit",
  },
  hooks: None,
}

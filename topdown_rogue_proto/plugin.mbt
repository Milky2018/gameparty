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
  scale? : Double = 1.35,
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
    prop_image: Some(visual(prop, scale=1.2, y_offset=-10.0)),
    blocks: true,
  }
}

///|
fn summer_player_spawn(path : String) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.PlayerSpawn,
    floor_image: Some(visual(path)),
    prop_image: None,
    blocks: false,
  }
}

///|
fn summer_enemy_spawn(path : String) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.EnemySpawn,
    floor_image: Some(visual(path)),
    prop_image: None,
    blocks: false,
  }
}

///|
fn build_legend() -> Map[Char, @topdown_platform.TileOrSpawnRule] {
  let legend : Map[Char, @topdown_platform.TileOrSpawnRule] = Map::new()
  let base_floor = "assets/top-down-summer/Top-Down Simple Summer_Ground 43.png"
  legend.set('.', summer_floor(base_floor))
  legend.set(',', summer_floor(base_floor))
  legend.set('~', summer_floor(base_floor))
  legend.set('P', summer_player_spawn(base_floor))
  legend.set('S', summer_enemy_spawn(base_floor))
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
    'H',
    summer_wall(
      base_floor, "assets/top-down-summer/Top-Down Simple Summer_Prop - House.png",
    ),
  )
  legend
}

///|
fn assassin_sprites() -> @topdown_platform.DirectionalSprites {
  {
    up: sprite_strip("assets/assassin/Back - Running.png"),
    down: sprite_strip("assets/assassin/Front - Running.png"),
    left: sprite_strip("assets/assassin/Left - Running.png"),
    right: sprite_strip("assets/assassin/Right - Running.png"),
  }
}

///|
fn robber_sprites() -> @topdown_platform.DirectionalSprites {
  {
    up: sprite_strip("assets/robber/Back - Running.png"),
    down: sprite_strip("assets/robber/Front - Running.png"),
    left: sprite_strip("assets/robber/Left - Running.png"),
    right: sprite_strip("assets/robber/Right - Running.png"),
  }
}

///|
fn thug_sprites() -> @topdown_platform.DirectionalSprites {
  {
    up: sprite_strip("assets/thug/Back - Running.png"),
    down: sprite_strip("assets/thug/Front - Running.png"),
    left: sprite_strip("assets/thug/Left - Running.png"),
    right: sprite_strip("assets/thug/Right - Running.png"),
  }
}

///|
fn phase_name(phase : @topdown_platform.RunPhase) -> String {
  match phase {
    @topdown_platform.Boot => "Boot"
    @topdown_platform.Playing => "Playing"
    @topdown_platform.Won => "Won"
    @topdown_platform.Lost => "Lost"
  }
}

///|
fn on_run_start(snapshot : @topdown_platform.PluginRuntimeState) -> Unit {
  println(
    "[topdown_rogue_proto] run started phase=\{phase_name(snapshot.phase)} wave=\{snapshot.wave}/\{snapshot.waves_total}",
  )
}

///|
fn on_enemy_killed(
  snapshot : @topdown_platform.PluginRuntimeState,
  archetype_id : String,
) -> Unit {
  println(
    "[topdown_rogue_proto] killed=\{archetype_id} score=\{snapshot.score} kills=\{snapshot.enemies_killed}",
  )
}

///|
fn on_pickup(
  snapshot : @topdown_platform.PluginRuntimeState,
  item_id : String,
) -> Unit {
  println(
    "[topdown_rogue_proto] pickup=\{item_id} hp=\{snapshot.player_hp}/\{snapshot.player_hp_max}",
  )
}

///|
pub let plugin : @topdown_platform.TopDownPluginDef = {
  meta: {
    id: "topdown_rogue_proto",
    name: "TopDown Rogue Proto",
    version: "0.1.0",
  },
  map: {
    tile_size: 64.0,
    rows: [
      "####################", "#...,...,T.....,..S#", "#..####......##....#", "#..#..#..,,,..#....#",
      "#..#..#..TTT..#....#", "#..#..#........#...#", "#..####....,....S..#", "#....P....H........#",
      "#....S.......TT....#", "#.....,........,...#", "####################",
    ],
    legend: build_legend(),
  },
  archetypes: [
    {
      id: "player_assassin",
      max_hp: 12,
      move_speed: 180.0,
      radius: 20.0,
      touch_damage: 0,
      score_value: 0,
      sprites: assassin_sprites(),
      drop_table_id: None,
      primary_skill_id: Some("dagger_throw"),
      secondary_skill_id: Some("knife_slash"),
    },
    {
      id: "robber",
      max_hp: 4,
      move_speed: 120.0,
      radius: 18.0,
      touch_damage: 1,
      score_value: 35,
      sprites: robber_sprites(),
      drop_table_id: Some("common"),
      primary_skill_id: None,
      secondary_skill_id: None,
    },
    {
      id: "thug",
      max_hp: 6,
      move_speed: 90.0,
      radius: 20.0,
      touch_damage: 2,
      score_value: 55,
      sprites: thug_sprites(),
      drop_table_id: Some("common"),
      primary_skill_id: None,
      secondary_skill_id: None,
    },
    {
      id: "assassin_elite",
      max_hp: 8,
      move_speed: 130.0,
      radius: 20.0,
      touch_damage: 2,
      score_value: 80,
      sprites: assassin_sprites(),
      drop_table_id: Some("elite"),
      primary_skill_id: None,
      secondary_skill_id: None,
    },
  ],
  skills: [
    {
      id: "knife_slash",
      kind: @topdown_platform.Melee,
      cooldown: 0.30,
      damage: 2,
      range: 46.0,
      projectile_speed: 0.0,
      projectile_radius: 0.0,
    },
    {
      id: "dagger_throw",
      kind: @topdown_platform.Projectile,
      cooldown: 0.36,
      damage: 2,
      range: 300.0,
      projectile_speed: 420.0,
      projectile_radius: 5.0,
    },
  ],
  waves: [
    {
      id: 1,
      start_delay: 1.0,
      entries: [
        { archetype_id: "robber", count: 5, spawn_interval: 0.7 },
        { archetype_id: "thug", count: 2, spawn_interval: 1.0 },
      ],
    },
    {
      id: 2,
      start_delay: 1.2,
      entries: [
        { archetype_id: "robber", count: 7, spawn_interval: 0.55 },
        { archetype_id: "thug", count: 4, spawn_interval: 0.8 },
      ],
    },
    {
      id: 3,
      start_delay: 1.5,
      entries: [
        { archetype_id: "thug", count: 6, spawn_interval: 0.65 },
        { archetype_id: "assassin_elite", count: 3, spawn_interval: 1.0 },
      ],
    },
  ],
  drops: [
    {
      id: "common",
      chance: 0.38,
      items: [
        {
          id: "coin",
          image: "assets/top-down-summer/Top-Down Simple Summer_Prop - Treasure Chest.png",
          weight: 6,
          heal: 0,
          score_bonus: 22,
        },
        {
          id: "herb",
          image: "assets/top-down-summer/Top-Down Simple Summer_Prop - Bushes Small.png",
          weight: 4,
          heal: 1,
          score_bonus: 0,
        },
      ],
    },
    {
      id: "elite",
      chance: 0.65,
      items: [
        {
          id: "big_coin",
          image: "assets/top-down-summer/Top-Down Simple Summer_Prop - Treasure Chest.png",
          weight: 5,
          heal: 0,
          score_bonus: 60,
        },
        {
          id: "camp_kit",
          image: "assets/top-down-summer/Top-Down Simple Summer_Prop - Campfire.png",
          weight: 3,
          heal: 2,
          score_bonus: 15,
        },
      ],
    },
  ],
  progression: { run_seconds: 300.0, player_archetype_id: "player_assassin" },
  ui_theme: {
    title: "TOPDOWN ROGUE PROTO",
    font_path: "assets/shared/fonts/ThaleahFat.ttf",
    font_family: "ThaleahFat",
    hud_color_css: "rgb(226,238,252)",
  },
  hooks: Some({
    on_run_start: Some(on_run_start),
    on_enemy_killed: Some(on_enemy_killed),
    on_pickup: Some(on_pickup),
  }),
}

///|
fn build_legend() -> Map[Char, @topdown_platform.TileOrSpawnRule] {
  let legend : Map[Char, @topdown_platform.TileOrSpawnRule] = Map::new()
  let floor = @kit.summer_ground_43
  legend.set('.', @kit.floor_tile(floor))
  legend.set(',', @kit.floor_tile(floor))
  legend.set('P', @kit.player_spawn_tile(floor))
  legend.set('N', @kit.enemy_spawn_tile(floor, "north"))
  legend.set('W', @kit.enemy_spawn_tile(floor, "west"))
  legend.set('E', @kit.enemy_spawn_tile(floor, "east"))
  legend.set('S', @kit.enemy_spawn_tile(floor, "south"))
  legend.set(
    '#',
    @kit.wall_tile(
      floor, "assets/top-down-summer/Top-Down Simple Summer_Prop - Rock 02.png",
    ),
  )
  legend.set(
    'T',
    @kit.wall_tile(
      floor, "assets/top-down-summer/Top-Down Simple Summer_Prop - Tree Small.png",
    ),
  )
  legend.set(
    'B',
    @kit.wall_tile(
      floor,
      "assets/top-down-summer/Top-Down Simple Summer_Prop - Wooden Crate.png",
      prop_scale=1.18,
      prop_y_offset=-8.0,
    ),
  )
  legend
}

///|
pub let plugin : @topdown_platform.TopDownPluginDef = {
  meta: { id: "jackal", name: "Jackal Reloaded", version: "2.0.0" },
  map: {
    tile_size: 64.0,
    default_floor_image: @kit.visual(@kit.summer_ground_43),
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
      sprites: @kit.humanoid_running_sprites("assets/assassin", scale=2.35),
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
      sprites: @kit.humanoid_running_sprites("assets/robber", scale=2.35),
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
      sprites: @kit.humanoid_running_sprites("assets/thug", scale=2.35),
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
      sprites: @kit.humanoid_running_sprites("assets/assassin", scale=2.35),
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
        @kit.wave_entry("scout", 6, 0.7, spawn_tag=Some("north")),
        @kit.wave_entry("grunt", 3, 0.95, spawn_tag=Some("west")),
      ],
    },
    {
      id: 2,
      start_delay: 1.2,
      entries: [
        @kit.wave_entry("scout", 8, 0.55, spawn_tag=Some("east")),
        @kit.wave_entry("grunt", 5, 0.8, spawn_tag=Some("south")),
      ],
    },
    {
      id: 3,
      start_delay: 1.5,
      entries: [
        @kit.wave_entry("grunt", 7, 0.65, spawn_tag=Some("west")),
        @kit.wave_entry("rocketeer", 4, 1.0, spawn_tag=Some("east")),
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
  ui_theme: @kit.ui_theme(
    "JACKAL RELOADED", "assets/shared/fonts/ThaleahFat.ttf", "ThaleahFat", "rgb(236,245,255)",
    "WASD move  LMB fire  SPACE knife  ESC quit",
  ),
  hooks: None,
}

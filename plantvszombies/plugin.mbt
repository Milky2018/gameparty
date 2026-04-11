///|
fn build_legend() -> Map[Char, @topdown_platform.TileOrSpawnRule] {
  let legend : Map[Char, @topdown_platform.TileOrSpawnRule] = Map::new()
  let floor = @kit.summer_ground_43
  legend.set('.', @kit.floor_tile(floor))
  legend.set(',', @kit.floor_tile(floor))
  legend.set('P', @kit.player_spawn_tile(floor))
  legend.set('1', @kit.enemy_spawn_tile(floor, "lane1"))
  legend.set('2', @kit.enemy_spawn_tile(floor, "lane2"))
  legend.set('3', @kit.enemy_spawn_tile(floor, "lane3"))
  legend.set('4', @kit.enemy_spawn_tile(floor, "lane4"))
  legend.set('5', @kit.enemy_spawn_tile(floor, "lane5"))
  legend.set(
    '#',
    @kit.wall_tile(
      floor, "assets/top-down-summer/Top-Down Simple Summer_Prop - Rock 02.png",
    ),
  )
  legend.set(
    'H',
    @kit.wall_tile(
      floor, "assets/top-down-summer/Top-Down Simple Summer_Prop - House.png",
    ),
  )
  legend.set(
    'T',
    @kit.wall_tile(
      floor, "assets/top-down-summer/Top-Down Simple Summer_Prop - Tree Small.png",
    ),
  )
  legend
}

///|
pub let plugin : @topdown_platform.TopDownPluginDef = {
  meta: { id: "plantvszombies", name: "Plants VS Zombies TD", version: "2.0.0" },
  map: {
    tile_size: 64.0,
    default_floor_image: @kit.visual(@kit.summer_ground_43),
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
      sprites: @kit.humanoid_running_sprites(
        "assets/assassin",
        scale=2.2,
        fps=10.0,
      ),
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
      sprites: @kit.humanoid_running_sprites("assets/thug", scale=2.2, fps=10.0),
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
      sprites: @kit.humanoid_running_sprites(
        "assets/robber",
        scale=2.2,
        fps=10.0,
      ),
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
        @kit.wave_entry("zombie", 4, 0.95, spawn_tag=Some("lane2")),
        @kit.wave_entry("zombie", 4, 0.95, spawn_tag=Some("lane4")),
      ],
    },
    {
      id: 2,
      start_delay: 1.2,
      entries: [
        @kit.wave_entry("zombie", 7, 0.78, spawn_tag=Some("lane1")),
        @kit.wave_entry("conehead", 4, 1.15, spawn_tag=Some("lane5")),
      ],
    },
    {
      id: 3,
      start_delay: 1.4,
      entries: [
        @kit.wave_entry("zombie", 8, 0.72, spawn_tag=Some("lane3")),
        @kit.wave_entry("conehead", 6, 0.95, spawn_tag=Some("lane2")),
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
  ui_theme: @kit.ui_theme(
    "PLANTS VS ZOMBIES TD", "assets/shared/fonts/ThaleahFat.ttf", "ThaleahFat", "rgb(235,246,227)",
    "WASD move  LMB pea shot  SPACE shovel  ESC quit",
  ),
  hooks: None,
}

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
  map: @kit.map_def(
    [
      "####################", "#1................##", "#..TTT....,........#", "#2................##",
      "#..TTT....H........#", "#3.......P.........#", "#..TTT....,........#", "#4................##",
      "#..TTT....,........#", "#5................##", "####################",
    ],
    build_legend(),
  ),
  archetypes: [
    @kit.humanoid_archetype(
      "gardener",
      "assets/assassin",
      @topdown_platform.Chase,
      0.0,
      14,
      165.0,
      20.0,
      0,
      0,
      primary_skill_id=Some("pea_shot"),
      secondary_skill_id=Some("shovel_smash"),
      sprite_scale=2.2,
      sprite_fps=10.0,
    ),
    @kit.humanoid_archetype(
      "zombie",
      "assets/thug",
      @topdown_platform.Chase,
      0.0,
      6,
      78.0,
      19.0,
      2,
      30,
      drop_table_id=Some("sun"),
      primary_skill_id=Some("zombie_bite"),
      sprite_scale=2.2,
      sprite_fps=10.0,
    ),
    @kit.humanoid_archetype(
      "conehead",
      "assets/robber",
      @topdown_platform.HoldDistance,
      120.0,
      10,
      72.0,
      20.0,
      2,
      55,
      drop_table_id=Some("sun"),
      primary_skill_id=Some("spore_glob"),
      sprite_scale=2.2,
      sprite_fps=10.0,
    ),
  ],
  skills: [
    @kit.projectile_skill("pea_shot", 0.32, 2, 315.0, 440.0, 4.0),
    @kit.melee_skill("shovel_smash", 0.5, 4, 46.0),
    @kit.melee_skill("zombie_bite", 0.95, 2, 38.0),
    @kit.projectile_skill("spore_glob", 1.25, 2, 230.0, 260.0, 5.0),
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
    @kit.drop_table("sun", 0.46, [
      @kit.drop_item(
        "sun_small",
        "assets/top-down-summer/Top-Down Simple Summer_Prop - Bushes Small.png",
        6,
        heal=1,
        score_bonus=16,
      ),
      @kit.drop_item(
        "sun_big",
        "assets/top-down-summer/Top-Down Simple Summer_Prop - Treasure Chest.png",
        3,
        heal=2,
        score_bonus=28,
      ),
    ]),
  ],
  progression: { run_seconds: 300.0, player_archetype_id: "gardener" },
  ui_theme: @kit.ui_theme(
    "PLANTS VS ZOMBIES TD", "assets/shared/fonts/mgs1codec.ttf", "MGS1Codec", "rgb(235,246,227)",
    "WASD move  LMB pea shot  SPACE shovel  ESC quit",
  ),
  hooks: None,
}

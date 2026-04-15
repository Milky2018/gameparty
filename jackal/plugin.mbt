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
pub let plugin : @topdown_action.TopDownPluginDef = {
  meta: { id: "jackal", name: "Jackal Reloaded", version: "2.0.0" },
  map: @kit.map_def(
    [
      "####################", "#N...,,,....T....E.#", "#..####.B..####....#", "#..#..#....#..#....#",
      "#..#..#..TT.#..#...#", "#..#..#....#..#....#", "#..####....####....#", "#....W....P....S...#",
      "#..####....####....#", "#..#..#....#..#....#", "#..#..#....#..#....#", "####################",
    ],
    build_legend(),
  ),
  archetypes: [
    @kit.humanoid_archetype(
      "commando",
      "assets/assassin",
      @topdown_action.Chase,
      0.0,
      12,
      190.0,
      20.0,
      0,
      0,
      primary_skill_id=Some("rifle_burst"),
      secondary_skill_id=Some("combat_knife"),
      sprite_scale=2.35,
    ),
    @kit.humanoid_archetype(
      "scout",
      "assets/robber",
      @topdown_action.HoldDistance,
      210.0,
      4,
      135.0,
      18.0,
      1,
      40,
      drop_table_id=Some("standard"),
      primary_skill_id=Some("scout_shot"),
      sprite_scale=2.35,
    ),
    @kit.humanoid_archetype(
      "grunt",
      "assets/thug",
      @topdown_action.Chase,
      0.0,
      7,
      105.0,
      20.0,
      2,
      60,
      drop_table_id=Some("standard"),
      primary_skill_id=Some("grunt_slash"),
      sprite_scale=2.35,
    ),
    @kit.humanoid_archetype(
      "rocketeer",
      "assets/assassin",
      @topdown_action.Wander,
      0.0,
      9,
      120.0,
      20.0,
      2,
      95,
      drop_table_id=Some("elite"),
      primary_skill_id=Some("rocket_bolt"),
      sprite_scale=2.35,
    ),
  ],
  skills: [
    @kit.projectile_skill("rifle_burst", 0.24, 2, 320.0, 490.0, 4.0),
    @kit.melee_skill("combat_knife", 0.34, 3, 46.0),
    @kit.projectile_skill("scout_shot", 1.05, 1, 280.0, 350.0, 4.0),
    @kit.melee_skill("grunt_slash", 0.82, 2, 42.0),
    @kit.projectile_skill("rocket_bolt", 1.2, 3, 300.0, 300.0, 5.0),
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
    @kit.drop_table("standard", 0.42, [
      @kit.drop_item(
        "ammo_box",
        "assets/top-down-summer/Top-Down Simple Summer_Prop - Wooden Crate.png",
        6,
        score_bonus=20,
      ),
      @kit.drop_item(
        "field_kit",
        "assets/top-down-summer/Top-Down Simple Summer_Prop - Campfire.png",
        4,
        heal=2,
      ),
    ]),
    @kit.drop_table("elite", 0.68, [
      @kit.drop_item(
        "intel_case",
        "assets/top-down-summer/Top-Down Simple Summer_Prop - Treasure Chest.png",
        5,
        score_bonus=75,
      ),
      @kit.drop_item(
        "advanced_kit",
        "assets/top-down-summer/Top-Down Simple Summer_Prop - Bushes Small.png",
        3,
        heal=3,
        score_bonus=10,
      ),
    ]),
  ],
  progression: { run_seconds: 360.0, player_archetype_id: "commando" },
  ui_theme: @kit.ui_theme(
    "JACKAL RELOADED", "assets/shared/fonts/mgs1codec.ttf", "MGS1Codec", "rgb(236,245,255)",
    "WASD move  LMB fire  SPACE knife  ESC quit",
  ),
  hooks: None,
}

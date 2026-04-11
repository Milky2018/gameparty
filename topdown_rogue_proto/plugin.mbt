///|
fn build_legend() -> Map[Char, @topdown_platform.TileOrSpawnRule] {
  let legend : Map[Char, @topdown_platform.TileOrSpawnRule] = Map::new()
  let floor = @kit.summer_ground_43
  legend.set('.', @kit.floor_tile(floor))
  legend.set(',', @kit.floor_tile(floor))
  legend.set('~', @kit.floor_tile(floor))
  legend.set('P', @kit.player_spawn_tile(floor))
  legend.set('S', @kit.enemy_spawn_tile(floor, "main"))
  legend.set('N', @kit.enemy_spawn_tile(floor, "north"))
  legend.set('W', @kit.enemy_spawn_tile(floor, "west"))
  legend.set('E', @kit.enemy_spawn_tile(floor, "east"))
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
    'H',
    @kit.wall_tile(
      floor, "assets/top-down-summer/Top-Down Simple Summer_Prop - House.png",
    ),
  )
  legend
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
  map: @kit.map_def(
    [
      "####################", "#...,...,T.....,..N#", "#..####......##....#", "#..#..#..,,,..#....#",
      "#..#..#..TTT..#....#", "#..#..#........#...#", "#..####....,....W..#", "#....P....H........#",
      "#....E.......TT..S.#", "#.....,........,...#", "####################",
    ],
    build_legend(),
  ),
  archetypes: [
    @kit.humanoid_archetype(
      "player_assassin",
      "assets/assassin",
      @topdown_platform.Chase,
      0.0,
      12,
      180.0,
      20.0,
      0,
      0,
      primary_skill_id=Some("dagger_throw"),
      secondary_skill_id=Some("knife_slash"),
      sprite_scale=2.4,
    ),
    @kit.humanoid_archetype(
      "robber",
      "assets/robber",
      @topdown_platform.HoldDistance,
      190.0,
      4,
      120.0,
      18.0,
      1,
      35,
      drop_table_id=Some("common"),
      primary_skill_id=Some("robber_shot"),
      sprite_scale=2.4,
    ),
    @kit.humanoid_archetype(
      "thug",
      "assets/thug",
      @topdown_platform.Chase,
      0.0,
      6,
      90.0,
      20.0,
      2,
      55,
      drop_table_id=Some("common"),
      primary_skill_id=Some("thug_smash"),
      sprite_scale=2.4,
    ),
    @kit.humanoid_archetype(
      "assassin_elite",
      "assets/assassin",
      @topdown_platform.Wander,
      0.0,
      8,
      130.0,
      20.0,
      2,
      80,
      drop_table_id=Some("elite"),
      primary_skill_id=Some("elite_blade"),
      sprite_scale=2.4,
    ),
  ],
  skills: [
    @kit.melee_skill("knife_slash", 0.30, 2, 46.0),
    @kit.projectile_skill("dagger_throw", 0.36, 2, 300.0, 420.0, 5.0),
    @kit.projectile_skill("robber_shot", 1.15, 1, 260.0, 360.0, 4.0),
    @kit.melee_skill("thug_smash", 0.85, 2, 40.0),
    @kit.projectile_skill("elite_blade", 0.9, 2, 290.0, 420.0, 4.5),
  ],
  waves: [
    {
      id: 1,
      start_delay: 1.0,
      entries: [
        @kit.wave_entry("robber", 5, 0.7, spawn_tag=Some("north")),
        @kit.wave_entry("thug", 2, 1.0, spawn_tag=Some("west")),
      ],
    },
    {
      id: 2,
      start_delay: 1.2,
      entries: [
        @kit.wave_entry("robber", 7, 0.55, spawn_tag=Some("east")),
        @kit.wave_entry("thug", 4, 0.8, spawn_tag=Some("main")),
      ],
    },
    {
      id: 3,
      start_delay: 1.5,
      entries: [
        @kit.wave_entry("thug", 6, 0.65, spawn_tag=Some("west")),
        @kit.wave_entry("assassin_elite", 3, 1.0, spawn_tag=Some("east")),
      ],
    },
  ],
  drops: [
    @kit.drop_table("common", 0.38, [
      @kit.drop_item(
        "coin",
        "assets/top-down-summer/Top-Down Simple Summer_Prop - Treasure Chest.png",
        6,
        score_bonus=22,
      ),
      @kit.drop_item(
        "herb",
        "assets/top-down-summer/Top-Down Simple Summer_Prop - Bushes Small.png",
        4,
        heal=1,
      ),
    ]),
    @kit.drop_table("elite", 0.65, [
      @kit.drop_item(
        "big_coin",
        "assets/top-down-summer/Top-Down Simple Summer_Prop - Treasure Chest.png",
        5,
        score_bonus=60,
      ),
      @kit.drop_item(
        "camp_kit",
        "assets/top-down-summer/Top-Down Simple Summer_Prop - Campfire.png",
        3,
        heal=2,
        score_bonus=15,
      ),
    ]),
  ],
  progression: { run_seconds: 300.0, player_archetype_id: "player_assassin" },
  ui_theme: @kit.ui_theme(
    "TOPDOWN ROGUE PROTO", "assets/shared/fonts/ThaleahFat.ttf", "ThaleahFat", "rgb(226,238,252)",
    "WASD move  LMB primary  SPACE secondary  ESC quit",
  ),
  hooks: Some({
    on_run_start: Some(on_run_start),
    on_enemy_killed: Some(on_enemy_killed),
    on_pickup: Some(on_pickup),
  }),
}

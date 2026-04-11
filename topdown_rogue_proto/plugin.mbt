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
  map: {
    tile_size: 64.0,
    default_floor_image: @kit.visual(@kit.summer_ground_43),
    rows: [
      "####################", "#...,...,T.....,..N#", "#..####......##....#", "#..#..#..,,,..#....#",
      "#..#..#..TTT..#....#", "#..#..#........#...#", "#..####....,....W..#", "#....P....H........#",
      "#....E.......TT..S.#", "#.....,........,...#", "####################",
    ],
    legend: build_legend(),
  },
  archetypes: [
    {
      id: "player_assassin",
      ai_mode: @topdown_platform.Chase,
      preferred_range: 0.0,
      max_hp: 12,
      move_speed: 180.0,
      radius: 20.0,
      touch_damage: 0,
      score_value: 0,
      sprites: @kit.humanoid_running_sprites("assets/assassin", scale=2.4),
      drop_table_id: None,
      primary_skill_id: Some("dagger_throw"),
      secondary_skill_id: Some("knife_slash"),
    },
    {
      id: "robber",
      ai_mode: @topdown_platform.HoldDistance,
      preferred_range: 190.0,
      max_hp: 4,
      move_speed: 120.0,
      radius: 18.0,
      touch_damage: 1,
      score_value: 35,
      sprites: @kit.humanoid_running_sprites("assets/robber", scale=2.4),
      drop_table_id: Some("common"),
      primary_skill_id: Some("robber_shot"),
      secondary_skill_id: None,
    },
    {
      id: "thug",
      ai_mode: @topdown_platform.Chase,
      preferred_range: 0.0,
      max_hp: 6,
      move_speed: 90.0,
      radius: 20.0,
      touch_damage: 2,
      score_value: 55,
      sprites: @kit.humanoid_running_sprites("assets/thug", scale=2.4),
      drop_table_id: Some("common"),
      primary_skill_id: Some("thug_smash"),
      secondary_skill_id: None,
    },
    {
      id: "assassin_elite",
      ai_mode: @topdown_platform.Wander,
      preferred_range: 0.0,
      max_hp: 8,
      move_speed: 130.0,
      radius: 20.0,
      touch_damage: 2,
      score_value: 80,
      sprites: @kit.humanoid_running_sprites("assets/assassin", scale=2.4),
      drop_table_id: Some("elite"),
      primary_skill_id: Some("elite_blade"),
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
    {
      id: "robber_shot",
      kind: @topdown_platform.Projectile,
      cooldown: 1.15,
      damage: 1,
      range: 260.0,
      projectile_speed: 360.0,
      projectile_radius: 4.0,
    },
    {
      id: "thug_smash",
      kind: @topdown_platform.Melee,
      cooldown: 0.85,
      damage: 2,
      range: 40.0,
      projectile_speed: 0.0,
      projectile_radius: 0.0,
    },
    {
      id: "elite_blade",
      kind: @topdown_platform.Projectile,
      cooldown: 0.9,
      damage: 2,
      range: 290.0,
      projectile_speed: 420.0,
      projectile_radius: 4.5,
    },
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

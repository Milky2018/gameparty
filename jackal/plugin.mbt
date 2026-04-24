///|
fn floor() -> String {
  "assets/jackal/terrain/floor.png"
}

///|
fn blocked_floor_tile(path : String) -> @topdown_platform.TileOrSpawnRule {
  {
    kind: @topdown_platform.Wall,
    floor_image: Some(@kit.visual(path)),
    prop_image: None,
    blocks: true,
    actor_spawn_tag: None,
    point_tag: None,
  }
}

///|
fn build_legend() -> Map[Char, @topdown_platform.TileOrSpawnRule] {
  let legend : Map[Char, @topdown_platform.TileOrSpawnRule] = Map::new()
  legend.set('.', @kit.floor_tile(floor()))
  legend.set(',', @kit.floor_tile("assets/jackal/terrain/floor_alt.png"))
  legend.set('=', @kit.floor_tile("assets/jackal/terrain/bridge.png"))
  legend.set('~', blocked_floor_tile("assets/jackal/terrain/water.png"))
  legend.set(
    '#',
    @kit.wall_tile(
      floor(),
      "assets/jackal/terrain/wall.png",
      prop_scale=1.15,
      prop_y_offset=-10.0,
    ),
  )
  legend.set('P', @kit.player_spawn_tile(floor()))
  legend.set('N', @kit.enemy_spawn_tile(floor(), "north"))
  legend.set('S', @kit.enemy_spawn_tile(floor(), "south"))
  legend.set('E', @kit.enemy_spawn_tile(floor(), "east"))
  legend.set('W', @kit.enemy_spawn_tile(floor(), "west"))
  legend.set(
    'C',
    @kit.interact_tile(
      floor(),
      "camp_alpha",
      prop_path=Some("assets/jackal/objectives/camp_alpha.png"),
      prop_scale=1.0,
      prop_y_offset=-8.0,
    ),
  )
  legend.set(
    'D',
    @kit.interact_tile(
      floor(),
      "camp_bravo",
      prop_path=Some("assets/jackal/objectives/camp_bravo.png"),
      prop_scale=1.0,
      prop_y_offset=-6.0,
    ),
  )
  legend.set(
    'F',
    @kit.interact_tile(
      floor(),
      "camp_charlie",
      prop_path=Some("assets/jackal/objectives/camp_charlie.png"),
      prop_scale=1.0,
      prop_y_offset=-8.0,
    ),
  )
  legend.set(
    'G',
    @kit.interact_tile(
      floor(),
      "camp_delta",
      prop_path=Some("assets/jackal/objectives/camp_delta.png"),
      prop_scale=0.9,
      prop_y_offset=-3.0,
    ),
  )
  legend.set(
    'X',
    @kit.interact_tile(
      floor(),
      "exit_main",
      prop_path=Some("assets/jackal/objectives/exit.png"),
      prop_scale=1.0,
      prop_y_offset=-10.0,
    ),
  )
  legend
}

///|
fn stage_1_rows() -> Array[String] {
  [
    "########################", "#......................#", "#...................X..#",
    "#...........,,,,,,,,...#", "#..........N,,,,,,,,...#", "#.#####...,,,,,,,,,,...#",
    "#...,,,,,.,,,,,,,,,,...#", "#...,,,,,.,,,,,,,,,,...#", "#...,,,,,.,,,,.#######.#",
    "#...,,,,,.,,,,.........#", "#.####,,,.,,,,.........#", "#...,,,,,.,,,,.........#",
    "#...,,,,,,,,,,####.....#", "#..###,#####,,.........#", "#..#,,D,,,,,,,.######..#",
    "#..W,,,,,,,#...........#", "#..###,#####...........#", "#~~~,,,,,,,=~~~~~~~~~~~#",
    "#~~~~~~~====~~~~~~~~~~~#", "#~~~~~~~====~~~~~~~~~~~#", "#......................#",
    "#......................#", "#............####,####.#", "#............#.,,,,,.#.#",
    "#....#########.,,,,,.#.#", "#............,.,,C,,.,.#", "#............#.,,,,,.#.#",
    "#..###########.,,,,###.#", "#............####,####.#", "#..............,,,,,...#",
    "#.#########....,,,,,...#", "#,,,,,,,,,,,,,,,,,,,S,,#", "#,,,,,,,,,,,,,,,,,,,,,,#",
    "#,,,,,,,,,,,,,,,,,,,,,,#", "#,,P,,,,,,,,,,,,,,,,,,,#", "#,,,,,,,,,,,,,,,,,,,,,,#",
    "#,,,,,,,,,,,,,,,,,,,,,,#", "########################",
  ]
}

///|
fn stage_2_rows() -> Array[String] {
  [
    "####################", "#.....N......E.....#", "#..####..##..####..#", "#..#..C..##..#..#..#",
    "#..#......#..#..#..#", "#..#..####.#.#..#..#", "#..#..P....#.#..#..#", "#..#..##...#.#..#..#",
    "#..#..##...#.#..#..#", "#..#..D....#.#..#..#", "#..####....#.#..#..#", "#......####..#..#..#",
    "#..S.....F...#..#..#", "#......####..#..#..#", "#..####......#..#..#", "#......####..#..#X.#",
    "#.....W............#", "####################",
  ]
}

///|
fn stage_3_rows() -> Array[String] {
  [
    "####################", "#....N.......E.....#", "#..#####..##..###..#", "#..#...#..##..#.#..#",
    "#..#.C.#......#.#..#", "#..#...####..##.#..#", "#..###....#..#..#..#", "#....#..P.#..#..#..#",
    "#.F..#....#..#..#..#", "#....####.#..#..#..#", "#..S....#.#..#..#..#", "#..####.#.#..#..#..#",
    "#..#..D.#.#..#..#..#", "#..#....#.#..#..#..#", "#..#.####.#..#..#..#", "#..#......#..#..#X.#",
    "#....W............##", "####################",
  ]
}

///|
fn stage_4_rows() -> Array[String] {
  [
    "####################", "#..N.....##....E...#", "#..####..##..####..#", "#..#..C..##..#..#..#",
    "#..#..##....##..#..#", "#..#..##.##.##..#..#", "#..#..P..##..D..#..#", "#..####..##..####..#",
    "#......F....G......#", "#..####..##..####..#", "#..#..#..##..#..#..#", "#..#..#..##..#..#..#",
    "#..#..#..##..#..#..#", "#..#..#..##..#..#..#", "#..#..#..##..#..#..#", "#..S..#..##..#..#X.#",
    "#..W.....##........#", "####################",
  ]
}

///|
fn stage_objectives(
  rescue_tags : Array[String],
) -> Array[@topdown_action.ObjectiveDef] {
  let objectives : Array[@topdown_action.ObjectiveDef] = []
  for tag in rescue_tags {
    objectives.push({ kind: @topdown_action.RescueCamp, tag, rescue_count: 2 })
  }
  objectives.push({
    kind: @topdown_action.ExitZone,
    tag: "exit_main",
    rescue_count: 0,
  })
  objectives
}

///|
fn stage_waves_easy() -> Array[@topdown_action.WaveDef] {
  [
    {
      id: 1,
      start_delay: 0.2,
      entries: [
        @kit.wave_entry("enemy_soldier", 5, 0.70, spawn_tag=Some("north")),
        @kit.wave_entry("enemy_soldier", 4, 0.75, spawn_tag=Some("south")),
      ],
    },
    {
      id: 2,
      start_delay: 1.0,
      entries: [
        @kit.wave_entry("enemy_vehicle", 2, 1.10, spawn_tag=Some("west")),
        @kit.wave_entry("enemy_soldier", 4, 0.60, spawn_tag=Some("north")),
      ],
    },
    {
      id: 3,
      start_delay: 1.2,
      entries: [
        @kit.wave_entry("enemy_turret", 2, 1.20, spawn_tag=Some("north")),
        @kit.wave_entry("enemy_vehicle", 2, 1.05, spawn_tag=Some("west")),
      ],
    },
  ]
}

///|
fn stage_waves_mid() -> Array[@topdown_action.WaveDef] {
  [
    {
      id: 1,
      start_delay: 0.2,
      entries: [
        @kit.wave_entry("enemy_soldier", 6, 0.65, spawn_tag=Some("north")),
        @kit.wave_entry("enemy_soldier", 4, 0.65, spawn_tag=Some("east")),
      ],
    },
    {
      id: 2,
      start_delay: 0.8,
      entries: [
        @kit.wave_entry("enemy_vehicle", 3, 1.00, spawn_tag=Some("west")),
        @kit.wave_entry("enemy_turret", 2, 1.15, spawn_tag=Some("east")),
      ],
    },
    {
      id: 3,
      start_delay: 1.0,
      entries: [
        @kit.wave_entry("enemy_soldier", 5, 0.55, spawn_tag=Some("south")),
        @kit.wave_entry("enemy_vehicle", 3, 0.95, spawn_tag=Some("north")),
      ],
    },
  ]
}

///|
fn stage_waves_hard() -> Array[@topdown_action.WaveDef] {
  [
    {
      id: 1,
      start_delay: 0.2,
      entries: [
        @kit.wave_entry("enemy_soldier", 8, 0.56, spawn_tag=Some("north")),
        @kit.wave_entry("enemy_turret", 2, 1.20, spawn_tag=Some("east")),
      ],
    },
    {
      id: 2,
      start_delay: 0.9,
      entries: [
        @kit.wave_entry("enemy_vehicle", 4, 0.90, spawn_tag=Some("west")),
        @kit.wave_entry("enemy_soldier", 6, 0.50, spawn_tag=Some("south")),
      ],
    },
    {
      id: 3,
      start_delay: 1.2,
      entries: [
        @kit.wave_entry("enemy_fort", 2, 1.35, spawn_tag=Some("north")),
        @kit.wave_entry("enemy_vehicle", 3, 0.85, spawn_tag=Some("east")),
      ],
    },
  ]
}

///|
fn stage_waves_final() -> Array[@topdown_action.WaveDef] {
  [
    {
      id: 1,
      start_delay: 0.2,
      entries: [
        @kit.wave_entry("enemy_soldier", 8, 0.52, spawn_tag=Some("north")),
        @kit.wave_entry("enemy_soldier", 6, 0.52, spawn_tag=Some("east")),
      ],
    },
    {
      id: 2,
      start_delay: 0.7,
      entries: [
        @kit.wave_entry("enemy_vehicle", 5, 0.80, spawn_tag=Some("west")),
        @kit.wave_entry("enemy_turret", 4, 1.00, spawn_tag=Some("south")),
      ],
    },
    {
      id: 3,
      start_delay: 1.0,
      entries: [
        @kit.wave_entry("enemy_fort", 3, 1.20, spawn_tag=Some("north")),
        @kit.wave_entry("enemy_vehicle", 4, 0.80, spawn_tag=Some("east")),
      ],
    },
  ]
}

///|
fn map(rows : Array[String]) -> @topdown_platform.MapDef {
  @kit.map_def(rows, build_legend())
}

///|
fn campaign_stages() -> Array[@topdown_action.CampaignStageDef] {
  [
    {
      id: 1,
      title: "Delta Marsh",
      map: map(stage_1_rows()),
      waves: stage_waves_easy(),
      objectives: stage_objectives(["camp_alpha", "camp_bravo"]),
      required_rescued: 3,
    },
    {
      id: 2,
      title: "River Convoy",
      map: map(stage_2_rows()),
      waves: stage_waves_mid(),
      objectives: stage_objectives(["camp_alpha", "camp_bravo", "camp_charlie"]),
      required_rescued: 4,
    },
    {
      id: 3,
      title: "Fortress Trail",
      map: map(stage_3_rows()),
      waves: stage_waves_hard(),
      objectives: stage_objectives(["camp_alpha", "camp_bravo", "camp_charlie"]),
      required_rescued: 5,
    },
    {
      id: 4,
      title: "Last Stand",
      map: map(stage_4_rows()),
      waves: stage_waves_final(),
      objectives: stage_objectives([
        "camp_alpha", "camp_bravo", "camp_charlie", "camp_delta",
      ]),
      required_rescued: 6,
    },
  ]
}

///|
fn sprites(
  dir : String,
  scale : Double,
) -> @topdown_platform.DirectionalSprites {
  {
    up: @kit.sprite_strip(
      "\{dir}/Back - Running.png",
      scale~,
      fps=8.0,
      frame_width=32.0,
      frame_height=32.0,
      columns=4,
      frame_count=4,
    ),
    down: @kit.sprite_strip(
      "\{dir}/Front - Running.png",
      scale~,
      fps=8.0,
      frame_width=32.0,
      frame_height=32.0,
      columns=4,
      frame_count=4,
    ),
    left: @kit.sprite_strip(
      "\{dir}/Left - Running.png",
      scale~,
      fps=8.0,
      frame_width=32.0,
      frame_height=32.0,
      columns=4,
      frame_count=4,
    ),
    right: @kit.sprite_strip(
      "\{dir}/Right - Running.png",
      scale~,
      fps=8.0,
      frame_width=32.0,
      frame_height=32.0,
      columns=4,
      frame_count=4,
    ),
  }
}

///|
let plugin : @topdown_action.TopDownCampaignPluginDef = {
  meta: { id: "jackal", name: "Jackal Campaign", version: "0.4.0" },
  archetypes: [
    {
      id: "player_jeep",
      ai_mode: @topdown_action.Chase,
      preferred_range: 0.0,
      max_hp: 9,
      move_speed: 208.0,
      radius: 20.0,
      touch_damage: 0,
      score_value: 0,
      sprites: sprites("assets/jackal/jeep", 1.9),
      drop_table_id: None,
      primary_skill_id: Some("jeep_mg"),
      secondary_skill_id: Some("jeep_shell"),
    },
    {
      id: "enemy_soldier",
      ai_mode: @topdown_action.HoldDistance,
      preferred_range: 190.0,
      max_hp: 2,
      move_speed: 116.0,
      radius: 18.0,
      touch_damage: 1,
      score_value: 20,
      sprites: sprites("assets/jackal/soldier", 1.8),
      drop_table_id: None,
      primary_skill_id: Some("rifle"),
      secondary_skill_id: None,
    },
    {
      id: "enemy_turret",
      ai_mode: @topdown_action.HoldDistance,
      preferred_range: 260.0,
      max_hp: 6,
      move_speed: 0.0,
      radius: 22.0,
      touch_damage: 0,
      score_value: 42,
      sprites: sprites("assets/jackal/turret", 1.95),
      drop_table_id: None,
      primary_skill_id: Some("turret_shell"),
      secondary_skill_id: None,
    },
    {
      id: "enemy_vehicle",
      ai_mode: @topdown_action.Chase,
      preferred_range: 0.0,
      max_hp: 5,
      move_speed: 128.0,
      radius: 22.0,
      touch_damage: 2,
      score_value: 48,
      sprites: sprites("assets/jackal/vehicle", 1.95),
      drop_table_id: None,
      primary_skill_id: Some("vehicle_cannon"),
      secondary_skill_id: None,
    },
    {
      id: "enemy_fort",
      ai_mode: @topdown_action.HoldDistance,
      preferred_range: 280.0,
      max_hp: 10,
      move_speed: 0.0,
      radius: 24.0,
      touch_damage: 0,
      score_value: 100,
      sprites: sprites("assets/jackal/fort", 2.0),
      drop_table_id: None,
      primary_skill_id: Some("fortress_blast"),
      secondary_skill_id: None,
    },
  ],
  skills: [
    @kit.projectile_skill("jeep_mg", 0.14, 1, 360.0, 560.0, 4.0),
    @kit.projectile_skill("jeep_shell", 0.66, 4, 430.0, 470.0, 6.0),
    @kit.projectile_skill("rifle", 1.05, 1, 320.0, 420.0, 4.0),
    @kit.projectile_skill("turret_shell", 1.35, 2, 360.0, 380.0, 5.0),
    @kit.projectile_skill("vehicle_cannon", 1.05, 2, 330.0, 430.0, 5.0),
    @kit.projectile_skill("fortress_blast", 1.40, 3, 390.0, 360.0, 6.0),
  ],
  drops: [],
  player_archetype_id: "player_jeep",
  campaign: {
    stages: campaign_stages(),
    lives: 3,
    intro_seconds: 1.0,
    clear_seconds: 1.2,
  },
  follower: { spacing_steps: 7, radius: 7.0, sprite_scale: 1.0 },
  ui_theme: @kit.ui_theme(
    "JACKAL", "assets/shared/fonts/mgs1codec.ttf", "MGS1Codec", "rgb(226,238,252)",
    "WASD/ARROWS MOVE  LMB FIRE  SPACE HEAVY  ENTER CONFIRM  ESC MENU",
  ),
  hooks: None,
}

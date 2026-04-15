///|
fn build_legend() -> Map[Char, @topdown_platform.TileOrSpawnRule] {
  let legend : Map[Char, @topdown_platform.TileOrSpawnRule] = Map::new()
  let floor = @kit.summer_ground_43
  legend.set('.', @kit.floor_tile(floor))
  legend.set('P', @kit.player_spawn_tile(floor))
  legend.set('A', @kit.actor_spawn_tile(floor, "guide"))
  legend.set('B', @kit.actor_spawn_tile(floor, "merchant"))
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
fn phase_name(phase : @topdown_dialogue.RunPhase) -> String {
  match phase {
    @topdown_dialogue.Boot => "Boot"
    @topdown_dialogue.Playing => "Playing"
    @topdown_dialogue.Dialogue => "Dialogue"
  }
}

///|
fn on_run_start(snapshot : @topdown_dialogue.PluginRuntimeState) -> Unit {
  println(
    "[topdown_dialogue_proto] started phase=\{phase_name(snapshot.phase)} npcs=\{snapshot.npc_count}",
  )
}

///|
fn on_dialogue_started(
  snapshot : @topdown_dialogue.PluginRuntimeState,
  npc_id : String,
  dialogue_id : String,
) -> Unit {
  println(
    "[topdown_dialogue_proto] talk start npc=\{npc_id} dialogue=\{dialogue_id} line=\{snapshot.active_line_index}",
  )
}

///|
fn on_dialogue_finished(
  _snapshot : @topdown_dialogue.PluginRuntimeState,
  npc_id : String,
  dialogue_id : String,
) -> Unit {
  println(
    "[topdown_dialogue_proto] talk end npc=\{npc_id} dialogue=\{dialogue_id}",
  )
}

///|
pub let plugin : @topdown_dialogue.TopDownPluginDef = {
  meta: {
    id: "topdown_dialogue_proto",
    name: "TopDown Dialogue Proto",
    version: "0.1.0",
  },
  map: @kit.map_def(
    [
      "####################", "#.....T......T.....#", "#..A......H.....B..#", "#..................#",
      "#....T.....P.......#", "#..................#", "#.....T........T...#", "####################",
    ],
    build_legend(),
  ),
  player_archetype_id: "traveler",
  archetypes: [
    @kit.humanoid_archetype(
      "traveler",
      "assets/assassin",
      170.0,
      20.0,
      sprite_scale=2.4,
    ),
    @kit.humanoid_archetype(
      "guide",
      "assets/robber",
      0.0,
      18.0,
      sprite_scale=2.4,
    ),
    @kit.humanoid_archetype(
      "merchant",
      "assets/thug",
      0.0,
      20.0,
      sprite_scale=2.4,
    ),
  ],
  npcs: [
    {
      id: "guide",
      archetype_id: "guide",
      spawn_tag: "guide",
      facing: @topdown_platform.Down,
      display_name: "Guide",
      dialogue_id: "welcome",
    },
    {
      id: "merchant",
      archetype_id: "merchant",
      spawn_tag: "merchant",
      facing: @topdown_platform.Left,
      display_name: "Merchant",
      dialogue_id: "shop_hint",
    },
  ],
  dialogues: [
    {
      id: "welcome",
      lines: [
        {
          speaker: "Guide",
          text: "This prototype proves topdown and dialogue can compose cleanly.",
        },
        {
          speaker: "Guide",
          text: "Movement, walls, and map parsing stay in topdown core.",
        },
        {
          speaker: "Guide",
          text: "Only dialogue-specific state lives in this package.",
        },
      ],
    },
    {
      id: "shop_hint",
      lines: [
        {
          speaker: "Merchant",
          text: "No combat here. This is the dialogue layer only.",
        },
        {
          speaker: "Merchant",
          text: "Next step can be quests, shops, or a full topdown RPG.",
        },
      ],
    },
  ],
  settings: {
    interaction_radius: 92.0,
    interact_prompt: "E TALK",
    advance_hint: "SPACE next  ESC close",
  },
  ui_theme: @kit.ui_theme(
    "TOPDOWN DIALOGUE PROTO", "assets/shared/fonts/mgs1codec.ttf", "MGS1Codec", "rgb(226,238,252)",
    "WASD move  E talk  ESC quit",
  ),
  dialogue_theme: {
    prompt_color_css: "rgb(255,212,120)",
    speaker_color_css: "rgb(255,244,166)",
    text_color_css: "rgb(236,240,250)",
    hint_color_css: "rgb(180,210,255)",
    panel_color: { r: 21U, g: 26U, b: 38U, a: 0.92 },
  },
  hooks: Some({
    on_run_start: Some(on_run_start),
    on_dialogue_started: Some(on_dialogue_started),
    on_dialogue_finished: Some(on_dialogue_finished),
  }),
}

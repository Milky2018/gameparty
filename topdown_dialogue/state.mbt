///|
const VIEWPORT_WIDTH : Double = 1280.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const CAPTURE_ENV : String = "TOPDOWN_DIALOGUE_CAPTURE"

///|
const CAPTURE_DELAY_SECONDS : Double = 2.5

///|
const CAPTURE_PATH : String = "topdown_dialogue_capture.png"

///|
const PROFILE_ENV : String = "TOPDOWN_DIALOGUE_PROFILE"

///|
const HUD_Z : Double = 420.0

///|
const TILE_Z : Double = 5.0

///|
const PROP_Z : Double = 18.0

///|
const PLAYER_Z : Double = 28.0

///|
const NPC_Z : Double = 26.0

///|
const DIALOGUE_PANEL_Z : Double = 410.0

///|
const WALL_PADDING : Double = 3.0

///|
let asset_path_prefixes : Array[String] = ["", "../", "../../", "../../../"]

///|
priv struct WorldTile {
  floor_entity : @entity.Entity
  prop_entity : @entity.Entity?
}

///|
priv struct PlayerRuntime {
  entity : @entity.Entity
  archetype_id : String
  mut position : @math.Vec2
  mut facing : @topdown_platform.Facing
  mut moving : Bool
  mut anim_elapsed : Double
  mut last_sprite_path : String
}

///|
priv struct NpcRuntime {
  entity : @entity.Entity
  id : String
  archetype_id : String
  display_name : String
  dialogue_id : String
  position : @math.Vec2
  facing : @topdown_platform.Facing
  mut moving : Bool
  mut anim_elapsed : Double
  mut last_sprite_path : String
}

///|
pub struct RunState {
  mut phase : RunPhase
  mut elapsed : Double
}

///|
pub struct WorldState {
  mut tile_size : Double
  mut rows : Int
  mut cols : Int
  mut world_width : Double
  mut world_height : Double
  mut player_spawn : @math.Vec2
  npc_spawns : Array[@topdown_platform.ActorSpawnPoint]
  blocking_rects : Array[@math.Rect]
}

///|
pub struct InputState {
  mut move_intent : @math.Vec2
}

///|
pub struct DialogueState {
  mut active_npc_id : String?
  mut active_dialogue_id : String?
  mut line_index : Int
}

///|
pub struct UiState {
  mut title_text : String
  mut hud_text : String
  mut message_text : String
  mut speaker_text : String
  mut dialogue_text : String
  mut dialogue_hint_text : String
}

///|
pub struct PluginRuntimeStateResource {
  mut snapshot : PluginRuntimeState
}

///|
let run_state : RunState = { phase: Boot, elapsed: 0.0 }

///|
let world_state : WorldState = {
  tile_size: 64.0,
  rows: 0,
  cols: 0,
  world_width: 0.0,
  world_height: 0.0,
  player_spawn: @math.Vec2(64.0, 64.0),
  npc_spawns: [],
  blocking_rects: [],
}

///|
let input_state : InputState = { move_intent: @math.Vec2(0.0, 0.0) }

///|
let dialogue_state : DialogueState = {
  active_npc_id: None,
  active_dialogue_id: None,
  line_index: 0,
}

///|
let ui_state : UiState = {
  title_text: "",
  hud_text: "",
  message_text: "",
  speaker_text: "",
  dialogue_text: "",
  dialogue_hint_text: "",
}

///|
let plugin_runtime_state : PluginRuntimeStateResource = {
  snapshot: {
    phase: Boot,
    player_cell_x: 0,
    player_cell_y: 0,
    npc_count: 0,
    active_npc_id: None,
    active_dialogue_id: None,
    active_line_index: 0,
  },
}

///|
let active_plugin : Ref[TopDownPluginDef?] = { val: None }

///|
let player_runtime : Ref[PlayerRuntime?] = { val: None }

///|
let npc_runtimes : Array[NpcRuntime] = []

///|
let world_tiles : Array[WorldTile] = []

///|
let dynamic_entities : Array[@entity.Entity] = []

///|
let image_cache : Map[String, @asset.ImageHandle] = Map::new()

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_entity : @entity.Entity = @entity.Entity::new()

///|
let message_entity : @entity.Entity = @entity.Entity::new()

///|
let world_bg_entity : @entity.Entity = @entity.Entity::new()

///|
let dialogue_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let dialogue_speaker_entity : @entity.Entity = @entity.Entity::new()

///|
let dialogue_body_entity : @entity.Entity = @entity.Entity::new()

///|
let dialogue_hint_entity : @entity.Entity = @entity.Entity::new()

///|
let topdown_font_registered : Ref[Bool] = { val: false }

///|
let title_cache : Ref[String] = { val: "" }

///|
let hud_cache : Ref[String] = { val: "" }

///|
let message_cache : Ref[String] = { val: "" }

///|
let speaker_cache : Ref[String] = { val: "" }

///|
let body_cache : Ref[String] = { val: "" }

///|
let hint_cache : Ref[String] = { val: "" }

///|
let debug_overlay_enabled : Ref[Bool] = { val: false }

///|
let capture_done : Ref[Bool] = { val: false }

///|
let capture_timer : Ref[Double] = { val: 0.0 }

///|
fn env_flag_enabled(name : String) -> Bool {
  match @env.get_env_var(name) {
    Some(value) => {
      let normalized = value.to_lower()
      normalized == "1" ||
      normalized == "true" ||
      normalized == "yes" ||
      normalized == "on"
    }
    None => false
  }
}

///|
fn phase_name(phase : RunPhase) -> String {
  match phase {
    Boot => "Boot"
    Playing => "Playing"
    Dialogue => "Dialogue"
  }
}

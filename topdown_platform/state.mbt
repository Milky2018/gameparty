///|
const VIEWPORT_WIDTH : Double = 1280.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const CAPTURE_ENV : String = "TOPDOWN_PLATFORM_CAPTURE"

///|
const CAPTURE_DELAY_SECONDS : Double = 2.5

///|
const CAPTURE_PATH : String = "topdown_platform_capture.png"

///|
const PROFILE_ENV : String = "TOPDOWN_PLATFORM_PROFILE"

///|
const HUD_Z : Double = 420.0

///|
const TILE_Z : Double = 5.0

///|
const PROP_Z : Double = 18.0

///|
const PLAYER_Z : Double = 28.0

///|
const ACTOR_Z : Double = 26.0

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
priv struct ActorRuntime {
  entity : @entity.Entity
  archetype_id : String
  mut position : @math.Vec2
  mut facing : Facing
  mut moving : Bool
  mut anim_elapsed : Double
  mut last_sprite_path : String
}

///|
pub struct ActorSpawnPoint {
  position : @math.Vec2
  tag : String?
}

///|
pub struct RunState {
  mut phase : RunPhase
  mut elapsed : Double
  mut status_message : String
}

///|
pub struct WorldState {
  mut tile_size : Double
  mut rows : Int
  mut cols : Int
  mut world_width : Double
  mut world_height : Double
  mut player_spawn : @math.Vec2
  actor_spawns : Array[ActorSpawnPoint]
  blocking_rects : Array[@math.Rect]
}

///|
pub struct InputState {
  mut move_intent : @math.Vec2
}

///|
pub struct UiState {
  mut title_text : String
  mut hud_text : String
  mut message_text : String
}

///|
pub struct PluginRuntimeStateResource {
  mut snapshot : PluginRuntimeState
}

///|
let run_state : RunState = { phase: Boot, elapsed: 0.0, status_message: "" }

///|
let world_state : WorldState = {
  tile_size: 64.0,
  rows: 0,
  cols: 0,
  world_width: 0.0,
  world_height: 0.0,
  player_spawn: @math.Vec2(64.0, 64.0),
  actor_spawns: [],
  blocking_rects: [],
}

///|
let input_state : InputState = { move_intent: @math.Vec2(0.0, 0.0) }

///|
let ui_state : UiState = { title_text: "", hud_text: "", message_text: "" }

///|
let plugin_runtime_state : PluginRuntimeStateResource = {
  snapshot: { phase: Boot, player_cell_x: 0, player_cell_y: 0, actor_count: 0 },
}

///|
let active_plugin : Ref[TopDownPluginDef?] = { val: None }

///|
let player_runtime : Ref[ActorRuntime?] = { val: None }

///|
let actor_runtimes : Array[ActorRuntime] = []

///|
let world_tiles : Array[WorldTile] = []

///|
let dynamic_entities : Array[@entity.Entity] = []

///|
let image_cache : Map[String, @asset.ImageHandle] = Map::new()

///|
let title_entity : @entity.Entity = @entity.Entity::Entity()

///|
let hud_entity : @entity.Entity = @entity.Entity::Entity()

///|
let message_entity : @entity.Entity = @entity.Entity::Entity()

///|
let world_bg_entity : @entity.Entity = @entity.Entity::Entity()

///|
let topdown_font_registered : Ref[Bool] = { val: false }

///|
let capture_done : Ref[Bool] = { val: false }

///|
let capture_timer : Ref[Double] = { val: 0.0 }

///|
pub fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
pub fn transform_xy(x : Double, y : Double, z : Double) -> @transform.Transform {
  @transform.Transform::from_xyz(x, y, z)
}

///|
pub fn set_entity_visible(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
pub fn clamp_double(value : Double, min_ : Double, max_ : Double) -> Double {
  if value < min_ {
    min_
  } else if value > max_ {
    max_
  } else {
    value
  }
}

///|
pub fn vec_length(value : @math.Vec2) -> Double {
  (value[X] * value[X] + value[Y] * value[Y]).sqrt()
}

///|
pub fn vec_normalize(value : @math.Vec2) -> @math.Vec2 {
  let len = vec_length(value)
  if len <= 0.000001 {
    @math.Vec2(0.0, 0.0)
  } else {
    value.scalar_div(len)
  }
}

///|
pub fn rect_intersects_circle(
  rect : @math.Rect,
  center : @math.Vec2,
  radius : Double,
) -> Bool {
  let rect_x = rect.position[X]
  let rect_y = rect.position[Y]
  let rect_w = rect.size[X]
  let rect_h = rect.size[Y]
  let nearest_x = clamp_double(center[X], rect_x, rect_x + rect_w)
  let nearest_y = clamp_double(center[Y], rect_y, rect_y + rect_h)
  let dx = center[X] - nearest_x
  let dy = center[Y] - nearest_y
  dx * dx + dy * dy <= radius * radius
}

///|
pub fn facing_from_vector(vector : @math.Vec2, current : Facing) -> Facing {
  let ax = vector[X].abs()
  let ay = vector[Y].abs()
  if ax < 0.001 && ay < 0.001 {
    current
  } else if ax > ay * 2.25 {
    if vector[X] >= 0.0 {
      Right
    } else {
      Left
    }
  } else if ay > ax * 2.25 {
    if vector[Y] >= 0.0 {
      Down
    } else {
      Up
    }
  } else if vector[X] >= 0.0 && vector[Y] < 0.0 {
    UpRight
  } else if vector[X] >= 0.0 && vector[Y] >= 0.0 {
    DownRight
  } else if vector[X] < 0.0 && vector[Y] >= 0.0 {
    DownLeft
  } else {
    UpLeft
  }
}

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
  }
}

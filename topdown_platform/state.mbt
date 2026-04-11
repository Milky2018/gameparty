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
const ENEMY_Z : Double = 26.0

///|
const PICKUP_Z : Double = 24.0

///|
const PROJECTILE_Z : Double = 30.0

///|
const ATTACK_FLASH_SECONDS : Double = 0.08

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
  mut hp : Int
  mut position : @math.Vec2D
  mut facing : Facing
  mut attack_cd : Double
  mut moving : Bool
  mut anim_elapsed : Double
  mut last_sprite_path : String
  mut ai_wander_dir : @math.Vec2D
  mut ai_wander_timer : Double
}

///|
priv struct ProjectileRuntime {
  entity : @entity.Entity
  owner_enemy : Bool
  mut position : @math.Vec2D
  velocity : @math.Vec2D
  radius : Double
  damage : Int
  mut ttl : Double
}

///|
priv struct PickupRuntime {
  entity : @entity.Entity
  item_id : String
  position : @math.Vec2D
  radius : Double
  heal : Int
  score_bonus : Int
}

///|
pub struct SpawnCursor {
  mut wave_index : Int
  mut entry_index : Int
  mut spawned_in_entry : Int
  mut wait_timer : Double
  mut wave_started : Bool
  mut all_spawned : Bool
}

///|
pub struct EnemySpawnPoint {
  position : @math.Vec2D
  tag : String?
}

///|
pub struct RunState {
  mut phase : RunPhase
  mut elapsed : Double
  mut time_left : Double
  mut score : Int
  mut enemies_killed : Int
  mut pickups_collected : Int
  mut status_message : String
}

///|
pub struct WorldState {
  mut tile_size : Double
  mut rows : Int
  mut cols : Int
  mut world_width : Double
  mut world_height : Double
  mut player_spawn : @math.Vec2D
  enemy_spawns : Array[EnemySpawnPoint]
  blocking_rects : Array[@math.Rect]
}

///|
pub struct CombatState {
  mut move_intent : @math.Vec2D
  mut primary_requested : Bool
  mut secondary_requested : Bool
  mut attack_flash_ttl : Double
}

///|
pub struct SpawnState {
  mut cursor : SpawnCursor
}

///|
pub struct LootState {
  mut live_pickups : Int
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
let run_state : RunState = {
  phase: Boot,
  elapsed: 0.0,
  time_left: 0.0,
  score: 0,
  enemies_killed: 0,
  pickups_collected: 0,
  status_message: "",
}

///|
let world_state : WorldState = {
  tile_size: 64.0,
  rows: 0,
  cols: 0,
  world_width: 0.0,
  world_height: 0.0,
  player_spawn: @math.Vec2D(64.0, 64.0),
  enemy_spawns: [],
  blocking_rects: [],
}

///|
let combat_state : CombatState = {
  move_intent: @math.Vec2D(0.0, 0.0),
  primary_requested: false,
  secondary_requested: false,
  attack_flash_ttl: 0.0,
}

///|
let spawn_state : SpawnState = {
  cursor: {
    wave_index: 0,
    entry_index: 0,
    spawned_in_entry: 0,
    wait_timer: 0.0,
    wave_started: false,
    all_spawned: false,
  },
}

///|
let loot_state : LootState = { live_pickups: 0 }

///|
let ui_state : UiState = { title_text: "", hud_text: "", message_text: "" }

///|
let plugin_runtime_state : PluginRuntimeStateResource = {
  snapshot: {
    phase: Boot,
    score: 0,
    player_hp: 0,
    player_hp_max: 0,
    wave: 0,
    waves_total: 0,
    time_left: 0.0,
    enemies_alive: 0,
    enemies_killed: 0,
    pickups_collected: 0,
  },
}

///|
let active_plugin : Ref[TopDownPluginDef?] = { val: None }

///|
let player_runtime : Ref[ActorRuntime?] = { val: None }

///|
let enemy_runtimes : Array[ActorRuntime] = []

///|
let projectile_runtimes : Array[ProjectileRuntime] = []

///|
let pickup_runtimes : Array[PickupRuntime] = []

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
let attack_flash_entity : @entity.Entity = @entity.Entity::new()

///|
let world_bg_entity : @entity.Entity = @entity.Entity::new()

///|
let topdown_font_registered : Ref[Bool] = { val: false }

///|
let capture_done : Ref[Bool] = { val: false }

///|
let capture_timer : Ref[Double] = { val: 0.0 }

///|
let rand : @random.Rand = @random.Rand::new()

///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
fn transform_xy(x : Double, y : Double, z : Double) -> @transform.Transform {
  @transform.Transform::from_xyz(x, y, z)
}

///|
fn set_entity_visible(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn clamp_double(value : Double, min_ : Double, max_ : Double) -> Double {
  if value < min_ {
    min_
  } else if value > max_ {
    max_
  } else {
    value
  }
}

///|
fn vec_length(value : @math.Vec2D) -> Double {
  (value[X] * value[X] + value[Y] * value[Y]).sqrt()
}

///|
fn vec_normalize(value : @math.Vec2D) -> @math.Vec2D {
  let len = vec_length(value)
  if len <= 0.000001 {
    @math.Vec2D(0.0, 0.0)
  } else {
    value.scalar_div(len)
  }
}

///|
fn circle_intersects_circle(
  a_center : @math.Vec2D,
  a_radius : Double,
  b_center : @math.Vec2D,
  b_radius : Double,
) -> Bool {
  let dx = a_center[X] - b_center[X]
  let dy = a_center[Y] - b_center[Y]
  let radius = a_radius + b_radius
  dx * dx + dy * dy <= radius * radius
}

///|
fn rect_intersects_circle(
  rect : @math.Rect,
  center : @math.Vec2D,
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
fn facing_from_vector(vector : @math.Vec2D, current : Facing) -> Facing {
  let ax = vector[X].abs()
  let ay = vector[Y].abs()
  if ax < 0.001 && ay < 0.001 {
    current
  } else if ax >= ay {
    if vector[X] >= 0.0 {
      Right
    } else {
      Left
    }
  } else if vector[Y] >= 0.0 {
    Down
  } else {
    Up
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
    Won => "Won"
    Lost => "Lost"
  }
}

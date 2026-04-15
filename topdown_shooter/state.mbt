///|
const VIEWPORT_WIDTH : Double = 1280.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const HUD_Z : Double = 220.0

///|
const WORLD_BG_Z : Double = 0.0

///|
const TILE_Z : Double = 10.0

///|
const TILE_OVERLAY_Z : Double = 12.0

///|
const PICKUP_Z : Double = 28.0

///|
const ACTOR_Z : Double = 34.0

///|
const BARREL_Z : Double = 36.0

///|
const PROJECTILE_Z : Double = 44.0

///|
const WORLD_TOP_MARGIN : Double = 108.0

///|
const WORLD_BOTTOM_MARGIN : Double = 52.0

///|
const WALL_PADDING : Double = 2.0

///|
const CAPTURE_ENV : String = "TOPDOWN_SHOOTER_CAPTURE"

///|
const CAPTURE_PATH : String = "topdown_shooter_capture.png"

///|
const CAPTURE_DELAY_SECONDS : Double = 2.0

///|
let asset_path_prefixes : Array[String] = ["", "../", "../../", "../../../"]

///|
let circle_mesh_handles : Map[Int, @mesh2d.Mesh2dHandle] = Map::new()

///|
let circle_material_handles : Map[String, @material2d.ColorMaterialHandle] = Map::new()

///|
priv struct WorldTile {
  floor_entity : @entity.Entity
  overlay_entity : @entity.Entity?
}

///|
priv struct SpawnPoint {
  center : @math.Vec2
  tag : String?
}

///|
priv struct PickupMarker {
  center : @math.Vec2
  pickup_id : String
}

///|
priv struct ActorRuntime {
  id : Int
  body_entity : @entity.Entity
  barrel_entity : @entity.Entity
  archetype_id : String
  mut weapon_id : String
  is_player : Bool
  bot_profile_id : String?
  mut alive : Bool
  mut hp : Int
  mut center : @math.Vec2
  mut aim_dir : @math.Vec2
  mut fire_cooldown : Double
  mut invuln_ttl : Double
  mut respawn_ttl : Double
  mut ammo_in_magazine : Int
  mut reserve_ammo : Int
  mut wander_dir : @math.Vec2
  mut wander_ttl : Double
  mut strafe_sign : Double
}

///|
priv struct PickupRuntime {
  entity : @entity.Entity
  spawn_id : String
  center : @math.Vec2
  radius : Double
  color : @render.Color
  mut active : Bool
  mut respawn_ttl : Double
}

///|
priv struct ProjectileRuntime {
  entity : @entity.Entity
  owner_actor_id : Int
  mut center : @math.Vec2
  velocity : @math.Vec2
  radius : Double
  damage : Int
  color : @render.Color
  mut ttl : Double
}

///|
pub struct MatchState {
  mut phase : MatchPhase
  mut elapsed : Double
  mut time_left : Double
  mut score : Int
  mut kills : Int
  mut deaths : Int
  mut current_streak : Int
  mut best_streak : Int
  mut best_score : Int
  mut status_message : String
}

///|
priv struct ShooterWorldState {
  mut tile_size : Double
  mut rows : Int
  mut cols : Int
  mut world_width : Double
  mut world_height : Double
  mut origin : @math.Vec2
  player_spawns : Array[SpawnPoint]
  bot_spawns : Array[SpawnPoint]
  wall_rects : Array[@math.Rect]
  pickup_markers : Array[PickupMarker]
}

///|
pub struct UiState {
  mut title_text : String
  mut hud_text : String
  mut message_text : String
}

///|
pub struct InputState {
  mut move_intent : @math.Vec2
  mut fire_requested : Bool
}

///|
let match_state : MatchState = {
  phase: Boot,
  elapsed: 0.0,
  time_left: 0.0,
  score: 0,
  kills: 0,
  deaths: 0,
  current_streak: 0,
  best_streak: 0,
  best_score: 0,
  status_message: "",
}

///|
let world_state : ShooterWorldState = {
  tile_size: 48.0,
  rows: 0,
  cols: 0,
  world_width: 0.0,
  world_height: 0.0,
  origin: @math.Vec2(0.0, 0.0),
  player_spawns: [],
  bot_spawns: [],
  wall_rects: [],
  pickup_markers: [],
}

///|
let ui_state : UiState = { title_text: "", hud_text: "", message_text: "" }

///|
let input_state : InputState = {
  move_intent: @math.Vec2(0.0, 0.0),
  fire_requested: false,
}

///|
let active_plugin : Ref[TopDownShooterPluginDef?] = { val: None }

///|
let world_tiles : Array[WorldTile] = []

///|
let dynamic_entities : Array[@entity.Entity] = []

///|
let player_runtime : Ref[ActorRuntime?] = { val: None }

///|
let bot_runtimes : Array[ActorRuntime] = []

///|
let pickup_runtimes : Array[PickupRuntime] = []

///|
let projectile_runtimes : Array[ProjectileRuntime] = []

///|
let next_actor_id : Ref[Int] = { val: 1 }

///|
let shooter_font_registered : Ref[Bool] = { val: false }

///|
let capture_done : Ref[Bool] = { val: false }

///|
let capture_timer : Ref[Double] = { val: 0.0 }

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_entity : @entity.Entity = @entity.Entity::new()

///|
let message_entity : @entity.Entity = @entity.Entity::new()

///|
let world_bg_entity : @entity.Entity = @entity.Entity::new()

///|
let top_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let bottom_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let title_cache : Ref[String] = { val: "" }

///|
let hud_cache : Ref[String] = { val: "" }

///|
let message_cache : Ref[String] = { val: "" }

///|
let rand : @random.Rand = @random.Rand::new()

///|
fn active_plugin_def() -> TopDownShooterPluginDef {
  match active_plugin.val {
    Some(plugin) => plugin
    None => abort("topdown_shooter: no active plugin configured")
  }
}

///|
fn rgba(r : UInt, g : UInt, b : UInt, a? : Double = 1.0) -> @render.Color {
  { r, g, b, a }
}

///|
fn color_material_key(color : @render.Color) -> String {
  let alpha = @cmath.round(color.a * 255.0).to_int()
  "\{color.r},\{color.g},\{color.b},\{alpha}"
}

///|
fn circle_mesh_handle(radius : Double) -> @mesh2d.Mesh2dHandle {
  let key = @cmath.round(radius * 1000.0).to_int()
  circle_mesh_handles.get_or_init(key, fn() { @mesh2d.circle(radius) })
}

///|
fn circle_material_handle(color : @render.Color) -> @material2d.ColorMaterialHandle {
  let key = color_material_key(color)
  circle_material_handles.get_or_init(key, fn() {
    @material2d.register_color_material(
      @material2d.ColorMaterial::from_color(color),
    )
  })
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
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
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
fn vec_length(value : @math.Vec2) -> Double {
  (value[X] * value[X] + value[Y] * value[Y]).sqrt()
}

///|
fn vec_normalize(value : @math.Vec2) -> @math.Vec2 {
  let len = vec_length(value)
  if len <= 0.000001 {
    @math.Vec2(0.0, 0.0)
  } else {
    value.scalar_div(len)
  }
}

///|
fn vec_perp(value : @math.Vec2) -> @math.Vec2 {
  @math.Vec2(-value[Y], value[X])
}

///|
fn rotate_vector(value : @math.Vec2, radians : Double) -> @math.Vec2 {
  let cos_v = @cmath.cos(radians)
  let sin_v = @cmath.sin(radians)
  @math.Vec2(
    value[X] * cos_v - value[Y] * sin_v,
    value[X] * sin_v + value[Y] * cos_v,
  )
}

///|
fn circle_intersects_circle(
  a_center : @math.Vec2,
  a_radius : Double,
  b_center : @math.Vec2,
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
fn line_blocked(
  rects : Array[@math.Rect],
  start : @math.Vec2,
  end_ : @math.Vec2,
) -> Bool {
  let delta = end_ - start
  let distance = vec_length(delta)
  if distance <= 4.0 {
    return false
  }
  let dir = vec_normalize(delta)
  let steps = (distance / 8.0).to_int().max(1)
  for i = 1; i < steps; i = i + 1 {
    let point = start + dir.scalar_mul(i.to_double() * 8.0)
    for rect in rects {
      if rect_intersects_circle(rect, point, 2.5) {
        return true
      }
    }
  }
  false
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
fn resolved_asset_path(path : String) -> String {
  for prefix in asset_path_prefixes {
    let candidate = "\{prefix}\{path}"
    if @asset.read_bytes(candidate) is Some(_) {
      return candidate
    }
  }
  path
}

///|

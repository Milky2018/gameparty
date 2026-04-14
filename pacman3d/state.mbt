///|
const VIEWPORT_WIDTH : Double = 480.0

///|
const VIEWPORT_HEIGHT : Double = 360.0

///|
const FPS : UInt = 60

///|
const TILE_WORLD_SIZE : Double = 2.0

///|
const WALL_HEIGHT : Double = 2.0

///|
const FLOOR_THICKNESS : Double = 0.08

///|
const DOT_RADIUS : Double = 0.125

///|
const GHOST_RADIUS : Double = 0.625

///|
const GHOST_BODY_RADIUS : Double = 0.45

///|
const GHOST_BODY_HEIGHT : Double = GHOST_RADIUS * 2.0

///|
const GHOST_EYE_RADIUS : Double = 0.1

///|
const GHOST_EYE_FORWARD_OFFSET : Double = 0.41

///|
const GHOST_EYE_SIDE_OFFSET : Double = 0.16

///|
const GHOST_EYE_HEIGHT_OFFSET : Double = GHOST_BODY_HEIGHT / 2.0 +
  GHOST_EYE_RADIUS +
  0.06

///|
const PLAYER_RADIUS : Double = 0.625

///|
const PLAYER_HEIGHT : Double = 1.0

///|
const PLAYER_SPEED : Double = 3.75

///|
const PLAYER_TURN_SENSITIVITY : Double = 0.0022

///|
const DOT_PICKUP_RADIUS : Double = 0.625

///|
const BASE_GHOST_SPEED : Double = 3.0

///|
const GHOST_LEVEL_SPEED_BONUS : Double = 0.5625

///|
const MAP_FLOOR_Y : Double = -FLOOR_THICKNESS / 2.0

///|
const MAP_CEILING_Y : Double = WALL_HEIGHT + FLOOR_THICKNESS / 2.0

///|
const MAP_DOT_Y : Double = 0.14

///|
const MAP_GHOST_Y : Double = GHOST_RADIUS

///|
const WALL_HALF_HEIGHT_Y : Double = WALL_HEIGHT / 2.0

///|
const MINIMAP_OFFSET_X : Double = 10.0

///|
const MINIMAP_OFFSET_Y : Double = 10.0

///|
const MINIMAP_CELL_SIZE : Double = 6.0

///|
const MINIMAP_DOT_SIZE : Double = 4.0

///|
const MINIMAP_MARKER_SIZE : Double = 4.0

///|
const WORLD_CLEAR_COLOR_R : UInt = 4U

///|
const WORLD_CLEAR_COLOR_G : UInt = 5U

///|
const WORLD_CLEAR_COLOR_B : UInt = 8U

///|
const AMBIENT_LIGHT_INTENSITY : Double = 0.06

///|
const DIRECTIONAL_LIGHT_INTENSITY : Double = 0.12

///|
const PLAYER_LIGHT_INTENSITY : Double = 0.9

///|
const PLAYER_LIGHT_RANGE : Double = 7.0

///|
const DOT_LIGHT_INTENSITY : Double = 0.28

///|
const DOT_LIGHT_RANGE : Double = 1.15

///|
const GHOST_POINT_LIGHT_INTENSITY : Double = 0.34

///|
const GHOST_POINT_LIGHT_RANGE : Double = 3.45

///|
const GHOST_SPOT_LIGHT_INTENSITY : Double = 2.6

///|
const GHOST_SPOT_LIGHT_RANGE : Double = 15.4

///|
const GHOST_SPOT_LIGHT_INNER_ANGLE : Double = 0.45

///|
const GHOST_SPOT_LIGHT_OUTER_ANGLE : Double = 2.52

///|
const GHOST_SPOT_LIGHT_FORWARD_OFFSET : Double = 0.32

///|
const GHOST_SPOT_LIGHT_HEIGHT_OFFSET : Double = 0.36

///|
const GHOST_SPOT_LIGHT_DOWNWARD : Double = 0.55

///|
const GHOST_SPOT_DEBUG_RAY_LENGTH : Double = 6.0

///|
const GHOST_SPOT_DEBUG_RAY_THICKNESS : Double = 0.12

///|
const GHOST_BOB_AMPLITUDE : Double = 0.14

///|
const GHOST_BOB_FREQUENCY_PER_SPEED : Double = 2.1

///|
type Level = ReadOnlyArray[ReadOnlyArray[Int]]

///|
priv enum Direction {
  Up
  Down
  Left
  Right
}

///|
priv enum GhostType {
  Fast
  Normal
  Slow
}

///|
priv struct PlayerState {
  mut x : Double
  mut z : Double
  mut yaw : Double
}

///|
priv struct Dot {
  entity : @entity.Entity
  minimap_entity : @entity.Entity
  x : Double
  z : Double
  mut collected : Bool
}

///|
priv struct Ghost {
  entity : @entity.Entity
  light_entity : @entity.Entity
  spot_ray_entity : @entity.Entity
  left_eye_entity : @entity.Entity
  right_eye_entity : @entity.Entity
  minimap_entity : @entity.Entity
  mut x : Double
  mut z : Double
  mut direction : Direction
  bob_phase : Double
  ghost_type : GhostType
}

///|
let level1 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 2, 0, 0, 1, 0, 0, 0, 1],
  [1, 0, 1, 0, 0, 5, 1, 0, 1],
  [1, 0, 0, 0, 1, 0, 0, 0, 1],
  [1, 1, 1, 0, 0, 0, 1, 1, 1],
  [1, 0, 0, 0, 1, 0, 0, 0, 1],
  [1, 0, 1, 5, 0, 0, 1, 0, 1],
  [1, 0, 0, 0, 1, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let level2 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 2, 0, 0, 0, 1, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 1, 0, 1, 0, 5, 0, 1, 0, 1, 1],
  [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1],
  [1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 1, 0, 0, 0, 3, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let level3 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 2, 0, 0, 0, 0, 1, 0, 0, 0, 0, 4, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1],
  [1, 1, 1, 0, 1, 0, 0, 0, 1, 0, 1, 1, 1],
  [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 1, 0, 0, 0, 1, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1],
  [1, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let level4 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 2, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 5, 1],
  [1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1],
  [1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1],
  [1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1],
  [1, 0, 1, 1, 0, 1, 0, 1, 3, 1, 0, 1, 0, 1, 1, 0, 1],
  [1, 0, 0, 0, 0, 1, 0, 3, 1, 3, 0, 1, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 0, 1, 0, 1, 3, 1, 0, 1, 0, 1, 1, 0, 1],
  [1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1],
  [1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1],
  [1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1],
  [1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1],
  [1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1],
  [1, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 1],
  [1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1],
  [1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1],
  [1, 5, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 5, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let levels : ReadOnlyArray[Level] = [level1, level2, level3, level4]

///|
let current_level : Ref[Int] = { val: 0 }

///|
let completed_all_levels : Ref[Bool] = { val: false }

///|
let player_state : PlayerState = { x: 0.0, z: 0.0, yaw: 0.0 }

///|
let dots : Array[Dot] = []

///|
let ghosts : Array[Ghost] = []

///|
let floor_entities : Array[@entity.Entity] = []

///|
let ceiling_entities : Array[@entity.Entity] = []

///|
let wall_entities : Array[@entity.Entity] = []

///|
let minimap_tile_entities : Array[@entity.Entity] = []

///|
let minimap_player_entity : @entity.Entity = @entity.Entity::new()

///|
let camera_entity : @entity.Entity = @entity.Entity::new()

///|
let light_entity : @entity.Entity = @entity.Entity::new()

///|
let player_light_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_title_ui : @entity.Entity = @entity.Entity::new()

///|
let hud_line1_ui : @entity.Entity = @entity.Entity::new()

///|
let hud_line2_ui : @entity.Entity = @entity.Entity::new()

///|
let hud_line3_ui : @entity.Entity = @entity.Entity::new()

///|
let hud_debug_ui : @entity.Entity = @entity.Entity::new()

///|
let hud_title_text_cache : Ref[String] = { val: "" }

///|
let hud_line1_text_cache : Ref[String] = { val: "" }

///|
let hud_line2_text_cache : Ref[String] = { val: "" }

///|
let hud_line3_text_cache : Ref[String] = { val: "" }

///|
let hud_debug_text_cache : Ref[String] = { val: "" }

///|
let wall_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let floor_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let dot_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let ghost_body_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let ghost_eye_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let ghost_spot_ray_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let wall_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let wall_material_neutral : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let wall_material_textured_flat : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let wall_material_brdf_only : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let floor_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let floor_material_neutral : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let floor_material_textured_flat : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let floor_material_brdf_only : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let ceiling_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let ceiling_material_neutral : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let ceiling_material_textured_flat : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let ceiling_material_brdf_only : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let dot_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let dot_material_neutral : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let dot_material_no_emissive : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let ghost_material_fast : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let ghost_material_fast_neutral : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let ghost_material_fast_no_emissive : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let ghost_material_normal : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let ghost_material_normal_neutral : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let ghost_material_normal_no_emissive : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let ghost_material_slow : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let ghost_material_slow_neutral : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let ghost_material_slow_no_emissive : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let ghost_eye_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let ghost_eye_material_neutral : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let ghost_eye_material_no_emissive : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let ghost_spot_ray_material_fast : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let ghost_spot_ray_material_normal : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let ghost_spot_ray_material_slow : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let rand : @random.Rand = @random.Rand::new()

///|
let pacman_asset_path_prefixes : Array[String] = [
  "", "../", "../../", "../../../",
]

///|
fn resolve_pacman_asset_path(path : String) -> String {
  for prefix in pacman_asset_path_prefixes {
    let candidate = "\{prefix}\{path}"
    if @asset.read_bytes(candidate) is Some(_) {
      return candidate
    }
  }
  path
}

///|
fn map_width(level : Level) -> Int {
  if level.length() == 0 {
    0
  } else {
    level[0].length()
  }
}

///|
fn map_height(level : Level) -> Int {
  level.length()
}

///|
fn get_map() -> Level {
  if lighting_debug.scene_enabled {
    lighting_debug_level
  } else {
    levels[current_level.val]
  }
}

///|
fn next_level() -> Unit {
  current_level.val += 1
  if current_level.val >= levels.length() {
    completed_all_levels.val = true
    current_level.val = 0
  }
}

///|
fn world_x_for_tile(tile_x : Int) -> Double {
  (tile_x.to_double() + 0.5) * TILE_WORLD_SIZE
}

///|
fn world_z_for_tile(tile_y : Int) -> Double {
  (tile_y.to_double() + 0.5) * TILE_WORLD_SIZE
}

///|
fn tile_x_for_world(x : Double) -> Int {
  (x / TILE_WORLD_SIZE).floor().to_int()
}

///|
fn tile_y_for_world(z : Double) -> Int {
  (z / TILE_WORLD_SIZE).floor().to_int()
}

///|
fn minimap_pos_for_tile(tile_x : Int, tile_y : Int) -> @math.Vec2 {
  @math.Vec2(
    MINIMAP_OFFSET_X + tile_x.to_double() * MINIMAP_CELL_SIZE,
    MINIMAP_OFFSET_Y + tile_y.to_double() * MINIMAP_CELL_SIZE,
  )
}

///|
fn minimap_pos_for_world(
  x : Double,
  z : Double,
  marker_size : Double,
) -> @math.Vec2 {
  @math.Vec2(
    MINIMAP_OFFSET_X +
    x / TILE_WORLD_SIZE * MINIMAP_CELL_SIZE -
    marker_size / 2.0,
    MINIMAP_OFFSET_Y +
    z / TILE_WORLD_SIZE * MINIMAP_CELL_SIZE -
    marker_size / 2.0,
  )
}

///|
fn is_wall_at_tile(level : Level, tile_x : Int, tile_y : Int) -> Bool {
  if tile_x < 0 || tile_y < 0 {
    return true
  }
  let width = map_width(level)
  let height = map_height(level)
  if tile_x >= width || tile_y >= height {
    return true
  }
  level[tile_y][tile_x] == 1
}

///|
fn is_wall_world(x : Double, z : Double) -> Bool {
  is_wall_at_tile(get_map(), tile_x_for_world(x), tile_y_for_world(z))
}

///|
fn ghost_speed(ghost_type : GhostType) -> Double {
  let level_bonus = current_level.val.to_double() * GHOST_LEVEL_SPEED_BONUS
  let base = BASE_GHOST_SPEED + level_bonus
  match ghost_type {
    Fast => base * 1.5
    Normal => base
    Slow => base * 0.7
  }
}

///|
fn ghost_type_from_tile(tile_value : Int) -> GhostType {
  match tile_value {
    3 => Fast
    4 => Normal
    5 => Slow
    _ => Normal
  }
}

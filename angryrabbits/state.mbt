///|
const VIEWPORT_WIDTH : Double = 640.0

///|
const VIEWPORT_HEIGHT : Double = 480.0

///|
const FPS : UInt = 60

///|
const ZOOM : Double = 2.0

///|
const SKY_COLOR : String = "rgb(183, 225, 255)"

///|
const GROUND_COLOR : String = "rgb(156, 198, 104)"

///|
const GROUND_HEIGHT : Double = 92.0

///|
const GROUND_Y : Double = VIEWPORT_HEIGHT - GROUND_HEIGHT

///|
let current_level_path : Ref[String] = { val: DEFAULT_LEVEL_PATH }

///|
let current_level : Ref[LevelDef] = { val: default_level_def() }

///|
fn slingshot_anchor() -> @math.Vec2D {
  current_level.val.slingshot_anchor
}

///|
fn rabbit_spawn_point() -> @math.Vec2D {
  current_level.val.rabbit_spawn
}

///|
const RABBIT_RADIUS : Double = 18.0

///|
const TARGET_RADIUS : Double = 18.0

///|
const MAX_DRAG_RADIUS : Double = 84.0

///|
const DRAG_GROUND_CLEARANCE : Double = 12.0

///|
const MIN_LAUNCH_STRETCH : Double = 12.0

///|
const LAUNCH_SPEED_FACTOR : Double = 9.2

///|
const GRAVITY : Double = 980.0

///|
const AIR_DRAG : Double = 0.997

///|
const GROUND_FRICTION : Double = 0.90

///|
const BLOCK_RESTITUTION : Double = 0.16

///|
const RABBIT_RESTITUTION : Double = 0.28

///|
const STOP_SPEED : Double = 62.0

///|
const MAX_SHOTS : Int = 5

///|
const AIM_DOT_COUNT : Int = 10

///|
const AIM_DOT_RADIUS : Double = 4.0

///|
const AIM_DOT_TIME_STEP : Double = 0.085

///|
const BLOCK_HIT_TRANSFER : Double = 0.48

///|
const TARGET_HIT_SPEED : Double = 165.0

///|
const BLOCK_TARGET_CRUSH_SPEED : Double = 150.0

///|
priv enum RoundPhase {
  Ready
  Dragging
  Flying
  Won
  Lost
} derive(Eq)

///|
priv struct BlockState {
  entity : @entity.Entity
  center : @math.Vec2D
  size : @math.Vec2D
  velocity : @math.Vec2D
  color : String
  alive : Bool
}

///|
priv struct TargetState {
  entity : @entity.Entity
  center : @math.Vec2D
  radius : Double
  velocity : @math.Vec2D
  color : String
  alive : Bool
}

///|
let scene_initialized : Ref[Bool] = { val: false }

///|
let phase : Ref[RoundPhase] = { val: Ready }

///|
let shots_remaining : Ref[Int] = { val: MAX_SHOTS }

///|
let rabbit_center : Ref[@math.Vec2D] = { val: rabbit_spawn_point() }

///|
let rabbit_velocity : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let rabbit_visible : Ref[Bool] = { val: true }

///|
let rabbit_flight_time : Ref[Double] = { val: 0.0 }

///|
let blocks : Array[BlockState] = []

///|
let targets : Array[TargetState] = []

///|
let background_entity : @entity.Entity = @entity.Entity::new()

///|
let ground_entity : @entity.Entity = @entity.Entity::new()

///|
let hill_entity : @entity.Entity = @entity.Entity::new()

///|
let slingshot_left_entity : @entity.Entity = @entity.Entity::new()

///|
let slingshot_right_entity : @entity.Entity = @entity.Entity::new()

///|
let slingshot_base_entity : @entity.Entity = @entity.Entity::new()

///|
let rabbit_entity : @entity.Entity = @entity.Entity::new()

///|
let rabbit_eye_entity : @entity.Entity = @entity.Entity::new()

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let hint_entity : @entity.Entity = @entity.Entity::new()

///|
let status_entity : @entity.Entity = @entity.Entity::new()

///|
let score_entity : @entity.Entity = @entity.Entity::new()

///|
let aim_dot_entities : Array[@entity.Entity] = []

///|
let block_entities : Array[@entity.Entity] = []

///|
let target_entities : Array[@entity.Entity] = []

///|
/// Logical viewport width in world pixels.
const VIEWPORT_WIDTH : Double = 640.0

///|
/// Logical viewport height in world pixels.
const VIEWPORT_HEIGHT : Double = 480.0

///|
/// Target render/update frame rate.
const FPS : UInt = 60

///|
/// Pixel zoom factor from logical viewport to window size.
const ZOOM : Double = 2.0

///|
/// Ground strip height from the bottom of the scene.
const GROUND_HEIGHT : Double = 92.0

///|
/// Derived top Y coordinate of the ground strip.
const GROUND_Y : Double = VIEWPORT_HEIGHT - GROUND_HEIGHT

///|
let current_level_path : Ref[String] = { val: DEFAULT_LEVEL_PATH }

///|
let current_level : Ref[LevelDef?] = { val: None }

///|
fn slingshot_anchor() -> @math.Vec2D {
  match current_level.val {
    Some(level) => level.slingshot_anchor
    None => @math.Vec2D::zero()
  }
}

///|
/// Rabbit collision radius and rendered body size.
const RABBIT_RADIUS : Double = 18.0

///|
/// Atlas texture used by runtime sprite slicing.
const ANGRYRABBITS_SPRITES_PATH : String = "angryrabbits/assets/sprites.png"

///|
/// Rabbit sprite source top-left X in `sprites.png`.
const RABBIT_SPRITE_SRC_X : Double = 294.0

///|
/// Rabbit sprite source top-left Y in `sprites.png`.
const RABBIT_SPRITE_SRC_Y : Double = 897.0

///|
/// Rabbit sprite source width in `sprites.png`.
const RABBIT_SPRITE_SRC_WIDTH : Double = 83.0

///|
/// Rabbit sprite source height in `sprites.png`.
const RABBIT_SPRITE_SRC_HEIGHT : Double = 95.0

///|
/// Block sprite source top-left X in `sprites.png`.
const BLOCK_SPRITE_SRC_X : Double = 1244.0

///|
/// Block sprite source top-left Y in `sprites.png`.
const BLOCK_SPRITE_SRC_Y : Double = 577.0

///|
/// Block sprite source width in `sprites.png`.
const BLOCK_SPRITE_SRC_WIDTH : Double = 68.0

///|
/// Block sprite source height in `sprites.png`.
const BLOCK_SPRITE_SRC_HEIGHT : Double = 89.0

///|
/// Target sprite source top-left X in `sprites.png`.
const TARGET_SPRITE_SRC_X : Double = 561.0

///|
/// Target sprite source top-left Y in `sprites.png`.
const TARGET_SPRITE_SRC_Y : Double = 899.0

///|
/// Target sprite source width in `sprites.png`.
const TARGET_SPRITE_SRC_WIDTH : Double = 50.0

///|
/// Target sprite source height in `sprites.png`.
const TARGET_SPRITE_SRC_HEIGHT : Double = 48.0

///|
/// Maximum slingshot stretch distance from the anchor.
const MAX_DRAG_RADIUS : Double = 84.0

///|
/// Minimum clearance between dragged rabbit and the ground.
const DRAG_GROUND_CLEARANCE : Double = 12.0

///|
/// Minimum stretch required before a release counts as a launch.
const MIN_LAUNCH_STRETCH : Double = 12.0

///|
/// Launch speed multiplier applied to slingshot stretch.
const LAUNCH_SPEED_FACTOR : Double = 9.2

///|
/// Downward gravity acceleration in pixels per second squared.
const GRAVITY : Double = 980.0

///|
/// Friction coefficient for the static ground collider.
const GROUND_FRICTION : Double = 0.90

///|
/// Bounce factor for wooden blocks.
const BLOCK_RESTITUTION : Double = 0.16

///|
/// Bounce factor for the rabbit body.
const RABBIT_RESTITUTION : Double = 0.28

///|
/// Speed threshold below which the rabbit is considered almost stationary.
const STOP_SPEED : Double = 62.0

///|
/// Default number of rabbits available in a level.
const MAX_SHOTS : Int = 5

///|
/// Number of projected aim dots shown while dragging.
const AIM_DOT_COUNT : Int = 10

///|
/// Radius of each projected aim dot.
const AIM_DOT_RADIUS : Double = 4.0

///|
/// Time spacing between aim dots on the projected arc.
const AIM_DOT_TIME_STEP : Double = 0.085

///|
/// Minimum rabbit impact speed required to pop a target directly.
const TARGET_HIT_SPEED : Double = 165.0

///|
/// Minimum block speed required to crush a target on contact.
const BLOCK_TARGET_CRUSH_SPEED : Double = 150.0

///|
/// Minimum rabbit impact speed required to break a wooden block.
const BLOCK_BREAK_SPEED : Double = 220.0

///|
/// Physics world pixel-to-meter scale.
const PHYSICS_PIXELS_PER_METER : Double = 100.0

///|
/// Maximum CCD substeps for fast-moving bodies.
const PHYSICS_MAX_CCD_SUBSTEPS : Int = 4

///|
/// Linear damping applied to the rabbit while flying.
const RABBIT_LINEAR_DAMPING : Double = 0.18

///|
/// Linear damping applied to wooden blocks.
const BLOCK_LINEAR_DAMPING : Double = 0.22

///|
/// Linear damping applied to targets.
const TARGET_LINEAR_DAMPING : Double = 0.30

///|
/// Minimum flight time before the rabbit is allowed to settle.
const RABBIT_SETTLE_TIME : Double = 0.18

///|
/// Continuous low-speed time required before advancing to the next shot.
const RABBIT_IDLE_TIME : Double = 0.35

///|
priv enum RoundPhase {
  Error
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
  alive : Bool
}

///|
priv struct TargetState {
  entity : @entity.Entity
  center : @math.Vec2D
  radius : Double
  alive : Bool
}

///|
let scene_initialized : Ref[Bool] = { val: false }

///|
let phase : Ref[RoundPhase] = { val: Ready }

///|
let shots_remaining : Ref[Int] = { val: MAX_SHOTS }

///|
let load_error_message : Ref[String] = { val: "" }

///|
let rabbit_center : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let rabbit_velocity : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let rabbit_visible : Ref[Bool] = { val: true }

///|
let rabbit_flight_time : Ref[Double] = { val: 0.0 }

///|
let rabbit_idle_time : Ref[Double] = { val: 0.0 }

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

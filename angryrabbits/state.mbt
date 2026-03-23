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
/// Slingshot sprite source top-left X in `sprites.png`.
const SLINGSHOT_SPRITE_SRC_X : Double = 1038.0

///|
/// Slingshot sprite source top-left Y in `sprites.png`.
const SLINGSHOT_SPRITE_SRC_Y : Double = 318.0

///|
/// Slingshot sprite source width in `sprites.png`.
const SLINGSHOT_SPRITE_SRC_WIDTH : Double = 60.0

///|
/// Slingshot sprite source height in `sprites.png`.
const SLINGSHOT_SPRITE_SRC_HEIGHT : Double = 338.0

///|
/// Front slingshot layer source Y offset from the slingshot source origin.
const SLINGSHOT_FRONT_SRC_OFFSET_Y : Double = 0.0

///|
/// Front slingshot layer source height from the slingshot source origin.
const SLINGSHOT_FRONT_SRC_HEIGHT : Double = 210.0

///|
/// Back slingshot layer source Y offset from the slingshot source origin.
const SLINGSHOT_BACK_SRC_OFFSET_Y : Double = 212.0

///|
/// Back slingshot layer source height from the slingshot source origin.
const SLINGSHOT_BACK_SRC_HEIGHT : Double = 126.0

///|
/// Additional world-space X offset applied to front slingshot layer.
const SLINGSHOT_FRONT_OFFSET_X : Double = 0.0

///|
/// Additional world-space Y offset applied to front slingshot layer.
const SLINGSHOT_FRONT_OFFSET_Y : Double = 0.0

///|
/// Additional world-space X offset applied to back slingshot layer.
const SLINGSHOT_BACK_OFFSET_X : Double = 0.0

///|
/// Additional world-space Y offset applied to back slingshot layer.
const SLINGSHOT_BACK_OFFSET_Y : Double = 0.0

///|
/// Slingshot rendered width in world pixels.
const SLINGSHOT_WORLD_WIDTH : Double = 26.0

///|
/// Slingshot rendered height in world pixels.
const SLINGSHOT_WORLD_HEIGHT : Double = 152.0

///|
/// Maximum slingshot stretch distance from the anchor.
const MAX_DRAG_RADIUS : Double = 84.0

///|
/// Upstream slingshot clamps the bird to a radius of 1.5 world units.
/// We map our pixel drag radius to the same gameplay distance instead of
/// reusing the physics meter scale.
const UPSTREAM_MAX_PULL_DISTANCE : Double = 1.5

///|
/// Minimum clearance between dragged rabbit and the ground.
const DRAG_GROUND_CLEARANCE : Double = 12.0

///|
/// Minimum stretch required before a release counts as a launch.
const MIN_LAUNCH_STRETCH : Double = 56.0

///|
/// Upstream slingshot throw speed.
const THROW_SPEED : Double = 10.0

///|
/// Downward gravity acceleration in pixels per second squared.
const GRAVITY : Double = 980.0

///|
/// Friction coefficient for the static ground collider.
const GROUND_FRICTION : Double = 0.4

///|
/// Friction coefficient for the rabbit collider.
const RABBIT_FRICTION : Double = 0.4

///|
/// Bounce factor for wooden blocks.
const BLOCK_RESTITUTION : Double = 0.0

///|
/// Bounce factor for the rabbit body.
const RABBIT_RESTITUTION : Double = 0.0

///|
/// Speed threshold below which a rigid body is treated as stopped.
const STOP_SPEED : Double = 22.4

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
/// Actual prefab health for wooden blocks in the shipped Unity scene.
const BLOCK_HEALTH : Double = 100.0

///|
/// Upstream-style health for targets.
const TARGET_HEALTH : Double = 150.0

///|
/// Damage multiplier applied to the other body's speed in meters per second.
const COLLISION_DAMAGE_FACTOR : Double = 10.0

///|
/// Time limit before the current shot advances even if some bodies still wobble.
const SHOT_TIMEOUT : Double = 5.0

///|
/// Extra margin around the viewport used for out-of-bounds cleanup.
const OUT_OF_BOUNDS_MARGIN : Double = 160.0

///|
/// Physics world pixel-to-meter scale.
const PHYSICS_PIXELS_PER_METER : Double = 100.0

///|
/// Maximum CCD substeps for fast-moving bodies.
const PHYSICS_MAX_CCD_SUBSTEPS : Int = 4

///|
/// Linear damping applied to the rabbit while flying.
const RABBIT_LINEAR_DAMPING : Double = 0.0

///|
/// Angular damping applied to the rabbit while flying.
const RABBIT_ANGULAR_DAMPING : Double = 5.0

///|
/// Linear damping applied to wooden blocks.
const BLOCK_LINEAR_DAMPING : Double = 0.0

///|
/// Angular damping for wooden blocks. Lower values make stacks topple easier.
const BLOCK_ANGULAR_DAMPING : Double = 0.05

///|
/// Block surface friction. Lower values make blocks slide/tilt more easily.
const BLOCK_FRICTION : Double = 0.4

///|
/// Linear damping applied to targets.
const TARGET_LINEAR_DAMPING : Double = 0.0

///|
/// Angular damping for targets.
const TARGET_ANGULAR_DAMPING : Double = 0.05

///|
/// Target surface friction.
const TARGET_FRICTION : Double = 0.4

///|
/// Pickup radius while the rabbit is idle on the slingshot.
const RABBIT_PICKUP_RADIUS : Double = 50.0

///|
/// Horizontal offset from the slingshot wait point to the first queued rabbit.
const RABBIT_QUEUE_OFFSET_X : Double = -72.0

///|
/// Horizontal spacing between queued rabbits.
const RABBIT_QUEUE_SPACING_X : Double = -48.0

///|
/// Speed used when animating a rabbit to or from the slingshot.
const RABBIT_MOVE_SPEED : Double = 1000.0

///|
/// Speed used when animating the camera back to the start position.
const CAMERA_RETURN_SPEED : Double = 1000.0

///|
/// Delay before a thrown rabbit is removed after it comes to rest.
const THROWN_RABBIT_REMOVE_DELAY : Double = 2.0

///|
priv enum GameState {
  Error
  Start
  BirdMovingToSlingshot
  Playing
  Won
  Lost
} derive(Eq)

///|
priv enum SlingshotState {
  Idle
  UserPulling
  BirdFlying
} derive(Eq)

///|
priv enum BirdState {
  BeforeThrown
  Thrown
  Removed
} derive(Eq)

///|
priv enum RabbitMotionKind {
  RabbitMotionNone
  RabbitMoveToSlingshot
  RabbitReturnToSlingshot
} derive(Eq)

///|
priv enum CameraMode {
  CameraIdle
  CameraFollowBird
  CameraReturnToStart
}

///|
priv struct RabbitState {
  entity : @entity.Entity
  center : @math.Vec2D
  velocity : @math.Vec2D
  rotation : Double
  visible : Bool
  state : BirdState
  alive : Bool
  sleep_time : Double
}

///|
priv struct BlockState {
  entity : @entity.Entity
  center : @math.Vec2D
  size : @math.Vec2D
  velocity : @math.Vec2D
  rotation : Double
  health : Double
  alive : Bool
}

///|
priv struct TargetState {
  entity : @entity.Entity
  center : @math.Vec2D
  radius : Double
  velocity : @math.Vec2D
  rotation : Double
  health : Double
  alive : Bool
}

///|
let scene_initialized : Ref[Bool] = { val: false }

///|
let game_state : Ref[GameState] = { val: Start }

///|
let slingshot_state : Ref[SlingshotState] = { val: Idle }

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
let current_rabbit_index : Ref[Int] = { val: 0 }

///|
let rabbits : Array[RabbitState] = []

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
let rabbit_eye_entity : @entity.Entity = @entity.Entity::new()

///|
let camera_anchor_entity : @entity.Entity = @entity.Entity::new()

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
let rabbit_entities : Array[@entity.Entity] = []

///|
let block_entities : Array[@entity.Entity] = []

///|
let target_entities : Array[@entity.Entity] = []

///|
let rabbit_motion_kind : Ref[RabbitMotionKind] = { val: RabbitMotionNone }

///|
let rabbit_motion_start : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let rabbit_motion_end : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let rabbit_motion_duration : Ref[Double] = { val: 0.0 }

///|
let rabbit_motion_elapsed : Ref[Double] = { val: 0.0 }

///|
let camera_mode : Ref[CameraMode] = { val: CameraIdle }

///|
let camera_start_position : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let camera_return_duration : Ref[Double] = { val: 0.0 }

///|
let camera_return_elapsed : Ref[Double] = { val: 0.0 }

///|
let camera_return_origin : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
const DEBUG_TRACE_FIXED_FRAMES : Int = 6

///|
let debug_text_entity : @entity.Entity = @entity.Entity::new()

///|
let debug_mouse_screen : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let debug_mouse_world : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let debug_drag_center : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let debug_release_screen : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let debug_release_mouse_world : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let debug_release_center : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let debug_launch_velocity : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let debug_physics_center : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let debug_physics_velocity : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }

///|
let debug_last_event : Ref[String] = { val: "startup" }

///|
let debug_trace_fixed_frames_remaining : Ref[Int] = { val: 0 }

///|
let debug_trace_update_frames_remaining : Ref[Int] = { val: 0 }

///|
let debug_tracked_rabbit_entity : Ref[@entity.Entity?] = { val: None }

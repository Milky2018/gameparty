///|
const VIEWPORT_WIDTH : Double = 1280.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const BRICK_COLS : Int = 10

///|
const BRICK_ROWS : Int = 8

///|
const MAX_BRICK_COUNT : Int = BRICK_COLS * BRICK_ROWS

///|
const MAX_BALLS : Int = 6

///|
const MAX_POWERUPS : Int = 8

///|
const MAX_LASERS : Int = 10

///|
const BRICK_WIDTH : Double = 84.0

///|
const BRICK_HEIGHT : Double = 24.0

///|
const BRICK_GAP : Double = 6.0

///|
const BOARD_WIDTH : Double = 894.0

///|
const BOARD_HEIGHT : Double = 520.0

///|
const BOARD_LEFT : Double = 193.0

///|
const BOARD_TOP : Double = 122.0

///|
const BOARD_RIGHT : Double = 1087.0

///|
const BOARD_BOTTOM : Double = BOARD_TOP + BOARD_HEIGHT

///|
const BRICK_ORIGIN_Y : Double = BOARD_TOP + 18.0

///|
const PADDLE_CENTER_Y : Double = BOARD_BOTTOM - 26.0

///|
const PADDLE_HEIGHT : Double = 18.0

///|
const PADDLE_BASE_WIDTH : Double = 112.0

///|
const PADDLE_WIDE_WIDTH : Double = 172.0

///|
const BALL_SIZE : Double = 12.0

///|
const LASER_WIDTH : Double = 6.0

///|
const LASER_HEIGHT : Double = 18.0

///|
const POWERUP_SIZE : Double = 18.0

///|
const BASE_BALL_SPEED : Double = 430.0

///|
const MULTIBALL_SIDE_SPEED : Double = 160.0

///|
const SLOW_BALL_MULTIPLIER : Double = 0.72

///|
const POWERUP_FALL_SPEED : Double = 140.0

///|
const LASER_SPEED : Double = 720.0

///|
const WIDE_PADDLE_SECONDS : Double = 12.0

///|
const SLOW_BALL_SECONDS : Double = 10.0

///|
const PADDLE_MODE_SECONDS : Double = 10.0

///|
const LEVEL_CLEAR_SECONDS : Double = 0.9

///|
const LASER_COOLDOWN_SECONDS : Double = 0.24

///|
const STARTING_LIVES : Int = 3

///|
enum GamePhase {
  Ready
  Serving
  Playing
  LevelCleared
  Won
  Lost
} derive(Eq, Debug)

///|
enum BrickKind {
  Normal
  Strong
  Steel
  PowerCarrier
} derive(Eq, Debug)

///|
enum PowerUpKind {
  WidePaddle
  SlowBall
  MultiBall
  Catch
  Laser
} derive(Eq, Debug)

///|
priv enum PaddleMode {
  None
  Catch
  Laser
} derive(Eq)

///|
priv struct BrickSpec {
  row : Int
  col : Int
  kind : BrickKind
  powerup : PowerUpKind?
}

///|
priv struct CarrierPlacement {
  col : Int
  powerup : PowerUpKind
}

///|
priv struct LevelSpec {
  bricks : Array[BrickSpec]
  speed_scale : Double
}

///|
priv struct BrickState {
  mut row : Int
  mut col : Int
  mut kind : BrickKind
  mut powerup : PowerUpKind?
  mut hits_remaining : Int
  mut active : Bool
}

///|
priv struct BallState {
  mut active : Bool
  mut x : Double
  mut y : Double
  mut vx : Double
  mut vy : Double
  mut stuck_to_paddle : Bool
  mut stuck_offset : Double
}

///|
priv struct PaddleState {
  mut center_x : Double
  mut width : Double
}

///|
priv struct PowerUpState {
  mut active : Bool
  mut kind : PowerUpKind
  mut x : Double
  mut y : Double
  mut vy : Double
}

///|
priv struct LaserShotState {
  mut active : Bool
  mut x : Double
  mut y : Double
  mut vy : Double
}

///|
priv struct GameState {
  mut phase : GamePhase
  mut phase_seconds : Double
  mut current_level : Int
  mut lives : Int
  mut remaining_breakables : Int
  mut wide_seconds : Double
  mut slow_seconds : Double
  mut paddle_mode : PaddleMode
  mut paddle_mode_seconds : Double
  mut laser_cooldown : Double
}

///|
priv struct ButtonRect {
  left : Double
  top : Double
  width : Double
  height : Double
}

///|
let game_state : GameState = {
  phase: Ready,
  phase_seconds: 0.0,
  current_level: 0,
  lives: STARTING_LIVES,
  remaining_breakables: 0,
  wide_seconds: 0.0,
  slow_seconds: 0.0,
  paddle_mode: PaddleMode::None,
  paddle_mode_seconds: 0.0,
  laser_cooldown: 0.0,
}

///|
let paddle_state : PaddleState = {
  center_x: BOARD_LEFT + BOARD_WIDTH * 0.5,
  width: PADDLE_BASE_WIDTH,
}

///|
let bricks : Array[BrickState] = []

///|
let balls : Array[BallState] = []

///|
let powerups : Array[PowerUpState] = []

///|
let laser_shots : Array[LaserShotState] = []

///|
let background_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let lives_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let lives_text_entity : @entity.Entity = @entity.Entity::new()

///|
let reset_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let reset_text_entity : @entity.Entity = @entity.Entity::new()

///|
let remaining_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let remaining_text_entity : @entity.Entity = @entity.Entity::new()

///|
let indicator_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let board_frame_entity : @entity.Entity = @entity.Entity::new()

///|
let paddle_entity : @entity.Entity = @entity.Entity::new()

///|
let overlay_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let overlay_text_entity : @entity.Entity = @entity.Entity::new()

///|
let brick_entities : Array[@entity.Entity] = []

///|
let ball_entities : Array[@entity.Entity] = []

///|
let powerup_entities : Array[@entity.Entity] = []

///|
let laser_entities : Array[@entity.Entity] = []

///|
fn brick(
  row : Int,
  col : Int,
  kind : BrickKind,
  powerup? : PowerUpKind? = None,
) -> BrickSpec {
  { row, col, kind, powerup }
}

///|
fn carrier(col : Int, powerup : PowerUpKind) -> CarrierPlacement {
  { col, powerup }
}

///|
fn push_brick_row(
  bricks : Array[BrickSpec],
  row : Int,
  cols : Array[Int],
  kind : BrickKind,
) -> Unit {
  for col in cols {
    bricks.push(brick(row, col, kind))
  }
}

///|
fn push_carrier_row(
  bricks : Array[BrickSpec],
  row : Int,
  placements : Array[CarrierPlacement],
) -> Unit {
  for placement in placements {
    bricks.push(
      brick(row, placement.col, PowerCarrier, powerup=Some(placement.powerup)),
    )
  }
}

///|
fn make_levels() -> Array[LevelSpec] {
  let levels : Array[LevelSpec] = []

  let level1 : Array[BrickSpec] = []
  push_brick_row(level1, 0, [1, 2, 3, 4, 5, 6, 7, 8], Normal)
  push_brick_row(level1, 1, [0, 1, 2, 3, 5, 6, 7, 8, 9], Normal)
  push_carrier_row(level1, 1, [carrier(4, WidePaddle)])
  push_brick_row(level1, 2, [2, 3, 4, 5, 6, 7], Strong)
  levels.push({ bricks: level1, speed_scale: 1.00 })

  let level2 : Array[BrickSpec] = []
  push_brick_row(level2, 0, [0, 9], Steel)
  push_brick_row(level2, 0, [1, 2, 3, 4, 5, 6, 7, 8], Strong)
  push_brick_row(level2, 1, [0, 1, 2, 4, 5, 6, 7, 8, 9], Normal)
  push_carrier_row(level2, 1, [carrier(3, SlowBall)])
  push_brick_row(level2, 2, [1, 2, 3, 6, 7, 8], Normal)
  push_brick_row(level2, 3, [3, 4, 5, 6], Strong)
  levels.push({ bricks: level2, speed_scale: 1.04 })

  let level3 : Array[BrickSpec] = []
  push_brick_row(level3, 0, [1, 2, 3, 4, 5, 6, 7, 8], Normal)
  push_brick_row(level3, 1, [0, 1, 3, 4, 5, 6, 8, 9], Strong)
  push_brick_row(level3, 2, [2, 7], Steel)
  push_brick_row(level3, 3, [0, 1, 2, 3, 5, 6, 7, 8, 9], Normal)
  push_carrier_row(level3, 3, [carrier(4, MultiBall)])
  levels.push({ bricks: level3, speed_scale: 1.08 })

  let level4 : Array[BrickSpec] = []
  push_brick_row(level4, 0, [0, 1, 2, 3, 6, 7, 8, 9], Strong)
  push_brick_row(level4, 1, [0, 4, 5, 9], Steel)
  push_brick_row(level4, 1, [1, 2, 3, 6, 7, 8], Normal)
  push_brick_row(level4, 2, [0, 1, 2, 7, 8, 9], Normal)
  push_carrier_row(level4, 2, [carrier(4, Catch), carrier(5, Catch)])
  push_brick_row(level4, 3, [2, 3, 4, 5, 6, 7], Strong)
  levels.push({ bricks: level4, speed_scale: 1.12 })

  let level5 : Array[BrickSpec] = []
  push_brick_row(level5, 0, [0, 9], Steel)
  push_brick_row(level5, 0, [1, 2, 3, 4, 5, 6, 7, 8], Strong)
  push_brick_row(level5, 1, [2, 3, 6, 7], Steel)
  push_brick_row(level5, 1, [0, 1, 4, 5, 8, 9], Normal)
  push_carrier_row(level5, 2, [carrier(1, Laser), carrier(8, Laser)])
  push_brick_row(level5, 2, [3, 4, 5, 6], Strong)
  push_brick_row(level5, 3, [0, 1, 2, 3, 6, 7, 8, 9], Normal)
  levels.push({ bricks: level5, speed_scale: 1.16 })

  let level6 : Array[BrickSpec] = []
  push_brick_row(level6, 0, [0, 1, 2, 7, 8, 9], Steel)
  push_brick_row(level6, 0, [3, 4, 5, 6], Strong)
  push_brick_row(level6, 1, [0, 2, 4, 5, 7, 9], Normal)
  push_carrier_row(level6, 1, [carrier(1, MultiBall), carrier(8, SlowBall)])
  push_brick_row(level6, 2, [1, 2, 3, 6, 7, 8], Strong)
  push_carrier_row(level6, 3, [
    carrier(0, WidePaddle),
    carrier(4, Catch),
    carrier(9, Laser),
  ])
  push_brick_row(level6, 3, [2, 3, 5, 6, 7], Normal)
  push_brick_row(level6, 4, [1, 4, 5, 8], Steel)
  push_brick_row(level6, 4, [0, 2, 3, 6, 7, 9], Strong)
  levels.push({ bricks: level6, speed_scale: 1.20 })

  levels
}

///|
let levels : Array[LevelSpec] = make_levels()

///|
fn level_count() -> Int {
  levels.length()
}

///|
fn rect(
  left : Double,
  top : Double,
  width : Double,
  height : Double,
) -> ButtonRect {
  { left, top, width, height }
}

///|
fn brick_rect(row : Int, col : Int) -> ButtonRect {
  let left = BOARD_LEFT + col.to_double() * (BRICK_WIDTH + BRICK_GAP)
  let top = BRICK_ORIGIN_Y + row.to_double() * (BRICK_HEIGHT + BRICK_GAP)
  rect(left, top, BRICK_WIDTH, BRICK_HEIGHT)
}

///|
fn paddle_rect() -> ButtonRect {
  rect(
    paddle_state.center_x - paddle_state.width * 0.5,
    PADDLE_CENTER_Y - PADDLE_HEIGHT * 0.5,
    paddle_state.width,
    PADDLE_HEIGHT,
  )
}

///|
fn ball_rect(ball : BallState) -> ButtonRect {
  rect(ball.x - BALL_SIZE * 0.5, ball.y - BALL_SIZE * 0.5, BALL_SIZE, BALL_SIZE)
}

///|
fn powerup_rect(powerup : PowerUpState) -> ButtonRect {
  rect(
    powerup.x - POWERUP_SIZE * 0.5,
    powerup.y - POWERUP_SIZE * 0.5,
    POWERUP_SIZE,
    POWERUP_SIZE,
  )
}

///|
fn laser_rect(shot : LaserShotState) -> ButtonRect {
  rect(
    shot.x - LASER_WIDTH * 0.5,
    shot.y - LASER_HEIGHT * 0.5,
    LASER_WIDTH,
    LASER_HEIGHT,
  )
}

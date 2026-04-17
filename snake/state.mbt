///|
const VIEWPORT_WIDTH : Double = 960.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const BOARD_COLS : Int = 24

///|
const BOARD_ROWS : Int = 16

///|
const TOTAL_CELLS : Int = BOARD_COLS * BOARD_ROWS

///|
const INITIAL_LENGTH : Int = 4

///|
const CELL_SIZE : Double = 28.0

///|
const SEGMENT_SIZE : Double = 23.0

///|
const FOOD_SIZE : Double = 15.0

///|
let board_width : Double = BOARD_COLS.to_double() * CELL_SIZE

///|
let board_height : Double = BOARD_ROWS.to_double() * CELL_SIZE

///|
let board_left : Double = (VIEWPORT_WIDTH - board_width) * 0.5

///|
const BOARD_TOP : Double = 158.0

///|
let board_right : Double = board_left + board_width

///|
const FRAME_THICKNESS : Double = 4.0

///|
const START_TICK_SECONDS : Double = 0.15

///|
const TICK_STEP_SECONDS : Double = 0.005

///|
const MIN_TICK_SECONDS : Double = 0.07

///|
const FOODS_PER_SPEED_STEP : Int = 4

///|
const BACKGROUND_Z : Double = 0.0

///|
const BOARD_FRAME_Z : Double = 10.0

///|
const BOARD_Z : Double = 20.0

///|
const FOOD_Z : Double = 30.0

///|
const SNAKE_Z : Double = 40.0

///|
const HUD_Z : Double = 100.0

///|
const OVERLAY_Z : Double = 140.0

///|
enum GamePhase {
  Title
  Playing
  Paused
  GameOver
  Perfect
} derive(Eq, Debug)

///|
enum Direction {
  Up
  Right
  Down
  Left
} derive(Eq, Debug)

///|
struct Cell {
  row : Int
  col : Int
} derive(Eq, Hash, Debug)

///|
priv struct RunState {
  mut phase : GamePhase
  mut score : Int
  mut foods_eaten : Int
  mut tick_seconds : Double
  mut tick_accumulator : Double
  mut direction : Direction
  mut queued_direction : Direction?
  mut snake : Array[Cell]
  mut food : Cell?
}

///|
let rand : @random.Rand = @random.Rand::new()

///|
let run_state : RunState = {
  phase: Title,
  score: 0,
  foods_eaten: 0,
  tick_seconds: START_TICK_SECONDS,
  tick_accumulator: 0.0,
  direction: Right,
  queued_direction: None,
  snake: [],
  food: None,
}

///|
let background_entity : @entity.Entity = @entity.Entity::new()

///|
let board_frame_entity : @entity.Entity = @entity.Entity::new()

///|
let board_entity : @entity.Entity = @entity.Entity::new()

///|
let overlay_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let prompt_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_score_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_length_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_phase_entity : @entity.Entity = @entity.Entity::new()

///|
let food_entity : @entity.Entity = @entity.Entity::new()

///|
let segment_entities : Array[@entity.Entity] = []

///|
fn wrap_index(value : Int, limit : Int) -> Int {
  if value < 0 {
    limit - 1
  } else if value >= limit {
    0
  } else {
    value
  }
}

///|
const VIEWPORT_WIDTH : Double = 656.0

///|
const VIEWPORT_HEIGHT : Double = 616.0

///|
const ZOOM : Double = 1.5

///|
const FPS : UInt = 60

///|
const GRID_WIDTH : Int = 13

///|
const GRID_HEIGHT : Int = 11

///|
const CELL_SIZE : Double = 48.0

///|
const GRID_OFFSET_X : Double = 16.0

///|
const GRID_OFFSET_Y : Double = 84.0

///|
const FLOOR_INSET : Double = 2.0

///|
const TURN_ASSIST_PX : Double = 10.0

///|
const PLAYER_SPEED : Double = CELL_SIZE * 3.0

///|
const ENEMY_SPEED : Double = CELL_SIZE * 2.5

///|
const PLAYER_RADIUS : Double = CELL_SIZE / 2.0 - 0.5

///|
const ENEMY_RADIUS : Double = CELL_SIZE / 2.0 - 0.5

///|
const BOMB_RADIUS : Double = CELL_SIZE / 2.0 - 0.5

///|
const COLLISION_EPSILON : Double = 0.001

///|
const BOMB_FUSE_TIME : Double = 2.0

///|
const FLAME_DURATION : Double = 0.16

///|
const PLAYER_START_BOMBS : Int = 2

///|
const PLAYER_BLAST_RADIUS : Int = 2

///|
const FLOOR_COLOR : String = "rgb(36, 48, 56)"

///|
const HARD_WALL_COLOR : String = "rgb(86, 113, 140)"

///|
const SOFT_WALL_COLOR : String = "rgb(163, 111, 58)"

///|
const P1_COLOR : String = "rgb(70, 200, 255)"

///|
const P1_DEAD_COLOR : String = "rgb(80, 98, 110)"

///|
const P2_COLOR : String = "rgb(255, 201, 84)"

///|
const P2_DEAD_COLOR : String = "rgb(124, 112, 82)"

///|
const BOMB_COLOR : String = "rgb(28, 28, 32)"

///|
const FLAME_COLOR : String = "rgb(255, 170, 56)"

///|
const HUD_TEXT_COLOR : String = "rgb(239, 241, 244)"

///|
const HUD_MUTED_TEXT_COLOR : String = "rgb(166, 176, 184)"

///|
const MENU_SELECTED_COLOR : String = "rgb(255, 220, 120)"

///|
const MENU_NORMAL_COLOR : String = HUD_TEXT_COLOR

///|
const BOMBMAN_FONT_FAMILY : String = "ThaleahFat"

///|
const BOMBMAN_FONT_PATH : String = "bombman/assets/ThaleahFat.ttf"

///|
const LEVEL_EMPTY : Int = 0

///|
const LEVEL_HARD_WALL : Int = 1

///|
const LEVEL_SOFT_WALL : Int = 2

///|
const LEVEL_P1_SPAWN : Int = 3

///|
const LEVEL_P2_SPAWN : Int = 4

///|
const LEVEL_ENEMY_SPAWN : Int = 5

///|
priv enum TileKind {
  Empty
  HardWall
  SoftWall
} derive(Eq)

///|
priv enum GamePhase {
  MainMenu
  Playing
  RoundOver
} derive(Eq)

///|
priv enum GameMode {
  SinglePlayer
  Coop
  Versus
} derive(Eq)

///|
priv enum MenuOption {
  OnePlayer
  TwoPlayersA
  TwoPlayersB
  Exit
} derive(Eq)

///|
priv enum RoundOutcome {
  LevelClear
  Defeat
  P1Win
  P2Win
  Draw
}

///|
priv enum PlayerId {
  P1
  P2
} derive(Eq)

///|
priv enum Direction {
  Up
  Down
  Left
  Right
} derive(Eq)

///|
type Level = ReadOnlyArray[ReadOnlyArray[Int]]

///|
priv struct Rect {
  left : Double
  top : Double
  right : Double
  bottom : Double
}

///|
priv struct PlayerState {
  id : PlayerId
  entity : @entity.Entity
  active : Bool
  mut center : @math.Vec2D
  mut direction : Direction?
  mut desired_direction : Direction?
  speed : Double
  radius : Double
  mut alive : Bool
  mut active_bombs : Int
  max_bombs : Int
  blast_radius : Int
}

///|
priv struct EnemyState {
  entity : @entity.Entity
  mut cell_x : Int
  mut cell_y : Int
  mut center : @math.Vec2D
  mut direction : Direction
  mut desired_direction : Direction
  speed : Double
  radius : Double
  mut alive : Bool
}

///|
priv struct BombState {
  entity : @entity.Entity
  cell_x : Int
  cell_y : Int
  mut timer : Double
  radius : Int
  owner : PlayerId
  mut passable_for_owner : Bool
}

///|
priv struct FlameState {
  entity : @entity.Entity
  cell_x : Int
  cell_y : Int
  mut timer : Double
}

///|
priv struct InputStamps {
  mut sequence : Int
  mut up : Int
  mut down : Int
  mut left : Int
  mut right : Int
}

///|
let phase : Ref[GamePhase] = { val: MainMenu }

///|
let current_mode : Ref[GameMode] = { val: SinglePlayer }

///|
let menu_selection : Ref[MenuOption] = { val: OnePlayer }

///|
let round_outcome : Ref[RoundOutcome] = { val: LevelClear }

///|
let tiles : Array[TileKind] = []

///|
let enemies : Array[EnemyState] = []

///|
let bombs : Array[BombState] = []

///|
let flames : Array[FlameState] = []

///|
let players : Array[PlayerState] = [
  {
    id: P1,
    entity: @entity.Entity::new(),
    active: true,
    center: cell_center(1, 1),
    direction: None,
    desired_direction: None,
    speed: PLAYER_SPEED,
    radius: PLAYER_RADIUS,
    alive: true,
    active_bombs: 0,
    max_bombs: PLAYER_START_BOMBS,
    blast_radius: PLAYER_BLAST_RADIUS,
  },
  {
    id: P2,
    entity: @entity.Entity::new(),
    active: false,
    center: cell_center(11, 9),
    direction: None,
    desired_direction: None,
    speed: PLAYER_SPEED,
    radius: PLAYER_RADIUS,
    alive: true,
    active_bombs: 0,
    max_bombs: PLAYER_START_BOMBS,
    blast_radius: PLAYER_BLAST_RADIUS,
  },
]

///|
let level1 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 3, 0, 2, 0, 2, 0, 2, 0, 2, 0, 4, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 0, 2, 0, 2, 0, 2, 0, 5, 0, 2, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 2, 0, 2, 0, 2, 0, 2, 0, 2, 0, 2, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 0, 0, 0, 2, 0, 2, 0, 0, 5, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let level2 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 3, 0, 0, 2, 0, 2, 0, 2, 0, 0, 4, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 0, 2, 0, 0, 0, 2, 0, 0, 0, 0, 1],
  [1, 2, 1, 0, 1, 2, 1, 0, 1, 2, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 0, 1],
  [1, 0, 1, 2, 1, 0, 1, 2, 1, 0, 1, 0, 1],
  [1, 0, 0, 0, 2, 0, 2, 0, 2, 0, 0, 0, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 5, 0, 2, 0, 2, 0, 2, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let level3 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 3, 0, 2, 0, 0, 0, 2, 0, 0, 0, 4, 1],
  [1, 0, 1, 0, 1, 2, 1, 0, 1, 2, 1, 0, 1],
  [1, 2, 0, 2, 0, 0, 0, 2, 0, 0, 0, 2, 1],
  [1, 0, 1, 0, 1, 2, 1, 0, 1, 2, 1, 0, 1],
  [1, 0, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 1],
  [1, 0, 1, 2, 1, 0, 1, 0, 1, 2, 1, 0, 1],
  [1, 2, 0, 0, 0, 2, 0, 2, 0, 0, 0, 2, 1],
  [1, 0, 1, 2, 1, 0, 1, 0, 1, 2, 1, 0, 1],
  [1, 0, 5, 0, 0, 2, 0, 2, 0, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let level4 : Level = [
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  [1, 3, 0, 0, 2, 0, 2, 0, 2, 0, 0, 4, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 0, 2, 0, 2, 0, 2, 0, 2, 0, 0, 1],
  [1, 2, 1, 0, 1, 0, 1, 0, 1, 0, 1, 2, 1],
  [1, 0, 0, 0, 0, 5, 0, 0, 0, 0, 0, 0, 1],
  [1, 2, 1, 0, 1, 0, 1, 0, 1, 0, 1, 2, 1],
  [1, 0, 0, 2, 0, 2, 0, 2, 0, 2, 0, 0, 1],
  [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1],
  [1, 0, 5, 0, 2, 0, 2, 0, 2, 0, 0, 0, 1],
  [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
]

///|
let levels : ReadOnlyArray[Level] = [level1, level2, level3, level4]

///|
let current_level : Ref[Int] = { val: 0 }

///|
let direction_input_state : Array[InputStamps] = [
  { sequence: 0, up: 0, down: 0, left: 0, right: 0 },
  { sequence: 0, up: 0, down: 0, left: 0, right: 0 },
]

///|
let tile_entities : Array[@entity.Entity] = []

///|
let background_entity : @entity.Entity = @entity.Entity::new()

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let menu_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let hud_entity : @entity.Entity = @entity.Entity::new()

///|
let status_entity : @entity.Entity = @entity.Entity::new()

///|
let hint_entity : @entity.Entity = @entity.Entity::new()

///|
let p2_bomb_test_override : Ref[Bool] = { val: false }

///|
let exit_request_count : Ref[Int] = { val: 0 }

///|
let suppress_exit_for_tests : Ref[Bool] = { val: false }

///|
fn cell_index(x : Int, y : Int) -> Int {
  y * GRID_WIDTH + x
}

///|
fn cell_in_bounds(x : Int, y : Int) -> Bool {
  x >= 0 && x < GRID_WIDTH && y >= 0 && y < GRID_HEIGHT
}

///|
fn cell_center(x : Int, y : Int) -> @math.Vec2D {
  @math.Vec2D(
    GRID_OFFSET_X + x.to_double() * CELL_SIZE + CELL_SIZE / 2.0,
    GRID_OFFSET_Y + y.to_double() * CELL_SIZE + CELL_SIZE / 2.0,
  )
}

///|
fn clamp_int(value : Int, min_ : Int, max_ : Int) -> Int {
  if value < min_ {
    min_
  } else if value > max_ {
    max_
  } else {
    value
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
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
fn player_index(id : PlayerId) -> Int {
  match id {
    P1 => 0
    P2 => 1
  }
}

///|
fn menu_options() -> Array[MenuOption] {
  [OnePlayer, TwoPlayersA, TwoPlayersB, Exit]
}

///|
fn menu_option_label(option : MenuOption) -> String {
  match option {
    OnePlayer => "1 PLAYER"
    TwoPlayersA => "2 PLAYERS A"
    TwoPlayersB => "2 PLAYERS B"
    Exit => "EXIT"
  }
}

///|
fn next_menu_option(option : MenuOption) -> MenuOption {
  match option {
    OnePlayer => TwoPlayersA
    TwoPlayersA => TwoPlayersB
    TwoPlayersB => Exit
    Exit => OnePlayer
  }
}

///|
fn previous_menu_option(option : MenuOption) -> MenuOption {
  match option {
    OnePlayer => Exit
    TwoPlayersA => OnePlayer
    TwoPlayersB => TwoPlayersA
    Exit => TwoPlayersB
  }
}

///|
fn mode_label(mode : GameMode) -> String {
  match mode {
    SinglePlayer => "1 PLAYER"
    Coop => "2 PLAYERS A"
    Versus => "2 PLAYERS B"
  }
}

///|
fn player_color(id : PlayerId, alive : Bool) -> String {
  match id {
    P1 => if alive { P1_COLOR } else { P1_DEAD_COLOR }
    P2 => if alive { P2_COLOR } else { P2_DEAD_COLOR }
  }
}

///|
fn cell_top_left(x : Int, y : Int) -> @math.Vec2D {
  @math.Vec2D(
    GRID_OFFSET_X + x.to_double() * CELL_SIZE,
    GRID_OFFSET_Y + y.to_double() * CELL_SIZE,
  )
}

///|
fn cell_bounds(x : Int, y : Int) -> Rect {
  let top_left = cell_top_left(x, y)
  {
    left: top_left[X],
    top: top_left[Y],
    right: top_left[X] + CELL_SIZE,
    bottom: top_left[Y] + CELL_SIZE,
  }
}

///|
fn center_to_circle_position(
  center : @math.Vec2D,
  radius : Double,
) -> @math.Vec2D {
  @math.Vec2D(center[X] - radius, center[Y] - radius)
}

///|
fn world_to_cell(center : @math.Vec2D) -> (Int, Int) {
  let raw_x = @cmath.floor((center[X] - GRID_OFFSET_X) / CELL_SIZE).to_int()
  let raw_y = @cmath.floor((center[Y] - GRID_OFFSET_Y) / CELL_SIZE).to_int()
  (clamp_int(raw_x, 0, GRID_WIDTH - 1), clamp_int(raw_y, 0, GRID_HEIGHT - 1))
}

///|
fn nearest_lane_center_x(x : Double) -> Double {
  let raw = @cmath.round((x - GRID_OFFSET_X - CELL_SIZE / 2.0) / CELL_SIZE).to_int()
  let cell_x = clamp_int(raw, 0, GRID_WIDTH - 1)
  cell_center(cell_x, 0)[X]
}

///|
fn nearest_lane_center_y(y : Double) -> Double {
  let raw = @cmath.round((y - GRID_OFFSET_Y - CELL_SIZE / 2.0) / CELL_SIZE).to_int()
  let cell_y = clamp_int(raw, 0, GRID_HEIGHT - 1)
  cell_center(0, cell_y)[Y]
}

///|
fn floor_tile_size() -> @math.Vec2D {
  @math.Vec2D(CELL_SIZE - FLOOR_INSET * 2.0, CELL_SIZE - FLOOR_INSET * 2.0)
}

///|
fn floor_tile_position(x : Int, y : Int) -> @math.Vec2D {
  cell_top_left(x, y) + @math.Vec2D(FLOOR_INSET, FLOOR_INSET)
}

///|
fn direction_delta(direction : Direction) -> (Int, Int) {
  match direction {
    Up => (0, -1)
    Down => (0, 1)
    Left => (-1, 0)
    Right => (1, 0)
  }
}

///|
fn direction_vector(direction : Direction) -> @math.Vec2D {
  match direction {
    Up => @math.Vec2D(0.0, -1.0)
    Down => @math.Vec2D(0.0, 1.0)
    Left => @math.Vec2D(-1.0, 0.0)
    Right => @math.Vec2D(1.0, 0.0)
  }
}

///|
fn is_horizontal(direction : Direction) -> Bool {
  match direction {
    Left | Right => true
    Up | Down => false
  }
}

///|
fn are_perpendicular(a : Direction, b : Direction) -> Bool {
  is_horizontal(a) != is_horizontal(b)
}

///|
fn turn_left(direction : Direction) -> Direction {
  match direction {
    Up => Left
    Down => Right
    Left => Down
    Right => Up
  }
}

///|
fn turn_right(direction : Direction) -> Direction {
  match direction {
    Up => Right
    Down => Left
    Left => Up
    Right => Down
  }
}

///|
fn opposite_direction(direction : Direction) -> Direction {
  match direction {
    Up => Down
    Down => Up
    Left => Right
    Right => Left
  }
}

///|
fn default_enemy_direction() -> Direction {
  Down
}

///|
fn current_level_number() -> Int {
  current_level.val + 1
}

///|
fn next_level_index(level_index : Int) -> Int {
  (level_index + 1) % levels.length()
}

///|
fn previous_level_index(level_index : Int) -> Int {
  if level_index <= 0 {
    levels.length() - 1
  } else {
    level_index - 1
  }
}

///|
fn alive_player_count() -> Int {
  players.fold(init=0, fn(acc, player) {
    if player.active && player.alive {
      acc + 1
    } else {
      acc
    }
  })
}

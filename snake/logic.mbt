///|
fn is_opposite_direction(current : Direction, next : Direction) -> Bool {
  match (current, next) {
    (Up, Down) => true
    (Down, Up) => true
    (Left, Right) => true
    (Right, Left) => true
    _ => false
  }
}

///|
fn initial_snake() -> Array[Cell] {
  let row = BOARD_ROWS / 2
  let head_col = BOARD_COLS / 2 + INITIAL_LENGTH / 2 - 1
  [
    Cell::{ row, col: head_col },
    Cell::{ row, col: head_col - 1 },
    Cell::{ row, col: head_col - 2 },
    Cell::{ row, col: head_col - 3 },
  ]
}

///|
fn snake_contains(target : Cell) -> Bool {
  for segment in run_state.snake {
    if segment == target {
      return true
    }
  }
  false
}

///|
fn speed_for_foods(foods_eaten : Int) -> Double {
  let interval = START_TICK_SECONDS -
    (foods_eaten / FOODS_PER_SPEED_STEP).to_double() * TICK_STEP_SECONDS
  if interval < MIN_TICK_SECONDS {
    MIN_TICK_SECONDS
  } else {
    interval
  }
}

///|
fn moved_cell(cell : Cell, direction : Direction) -> Cell {
  match direction {
    Up => Cell::{ row: wrap_index(cell.row - 1, BOARD_ROWS), col: cell.col }
    Right => Cell::{ row: cell.row, col: wrap_index(cell.col + 1, BOARD_COLS) }
    Down => Cell::{ row: wrap_index(cell.row + 1, BOARD_ROWS), col: cell.col }
    Left => Cell::{ row: cell.row, col: wrap_index(cell.col - 1, BOARD_COLS) }
  }
}

///|
fn snake_head() -> Cell {
  run_state.snake[0]
}

///|
fn spawn_food() -> Cell? {
  if run_state.snake.length() >= TOTAL_CELLS {
    return None
  }
  let available : Array[Cell] = []
  for row in 0..<BOARD_ROWS {
    for col in 0..<BOARD_COLS {
      let candidate = Cell::{ row, col }
      if !snake_contains(candidate) {
        available.push(candidate)
      }
    }
  }
  if available.is_empty() {
    None
  } else {
    Some(available[rand.int(limit=available.length())])
  }
}

///|
fn initialize_run(phase : GamePhase) -> Unit {
  run_state.phase = phase
  run_state.score = 0
  run_state.foods_eaten = 0
  run_state.tick_seconds = START_TICK_SECONDS
  run_state.tick_accumulator = 0.0
  run_state.direction = Right
  run_state.queued_direction = None
  run_state.snake = initial_snake()
  run_state.food = spawn_food()
}

///|
fn reset_to_title() -> Unit {
  initialize_run(Title)
}

///|
fn start_new_run() -> Unit {
  initialize_run(Playing)
  play_start_sound()
}

///|
fn toggle_pause_state() -> Unit {
  match run_state.phase {
    Playing => {
      run_state.phase = Paused
      play_pause_sound()
    }
    Paused => {
      run_state.phase = Playing
      play_pause_sound()
    }
    _ => ()
  }
}

///|
fn request_turn(next : Direction) -> Bool {
  if run_state.phase != Playing {
    return false
  }
  if run_state.queued_direction is Some(_) {
    return false
  }
  if next == run_state.direction {
    return false
  }
  if run_state.snake.length() > 1 &&
    is_opposite_direction(run_state.direction, next) {
    return false
  }
  run_state.queued_direction = Some(next)
  true
}

///|
fn apply_queued_turn() -> Unit {
  match run_state.queued_direction {
    Some(next) => {
      if next != run_state.direction &&
        !(run_state.snake.length() > 1 &&
        is_opposite_direction(run_state.direction, next)) {
        run_state.direction = next
      }
      run_state.queued_direction = None
    }
    None => ()
  }
}

///|
fn next_head_collides(next_head : Cell, grows : Bool) -> Bool {
  let collision_count = if grows {
    run_state.snake.length()
  } else {
    run_state.snake.length() - 1
  }
  for index in 0..<collision_count {
    if run_state.snake[index] == next_head {
      return true
    }
  }
  false
}

///|
fn advance_snake_tick() -> Unit {
  if run_state.phase != Playing {
    return
  }

  apply_queued_turn()
  let next_head = moved_cell(snake_head(), run_state.direction)
  let grows = match run_state.food {
    Some(food) => food == next_head
    None => false
  }

  if next_head_collides(next_head, grows) {
    run_state.phase = GameOver
    run_state.tick_accumulator = 0.0
    run_state.queued_direction = None
    play_game_over_sound()
    return
  }

  let new_body : Array[Cell] = [next_head]
  let keep_count = run_state.snake.length() - (if grows { 0 } else { 1 })
  for index in 0..<keep_count {
    new_body.push(run_state.snake[index])
  }
  run_state.snake = new_body
  run_state.queued_direction = None

  if grows {
    run_state.score += 1
    run_state.foods_eaten += 1
    run_state.tick_seconds = speed_for_foods(run_state.foods_eaten)
    if run_state.snake.length() >= TOTAL_CELLS {
      run_state.food = None
      run_state.phase = Perfect
      run_state.tick_accumulator = 0.0
      play_perfect_sound()
    } else {
      run_state.food = spawn_food()
      play_eat_sound()
    }
  }
}

///|
fn tick_run(delta_seconds : Double) -> Unit {
  if run_state.phase != Playing {
    return
  }
  run_state.tick_accumulator += delta_seconds
  while run_state.phase == Playing &&
        run_state.tick_accumulator >= run_state.tick_seconds {
    run_state.tick_accumulator -= run_state.tick_seconds
    advance_snake_tick()
  }
}

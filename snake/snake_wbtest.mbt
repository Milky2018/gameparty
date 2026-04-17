///|
fn reset_logic_state_for_test() -> Unit {
  initialize_run(Playing)
}

///|
fn set_snake_for_test(snake : Array[Cell], direction : Direction) -> Unit {
  initialize_run(Playing)
  run_state.snake = snake.copy()
  run_state.direction = direction
  run_state.queued_direction = None
  run_state.food = None
  run_state.score = 0
  run_state.foods_eaten = 0
  run_state.tick_seconds = START_TICK_SECONDS
  run_state.tick_accumulator = 0.0
}

///|
fn nearly_full_snake_for_test() -> Array[Cell] {
  let snake : Array[Cell] = []
  snake.push(Cell::{ row: 0, col: 1 })
  for col in 2..<BOARD_COLS {
    snake.push(Cell::{ row: 0, col })
  }
  for row in 1..<BOARD_ROWS {
    if row % 2 == 1 {
      for offset in 0..<BOARD_COLS {
        snake.push(Cell::{ row, col: BOARD_COLS - 1 - offset })
      }
    } else {
      for col in 0..<BOARD_COLS {
        snake.push(Cell::{ row, col })
      }
    }
  }
  snake
}

///|
test "wraparound works on all board edges" {
  set_snake_for_test([Cell::{ row: 0, col: 5 }], Up)
  advance_snake_tick()
  assert_true(run_state.snake[0] == Cell::{ row: BOARD_ROWS - 1, col: 5 })

  set_snake_for_test([Cell::{ row: 7, col: BOARD_COLS - 1 }], Right)
  advance_snake_tick()
  assert_true(run_state.snake[0] == Cell::{ row: 7, col: 0 })

  set_snake_for_test([Cell::{ row: BOARD_ROWS - 1, col: 8 }], Down)
  advance_snake_tick()
  assert_true(run_state.snake[0] == Cell::{ row: 0, col: 8 })

  set_snake_for_test([Cell::{ row: 3, col: 0 }], Left)
  advance_snake_tick()
  assert_true(run_state.snake[0] == Cell::{ row: 3, col: BOARD_COLS - 1 })
}

///|
test "food never spawns on the snake body" {
  set_snake_for_test(
    [
      Cell::{ row: 5, col: 5 },
      Cell::{ row: 5, col: 4 },
      Cell::{ row: 5, col: 3 },
      Cell::{ row: 5, col: 2 },
    ],
    Right,
  )
  let food = spawn_food().unwrap()
  for segment in run_state.snake {
    assert_true(segment != food)
  }
}

///|
test "eating food grows the snake and increments score" {
  set_snake_for_test(
    [
      Cell::{ row: 6, col: 6 },
      Cell::{ row: 6, col: 5 },
      Cell::{ row: 6, col: 4 },
      Cell::{ row: 6, col: 3 },
    ],
    Right,
  )
  run_state.food = Some(Cell::{ row: 6, col: 7 })
  advance_snake_tick()
  assert_eq(run_state.score, 1)
  assert_eq(run_state.snake.length(), 5)
  assert_true(run_state.snake[0] == Cell::{ row: 6, col: 7 })
}

///|
test "opposite direction input is rejected" {
  reset_logic_state_for_test()
  assert_true(!request_turn(Left))
  assert_true(run_state.queued_direction == None)
}

///|
test "queued turn applies on the next simulation tick" {
  reset_logic_state_for_test()
  assert_true(request_turn(Up))
  assert_true(run_state.direction == Right)
  advance_snake_tick()
  assert_true(run_state.direction == Up)
  assert_true(
    run_state.snake[0] ==
    Cell::{
      row: BOARD_ROWS / 2 - 1,
      col: BOARD_COLS / 2 + INITIAL_LENGTH / 2 - 1,
    },
  )
}

///|
test "stepping into the vacating tail cell is legal" {
  set_snake_for_test(
    [
      Cell::{ row: 2, col: 2 },
      Cell::{ row: 2, col: 1 },
      Cell::{ row: 1, col: 1 },
      Cell::{ row: 1, col: 2 },
    ],
    Up,
  )
  advance_snake_tick()
  assert_true(run_state.phase == Playing)
  assert_true(run_state.snake[0] == Cell::{ row: 1, col: 2 })
}

///|
test "true self collision causes game over" {
  set_snake_for_test(
    [
      Cell::{ row: 2, col: 2 },
      Cell::{ row: 2, col: 1 },
      Cell::{ row: 1, col: 1 },
      Cell::{ row: 1, col: 2 },
    ],
    Left,
  )
  advance_snake_tick()
  assert_true(run_state.phase == GameOver)
}

///|
test "tick interval accelerates and clamps" {
  assert_eq(speed_for_foods(0), START_TICK_SECONDS)
  assert_eq(speed_for_foods(FOODS_PER_SPEED_STEP), 0.145)
  assert_eq(speed_for_foods(400), MIN_TICK_SECONDS)
}

///|
test "restart resets score length direction and phase" {
  reset_logic_state_for_test()
  run_state.phase = GameOver
  run_state.score = 9
  run_state.foods_eaten = 12
  run_state.direction = Down
  run_state.snake = [Cell::{ row: 0, col: 0 }]
  start_new_run()
  assert_true(run_state.phase == Playing)
  assert_eq(run_state.score, 0)
  assert_true(run_state.direction == Right)
  assert_eq(run_state.snake.length(), INITIAL_LENGTH)
}

///|
test "full board occupation reaches perfect state" {
  set_snake_for_test(nearly_full_snake_for_test(), Left)
  run_state.food = Some(Cell::{ row: 0, col: 0 })
  advance_snake_tick()
  assert_true(run_state.phase == Perfect)
  assert_eq(run_state.snake.length(), TOTAL_CELLS)
  assert_true(run_state.food == None)
}

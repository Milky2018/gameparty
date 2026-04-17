///|
fn reset_logic_state_for_test(level_index : Int) -> Unit {
  ensure_runtime_storage()
  game_state.lives = STARTING_LIVES
  load_level(level_index, Ready)
}

///|
fn set_playing_state_for_test(level_index : Int) -> Unit {
  reset_logic_state_for_test(level_index)
  ignore(release_stuck_balls())
}

///|
fn clear_bricks_for_test() -> Unit {
  clear_bricks()
  game_state.remaining_breakables = 0
}

///|
fn activate_brick_for_test(
  slot : Int,
  row : Int,
  col : Int,
  kind : BrickKind,
  powerup? : PowerUpKind? = None,
) -> Unit {
  bricks[slot].row = row
  bricks[slot].col = col
  bricks[slot].kind = kind
  bricks[slot].powerup = powerup
  bricks[slot].hits_remaining = brick_hit_points(kind)
  bricks[slot].active = true
  if is_breakable(kind) {
    game_state.remaining_breakables += 1
  }
}

///|
fn set_single_ball_for_test(
  x : Double,
  y : Double,
  vx : Double,
  vy : Double,
) -> Unit {
  clear_balls()
  balls[0].active = true
  balls[0].x = x
  balls[0].y = y
  balls[0].vx = vx
  balls[0].vy = vy
  balls[0].stuck_to_paddle = false
  balls[0].stuck_offset = 0.0
}

///|
fn active_powerup_count_for_test() -> Int {
  let mut count = 0
  for powerup in powerups {
    if powerup.active {
      count += 1
    }
  }
  count
}

///|
test "ball reflects from side wall and ceiling" {
  set_playing_state_for_test(0)
  clear_bricks_for_test()

  set_single_ball_for_test(
    BOARD_LEFT + BALL_SIZE * 0.5 + 2.0,
    BOARD_TOP + 120.0,
    -220.0,
    -180.0,
  )
  update_balls(0.05)
  assert_true(balls[0].vx > 0.0)

  set_single_ball_for_test(
    BOARD_LEFT + 220.0,
    BOARD_TOP + BALL_SIZE * 0.5 + 2.0,
    120.0,
    -200.0,
  )
  update_balls(0.05)
  assert_true(balls[0].vy > 0.0)
}

///|
test "bottom out removes one life and transitions to serving" {
  set_playing_state_for_test(0)
  clear_bricks_for_test()

  set_single_ball_for_test(
    BOARD_LEFT + 200.0,
    BOARD_BOTTOM + BALL_SIZE + 8.0,
    0.0,
    200.0,
  )
  update_balls(0.01)
  assert_eq(game_state.lives, STARTING_LIVES - 1)
  assert_true(game_state.phase == Serving)
  assert_true(balls[0].active)
  assert_true(balls[0].stuck_to_paddle)
}

///|
test "paddle collision changes horizontal velocity by impact offset" {
  set_playing_state_for_test(0)
  clear_bricks_for_test()

  paddle_state.center_x = BOARD_LEFT + BOARD_WIDTH * 0.5
  let paddle = paddle_rect()
  set_single_ball_for_test(
    paddle.left + paddle.width * 0.85,
    paddle.top - BALL_SIZE * 0.5 - 1.0,
    0.0,
    220.0,
  )
  update_balls(0.03)
  assert_true(balls[0].vy < 0.0)
  assert_true(balls[0].vx > 0.0)
}

///|
test "strong brick requires two hits" {
  reset_logic_state_for_test(0)
  clear_bricks_for_test()
  activate_brick_for_test(0, 0, 0, Strong)
  assert_true(!damage_brick(0))
  assert_true(bricks[0].active)
  assert_eq(bricks[0].hits_remaining, 1)
  assert_true(damage_brick(0))
  assert_true(!bricks[0].active)
}

///|
test "steel brick is never destroyed" {
  reset_logic_state_for_test(0)
  clear_bricks_for_test()
  activate_brick_for_test(0, 0, 0, Steel)
  assert_true(!damage_brick(0))
  assert_true(bricks[0].active)
  assert_eq(bricks[0].hits_remaining, 999)
}

///|
test "clearing last brick advances or wins final level" {
  reset_logic_state_for_test(0)
  clear_bricks_for_test()
  game_state.phase = Playing
  activate_brick_for_test(0, 0, 0, Normal)
  assert_true(damage_brick(0))
  assert_true(game_state.phase == LevelCleared)

  reset_logic_state_for_test(level_count() - 1)
  clear_bricks_for_test()
  game_state.phase = Playing
  activate_brick_for_test(0, 0, 0, Normal)
  assert_true(damage_brick(0))
  assert_true(game_state.phase == Won)
}

///|
test "power carrier spawns authored powerup" {
  reset_logic_state_for_test(0)
  clear_bricks_for_test()
  activate_brick_for_test(0, 0, 0, PowerCarrier, powerup=Some(SlowBall))
  ignore(damage_brick(0))
  assert_eq(active_powerup_count_for_test(), 1)
  assert_true(powerups[0].kind == SlowBall)
}

///|
test "wide and slow timers expire correctly" {
  reset_logic_state_for_test(0)
  apply_powerup(WidePaddle)
  apply_powerup(SlowBall)
  assert_eq(paddle_state.width, PADDLE_WIDE_WIDTH)
  assert_true(game_state.slow_seconds > 0.0)
  tick_timed_powerups(WIDE_PADDLE_SECONDS + 0.2)
  tick_timed_powerups(SLOW_BALL_SECONDS + 0.2)
  assert_eq(paddle_state.width, PADDLE_BASE_WIDTH)
  assert_eq(game_state.slow_seconds, 0.0)
}

///|
test "multiball creates extra active balls" {
  set_playing_state_for_test(0)
  clear_bricks_for_test()
  apply_powerup(MultiBall)
  assert_true(active_ball_count() >= 3)
}

///|
test "catch captures a ball on paddle contact" {
  set_playing_state_for_test(0)
  clear_bricks_for_test()
  game_state.paddle_mode = PaddleMode::Catch
  game_state.paddle_mode_seconds = 4.0
  let paddle = paddle_rect()
  set_single_ball_for_test(
    paddle.left + paddle.width * 0.5,
    paddle.top - BALL_SIZE * 0.5 - 1.0,
    0.0,
    200.0,
  )
  update_balls(0.03)
  assert_true(balls[0].stuck_to_paddle)
  assert_true(game_state.phase == Serving)
}

///|
test "laser shots damage breakable bricks and ignore steel" {
  reset_logic_state_for_test(0)
  clear_bricks_for_test()
  activate_brick_for_test(0, 0, 0, Normal)
  activate_brick_for_test(1, 0, 1, Steel)
  laser_shots[0].active = true
  laser_shots[0].x = brick_rect(0, 0).left + BRICK_WIDTH * 0.5
  laser_shots[0].y = brick_rect(0, 0).top + BRICK_HEIGHT + 4.0
  laser_shots[0].vy = -LASER_SPEED
  update_lasers(0.05)
  assert_true(!bricks[0].active)

  laser_shots[1].active = true
  laser_shots[1].x = brick_rect(0, 1).left + BRICK_WIDTH * 0.5
  laser_shots[1].y = brick_rect(0, 1).top + BRICK_HEIGHT + 4.0
  laser_shots[1].vy = -LASER_SPEED
  update_lasers(0.05)
  assert_true(bricks[1].active)
}

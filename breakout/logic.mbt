///|
fn clamp_double(value : Double, minimum : Double, maximum : Double) -> Double {
  if value < minimum {
    minimum
  } else if value > maximum {
    maximum
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
fn default_brick_state() -> BrickState {
  {
    row: 0,
    col: 0,
    kind: Normal,
    powerup: None,
    hits_remaining: 0,
    active: false,
  }
}

///|
fn default_ball_state() -> BallState {
  {
    active: false,
    x: BOARD_LEFT + BOARD_WIDTH * 0.5,
    y: PADDLE_CENTER_Y - 24.0,
    vx: 0.0,
    vy: 0.0,
    stuck_to_paddle: false,
    stuck_offset: 0.0,
  }
}

///|
fn default_powerup_state() -> PowerUpState {
  { active: false, kind: WidePaddle, x: 0.0, y: 0.0, vy: POWERUP_FALL_SPEED }
}

///|
fn default_laser_state() -> LaserShotState {
  { active: false, x: 0.0, y: 0.0, vy: -LASER_SPEED }
}

///|
fn ensure_runtime_storage() -> Unit {
  if bricks.is_empty() {
    for _ in 0..<MAX_BRICK_COUNT {
      bricks.push(default_brick_state())
      brick_entities.push(@entity.Entity::Entity())
    }
  }
  if balls.is_empty() {
    for _ in 0..<MAX_BALLS {
      balls.push(default_ball_state())
      ball_entities.push(@entity.Entity::Entity())
    }
  }
  if powerups.is_empty() {
    for _ in 0..<MAX_POWERUPS {
      powerups.push(default_powerup_state())
      powerup_entities.push(@entity.Entity::Entity())
    }
  }
  if laser_shots.is_empty() {
    for _ in 0..<MAX_LASERS {
      laser_shots.push(default_laser_state())
      laser_entities.push(@entity.Entity::Entity())
    }
  }
}

///|
fn brick_hit_points(kind : BrickKind) -> Int {
  match kind {
    Strong => 2
    Steel => 999
    _ => 1
  }
}

///|
fn is_breakable(kind : BrickKind) -> Bool {
  kind != Steel
}

///|
fn level_ball_speed() -> Double {
  BASE_BALL_SPEED * levels[game_state.current_level].speed_scale
}

///|
fn slow_ball_multiplier() -> Double {
  if game_state.slow_seconds > 0.0 {
    SLOW_BALL_MULTIPLIER
  } else {
    1.0
  }
}

///|
fn clear_bricks() -> Unit {
  for index in 0..<MAX_BRICK_COUNT {
    bricks[index] = default_brick_state()
  }
}

///|
fn clear_balls() -> Unit {
  for index in 0..<MAX_BALLS {
    balls[index] = default_ball_state()
  }
}

///|
fn clear_powerups() -> Unit {
  for index in 0..<MAX_POWERUPS {
    powerups[index] = default_powerup_state()
  }
}

///|
fn clear_lasers() -> Unit {
  for index in 0..<MAX_LASERS {
    laser_shots[index] = default_laser_state()
  }
}

///|
fn reset_timed_powerups() -> Unit {
  game_state.wide_seconds = 0.0
  game_state.slow_seconds = 0.0
  game_state.paddle_mode = PaddleMode::None
  game_state.paddle_mode_seconds = 0.0
  game_state.laser_cooldown = 0.0
  paddle_state.width = PADDLE_BASE_WIDTH
}

///|
fn active_ball_count() -> Int {
  let mut count = 0
  for ball in balls {
    if ball.active {
      count += 1
    }
  }
  count
}

///|
fn stuck_ball_count() -> Int {
  let mut count = 0
  for ball in balls {
    if ball.active && ball.stuck_to_paddle {
      count += 1
    }
  }
  count
}

///|
fn free_ball_count() -> Int {
  let mut count = 0
  for ball in balls {
    if ball.active && !ball.stuck_to_paddle {
      count += 1
    }
  }
  count
}

///|
fn first_active_ball_index() -> Int? {
  for index in 0..<MAX_BALLS {
    if balls[index].active {
      return Some(index)
    }
  }
  None
}

///|
fn attach_stuck_balls_to_paddle() -> Unit {
  let paddle_top = PADDLE_CENTER_Y - PADDLE_HEIGHT * 0.5
  for index in 0..<MAX_BALLS {
    if balls[index].active && balls[index].stuck_to_paddle {
      balls[index].x = clamp_double(
        paddle_state.center_x + balls[index].stuck_offset,
        BOARD_LEFT + BALL_SIZE * 0.5,
        BOARD_RIGHT - BALL_SIZE * 0.5,
      )
      balls[index].y = paddle_top - BALL_SIZE * 0.5 - 2.0
      balls[index].vx = 0.0
      balls[index].vy = 0.0
    }
  }
}

///|
fn prepare_single_stuck_ball(phase : GamePhase) -> Unit {
  clear_balls()
  balls[0].active = true
  balls[0].stuck_to_paddle = true
  balls[0].stuck_offset = 0.0
  attach_stuck_balls_to_paddle()
  game_state.phase = phase
  game_state.phase_seconds = 0.0
}

///|
fn load_level(index : Int, phase : GamePhase) -> Unit {
  clear_bricks()
  clear_powerups()
  clear_lasers()
  reset_timed_powerups()
  game_state.current_level = index
  game_state.remaining_breakables = 0
  let specs = levels[index].bricks
  for brick_index in 0..<specs.length() {
    let spec = specs[brick_index]
    bricks[brick_index].row = spec.row
    bricks[brick_index].col = spec.col
    bricks[brick_index].kind = spec.kind
    bricks[brick_index].powerup = spec.powerup
    bricks[brick_index].hits_remaining = brick_hit_points(spec.kind)
    bricks[brick_index].active = true
    if is_breakable(spec.kind) {
      game_state.remaining_breakables += 1
    }
  }
  paddle_state.center_x = BOARD_LEFT + BOARD_WIDTH * 0.5
  paddle_state.width = PADDLE_BASE_WIDTH
  prepare_single_stuck_ball(phase)
}

///|
fn reset_run_state() -> Unit {
  ensure_runtime_storage()
  game_state.lives = STARTING_LIVES
  load_level(0, Ready)
}

///|
fn begin_level_cleared_or_won() -> Unit {
  clear_powerups()
  clear_lasers()
  clear_balls()
  reset_timed_powerups()
  game_state.phase_seconds = 0.0
  if game_state.current_level + 1 >= level_count() {
    game_state.phase = Won
    play_sound_ref(sound_win)
  } else {
    game_state.phase = LevelCleared
    play_sound_ref(sound_brick)
  }
}

///|
fn maybe_clear_level() -> Unit {
  if game_state.remaining_breakables <= 0 && game_state.phase == Playing {
    begin_level_cleared_or_won()
  }
}

///|
fn advance_level() -> Unit {
  if game_state.current_level + 1 < level_count() {
    load_level(game_state.current_level + 1, Ready)
  } else {
    game_state.phase = Won
    game_state.phase_seconds = 0.0
  }
}

///|
fn lose_life_or_game_over() -> Unit {
  clear_powerups()
  clear_lasers()
  reset_timed_powerups()
  if game_state.lives > 1 {
    game_state.lives -= 1
    play_sound_ref(sound_life_lost)
    prepare_single_stuck_ball(Serving)
  } else {
    game_state.lives = 0
    clear_balls()
    game_state.phase = Lost
    game_state.phase_seconds = 0.0
    play_sound_ref(sound_game_over)
  }
}

///|
fn spawn_powerup(kind : PowerUpKind, x : Double, y : Double) -> Unit {
  for index in 0..<MAX_POWERUPS {
    if !powerups[index].active {
      powerups[index].active = true
      powerups[index].kind = kind
      powerups[index].x = x
      powerups[index].y = y
      powerups[index].vy = POWERUP_FALL_SPEED
      return
    }
  }
}

///|
fn launch_ball(index : Int, desired_vx : Double) -> Unit {
  let speed = level_ball_speed()
  let clamped_vx = clamp_double(desired_vx, -speed * 0.75, speed * 0.75)
  balls[index].active = true
  balls[index].stuck_to_paddle = false
  balls[index].vx = clamped_vx
  balls[index].vy = -(speed - abs_double(clamped_vx) * 0.18)
}

///|
fn release_stuck_balls() -> Bool {
  let stuck_count = stuck_ball_count()
  if stuck_count == 0 {
    return false
  }
  let mut released_index = 0
  for index in 0..<MAX_BALLS {
    if balls[index].active && balls[index].stuck_to_paddle {
      let spread = released_index.to_double() -
        (stuck_count - 1).to_double() * 0.5
      let desired_vx = spread * MULTIBALL_SIDE_SPEED +
        balls[index].stuck_offset * 1.6
      launch_ball(index, desired_vx)
      released_index += 1
    }
  }
  game_state.phase = Playing
  game_state.phase_seconds = 0.0
  play_sound_ref(sound_serve)
  true
}

///|
fn spawn_multiball_from(source_index : Int) -> Unit {
  let source = balls[source_index]
  let variants = [-MULTIBALL_SIDE_SPEED, MULTIBALL_SIDE_SPEED]
  for variant in variants {
    for index in 0..<MAX_BALLS {
      if !balls[index].active {
        balls[index].active = true
        balls[index].stuck_to_paddle = false
        balls[index].stuck_offset = 0.0
        balls[index].x = source.x
        balls[index].y = source.y
        balls[index].vx = source.vx + variant
        balls[index].vy = if source.vy < 0.0 {
          source.vy
        } else {
          -abs_double(source.vy)
        }
        break
      }
    }
  }
}

///|
fn apply_powerup(kind : PowerUpKind) -> Unit {
  match kind {
    WidePaddle => {
      game_state.wide_seconds = WIDE_PADDLE_SECONDS
      paddle_state.width = PADDLE_WIDE_WIDTH
    }
    SlowBall => game_state.slow_seconds = SLOW_BALL_SECONDS
    MultiBall =>
      match first_active_ball_index() {
        Some(index) => spawn_multiball_from(index)
        None => ()
      }
    Catch => {
      game_state.paddle_mode = PaddleMode::Catch
      game_state.paddle_mode_seconds = PADDLE_MODE_SECONDS
    }
    Laser => {
      game_state.paddle_mode = PaddleMode::Laser
      game_state.paddle_mode_seconds = PADDLE_MODE_SECONDS
      game_state.laser_cooldown = 0.0
    }
  }
  play_sound_ref(sound_pickup)
}

///|
fn spawn_laser_pair() -> Bool {
  let mut spawned = 0
  let paddle = paddle_rect()
  let launch_positions = [
    paddle.left + paddle.width * 0.28,
    paddle.left + paddle.width * 0.72,
  ]
  for x in launch_positions {
    for index in 0..<MAX_LASERS {
      if !laser_shots[index].active {
        laser_shots[index].active = true
        laser_shots[index].x = x
        laser_shots[index].y = paddle.top
        laser_shots[index].vy = -LASER_SPEED
        spawned += 1
        break
      }
    }
  }
  if spawned > 0 {
    game_state.laser_cooldown = LASER_COOLDOWN_SECONDS
    play_sound_ref(sound_laser)
    true
  } else {
    false
  }
}

///|
fn damage_brick(index : Int) -> Bool {
  if !bricks[index].active || bricks[index].kind == Steel {
    return false
  }
  bricks[index].hits_remaining -= 1
  if bricks[index].hits_remaining > 0 {
    play_sound_ref(sound_wall)
    return false
  }
  bricks[index].active = false
  game_state.remaining_breakables -= 1
  match bricks[index].powerup {
    Some(kind) => {
      let rect = brick_rect(bricks[index].row, bricks[index].col)
      spawn_powerup(
        kind,
        rect.left + rect.width * 0.5,
        rect.top + rect.height * 0.5,
      )
    }
    None => ()
  }
  play_sound_ref(sound_brick)
  maybe_clear_level()
  true
}

///|
fn reflect_ball_from_paddle(index : Int) -> Unit {
  let paddle = paddle_rect()
  let ball_center = balls[index].x
  let normalized = clamp_double(
    (ball_center - (paddle.left + paddle.width * 0.5)) / (paddle.width * 0.5),
    -1.0,
    1.0,
  )
  balls[index].y = paddle.top - BALL_SIZE * 0.5 - 0.1
  if game_state.paddle_mode == PaddleMode::Catch {
    balls[index].stuck_to_paddle = true
    balls[index].stuck_offset = clamp_double(
      ball_center - paddle_state.center_x,
      -paddle_state.width * 0.35,
      paddle_state.width * 0.35,
    )
    balls[index].vx = 0.0
    balls[index].vy = 0.0
    game_state.phase = Serving
  } else {
    launch_ball(index, normalized * level_ball_speed() * 0.74)
    game_state.phase = Playing
  }
  play_sound_ref(sound_paddle)
}

///|
fn reflect_ball_from_brick(
  index : Int,
  prev_x : Double,
  prev_y : Double,
  brick : ButtonRect,
) -> Unit {
  let prev_rect = rect(
    prev_x - BALL_SIZE * 0.5,
    prev_y - BALL_SIZE * 0.5,
    BALL_SIZE,
    BALL_SIZE,
  )
  let hit_from_top = prev_rect.top + prev_rect.height <= brick.top
  let hit_from_bottom = prev_rect.top >= brick.top + brick.height
  if hit_from_top || hit_from_bottom {
    balls[index].vy = -balls[index].vy
  } else {
    balls[index].vx = -balls[index].vx
  }
  balls[index].x = prev_x
  balls[index].y = prev_y
}

///|
fn collide_ball_with_bricks(
  index : Int,
  prev_x : Double,
  prev_y : Double,
) -> Unit {
  let current_rect = ball_rect(balls[index])
  for brick_index in 0..<MAX_BRICK_COUNT {
    if !bricks[brick_index].active {
      continue
    }
    let brick_hitbox = brick_rect(
      bricks[brick_index].row,
      bricks[brick_index].col,
    )
    if !rects_overlap(current_rect, brick_hitbox) {
      continue
    }
    reflect_ball_from_brick(index, prev_x, prev_y, brick_hitbox)
    if bricks[brick_index].kind == Steel {
      play_sound_ref(sound_wall)
    } else {
      ignore(damage_brick(brick_index))
    }
    return
  }
}

///|
fn update_balls(delta : Double) -> Unit {
  let speed_multiplier = slow_ball_multiplier()
  let paddle_hitbox = paddle_rect()
  for index in 0..<MAX_BALLS {
    if !balls[index].active || balls[index].stuck_to_paddle {
      continue
    }
    let prev_x = balls[index].x
    let prev_y = balls[index].y
    balls[index].x += balls[index].vx * delta * speed_multiplier
    balls[index].y += balls[index].vy * delta * speed_multiplier

    if balls[index].x - BALL_SIZE * 0.5 < BOARD_LEFT {
      balls[index].x = BOARD_LEFT + BALL_SIZE * 0.5
      balls[index].vx = abs_double(balls[index].vx)
      play_sound_ref(sound_wall)
    } else if balls[index].x + BALL_SIZE * 0.5 > BOARD_RIGHT {
      balls[index].x = BOARD_RIGHT - BALL_SIZE * 0.5
      balls[index].vx = -abs_double(balls[index].vx)
      play_sound_ref(sound_wall)
    }

    if balls[index].y - BALL_SIZE * 0.5 < BOARD_TOP {
      balls[index].y = BOARD_TOP + BALL_SIZE * 0.5
      balls[index].vy = abs_double(balls[index].vy)
      play_sound_ref(sound_wall)
    }

    if balls[index].y - BALL_SIZE * 0.5 > BOARD_BOTTOM {
      balls[index].active = false
      continue
    }

    if balls[index].vy > 0.0 &&
      rects_overlap(ball_rect(balls[index]), paddle_hitbox) {
      reflect_ball_from_paddle(index)
      continue
    }

    collide_ball_with_bricks(index, prev_x, prev_y)
    if game_state.phase != Playing {
      return
    }
  }

  if active_ball_count() == 0 {
    lose_life_or_game_over()
  } else if free_ball_count() == 0 && stuck_ball_count() > 0 {
    game_state.phase = Serving
  }
}

///|
fn update_powerups(delta : Double) -> Unit {
  let paddle_hitbox = paddle_rect()
  for index in 0..<MAX_POWERUPS {
    if !powerups[index].active {
      continue
    }
    powerups[index].y += powerups[index].vy * delta
    if powerups[index].y - POWERUP_SIZE * 0.5 > BOARD_BOTTOM {
      powerups[index].active = false
      continue
    }
    if rects_overlap(powerup_rect(powerups[index]), paddle_hitbox) {
      let kind = powerups[index].kind
      powerups[index].active = false
      apply_powerup(kind)
    }
  }
}

///|
fn update_lasers(delta : Double) -> Unit {
  for shot_index in 0..<MAX_LASERS {
    if !laser_shots[shot_index].active {
      continue
    }
    laser_shots[shot_index].y += laser_shots[shot_index].vy * delta
    if laser_shots[shot_index].y + LASER_HEIGHT * 0.5 < BOARD_TOP {
      laser_shots[shot_index].active = false
      continue
    }
    let shot_hitbox = laser_rect(laser_shots[shot_index])
    for brick_index in 0..<MAX_BRICK_COUNT {
      if !bricks[brick_index].active {
        continue
      }
      if !rects_overlap(
          shot_hitbox,
          brick_rect(bricks[brick_index].row, bricks[brick_index].col),
        ) {
        continue
      }
      if bricks[brick_index].kind != Steel {
        ignore(damage_brick(brick_index))
        laser_shots[shot_index].active = false
      }
      break
    }
    if game_state.phase != Playing {
      return
    }
  }
}

///|
fn update_paddle_from_mouse() -> Unit {
  let mouse_x = @inputs.mouse.pos[X]
  paddle_state.center_x = clamp_double(
    mouse_x,
    BOARD_LEFT + paddle_state.width * 0.5,
    BOARD_RIGHT - paddle_state.width * 0.5,
  )
  attach_stuck_balls_to_paddle()
}

///|
fn tick_timed_powerups(delta : Double) -> Unit {
  if game_state.wide_seconds > 0.0 {
    game_state.wide_seconds -= delta
    if game_state.wide_seconds <= 0.0 {
      game_state.wide_seconds = 0.0
      paddle_state.width = PADDLE_BASE_WIDTH
    }
  }
  if game_state.slow_seconds > 0.0 {
    game_state.slow_seconds -= delta
    if game_state.slow_seconds < 0.0 {
      game_state.slow_seconds = 0.0
    }
  }
  if game_state.paddle_mode_seconds > 0.0 {
    game_state.paddle_mode_seconds -= delta
    if game_state.paddle_mode_seconds <= 0.0 {
      game_state.paddle_mode_seconds = 0.0
      game_state.paddle_mode = PaddleMode::None
    }
  }
  if game_state.laser_cooldown > 0.0 {
    game_state.laser_cooldown -= delta
    if game_state.laser_cooldown < 0.0 {
      game_state.laser_cooldown = 0.0
    }
  }
}

///|
fn update_playing(delta : Double) -> Unit {
  tick_timed_powerups(delta)
  update_powerups(delta)
  if game_state.phase != Playing {
    return
  }
  update_lasers(delta)
  if game_state.phase != Playing {
    return
  }
  update_balls(delta)
}

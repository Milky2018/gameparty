///|

///|
const STATUS_PANEL_WIDTH : Double = 116.0

///|
const STATUS_PANEL_HEIGHT : Double = 48.0

///|
const FACE_BUTTON_SIZE : Double = 48.0

///|
const INDICATOR_WIDTH : Double = 44.0

///|
const INDICATOR_HEIGHT : Double = 14.0

///|
const INDICATOR_GAP : Double = 12.0

///|
fn format_counter(value : Int) -> String {
  if value < 0 {
    "000"
  } else if value < 10 {
    "00\{value}"
  } else if value < 100 {
    "0\{value}"
  } else {
    "\{value}"
  }
}

///|
fn hud_rect() -> ButtonRect {
  rect(BOARD_LEFT - 8.0, 28.0, BOARD_WIDTH + 16.0, 58.0)
}

///|
fn lives_panel_rect() -> ButtonRect {
  let hud = hud_rect()
  rect(hud.left + 10.0, hud.top + 5.0, STATUS_PANEL_WIDTH, STATUS_PANEL_HEIGHT)
}

///|
fn reset_panel_rect() -> ButtonRect {
  let hud = hud_rect()
  rect(
    hud.left + hud.width * 0.5 - FACE_BUTTON_SIZE * 0.5,
    hud.top + 5.0,
    FACE_BUTTON_SIZE,
    STATUS_PANEL_HEIGHT,
  )
}

///|
fn remaining_panel_rect() -> ButtonRect {
  let hud = hud_rect()
  rect(
    hud.left + hud.width - STATUS_PANEL_WIDTH - 10.0,
    hud.top + 5.0,
    STATUS_PANEL_WIDTH,
    STATUS_PANEL_HEIGHT,
  )
}

///|
fn indicator_rect(slot : Int) -> ButtonRect {
  let total_width = INDICATOR_WIDTH * 3.0 + INDICATOR_GAP * 2.0
  let left = VIEWPORT_WIDTH * 0.5 -
    total_width * 0.5 +
    slot.to_double() * (INDICATOR_WIDTH + INDICATOR_GAP)
  rect(
    left,
    hud_rect().top + hud_rect().height + 8.0,
    INDICATOR_WIDTH,
    INDICATOR_HEIGHT,
  )
}

///|
fn reset_text() -> String {
  match game_state.phase {
    Won => "+"
    Lost => "x"
    _ => "o"
  }
}

///|
fn overlay_text() -> String {
  match game_state.phase {
    LevelCleared => "CLEAR"
    Won => "WIN"
    Lost => "LOST"
    _ => ""
  }
}

///|
fn powerup_color(kind : PowerUpKind) -> @render.Color {
  match kind {
    WidePaddle => color_rgba(82U, 131U, 217U, 1.0)
    SlowBall => color_rgba(44U, 173U, 179U, 1.0)
    MultiBall => color_rgba(177U, 96U, 214U, 1.0)
    Catch => color_rgba(226U, 174U, 66U, 1.0)
    Laser => color_rgba(224U, 81U, 70U, 1.0)
  }
}

///|
fn brick_fill_color(brick : BrickState) -> @render.Color {
  match brick.kind {
    Normal => color_rgba(83U, 131U, 206U, 1.0)
    Strong =>
      if brick.hits_remaining > 1 {
        color_rgba(220U, 172U, 72U, 1.0)
      } else {
        color_rgba(211U, 125U, 56U, 1.0)
      }
    Steel => color_rgba(92U, 100U, 112U, 1.0)
    PowerCarrier =>
      match brick.powerup {
        Some(kind) => powerup_color(kind)
        None => color_rgba(123U, 131U, 145U, 1.0)
      }
  }
}

///|
fn active_indicator_color(slot : Int) -> @render.Color? {
  match slot {
    0 =>
      if game_state.wide_seconds > 0.0 {
        Some(powerup_color(WidePaddle))
      } else {
        None
      }
    1 =>
      if game_state.slow_seconds > 0.0 {
        Some(powerup_color(SlowBall))
      } else {
        None
      }
    _ =>
      match game_state.paddle_mode {
        PaddleMode::Catch => Some(powerup_color(Catch))
        PaddleMode::Laser => Some(powerup_color(Laser))
        PaddleMode::None => None
      }
  }
}

///|
fn sync_hud() -> Unit {
  let hud = hud_rect()
  panel_entity(
    background_entity,
    color_rgba(222U, 228U, 235U, 1.0),
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5,
    VIEWPORT_WIDTH,
    VIEWPORT_HEIGHT,
    0.0,
  )
  panel_entity(
    hud_panel_entity,
    color_rgba(58U, 67U, 78U, 0.98),
    hud.left + hud.width * 0.5,
    hud.top + hud.height * 0.5,
    hud.width,
    hud.height,
    40.0,
  )

  let lives_rect = lives_panel_rect()
  panel_entity(
    lives_panel_entity,
    color_rgba(24U, 31U, 41U, 0.98),
    lives_rect.left + lives_rect.width * 0.5,
    lives_rect.top + lives_rect.height * 0.5,
    lives_rect.width,
    lives_rect.height,
    70.0,
  )
  centered_text_entity(
    lives_text_entity,
    format_counter(game_state.lives),
    lives_rect.left + lives_rect.width * 0.5,
    lives_rect.top + lives_rect.height * 0.5,
    lives_rect.width * 0.9,
    lives_rect.height * 0.9,
    28,
    "rgb(255,255,255)",
    80.0,
  )

  let reset_rect = reset_panel_rect()
  let reset_color = match game_state.phase {
    Won => color_rgba(68U, 179U, 120U, 1.0)
    Lost => color_rgba(215U, 88U, 74U, 1.0)
    _ => color_rgba(82U, 131U, 217U, 1.0)
  }
  panel_entity(
    reset_panel_entity,
    reset_color,
    reset_rect.left + reset_rect.width * 0.5,
    reset_rect.top + reset_rect.height * 0.5,
    reset_rect.width,
    reset_rect.height,
    70.0,
  )
  centered_text_entity(
    reset_text_entity,
    reset_text(),
    reset_rect.left + reset_rect.width * 0.5,
    reset_rect.top + reset_rect.height * 0.5,
    reset_rect.width * 0.9,
    reset_rect.height * 0.9,
    28,
    "rgb(255,255,255)",
    80.0,
  )

  let remaining_rect = remaining_panel_rect()
  panel_entity(
    remaining_panel_entity,
    color_rgba(24U, 31U, 41U, 0.98),
    remaining_rect.left + remaining_rect.width * 0.5,
    remaining_rect.top + remaining_rect.height * 0.5,
    remaining_rect.width,
    remaining_rect.height,
    70.0,
  )
  centered_text_entity(
    remaining_text_entity,
    format_counter(game_state.remaining_breakables),
    remaining_rect.left + remaining_rect.width * 0.5,
    remaining_rect.top + remaining_rect.height * 0.5,
    remaining_rect.width * 0.9,
    remaining_rect.height * 0.9,
    28,
    "rgb(255,255,255)",
    80.0,
  )

  for index in 0..<indicator_entities.length() {
    let rect = indicator_rect(index)
    match active_indicator_color(index) {
      Some(color) =>
        panel_entity(
          indicator_entities[index],
          color,
          rect.left + rect.width * 0.5,
          rect.top + rect.height * 0.5,
          rect.width,
          rect.height,
          75.0,
        )
      None => set_entity_visible(indicator_entities[index], false)
    }
  }
}

///|
fn sync_board() -> Unit {
  panel_entity(
    board_frame_entity,
    color_rgba(98U, 108U, 120U, 1.0),
    BOARD_LEFT + BOARD_WIDTH * 0.5,
    BOARD_TOP + BOARD_HEIGHT * 0.5,
    BOARD_WIDTH + 12.0,
    BOARD_HEIGHT + 12.0,
    60.0,
  )

  let paddle = paddle_rect()
  panel_entity(
    paddle_entity,
    color_rgba(233U, 238U, 245U, 1.0),
    paddle.left + paddle.width * 0.5,
    paddle.top + paddle.height * 0.5,
    paddle.width,
    paddle.height,
    120.0,
  )

  for index in 0..<MAX_BRICK_COUNT {
    if index < bricks.length() && bricks[index].active {
      let hitbox = brick_rect(bricks[index].row, bricks[index].col)
      panel_entity(
        brick_entities[index],
        brick_fill_color(bricks[index]),
        hitbox.left + hitbox.width * 0.5,
        hitbox.top + hitbox.height * 0.5,
        hitbox.width,
        hitbox.height,
        110.0,
      )
    } else {
      set_entity_visible(brick_entities[index], false)
    }
  }

  for index in 0..<MAX_BALLS {
    if balls[index].active {
      panel_entity(
        ball_entities[index],
        color_rgba(246U, 248U, 252U, 1.0),
        balls[index].x,
        balls[index].y,
        BALL_SIZE,
        BALL_SIZE,
        130.0,
      )
    } else {
      set_entity_visible(ball_entities[index], false)
    }
  }

  for index in 0..<MAX_POWERUPS {
    if powerups[index].active {
      panel_entity(
        powerup_entities[index],
        powerup_color(powerups[index].kind),
        powerups[index].x,
        powerups[index].y,
        POWERUP_SIZE,
        POWERUP_SIZE,
        125.0,
      )
    } else {
      set_entity_visible(powerup_entities[index], false)
    }
  }

  for index in 0..<MAX_LASERS {
    if laser_shots[index].active {
      panel_entity(
        laser_entities[index],
        color_rgba(238U, 92U, 78U, 1.0),
        laser_shots[index].x,
        laser_shots[index].y,
        LASER_WIDTH,
        LASER_HEIGHT,
        128.0,
      )
    } else {
      set_entity_visible(laser_entities[index], false)
    }
  }
}

///|
fn sync_overlay() -> Unit {
  let text = overlay_text()
  if text == "" {
    set_entity_visible(overlay_panel_entity, false)
    set_entity_visible(overlay_text_entity, false)
    return
  }
  panel_entity(
    overlay_panel_entity,
    color_rgba(16U, 22U, 32U, 0.82),
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5,
    220.0,
    72.0,
    280.0,
  )
  centered_text_entity(
    overlay_text_entity,
    text,
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5,
    200.0,
    52.0,
    22,
    "rgb(255,255,255)",
    290.0,
  )
}

///|
fn try_reset_click() -> Bool {
  let mouse = @inputs.mouse.pos
  if point_in_rect(mouse[X], mouse[Y], reset_panel_rect()) {
    reset_run_state()
    true
  } else {
    false
  }
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  if @inputs.is_just_pressed(Escape) {
    @system.exit()
    return
  }
  if !@inputs.just_pressed_mouse.left_button {
    return
  }
  if try_reset_click() {
    return
  }
  match game_state.phase {
    Ready => ignore(release_stuck_balls())
    Serving => ignore(release_stuck_balls())
    Playing =>
      if game_state.paddle_mode == PaddleMode::Laser &&
        game_state.laser_cooldown <= 0.0 {
        ignore(spawn_laser_pair())
      }
    LevelCleared => advance_level()
    Won => reset_run_state()
    Lost => reset_run_state()
  }
}

///|
pub fn update_system(_world : @ecs.World) -> Unit {
  update_paddle_from_mouse()
  let delta = @time.delta()
  match game_state.phase {
    Ready => tick_timed_powerups(delta)
    Serving => tick_timed_powerups(delta)
    Playing => update_playing(delta)
    LevelCleared => {
      game_state.phase_seconds += delta
      if game_state.phase_seconds >= LEVEL_CLEAR_SECONDS {
        advance_level()
      }
    }
    Won => ()
    Lost => ()
  }
}

///|
pub fn render_system(_world : @ecs.World) -> Unit {
  sync_hud()
  sync_board()
  sync_overlay()
}

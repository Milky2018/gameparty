///|
fn cell_center_x(cell : Cell) -> Double {
  board_left + cell.col.to_double() * CELL_SIZE + CELL_SIZE * 0.5
}

///|
fn cell_center_y(cell : Cell) -> Double {
  BOARD_TOP + cell.row.to_double() * CELL_SIZE + CELL_SIZE * 0.5
}

///|
fn movement_input() -> Direction? {
  if @inputs.is_just_pressed(KeyW) || @inputs.is_just_pressed(ArrowUp) {
    Some(Up)
  } else if @inputs.is_just_pressed(KeyD) || @inputs.is_just_pressed(ArrowRight) {
    Some(Right)
  } else if @inputs.is_just_pressed(KeyS) || @inputs.is_just_pressed(ArrowDown) {
    Some(Down)
  } else if @inputs.is_just_pressed(KeyA) || @inputs.is_just_pressed(ArrowLeft) {
    Some(Left)
  } else {
    None
  }
}

///|
fn overlay_title() -> String? {
  match run_state.phase {
    Title => Some("SNAKE")
    GameOver => Some("GAME OVER")
    Perfect => Some("PERFECT")
    _ => None
  }
}

///|
fn overlay_prompt() -> String? {
  match run_state.phase {
    Title => Some("ENTER")
    GameOver => Some("ENTER")
    Perfect => Some("ENTER")
    _ => None
  }
}

///|
fn sync_background() -> Unit {
  panel_entity(
    background_entity,
    color_rgba(236U, 241U, 232U, 1.0),
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5,
    VIEWPORT_WIDTH,
    VIEWPORT_HEIGHT,
    BACKGROUND_Z,
  )
  panel_entity(
    board_frame_entity,
    color_rgba(41U, 55U, 45U, 1.0),
    VIEWPORT_WIDTH * 0.5,
    BOARD_TOP + board_height * 0.5,
    board_width + FRAME_THICKNESS * 2.0,
    board_height + FRAME_THICKNESS * 2.0,
    BOARD_FRAME_Z,
  )
  panel_entity(
    board_entity,
    color_rgba(21U, 29U, 25U, 1.0),
    VIEWPORT_WIDTH * 0.5,
    BOARD_TOP + board_height * 0.5,
    board_width,
    board_height,
    BOARD_Z,
  )
}

///|
fn sync_food() -> Unit {
  match run_state.food {
    Some(food) =>
      panel_entity(
        food_entity,
        color_rgba(255U, 92U, 92U, 1.0),
        cell_center_x(food),
        cell_center_y(food),
        FOOD_SIZE,
        FOOD_SIZE,
        FOOD_Z,
      )
    None => hide_entity(food_entity)
  }
}

///|
fn sync_snake() -> Unit {
  for index in 0..<TOTAL_CELLS {
    let entity = segment_entities[index]
    if index < run_state.snake.length() {
      let segment = run_state.snake[index]
      let color = if index == 0 {
        color_rgba(206U, 255U, 128U, 1.0)
      } else if index % 2 == 0 {
        color_rgba(115U, 212U, 109U, 1.0)
      } else {
        color_rgba(92U, 184U, 93U, 1.0)
      }
      panel_entity(
        entity,
        color,
        cell_center_x(segment),
        cell_center_y(segment),
        SEGMENT_SIZE,
        SEGMENT_SIZE,
        SNAKE_Z + index.to_double() * 0.001,
      )
    } else {
      hide_entity(entity)
    }
  }
}

///|
fn sync_hud() -> Unit {
  centered_text_entity(
    hud_score_entity,
    "S \{run_state.score}",
    board_left + 52.0,
    96.0,
    104.0,
    26.0,
    24,
    "rgb(41,55,45)",
    HUD_Z,
  )
  centered_text_entity(
    hud_length_entity,
    "L \{run_state.snake.length()}",
    board_right - 52.0,
    96.0,
    104.0,
    26.0,
    24,
    "rgb(41,55,45)",
    HUD_Z,
  )
  match run_state.phase {
    Paused =>
      centered_text_entity(
        hud_phase_entity,
        "PAUSED",
        VIEWPORT_WIDTH * 0.5,
        96.0,
        140.0,
        24.0,
        20,
        "rgb(41,55,45)",
        HUD_Z,
      )
    _ => hide_entity(hud_phase_entity)
  }
}

///|
fn sync_overlay() -> Unit {
  match overlay_title() {
    Some(title) => {
      panel_entity(
        overlay_panel_entity,
        color_rgba(14U, 20U, 17U, 0.78),
        VIEWPORT_WIDTH * 0.5,
        VIEWPORT_HEIGHT * 0.5,
        300.0,
        136.0,
        OVERLAY_Z,
      )
      centered_text_entity(
        title_entity,
        title,
        VIEWPORT_WIDTH * 0.5,
        VIEWPORT_HEIGHT * 0.5 - 18.0,
        260.0,
        36.0,
        30,
        "rgb(244,247,241)",
        OVERLAY_Z + 1.0,
      )
      centered_text_entity(
        prompt_entity,
        overlay_prompt().unwrap(),
        VIEWPORT_WIDTH * 0.5,
        VIEWPORT_HEIGHT * 0.5 + 28.0,
        180.0,
        24.0,
        18,
        "rgb(175,188,175)",
        OVERLAY_Z + 1.0,
      )
    }
    None => {
      hide_entity(overlay_panel_entity)
      hide_entity(title_entity)
      hide_entity(prompt_entity)
    }
  }
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  if @inputs.is_just_pressed(Escape) && run_state.phase != Title {
    reset_to_title()
    return
  }

  if @inputs.is_just_pressed(Enter) {
    match run_state.phase {
      Title => start_new_run()
      GameOver => start_new_run()
      Perfect => start_new_run()
      _ => ()
    }
  }

  if @inputs.is_just_pressed(Space) {
    toggle_pause_state()
  }

  match movement_input() {
    Some(direction) => ignore(request_turn(direction))
    None => ()
  }
}

///|
pub fn update_system(_world : @ecs.World) -> Unit {
  tick_run(@time.delta())
}

///|
pub fn render_system(_world : @ecs.World) -> Unit {
  sync_background()
  sync_food()
  sync_snake()
  sync_hud()
  sync_overlay()
}

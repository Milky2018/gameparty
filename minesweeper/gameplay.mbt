///|
fn point_in_rect(x : Double, y : Double, rect : ButtonRect) -> Bool {
  x >= rect.left &&
  x <= rect.left + rect.width &&
  y >= rect.top &&
  y <= rect.top + rect.height
}

///|
fn difficulty_button_rect(slot : Int) -> ButtonRect {
  let total_width = difficulties.length().to_double() * DIFFICULTY_BUTTON_WIDTH +
    (difficulties.length() - 1).to_double() * DIFFICULTY_BUTTON_GAP
  let left = VIEWPORT_WIDTH * 0.5 -
    total_width * 0.5 +
    slot.to_double() * (DIFFICULTY_BUTTON_WIDTH + DIFFICULTY_BUTTON_GAP)
  {
    left,
    top: DIFFICULTY_BUTTON_TOP,
    width: DIFFICULTY_BUTTON_WIDTH,
    height: DIFFICULTY_BUTTON_HEIGHT,
  }
}

///|
fn face_button_rect() -> ButtonRect {
  {
    left: VIEWPORT_WIDTH * 0.5 - FACE_BUTTON_SIZE * 0.5,
    top: CONTROL_CENTER_Y - FACE_BUTTON_SIZE * 0.5,
    width: FACE_BUTTON_SIZE,
    height: FACE_BUTTON_SIZE,
  }
}

///|
fn current_hovered_cell() -> Cell? {
  let mouse = @inputs.mouse.pos
  let layout = active_layout()
  let col = @cmath.floor(
    (mouse[X] - layout.left) / (layout.cell_size + BOARD_GAP),
  ).to_int()
  let row = @cmath.floor(
    (mouse[Y] - layout.top) / (layout.cell_size + BOARD_GAP),
  ).to_int()
  if !in_bounds(row, col) {
    return None
  }
  let cell = Cell::{ row, col }
  let rect = cell_rect(layout, cell)
  if point_in_rect(mouse[X], mouse[Y], rect) {
    Some(cell)
  } else {
    None
  }
}

///|
fn choose_number_color(adjacent_mines : Int) -> String {
  match adjacent_mines {
    1 => "rgb(66,133,244)"
    2 => "rgb(15,157,88)"
    3 => "rgb(219,68,55)"
    4 => "rgb(62,39,148)"
    5 => "rgb(180,95,6)"
    6 => "rgb(0,121,107)"
    7 => "rgb(38,50,56)"
    8 => "rgb(120,144,156)"
    _ => "rgb(235,239,244)"
  }
}

///|
fn cell_text_for_index(index : Int) -> String {
  match board[index].visibility {
    Hidden => ""
    Flagged => "F"
    Revealed =>
      if board[index].has_mine {
        "*"
      } else if board[index].adjacent_mines > 0 {
        "\{board[index].adjacent_mines}"
      } else {
        ""
      }
  }
}

///|
fn cell_text_color_for_index(index : Int) -> String {
  match board[index].visibility {
    Hidden => "rgb(235,239,244)"
    Flagged => "rgb(227,74,66)"
    Revealed =>
      if board[index].has_mine {
        if board[index].exploded {
          "rgb(255,248,240)"
        } else {
          "rgb(38,45,54)"
        }
      } else {
        choose_number_color(board[index].adjacent_mines)
      }
  }
}

///|
fn cell_fill_color_for_index(index : Int) -> @render.Color {
  match board[index].visibility {
    Hidden =>
      color_rgba(
        132U,
        144U,
        156U,
        if board[index].exploded {
          1.0
        } else {
          0.98
        },
      )
    Flagged => color_rgba(130U, 143U, 156U, 0.98)
    Revealed =>
      if board[index].has_mine {
        if board[index].exploded {
          color_rgba(220U, 68U, 55U, 1.0)
        } else {
          color_rgba(207U, 214U, 223U, 1.0)
        }
      } else {
        color_rgba(224U, 229U, 236U, 1.0)
      }
  }
}

///|
fn cell_text_size(layout : BoardLayout) -> Int {
  clamp_int((layout.cell_size * 0.48).to_int(), 14, 28)
}

///|
fn set_hover_frame_visible(visible : Bool) -> Unit {
  set_entity_visible(hover_frame_top_entity, visible)
  set_entity_visible(hover_frame_bottom_entity, visible)
  set_entity_visible(hover_frame_left_entity, visible)
  set_entity_visible(hover_frame_right_entity, visible)
}

///|
fn sync_hover_frame(layout : BoardLayout) -> Unit {
  if game_state.phase == Won || game_state.phase == Lost {
    set_hover_frame_visible(false)
    return
  }
  match game_state.hovered_cell {
    None => set_hover_frame_visible(false)
    Some(cell) => {
      let rect = cell_rect(layout, cell)
      let center_x = rect.left + rect.width * 0.5
      let center_y = rect.top + rect.height * 0.5
      panel_entity(
        hover_frame_top_entity,
        color_rgba(88U, 194U, 255U, 0.95),
        center_x,
        rect.top + HOVER_FRAME_THICKNESS * 0.5,
        rect.width,
        HOVER_FRAME_THICKNESS,
        HOVER_FRAME_Z,
      )
      panel_entity(
        hover_frame_bottom_entity,
        color_rgba(88U, 194U, 255U, 0.95),
        center_x,
        rect.top + rect.height - HOVER_FRAME_THICKNESS * 0.5,
        rect.width,
        HOVER_FRAME_THICKNESS,
        HOVER_FRAME_Z,
      )
      panel_entity(
        hover_frame_left_entity,
        color_rgba(88U, 194U, 255U, 0.95),
        rect.left + HOVER_FRAME_THICKNESS * 0.5,
        center_y,
        HOVER_FRAME_THICKNESS,
        rect.height,
        HOVER_FRAME_Z,
      )
      panel_entity(
        hover_frame_right_entity,
        color_rgba(88U, 194U, 255U, 0.95),
        rect.left + rect.width - HOVER_FRAME_THICKNESS * 0.5,
        center_y,
        HOVER_FRAME_THICKNESS,
        rect.height,
        HOVER_FRAME_Z,
      )
      set_hover_frame_visible(true)
    }
  }
}

///|
fn format_counter(value : Int) -> String {
  let negative = value < 0
  let abs_value = if negative { -value } else { value }
  let padded = if abs_value < 10 {
    "00\{abs_value}"
  } else if abs_value < 100 {
    "0\{abs_value}"
  } else {
    "\{abs_value}"
  }
  if negative {
    "-\{padded}"
  } else {
    padded
  }
}

///|
fn mine_counter_text() -> String {
  "MINES\n\{format_counter(game_state.mine_count - game_state.flag_count)}"
}

///|
fn timer_text() -> String {
  "TIME\n\{format_counter(@cmath.floor(game_state.seconds_elapsed).to_int())}"
}

///|
fn face_text() -> String {
  match game_state.phase {
    Ready => ":)"
    Running => ":)"
    Won => "B)"
    Lost => ":("
  }
}

///|
fn overlay_text() -> String {
  match game_state.phase {
    Won =>
      "FIELD CLEARED\nTime \{format_counter(@cmath.floor(game_state.seconds_elapsed).to_int())}\nClick the face or press R / Enter / Space"
    Lost => "BOOM\nClick the face or press R / Enter / Space"
    _ => ""
  }
}

///|
fn sync_board_visuals(layout : BoardLayout) -> Unit {
  let active_count = total_cells()
  let number_size = cell_text_size(layout)
  for index in 0..<MAX_CELL_COUNT {
    let bg_entity = cell_background_entities[index]
    let text_entity_ref = cell_text_entities[index]
    if index < active_count {
      let row = index / game_state.cols
      let col = index % game_state.cols
      let cell = Cell::{ row, col }
      let rect = cell_rect(layout, cell)
      let center_x = rect.left + rect.width * 0.5
      let center_y = rect.top + rect.height * 0.5
      panel_entity(
        bg_entity,
        cell_fill_color_for_index(index),
        center_x,
        center_y,
        rect.width,
        rect.height,
        120.0,
      )
      centered_text_entity(
        text_entity_ref,
        cell_text_for_index(index),
        center_x,
        center_y,
        rect.width * 0.96,
        rect.height * 0.96,
        number_size,
        cell_text_color_for_index(index),
        130.0,
      )
      set_entity_visible(bg_entity, true)
      set_entity_visible(text_entity_ref, true)
    } else {
      set_entity_visible(bg_entity, false)
      set_entity_visible(text_entity_ref, false)
    }
  }
  game_state.board_dirty = false
  game_state.layout_dirty = false
}

///|
fn sync_chrome(layout : BoardLayout) -> Unit {
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
    header_entity,
    color_rgba(55U, 63U, 73U, 0.98),
    VIEWPORT_WIDTH * 0.5,
    82.0,
    VIEWPORT_WIDTH - 48.0,
    118.0,
    40.0,
  )
  text_entity(
    title_entity, "MOONBIT MINES", 86.0, 24.0, 46, "rgb(245,247,250)", 60.0,
  )
  text_entity(
    footer_entity,
    "Left click reveal   Right click flag   Click a number to chord   R / Enter / Space restart",
    220.0,
    VIEWPORT_HEIGHT - 42.0,
    18,
    "rgb(68,76,88)",
    60.0,
  )
  let mine_center_x = 158.0
  let timer_center_x = VIEWPORT_WIDTH - 158.0
  panel_entity(
    mine_panel_entity,
    color_rgba(25U, 31U, 41U, 0.96),
    mine_center_x,
    CONTROL_CENTER_Y,
    STATUS_PANEL_WIDTH,
    STATUS_PANEL_HEIGHT,
    70.0,
  )
  panel_entity(
    timer_panel_entity,
    color_rgba(25U, 31U, 41U, 0.96),
    timer_center_x,
    CONTROL_CENTER_Y,
    STATUS_PANEL_WIDTH,
    STATUS_PANEL_HEIGHT,
    70.0,
  )
  let mine_label = mine_counter_text()
  if game_state.mine_text_cache != mine_label {
    centered_text_entity(
      mine_text_entity,
      mine_label,
      mine_center_x,
      CONTROL_CENTER_Y,
      STATUS_PANEL_WIDTH * 0.9,
      STATUS_PANEL_HEIGHT * 0.9,
      26,
      "rgb(255,255,255)",
      80.0,
    )
    game_state.mine_text_cache = mine_label
  } else {
    set_entity_visible(mine_text_entity, true)
  }
  let timer_label = timer_text()
  if game_state.timer_text_cache != timer_label {
    centered_text_entity(
      timer_text_entity,
      timer_label,
      timer_center_x,
      CONTROL_CENTER_Y,
      STATUS_PANEL_WIDTH * 0.9,
      STATUS_PANEL_HEIGHT * 0.9,
      26,
      "rgb(255,255,255)",
      80.0,
    )
    game_state.timer_text_cache = timer_label
  } else {
    set_entity_visible(timer_text_entity, true)
  }

  let mouse = @inputs.mouse.pos
  let face_rect = face_button_rect()
  let face_hovered = point_in_rect(mouse[X], mouse[Y], face_rect)
  let face_color = match game_state.phase {
    Won => color_rgba(246U, 190U, 64U, 1.0)
    Lost => color_rgba(220U, 92U, 74U, 1.0)
    _ =>
      if face_hovered {
        color_rgba(245U, 203U, 89U, 1.0)
      } else {
        color_rgba(235U, 193U, 74U, 1.0)
      }
  }
  panel_entity(
    face_panel_entity,
    face_color,
    face_rect.left + face_rect.width * 0.5,
    face_rect.top + face_rect.height * 0.5,
    face_rect.width,
    face_rect.height,
    75.0,
  )
  let face_label = face_text()
  if game_state.face_text_cache != face_label {
    centered_text_entity(
      face_text_entity,
      face_label,
      face_rect.left + face_rect.width * 0.5,
      face_rect.top + face_rect.height * 0.5,
      face_rect.width * 0.9,
      face_rect.height * 0.9,
      38,
      "rgb(36,36,36)",
      82.0,
    )
    game_state.face_text_cache = face_label
  } else {
    set_entity_visible(face_text_entity, true)
  }

  for index in 0..<difficulties.length() {
    let rect = difficulty_button_rect(index)
    let difficulty = difficulties[index]
    let hovered = point_in_rect(mouse[X], mouse[Y], rect)
    let is_active = difficulty == game_state.current_difficulty
    let panel_color = if is_active {
      color_rgba(75U, 133U, 219U, 1.0)
    } else if hovered {
      color_rgba(105U, 117U, 132U, 1.0)
    } else {
      color_rgba(84U, 95U, 108U, 1.0)
    }
    panel_entity(
      difficulty_panel_entities[index],
      panel_color,
      rect.left + rect.width * 0.5,
      rect.top + rect.height * 0.5,
      rect.width,
      rect.height,
      70.0,
    )
    centered_text_entity(
      difficulty_text_entities[index],
      difficulty_label(difficulty),
      rect.left + rect.width * 0.5,
      rect.top + rect.height * 0.5,
      rect.width * 0.92,
      rect.height * 0.92,
      18,
      "rgb(245,247,250)",
      80.0,
    )
  }

  panel_entity(
    board_panel_entity,
    color_rgba(94U, 104U, 116U, 1.0),
    layout.left + layout.width * 0.5,
    layout.top + layout.height * 0.5,
    layout.width + 18.0,
    layout.height + 18.0,
    90.0,
  )
}

///|
fn sync_overlay() -> Unit {
  if game_state.phase == Won || game_state.phase == Lost {
    set_entity_visible(overlay_panel_entity, true)
    let text = overlay_text()
    if game_state.overlay_text_cache != text {
      centered_text_entity(
        overlay_text_entity,
        text,
        VIEWPORT_WIDTH * 0.5,
        VIEWPORT_HEIGHT * 0.5 - 8.0,
        VIEWPORT_WIDTH * 0.56,
        160.0,
        34,
        "rgb(255,255,255)",
        310.0,
      )
      game_state.overlay_text_cache = text
    } else {
      set_entity_visible(overlay_text_entity, true)
    }
  } else {
    set_entity_visible(overlay_panel_entity, false)
    set_entity_visible(overlay_text_entity, false)
  }
}

///|
fn handle_left_click_cell(cell : Cell) -> Unit {
  let phase_before = game_state.phase
  let revealed_before = game_state.revealed_safe_cells
  let index = board_index_for_cell(cell)
  let changed = if board[index].visibility == Revealed {
    chord_reveal(cell)
  } else {
    reveal_cell(cell)
  }
  if !changed {
    return
  }
  if game_state.phase == Lost && phase_before != Lost {
    play_sound_ref(sound_explode)
  } else if game_state.phase == Won && phase_before != Won {
    play_sound_ref(sound_win)
  } else if game_state.revealed_safe_cells > revealed_before {
    play_sound_ref(sound_reveal)
  }
}

///|
fn handle_right_click_cell(cell : Cell) -> Unit {
  if toggle_flag(cell) {
    play_sound_ref(sound_flag)
  }
}

///|
fn handle_ui_click() -> Bool {
  let mouse = @inputs.mouse.pos
  if point_in_rect(mouse[X], mouse[Y], face_button_rect()) {
    reset_current_run()
    return true
  }
  for index in 0..<difficulties.length() {
    if point_in_rect(mouse[X], mouse[Y], difficulty_button_rect(index)) {
      reset_run_state(difficulties[index])
      return true
    }
  }
  false
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  if @inputs.is_just_pressed(Escape) {
    @system.exit()
    return
  }
  if @inputs.is_just_pressed(KeyR) ||
    @inputs.is_just_pressed(Enter) ||
    @inputs.is_just_pressed(Space) {
    reset_current_run()
    return
  }
  if @inputs.just_pressed_mouse.left_button {
    if handle_ui_click() {
      return
    }
    match current_hovered_cell() {
      Some(cell) => handle_left_click_cell(cell)
      None => ()
    }
  }
  if @inputs.just_pressed_mouse.right_button {
    match current_hovered_cell() {
      Some(cell) => handle_right_click_cell(cell)
      None => ()
    }
  }
}

///|
pub fn update_system(_world : @ecs.World) -> Unit {
  if game_state.phase == Running {
    game_state.seconds_elapsed += @time.delta()
  }
}

///|
pub fn render_system(_world : @ecs.World) -> Unit {
  let layout = active_layout()
  game_state.hovered_cell = current_hovered_cell()
  sync_chrome(layout)
  if game_state.board_dirty || game_state.layout_dirty {
    sync_board_visuals(layout)
  }
  sync_hover_frame(layout)
  sync_overlay()
}

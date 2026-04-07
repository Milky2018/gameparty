///|
fn board_get(row : Int, col : Int) -> GemKind? {
  if !in_bounds(row, col) {
    return None
  }
  board[board_index(row, col)]
}

///|
fn board_set(row : Int, col : Int, value : GemKind?) -> Unit {
  if in_bounds(row, col) {
    board[board_index(row, col)] = value
  }
}

///|
fn random_kind() -> GemKind {
  match rand.int(limit=GEM_COUNT) {
    0 => Ruby
    1 => Emerald
    2 => Sapphire
    3 => Amber
    4 => Amethyst
    _ => Pearl
  }
}

///|
fn fill_board_without_initial_matches() -> Unit {
  for row in 0..<BOARD_ROWS {
    for col in 0..<BOARD_COLS {
      let mut candidate = random_kind()
      while makes_match_at(row, col, candidate) {
        candidate = random_kind()
      }
      board_set(row, col, Some(candidate))
    }
  }
}

///|
fn makes_match_at(row : Int, col : Int, kind : GemKind) -> Bool {
  let left1 = if col >= 1 { board_get(row, col - 1) } else { None }
  let left2 = if col >= 2 { board_get(row, col - 2) } else { None }
  if left1 == Some(kind) && left2 == Some(kind) {
    return true
  }
  let up1 = if row >= 1 { board_get(row - 1, col) } else { None }
  let up2 = if row >= 2 { board_get(row - 2, col) } else { None }
  up1 == Some(kind) && up2 == Some(kind)
}

///|
fn selected_hint_text() -> String {
  match game_state.first_pick {
    Some(cell) =>
      match board_get(cell.row, cell.col) {
        Some(kind) =>
          "Selected \{gem_names[gem_index(kind)]} at \{cell.row + 1},\{cell.col + 1}. Pick an adjacent gem."
        None => "Selected empty cell. Pick an adjacent gem."
      }
    None =>
      "Click adjacent gems to swap. Match 3+ to clear. R/Enter/Space restart. F3 toggle FPS. Esc quit."
  }
}

///|
fn find_matches() -> Array[Cell] {
  let matched : Map[Cell, Bool] = Map::new()
  for row in 0..<BOARD_ROWS {
    let mut run_kind : GemKind? = None
    let mut run_start = 0
    let mut run_len = 0
    for col in 0..<BOARD_COLS {
      let current = board_get(row, col)
      if current == run_kind && current is Some(_) {
        run_len += 1
      } else {
        if run_len >= 3 && run_kind is Some(_) {
          for k in run_start..<(run_start + run_len) {
            matched.set(Cell::{ row, col: k }, true)
          }
        }
        run_kind = current
        run_start = col
        run_len = if current is Some(_) { 1 } else { 0 }
      }
    }
    if run_len >= 3 && run_kind is Some(_) {
      for k in run_start..<(run_start + run_len) {
        matched.set(Cell::{ row, col: k }, true)
      }
    }
  }

  for col in 0..<BOARD_COLS {
    let mut run_kind : GemKind? = None
    let mut run_start = 0
    let mut run_len = 0
    for row in 0..<BOARD_ROWS {
      let current = board_get(row, col)
      if current == run_kind && current is Some(_) {
        run_len += 1
      } else {
        if run_len >= 3 && run_kind is Some(_) {
          for k in run_start..<(run_start + run_len) {
            matched.set(Cell::{ row: k, col }, true)
          }
        }
        run_kind = current
        run_start = row
        run_len = if current is Some(_) { 1 } else { 0 }
      }
    }
    if run_len >= 3 && run_kind is Some(_) {
      for k in run_start..<(run_start + run_len) {
        matched.set(Cell::{ row: k, col }, true)
      }
    }
  }

  let result : Array[Cell] = []
  for cell, _ in matched {
    result.push(cell)
  }
  result
}

///|
fn is_adjacent(a : Cell, b : Cell) -> Bool {
  let col_delta = if a.col >= b.col { a.col - b.col } else { b.col - a.col }
  let row_delta = if a.row >= b.row { a.row - b.row } else { b.row - a.row }
  (a.row == b.row && col_delta == 1) || (a.col == b.col && row_delta == 1)
}

///|
fn swap_cells(a : Cell, b : Cell) -> Unit {
  let left = board_get(a.row, a.col)
  let right = board_get(b.row, b.col)
  board_set(a.row, a.col, right)
  board_set(b.row, b.col, left)
}

///|
fn try_swap_and_find_match(a : Cell, b : Cell) -> Bool {
  if !is_adjacent(a, b) {
    return false
  }
  swap_cells(a, b)
  let matches = find_matches()
  let valid = !matches.is_empty()
  if !valid {
    swap_cells(a, b)
  }
  valid
}

///|
fn score_for_matches(count : Int) -> Int {
  if count <= 0 {
    0
  } else {
    count * 10
  }
}

///|
fn remove_matches(matches : Array[Cell]) -> Unit {
  for cell in matches {
    board_set(cell.row, cell.col, None)
  }
}

///|
fn collapse_board() -> Bool {
  let mut changed = false
  for col in 0..<BOARD_COLS {
    let mut write_row = BOARD_ROWS - 1
    let mut row = BOARD_ROWS - 1
    while row >= 0 {
      match board_get(row, col) {
        Some(kind) => {
          if write_row != row {
            board_set(write_row, col, Some(kind))
            board_set(row, col, None)
            changed = true
          }
          write_row -= 1
        }
        None => ()
      }
      row -= 1
    }
    while write_row >= 0 {
      board_set(write_row, col, Some(random_kind()))
      changed = true
      write_row -= 1
    }
  }
  changed
}

///|
fn create_gem_entity(cell : Cell, kind : GemKind) -> Gem {
  let entity = @entity.Entity::new()
  let (center, z) = cell_center(cell)
  let size = @math.Vec2D(CELL_SIZE * 0.75, CELL_SIZE * 0.75)
  let top_left = @math.Vec2D(
    center[X] - size[X] * 0.5,
    center[Y] - size[Y] * 0.5,
  )
  let gem = Gem::{
    kind,
    row: cell.row,
    col: cell.col,
    x: center[X],
    y: center[Y],
    target_x: center[X],
    target_y: center[Y],
    t: 1.0,
    anim_seconds: 0.001,
    clearing: false,
    entity,
  }
  @transform.transforms().set(
    entity,
    @transform.Transform::from_xyz(top_left[X], top_left[Y], z).with_scale(
      @math.Vec3::one(),
    ),
  )
  let sprite = @sprite.Sprite::from_color(gem_color(kind), size)
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @visibility.visibilities().set(entity, Visible)
  gem
}

///|
fn rebuild_visuals_from_board() -> Unit {
  for entity in gem_entities {
    entity.destroy()
  }
  gem_entities.clear()
  gem_lookup.clear()
  for row in 0..<BOARD_ROWS {
    for col in 0..<BOARD_COLS {
      match board_get(row, col) {
        Some(kind) => {
          let gem = create_gem_entity(Cell::{ row, col }, kind)
          gem_entities.push(gem.entity)
          gem_lookup.set(Cell::{ row, col }, gem)
        }
        None => ()
      }
    }
  }
}

///|
fn clear_matches_and_cascade() -> Int {
  let mut total_cleared = 0
  while true {
    let matches = find_matches()
    if matches.is_empty() {
      break
    }
    total_cleared += matches.length()
    remove_matches(matches)
    ignore(collapse_board())
  }
  total_cleared
}

///|
fn choose_cell_from_mouse() -> Cell? {
  let mouse = @inputs.mouse.pos
  let col = @cmath.floor((mouse[X] - BOARD_ORIGIN_X) / CELL_SIZE).to_int()
  let row = @cmath.floor((mouse[Y] - BOARD_ORIGIN_Y) / CELL_SIZE).to_int()
  if in_bounds(row, col) {
    Some(Cell::{ row, col })
  } else {
    None
  }
}

///|
fn reset_if_needed() -> Unit {
  if @inputs.is_just_pressed(KeyR) ||
    @inputs.is_just_pressed(Enter) ||
    @inputs.is_just_pressed(Space) {
    reset_run_state()
  }
}

///|
fn maybe_report_profile() -> Unit {
  if !game_state.profile_enabled {
    return
  }
  let now = @time.elapsed()
  let sample_s = now - game_state.profile_started_at
  if sample_s < BEJEWELED_PROFILE_WARMUP_SECONDS {
    game_state.profile_last_report_at = now
    game_state.profile_frame_count = 0
    game_state.profile_input_total = 0.0
    game_state.profile_update_total = 0.0
    game_state.profile_render_total = 0.0
    game_state.profile_slowest_frame = 0.0
    return
  }
  if now - game_state.profile_last_report_at < BEJEWELED_PROFILE_REPORT_SECONDS {
    return
  }
  let frames = if game_state.profile_frame_count <= 0 {
    1
  } else {
    game_state.profile_frame_count
  }
  let frames_double = frames.to_double()
  let window = now - game_state.profile_last_report_at
  let fps_avg = if window <= 0.0 { 0.0 } else { frames_double / window }
  let fps_window = fps_avg
  let fps_frame_dt = fps_avg
  let input_ms = game_state.profile_input_total / frames_double * 1000.0
  let update_ms = game_state.profile_update_total / frames_double * 1000.0
  let render_ms = game_state.profile_render_total / frames_double * 1000.0
  let slowest_frame_ms = game_state.profile_slowest_frame * 1000.0
  let min_fps = if slowest_frame_ms <= 0.0 {
    0.0
  } else {
    1000.0 / slowest_frame_ms
  }
  println(
    "[bejeweled][profile] elapsed=\{sample_s}s frames=\{game_state.profile_frame_count} fps_avg=\{fps_avg} fps_window=\{fps_window} fps_frame_dt=\{fps_frame_dt} fps_min=\{min_fps} input_avg_ms=\{input_ms} update_avg_ms=\{update_ms} render_avg_ms=\{render_ms} slowest_frame_ms=\{slowest_frame_ms} score=\{game_state.score} moves=\{game_state.moves_left} time_left=\{game_state.time_left}",
  )
  game_state.profile_last_report_at = now
  game_state.profile_frame_count = 0
  game_state.profile_input_total = 0.0
  game_state.profile_update_total = 0.0
  game_state.profile_render_total = 0.0
  game_state.profile_slowest_frame = 0.0
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  reset_if_needed()
  if @raylib.is_key_pressed(@raylib.KeyF3) {
    game_state.debug_fps = !game_state.debug_fps
  }
  if @inputs.is_just_pressed(Escape) {
    @system.exit()
    return
  }
  if game_state.phase != Playing || game_state.resolution_lock > 0.0 {
    return
  }
  if !@inputs.is_mouse_just_pressed(@inputs.MouseButton::Left) {
    return
  }
  match choose_cell_from_mouse() {
    Some(cell) =>
      match game_state.first_pick {
        None => game_state.first_pick = Some(cell)
        Some(first) => {
          if first == cell {
            game_state.first_pick = None
            return
          }
          if !is_adjacent(first, cell) {
            game_state.first_pick = Some(cell)
            return
          }
          if try_swap_and_find_match(first, cell) {
            game_state.moves_left -= 1
            play_sound_ref(sound_swap)
            let cleared = clear_matches_and_cascade()
            if cleared > 0 {
              game_state.score += score_for_matches(cleared)
              play_sound_ref(sound_match)
              if cleared >= 6 {
                play_sound_ref(sound_cascade)
              }
            }
            rebuild_visuals_from_board()
            game_state.first_pick = None
            game_state.resolution_lock = BOARD_ANIM_SECONDS
            if game_state.moves_left <= 0 {
              game_state.phase = GameOver
              game_state.game_over_reason = "No moves left"
              play_sound_ref(sound_gameover)
            }
          } else {
            play_sound_ref(sound_swap)
            game_state.first_pick = Some(cell)
            game_state.resolution_lock = BOARD_ANIM_SECONDS * 0.75
          }
        }
      }
    None => ()
  }
  if game_state.profile_enabled {
    game_state.profile_input_total += @time.elapsed() - started_at
  }
}

///|
pub fn update_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  let delta = @time.delta()
  if game_state.phase == GameOver {
    return
  }
  game_state.time_left -= delta
  if game_state.time_left <= 0.0 {
    game_state.time_left = 0.0
    game_state.phase = GameOver
    game_state.game_over_reason = "Time up"
    play_sound_ref(sound_gameover)
    return
  }
  if game_state.resolution_lock > 0.0 {
    game_state.resolution_lock = if game_state.resolution_lock > delta {
      game_state.resolution_lock - delta
    } else {
      0.0
    }
  }
  if game_state.debug_capture_enabled &&
    !game_state.debug_capture_taken &&
    @time.elapsed() - game_state.debug_capture_started_at >=
    DEBUG_CAPTURE_DELAY_SECONDS {
    @raylib.take_screenshot(DEBUG_CAPTURE_PATH)
    println("[bejeweled][capture] path=\{DEBUG_CAPTURE_PATH}")
    game_state.debug_capture_taken = true
    @system.exit()
  }
  if game_state.profile_enabled {
    game_state.profile_update_total += @time.elapsed() - started_at
  }
}

///|
fn hud_text() -> String {
  let remaining = @cmath.floor(game_state.time_left).to_int()
  let seconds = remaining % 60
  let minutes = remaining / 60
  let seconds_text = if seconds < 10 { "0\{seconds}" } else { "\{seconds}" }
  let fps_text = if game_state.debug_fps { " FPS ON" } else { "" }
  "SCORE \{game_state.score}  MOVES \{game_state.moves_left}  TIME \{minutes}:\{seconds_text}\{fps_text}"
}

///|
fn overlay_text() -> String {
  "GAME OVER\n\{game_state.game_over_reason}\nScore \{game_state.score}\nPress R, Enter, or Space to restart"
}

///|
pub fn render_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  let hud = hud_text()
  if game_state.hud_text_cache != hud {
    @ui.texts().set(hud_entity, @ui.Text::new(hud))
    game_state.hud_text_cache = hud
  }
  let hint = selected_hint_text()
  if game_state.hint_text_cache != hint {
    @ui.texts().set(hint_entity, @ui.Text::new(hint))
    game_state.hint_text_cache = hint
  }
  if game_state.phase == GameOver {
    set_entity_visible(overlay_entity, true)
    set_entity_visible(overlay_text_entity, true)
    let overlay = overlay_text()
    if game_state.overlay_text_cache != overlay {
      @ui.texts().set(overlay_text_entity, @ui.Text::new(overlay))
      game_state.overlay_text_cache = overlay
    }
  } else {
    set_entity_visible(overlay_entity, false)
    set_entity_visible(overlay_text_entity, false)
  }
  if game_state.profile_enabled {
    game_state.profile_render_total += @time.elapsed() - started_at
    game_state.profile_frame_count = game_state.profile_frame_count + 1
    let frame_dt = @time.frame_delta()
    if frame_dt > game_state.profile_slowest_frame {
      game_state.profile_slowest_frame = frame_dt
    }
    maybe_report_profile()
  }
}

///|
pub fn capture_after_render_system(_world : @ecs.World) -> Unit {
  if !game_state.debug_capture_enabled || game_state.debug_capture_taken {
    return
  }
  if @time.elapsed() - game_state.debug_capture_started_at <
    DEBUG_CAPTURE_DELAY_SECONDS {
    return
  }
  @raylib.take_screenshot(DEBUG_CAPTURE_PATH)
  println("[bejeweled][capture] path=\{DEBUG_CAPTURE_PATH}")
  game_state.debug_capture_taken = true
  @system.exit()
}

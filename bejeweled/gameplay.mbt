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
  if game_state.phase == GameOver {
    return "Round ended. Press R, Enter, or Space to restart."
  }
  if game_state.resolution_phase != InputReady {
    return "Resolving board..."
  }
  match game_state.first_pick {
    Some(cell) =>
      match board_get(cell.row, cell.col) {
        Some(kind) =>
          "Selected \{gem_names[gem_index(kind)]} at \{cell.row + 1},\{cell.col + 1}. Pick an adjacent gem."
        None => "Selected empty cell. Pick an adjacent gem."
      }
    None =>
      "Click or drag adjacent gems to swap. Match 3+ to clear. R/Enter/Space restart. F3 toggle FPS. Esc quit."
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
fn score_for_matches(count : Int) -> Int {
  if count <= 0 {
    0
  } else {
    count * 10
  }
}

///|
fn clamp01(value : Double) -> Double {
  if value <= 0.0 {
    0.0
  } else if value >= 1.0 {
    1.0
  } else {
    value
  }
}

///|
fn lerp(from : Double, to : Double, t : Double) -> Double {
  from + (to - from) * t
}

///|
fn smoothstep(t : Double) -> Double {
  let clamped = clamp01(t)
  clamped * clamped * (3.0 - 2.0 * clamped)
}

///|
fn set_gem_visual(
  entity : @entity.Entity,
  kind : GemKind,
  center : @math.Vec2D,
  z : Double,
  scale : Double,
  alpha : Double,
) -> Unit {
  let clamped_scale = if scale <= 0.01 { 0.01 } else { scale }
  let clamped_alpha = clamp01(alpha)
  let size_value = CELL_SIZE * 0.75 * clamped_scale
  let size = @math.Vec2D(size_value, size_value)
  let top_left = @math.Vec2D(
    center[X] - size[X] * 0.5,
    center[Y] - size[Y] * 0.5,
  )
  let color = { ..gem_color(kind), a: clamped_alpha }
  let sprite = @sprite.Sprite::from_color(color, size)
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    @transform.Transform::from_xyz(top_left[X], top_left[Y], z),
  )
  set_entity_visible(entity, true)
}

///|
fn create_gem_entity(cell : Cell, kind : GemKind) -> Gem {
  let entity = @entity.Entity::new()
  let (center, z) = cell_center(cell)
  set_gem_visual(entity, kind, center, z, 1.0, 1.0)
  Gem::{ kind, row: cell.row, col: cell.col, entity }
}

///|
fn remove_entity_once(entity : @entity.Entity) -> Unit {
  match gem_entities.search_by(fn(existing) { existing == entity }) {
    Some(index) => ignore(gem_entities.remove(index))
    None => ()
  }
  if entity.is_alive() {
    entity.destroy()
  }
}

///|
fn rebuild_visuals_from_board() -> Unit {
  for entity in gem_entities {
    if entity.is_alive() {
      entity.destroy()
    }
  }
  gem_entities.clear()
  gem_lookup.clear()
  for row in 0..<BOARD_ROWS {
    for col in 0..<BOARD_COLS {
      match board_get(row, col) {
        Some(kind) => {
          let cell = Cell::{ row, col }
          let gem = create_gem_entity(cell, kind)
          gem_entities.push(gem.entity)
          gem_lookup.set(cell, gem)
        }
        None => ()
      }
    }
  }
}

///|
fn can_accept_input() -> Bool {
  game_state.phase == Playing && game_state.resolution_phase == InputReady
}

///|
fn max_tween_duration(tweens : Array[GemTween]) -> Double {
  let mut max_duration = 0.0
  for tween in tweens {
    if tween.duration > max_duration {
      max_duration = tween.duration
    }
  }
  if max_duration <= 0.0 {
    0.0001
  } else {
    max_duration
  }
}

///|
fn set_input_ready_phase() -> Unit {
  game_state.resolution_phase = InputReady
  game_state.resolution_elapsed = 0.0
  game_state.resolution_duration = 0.0
  game_state.active_tweens.clear()
}

///|
fn start_resolution_phase(
  phase : ResolutionPhase,
  tweens : Array[GemTween],
) -> Unit {
  game_state.resolution_phase = phase
  game_state.resolution_elapsed = 0.0
  game_state.resolution_duration = max_tween_duration(tweens)
  game_state.active_tweens = tweens
}

///|
fn move_tween(
  entity : @entity.Entity,
  kind : GemKind,
  from_cell : Cell,
  to_cell : Cell,
  duration : Double,
) -> GemTween {
  let (from_center, from_z) = cell_center(from_cell)
  let (to_center, to_z) = cell_center(to_cell)
  {
    entity,
    kind,
    from_x: from_center[X],
    from_y: from_center[Y],
    to_x: to_center[X],
    to_y: to_center[Y],
    from_z,
    to_z,
    from_scale: 1.0,
    to_scale: 1.0,
    from_alpha: 1.0,
    to_alpha: 1.0,
    duration: if duration <= 0.0001 {
      0.0001
    } else {
      duration
    },
  }
}

///|
fn clear_tween(
  entity : @entity.Entity,
  kind : GemKind,
  cell : Cell,
) -> GemTween {
  let (center, z) = cell_center(cell)
  {
    entity,
    kind,
    from_x: center[X],
    from_y: center[Y],
    to_x: center[X],
    to_y: center[Y],
    from_z: z,
    to_z: z,
    from_scale: 1.0,
    to_scale: 0.12,
    from_alpha: 1.0,
    to_alpha: 0.0,
    duration: CLEAR_SECONDS,
  }
}

///|
fn swap_gems_in_lookup(a : Cell, b : Cell) -> Unit {
  match gem_lookup.get(a) {
    Some(gem_a) =>
      match gem_lookup.get(b) {
        Some(gem_b) => {
          gem_lookup.set(a, { ..gem_b, row: a.row, col: a.col })
          gem_lookup.set(b, { ..gem_a, row: b.row, col: b.col })
        }
        None => ()
      }
    None => ()
  }
}

///|
fn begin_swap_forward_phase(a : Cell, b : Cell) -> Unit {
  game_state.pending_swap_a = Some(a)
  game_state.pending_swap_b = Some(b)
  let tweens : Array[GemTween] = []
  match gem_lookup.get(a) {
    Some(gem_a) =>
      tweens.push(
        move_tween(gem_a.entity, gem_a.kind, a, b, SWAP_FORWARD_SECONDS),
      )
    None => ()
  }
  match gem_lookup.get(b) {
    Some(gem_b) =>
      tweens.push(
        move_tween(gem_b.entity, gem_b.kind, b, a, SWAP_FORWARD_SECONDS),
      )
    None => ()
  }
  if tweens.length() == 2 {
    play_sound_ref(sound_swap)
    start_resolution_phase(SwapForward, tweens)
  } else {
    set_input_ready_phase()
  }
}

///|
fn begin_swap_rollback_phase() -> Unit {
  match game_state.pending_swap_a {
    Some(a) =>
      match game_state.pending_swap_b {
        Some(b) => {
          let tweens : Array[GemTween] = []
          match gem_lookup.get(a) {
            Some(gem_a) =>
              tweens.push(
                move_tween(
                  gem_a.entity,
                  gem_a.kind,
                  a,
                  b,
                  SWAP_ROLLBACK_SECONDS,
                ),
              )
            None => ()
          }
          match gem_lookup.get(b) {
            Some(gem_b) =>
              tweens.push(
                move_tween(
                  gem_b.entity,
                  gem_b.kind,
                  b,
                  a,
                  SWAP_ROLLBACK_SECONDS,
                ),
              )
            None => ()
          }
          if tweens.length() == 2 {
            start_resolution_phase(SwapRollback, tweens)
          } else {
            set_input_ready_phase()
          }
        }
        None => set_input_ready_phase()
      }
    None => set_input_ready_phase()
  }
}

///|
fn begin_clear_phase(matches : Array[Cell]) -> Unit {
  game_state.pending_matches = matches
  let tweens : Array[GemTween] = []
  for cell in matches {
    if gem_lookup.get(cell) is Some(gem) {
      tweens.push(clear_tween(gem.entity, gem.kind, cell))
    }
  }
  if tweens.is_empty() {
    game_state.pending_matches.clear()
    set_input_ready_phase()
  } else {
    start_resolution_phase(Clear, tweens)
  }
}

///|
fn begin_cascade_check_phase() -> Unit {
  game_state.resolution_phase = CascadeCheck
  game_state.resolution_elapsed = 0.0
  game_state.resolution_duration = 0.0
  game_state.active_tweens.clear()
}

///|
fn begin_fall_phase() -> Bool {
  let tweens : Array[GemTween] = []
  for col in 0..<BOARD_COLS {
    let mut write_row = BOARD_ROWS - 1
    let mut row = BOARD_ROWS - 1
    while row >= 0 {
      match board_get(row, col) {
        Some(kind) => {
          if write_row != row {
            board_set(write_row, col, Some(kind))
            board_set(row, col, None)
            let from = Cell::{ row, col }
            let to = Cell::{ row: write_row, col }
            if gem_lookup.get(from) is Some(gem) {
              gem_lookup.remove(from)
              gem_lookup.set(to, { ..gem, row: write_row, col })
              let distance = (write_row - row).to_double()
              tweens.push(
                move_tween(
                  gem.entity,
                  gem.kind,
                  from,
                  to,
                  FALL_SECONDS_PER_CELL * distance,
                ),
              )
            }
          }
          write_row -= 1
        }
        None => ()
      }
      row -= 1
    }
    while write_row >= 0 {
      board_set(write_row, col, None)
      write_row -= 1
    }
  }
  if tweens.is_empty() {
    false
  } else {
    start_resolution_phase(Fall, tweens)
    true
  }
}

///|
fn begin_refill_phase() -> Bool {
  let tweens : Array[GemTween] = []
  for col in 0..<BOARD_COLS {
    let mut spawn_index = 0
    for row in 0..<BOARD_ROWS {
      if board_get(row, col) is None {
        let kind = random_kind()
        board_set(row, col, Some(kind))
        let spawn_row = -1 - spawn_index
        spawn_index += 1
        let target = Cell::{ row, col }
        let spawn = Cell::{ row: spawn_row, col }
        let entity = @entity.Entity::new()
        let gem = Gem::{ kind, row, col, entity }
        gem_lookup.set(target, gem)
        gem_entities.push(entity)
        let distance = (row - spawn_row).to_double()
        tweens.push(
          move_tween(
            entity,
            kind,
            spawn,
            target,
            REFILL_SECONDS_PER_CELL * distance,
          ),
        )
      }
    }
  }
  if tweens.is_empty() {
    false
  } else {
    start_resolution_phase(Refill, tweens)
    true
  }
}

///|
fn finalize_clear_phase() -> Unit {
  let cleared = game_state.pending_matches.length()
  if cleared <= 0 {
    game_state.pending_matches.clear()
    return
  }
  game_state.score += score_for_matches(cleared)
  play_sound_ref(sound_match)
  if game_state.cascade_depth > 0 || cleared >= 6 {
    play_sound_ref(sound_cascade)
  }
  for cell in game_state.pending_matches {
    board_set(cell.row, cell.col, None)
    if gem_lookup.get(cell) is Some(gem) {
      gem_lookup.remove(cell)
      remove_entity_once(gem.entity)
    }
  }
  game_state.pending_matches.clear()
}

///|
fn complete_resolution_phase() -> Unit {
  match game_state.resolution_phase {
    InputReady => ()
    SwapForward =>
      match game_state.pending_swap_a {
        Some(a) =>
          match game_state.pending_swap_b {
            Some(b) => {
              swap_cells(a, b)
              swap_gems_in_lookup(a, b)
              let matches = find_matches()
              if matches.is_empty() {
                begin_swap_rollback_phase()
              } else {
                game_state.moves_left -= 1
                game_state.cascade_depth = 0
                begin_clear_phase(matches)
              }
            }
            None => set_input_ready_phase()
          }
        None => set_input_ready_phase()
      }
    SwapRollback => {
      match game_state.pending_swap_a {
        Some(a) =>
          match game_state.pending_swap_b {
            Some(b) => {
              swap_cells(a, b)
              swap_gems_in_lookup(a, b)
            }
            None => ()
          }
        None => ()
      }
      game_state.first_pick = game_state.pending_swap_b
      game_state.pending_swap_a = None
      game_state.pending_swap_b = None
      game_state.cascade_depth = 0
      game_state.pending_matches.clear()
      set_input_ready_phase()
    }
    Clear => {
      finalize_clear_phase()
      if begin_fall_phase() {
        return
      }
      if begin_refill_phase() {
        return
      }
      begin_cascade_check_phase()
    }
    Fall => {
      if begin_refill_phase() {
        return
      }
      begin_cascade_check_phase()
    }
    Refill => begin_cascade_check_phase()
    CascadeCheck => {
      let matches = find_matches()
      if matches.is_empty() {
        game_state.pending_swap_a = None
        game_state.pending_swap_b = None
        game_state.pending_matches.clear()
        game_state.cascade_depth = 0
        set_input_ready_phase()
        if game_state.moves_left <= 0 {
          game_state.phase = GameOver
          game_state.game_over_reason = "No moves left"
          play_sound_ref(sound_gameover)
        }
      } else {
        game_state.cascade_depth += 1
        begin_clear_phase(matches)
      }
    }
  }
}

///|
fn apply_active_tweens() -> Unit {
  for tween in game_state.active_tweens {
    let local_t = if tween.duration <= 0.0001 {
      1.0
    } else {
      clamp01(game_state.resolution_elapsed / tween.duration)
    }
    let eased = smoothstep(local_t)
    let center = @math.Vec2D(
      lerp(tween.from_x, tween.to_x, eased),
      lerp(tween.from_y, tween.to_y, eased),
    )
    let z = lerp(tween.from_z, tween.to_z, eased)
    let scale = lerp(tween.from_scale, tween.to_scale, eased)
    let alpha = lerp(tween.from_alpha, tween.to_alpha, eased)
    set_gem_visual(tween.entity, tween.kind, center, z, scale, alpha)
  }
}

///|
fn tick_resolution(delta : Double) -> Unit {
  if game_state.resolution_phase == InputReady {
    return
  }
  let mut phase_guard_count = 0
  while game_state.resolution_phase == CascadeCheck && phase_guard_count < 8 {
    complete_resolution_phase()
    phase_guard_count += 1
  }
  if game_state.resolution_phase == InputReady ||
    game_state.resolution_phase == CascadeCheck {
    return
  }
  game_state.resolution_elapsed += delta
  apply_active_tweens()
  if game_state.resolution_elapsed >= game_state.resolution_duration {
    complete_resolution_phase()
    phase_guard_count = 0
    while game_state.resolution_phase == CascadeCheck && phase_guard_count < 8 {
      complete_resolution_phase()
      phase_guard_count += 1
    }
  }
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
fn clear_drag_state() -> Unit {
  game_state.drag_origin = None
  game_state.drag_pointer_down = false
  game_state.drag_swapped = false
}

///|
fn handle_click_cell(cell : Cell) -> Bool {
  match game_state.first_pick {
    None => {
      game_state.first_pick = Some(cell)
      false
    }
    Some(first) => {
      if first == cell {
        game_state.first_pick = None
        return false
      }
      if !is_adjacent(first, cell) {
        game_state.first_pick = Some(cell)
        return false
      }
      game_state.first_pick = None
      begin_swap_forward_phase(first, cell)
      true
    }
  }
}

///|
fn try_drag_swap_to_cell(cell : Cell?) -> Bool {
  if !can_accept_input() {
    return false
  }
  if !game_state.drag_pointer_down || game_state.drag_swapped {
    return false
  }
  match game_state.drag_origin {
    Some(origin) =>
      match cell {
        Some(target) => {
          if origin == target || !is_adjacent(origin, target) {
            return false
          }
          game_state.first_pick = None
          game_state.drag_swapped = true
          game_state.drag_origin = None
          game_state.drag_pointer_down = false
          begin_swap_forward_phase(origin, target)
          true
        }
        None => false
      }
    None => false
  }
}

///|
fn should_show_selected_frame() -> Bool {
  can_accept_input() && game_state.first_pick is Some(_)
}

///|
fn set_selection_frame_visible(visible : Bool) -> Unit {
  set_entity_visible(selected_frame_top_entity, visible)
  set_entity_visible(selected_frame_bottom_entity, visible)
  set_entity_visible(selected_frame_left_entity, visible)
  set_entity_visible(selected_frame_right_entity, visible)
}

///|
fn set_selection_frame_transform(
  entity : @entity.Entity,
  center_x : Double,
  center_y : Double,
  width : Double,
  height : Double,
  z : Double,
) -> Unit {
  @transform.transforms().set(
    entity,
    transform_xy(center_x - width * 0.5, center_y - height * 0.5, z),
  )
}

///|
fn update_selected_frame_visual() -> Unit {
  if !should_show_selected_frame() {
    set_selection_frame_visible(false)
    return
  }
  match game_state.first_pick {
    Some(cell) => {
      let (center, _) = cell_center(cell)
      let span = CELL_SIZE - BOARD_GAP
      let half = span * 0.5
      let thickness = SELECT_FRAME_THICKNESS
      let row_z = SELECT_FRAME_Z + cell.row.to_double() * 0.01
      let top_center_y = center[Y] - half + thickness * 0.5
      let bottom_center_y = center[Y] + half - thickness * 0.5
      let left_center_x = center[X] - half + thickness * 0.5
      let right_center_x = center[X] + half - thickness * 0.5
      set_selection_frame_transform(
        selected_frame_top_entity,
        center[X],
        top_center_y,
        span,
        thickness,
        row_z,
      )
      set_selection_frame_transform(
        selected_frame_bottom_entity,
        center[X],
        bottom_center_y,
        span,
        thickness,
        row_z,
      )
      set_selection_frame_transform(
        selected_frame_left_entity,
        left_center_x,
        center[Y],
        thickness,
        span,
        row_z,
      )
      set_selection_frame_transform(
        selected_frame_right_entity,
        right_center_x,
        center[Y],
        thickness,
        span,
        row_z,
      )
      set_selection_frame_visible(true)
    }
    None => set_selection_frame_visible(false)
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
  let left_just_pressed = @inputs.just_pressed_mouse.left_button
  let left_pressed = @inputs.mouse.left_button
  let left_just_released = @inputs.just_release_mouse.left_button
  let mouse_cell = choose_cell_from_mouse()
  if !can_accept_input() {
    if left_just_released || !left_pressed {
      clear_drag_state()
    }
    return
  }
  if left_just_pressed {
    game_state.drag_pointer_down = true
    game_state.drag_swapped = false
    game_state.drag_origin = mouse_cell
    match mouse_cell {
      Some(cell) => if handle_click_cell(cell) { clear_drag_state() }
      None => game_state.first_pick = None
    }
  }
  if left_pressed {
    ignore(try_drag_swap_to_cell(mouse_cell))
  }
  if left_just_released || !left_pressed {
    clear_drag_state()
  }
  if game_state.profile_enabled {
    game_state.profile_input_total += @time.elapsed() - started_at
  }
}

///|
pub fn update_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  let delta = @time.delta()

  if game_state.phase != GameOver {
    game_state.time_left -= delta
    if game_state.time_left <= 0.0 {
      game_state.time_left = 0.0
      game_state.phase = GameOver
      game_state.game_over_reason = "Time up"
      play_sound_ref(sound_gameover)
    } else {
      tick_resolution(delta)
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
  update_selected_frame_visual()
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

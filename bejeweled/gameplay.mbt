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
  aura_entity : @entity.Entity,
  kind : GemKind,
  flash : Bool,
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
  let sprite = @sprite.Sprite::from_image(
    gem_image(kind),
    custom_size=Some(size),
  )
  sprite.color = { r: 255U, g: 255U, b: 255U, a: clamped_alpha }
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    @transform.Transform::from_xyz(top_left[X], top_left[Y], z),
  )
  set_entity_visible(entity, true)
  if flash {
    let pulse = 0.5 +
      0.5 *
      @cmath.sin(@time.elapsed() * 11.0 + center[X] * 0.021 + center[Y] * 0.017)
    // Keep the glow energy high, but clip it to one board cell so it never bleeds
    // into neighbor cells.
    let aura_virtual_scale = 1.24 + 0.18 * pulse
    let aura_virtual_size_value = size_value * aura_virtual_scale
    let aura_clip_size_value = CELL_SIZE - BOARD_GAP
    let aura_size = @math.Vec2D(aura_clip_size_value, aura_clip_size_value)
    let aura_top_left = @math.Vec2D(
      center[X] - aura_size[X] * 0.5,
      center[Y] - aura_size[Y] * 0.5,
    )
    let clip_ratio_unclamped = aura_clip_size_value / aura_virtual_size_value
    let clip_ratio = if clip_ratio_unclamped >= 1.0 {
      1.0
    } else if clip_ratio_unclamped <= 0.01 {
      0.01
    } else {
      clip_ratio_unclamped
    }
    let source_size = gem_image_size(kind)
    let source_clip_size = @math.Vec2D(
      source_size[X] * clip_ratio,
      source_size[Y] * clip_ratio,
    )
    let source_clip_pos = @math.Vec2D(
      (source_size[X] - source_clip_size[X]) * 0.5,
      (source_size[Y] - source_clip_size[Y]) * 0.5,
    )
    let aura_color = {
      ..gem_aura_color(kind),
      a: clamp01(clamped_alpha * (0.18 + 0.26 * pulse)),
    }
    let aura_sprite = @sprite.Sprite::from_image(
      gem_image(kind),
      custom_size=Some(aura_size),
    )
    aura_sprite.rect = Some({
      position: source_clip_pos,
      size: source_clip_size,
    })
    aura_sprite.color = aura_color
    aura_sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
    @sprite.sprites().set(aura_entity, aura_sprite)
    @transform.transforms().set(
      aura_entity,
      @transform.Transform::from_xyz(
        aura_top_left[X],
        aura_top_left[Y],
        z - 0.35,
      ),
    )
    set_entity_visible(aura_entity, true)
  } else {
    set_entity_visible(aura_entity, false)
  }
}

///|
fn create_gem_entity(cell : Cell, kind : GemKind) -> Gem {
  let entity = @entity.Entity::new()
  let aura_entity = @entity.Entity::new()
  let (center, z) = cell_center(cell)
  set_gem_visual(entity, aura_entity, kind, false, center, z, 1.0, 1.0)
  Gem::{ kind, flash: false, entity, aura_entity }
}

///|
fn remove_gem_once(gem : Gem) -> Unit {
  match gem_entities.search_by(fn(existing) { existing == gem.entity }) {
    Some(index) => ignore(gem_entities.remove(index))
    None => ()
  }
  match
    gem_aura_entities.search_by(fn(existing) { existing == gem.aura_entity }) {
    Some(index) => ignore(gem_aura_entities.remove(index))
    None => ()
  }
  if gem.entity.is_alive() {
    gem.entity.destroy()
  }
  if gem.aura_entity.is_alive() {
    gem.aura_entity.destroy()
  }
}

///|
fn rebuild_visuals_from_board() -> Unit {
  for entity in gem_entities {
    if entity.is_alive() {
      entity.destroy()
    }
  }
  for entity in gem_aura_entities {
    if entity.is_alive() {
      entity.destroy()
    }
  }
  gem_entities.clear()
  gem_aura_entities.clear()
  gem_lookup.clear()
  for row in 0..<BOARD_ROWS {
    for col in 0..<BOARD_COLS {
      match board_get(row, col) {
        Some(kind) => {
          let cell = Cell::{ row, col }
          let gem = create_gem_entity(cell, kind)
          gem_entities.push(gem.entity)
          gem_aura_entities.push(gem.aura_entity)
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
  gem : Gem,
  from_cell : Cell,
  to_cell : Cell,
  duration : Double,
) -> GemTween {
  let (from_center, from_z) = cell_center(from_cell)
  let (to_center, to_z) = cell_center(to_cell)
  {
    entity: gem.entity,
    aura_entity: gem.aura_entity,
    kind: gem.kind,
    flash: gem.flash,
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
fn clear_tween(gem : Gem, cell : Cell) -> GemTween {
  let (center, z) = cell_center(cell)
  {
    entity: gem.entity,
    aura_entity: gem.aura_entity,
    kind: gem.kind,
    flash: gem.flash,
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
fn promote_flash_tween(gem : Gem, cell : Cell) -> GemTween {
  let (center, z) = cell_center(cell)
  {
    entity: gem.entity,
    aura_entity: gem.aura_entity,
    kind: gem.kind,
    flash: true,
    from_x: center[X],
    from_y: center[Y],
    to_x: center[X],
    to_y: center[Y],
    from_z: z,
    to_z: z,
    from_scale: 1.0,
    to_scale: 1.18,
    from_alpha: 1.0,
    to_alpha: 1.0,
    duration: CLEAR_SECONDS,
  }
}

///|
fn swap_gems_in_lookup(a : Cell, b : Cell) -> Unit {
  match gem_lookup.get(a) {
    Some(gem_a) =>
      match gem_lookup.get(b) {
        Some(gem_b) => {
          gem_lookup.set(a, gem_b)
          gem_lookup.set(b, gem_a)
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
    Some(gem_a) => tweens.push(move_tween(gem_a, a, b, SWAP_FORWARD_SECONDS))
    None => ()
  }
  match gem_lookup.get(b) {
    Some(gem_b) => tweens.push(move_tween(gem_b, b, a, SWAP_FORWARD_SECONDS))
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
              tweens.push(move_tween(gem_a, a, b, SWAP_ROLLBACK_SECONDS))
            None => ()
          }
          match gem_lookup.get(b) {
            Some(gem_b) =>
              tweens.push(move_tween(gem_b, b, a, SWAP_ROLLBACK_SECONDS))
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
  game_state.pending_match_count = matches.length()
  let (clear_cells, special_spawns) = plan_special_spawns(matches)
  game_state.pending_matches = clear_cells
  game_state.pending_special_spawns = special_spawns
  let special_anchor_cells : Map[Cell, Bool] = Map::new()
  for spawn in game_state.pending_special_spawns {
    special_anchor_cells.set(spawn.cell, true)
  }
  let tweens : Array[GemTween] = []
  for cell in matches {
    if gem_lookup.get(cell) is Some(gem) {
      if special_anchor_cells.get(cell) is Some(_) {
        tweens.push(promote_flash_tween(gem, cell))
      } else {
        tweens.push(clear_tween(gem, cell))
      }
    }
  }
  if tweens.is_empty() {
    game_state.pending_matches.clear()
    game_state.pending_match_count = 0
    game_state.pending_special_spawns.clear()
    set_input_ready_phase()
  } else {
    start_resolution_phase(Clear, tweens)
  }
}

///|
fn begin_deadlock_clear_phase() -> Unit {
  let clear_cells : Array[Cell] = []
  let tweens : Array[GemTween] = []
  for row in 0..<BOARD_ROWS {
    for col in 0..<BOARD_COLS {
      let cell = Cell::{ row, col }
      if board_get(row, col) is Some(_) {
        clear_cells.push(cell)
        if gem_lookup.get(cell) is Some(gem) {
          tweens.push(clear_tween(gem, cell))
        }
      }
    }
  }
  game_state.pending_matches = clear_cells
  game_state.pending_match_count = 0
  game_state.pending_special_spawns.clear()
  if tweens.is_empty() {
    if begin_fall_phase() {
      return
    }
    begin_cascade_check_phase()
  } else {
    start_resolution_phase(DeadlockClear, tweens)
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
              gem_lookup.set(to, gem)
              let distance = (write_row - row).to_double()
              tweens.push(
                move_tween(gem, from, to, FALL_SECONDS_PER_CELL * distance),
              )
            }
          }
          write_row -= 1
        }
        None => ()
      }
      row -= 1
    }
    let mut spawn_index = 0
    while write_row >= 0 {
      let kind = random_kind()
      board_set(write_row, col, Some(kind))
      let spawn_row = -1 - spawn_index
      spawn_index += 1
      let target = Cell::{ row: write_row, col }
      let spawn = Cell::{ row: spawn_row, col }
      let gem = create_gem_entity(target, kind)
      gem_lookup.set(target, gem)
      gem_entities.push(gem.entity)
      gem_aura_entities.push(gem.aura_entity)
      let distance = (write_row - spawn_row).to_double()
      tweens.push(
        move_tween(gem, spawn, target, REFILL_SECONDS_PER_CELL * distance),
      )
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
fn finalize_clear_phase() -> Unit {
  if game_state.pending_match_count <= 0 {
    game_state.pending_matches.clear()
    game_state.pending_special_spawns.clear()
    game_state.pending_match_count = 0
    return
  }
  let had_amethyst_bonus = game_state.score_bonus_remaining > 0.0
  let original_match_set : Map[Cell, Bool] = Map::new()
  for cell in game_state.pending_matches {
    original_match_set.set(cell, true)
  }
  for spawn in game_state.pending_special_spawns {
    original_match_set.set(spawn.cell, true)
  }
  let clear_set : Map[Cell, Bool] = Map::new()
  for cell in game_state.pending_matches {
    clear_set.set(cell, true)
  }
  let flash_round_multiplier = apply_flash_effects(clear_set)
  let mut extra_cleared = 0
  for cell, _ in clear_set {
    if original_match_set.get(cell) is Some(_) {
      continue
    }
    if board_get(cell.row, cell.col) is Some(_) {
      extra_cleared += 1
    }
  }
  let scored_count = game_state.pending_match_count + extra_cleared
  let mut earned_score = score_for_matches(scored_count)
  if had_amethyst_bonus {
    earned_score *= FLASH_AMETHYST_SCORE_MULTIPLIER
  }
  earned_score *= flash_round_multiplier
  game_state.score += earned_score
  play_sound_ref(sound_match)
  if game_state.cascade_depth > 0 || scored_count >= 6 {
    play_sound_ref(sound_cascade)
  }
  for cell, _ in clear_set {
    board_set(cell.row, cell.col, None)
    if gem_lookup.get(cell) is Some(gem) {
      gem_lookup.remove(cell)
      remove_gem_once(gem)
    }
  }
  for spawn in game_state.pending_special_spawns {
    let cell = spawn.cell
    if clear_set.get(cell) is Some(_) {
      continue
    }
    board_set(cell.row, cell.col, Some(spawn.kind))
    match gem_lookup.get(cell) {
      Some(gem) => {
        let promoted = { ..gem, kind: spawn.kind, flash: true }
        gem_lookup.set(cell, promoted)
      }
      None => {
        let created = create_gem_entity(cell, spawn.kind)
        let promoted = { ..created, flash: true }
        gem_lookup.set(cell, promoted)
        gem_entities.push(promoted.entity)
        gem_aura_entities.push(promoted.aura_entity)
      }
    }
  }
  game_state.pending_matches.clear()
  game_state.pending_special_spawns.clear()
  game_state.pending_match_count = 0
}

///|
fn finalize_deadlock_clear_phase() -> Unit {
  for cell in game_state.pending_matches {
    board_set(cell.row, cell.col, None)
    if gem_lookup.get(cell) is Some(gem) {
      gem_lookup.remove(cell)
      remove_gem_once(gem)
    }
  }
  game_state.pending_matches.clear()
  game_state.pending_special_spawns.clear()
  game_state.pending_match_count = 0
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
      game_state.pending_match_count = 0
      game_state.pending_special_spawns.clear()
      set_input_ready_phase()
    }
    Clear => {
      finalize_clear_phase()
      if begin_fall_phase() {
        return
      }
      begin_cascade_check_phase()
    }
    Fall => begin_cascade_check_phase()
    DeadlockClear => {
      finalize_deadlock_clear_phase()
      if begin_fall_phase() {
        return
      }
      begin_cascade_check_phase()
    }
    CascadeCheck => {
      let matches = find_matches()
      if matches.is_empty() {
        game_state.pending_swap_a = None
        game_state.pending_swap_b = None
        game_state.pending_matches.clear()
        game_state.pending_match_count = 0
        game_state.pending_special_spawns.clear()
        game_state.cascade_depth = 0
        if has_playable_swap() {
          set_input_ready_phase()
        } else {
          begin_deadlock_clear_phase()
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
    set_gem_visual(
      tween.entity,
      tween.aura_entity,
      tween.kind,
      tween.flash,
      center,
      z,
      scale,
      alpha,
    )
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
    "[bejeweled][profile] elapsed=\{sample_s}s frames=\{game_state.profile_frame_count} fps_avg=\{fps_avg} fps_window=\{fps_window} fps_frame_dt=\{fps_frame_dt} fps_min=\{min_fps} input_avg_ms=\{input_ms} update_avg_ms=\{update_ms} render_avg_ms=\{render_ms} slowest_frame_ms=\{slowest_frame_ms} score=\{game_state.score} time_left=\{game_state.time_left}",
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
    let time_scale = effect_time_scale_for_tick(delta)
    game_state.time_left -= delta * time_scale
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
fn timer_text() -> String {
  let remaining = @cmath.floor(game_state.time_left).to_int()
  let seconds = remaining % 60
  let minutes = remaining / 60
  let seconds_text = if seconds < 10 { "0\{seconds}" } else { "\{seconds}" }
  "TIME\n\{minutes}:\{seconds_text}"
}

///|
fn score_text() -> String {
  let fps_text = if game_state.debug_fps {
    let fps = @raylib.get_fps()
    "\nFPS \{fps}"
  } else {
    ""
  }
  "SCORE\n\{game_state.score}\{fps_text}"
}

///|
fn overlay_text() -> String {
  "GAME OVER\n\{game_state.game_over_reason}\nScore \{game_state.score}\nPress R, Enter, or Space to restart"
}

///|
pub fn render_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  let timer = timer_text()
  if game_state.timer_text_cache != timer {
    @ui.texts().set(timer_text_entity, @ui.Text::new(timer))
    game_state.timer_text_cache = timer
  }
  let score = score_text()
  if game_state.score_text_cache != score {
    @ui.texts().set(score_text_entity, @ui.Text::new(score))
    game_state.score_text_cache = score
  }
  let hint = selected_hint_text()
  if game_state.hint_text_cache != hint {
    @ui.texts().set(hint_entity, @ui.Text::new(hint))
    game_state.hint_text_cache = hint
  }
  set_entity_visible(timer_fx_entity, game_state.time_freeze_remaining > 0.0)
  set_entity_visible(score_fx_entity, game_state.score_bonus_remaining > 0.0)
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

///|
let bejeweled_font_registered : Ref[Bool] = { val: false }

///|
fn register_bejeweled_font_once() -> Unit {
  if bejeweled_font_registered.val {
    return
  }
  ignore(@asset.load_font(BEJEWELED_FONT_PATH, family=BEJEWELED_FONT_FAMILY))
  bejeweled_font_registered.val = true
}

///|
fn setup_board_background() -> Unit {
  panel_entity(
    board_bg_entity,
    color_rgba(204U, 209U, 217U, 1.0),
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5,
    VIEWPORT_WIDTH,
    VIEWPORT_HEIGHT,
    0.0,
  )
}

///|
fn setup_camera() -> Unit {
  ()
}

///|
fn setup_board_entities() -> Unit {
  let board_width = BOARD_COLS.to_double() * CELL_SIZE - BOARD_GAP
  let board_height = BOARD_ROWS.to_double() * CELL_SIZE - BOARD_GAP
  let board_center_x = BOARD_ORIGIN_X + BOARD_COLS.to_double() * CELL_SIZE * 0.5
  let board_center_y = BOARD_ORIGIN_Y + BOARD_ROWS.to_double() * CELL_SIZE * 0.5
  panel_entity(
    board_panel_entity,
    color_rgba(66U, 72U, 84U, 0.96),
    board_center_x,
    board_center_y,
    board_width,
    board_height,
    50.0,
  )
}

///|
fn setup_selection_frame() -> Unit {
  let frame_color = color_rgba(64U, 156U, 255U, 0.9)
  let span = CELL_SIZE - BOARD_GAP
  panel_entity(
    selected_frame_top_entity,
    frame_color,
    0.0,
    0.0,
    span,
    SELECT_FRAME_THICKNESS,
    SELECT_FRAME_Z,
  )
  panel_entity(
    selected_frame_bottom_entity,
    frame_color,
    0.0,
    0.0,
    span,
    SELECT_FRAME_THICKNESS,
    SELECT_FRAME_Z,
  )
  panel_entity(
    selected_frame_left_entity,
    frame_color,
    0.0,
    0.0,
    SELECT_FRAME_THICKNESS,
    span,
    SELECT_FRAME_Z,
  )
  panel_entity(
    selected_frame_right_entity,
    frame_color,
    0.0,
    0.0,
    SELECT_FRAME_THICKNESS,
    span,
    SELECT_FRAME_Z,
  )
  set_entity_visible(selected_frame_top_entity, false)
  set_entity_visible(selected_frame_bottom_entity, false)
  set_entity_visible(selected_frame_left_entity, false)
  set_entity_visible(selected_frame_right_entity, false)
}

///|
fn reset_run_state() -> Unit {
  game_state.phase = Playing
  game_state.resolution_phase = InputReady
  game_state.resolution_elapsed = 0.0
  game_state.resolution_duration = 0.0
  game_state.score = 0
  game_state.time_left = GAME_TIME_LIMIT
  game_state.time_freeze_remaining = 0.0
  game_state.score_bonus_remaining = 0.0
  game_state.first_pick = None
  game_state.drag_origin = None
  game_state.drag_pointer_down = false
  game_state.drag_swapped = false
  game_state.pending_swap_a = None
  game_state.pending_swap_b = None
  game_state.pending_matches.clear()
  game_state.pending_match_count = 0
  game_state.pending_special_spawns.clear()
  game_state.active_tweens.clear()
  game_state.cascade_depth = 0
  game_state.game_over_reason = ""
  game_state.timer_text_cache = ""
  game_state.score_text_cache = ""
  game_state.overlay_text_cache = ""
  board.clear()
  for _ in 0..<(BOARD_ROWS * BOARD_COLS) {
    board.push(None)
  }
  fill_board_without_initial_matches()
  rebuild_visuals_from_board()
  if has_playable_swap() {
    set_input_ready_phase()
  } else {
    begin_deadlock_clear_phase()
  }
}

///|
fn setup_debug_capture() -> Unit {
  game_state.debug_capture_enabled = env_flag_enabled(DEBUG_CAPTURE_ENV)
  game_state.debug_capture_started_at = @time.elapsed()
  game_state.debug_capture_taken = false
}

///|
fn setup_profile() -> Unit {
  game_state.profile_enabled = env_flag_enabled(BEJEWELED_PROFILE_ENV)
  game_state.profile_started_at = @time.elapsed()
  game_state.profile_last_report_at = game_state.profile_started_at
  game_state.profile_frame_count = 0
  game_state.profile_input_total = 0.0
  game_state.profile_update_total = 0.0
  game_state.profile_render_total = 0.0
  game_state.profile_slowest_frame = 0.0
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  register_bejeweled_font_once()
  setup_camera()
  setup_board_background()
  setup_static_text()
  setup_flash_gem_legend()
  setup_board_entities()
  setup_selection_frame()
  ensure_sounds_loaded()
  setup_debug_capture()
  setup_profile()
  reset_run_state()
  if game_state.profile_enabled {
    game_state.profile_started_at = @time.elapsed()
    game_state.profile_last_report_at = game_state.profile_started_at
    game_state.profile_frame_count = 0
    game_state.profile_input_total = 0.0
    game_state.profile_update_total = 0.0
    game_state.profile_render_total = 0.0
    game_state.profile_slowest_frame = 0.0
  }
}

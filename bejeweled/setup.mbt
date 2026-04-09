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
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
fn set_entity_visible(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn transform_xy(x : Double, y : Double, z : Double) -> @transform.Transform {
  @transform.Transform::from_xyz(x, y, z)
}

///|
fn text_entity(
  entity : @entity.Entity,
  content : String,
  x : Double,
  y : Double,
  size_px : Int,
  color_css : String,
  z : Double,
) -> Unit {
  @ui.texts().set(entity, @ui.Text::new(content))
  @ui.text_fonts().set(
    entity,
    @ui.TextFont::from_css("\{size_px}px \{BEJEWELED_FONT_FAMILY}"),
  )
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color_css))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2D(-0.5, 0.5)))
  @transform.transforms().set(entity, transform_xy(x, y, z))
  set_entity_visible(entity, true)
}

///|
fn panel_entity(
  entity : @entity.Entity,
  color : @render.Color,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  z : Double,
) -> Unit {
  let sprite = @sprite.Sprite::from_color(color, @math.Vec2D(w, h))
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_xy(x - w * 0.5, y - h * 0.5, z))
  set_entity_visible(entity, true)
}

///|
fn setup_board_background() -> Unit {
  panel_entity(
    board_bg_entity,
    color_rgba(10U, 15U, 28U, 1.0),
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
fn setup_static_text() -> Unit {
  text_entity(
    title_entity, "BEJEWELED", 32.0, 24.0, 40, "rgb(249,251,255)", 100.0,
  )
  text_entity(hud_entity, "", 32.0, 74.0, 24, "rgb(221,228,241)", 100.0)
  text_entity(hint_entity, "", 32.0, 654.0, 20, "rgb(196,205,220)", 100.0)
  text_entity(
    overlay_text_entity,
    "",
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5 - 18.0,
    44,
    "rgb(255,255,255)",
    400.0,
  )
  panel_entity(
    overlay_entity,
    color_rgba(0U, 0U, 0U, 0.58),
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5,
    VIEWPORT_WIDTH,
    VIEWPORT_HEIGHT,
    390.0,
  )
  set_entity_visible(overlay_entity, false)
  set_entity_visible(overlay_text_entity, false)
}

///|
fn setup_board_entities() -> Unit {
  board_cell_entities.clear()
  for row in 0..<BOARD_ROWS {
    for col in 0..<BOARD_COLS {
      let entity = @entity.Entity::new()
      let cell_x = BOARD_ORIGIN_X +
        col.to_double() * CELL_SIZE +
        CELL_SIZE * 0.5
      let cell_y = BOARD_ORIGIN_Y +
        row.to_double() * CELL_SIZE +
        CELL_SIZE * 0.5
      panel_entity(
        entity,
        color_rgba(19U, 30U, 50U, 0.95),
        cell_x,
        cell_y,
        CELL_SIZE - BOARD_GAP,
        CELL_SIZE - BOARD_GAP,
        50.0,
      )
      board_cell_entities.push(entity)
    }
  }
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
  game_state.moves_left = MOVE_LIMIT
  game_state.time_left = GAME_TIME_LIMIT
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
  game_state.hud_text_cache = ""
  game_state.hint_text_cache = ""
  game_state.overlay_text_cache = ""
  board.clear()
  for _ in 0..<(BOARD_ROWS * BOARD_COLS) {
    board.push(None)
  }
  fill_board_without_initial_matches()
  rebuild_visuals_from_board()
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

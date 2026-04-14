///|
fn set_rotated_rect_entity(
  entity : @entity.Entity,
  position : @math.Vec2,
  size : @math.Vec2,
  color : String,
  zindex : Int,
  _angle : Double,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_color(@sprite.color_from_css(color), size)
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  let top_left = vec2(position[X] - size[X] * 0.5, position[Y] - size[Y] * 0.5)
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, entity_transform_2d(top_left, zindex))
  show_entity(entity)
}

///|
fn sync_background() -> Unit {
  set_rect_entity(
    background_entity,
    vec2(VIEWPORT_WIDTH * 0.5, VIEWPORT_HEIGHT * 0.5),
    vec2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT),
    "rgb(19, 28, 38)",
    BOARD_Z,
  )
}

///|
fn sync_board_box() -> Unit {
  let width = ARENA_COLS.to_double() * TILE_SIZE + 20.0
  let height = ARENA_ROWS.to_double() * TILE_SIZE + 20.0
  set_rect_entity(
    box_entity,
    vec2(
      ARENA_ORIGIN_X + ARENA_COLS.to_double() * TILE_SIZE * 0.5,
      ARENA_ORIGIN_Y + ARENA_ROWS.to_double() * TILE_SIZE * 0.5,
    ),
    vec2(width, height),
    "rgb(25, 38, 48)",
    BOARD_Z + 1,
  )
}

///|
fn sync_tile_entities() -> Unit {
  for y in 0..<ARENA_ROWS {
    for x in 0..<ARENA_COLS {
      let entity = tile_entities[tile_index(x, y)]
      let center = grid_to_world_center(x, y)
      let color = match tile_at(x, y) {
        Floor => FLOOR_COLOR
        Steel => WALL_COLOR
        Brick => BRICK_COLOR
      }
      set_rect_entity(
        entity,
        center,
        vec2(TILE_SIZE - 2.0, TILE_SIZE - 2.0),
        color,
        TILE_Z_BASE,
      )
    }
  }
}

///|
fn setup_tile_entities_once() -> Unit {
  if tile_entities.length() > 0 {
    return
  }
  for _ in 0..<(ARENA_COLS * ARENA_ROWS) {
    tile_entities.push(@entity.Entity::new())
  }
}

///|
fn setup_menu_entities() -> Unit {
  set_text_entity_center(
    title_entity,
    "TANK BATTLE",
    vec2(VIEWPORT_WIDTH * 0.5, 68.0),
    TITLE_COLOR,
    42.0,
    HUD_Z + 2,
  )
  set_text_entity_center(
    status_entity,
    "",
    vec2(VIEWPORT_WIDTH * 0.5, 112.0),
    HUD_MUTED_COLOR,
    24.0,
    HUD_Z + 2,
  )
  set_text_entity_center(
    round_entity,
    "",
    vec2(VIEWPORT_WIDTH * 0.5, 300.0),
    TITLE_COLOR,
    44.0,
    HUD_Z + 4,
  )
  set_text_entity_center(
    hint_entity,
    "",
    vec2(VIEWPORT_WIDTH * 0.5, HUD_BOTTOM_Y),
    HUD_TEXT_COLOR,
    22.0,
    HUD_Z + 2,
  )
  set_text_entity_center(
    fps_entity,
    "",
    vec2(VIEWPORT_WIDTH - 112.0, 20.0),
    HUD_MUTED_COLOR,
    20.0,
    HUD_Z + 2,
  )
  set_text_entity_center(
    menu_option_entities[0],
    "",
    vec2(VIEWPORT_WIDTH * 0.5, 420.0),
    HUD_TEXT_COLOR,
    30.0,
    HUD_Z + 3,
  )
  set_text_entity_center(
    menu_option_entities[1],
    "",
    vec2(VIEWPORT_WIDTH * 0.5, 472.0),
    HUD_TEXT_COLOR,
    30.0,
    HUD_Z + 3,
  )
}

///|
fn setup_tank_entities() -> Unit {
  ensure_entity_alive(player_body_entity)
  ensure_entity_alive(player_barrel_entity)
  hide_entity(player_body_entity)
  hide_entity(player_barrel_entity)

  for i in 0..<enemy_body_entities.length() {
    ensure_entity_alive(enemy_body_entities[i])
    ensure_entity_alive(enemy_barrel_entities[i])
    hide_entity(enemy_body_entities[i])
    hide_entity(enemy_barrel_entities[i])
  }
}

///|
fn setup_runtime_entities() -> Unit {
  sync_background()
  sync_board_box()
  setup_tile_entities_once()
  setup_menu_entities()
  setup_tank_entities()
}

///|
fn reset_player_state(center : @math.Vec2) -> Unit {
  player.alive = true
  player.center = center
  player.direction = Up
  player.turret_direction = Up
  player.reload_timer = 0.0
}

///|
fn reset_enemy_slot(
  index : Int,
  center : @math.Vec2,
  direction : Direction,
) -> Unit {
  enemies[index].alive = true
  enemies[index].center = center
  enemies[index].direction = direction
  enemies[index].turret_direction = direction
  enemies[index].reload_timer = 0.2 + index.to_double() * 0.12
  enemies[index].think_timer = index.to_double() * 0.15
}

///|
fn setup_level_from_config(level : LevelConfig) -> Unit {
  clear_tiles()
  for y in 0..<ARENA_ROWS {
    for x in 0..<ARENA_COLS {
      set_tile_code(x, y, level.tiles[y][x])
    }
  }
  sync_tile_entities()
  reset_player_state(level.player_spawn)
  hide_all_enemies()
  for i in 0..<level.enemy_spawns.length() {
    if i < enemies.length() {
      let dir = if i % 2 == 0 { Left } else { Down }
      reset_enemy_slot(i, level.enemy_spawns[i], dir)
    }
  }
  clear_bullets()
}

///|
fn setup_menu_phase() -> Unit {
  phase.val = MainMenu
  clear_bullets()
  set_menu_option(Start)
  update_text_entity_if_changed(title_entity, last_title_text, "TANK BATTLE")
  update_text_entity_if_changed(
    status_entity, last_status_text, "A/D changes level. W/S selects Start or Exit.",
  )
  update_text_entity_if_changed(round_entity, last_round_text, "")
  update_text_entity_if_changed(
    hint_entity, last_hint_text, "Enter/Space start   Esc exits   F3 toggles FPS",
  )
  update_text_entity_if_changed(fps_entity, last_fps_text, "")
  update_text_entity_if_changed(
    menu_option_entities[0],
    last_menu_start_text,
    "> START GAME",
  )
  update_text_entity_if_changed(
    menu_option_entities[1],
    last_menu_exit_text,
    "  EXIT",
  )
  show_entity(title_entity)
  show_entity(status_entity)
  show_entity(round_entity)
  show_entity(hint_entity)
  show_entity(fps_entity)
  show_entity(menu_option_entities[0])
  show_entity(menu_option_entities[1])
  hide_entity(player_body_entity)
  hide_entity(player_barrel_entity)
  for i in 0..<enemy_body_entities.length() {
    hide_entity(enemy_body_entities[i])
    hide_entity(enemy_barrel_entities[i])
  }
}

///|
fn setup_playing_phase() -> Unit {
  phase.val = Playing
  update_text_entity_if_changed(title_entity, last_title_text, "TANK BATTLE")
  update_text_entity_if_changed(status_entity, last_status_text, "")
  update_text_entity_if_changed(round_entity, last_round_text, "")
  update_text_entity_if_changed(
    hint_entity, last_hint_text, "Move: WASD / Arrows   Aim: Mouse   Fire: LMB / Space   R restart   Esc menu",
  )
  update_text_entity_if_changed(fps_entity, last_fps_text, "")
  hide_entity(menu_option_entities[0])
  hide_entity(menu_option_entities[1])
  show_entity(player_body_entity)
  show_entity(player_barrel_entity)
  for i in 0..<enemy_body_entities.length() {
    if enemies[i].alive {
      show_entity(enemy_body_entities[i])
      show_entity(enemy_barrel_entities[i])
    } else {
      hide_entity(enemy_body_entities[i])
      hide_entity(enemy_barrel_entities[i])
    }
  }
}

///|
fn setup_round_over_phase() -> Unit {
  phase.val = RoundOver
  clear_bullets()
  update_text_entity_if_changed(title_entity, last_title_text, "TANK BATTLE")
  update_text_entity_if_changed(status_entity, last_status_text, phase_label())
  update_text_entity_if_changed(round_entity, last_round_text, round_title())
  update_text_entity_if_changed(
    hint_entity, last_hint_text, "Enter/Space restart   R retry   Esc menu",
  )
  show_entity(menu_option_entities[0])
  show_entity(menu_option_entities[1])
  hide_entity(player_body_entity)
  hide_entity(player_barrel_entity)
  for i in 0..<enemy_body_entities.length() {
    hide_entity(enemy_body_entities[i])
    hide_entity(enemy_barrel_entities[i])
  }
}

///|
fn startup_level_setup() -> Unit {
  set_profile_from_env()
  register_tankbattle_font_once()
  let startup_started_at = @time.elapsed()

  let init_levels_started_at = @time.elapsed()
  init_levels_once()
  profile_phase("startup/init-levels", init_levels_started_at)

  let runtime_entities_started_at = @time.elapsed()
  setup_runtime_entities()
  profile_phase("startup/runtime-entities", runtime_entities_started_at)

  let sound_started_at = @time.elapsed()
  init_sound_bank_once()
  profile_phase("startup/audio", sound_started_at)

  let capture_started_at = @time.elapsed()
  set_capture_from_env()
  profile_phase("startup/capture-flags", capture_started_at)

  let window_state_started_at = @time.elapsed()
  if @raylib.is_window_fullscreen() {
    @raylib.clear_window_state(@raylib.FlagFullscreenMode)
  }
  profile_phase("startup/window-state", window_state_started_at)

  let scene_started_at = @time.elapsed()
  if debug_capture_enabled.val {
    setup_level_from_config(level_at(current_level.val))
    setup_playing_phase()
  } else {
    setup_menu_phase()
  }
  profile_phase("startup/first-scene", scene_started_at)
  if profile_enabled.val {
    profile_started_at.val = @time.elapsed()
    profile_last_report_at.val = profile_started_at.val
    profile_frame_count.val = 0
    profile_input_total.val = 0.0
    profile_sim_total.val = 0.0
    profile_render_total.val = 0.0
    profile_slowest_frame.val = 0.0
  }
  profile_phase("startup/total", startup_started_at)
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  startup_level_setup()
}

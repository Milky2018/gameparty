///|
fn register_font_once() -> Unit {
  if font_registered.val {
    return
  }
  ignore(@asset.load_font(FONT_PATH, family=FONT_FAMILY))
  font_registered.val = true
}

///|
fn register_assets_once() -> Unit {
  if map_image_handle.val is Some(_) {
    return
  }

  map_image_handle.val = Some(@asset.load_image(MAP_IMAGE_PATH))
  player_sheet_handle.val = Some(@asset.load_image(PLAYER_SHEET_PATH))
  enemy_sheet_handle.val = Some(@asset.load_image(ENEMY_SHEET_PATH))
  powerup_sheet_handle.val = Some(@asset.load_image(POWERUP_SHEET_PATH))
  shield_sheet_handle.val = Some(@asset.load_image(SHIELD_SHEET_PATH))
  spawn_sheet_handle.val = Some(@asset.load_image(SPAWN_SHEET_PATH))
  bullet_sheet_handle.val = Some(@asset.load_image(BULLET_SHEET_PATH))
  title_image_handle.val = Some(@asset.load_image(TITLE_IMAGE_PATH))
  game_over_image_handle.val = Some(@asset.load_image(GAME_OVER_IMAGE_PATH))
  flag_image_handle.val = Some(@asset.load_image(FLAG_IMAGE_PATH))
  ice_image_handle.val = Some(@asset.load_image(ICE_TILE_PATH))

  bullet_explosion_handles.push(@asset.load_image(BULLET_EXPLOSION_1_PATH))
  bullet_explosion_handles.push(@asset.load_image(BULLET_EXPLOSION_2_PATH))
  bullet_explosion_handles.push(@asset.load_image(BULLET_EXPLOSION_3_PATH))
  big_explosion_handles.push(@asset.load_image(BIG_EXPLOSION_1_PATH))
  big_explosion_handles.push(@asset.load_image(BIG_EXPLOSION_2_PATH))
  big_explosion_handles.push(@asset.load_image(BIG_EXPLOSION_3_PATH))
  big_explosion_handles.push(@asset.load_image(BIG_EXPLOSION_4_PATH))
  big_explosion_handles.push(@asset.load_image(BIG_EXPLOSION_5_PATH))

  sfx_menu_handle.val = Some(@asset.load_audio(SFX_MENU_PATH))
  sfx_switch_handle.val = Some(@asset.load_audio(SFX_SWITCH_PATH))
  sfx_fire_handle.val = Some(@asset.load_audio(SFX_FIRE_PATH))
  sfx_bullet_explosion_handle.val = Some(
    @asset.load_audio(SFX_BULLET_EXPLOSION_PATH),
  )
  sfx_big_explosion_handle.val = Some(@asset.load_audio(SFX_BIG_EXPLOSION_PATH))
  sfx_hit_1_handle.val = Some(@asset.load_audio(SFX_HIT_1_PATH))
  sfx_hit_2_handle.val = Some(@asset.load_audio(SFX_HIT_2_PATH))
  sfx_powerup_appear_handle.val = Some(
    @asset.load_audio(SFX_POWERUP_APPEAR_PATH),
  )
  sfx_powerup_pick_handle.val = Some(@asset.load_audio(SFX_POWERUP_PICK_PATH))
  sfx_pause_handle.val = Some(@asset.load_audio(SFX_PAUSE_PATH))
  sfx_game_over_handle.val = Some(@asset.load_audio(SFX_GAME_OVER_PATH))
}

///|
fn play_sfx(handle : Ref[@asset.AudioHandle?], volume? : Double = 0.72) -> Unit {
  match handle.val {
    Some(source) => @audio.play_one_shot(source, volume~)
    None => ()
  }
}

///|
fn setup_static_ui() -> Unit {
  panel_entity(
    background_entity,
    BACKGROUND_COLOR,
    vec2(VIEWPORT_WIDTH * 0.5, VIEWPORT_HEIGHT * 0.5),
    vec2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT),
    0.0,
  )
  panel_entity(
    board_entity,
    BOARD_BG_COLOR,
    vec2(BOARD_LEFT + BOARD_WIDTH * 0.5, BOARD_TOP + BOARD_HEIGHT * 0.5),
    vec2(BOARD_WIDTH + 8.0, BOARD_HEIGHT + 8.0),
    2.0,
  )
  panel_entity(
    hud_entity,
    PANEL_COLOR,
    vec2(HUD_LEFT + HUD_WIDTH * 0.5, HUD_TOP + BOARD_HEIGHT * 0.5),
    vec2(HUD_WIDTH, BOARD_HEIGHT + 8.0),
    2.0,
  )

  set_sprite_entity(
    title_image_entity,
    title_image_handle.val.unwrap(),
    vec2(VIEWPORT_WIDTH * 0.5, 196.0),
    vec2(360.0, 212.0),
    HUD_Z.to_double(),
  )
  set_sprite_entity(
    game_over_image_entity,
    game_over_image_handle.val.unwrap(),
    vec2(VIEWPORT_WIDTH * 0.5, 314.0),
    vec2(280.0, 44.0),
    OVERLAY_Z.to_double(),
  )
  set_sprite_entity(
    hud_lives_icon_entity,
    player_sheet_handle.val.unwrap(),
    vec2(HUD_LEFT + 32.0, HUD_TOP + 176.0),
    vec2(26.0, 26.0),
    HUD_Z.to_double(),
    rect=Some(
      atlas_rect(
        TANK_ATLAS_CELL,
        TANK_ATLAS_CELL,
        8,
        player_sprite_index(Basic, Up, 0),
      ),
    ),
  )
  set_sprite_entity(
    hud_flag_entity,
    flag_image_handle.val.unwrap(),
    vec2(HUD_LEFT + 32.0, HUD_TOP + 246.0),
    vec2(26.0, 26.0),
    HUD_Z.to_double(),
  )

  set_text_entity_center(
    menu_one_player_entity,
    "",
    vec2(VIEWPORT_WIDTH * 0.5, 426.0),
    320.0,
    32.0,
    26,
    HUD_TEXT_COLOR,
    HUD_Z.to_double(),
  )
  set_text_entity_center(
    menu_exit_entity,
    "",
    vec2(VIEWPORT_WIDTH * 0.5, 466.0),
    320.0,
    32.0,
    26,
    HUD_TEXT_COLOR,
    HUD_Z.to_double(),
  )
  set_text_entity_center(
    hud_lives_text_entity,
    "",
    vec2(HUD_LEFT + 92.0, HUD_TOP + 176.0),
    96.0,
    28.0,
    22,
    HUD_TEXT_COLOR,
    HUD_Z.to_double(),
  )
  set_text_entity_center(
    hud_stage_text_entity,
    "",
    vec2(HUD_LEFT + 92.0, HUD_TOP + 246.0),
    96.0,
    28.0,
    22,
    HUD_TEXT_COLOR,
    HUD_Z.to_double(),
  )
  set_text_entity_center(
    hud_status_text_entity,
    "",
    vec2(HUD_LEFT + HUD_WIDTH * 0.5, HUD_TOP + BOARD_HEIGHT - 34.0),
    HUD_WIDTH - 20.0,
    30.0,
    15,
    HUD_MUTED_COLOR,
    HUD_Z.to_double(),
  )
  set_text_entity_center(
    overlay_text_entity,
    "",
    vec2(VIEWPORT_WIDTH * 0.5, 74.0),
    380.0,
    30.0,
    28,
    OVERLAY_COLOR,
    OVERLAY_Z.to_double(),
  )
  set_text_entity_center(
    overlay_subtext_entity,
    "",
    vec2(VIEWPORT_WIDTH * 0.5, 106.0),
    480.0,
    24.0,
    16,
    HUD_TEXT_COLOR,
    OVERLAY_Z.to_double(),
  )
  set_text_entity_center(
    fps_text_entity,
    "",
    vec2(VIEWPORT_WIDTH - 62.0, 20.0),
    120.0,
    24.0,
    14,
    HUD_MUTED_COLOR,
    OVERLAY_Z.to_double(),
  )
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  ensure_runtime_storage()
  register_font_once()
  register_assets_once()
  setup_static_ui()
  reset_menu_state()
}

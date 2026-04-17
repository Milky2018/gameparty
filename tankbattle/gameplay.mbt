///|
let debug_toggle_latch : Ref[Bool] = { val: false }

///|
fn request_exit() -> Unit {
  @system.exit()
}

///|
fn begin_playing_phase() -> Unit {
  campaign_state.phase = Playing
  campaign_state.phase_seconds = 0.0
}

///|
fn return_to_menu() -> Unit {
  reset_menu_state()
}

///|
fn toggle_pause() -> Unit {
  match campaign_state.phase {
    Playing => {
      campaign_state.phase = Paused
      campaign_state.phase_seconds = 0.0
      play_sfx(sfx_pause_handle, volume=0.55)
    }
    Paused => {
      campaign_state.phase = Playing
      campaign_state.phase_seconds = 0.0
      play_sfx(sfx_pause_handle, volume=0.55)
    }
    _ => ()
  }
}

///|
fn activate_menu_option(option : MenuOption) -> Unit {
  match option {
    OnePlayer => {
      play_sfx(sfx_menu_handle, volume=0.65)
      start_new_campaign()
    }
    Exit => request_exit()
  }
}

///|
fn previous_menu_option(option : MenuOption) -> MenuOption {
  match option {
    OnePlayer => Exit
    Exit => OnePlayer
  }
}

///|
fn next_menu_option(option : MenuOption) -> MenuOption {
  match option {
    OnePlayer => Exit
    Exit => OnePlayer
  }
}

///|
fn menu_label(option : MenuOption) -> String {
  match option {
    OnePlayer => "1 PLAYER"
    Exit => "EXIT"
  }
}

///|
fn powerup_label(kind : PowerUpKind) -> String {
  match kind {
    Helmet => "HELMET"
    Timer => "TIMER"
    Shovel => "SHOVEL"
    Star => "STAR"
    Grenade => "GRENADE"
    Tank => "TANK"
  }
}

///|
fn rank_label(rank : TankRank) -> String {
  match rank {
    Basic => "I"
    Speed => "II"
    Twin => "III"
    Power => "IV"
  }
}

///|
fn active_menu_line(option : MenuOption) -> String {
  if campaign_state.menu_option == option {
    "> \{menu_label(option)} <"
  } else {
    menu_label(option)
  }
}

///|
fn player_input_direction() -> Direction? {
  if @inputs.is_pressed(KeyW) || @inputs.is_pressed(ArrowUp) {
    Some(Up)
  } else if @inputs.is_pressed(KeyD) || @inputs.is_pressed(ArrowRight) {
    Some(Right)
  } else if @inputs.is_pressed(KeyS) || @inputs.is_pressed(ArrowDown) {
    Some(Down)
  } else if @inputs.is_pressed(KeyA) || @inputs.is_pressed(ArrowLeft) {
    Some(Left)
  } else {
    None
  }
}

///|
fn current_animation_frame(frame_count : Int, fps? : Double = 8.0) -> Int {
  (@time.elapsed() * fps).floor().to_int() % frame_count
}

///|
fn queue_icon_center(index : Int) -> @math.Vec2 {
  let col = index % 2
  let row = index / 2
  vec2(
    HUD_LEFT + 34.0 + col.to_double() * 22.0,
    HUD_TOP + 32.0 + row.to_double() * 18.0,
  )
}

///|
fn tile_sheet_index(tile : TerrainKind) -> Int {
  match tile {
    Brick => 0
    Steel => 1
    Forest => 2
    Water => if current_animation_frame(2, fps=3.0) == 0 { 3 } else { 4 }
    Base => if campaign_state.base_destroyed { 6 } else { 5 }
    _ => 0
  }
}

///|
fn sync_terrain_tile(index : Int, x : Int, y : Int) -> Unit {
  let tile = tile_at(x, y)
  let center = tile_center(x, y)
  let base_entity = terrain_entities[index]
  let overlay_entity = terrain_overlay_entities[index]
  match tile {
    Empty => {
      hide_entity(base_entity)
      hide_entity(overlay_entity)
    }
    Forest => {
      hide_entity(base_entity)
      set_sprite_entity(
        overlay_entity,
        map_image_handle.val.unwrap(),
        center,
        vec2(TILE_SIZE, TILE_SIZE),
        FOREST_Z.to_double(),
        rect=Some(atlas_rect(32.0, 32.0, 7, tile_sheet_index(tile))),
      )
    }
    Ice => {
      set_sprite_entity(
        base_entity,
        ice_image_handle.val.unwrap(),
        center,
        vec2(TILE_SIZE, TILE_SIZE),
        TILE_Z.to_double(),
      )
      hide_entity(overlay_entity)
    }
    _ => {
      set_sprite_entity(
        base_entity,
        map_image_handle.val.unwrap(),
        center,
        vec2(TILE_SIZE, TILE_SIZE),
        TILE_Z.to_double(),
        rect=Some(atlas_rect(32.0, 32.0, 7, tile_sheet_index(tile))),
      )
      hide_entity(overlay_entity)
    }
  }
}

///|
fn sync_terrain_tiles() -> Unit {
  for y in 0..<STAGE_ROWS {
    for x in 0..<STAGE_COLS {
      let index = terrain_index(x, y)
      sync_terrain_tile(index, x, y)
    }
  }
}

///|
fn sync_player_tank() -> Unit {
  if !player_tank.active {
    hide_entity(player_entity)
    hide_entity(player_effect_entity)
    return
  }
  let frame = current_animation_frame(2)
  set_sprite_entity(
    player_entity,
    player_sheet_handle.val.unwrap(),
    player_tank.center,
    vec2(PLAYER_SIZE, PLAYER_SIZE),
    TANK_Z.to_double(),
    rect=Some(
      atlas_rect(
        TANK_ATLAS_CELL,
        TANK_ATLAS_CELL,
        8,
        player_sprite_index(player_tank.rank, player_tank.direction, frame),
      ),
    ),
  )
  if player_tank.born_seconds > 0.0 {
    let spawn_frame = current_animation_frame(4, fps=12.0)
    set_sprite_entity(
      player_effect_entity,
      spawn_sheet_handle.val.unwrap(),
      player_tank.center,
      vec2(PLAYER_SIZE, PLAYER_SIZE),
      EFFECT_Z.to_double(),
      rect=Some(atlas_rect(32.0, 32.0, 4, spawn_frame)),
    )
  } else if player_tank.shield_seconds > 0.0 {
    let shield_frame = current_animation_frame(2, fps=10.0)
    set_sprite_entity(
      player_effect_entity,
      shield_sheet_handle.val.unwrap(),
      player_tank.center,
      vec2(36.0, 36.0),
      EFFECT_Z.to_double(),
      rect=Some(atlas_rect(32.0, 32.0, 1, shield_frame)),
    )
  } else {
    hide_entity(player_effect_entity)
  }
}

///|
fn sync_enemy_tanks() -> Unit {
  for index in 0..<MAX_ACTIVE_ENEMIES {
    let enemy = enemy_tanks[index]
    if !enemy.active {
      hide_entity(enemy_entities[index])
      hide_entity(enemy_effect_entities[index])
      continue
    }
    let frame = current_animation_frame(2)
    let flashing = match enemy.carrier_drop {
      Some(_) => current_animation_frame(2, fps=6.0) == 0
      None => false
    }
    set_sprite_entity(
      enemy_entities[index],
      enemy_sheet_handle.val.unwrap(),
      enemy.center,
      vec2(PLAYER_SIZE, PLAYER_SIZE),
      TANK_Z.to_double(),
      rect=Some(
        atlas_rect(
          TANK_ATLAS_CELL,
          TANK_ATLAS_CELL,
          8,
          enemy_sprite_index(enemy.kind, enemy.direction, frame, flashing),
        ),
      ),
    )
    if enemy.born_seconds > 0.0 {
      let spawn_frame = current_animation_frame(4, fps=12.0)
      set_sprite_entity(
        enemy_effect_entities[index],
        spawn_sheet_handle.val.unwrap(),
        enemy.center,
        vec2(PLAYER_SIZE, PLAYER_SIZE),
        EFFECT_Z.to_double(),
        rect=Some(atlas_rect(32.0, 32.0, 4, spawn_frame)),
      )
    } else {
      hide_entity(enemy_effect_entities[index])
    }
  }
}

///|
fn sync_projectiles() -> Unit {
  for index in 0..<MAX_PROJECTILES {
    let projectile = projectiles[index]
    if !projectile.active {
      hide_entity(projectile_entities[index])
      continue
    }
    let size = if is_vertical(projectile.direction) {
      vec2(9.0, 12.0)
    } else {
      vec2(12.0, 9.0)
    }
    set_sprite_entity(
      projectile_entities[index],
      bullet_sheet_handle.val.unwrap(),
      projectile.center,
      size,
      PROJECTILE_Z.to_double(),
      rect=Some(
        atlas_rect(7.0, 8.0, 4, projectile_sprite_index(projectile.direction)),
      ),
    )
  }
}

///|
fn explosion_handle_for(index : Int) -> @asset.ImageHandle {
  let explosion = explosions[index]
  match explosion.kind {
    Bullet => {
      let progress = 1.0 -
        explosion.seconds_remaining / BULLET_EXPLOSION_SECONDS
      let frame = clamp_int((progress * 3.0).floor().to_int(), 0, 2)
      bullet_explosion_handles[frame]
    }
    Big => {
      let progress = 1.0 - explosion.seconds_remaining / BIG_EXPLOSION_SECONDS
      let frame = clamp_int((progress * 5.0).floor().to_int(), 0, 4)
      big_explosion_handles[frame]
    }
  }
}

///|
fn explosion_size(kind : ExplosionKind) -> @math.Vec2 {
  match kind {
    Bullet => vec2(24.0, 24.0)
    Big => vec2(48.0, 48.0)
  }
}

///|
fn sync_explosions() -> Unit {
  for index in 0..<MAX_EXPLOSIONS {
    let explosion = explosions[index]
    if !explosion.active {
      hide_entity(explosion_entities[index])
      continue
    }
    set_sprite_entity(
      explosion_entities[index],
      explosion_handle_for(index),
      explosion.center,
      explosion_size(explosion.kind),
      EFFECT_Z.to_double(),
    )
  }
}

///|
fn sync_powerup() -> Unit {
  if !active_powerup.active {
    hide_entity(powerup_entity)
    return
  }
  let visible = current_animation_frame(6, fps=12.0) < 4
  if !visible {
    hide_entity(powerup_entity)
    return
  }
  set_sprite_entity(
    powerup_entity,
    powerup_sheet_handle.val.unwrap(),
    active_powerup.center,
    vec2(30.0, 30.0),
    EFFECT_Z.to_double(),
    rect=Some(
      atlas_rect(
        POWERUP_WIDTH,
        POWERUP_HEIGHT,
        6,
        powerup_sprite_index(active_powerup.kind),
      ),
    ),
  )
}

///|
fn sync_queue_icons() -> Unit {
  let remaining = remaining_enemy_count()
  for index in 0..<ENEMIES_PER_STAGE {
    if index < remaining {
      set_sprite_entity(
        queue_icon_entities[index],
        enemy_sheet_handle.val.unwrap(),
        queue_icon_center(index),
        vec2(QUEUE_ICON_SIZE, QUEUE_ICON_SIZE),
        HUD_Z.to_double(),
        rect=Some(
          atlas_rect(
            TANK_ATLAS_CELL,
            TANK_ATLAS_CELL,
            8,
            enemy_sprite_index(Basic, Up, 0, false),
          ),
        ),
      )
    } else {
      hide_entity(queue_icon_entities[index])
    }
  }
}

///|
fn status_line() -> String {
  if campaign_state.phase == Paused {
    return "PAUSED"
  }
  if campaign_state.pending_respawn_seconds > 0.0 {
    return "RESPAWNING"
  }
  if active_powerup.active {
    return "BONUS \{powerup_label(active_powerup.kind)}"
  }
  if campaign_state.freeze_seconds > 0.0 {
    return "ENEMY FROZEN"
  }
  if campaign_state.shovel_seconds > 0.0 {
    return "BASE STEEL"
  }
  if player_tank.active {
    return "RANK \{rank_label(player_tank.rank)}"
  }
  ""
}

///|
fn overlay_copy() -> (String, String, Bool) {
  match campaign_state.phase {
    MainMenu => ("", "", false)
    StageIntro =>
      (
        "STAGE \{campaign_state.current_stage + 1}",
        stage_at(campaign_state.current_stage).name,
        true,
      )
    Playing => ("", "", false)
    Paused => ("PAUSED", "ESC / ENTER RESUME", true)
    StageClear => ("STAGE CLEAR", "ENTER TO ADVANCE", true)
    GameOver => ("", "ENTER TO RETURN", true)
    CampaignClear => ("YOU WIN", "ENTER TO RETURN", true)
  }
}

///|
fn sync_menu() -> Unit {
  let in_menu = campaign_state.phase == MainMenu
  set_entity_visible(title_image_entity, in_menu)
  set_entity_visible(menu_one_player_entity, in_menu)
  set_entity_visible(menu_exit_entity, in_menu)
  update_text_if_changed(
    menu_one_player_entity,
    last_menu_one_player_text,
    active_menu_line(OnePlayer),
  )
  update_text_if_changed(
    menu_exit_entity,
    last_menu_exit_text,
    active_menu_line(Exit),
  )
}

///|
fn sync_hud() -> Unit {
  let show_runtime = campaign_state.phase != MainMenu
  set_entity_visible(board_entity, show_runtime)
  set_entity_visible(hud_entity, show_runtime)
  set_entity_visible(hud_lives_icon_entity, show_runtime)
  set_entity_visible(hud_flag_entity, show_runtime)
  set_entity_visible(hud_lives_text_entity, show_runtime)
  set_entity_visible(hud_stage_text_entity, show_runtime)
  set_entity_visible(hud_status_text_entity, show_runtime)
  if !show_runtime {
    for entity in queue_icon_entities {
      hide_entity(entity)
    }
    return
  }

  update_text_if_changed(
    hud_lives_text_entity,
    last_lives_text,
    format_counter(campaign_state.lives),
  )
  update_text_if_changed(
    hud_stage_text_entity,
    last_stage_text,
    format_counter(campaign_state.current_stage + 1),
  )
  update_text_if_changed(
    hud_status_text_entity,
    last_status_text,
    status_line(),
  )
  sync_queue_icons()
}

///|
fn sync_overlay() -> Unit {
  let (text, subtext, visible) = overlay_copy()
  let show_game_over_image = campaign_state.phase == GameOver
  set_entity_visible(game_over_image_entity, show_game_over_image)
  set_entity_visible(overlay_text_entity, visible && text != "")
  set_entity_visible(overlay_subtext_entity, visible && subtext != "")
  update_text_if_changed(overlay_text_entity, last_overlay_text, text)
  update_text_if_changed(overlay_subtext_entity, last_overlay_subtext, subtext)
}

///|
fn sync_fps_counter() -> Unit {
  set_entity_visible(fps_text_entity, campaign_state.debug_fps_enabled)
  if !campaign_state.debug_fps_enabled {
    return
  }
  let fps = if @time.delta() > 0.0 {
    (1.0 / @time.delta()).floor().to_int()
  } else {
    0
  }
  update_text_if_changed(fps_text_entity, last_fps_text, "FPS \{fps}")
}

///|
fn handle_main_menu_input() -> Unit {
  if campaign_state.phase != MainMenu {
    return
  }
  if @inputs.is_just_pressed(KeyW) || @inputs.is_just_pressed(ArrowUp) {
    campaign_state.menu_option = previous_menu_option(
      campaign_state.menu_option,
    )
    play_sfx(sfx_switch_handle, volume=0.45)
  }
  if @inputs.is_just_pressed(KeyS) || @inputs.is_just_pressed(ArrowDown) {
    campaign_state.menu_option = next_menu_option(campaign_state.menu_option)
    play_sfx(sfx_switch_handle, volume=0.45)
  }
  if @inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space) {
    activate_menu_option(campaign_state.menu_option)
  }
}

///|
fn handle_phase_shortcuts() -> Unit {
  let debug_pressed = @host.is_key_pressed("F3")
  if debug_pressed && !debug_toggle_latch.val {
    campaign_state.debug_fps_enabled = !campaign_state.debug_fps_enabled
  }
  debug_toggle_latch.val = debug_pressed

  if !@inputs.is_just_pressed(Escape) {
    return
  }

  match campaign_state.phase {
    MainMenu => request_exit()
    Playing | Paused => toggle_pause()
    _ => return_to_menu()
  }
}

///|
fn handle_overlay_input() -> Unit {
  if !(@inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space)) {
    return
  }
  match campaign_state.phase {
    StageIntro => begin_playing_phase()
    StageClear => next_stage_or_campaign_clear()
    GameOver | CampaignClear => return_to_menu()
    Paused => toggle_pause()
    _ => ()
  }
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  handle_phase_shortcuts()
  handle_main_menu_input()
  handle_overlay_input()
}

///|
pub fn simulation_system(_world : @ecs.World) -> Unit {
  let delta = @time.delta()
  campaign_state.phase_seconds += delta
  match campaign_state.phase {
    MainMenu => ()
    StageIntro =>
      if campaign_state.phase_seconds >= STAGE_INTRO_SECONDS {
        begin_playing_phase()
      }
    Playing =>
      update_playing(
        delta,
        player_input_direction(),
        @inputs.is_just_pressed(Space),
      )
    Paused => ()
    StageClear =>
      if campaign_state.phase_seconds >= STAGE_CLEAR_SECONDS {
        next_stage_or_campaign_clear()
      }
    GameOver => ()
    CampaignClear => ()
  }
}

///|
pub fn render_sync_system(_world : @ecs.World) -> Unit {
  sync_menu()
  sync_hud()
  sync_overlay()
  sync_fps_counter()

  if campaign_state.phase != MainMenu {
    sync_terrain_tiles()
    sync_player_tank()
    sync_enemy_tanks()
    sync_projectiles()
    sync_explosions()
    sync_powerup()
  } else {
    for entity in terrain_entities {
      hide_entity(entity)
    }
    for entity in terrain_overlay_entities {
      hide_entity(entity)
    }
    hide_entity(player_entity)
    hide_entity(player_effect_entity)
    for entity in enemy_entities {
      hide_entity(entity)
    }
    for entity in enemy_effect_entities {
      hide_entity(entity)
    }
    for entity in projectile_entities {
      hide_entity(entity)
    }
    for entity in explosion_entities {
      hide_entity(entity)
    }
    hide_entity(powerup_entity)
  }
}

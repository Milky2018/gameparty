///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn install_audio_once() -> Unit {
  if shoot_sound.val is Some(_) {
    return
  }
  if is_capture_enabled() {
    return
  }
  shoot_sound.val = Some(make_tone_sound(540.0, 0.08, 0.72))
  hit_sound.val = Some(make_tone_sound(220.0, 0.10, 0.82))
  boom_sound.val = Some(make_tone_sound(120.0, 0.14, 0.90))
  win_sound.val = Some(make_tone_sound(880.0, 0.22, 0.68))
  lose_sound.val = Some(make_tone_sound(160.0, 0.20, 0.80))
}

///|
fn play_sound(sound_ref : Ref[@raylib.Sound?]) -> Unit {
  match sound_ref.val {
    Some(sound) => sound.play()
    None => ()
  }
}

///|
fn spawn_floor() -> Unit {
  ensure_entity_alive(floor_entity)
  set_rect_entity(
    floor_entity,
    @math.Vec2D(WORLD_WIDTH * 0.5, WORLD_HEIGHT * 0.5),
    @math.Vec2D(WORLD_WIDTH, WORLD_HEIGHT),
    color_rgb(32U, 63U, 31U),
    FLOOR_Z,
  )
}

///|
fn spawn_extraction() -> Unit {
  ensure_entity_alive(extraction_entity)
  set_rect_entity(
    extraction_entity,
    center_of_rect(extraction_zone),
    extraction_zone.size,
    if wave_state.extraction_open {
      color_rgb(80U, 220U, 120U)
    } else {
      color_rgba(45U, 80U, 55U, 0.65)
    },
    GOAL_Z,
  )
}

///|
fn spawn_hud_entities() -> Unit {
  ensure_entity_alive(title_entity)
  ensure_entity_alive(hud_entity)
  ensure_entity_alive(message_entity)
  ensure_entity_alive(debug_entity)
  set_text_entity(
    title_entity,
    "JACKAL",
    @math.Vec2D(24.0, 20.0),
    "rgb(248,248,248)",
    "34px monospace",
    HUD_Z,
  )
  set_text_entity(
    hud_entity,
    "",
    @math.Vec2D(24.0, 58.0),
    "rgb(224,232,240)",
    "22px monospace",
    HUD_Z,
  )
  set_text_entity(
    message_entity,
    "",
    @math.Vec2D(24.0, 92.0),
    "rgb(227,214,134)",
    "22px monospace",
    HUD_Z,
  )
  set_text_entity(
    debug_entity,
    "",
    @math.Vec2D(24.0, 124.0),
    "rgb(180,224,255)",
    "18px monospace",
    HUD_Z,
  )
}

///|
fn spawn_player_visual() -> Unit {
  ensure_entity_alive(player_state.entity)
  set_rect_entity(
    player_state.entity,
    player_state.pos,
    @math.Vec2D(34.0, 24.0),
    if player_state.invuln > 0.0 {
      color_rgb(110U, 160U, 250U)
    } else {
      color_rgb(60U, 120U, 240U)
    },
    PLAYER_Z,
    rotation=facing_angle(player_state.facing),
  )
}

///|
fn spawn_enemy_visual(
  entity : @entity.Entity,
  kind : EnemyKind,
  pos : @math.Vec2D,
  facing : Facing,
) -> Unit {
  ensure_entity_alive(entity)
  let color = match kind {
    Soldier => color_rgb(230U, 88U, 64U)
    Turret => color_rgb(186U, 144U, 55U)
  }
  set_rect_entity(
    entity,
    pos,
    if kind == Soldier {
      @math.Vec2D(30.0, 22.0)
    } else {
      @math.Vec2D(28.0, 28.0)
    },
    color,
    ENEMY_Z,
    rotation=facing_angle(facing),
  )
}

///|
fn spawn_bullet_visual(
  entity : @entity.Entity,
  owner : BulletOwner,
  pos : @math.Vec2D,
  vel : @math.Vec2D,
) -> Unit {
  ensure_entity_alive(entity)
  let size = @math.Vec2D(8.0, 8.0)
  let color = match owner {
    Player => color_rgb(250U, 228U, 96U)
    Enemy => color_rgb(250U, 130U, 90U)
  }
  let rotation = if vec_length(vel) <= 0.000001 {
    0.0
  } else {
    facing_angle(facing_from_vector(vel))
  }
  set_rect_entity(entity, pos, size, color, BULLET_Z, rotation~)
}

///|
fn spawn_obstacle_visual(
  entity : @entity.Entity,
  obstacle : ObstacleState,
) -> Unit {
  ensure_entity_alive(entity)
  let color = match obstacle.kind {
    Rock => color_rgb(92U, 104U, 119U)
    Crate => color_rgb(156U, 112U, 66U)
  }
  set_rect_entity(
    entity,
    center_of_rect(obstacle.rect),
    obstacle.rect.size,
    color,
    OBJECT_Z,
  )
}

///|
fn spawn_decorative_border() -> Unit {
  clear_decorative_entities()
  let north = @entity.Entity::new()
  set_rect_entity(
    north,
    @math.Vec2D(WORLD_WIDTH * 0.5, 8.0),
    @math.Vec2D(WORLD_WIDTH, 16.0),
    color_rgb(24U, 28U, 36U),
    FLOOR_Z,
  )
  decorative_entities.push(north)
  let south = @entity.Entity::new()
  set_rect_entity(
    south,
    @math.Vec2D(WORLD_WIDTH * 0.5, WORLD_HEIGHT - 8.0),
    @math.Vec2D(WORLD_WIDTH, 16.0),
    color_rgb(24U, 28U, 36U),
    FLOOR_Z,
  )
  decorative_entities.push(south)
}

///|
fn spawn_level_geometry() -> Unit {
  clear_obstacle_entities()
  let specs = base_obstacle_specs()
  for index in 0..<specs.length() {
    let (kind, rect) = specs[index]
    let obstacle : ObstacleState = {
      entity: @entity.Entity::new(),
      rect,
      kind,
      hp: if kind == Crate {
        1
      } else {
        9999
      },
      alive: true,
    }
    spawn_obstacle_visual(obstacle.entity, obstacle)
    obstacle_states.push(obstacle)
  }
}

///|
fn spawn_first_wave() -> Unit {
  wave_state.index = 0
  begin_next_wave()
}

///|
fn spawn_enemy_batch() -> Unit {
  if wave_state.spawn_left <= 0 || game_state.phase != Playing {
    return
  }
  let count_before = enemy_states.length()
  if count_before > 12 {
    return
  }
  let spawn_index = (wave_state.index + wave_state.spawn_left) %
    all_enemy_spawn_points.length()
  let spawn_pos = all_enemy_spawn_points[spawn_index]
  let kind = if wave_state.index >= 2 && wave_state.spawn_left % 3 == 0 {
    Turret
  } else {
    Soldier
  }
  spawn_enemy(kind, spawn_pos)
  wave_state.spawn_left -= 1
}

///|
fn reset_entities() -> Unit {
  clear_enemy_entities()
  clear_bullet_entities()
  clear_obstacle_entities()
  spawn_floor()
  spawn_decorative_border()
  spawn_level_geometry()
  spawn_player_visual()
  spawn_extraction()
  spawn_hud_entities()
  spawn_first_wave()
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  game_state.capture_enabled = is_capture_enabled()
  game_state.profile_enabled = is_profile_enabled()
  game_state.capture_started_at = @time.elapsed()
  game_state.capture_taken = false
  game_state.profile_started_at = game_state.capture_started_at
  game_state.profile_last_report_at = game_state.profile_started_at
  game_state.profile_frame_count = 0
  install_audio_once()
  reset_game_state()
  reset_entities()
}

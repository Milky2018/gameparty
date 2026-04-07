///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn set_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn transform_2d(center : @math.Vec2D, z : Double) -> @transform.Transform {
  {
    translation: @math.Vec3::new(center[X], center[Y], z),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  }
}

///|
fn set_sprite_entity(
  entity : @entity.Entity,
  color : @render.Color,
  size : @math.Vec2D,
  center : @math.Vec2D,
  z : Double,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_color(color, size)
  sprite.anchor = @sprite.Anchor(@math.Vec2D(0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_2d(center, z))
  set_visibility(entity, true)
}

///|
fn set_text_entity(
  entity : @entity.Entity,
  content : String,
  center : @math.Vec2D,
  font_size : String,
  color : @render.Color,
) -> Unit {
  ensure_entity_alive(entity)
  @ui.texts().set(entity, @ui.Text::new(content))
  @ui.text_fonts().set(entity, @ui.TextFont::from_css(font_size))
  @ui.text_colors().set(entity, @ui.TextColor::new(color))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2D(-0.5, 0.5)))
  @transform.transforms().set(entity, transform_2d(center, 1000.0))
  set_visibility(entity, true)
}

///|
fn setup_camera() -> Unit {
  ensure_entity_alive(camera_entity)
  @camera.cameras().set(camera_entity, @camera.Camera::new(is_active=true, order=0))
  @camera.camera2ds().set(camera_entity, @camera.Camera2d::new())
  @camera.orthographic_projections().set(
    camera_entity,
    @camera.OrthographicProjection::new(),
  )
}

///|
fn clear_static_entities() -> Unit {
  for entity in static_entities {
    entity.destroy()
  }
  static_entities.clear()
}

///|
fn clear_enemies() -> Unit {
  for entity, _ in enemy_entities {
    entity.destroy()
  }
  enemy_entities.clear()
  enemy_entities_order.clear()
}

///|
fn spawn_background(level : LevelSpec) -> Unit {
  let sky = @entity.Entity::new()
  set_sprite_entity(
    sky,
    background_color,
    vec2(level.world_width + 600.0, WORLD_HEIGHT + 240.0),
    vec2(level.world_width * 0.5, WORLD_HEIGHT * 0.42),
    -200.0,
  )
  static_entities.push(sky)

  let near_hill = @entity.Entity::new()
  set_sprite_entity(
    near_hill,
    near_hill_color,
    vec2(level.world_width * 0.34, 170.0),
    vec2(level.world_width * 0.25, WORLD_HEIGHT - 85.0),
    -180.0,
  )
  static_entities.push(near_hill)

  let far_hill = @entity.Entity::new()
  set_sprite_entity(
    far_hill,
    far_hill_color,
    vec2(level.world_width * 0.22, 120.0),
    vec2(level.world_width * 0.68, WORLD_HEIGHT - 125.0),
    -190.0,
  )
  static_entities.push(far_hill)
}

///|
fn spawn_level_entities(level : LevelSpec) -> Unit {
  clear_static_entities()
  clear_enemies()
  spawn_background(level)
  for block in level.blocks {
    let entity = @entity.Entity::new()
    let color = match block.kind {
      Ground => ground_color
      Brick => brick_color
      Pipe => pipe_color
    }
    set_sprite_entity(entity, color, block.size, block.center, 0.0)
    static_entities.push(entity)
  }
  let goal_pole = @entity.Entity::new()
  set_sprite_entity(
    goal_pole,
    rgb(233U, 235U, 240U),
    vec2(14.0, level.goal_size[Y]),
    level.goal_center,
    1.0,
  )
  static_entities.push(goal_pole)
  let goal_flag = @entity.Entity::new()
  set_sprite_entity(
    goal_flag,
    flag_color,
    vec2(64.0, 36.0),
    vec2(level.goal_center[X] + 38.0, level.goal_center[Y] - 40.0),
    2.0,
  )
  static_entities.push(goal_flag)
  for spawn in level.enemy_spawns {
    spawn_enemy(spawn)
  }
}

///|
fn spawn_player(level : LevelSpec) -> Unit {
  player_state.val = {
    center: level.player_spawn,
    velocity: @math.Vec2D::zero(),
    facing_right: true,
    on_ground: false,
    coyote_timer: 0.0,
    jump_buffer: 0.0,
    hurt_timer: 0.0,
    alive: true,
  }
  ensure_entity_alive(player_entity)
  set_sprite_entity(
    player_entity,
    player_sprite_color,
    vec2(PLAYER_WIDTH, PLAYER_HEIGHT),
    level.player_spawn,
    5.0,
  )
}

///|
fn spawn_enemy(spawn : EnemySpawn) -> Unit {
  let entity = @entity.Entity::new()
  enemy_entities.set(
    entity,
    {
      center: spawn.center,
      velocity: vec2(if spawn.facing_right { ENEMY_MOVE_SPEED } else { -ENEMY_MOVE_SPEED }, 0.0),
      facing_right: spawn.facing_right,
      on_ground: false,
      alive: true,
      patrol_left: spawn.patrol_left,
      patrol_right: spawn.patrol_right,
    },
  )
  enemy_entities_order.push(entity)
  set_sprite_entity(entity, enemy_sprite_color, vec2(ENEMY_WIDTH, ENEMY_HEIGHT), spawn.center, 4.0)
}

///|
fn set_message_visible(visible : Bool) -> Unit {
  set_visibility(hud_overlay_entity, visible)
  set_visibility(hud_message_entity, visible)
}

///|
fn setup_hud() -> Unit {
  set_sprite_entity(
    hud_overlay_entity,
    hud_color_dark,
    vec2(VIEWPORT_WIDTH, 120.0),
    vec2(VIEWPORT_WIDTH * 0.5, VIEWPORT_HEIGHT - 60.0),
    900.0,
  )
  set_text_entity(
    hud_title_entity,
    "SUPER MARIO",
    vec2(28.0, 24.0),
    "34px monospace",
    hud_color_white,
  )
  set_text_entity(
    hud_sub_entity,
    "",
    vec2(28.0, 68.0),
    "22px monospace",
    hud_color_soft,
  )
  set_text_entity(
    hud_hint_entity,
    "",
    vec2(28.0, VIEWPORT_HEIGHT - 36.0),
    "20px monospace",
    hud_color_soft,
  )
  set_text_entity(
    hud_message_entity,
    "",
    vec2(VIEWPORT_WIDTH * 0.5 - 220.0, VIEWPORT_HEIGHT * 0.5 - 30.0),
    "48px monospace",
    hud_color_gold,
  )
  set_visibility(hud_overlay_entity, false)
  set_visibility(hud_message_entity, false)
}

///|
fn setup_audio() -> Unit {
  audio_bank.val = Some(create_audio_bank())
}

///|
fn set_current_level(level_index : Int) -> Unit {
  let level = level_specs[level_index]
  current_level.val = Some(level)
  spawn_level_entities(level)
  spawn_player(level)
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  level_specs.clear()
  for level in build_level_specs() {
    level_specs.push(level)
  }
  setup_camera()
  setup_hud()
  setup_audio()
  capture_enabled.val = env_flag_enabled(DEBUG_CAPTURE_ENV)
  capture_started_at.val = @time.elapsed()
  capture_taken.val = false
  current_level_index.val = 0
  game_phase.val = Playing
  debug_overlay.val = false
  set_current_level(current_level_index.val)
}

///|
const ANGRYRABBITS_FONT_FAMILY : String = "ThaleahFat"

///|
const ANGRYRABBITS_FONT_PATH : String = "angryrabbits/assets/ThaleahFat.ttf"

///|
let angryrabbits_font_registered : Ref[Bool] = { val: false }

///|
fn register_angryrabbits_font_once() -> Unit {
  if angryrabbits_font_registered.val {
    return
  }
  ignore(
    @asset.load_font(ANGRYRABBITS_FONT_PATH, family=ANGRYRABBITS_FONT_FAMILY),
  )
  angryrabbits_font_registered.val = true
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn ensure_entity_list(entities : Array[@entity.Entity], count : Int) -> Unit {
  while entities.length() < count {
    entities.push(@entity.Entity::new())
  }
  for entity in entities {
    ensure_entity_alive(entity)
  }
}

///|
fn center_to_rect_position(
  center : @math.Vec2D,
  size : @math.Vec2D,
) -> @math.Vec2D {
  @math.Vec2D(center[X] - size[X] / 2.0, center[Y] - size[Y] / 2.0)
}

///|
fn center_to_circle_position(
  center : @math.Vec2D,
  radius : Double,
) -> @math.Vec2D {
  @math.Vec2D(center[X] - radius, center[Y] - radius)
}

///|
fn sprite_from_atlas(
  source_offset : @math.Vec2D,
  source_size : @math.Vec2D,
  world_size : @math.Vec2D,
  zindex : Int,
) -> @sprite.Sprite {
  let scale_x = if source_size[X] <= 0.0 {
    1.0
  } else {
    world_size[X] / source_size[X]
  }
  let scale_y = if source_size[Y] <= 0.0 {
    1.0
  } else {
    world_size[Y] / source_size[Y]
  }
  let animation = @sprite.Animation::single_frame(
    ANGRYRABBITS_SPRITES_PATH,
    source_size,
    transform=@math.Transform::from_scale(scale_x, scale_y),
    offset=source_offset,
  )
  @sprite.Sprite::from_animation(animation, zindex)
}

///|
fn physics_filter() -> @physics2d.CollisionFilter {
  @physics2d.CollisionFilter::all(@physics2d.CollisionGroup::new())
}

///|
fn rabbit_shape() -> @physics2d.CollisionShape {
  Ball(radius=RABBIT_RADIUS, offset=@math.Vec2D(RABBIT_RADIUS, RABBIT_RADIUS))
}

///|
fn rabbit_ready_body() -> @physics2d.RigidBody {
  {
    ..@physics2d.RigidBody::dynamic(),
    gravity_scale: 0.0,
    linear_damping: 1.0,
    angular_damping: 1.0,
    ccd_enabled: true,
    lock_rotation: true,
  }
}

///|
fn rabbit_flying_body() -> @physics2d.RigidBody {
  {
    ..@physics2d.RigidBody::dynamic(),
    gravity_scale: 1.0,
    linear_damping: RABBIT_LINEAR_DAMPING,
    angular_damping: 1.0,
    ccd_enabled: true,
    lock_rotation: true,
  }
}

///|
fn block_body() -> @physics2d.RigidBody {
  {
    ..@physics2d.RigidBody::dynamic(),
    gravity_scale: 1.0,
    linear_damping: BLOCK_LINEAR_DAMPING,
    angular_damping: 1.0,
    ccd_enabled: false,
    lock_rotation: true,
  }
}

///|
fn target_body() -> @physics2d.RigidBody {
  {
    ..@physics2d.RigidBody::dynamic(),
    gravity_scale: 1.0,
    linear_damping: TARGET_LINEAR_DAMPING,
    angular_damping: 1.0,
    ccd_enabled: false,
    lock_rotation: true,
  }
}

///|
fn clear_physics_entity(entity : @entity.Entity) -> Unit {
  @physics2d.colliders().remove(entity)
  @physics2d.shapes().remove(entity)
  @physics2d.rigid_bodies().remove(entity)
  @physics2d.velocities().remove(entity)
  @physics2d.resolved_velocities().remove(entity)
}

///|
fn clear_level_physics_entities() -> Unit {
  clear_physics_entity(ground_entity)
  clear_physics_entity(rabbit_entity)
  for entity in block_entities {
    clear_physics_entity(entity)
  }
  for entity in target_entities {
    clear_physics_entity(entity)
  }
}

///|
fn set_rabbit_ready_state(center : @math.Vec2D) -> Unit {
  let top_left = center_to_circle_position(center, RABBIT_RADIUS)
  rabbit_center.val = center
  rabbit_velocity.val = @math.Vec2D::zero()
  rabbit_visible.val = true
  @transform.positions().set(rabbit_entity, top_left)
  @physics2d.shapes().set(rabbit_entity, rabbit_shape())
  @physics2d.colliders().set(
    rabbit_entity,
    @physics2d.Collider::with_material(
      physics_filter(),
      friction=0.65,
      restitution=RABBIT_RESTITUTION,
      active=false,
    ),
  )
  @physics2d.rigid_bodies().set(rabbit_entity, rabbit_ready_body())
  @physics2d.set_rigid_body_translation(rabbit_entity, top_left)
  @physics2d.set_rigid_body_linear_velocity(rabbit_entity, @math.Vec2D::zero())
}

///|
fn launch_rabbit(center : @math.Vec2D, velocity : @math.Vec2D) -> Unit {
  let top_left = center_to_circle_position(center, RABBIT_RADIUS)
  rabbit_center.val = center
  rabbit_velocity.val = velocity
  rabbit_visible.val = true
  @transform.positions().set(rabbit_entity, top_left)
  @physics2d.shapes().set(rabbit_entity, rabbit_shape())
  @physics2d.colliders().set(
    rabbit_entity,
    @physics2d.Collider::with_material(
      physics_filter(),
      friction=0.65,
      restitution=RABBIT_RESTITUTION,
      active=true,
    ),
  )
  @physics2d.rigid_bodies().set(rabbit_entity, rabbit_flying_body())
  @physics2d.set_rigid_body_translation(rabbit_entity, top_left)
  @physics2d.set_rigid_body_linear_velocity(rabbit_entity, velocity)
}

///|
fn hide_rabbit_physics() -> Unit {
  rabbit_velocity.val = @math.Vec2D::zero()
  rabbit_visible.val = false
  @physics2d.colliders().set(
    rabbit_entity,
    @physics2d.Collider::with_material(
      physics_filter(),
      friction=0.65,
      restitution=RABBIT_RESTITUTION,
      active=false,
    ),
  )
  @physics2d.rigid_bodies().set(rabbit_entity, rabbit_ready_body())
  @physics2d.set_rigid_body_linear_velocity(rabbit_entity, @math.Vec2D::zero())
}

///|
fn configure_level_physics(level : LevelDef) -> Unit {
  @physics2d.configure_physics(
    gravity=@math.Vec2D(0.0, GRAVITY),
    pixels_per_meter=PHYSICS_PIXELS_PER_METER,
    max_ccd_substeps=PHYSICS_MAX_CCD_SUBSTEPS,
  )
  clear_level_physics_entities()

  @transform.positions().set(ground_entity, level.ground_rect.position)
  @physics2d.shapes().set(
    ground_entity,
    Rect(size=level.ground_rect.size, offset=@math.Vec2D::zero()),
  )
  @physics2d.colliders().set(
    ground_entity,
    @physics2d.Collider::with_material(
      physics_filter(),
      friction=GROUND_FRICTION,
      restitution=0.04,
    ),
  )
  @physics2d.rigid_bodies().set(ground_entity, @physics2d.RigidBody::fixed())
  @physics2d.set_rigid_body_translation(
    ground_entity,
    level.ground_rect.position,
  )

  for index, block in level.blocks {
    let entity = block_entities[index]
    let top_left = center_to_rect_position(block.center, block.size)
    @transform.positions().set(entity, top_left)
    @physics2d.shapes().set(
      entity,
      Rect(size=block.size, offset=@math.Vec2D::zero()),
    )
    @physics2d.colliders().set(
      entity,
      @physics2d.Collider::with_material(
        physics_filter(),
        friction=0.78,
        restitution=BLOCK_RESTITUTION,
      ),
    )
    @physics2d.rigid_bodies().set(entity, block_body())
    @physics2d.set_rigid_body_translation(entity, top_left)
    @physics2d.set_rigid_body_linear_velocity(entity, @math.Vec2D::zero())
  }

  for index, target in level.targets {
    let entity = target_entities[index]
    let top_left = center_to_circle_position(target.center, target.radius)
    @transform.positions().set(entity, top_left)
    @physics2d.shapes().set(
      entity,
      Ball(
        radius=target.radius,
        offset=@math.Vec2D(target.radius, target.radius),
      ),
    )
    @physics2d.colliders().set(
      entity,
      @physics2d.Collider::with_material(
        physics_filter(),
        friction=0.52,
        restitution=0.18,
      ),
    )
    @physics2d.rigid_bodies().set(entity, target_body())
    @physics2d.set_rigid_body_translation(entity, top_left)
    @physics2d.set_rigid_body_linear_velocity(entity, @math.Vec2D::zero())
  }

  set_rabbit_ready_state(level.rabbit_spawn)
}

///|
fn sync_rabbit_from_physics() -> Unit {
  guard @physics2d.rigid_body_translation(rabbit_entity) is Some(top_left) else {
    return
  }
  rabbit_center.val = top_left + @math.Vec2D(RABBIT_RADIUS, RABBIT_RADIUS)
  rabbit_velocity.val = @physics2d.rigid_body_linear_velocity(rabbit_entity).unwrap_or(
    @math.Vec2D::zero(),
  )
}

///|
fn sync_blocks_from_physics() -> Unit {
  for index in 0..<blocks.length() {
    let block = blocks[index]
    if !block.alive {
      continue
    }
    guard @physics2d.rigid_body_translation(block.entity) is Some(top_left) else {
      continue
    }
    blocks[index] = {
      ..block,
      center: top_left + block.size.scalar_mul(0.5),
      velocity: @physics2d.rigid_body_linear_velocity(block.entity).unwrap_or(
        @math.Vec2D::zero(),
      ),
    }
  }
}

///|
fn sync_targets_from_physics() -> Unit {
  for index in 0..<targets.length() {
    let target = targets[index]
    if !target.alive {
      continue
    }
    guard @physics2d.rigid_body_translation(target.entity) is Some(top_left) else {
      continue
    }
    targets[index] = {
      ..target,
      center: top_left + @math.Vec2D(target.radius, target.radius),
    }
  }
}

///|
fn sync_physics_snapshots() -> Unit {
  sync_rabbit_from_physics()
  sync_blocks_from_physics()
  sync_targets_from_physics()
}

///|
fn destroy_target_body(entity : @entity.Entity) -> Unit {
  clear_physics_entity(entity)
}

///|
fn register_scene_entities() -> Unit {
  for
    entity in [
      background_entity, ground_entity, hill_entity, slingshot_left_entity, slingshot_right_entity,
      slingshot_base_entity, rabbit_entity, rabbit_eye_entity, title_entity, hint_entity,
      status_entity, score_entity,
    ] {
    ensure_entity_alive(entity)
  }
  ensure_entity_list(aim_dot_entities, AIM_DOT_COUNT)
}

///|
fn register_level_entities(level : LevelDef) -> Unit {
  ensure_entity_list(block_entities, level.blocks.length())
  ensure_entity_list(target_entities, level.targets.length())
}

///|
fn hide_unused_level_entities(level : LevelDef) -> Unit {
  for index in level.blocks.length()..<block_entities.length() {
    clear_physics_entity(block_entities[index])
    if @sprite.sprites().get(block_entities[index]) is Some(sprite) {
      sprite.visible = false
    }
  }
  for index in level.targets.length()..<target_entities.length() {
    clear_physics_entity(target_entities[index])
    if @sprite.sprites().get(target_entities[index]) is Some(sprite) {
      sprite.visible = false
    }
  }
}

///|
fn instantiate_level(level : LevelDef) -> Unit {
  blocks.clear()
  targets.clear()
  for index, block in level.blocks {
    blocks.push({
      entity: block_entities[index],
      center: block.center,
      size: block.size,
      velocity: @math.Vec2D::zero(),
      alive: true,
    })
  }
  for index, target in level.targets {
    targets.push({
      entity: target_entities[index],
      center: target.center,
      radius: target.radius,
      alive: true,
    })
  }
  hide_unused_level_entities(level)
}

///|
fn hide_aim_dots() -> Unit {
  for entity in aim_dot_entities {
    if @sprite.sprites().get(entity) is Some(sprite) {
      sprite.visible = false
    }
  }
}

///|
fn launch_velocity_from_rabbit(center : @math.Vec2D) -> @math.Vec2D {
  (slingshot_anchor() - center).scalar_mul(LAUNCH_SPEED_FACTOR)
}

///|
fn refresh_aim_dots() -> Unit {
  if phase.val != Dragging {
    hide_aim_dots()
    return
  }
  let velocity = launch_velocity_from_rabbit(rabbit_center.val)
  for index, entity in aim_dot_entities {
    let time = (index.to_double() + 1.0) * AIM_DOT_TIME_STEP
    let offset = velocity.scalar_mul(time) +
      @math.Vec2D(0.0, GRAVITY * 0.5 * time * time)
    @transform.positions().set(
      entity,
      center_to_circle_position(rabbit_center.val + offset, AIM_DOT_RADIUS),
    )
    @sprite.sprites().set(
      entity,
      @sprite.Sprite::from_color_circle(
        @sprite.ColorCircle::new(
          AIM_DOT_RADIUS,
          "rgba(255,255,255,0.85)",
          stroke_color="rgba(0,0,0,0.0)",
        ),
        120,
      ),
    )
  }
}

///|
fn set_text_entity(
  entity : @entity.Entity,
  text : String,
  position : @math.Vec2D,
  font : String,
  color : String,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  @sprite.sprites().set(
    entity,
    @sprite.Sprite::from_text(
      @sprite.Text::new(text, color~, font~, baseline=Top, align=Left),
      zindex,
    ),
  )
  @transform.positions().set(entity, position)
}

///|
fn set_entity_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  if @sprite.sprites().get(entity) is Some(sprite) {
    sprite.visible = visible
  }
}

///|
fn wrap_text_for_ui(
  text : String,
  max_chars_per_line : Int,
  max_lines : Int,
) -> String {
  if text == "" || max_chars_per_line <= 0 || max_lines <= 0 {
    return ""
  }
  let lines : Array[String] = []
  let mut start = 0
  while start < text.length() && lines.length() < max_lines {
    let remaining = text.length() - start
    let line_length = if remaining < max_chars_per_line {
      remaining
    } else {
      max_chars_per_line
    }
    lines.push(text.unsafe_substring(start~, end=start + line_length))
    start += line_length
  }
  if start < text.length() && !lines.is_empty() {
    let last_index = lines.length() - 1
    let last_line = lines[last_index]
    if last_line.length() > 3 {
      lines[last_index] = last_line.unsafe_substring(
          start=0,
          end=last_line.length() - 3,
        ) +
        "..."
    } else {
      lines[last_index] = "..."
    }
  }
  let mut wrapped = ""
  for index, line in lines {
    if index > 0 {
      wrapped = wrapped + "\n"
    }
    wrapped = wrapped + line
  }
  wrapped
}

///|
fn hide_all_level_visuals() -> Unit {
  for
    entity in [
      ground_entity, hill_entity, slingshot_left_entity, slingshot_right_entity,
      slingshot_base_entity, rabbit_entity, rabbit_eye_entity,
    ] {
    set_entity_visibility(entity, false)
  }
  for entity in block_entities {
    set_entity_visibility(entity, false)
  }
  for entity in target_entities {
    set_entity_visibility(entity, false)
  }
  hide_aim_dots()
}

///|
fn sync_error_visuals(message : String) -> Unit {
  @sprite.sprites().set(
    background_entity,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(
        @math.Vec2D(VIEWPORT_WIDTH, VIEWPORT_HEIGHT),
        "rgb(29, 20, 24)",
      ),
      0,
    ),
  )
  @transform.positions().set(background_entity, @math.Vec2D::zero())
  set_entity_visibility(background_entity, true)
  hide_all_level_visuals()

  set_text_entity(
    title_entity,
    "ANGRY RABBITS",
    @math.Vec2D(20.0, 20.0),
    "32px \{ANGRYRABBITS_FONT_FAMILY}",
    "rgb(255, 239, 222)",
    220,
  )
  set_text_entity(
    score_entity,
    "LEVEL LOAD ERROR",
    @math.Vec2D(20.0, 60.0),
    "20px \{ANGRYRABBITS_FONT_FAMILY}",
    "rgb(255, 132, 112)",
    220,
  )
  set_text_entity(
    status_entity,
    wrap_text_for_ui(message, 56, 8),
    @math.Vec2D(20.0, 98.0),
    "16px \{ANGRYRABBITS_FONT_FAMILY}",
    "rgb(246, 230, 220)",
    220,
  )
  set_text_entity(
    hint_entity,
    "Press Enter or R to retry   ESC back",
    @math.Vec2D(20.0, VIEWPORT_HEIGHT - 28.0),
    "16px \{ANGRYRABBITS_FONT_FAMILY}",
    "rgb(205, 189, 176)",
    220,
  )
}

///|
fn sync_static_visuals() -> Unit {
  guard current_level.val is Some(level) else { return }
  let anchor = level.slingshot_anchor
  let background = level.background_rect
  let ground = level.ground_rect
  let hill = level.hill_circle
  @sprite.sprites().set(
    background_entity,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(background.size, background.color),
      background.zindex,
    ),
  )
  @transform.positions().set(background_entity, background.position)

  @sprite.sprites().set(
    hill_entity,
    @sprite.Sprite::from_color_circle(
      @sprite.ColorCircle::new(hill.radius, hill.color),
      hill.zindex,
    ),
  )
  @transform.positions().set(
    hill_entity,
    center_to_circle_position(hill.center, hill.radius),
  )

  @sprite.sprites().set(
    ground_entity,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(ground.size, ground.color),
      ground.zindex,
    ),
  )
  @transform.positions().set(ground_entity, ground.position)

  @sprite.sprites().set(
    slingshot_left_entity,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(16.0, 96.0), "rgb(122, 76, 39)"),
      30,
    ),
  )
  @transform.positions().set(
    slingshot_left_entity,
    anchor + @math.Vec2D(-26.0, -8.0),
  )

  @sprite.sprites().set(
    slingshot_right_entity,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(16.0, 112.0), "rgb(101, 61, 28)"),
      31,
    ),
  )
  @transform.positions().set(
    slingshot_right_entity,
    anchor + @math.Vec2D(6.0, -24.0),
  )

  @sprite.sprites().set(
    slingshot_base_entity,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(54.0, 18.0), "rgb(133, 86, 45)"),
      29,
    ),
  )
  @transform.positions().set(
    slingshot_base_entity,
    anchor + @math.Vec2D(-38.0, 70.0),
  )
}

///|
fn sync_dynamic_visuals() -> Unit {
  let rabbit_size = @math.Vec2D(RABBIT_RADIUS * 2.0, RABBIT_RADIUS * 2.0)
  @sprite.sprites().set(
    rabbit_entity,
    sprite_from_atlas(
      @math.Vec2D(RABBIT_SPRITE_SRC_X, RABBIT_SPRITE_SRC_Y),
      @math.Vec2D(RABBIT_SPRITE_SRC_WIDTH, RABBIT_SPRITE_SRC_HEIGHT),
      rabbit_size,
      70,
    ),
  )
  @transform.positions().set(
    rabbit_entity,
    center_to_rect_position(rabbit_center.val, rabbit_size),
  )
  if @sprite.sprites().get(rabbit_entity) is Some(sprite) {
    sprite.visible = rabbit_visible.val
  }

  set_entity_visibility(rabbit_eye_entity, false)

  for block in blocks {
    @sprite.sprites().set(
      block.entity,
      sprite_from_atlas(
        @math.Vec2D(BLOCK_SPRITE_SRC_X, BLOCK_SPRITE_SRC_Y),
        @math.Vec2D(BLOCK_SPRITE_SRC_WIDTH, BLOCK_SPRITE_SRC_HEIGHT),
        block.size,
        60,
      ),
    )
    @transform.positions().set(
      block.entity,
      center_to_rect_position(block.center, block.size),
    )
    if @sprite.sprites().get(block.entity) is Some(sprite) {
      sprite.visible = block.alive
    }
  }

  for target in targets {
    let target_size = @math.Vec2D(target.radius * 2.0, target.radius * 2.0)
    @sprite.sprites().set(
      target.entity,
      sprite_from_atlas(
        @math.Vec2D(TARGET_SPRITE_SRC_X, TARGET_SPRITE_SRC_Y),
        @math.Vec2D(TARGET_SPRITE_SRC_WIDTH, TARGET_SPRITE_SRC_HEIGHT),
        target_size,
        65,
      ),
    )
    @transform.positions().set(
      target.entity,
      center_to_rect_position(target.center, target_size),
    )
    if @sprite.sprites().get(target.entity) is Some(sprite) {
      sprite.visible = target.alive
    }
  }

  refresh_aim_dots()
}

///|
fn status_text() -> String {
  match phase.val {
    Error =>
      "Level load failed. Fix the LDtk file and press Enter or R to retry."
    Ready => "Drag the rabbit backward with the mouse, then release."
    Dragging => "Release to launch. Rabbit speed scales with stretch."
    Flying => "Break every green target before you run out of rabbits."
    Won => "Stage cleared. Press Enter or R to play again."
    Lost => "Out of rabbits. Press Enter or R to retry."
  }
}

///|
fn score_text() -> String {
  let remaining_targets = targets.filter(fn(target) { target.alive }).length()
  "Rabbits: \{shots_remaining.val}   Targets: \{remaining_targets}"
}

///|
fn sync_ui() -> Unit {
  if phase.val == Error {
    sync_error_visuals(load_error_message.val)
    return
  }
  set_text_entity(
    title_entity,
    "ANGRY RABBITS",
    @math.Vec2D(20.0, 16.0),
    "32px \{ANGRYRABBITS_FONT_FAMILY}",
    "rgb(84, 48, 22)",
    220,
  )
  set_text_entity(
    hint_entity,
    "Mouse drag/release launch   R/Enter restart   ESC back",
    @math.Vec2D(20.0, VIEWPORT_HEIGHT - 28.0),
    "16px \{ANGRYRABBITS_FONT_FAMILY}",
    "rgb(77, 74, 66)",
    220,
  )
  set_text_entity(
    score_entity,
    score_text(),
    @math.Vec2D(20.0, 54.0),
    "20px \{ANGRYRABBITS_FONT_FAMILY}",
    "rgb(66, 52, 32)",
    220,
  )
  set_text_entity(
    status_entity,
    status_text(),
    @math.Vec2D(20.0, 82.0),
    "18px \{ANGRYRABBITS_FONT_FAMILY}",
    if phase.val == Won {
      "rgb(32, 112, 48)"
    } else if phase.val == Lost {
      "rgb(161, 54, 44)"
    } else {
      "rgb(72, 60, 44)"
    },
    220,
  )
}

///|
fn reset_level() -> Unit {
  register_angryrabbits_font_once()
  match load_current_level() {
    Err(message) => {
      current_level.val = None
      load_error_message.val = message
      phase.val = Error
      shots_remaining.val = 0
      rabbit_center.val = @math.Vec2D::zero()
      rabbit_velocity.val = @math.Vec2D::zero()
      rabbit_visible.val = false
      rabbit_flight_time.val = 0.0
      rabbit_idle_time.val = 0.0
      blocks.clear()
      targets.clear()
      clear_level_physics_entities()
      register_scene_entities()
      sync_error_visuals(message)
    }
    Ok(level) => {
      current_level.val = Some(level)
      load_error_message.val = ""
      register_scene_entities()
      register_level_entities(level)
      sync_static_visuals()
      instantiate_level(level)
      configure_level_physics(level)
      shots_remaining.val = level.max_shots
      phase.val = Ready
      rabbit_flight_time.val = 0.0
      rabbit_idle_time.val = 0.0
      sync_physics_snapshots()
      sync_dynamic_visuals()
      sync_ui()
    }
  }
}

///|
fn setup_scene_if_needed() -> Unit {
  if !scene_initialized.val {
    register_scene_entities()
    scene_initialized.val = true
  }
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  setup_scene_if_needed()
  reset_level()
}

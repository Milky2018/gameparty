///|
const ANGRYRABBITS_FONT_FAMILY : String = "ThaleahFat"

///|
const ANGRYRABBITS_FONT_PATH : String = "assets/angryrabbits/ThaleahFat.ttf"

///|
let angryrabbits_font_registered : Ref[Bool] = { val: false }

///|
let angryrabbits_spritesheet_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let circle_mesh_handles : Map[Int, @mesh2d.Mesh2dHandle] = Map::new()

///|
let circle_material_handles : Map[String, @material2d.ColorMaterialHandle] = Map::new()

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
fn parse_color_component_int(part : StringView) -> Int? {
  let token = part.to_string().trim().to_string()
  if token == "" {
    return None
  }
  Some(@string.parse_int(token)) catch {
    _ => None
  }
}

///|
fn parse_color_alpha(part : StringView) -> Double? {
  let token = part.to_string().trim().to_string()
  if token == "" {
    return None
  }
  Some(@string.parse_double(token)) catch {
    _ => None
  }
}

///|
fn clamp_color_byte(value : Int) -> UInt {
  let clamped = if value < 0 { 0 } else if value > 255 { 255 } else { value }
  clamped.reinterpret_as_uint()
}

///|
fn clamp_color_alpha(value : Double) -> Double {
  clamp_double(value, 0.0, 1.0)
}

///|
fn normalize_css_color_string(color : String) -> String {
  let trimmed = color.trim().to_string()
  if trimmed.length() >= 2 &&
    trimmed.unsafe_get(0) == '\"' &&
    trimmed.unsafe_get(trimmed.length() - 1) == '\"' {
    return trimmed.unsafe_substring(start=1, end=trimmed.length() - 1)
  }
  if trimmed.length() >= 2 &&
    trimmed.unsafe_get(0) == '\'' &&
    trimmed.unsafe_get(trimmed.length() - 1) == '\'' {
    return trimmed.unsafe_substring(start=1, end=trimmed.length() - 1)
  }
  trimmed
}

///|
fn parse_css_rgb_components(color : String) -> (UInt, UInt, UInt, Double)? {
  let trimmed = normalize_css_color_string(color)
  let is_rgb = trimmed.has_prefix("rgb(") && trimmed.has_suffix(")")
  let is_rgba = trimmed.has_prefix("rgba(") && trimmed.has_suffix(")")
  if !is_rgb && !is_rgba {
    return None
  }
  let body = if is_rgba {
    trimmed.replace(old="rgba(", new="").replace(old=")", new="")
  } else {
    trimmed.replace(old="rgb(", new="").replace(old=")", new="")
  }
  let parts : Array[StringView] = []
  for part in body.split(",") {
    parts.push(part)
  }
  if (is_rgba && parts.length() != 4) || (is_rgb && parts.length() != 3) {
    return None
  }
  guard parse_color_component_int(parts[0]) is Some(r) else { return None }
  guard parse_color_component_int(parts[1]) is Some(g) else { return None }
  guard parse_color_component_int(parts[2]) is Some(b) else { return None }
  let alpha = if is_rgba {
    guard parse_color_alpha(parts[3]) is Some(a) else { return None }
    clamp_color_alpha(a)
  } else {
    1.0
  }
  Some((clamp_color_byte(r), clamp_color_byte(g), clamp_color_byte(b), alpha))
}

///|
fn sprite_color(color : String) -> @render.Color {
  let normalized = normalize_css_color_string(color)
  match parse_css_rgb_components(color) {
    Some((r, g, b, a)) => { r, g, b, a }
    None => @sprite.color_from_css(normalized)
  }
}

///|
fn angryrabbits_spritesheet() -> @asset.ImageHandle {
  match angryrabbits_spritesheet_handle.val {
    Some(handle) => handle
    None => {
      let handle = @asset.load_image(ANGRYRABBITS_SPRITES_PATH)
      angryrabbits_spritesheet_handle.val = Some(handle)
      handle
    }
  }
}

///|
fn entity_transform_2d(
  position : @math.Vec2D,
  zindex : Int,
  rotation? : Double = 0.0,
) -> @transform.Transform {
  let transform = @transform.Transform::from_xyz(
    position[X],
    position[Y],
    zindex.to_double(),
  )
  if rotation == 0.0 {
    transform
  } else {
    transform.with_rotation(
      @math.Quat::from_axis_angle(@math.Vec3::z_axis(), rotation),
    )
  }
}

///|
fn show_entity(entity : @entity.Entity) -> Unit {
  @visibility.visibilities().set(entity, Visible)
}

///|
fn circle_mesh_handle(radius : Double) -> @mesh2d.Mesh2dHandle {
  let key = @cmath.round(radius * 1000.0).to_int()
  circle_mesh_handles.get_or_init(key, fn() { @mesh2d.circle(radius) })
}

///|
fn circle_material_handle(color : String) -> @material2d.ColorMaterialHandle {
  circle_material_handles.get_or_init(color, fn() {
    @material2d.register_color_material(
      @material2d.ColorMaterial::from_color(sprite_color(color)),
    )
  })
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
fn rabbit_queue_center(index : Int) -> @math.Vec2D {
  guard current_level.val is Some(level) else { return @math.Vec2D::zero() }
  level.rabbit_spawn +
  @math.Vec2D(
    RABBIT_QUEUE_OFFSET_X + index.to_double() * RABBIT_QUEUE_SPACING_X,
    0.0,
  )
}

///|
fn current_rabbit() -> RabbitState? {
  if current_rabbit_index.val < 0 ||
    current_rabbit_index.val >= rabbits.length() {
    None
  } else {
    Some(rabbits[current_rabbit_index.val])
  }
}

///|
fn sync_current_rabbit_refs() -> Unit {
  guard current_rabbit() is Some(rabbit) else {
    rabbit_center.val = @math.Vec2D::zero()
    rabbit_velocity.val = @math.Vec2D::zero()
    rabbit_visible.val = false
    return
  }
  rabbit_center.val = rabbit.center
  rabbit_velocity.val = rabbit.velocity
  rabbit_visible.val = rabbit.visible
}

///|
fn set_camera_anchor_position(position : @math.Vec2D) -> Unit {
  @transform.transforms().set(
    camera_anchor_entity,
    entity_transform_2d(
      position + @math.Vec2D(VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0),
      0,
    ),
  )
}

///|
fn camera_anchor_position() -> @math.Vec2D {
  match @transform.transforms().get(camera_anchor_entity) {
    Some(transform) =>
      @math.Vec2D(transform.translation.x, transform.translation.y) -
      @math.Vec2D(VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0)
    None => @math.Vec2D::zero()
  }
}

///|
fn current_camera_view() -> (
  @camera.Camera,
  @transform.GlobalTransform,
  @camera.OrthographicProjection,
)? {
  guard @camera.cameras().get(camera_anchor_entity) is Some(camera) else {
    return None
  }
  let projection = @camera.orthographic_projections()
    .get(camera_anchor_entity)
    .unwrap_or_default()
  let global = @transform.compute_global_transform(camera_anchor_entity).unwrap_or(
    @transform.GlobalTransform::from_transform(
      @transform.transforms().get(camera_anchor_entity).unwrap_or_default(),
    ),
  )
  Some((camera, global, projection))
}

///|
fn screen_to_world_position(screen : @math.Vec2D) -> @math.Vec2D {
  match current_camera_view() {
    Some((camera, global, projection)) =>
      camera.viewport_to_world_2d(global, projection, screen)
    None => @system.unscale_vec2(screen)
  }
}

///|
fn camera_follow_max_x() -> Double {
  guard current_level.val is Some(level) else { return 0.0 }
  let right = level.background_rect.position[X] +
    level.background_rect.size[X] -
    VIEWPORT_WIDTH
  if right < level.background_rect.position[X] {
    level.background_rect.position[X]
  } else {
    right
  }
}

///|
fn camera_start_x() -> Double {
  camera_start_position.val[X]
}

///|
fn sprite_from_atlas(
  source_offset : @math.Vec2D,
  source_size : @math.Vec2D,
  world_size : @math.Vec2D,
) -> @sprite.Sprite {
  let sprite = @sprite.Sprite::from_image(
    angryrabbits_spritesheet(),
    custom_size=Some(world_size),
  )
  sprite.rect = Some({ position: source_offset, size: source_size })
  sprite
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
    ..@physics2d.RigidBody::kinematic_velocity_based(),
    gravity_scale: 0.0,
    linear_damping: 0.0,
    angular_damping: RABBIT_ANGULAR_DAMPING,
    ccd_enabled: true,
    lock_rotation: false,
  }
}

///|
fn rabbit_flying_body() -> @physics2d.RigidBody {
  {
    ..@physics2d.RigidBody::dynamic(),
    gravity_scale: 1.0,
    linear_damping: RABBIT_LINEAR_DAMPING,
    angular_damping: RABBIT_ANGULAR_DAMPING,
    ccd_enabled: true,
    lock_rotation: false,
  }
}

///|
fn block_body() -> @physics2d.RigidBody {
  {
    ..@physics2d.RigidBody::dynamic(),
    gravity_scale: 1.0,
    linear_damping: BLOCK_LINEAR_DAMPING,
    angular_damping: BLOCK_ANGULAR_DAMPING,
    ccd_enabled: false,
    lock_rotation: false,
  }
}

///|
fn target_body() -> @physics2d.RigidBody {
  {
    ..@physics2d.RigidBody::dynamic(),
    gravity_scale: 1.0,
    linear_damping: TARGET_LINEAR_DAMPING,
    angular_damping: TARGET_ANGULAR_DAMPING,
    ccd_enabled: false,
    lock_rotation: false,
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
  for entity in rabbit_entities {
    clear_physics_entity(entity)
  }
  for entity in block_entities {
    clear_physics_entity(entity)
  }
  for entity in target_entities {
    clear_physics_entity(entity)
  }
}

///|
fn set_rabbit_waiting_state(index : Int, center : @math.Vec2D) -> Unit {
  let rabbit = rabbits[index]
  let entity = rabbit.entity
  let top_left = center_to_circle_position(center, RABBIT_RADIUS)
  @transform.transforms().set(entity, entity_transform_2d(top_left, 70))
  @physics2d.shapes().set(entity, rabbit_shape())
  @physics2d.colliders().set(
    entity,
    @physics2d.Collider::with_material(
      physics_filter(),
      friction=RABBIT_FRICTION,
      restitution=RABBIT_RESTITUTION,
      active=false,
    ),
  )
  @physics2d.rigid_bodies().set(entity, rabbit_ready_body())
  @physics2d.set_rigid_body_translation(entity, top_left)
  @physics2d.set_rigid_body_linear_velocity(entity, @math.Vec2D::zero())
  rabbits[index] = {
    ..rabbit,
    center,
    velocity: @math.Vec2D::zero(),
    rotation: 0.0,
    visible: true,
    state: BeforeThrown,
    alive: true,
    sleep_time: 0.0,
  }
  if index == current_rabbit_index.val {
    sync_current_rabbit_refs()
  }
}

///|
fn set_current_rabbit_ready_state(center : @math.Vec2D) -> Unit {
  guard current_rabbit_index.val >= 0 &&
    current_rabbit_index.val < rabbits.length() else {
    return
  }
  set_rabbit_waiting_state(current_rabbit_index.val, center)
}

///|
fn launch_rabbit_at(
  index : Int,
  center : @math.Vec2D,
  velocity : @math.Vec2D,
) -> Unit {
  let rabbit = rabbits[index]
  let entity = rabbit.entity
  let top_left = center_to_circle_position(center, RABBIT_RADIUS)
  @transform.transforms().set(entity, entity_transform_2d(top_left, 70))
  @physics2d.shapes().set(entity, rabbit_shape())
  @physics2d.colliders().set(
    entity,
    @physics2d.Collider::with_material(
      physics_filter(),
      friction=RABBIT_FRICTION,
      restitution=RABBIT_RESTITUTION,
      active=true,
    ),
  )
  @physics2d.velocities().remove(entity)
  @physics2d.resolved_velocities().remove(entity)
  @physics2d.rigid_bodies().set(entity, rabbit_flying_body())
  @physics2d.set_rigid_body_translation(entity, top_left)
  @physics2d.set_rigid_body_linear_velocity(entity, velocity)
  rabbits[index] = {
    ..rabbit,
    center,
    velocity,
    rotation: 0.0,
    visible: true,
    state: Thrown,
    alive: true,
    sleep_time: 0.0,
  }
  let immediate_center = @physics2d.rigid_body_translation(entity).unwrap_or(
      top_left,
    ) +
    @math.Vec2D(RABBIT_RADIUS, RABBIT_RADIUS)
  let immediate_velocity = @physics2d.rigid_body_linear_velocity(entity).unwrap_or(
    @math.Vec2D::zero(),
  )
  println(
    "[angryrabbits][debug][launch_rabbit_at] index=\{index} center=\{debug_vec2_string(immediate_center)} getter_vel=\{debug_vec2_string(immediate_velocity)} arg_vel=\{debug_vec2_string(velocity)}",
  )
  if index == current_rabbit_index.val {
    sync_current_rabbit_refs()
  }
}

///|
fn launch_rabbit(center : @math.Vec2D, velocity : @math.Vec2D) -> Unit {
  guard current_rabbit_index.val >= 0 &&
    current_rabbit_index.val < rabbits.length() else {
    return
  }
  launch_rabbit_at(current_rabbit_index.val, center, velocity)
}

///|
fn remove_rabbit(index : Int) -> Unit {
  let rabbit = rabbits[index]
  if !rabbit.alive {
    return
  }
  clear_physics_entity(rabbit.entity)
  rabbits[index] = {
    ..rabbit,
    velocity: @math.Vec2D::zero(),
    rotation: rabbit.rotation,
    visible: false,
    state: Removed,
    alive: false,
    sleep_time: 0.0,
  }
  if index == current_rabbit_index.val {
    sync_current_rabbit_refs()
  }
}

///|
fn configure_level_physics(level : LevelDef) -> Unit {
  @physics2d.configure_physics(
    gravity=@math.Vec2D(0.0, GRAVITY),
    pixels_per_meter=PHYSICS_PIXELS_PER_METER,
    max_ccd_substeps=PHYSICS_MAX_CCD_SUBSTEPS,
  )
  clear_level_physics_entities()

  @transform.transforms().set(
    ground_entity,
    entity_transform_2d(level.ground_rect.position, level.ground_rect.zindex),
  )
  @physics2d.shapes().set(
    ground_entity,
    Rect(size=level.ground_rect.size, offset=@math.Vec2D::zero()),
  )
  @physics2d.colliders().set(
    ground_entity,
    @physics2d.Collider::with_material(
      physics_filter(),
      friction=GROUND_FRICTION,
      restitution=0.0,
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
    @transform.transforms().set(entity, entity_transform_2d(top_left, 60))
    @physics2d.shapes().set(
      entity,
      Rect(size=block.size, offset=@math.Vec2D::zero()),
    )
    @physics2d.colliders().set(
      entity,
      @physics2d.Collider::with_material(
        physics_filter(),
        friction=BLOCK_FRICTION,
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
    @transform.transforms().set(entity, entity_transform_2d(top_left, 65))
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
        friction=TARGET_FRICTION,
        restitution=0.0,
      ),
    )
    @physics2d.rigid_bodies().set(entity, target_body())
    @physics2d.set_rigid_body_translation(entity, top_left)
    @physics2d.set_rigid_body_linear_velocity(entity, @math.Vec2D::zero())
  }

  for index in 0..<rabbits.length() {
    set_rabbit_waiting_state(index, rabbits[index].center)
  }
  sync_current_rabbit_refs()
}

///|
fn sync_rabbits_from_physics() -> Unit {
  for index in 0..<rabbits.length() {
    let rabbit = rabbits[index]
    if !rabbit.alive {
      continue
    }
    if rabbit.state != Thrown {
      if index == current_rabbit_index.val {
        sync_current_rabbit_refs()
      }
      continue
    }
    guard @physics2d.rigid_body_translation(rabbit.entity) is Some(top_left) else {
      continue
    }
    rabbits[index] = {
      ..rabbit,
      center: top_left + @math.Vec2D(RABBIT_RADIUS, RABBIT_RADIUS),
      velocity: @physics2d.rigid_body_linear_velocity(rabbit.entity).unwrap_or(
        @math.Vec2D::zero(),
      ),
      rotation: @physics2d.rigid_body_rotation(rabbit.entity).unwrap_or(
        rabbit.rotation,
      ),
    }
    if index == current_rabbit_index.val {
      sync_current_rabbit_refs()
    }
  }
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
      rotation: @physics2d.rigid_body_rotation(block.entity).unwrap_or(
        block.rotation,
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
      velocity: @physics2d.rigid_body_linear_velocity(target.entity).unwrap_or(
        @math.Vec2D::zero(),
      ),
      rotation: @physics2d.rigid_body_rotation(target.entity).unwrap_or(
        target.rotation,
      ),
    }
  }
}

///|
fn sync_physics_snapshots() -> Unit {
  sync_rabbits_from_physics()
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
      slingshot_base_entity, rabbit_eye_entity, camera_anchor_entity, title_entity,
      hint_entity, status_entity, score_entity, debug_text_entity,
    ] {
    ensure_entity_alive(entity)
  }
  ensure_entity_list(aim_dot_entities, AIM_DOT_COUNT)
}

///|
fn register_level_entities(level : LevelDef) -> Unit {
  ensure_entity_list(rabbit_entities, level.max_shots)
  ensure_entity_list(block_entities, level.blocks.length())
  ensure_entity_list(target_entities, level.targets.length())
}

///|
fn hide_unused_level_entities(level : LevelDef) -> Unit {
  for index in level.max_shots..<rabbit_entities.length() {
    clear_physics_entity(rabbit_entities[index])
    set_entity_visibility(rabbit_entities[index], false)
  }
  for index in level.blocks.length()..<block_entities.length() {
    clear_physics_entity(block_entities[index])
    set_entity_visibility(block_entities[index], false)
  }
  for index in level.targets.length()..<target_entities.length() {
    clear_physics_entity(target_entities[index])
    set_entity_visibility(target_entities[index], false)
  }
}

///|
fn instantiate_level(level : LevelDef) -> Unit {
  rabbits.clear()
  blocks.clear()
  targets.clear()
  for index in 0..<level.max_shots {
    rabbits.push({
      entity: rabbit_entities[index],
      center: rabbit_queue_center(index),
      velocity: @math.Vec2D::zero(),
      rotation: 0.0,
      visible: true,
      state: BeforeThrown,
      alive: true,
      sleep_time: 0.0,
    })
  }
  for index, block in level.blocks {
    blocks.push({
      entity: block_entities[index],
      center: block.center,
      size: block.size,
      velocity: @math.Vec2D::zero(),
      rotation: 0.0,
      health: BLOCK_HEALTH,
      alive: true,
    })
  }
  for index, target in level.targets {
    targets.push({
      entity: target_entities[index],
      center: target.center,
      radius: target.radius,
      velocity: @math.Vec2D::zero(),
      rotation: 0.0,
      health: TARGET_HEALTH,
      alive: true,
    })
  }
  hide_unused_level_entities(level)
}

///|
fn hide_aim_dots() -> Unit {
  for entity in aim_dot_entities {
    set_entity_visibility(entity, false)
  }
}

///|
fn launch_velocity_from_rabbit(center : @math.Vec2D) -> @math.Vec2D {
  let stretch = slingshot_anchor() - center
  let distance = vec_length(stretch)
  let distance_units = if MAX_DRAG_RADIUS <= 0.0 {
    0.0
  } else {
    distance / MAX_DRAG_RADIUS * UPSTREAM_MAX_PULL_DISTANCE
  }
  stretch.scalar_mul(THROW_SPEED * distance_units)
}

///|
fn refresh_aim_dots() -> Unit {
  if slingshot_state.val != UserPulling {
    hide_aim_dots()
    return
  }
  let velocity = launch_velocity_from_rabbit(rabbit_center.val)
  for index, entity in aim_dot_entities {
    let time = (index.to_double() + 1.0) * AIM_DOT_TIME_STEP
    let offset = velocity.scalar_mul(time) +
      @math.Vec2D(0.0, GRAVITY * 0.5 * time * time)
    @mesh2d.mesh2ds().set(
      entity,
      @mesh2d.Mesh2d::new(circle_mesh_handle(AIM_DOT_RADIUS)),
    )
    @material2d.mesh_material2ds().set(
      entity,
      @material2d.MeshMaterial2d::from_color_material(
        circle_material_handle("rgba(255,255,255,0.85)"),
      ),
    )
    @transform.transforms().set(
      entity,
      entity_transform_2d(rabbit_center.val + offset, 120),
    )
    show_entity(entity)
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
  show_entity(entity)
  @ui.texts().set(entity, @ui.Text::new(text))
  @ui.text_fonts().set(entity, @ui.TextFont::from_css(font))
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
  @ui.text_layouts().set(entity, @ui.TextLayout::new(align=Left, baseline=Top))
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2D(-0.5, 0.5)))
  @transform.transforms().set(entity, entity_transform_2d(position, zindex))
}

///|
fn set_entity_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn debug_game_state_name(state : GameState) -> String {
  match state {
    Error => "Error"
    Start => "Start"
    BirdMovingToSlingshot => "BirdMovingToSlingshot"
    Playing => "Playing"
    Won => "Won"
    Lost => "Lost"
  }
}

///|
fn debug_slingshot_state_name(state : SlingshotState) -> String {
  match state {
    Idle => "Idle"
    UserPulling => "UserPulling"
    BirdFlying => "BirdFlying"
  }
}

///|
fn debug_camera_mode_name(mode : CameraMode) -> String {
  match mode {
    CameraIdle => "CameraIdle"
    CameraFollowBird => "CameraFollowBird"
    CameraReturnToStart => "CameraReturnToStart"
  }
}

///|
fn debug_bird_state_name(state : BirdState) -> String {
  match state {
    BeforeThrown => "BeforeThrown"
    Thrown => "Thrown"
    Removed => "Removed"
  }
}

///|
fn debug_scalar_string(value : Double) -> String {
  let scaled = (value * 10.0).round().to_int()
  let abs_scaled = if scaled < 0 { -scaled } else { scaled }
  let sign = if scaled < 0 { "-" } else { "" }
  let integer_part = abs_scaled / 10
  let fraction_part = abs_scaled % 10
  "\{sign}\{integer_part}.\{fraction_part}"
}

///|
fn debug_vec2_string(value : @math.Vec2D) -> String {
  "(\{debug_scalar_string(value[X])}, \{debug_scalar_string(value[Y])})"
}

///|
fn current_rabbit_debug_line() -> String {
  match current_rabbit() {
    Some(rabbit) =>
      "rabbit idx=\{current_rabbit_index.val} \{debug_bird_state_name(rabbit.state)} alive=\{rabbit.alive}"
    None => "rabbit none"
  }
}

///|
fn debug_text() -> String {
  let line1 = "DBG g=\{debug_game_state_name(game_state.val)} s=\{debug_slingshot_state_name(slingshot_state.val)} cam=\{debug_camera_mode_name(camera_mode.val)}"
  let line2 = "mouse s=\{debug_vec2_string(debug_mouse_screen.val)} w=\{debug_vec2_string(debug_mouse_world.val)}"
  let line3 = "drag=\{debug_vec2_string(debug_drag_center.val)} rel=\{debug_vec2_string(debug_release_center.val)}"
  let line4 = "rel_mouse=\{debug_vec2_string(debug_release_mouse_world.val)} launch=\{debug_vec2_string(debug_launch_velocity.val)}"
  let line5 = "phys center=\{debug_vec2_string(debug_physics_center.val)} vel=\{debug_vec2_string(debug_physics_velocity.val)}"
  let line6 = "\{current_rabbit_debug_line()} trace=\{debug_trace_fixed_frames_remaining.val}"
  let line7 = "evt: \{debug_last_event.val}"
  line1 +
  "\n" +
  line2 +
  "\n" +
  line3 +
  "\n" +
  line4 +
  "\n" +
  line5 +
  "\n" +
  line6 +
  "\n" +
  line7
}

///|
fn sync_debug_ui() -> Unit {
  if !debug_ui_enabled.val {
    set_entity_visibility(debug_text_entity, false)
    return
  }
  set_text_entity(
    debug_text_entity,
    debug_text(),
    @math.Vec2D(20.0, 112.0),
    "10px \{ANGRYRABBITS_FONT_FAMILY}",
    "rgb(24, 68, 32)",
    240,
  )
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
      slingshot_base_entity, rabbit_eye_entity,
    ] {
    set_entity_visibility(entity, false)
  }
  for entity in rabbit_entities {
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
  let background_sprite = @sprite.Sprite::from_color(
    sprite_color("rgb(29, 20, 24)"),
    @math.Vec2D(VIEWPORT_WIDTH, VIEWPORT_HEIGHT),
  )
  background_sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(background_entity, background_sprite)
  @transform.transforms().set(
    background_entity,
    entity_transform_2d(@math.Vec2D::zero(), 0),
  )
  show_entity(background_entity)
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
  let background = level.background_rect
  let ground = level.ground_rect
  let hill = level.hill_circle
  let background_sprite = @sprite.Sprite::from_color(
    sprite_color(background.color),
    background.size,
  )
  background_sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(background_entity, background_sprite)
  @transform.transforms().set(
    background_entity,
    entity_transform_2d(background.position, background.zindex),
  )
  set_entity_visibility(background_entity, true)

  @mesh2d.mesh2ds().set(
    hill_entity,
    @mesh2d.Mesh2d::new(circle_mesh_handle(hill.radius)),
  )
  @material2d.mesh_material2ds().set(
    hill_entity,
    @material2d.MeshMaterial2d::from_color_material(
      circle_material_handle(hill.color),
    ),
  )
  @transform.transforms().set(
    hill_entity,
    entity_transform_2d(hill.center, hill.zindex),
  )
  set_entity_visibility(hill_entity, true)

  let ground_sprite = @sprite.Sprite::from_color(
    sprite_color(ground.color),
    ground.size,
  )
  ground_sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(ground_entity, ground_sprite)
  @transform.transforms().set(
    ground_entity,
    entity_transform_2d(ground.position, ground.zindex),
  )
  set_entity_visibility(ground_entity, true)

  let slingshot_scale_y = SLINGSHOT_WORLD_HEIGHT / SLINGSHOT_SPRITE_SRC_HEIGHT
  let slingshot_front_world_height = SLINGSHOT_FRONT_SRC_HEIGHT *
    slingshot_scale_y
  let slingshot_back_world_height = SLINGSHOT_BACK_SRC_HEIGHT *
    slingshot_scale_y

  @sprite.sprites().set(
    slingshot_left_entity,
    sprite_from_atlas(
      @math.Vec2D(
        SLINGSHOT_SPRITE_SRC_X,
        SLINGSHOT_SPRITE_SRC_Y + SLINGSHOT_BACK_SRC_OFFSET_Y,
      ),
      @math.Vec2D(SLINGSHOT_SPRITE_SRC_WIDTH, SLINGSHOT_BACK_SRC_HEIGHT),
      @math.Vec2D(SLINGSHOT_WORLD_WIDTH, slingshot_back_world_height),
    ),
  )
  if @sprite.sprites().get(slingshot_left_entity) is Some(sprite) {
    sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  }
  @transform.transforms().set(
    slingshot_left_entity,
    entity_transform_2d(
      level.slingshot_back_stick +
      @math.Vec2D(SLINGSHOT_BACK_OFFSET_X, SLINGSHOT_BACK_OFFSET_Y),
      30,
    ),
  )

  @sprite.sprites().set(
    slingshot_right_entity,
    sprite_from_atlas(
      @math.Vec2D(
        SLINGSHOT_SPRITE_SRC_X,
        SLINGSHOT_SPRITE_SRC_Y + SLINGSHOT_FRONT_SRC_OFFSET_Y,
      ),
      @math.Vec2D(SLINGSHOT_SPRITE_SRC_WIDTH, SLINGSHOT_FRONT_SRC_HEIGHT),
      @math.Vec2D(SLINGSHOT_WORLD_WIDTH, slingshot_front_world_height),
    ),
  )
  if @sprite.sprites().get(slingshot_right_entity) is Some(sprite) {
    sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  }
  @transform.transforms().set(
    slingshot_right_entity,
    entity_transform_2d(
      level.slingshot_front_stick +
      @math.Vec2D(SLINGSHOT_FRONT_OFFSET_X, SLINGSHOT_FRONT_OFFSET_Y),
      72,
    ),
  )
  set_entity_visibility(slingshot_right_entity, true)
  set_entity_visibility(slingshot_left_entity, true)
  set_entity_visibility(slingshot_base_entity, false)
}

///|
fn sync_dynamic_visuals() -> Unit {
  let rabbit_size = @math.Vec2D(RABBIT_RADIUS * 2.0, RABBIT_RADIUS * 2.0)
  for rabbit in rabbits {
    @sprite.sprites().set(
      rabbit.entity,
      sprite_from_atlas(
        @math.Vec2D(RABBIT_SPRITE_SRC_X, RABBIT_SPRITE_SRC_Y),
        @math.Vec2D(RABBIT_SPRITE_SRC_WIDTH, RABBIT_SPRITE_SRC_HEIGHT),
        rabbit_size,
      ),
    )
    @transform.transforms().set(
      rabbit.entity,
      entity_transform_2d(rabbit.center, 70, rotation=rabbit.rotation),
    )
    if @sprite.sprites().get(rabbit.entity) is Some(sprite) {
      sprite.anchor = @sprite.Anchor(@math.Vec2D(0.0, 0.0))
    }
    set_entity_visibility(rabbit.entity, rabbit.visible)
  }

  set_entity_visibility(rabbit_eye_entity, false)

  for block in blocks {
    @sprite.sprites().set(
      block.entity,
      sprite_from_atlas(
        @math.Vec2D(BLOCK_SPRITE_SRC_X, BLOCK_SPRITE_SRC_Y),
        @math.Vec2D(BLOCK_SPRITE_SRC_WIDTH, BLOCK_SPRITE_SRC_HEIGHT),
        block.size,
      ),
    )
    @transform.transforms().set(
      block.entity,
      entity_transform_2d(block.center, 60, rotation=block.rotation),
    )
    if @sprite.sprites().get(block.entity) is Some(sprite) {
      sprite.anchor = @sprite.Anchor(@math.Vec2D(0.0, 0.0))
    }
    set_entity_visibility(block.entity, block.alive)
  }

  for target in targets {
    let target_size = @math.Vec2D(target.radius * 2.0, target.radius * 2.0)
    @sprite.sprites().set(
      target.entity,
      sprite_from_atlas(
        @math.Vec2D(TARGET_SPRITE_SRC_X, TARGET_SPRITE_SRC_Y),
        @math.Vec2D(TARGET_SPRITE_SRC_WIDTH, TARGET_SPRITE_SRC_HEIGHT),
        target_size,
      ),
    )
    @transform.transforms().set(
      target.entity,
      entity_transform_2d(target.center, 65, rotation=target.rotation),
    )
    if @sprite.sprites().get(target.entity) is Some(sprite) {
      sprite.anchor = @sprite.Anchor(@math.Vec2D(0.0, 0.0))
    }
    set_entity_visibility(target.entity, target.alive)
  }

  refresh_aim_dots()
}

///|
fn status_text() -> String {
  match game_state.val {
    Error =>
      "Level load failed. Fix the LDtk file and press Enter or R to retry."
    Start => "Tap the screen to start."
    BirdMovingToSlingshot => "Preparing the next rabbit."
    Playing =>
      match slingshot_state.val {
        Idle => "Drag the rabbit backward with the mouse, then release."
        UserPulling => "Release to launch. Rabbit speed scales with stretch."
        BirdFlying => "Break every green target before you run out of rabbits."
      }
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
fn reset_debug_state(event : String) -> Unit {
  debug_mouse_screen.val = @math.Vec2D::zero()
  debug_mouse_world.val = @math.Vec2D::zero()
  debug_drag_center.val = @math.Vec2D::zero()
  debug_release_screen.val = @math.Vec2D::zero()
  debug_release_mouse_world.val = @math.Vec2D::zero()
  debug_release_center.val = @math.Vec2D::zero()
  debug_launch_velocity.val = @math.Vec2D::zero()
  debug_physics_center.val = @math.Vec2D::zero()
  debug_physics_velocity.val = @math.Vec2D::zero()
  debug_last_event.val = event
  debug_trace_fixed_frames_remaining.val = 0
  debug_trace_update_frames_remaining.val = 0
  debug_tracked_rabbit_entity.val = None
}

///|
fn sync_ui() -> Unit {
  if game_state.val == Error {
    sync_error_visuals(load_error_message.val)
    sync_debug_ui()
    return
  }
  let title_text = "ANGRY RABBITS"
  if ui_title_text_cache.val != title_text {
    set_text_entity(
      title_entity,
      title_text,
      @math.Vec2D(20.0, 16.0),
      "32px \{ANGRYRABBITS_FONT_FAMILY}",
      "rgb(84, 48, 22)",
      220,
    )
    ui_title_text_cache.val = title_text
  } else {
    ensure_entity_alive(title_entity)
    show_entity(title_entity)
  }
  let hint_text = "Click to start   Mouse drag/release launch   R/Enter restart   ESC back"
  if ui_hint_text_cache.val != hint_text {
    set_text_entity(
      hint_entity,
      hint_text,
      @math.Vec2D(20.0, VIEWPORT_HEIGHT - 28.0),
      "16px \{ANGRYRABBITS_FONT_FAMILY}",
      "rgb(77, 74, 66)",
      220,
    )
    ui_hint_text_cache.val = hint_text
  } else {
    ensure_entity_alive(hint_entity)
    show_entity(hint_entity)
  }
  let score = score_text()
  if ui_score_text_cache.val != score {
    set_text_entity(
      score_entity,
      score,
      @math.Vec2D(20.0, 54.0),
      "20px \{ANGRYRABBITS_FONT_FAMILY}",
      "rgb(66, 52, 32)",
      220,
    )
    ui_score_text_cache.val = score
  } else {
    ensure_entity_alive(score_entity)
    show_entity(score_entity)
  }
  let status = status_text()
  let status_color = if game_state.val == Won {
    "rgb(32, 112, 48)"
  } else if game_state.val == Lost {
    "rgb(161, 54, 44)"
  } else {
    "rgb(72, 60, 44)"
  }
  if ui_status_text_cache.val != status ||
    ui_status_color_cache.val != status_color {
    set_text_entity(
      status_entity,
      status,
      @math.Vec2D(20.0, 82.0),
      "18px \{ANGRYRABBITS_FONT_FAMILY}",
      status_color,
      220,
    )
    ui_status_text_cache.val = status
    ui_status_color_cache.val = status_color
  } else {
    ensure_entity_alive(status_entity)
    show_entity(status_entity)
  }
  sync_debug_ui()
}

///|
fn reset_level() -> Unit {
  register_angryrabbits_font_once()
  ui_title_text_cache.val = ""
  ui_hint_text_cache.val = ""
  ui_score_text_cache.val = ""
  ui_status_text_cache.val = ""
  ui_status_color_cache.val = ""
  match load_current_level() {
    Err(message) => {
      reset_debug_state("level load error")
      current_level.val = None
      load_error_message.val = message
      game_state.val = Error
      slingshot_state.val = Idle
      shots_remaining.val = 0
      rabbits.clear()
      current_rabbit_index.val = 0
      rabbit_center.val = @math.Vec2D::zero()
      rabbit_velocity.val = @math.Vec2D::zero()
      rabbit_visible.val = false
      rabbit_flight_time.val = 0.0
      rabbit_idle_time.val = 0.0
      rabbit_motion_kind.val = RabbitMotionNone
      camera_mode.val = CameraIdle
      blocks.clear()
      targets.clear()
      clear_level_physics_entities()
      register_scene_entities()
      sync_error_visuals(message)
    }
    Ok(level) => {
      reset_debug_state("level reset")
      current_level.val = Some(level)
      load_error_message.val = ""
      register_scene_entities()
      register_level_entities(level)
      sync_static_visuals()
      current_rabbit_index.val = 0
      instantiate_level(level)
      configure_level_physics(level)
      shots_remaining.val = level.max_shots
      game_state.val = Start
      slingshot_state.val = Idle
      rabbit_flight_time.val = 0.0
      rabbit_idle_time.val = 0.0
      rabbit_motion_kind.val = RabbitMotionNone
      camera_start_position.val = level.background_rect.position
      set_camera_anchor_position(camera_start_position.val)
      camera_mode.val = CameraIdle
      camera_return_elapsed.val = 0.0
      camera_return_duration.val = 0.0
      camera_return_origin.val = camera_start_position.val
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
    @camera.cameras().set(camera_anchor_entity, @camera.Camera::new())
    @camera.camera2ds().set(camera_anchor_entity, @camera.Camera2d::new())
    @camera.orthographic_projections().set(
      camera_anchor_entity,
      @camera.OrthographicProjection::new(),
    )
    set_camera_anchor_position(@math.Vec2D::zero())
    scene_initialized.val = true
  }
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  setup_scene_if_needed()
  profile_enabled.val = env_flag_enabled(PROFILE_ENV)
  capture_enabled.val = env_flag_enabled(CAPTURE_ENV)
  debug_ui_enabled.val = env_flag_enabled(DEBUG_UI_ENV)
  reset_level()
  let started_at = @time.elapsed_raw()
  profile_started_at.val = started_at
  profile_last_report_at.val = started_at
  profile_frame_count.val = 0
  profile_sim_total.val = 0.0
  profile_render_total.val = 0.0
  profile_frame_dt_total.val = 0.0
  capture_started_at.val = started_at
  capture_taken.val = false
  capture_forced_start.val = false
}

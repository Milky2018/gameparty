///|
fn vec_length(vector : @math.Vec2D) -> Double {
  vector.distance()
}

///|
fn clamp_double(value : Double, lower : Double, upper : Double) -> Double {
  if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}

///|
fn lerp_vec2(
  start : @math.Vec2D,
  end_ : @math.Vec2D,
  alpha : Double,
) -> @math.Vec2D {
  start.scalar_mul(1.0 - alpha) + end_.scalar_mul(alpha)
}

///|
fn clamp_drag_target(mouse_center : @math.Vec2D) -> @math.Vec2D {
  let offset = mouse_center - slingshot_anchor()
  let length = vec_length(offset)
  let clamped = if length <= MAX_DRAG_RADIUS {
    mouse_center
  } else {
    slingshot_anchor() + offset.scalar_div(length).scalar_mul(MAX_DRAG_RADIUS)
  }
  let max_drag_y = GROUND_Y - RABBIT_RADIUS - DRAG_GROUND_CLEARANCE
  @math.Vec2D(
    clamped[X],
    if clamped[Y] > max_drag_y {
      max_drag_y
    } else {
      clamped[Y]
    },
  )
}

///|
fn drag_distance(center : @math.Vec2D) -> Double {
  vec_length(center - slingshot_anchor())
}

///|
let contact_event_reader : @event.EventReader[@physics2d.ContactEvent] = @event.EventReader::new()

///|
fn circle_intersects_circle(
  center_a : @math.Vec2D,
  radius_a : Double,
  center_b : @math.Vec2D,
  radius_b : Double,
) -> Bool {
  let delta = center_a - center_b
  let radius = radius_a + radius_b
  delta[X] * delta[X] + delta[Y] * delta[Y] <= radius * radius
}

///|
fn rabbit_motion_active() -> Bool {
  rabbit_motion_kind.val != RabbitMotionNone
}

///|
fn rabbit_ready_for_pickup() -> Bool {
  match current_rabbit() {
    Some(rabbit) =>
      game_state.val == Playing &&
      slingshot_state.val == Idle &&
      !rabbit_motion_active() &&
      rabbit.alive &&
      rabbit.visible &&
      rabbit.state == BeforeThrown &&
      shots_remaining.val > 0
    None => false
  }
}

///|
fn rabbit_contains(point : @math.Vec2D) -> Bool {
  circle_intersects_circle(rabbit_center.val, RABBIT_PICKUP_RADIUS, point, 0.0)
}

///|
fn all_targets_cleared() -> Bool {
  targets.all(fn(target) { !target.alive })
}

///|
fn find_rabbit_index(entity : @entity.Entity) -> Int? {
  for index in 0..<rabbits.length() {
    if rabbits[index].entity == entity {
      return Some(index)
    }
  }
  None
}

///|
fn find_block_index(entity : @entity.Entity) -> Int? {
  for index in 0..<blocks.length() {
    if blocks[index].entity == entity {
      return Some(index)
    }
  }
  None
}

///|
fn find_target_index(entity : @entity.Entity) -> Int? {
  for index in 0..<targets.length() {
    if targets[index].entity == entity {
      return Some(index)
    }
  }
  None
}

///|
fn velocity_for_entity(entity : @entity.Entity) -> @math.Vec2D {
  if find_rabbit_index(entity) is Some(index) {
    rabbits[index].velocity
  } else if find_block_index(entity) is Some(index) {
    blocks[index].velocity
  } else if find_target_index(entity) is Some(index) {
    targets[index].velocity
  } else {
    @physics2d.rigid_body_linear_velocity(entity).unwrap_or(@math.Vec2D::zero())
  }
}

///|
fn collision_damage_from_velocity(velocity : @math.Vec2D) -> Double {
  vec_length(velocity) / PHYSICS_PIXELS_PER_METER * COLLISION_DAMAGE_FACTOR
}

///|
fn entity_is_thrown_rabbit(entity : @entity.Entity) -> Bool {
  match find_rabbit_index(entity) {
    Some(index) => {
      let rabbit = rabbits[index]
      rabbit.alive && rabbit.state == Thrown
    }
    None => false
  }
}

///|
fn destroy_target(index : Int) -> Unit {
  let target = targets[index]
  if !target.alive {
    return
  }
  targets[index] = { ..target, health: 0.0, alive: false }
  destroy_target_body(target.entity)
}

///|
fn destroy_block(index : Int) -> Unit {
  let block = blocks[index]
  if !block.alive {
    return
  }
  blocks[index] = {
    ..block,
    velocity: @math.Vec2D::zero(),
    health: 0.0,
    alive: false,
  }
  clear_physics_entity(block.entity)
}

///|
fn damage_block(index : Int, damage : Double) -> Unit {
  if damage <= 0.0 {
    return
  }
  let block = blocks[index]
  if !block.alive {
    return
  }
  let next_health = block.health - damage
  if next_health <= 0.0 {
    destroy_block(index)
  } else {
    blocks[index] = { ..block, health: next_health }
  }
}

///|
fn damage_target(index : Int, damage : Double) -> Unit {
  if damage <= 0.0 {
    return
  }
  let target = targets[index]
  if !target.alive {
    return
  }
  let next_health = target.health - damage
  if next_health <= 0.0 {
    destroy_target(index)
  } else {
    targets[index] = { ..target, health: next_health }
  }
}

///|
fn current_rabbit_out_of_bounds() -> Bool {
  rabbit_center.val[X] < -OUT_OF_BOUNDS_MARGIN ||
  rabbit_center.val[X] > VIEWPORT_WIDTH + OUT_OF_BOUNDS_MARGIN ||
  rabbit_center.val[Y] > VIEWPORT_HEIGHT + OUT_OF_BOUNDS_MARGIN
}

///|
fn rect_body_out_of_bounds(center : @math.Vec2D, size : @math.Vec2D) -> Bool {
  let half = size.scalar_mul(0.5)
  center[X] + half[X] < -OUT_OF_BOUNDS_MARGIN ||
  center[X] - half[X] > VIEWPORT_WIDTH + OUT_OF_BOUNDS_MARGIN ||
  center[Y] - half[Y] > VIEWPORT_HEIGHT + OUT_OF_BOUNDS_MARGIN
}

///|
fn circle_body_out_of_bounds(center : @math.Vec2D, radius : Double) -> Bool {
  center[X] + radius < -OUT_OF_BOUNDS_MARGIN ||
  center[X] - radius > VIEWPORT_WIDTH + OUT_OF_BOUNDS_MARGIN ||
  center[Y] - radius > VIEWPORT_HEIGHT + OUT_OF_BOUNDS_MARGIN
}

///|
fn cleanup_out_of_bounds_bodies() -> Unit {
  for index in 0..<blocks.length() {
    let block = blocks[index]
    if block.alive && rect_body_out_of_bounds(block.center, block.size) {
      destroy_block(index)
    }
  }
  for index in 0..<targets.length() {
    let target = targets[index]
    if target.alive && circle_body_out_of_bounds(target.center, target.radius) {
      destroy_target(index)
    }
  }
}

///|
fn update_thrown_rabbits(delta : Double) -> Unit {
  for index in 0..<rabbits.length() {
    let rabbit = rabbits[index]
    if !rabbit.alive || rabbit.state != Thrown {
      continue
    }
    if circle_body_out_of_bounds(rabbit.center, RABBIT_RADIUS) {
      remove_rabbit(index)
      continue
    }
    let next_sleep_time = if vec_length(rabbit.velocity) < STOP_SPEED {
      rabbit.sleep_time + delta
    } else {
      0.0
    }
    if next_sleep_time >= THROWN_RABBIT_REMOVE_DELAY {
      remove_rabbit(index)
    } else {
      rabbits[index] = { ..rabbit, sleep_time: next_sleep_time }
    }
  }
  sync_current_rabbit_refs()
}

///|
fn world_is_quiet() -> Bool {
  for rabbit in rabbits {
    if rabbit.alive &&
      rabbit.state == Thrown &&
      vec_length(rabbit.velocity) >= STOP_SPEED {
      return false
    }
  }
  for block in blocks {
    if block.alive && vec_length(block.velocity) >= STOP_SPEED {
      return false
    }
  }
  for target in targets {
    if target.alive && vec_length(target.velocity) >= STOP_SPEED {
      return false
    }
  }
  true
}

///|
fn apply_contact_damage(
  entity : @entity.Entity,
  other : @entity.Entity,
) -> Unit {
  if find_block_index(entity) is Some(block_index) {
    let damage = collision_damage_from_velocity(velocity_for_entity(other))
    damage_block(block_index, damage)
    return
  }
  if find_target_index(entity) is Some(target_index) {
    if entity_is_thrown_rabbit(other) {
      destroy_target(target_index)
    } else {
      let damage = collision_damage_from_velocity(velocity_for_entity(other))
      damage_target(target_index, damage)
    }
  }
}

///|
fn apply_contact_damage_events() -> Unit {
  for event in @event.read(contact_event_reader, @physics2d.contact_event_bus) {
    if event.started {
      apply_contact_damage(event.entity, event.other)
    }
  }
}

///|
fn start_rabbit_motion(
  kind : RabbitMotionKind,
  start : @math.Vec2D,
  end_ : @math.Vec2D,
) -> Unit {
  rabbit_motion_kind.val = kind
  rabbit_motion_start.val = start
  rabbit_motion_end.val = end_
  rabbit_motion_elapsed.val = 0.0
  let distance = vec_length(end_ - start)
  rabbit_motion_duration.val = if distance <= 0.0 {
    0.1
  } else {
    distance / RABBIT_MOVE_SPEED
  }
  set_current_rabbit_ready_state(start)
}

///|
fn start_move_current_rabbit_to_slingshot() -> Unit {
  guard current_rabbit() is Some(rabbit) else { return }
  guard current_level.val is Some(level) else { return }
  game_state.val = BirdMovingToSlingshot
  slingshot_state.val = Idle
  start_rabbit_motion(RabbitMoveToSlingshot, rabbit.center, level.rabbit_spawn)
}

///|
fn finish_turn_after_camera_return() -> Unit {
  if all_targets_cleared() {
    game_state.val = Won
    slingshot_state.val = Idle
    return
  }
  if current_rabbit_index.val >= rabbits.length() - 1 {
    game_state.val = Lost
    slingshot_state.val = Idle
    return
  }
  current_rabbit_index.val = current_rabbit_index.val + 1
  sync_current_rabbit_refs()
  start_move_current_rabbit_to_slingshot()
}

///|
fn start_camera_return_to_start() -> Unit {
  let origin = camera_anchor_position()
  camera_return_origin.val = origin
  camera_return_elapsed.val = 0.0
  let distance = vec_length(camera_start_position.val - origin)
  camera_return_duration.val = if distance <= 0.0 {
    0.1
  } else {
    distance / CAMERA_RETURN_SPEED
  }
  if distance <= 0.0 {
    set_camera_anchor_position(camera_start_position.val)
    camera_mode.val = CameraIdle
    finish_turn_after_camera_return()
  } else {
    camera_mode.val = CameraReturnToStart
  }
}

///|
fn begin_next_shot_or_end() -> Unit {
  rabbit_flight_time.val = 0.0
  rabbit_idle_time.val = 0.0
  slingshot_state.val = Idle
  game_state.val = BirdMovingToSlingshot
  start_camera_return_to_start()
}

///|
fn update_rabbit_motion(delta : Double) -> Unit {
  if rabbit_motion_kind.val == RabbitMotionNone {
    return
  }
  rabbit_motion_elapsed.val = rabbit_motion_elapsed.val + delta
  let duration = if rabbit_motion_duration.val <= 0.0 {
    0.0001
  } else {
    rabbit_motion_duration.val
  }
  let alpha = clamp_double(rabbit_motion_elapsed.val / duration, 0.0, 1.0)
  let center = lerp_vec2(rabbit_motion_start.val, rabbit_motion_end.val, alpha)
  set_current_rabbit_ready_state(center)
  if alpha >= 1.0 {
    let finished_kind = rabbit_motion_kind.val
    rabbit_motion_kind.val = RabbitMotionNone
    rabbit_motion_elapsed.val = 0.0
    rabbit_motion_duration.val = 0.0
    set_current_rabbit_ready_state(rabbit_motion_end.val)
    match finished_kind {
      RabbitMoveToSlingshot | RabbitReturnToSlingshot => {
        game_state.val = Playing
        slingshot_state.val = Idle
      }
      RabbitMotionNone => ()
    }
  }
}

///|
fn update_camera(delta : Double) -> Unit {
  match camera_mode.val {
    CameraIdle => ()
    CameraFollowBird =>
      match current_rabbit() {
        Some(rabbit) =>
          if rabbit.alive && rabbit.state == Thrown {
            let target_x = rabbit.center[X] - VIEWPORT_WIDTH / 2.0
            let clamped_x = clamp_double(
              target_x,
              camera_start_x(),
              camera_follow_max_x(),
            )
            set_camera_anchor_position(
              @math.Vec2D(clamped_x, camera_start_position.val[Y]),
            )
          } else {
            camera_mode.val = CameraIdle
          }
        None => camera_mode.val = CameraIdle
      }
    CameraReturnToStart => {
      camera_return_elapsed.val = camera_return_elapsed.val + delta
      let duration = if camera_return_duration.val <= 0.0 {
        0.0001
      } else {
        camera_return_duration.val
      }
      let alpha = clamp_double(camera_return_elapsed.val / duration, 0.0, 1.0)
      set_camera_anchor_position(
        lerp_vec2(camera_return_origin.val, camera_start_position.val, alpha),
      )
      if alpha >= 1.0 {
        camera_mode.val = CameraIdle
        set_camera_anchor_position(camera_start_position.val)
        finish_turn_after_camera_return()
      }
    }
  }
}

///|
fn input_system(_world : @ecs.World) -> Unit {
  let mouse_center = screen_to_world_position(@inputs.mouse.pos)
  debug_mouse_screen.val = @inputs.mouse.pos
  debug_mouse_world.val = mouse_center

  if @inputs.is_just_pressed(Escape) {
    request_exit()
    return
  }

  if game_state.val == Error &&
    (@inputs.is_just_pressed(KeyR) || @inputs.is_just_pressed(Enter)) {
    reset_level()
    return
  }

  if (game_state.val == Won || game_state.val == Lost) &&
    (
      @inputs.is_just_pressed(KeyR) ||
      @inputs.is_just_pressed(Enter) ||
      @inputs.just_release_mouse.left_button
    ) {
    reset_level()
    return
  }

  if game_state.val == Start && @inputs.just_release_mouse.left_button {
    debug_last_event.val = "start click -> move to slingshot"
    start_move_current_rabbit_to_slingshot()
    return
  }

  if game_state.val != Playing || rabbit_motion_active() {
    return
  }

  if rabbit_ready_for_pickup() && @inputs.just_pressed_mouse.left_button {
    if rabbit_contains(mouse_center) {
      slingshot_state.val = UserPulling
      debug_last_event.val = "pickup accepted"
    } else {
      debug_last_event.val = "pickup miss"
    }
  }

  if slingshot_state.val == UserPulling {
    let drag_center = clamp_drag_target(mouse_center)
    debug_drag_center.val = drag_center
    if @inputs.is_mouse_pressed(Left) {
      set_current_rabbit_ready_state(drag_center)
    }
    if @inputs.just_release_mouse.left_button {
      let release_center = drag_center
      let launch_velocity = launch_velocity_from_rabbit(release_center)
      debug_release_screen.val = @inputs.mouse.pos
      debug_release_mouse_world.val = mouse_center
      debug_release_center.val = release_center
      debug_launch_velocity.val = launch_velocity
      guard current_level.val is Some(level) else { return }
      if drag_distance(release_center) < MIN_LAUNCH_STRETCH {
        debug_last_event.val = "release below min stretch"
        debug_trace_fixed_frames_remaining.val = 0
        debug_trace_update_frames_remaining.val = 0
        debug_tracked_rabbit_entity.val = None
        println(
          "[angryrabbits][debug][return] mouse_screen=\{debug_vec2_string(debug_release_screen.val)} mouse_world=\{debug_vec2_string(debug_release_mouse_world.val)} release_center=\{debug_vec2_string(release_center)} launch=\{debug_vec2_string(launch_velocity)}",
        )
        start_rabbit_motion(
          RabbitReturnToSlingshot,
          release_center,
          level.rabbit_spawn,
        )
      } else {
        debug_last_event.val = "launch"
        debug_trace_fixed_frames_remaining.val = DEBUG_TRACE_FIXED_FRAMES
        debug_trace_update_frames_remaining.val = 1
        debug_tracked_rabbit_entity.val = current_rabbit().map(rabbit => {
          rabbit.entity
        })
        println(
          "[angryrabbits][debug][launch] mouse_screen=\{debug_vec2_string(debug_release_screen.val)} mouse_world=\{debug_vec2_string(debug_release_mouse_world.val)} release_center=\{debug_vec2_string(release_center)} anchor=\{debug_vec2_string(slingshot_anchor())} launch=\{debug_vec2_string(launch_velocity)}",
        )
        slingshot_state.val = BirdFlying
        launch_rabbit(release_center, launch_velocity)
        rabbit_flight_time.val = 0.0
        rabbit_idle_time.val = 0.0
        shots_remaining.val = shots_remaining.val - 1
        camera_mode.val = CameraFollowBird
      }
    }
  }
}

///|
fn simulation_system(_world : @ecs.World) -> Unit {
  if game_state.val == Error {
    return
  }
  let delta = @time.delta()
  if debug_trace_update_frames_remaining.val > 0 {
    match debug_tracked_rabbit_entity.val {
      Some(entity) => {
        let before_center = @physics2d.rigid_body_translation(entity).map_or(
          @math.Vec2D::zero(),
          fn(top_left) { top_left + @math.Vec2D(RABBIT_RADIUS, RABBIT_RADIUS) },
        )
        let before_velocity = @physics2d.rigid_body_linear_velocity(entity).unwrap_or(
          @math.Vec2D::zero(),
        )
        let state_summary = match find_rabbit_index(entity) {
          Some(index) =>
            "idx=\{index} state=\{debug_bird_state_name(rabbits[index].state)} state_vel=\{debug_vec2_string(rabbits[index].velocity)}"
          None => "idx=missing"
        }
        println(
          "[angryrabbits][debug][update-before-sync] center=\{debug_vec2_string(before_center)} vel=\{debug_vec2_string(before_velocity)} \{state_summary}",
        )
      }
      None =>
        println(
          "[angryrabbits][debug][update-before-sync] tracked rabbit missing",
        )
    }
  }
  update_rabbit_motion(delta)
  sync_physics_snapshots()
  if debug_trace_update_frames_remaining.val > 0 {
    match debug_tracked_rabbit_entity.val {
      Some(entity) => {
        let after_center = @physics2d.rigid_body_translation(entity).map_or(
          @math.Vec2D::zero(),
          fn(top_left) { top_left + @math.Vec2D(RABBIT_RADIUS, RABBIT_RADIUS) },
        )
        let after_velocity = @physics2d.rigid_body_linear_velocity(entity).unwrap_or(
          @math.Vec2D::zero(),
        )
        let state_summary = match find_rabbit_index(entity) {
          Some(index) =>
            "idx=\{index} state=\{debug_bird_state_name(rabbits[index].state)} state_vel=\{debug_vec2_string(rabbits[index].velocity)}"
          None => "idx=missing"
        }
        println(
          "[angryrabbits][debug][update-after-sync] center=\{debug_vec2_string(after_center)} vel=\{debug_vec2_string(after_velocity)} \{state_summary}",
        )
      }
      None =>
        println(
          "[angryrabbits][debug][update-after-sync] tracked rabbit missing",
        )
    }
    debug_trace_update_frames_remaining.val = debug_trace_update_frames_remaining.val -
      1
  }
  apply_contact_damage_events()
  cleanup_out_of_bounds_bodies()
  update_thrown_rabbits(delta)
  update_camera(delta)

  if game_state.val == Playing && slingshot_state.val == BirdFlying {
    rabbit_flight_time.val = rabbit_flight_time.val + delta
    if current_rabbit_out_of_bounds() ||
      world_is_quiet() ||
      rabbit_flight_time.val >= SHOT_TIMEOUT {
      begin_next_shot_or_end()
    }
  }
}

///|
fn physics_debug_trace_system(_world : @ecs.World) -> Unit {
  guard debug_tracked_rabbit_entity.val is Some(entity) else { return }
  guard @physics2d.rigid_body_translation(entity) is Some(top_left) else {
    return
  }
  let center = top_left + @math.Vec2D(RABBIT_RADIUS, RABBIT_RADIUS)
  let velocity = @physics2d.rigid_body_linear_velocity(entity).unwrap_or(
    @math.Vec2D::zero(),
  )
  debug_physics_center.val = center
  debug_physics_velocity.val = velocity
  if debug_trace_fixed_frames_remaining.val > 0 {
    println(
      "[angryrabbits][debug][fixed] remain=\{debug_trace_fixed_frames_remaining.val} center=\{debug_vec2_string(center)} vel=\{debug_vec2_string(velocity)}",
    )
    debug_trace_fixed_frames_remaining.val = debug_trace_fixed_frames_remaining.val -
      1
  }
}

///|
fn render_sync_system(_world : @ecs.World) -> Unit {
  sync_dynamic_visuals()
  sync_ui()
}

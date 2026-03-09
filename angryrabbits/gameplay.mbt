///|
fn vec_length(vector : @math.Vec2D) -> Double {
  vector.distance()
}

///|
fn normalize_or_zero(vector : @math.Vec2D) -> @math.Vec2D {
  vector.normalize()
}

///|
fn scale_vec(vector : @math.Vec2D, scalar : Double) -> @math.Vec2D {
  vector.scalar_mul(scalar)
}

///|
fn clamp(value : Double, lower : Double, upper : Double) -> Double {
  if value < lower {
    lower
  } else if value > upper {
    upper
  } else {
    value
  }
}

///|
fn clamp_drag_target(mouse_center : @math.Vec2D) -> @math.Vec2D {
  let offset = mouse_center - slingshot_anchor()
  let length = vec_length(offset)
  if length <= MAX_DRAG_RADIUS {
    mouse_center
  } else {
    slingshot_anchor() + offset.scalar_div(length).scalar_mul(MAX_DRAG_RADIUS)
  }
}

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
fn circle_intersects_rect(
  center : @math.Vec2D,
  radius : Double,
  rect_center : @math.Vec2D,
  rect_size : @math.Vec2D,
) -> Bool {
  let nearest_x = clamp(
    center[X],
    rect_center[X] - rect_size[X] / 2.0,
    rect_center[X] + rect_size[X] / 2.0,
  )
  let nearest_y = clamp(
    center[Y],
    rect_center[Y] - rect_size[Y] / 2.0,
    rect_center[Y] + rect_size[Y] / 2.0,
  )
  let delta = center - @math.Vec2D(nearest_x, nearest_y)
  delta[X] * delta[X] + delta[Y] * delta[Y] <= radius * radius
}

///|
fn rabbit_ready_for_pickup() -> Bool {
  match phase.val {
    Ready => rabbit_visible.val && shots_remaining.val > 0
    _ => false
  }
}

///|
fn rabbit_contains(point : @math.Vec2D) -> Bool {
  circle_intersects_circle(rabbit_center.val, RABBIT_RADIUS, point, 8.0)
}

///|
fn all_targets_cleared() -> Bool {
  targets.all(fn(target) { !target.alive })
}

///|
fn begin_next_shot_or_end() -> Unit {
  rabbit_velocity.val = @math.Vec2D::zero()
  rabbit_flight_time.val = 0.0
  if all_targets_cleared() {
    phase.val = Won
    rabbit_visible.val = false
    return
  }
  if shots_remaining.val <= 0 {
    phase.val = Lost
    rabbit_visible.val = false
    return
  }
  phase.val = Ready
  rabbit_center.val = slingshot_anchor()
  rabbit_visible.val = true
}

///|
fn resolve_rabbit_ground_collision() -> Unit {
  let mut center = rabbit_center.val
  let mut velocity = rabbit_velocity.val
  let bottom = center[Y] + RABBIT_RADIUS
  if bottom < GROUND_Y {
    rabbit_center.val = center
    rabbit_velocity.val = velocity
    return
  }
  center = @math.Vec2D(center[X], GROUND_Y - RABBIT_RADIUS)
  velocity = @math.Vec2D(
    velocity[X] * GROUND_FRICTION,
    -velocity[Y] * RABBIT_RESTITUTION,
  )
  if vec_length(velocity) < STOP_SPEED {
    rabbit_center.val = center
    rabbit_velocity.val = @math.Vec2D::zero()
    begin_next_shot_or_end()
    return
  }
  rabbit_center.val = center
  rabbit_velocity.val = velocity
}

///|
fn integrate_block(index : Int, delta : Double) -> Unit {
  let block = blocks[index]
  if !block.alive {
    return
  }
  let mut velocity = @math.Vec2D(
    block.velocity[X] * AIR_DRAG,
    block.velocity[Y] + GRAVITY * delta,
  )
  let mut center = block.center + scale_vec(velocity, delta)
  let floor = GROUND_Y - block.size[Y] / 2.0
  if center[Y] > floor {
    center = @math.Vec2D(center[X], floor)
    velocity = @math.Vec2D(
      velocity[X] * GROUND_FRICTION,
      -velocity[Y] * BLOCK_RESTITUTION,
    )
    if vec_length(velocity) < STOP_SPEED * 0.4 {
      velocity = @math.Vec2D::zero()
    }
  }
  blocks[index] = { ..block, center, velocity }
}

///|
fn integrate_target(index : Int, delta : Double) -> Unit {
  let target = targets[index]
  if !target.alive {
    return
  }
  let mut velocity = @math.Vec2D(
    target.velocity[X] * AIR_DRAG,
    target.velocity[Y] + GRAVITY * delta,
  )
  let mut center = target.center + scale_vec(velocity, delta)
  let floor = GROUND_Y - target.radius
  if center[Y] > floor {
    center = @math.Vec2D(center[X], floor)
    velocity = @math.Vec2D(velocity[X] * 0.88, -velocity[Y] * 0.20)
    if vec_length(velocity) < STOP_SPEED * 0.35 {
      velocity = @math.Vec2D::zero()
    }
  }
  targets[index] = { ..target, center, velocity }
}

///|
fn apply_rabbit_block_collisions() -> Unit {
  for index in 0..<blocks.length() {
    let block = blocks[index]
    if !block.alive {
      continue
    }
    if !circle_intersects_rect(
        rabbit_center.val,
        RABBIT_RADIUS,
        block.center,
        block.size,
      ) {
      continue
    }
    let push = normalize_or_zero(block.center - rabbit_center.val)
    let rabbit_speed = vec_length(rabbit_velocity.val)
    let transfer = rabbit_speed * BLOCK_HIT_TRANSFER
    let next_block_velocity = block.velocity +
      scale_vec(push, transfer) +
      @math.Vec2D(0.0, -rabbit_speed * 0.10)
    blocks[index] = { ..block, velocity: next_block_velocity }
    rabbit_velocity.val = scale_vec(rabbit_velocity.val, -0.36) +
      scale_vec(push, -transfer * 0.18)
    rabbit_center.val = rabbit_center.val - scale_vec(push, 6.0)
  }
}

///|
fn crush_targets_with_blocks() -> Unit {
  for target_index in 0..<targets.length() {
    let target = targets[target_index]
    if !target.alive {
      continue
    }
    for block in blocks {
      if !block.alive {
        continue
      }
      if !circle_intersects_rect(
          target.center,
          target.radius,
          block.center,
          block.size,
        ) {
        continue
      }
      let impact = vec_length(block.velocity)
      if impact >= BLOCK_TARGET_CRUSH_SPEED {
        targets[target_index] = {
          ..target,
          alive: false,
          velocity: target.velocity +
          scale_vec(
            normalize_or_zero(target.center - block.center),
            impact * 0.15,
          ),
        }
      }
    }
  }
}

///|
fn apply_rabbit_target_collisions() -> Unit {
  let mut hit_any = false
  for index in 0..<targets.length() {
    let target = targets[index]
    if !target.alive {
      continue
    }
    if !circle_intersects_circle(
        rabbit_center.val,
        RABBIT_RADIUS,
        target.center,
        target.radius,
      ) {
      continue
    }
    let rabbit_speed = vec_length(rabbit_velocity.val)
    let push = normalize_or_zero(target.center - rabbit_center.val)
    let next_velocity = target.velocity + scale_vec(push, rabbit_speed * 0.72)
    targets[index] = {
      ..target,
      alive: rabbit_speed < TARGET_HIT_SPEED,
      velocity: next_velocity,
    }
    rabbit_velocity.val = scale_vec(rabbit_velocity.val, -0.42)
    hit_any = true
  }
  if hit_any && all_targets_cleared() {
    phase.val = Won
    rabbit_visible.val = false
  }
}

///|
fn input_system(_delta : Double) -> Unit {
  if @inputs.is_just_pressed(Escape) {
    request_exit()
    return
  }
  if (@inputs.is_just_pressed(KeyR) || @inputs.is_just_pressed(Enter)) &&
    (phase.val == Won || phase.val == Lost) {
    reset_level()
    return
  }

  let mouse_center = @inputs.mouse.pos
  if rabbit_ready_for_pickup() &&
    @inputs.just_pressed_mouse.left_button &&
    rabbit_contains(mouse_center) {
    phase.val = Dragging
  }

  if phase.val == Dragging {
    if @inputs.is_mouse_pressed(Left) {
      rabbit_center.val = clamp_drag_target(mouse_center)
    }
    if @inputs.just_release_mouse.left_button {
      phase.val = Flying
      rabbit_velocity.val = launch_velocity_from_rabbit(rabbit_center.val)
      rabbit_flight_time.val = 0.0
      shots_remaining.val = shots_remaining.val - 1
    }
  }
}

///|
fn simulation_system(delta : Double) -> Unit {
  if phase.val == Flying {
    rabbit_flight_time.val = rabbit_flight_time.val + delta
    rabbit_velocity.val = @math.Vec2D(
      rabbit_velocity.val[X] * AIR_DRAG,
      rabbit_velocity.val[Y] + GRAVITY * delta,
    )
    rabbit_center.val = rabbit_center.val +
      scale_vec(rabbit_velocity.val, delta)
    apply_rabbit_block_collisions()
    apply_rabbit_target_collisions()
    resolve_rabbit_ground_collision()
    if rabbit_center.val[X] < -120.0 ||
      rabbit_center.val[X] > VIEWPORT_WIDTH + 120.0 ||
      rabbit_center.val[Y] > VIEWPORT_HEIGHT + 120.0 {
      begin_next_shot_or_end()
    }
  }

  for index in 0..<blocks.length() {
    integrate_block(index, delta)
  }
  for index in 0..<targets.length() {
    integrate_target(index, delta)
  }
  crush_targets_with_blocks()

  if phase.val != Won && all_targets_cleared() {
    phase.val = Won
    rabbit_visible.val = false
  }
}

///|
fn render_sync_system(_delta : Double) -> Unit {
  sync_dynamic_visuals()
  sync_ui()
}

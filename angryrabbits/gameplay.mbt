///|
fn vec_length(vector : @math.Vec2D) -> Double {
  vector.distance()
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
  circle_rect_overlap_depth(center, radius, rect_center, rect_size) > 0.0
}

///|
fn circle_rect_overlap_depth(
  center : @math.Vec2D,
  radius : Double,
  rect_center : @math.Vec2D,
  rect_size : @math.Vec2D,
) -> Double {
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
  let separation = vec_length(delta)
  if separation >= radius {
    0.0
  } else {
    radius - separation
  }
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
  rabbit_idle_time.val = 0.0
  if all_targets_cleared() {
    phase.val = Won
    hide_rabbit_physics()
    return
  }
  if shots_remaining.val <= 0 {
    phase.val = Lost
    hide_rabbit_physics()
    return
  }
  phase.val = Ready
  set_rabbit_ready_state(slingshot_anchor())
}

///|
fn destroy_target(index : Int) -> Unit {
  let target = targets[index]
  if !target.alive {
    return
  }
  targets[index] = { ..target, alive: false, overlap_time: 0.0 }
  destroy_target_body(target.entity)
}

///|
fn destroy_block(index : Int) -> Unit {
  let block = blocks[index]
  if !block.alive {
    return
  }
  blocks[index] = { ..block, alive: false, velocity: @math.Vec2D::zero() }
  clear_physics_entity(block.entity)
}

///|
fn rabbit_out_of_bounds() -> Bool {
  rabbit_center.val[X] < -120.0 ||
  rabbit_center.val[X] > VIEWPORT_WIDTH + 120.0 ||
  rabbit_center.val[Y] > VIEWPORT_HEIGHT + 120.0
}

///|
fn rabbit_has_settled() -> Bool {
  rabbit_flight_time.val >= RABBIT_SETTLE_TIME &&
  rabbit_idle_time.val >= RABBIT_IDLE_TIME
}

///|
fn crush_targets_with_blocks(delta : Double) -> Unit {
  for target_index in 0..<targets.length() {
    let target = targets[target_index]
    if !target.alive {
      continue
    }
    let mut is_overlapping = false
    let mut max_overlap_depth = 0.0
    let mut fastest_impact_speed = 0.0
    for block in blocks {
      if !block.alive {
        continue
      }
      let overlap_depth = circle_rect_overlap_depth(
        target.center,
        target.radius,
        block.center,
        block.size,
      )
      if overlap_depth <= 0.0 {
        continue
      }
      is_overlapping = true
      if overlap_depth > max_overlap_depth {
        max_overlap_depth = overlap_depth
      }
      let impact_speed = vec_length(block.velocity - target.velocity)
      if impact_speed > fastest_impact_speed {
        fastest_impact_speed = impact_speed
      }
    }
    if !targets[target_index].alive {
      continue
    }
    if is_overlapping {
      let overlap_time = target.overlap_time + delta
      if fastest_impact_speed >= BLOCK_TARGET_CRUSH_SPEED ||
        (
          max_overlap_depth >= TARGET_OVERLAP_CRUSH_DEPTH &&
          overlap_time >= TARGET_OVERLAP_CRUSH_TIME
        ) {
        destroy_target(target_index)
      } else {
        targets[target_index] = { ..target, overlap_time, }
      }
    } else if target.overlap_time > 0.0 {
      targets[target_index] = { ..target, overlap_time: 0.0 }
    }
  }
}

///|
fn apply_rabbit_block_hits() -> Unit {
  let rabbit_speed = vec_length(rabbit_velocity.val)
  if rabbit_speed < BLOCK_BREAK_SPEED {
    return
  }
  for index in 0..<blocks.length() {
    let block = blocks[index]
    if !block.alive {
      continue
    }
    if circle_intersects_rect(
        rabbit_center.val,
        RABBIT_RADIUS,
        block.center,
        block.size,
      ) {
      destroy_block(index)
    }
  }
}

///|
fn apply_rabbit_target_hits() -> Unit {
  for index in 0..<targets.length() {
    let target = targets[index]
    if !target.alive {
      continue
    }
    if circle_intersects_circle(
        rabbit_center.val,
        RABBIT_RADIUS,
        target.center,
        target.radius,
      ) {
      destroy_target(index)
    }
  }
}

///|
fn input_system(_world : @ecs.World) -> Unit {
  if @inputs.is_just_pressed(Escape) {
    request_exit()
    return
  }
  if (@inputs.is_just_pressed(KeyR) || @inputs.is_just_pressed(Enter)) &&
    (phase.val == Error || phase.val == Won || phase.val == Lost) {
    reset_level()
    return
  }

  let camera_pos = @camera.get_position()
  let mouse_center = @system.screen_to_world(@inputs.mouse.pos, camera_pos)
  if rabbit_ready_for_pickup() &&
    @inputs.just_pressed_mouse.left_button &&
    rabbit_contains(mouse_center) {
    phase.val = Dragging
  }

  if phase.val == Dragging {
    if @inputs.is_mouse_pressed(Left) {
      let center = clamp_drag_target(mouse_center)
      set_rabbit_ready_state(center)
    }
    if @inputs.just_release_mouse.left_button {
      let release_center = rabbit_center.val
      if drag_distance(release_center) < MIN_LAUNCH_STRETCH {
        phase.val = Ready
        set_rabbit_ready_state(slingshot_anchor())
      } else {
        phase.val = Flying
        launch_rabbit(
          release_center,
          launch_velocity_from_rabbit(release_center),
        )
        rabbit_flight_time.val = 0.0
        rabbit_idle_time.val = 0.0
        shots_remaining.val = shots_remaining.val - 1
      }
    }
  }
}

///|
fn simulation_system(_world : @ecs.World) -> Unit {
  if phase.val == Error {
    return
  }
  let delta = @time.delta()
  sync_physics_snapshots()
  if phase.val == Flying {
    rabbit_flight_time.val = rabbit_flight_time.val + delta
    if vec_length(rabbit_velocity.val) < STOP_SPEED {
      rabbit_idle_time.val = rabbit_idle_time.val + delta
    } else {
      rabbit_idle_time.val = 0.0
    }
    apply_rabbit_block_hits()
    apply_rabbit_target_hits()
    crush_targets_with_blocks(delta)
    if rabbit_out_of_bounds() || rabbit_has_settled() {
      begin_next_shot_or_end()
    }
  } else {
    crush_targets_with_blocks(delta)
  }

  if phase.val != Won && all_targets_cleared() {
    phase.val = Won
    hide_rabbit_physics()
  }
}

///|
fn render_sync_system(_world : @ecs.World) -> Unit {
  sync_dynamic_visuals()
  sync_ui()
}

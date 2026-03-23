///|
fn request_restart() -> Unit {
  reset_level()
}

///|
fn request_start() -> Unit {
  if phase.val == Start {
    phase.val = Playing
  }
}

///|
fn request_exit() -> Unit {
  @system.exit()
}

///|
fn handle_global_input() -> Unit {
  if @inputs.is_just_pressed(Escape) {
    request_exit()
  }
  if @inputs.is_just_pressed(KeyR) {
    request_restart()
  }
}

///|
fn handle_phase_input() -> Unit {
  match phase.val {
    Start => if @inputs.is_just_pressed(Enter) { request_start() }
    Won | Lost => if @inputs.is_just_pressed(Enter) { request_restart() }
    Playing => ()
  }
}

///|
fn record_direction_press(direction : Direction) -> Unit {
  input_press_sequence.val += 1
  let stamp = input_press_sequence.val
  match direction {
    Up => up_press_stamp.val = stamp
    Down => down_press_stamp.val = stamp
    Left => left_press_stamp.val = stamp
    Right => right_press_stamp.val = stamp
  }
}

///|
fn direction_press_stamp(direction : Direction) -> Int {
  match direction {
    Up => up_press_stamp.val
    Down => down_press_stamp.val
    Left => left_press_stamp.val
    Right => right_press_stamp.val
  }
}

///|
fn is_direction_pressed(direction : Direction) -> Bool {
  match direction {
    Up => @inputs.is_pressed(KeyW) || @inputs.is_pressed(ArrowUp)
    Down => @inputs.is_pressed(KeyS) || @inputs.is_pressed(ArrowDown)
    Left => @inputs.is_pressed(KeyA) || @inputs.is_pressed(ArrowLeft)
    Right => @inputs.is_pressed(KeyD) || @inputs.is_pressed(ArrowRight)
  }
}

///|
fn refresh_direction_press_stamps() -> Unit {
  if @inputs.is_just_pressed(KeyW) || @inputs.is_just_pressed(ArrowUp) {
    record_direction_press(Up)
  }
  if @inputs.is_just_pressed(KeyS) || @inputs.is_just_pressed(ArrowDown) {
    record_direction_press(Down)
  }
  if @inputs.is_just_pressed(KeyA) || @inputs.is_just_pressed(ArrowLeft) {
    record_direction_press(Left)
  }
  if @inputs.is_just_pressed(KeyD) || @inputs.is_just_pressed(ArrowRight) {
    record_direction_press(Right)
  }
}

///|
fn latest_held_direction() -> Direction? {
  let mut best_direction : Direction? = None
  let mut best_stamp = -1
  for direction in [Up, Down, Left, Right] {
    if is_direction_pressed(direction) {
      let stamp = direction_press_stamp(direction)
      if stamp > best_stamp || best_direction is None {
        best_direction = Some(direction)
        best_stamp = stamp
      }
    }
  }
  best_direction
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  refresh_direction_press_stamps()
  handle_global_input()
  handle_phase_input()
  if phase.val != Playing || !player.val.alive {
    return
  }
  player.val = { ..player.val, desired_direction: latest_held_direction() }
  if @inputs.is_just_pressed(Space) {
    place_bomb()
  }
}

///|
fn circle_overlaps_rect(
  center : @math.Vec2D,
  radius : Double,
  rect : Rect,
) -> Bool {
  let closest_x = clamp_double(center[X], rect.left, rect.right)
  let closest_y = clamp_double(center[Y], rect.top, rect.bottom)
  let dx = center[X] - closest_x
  let dy = center[Y] - closest_y
  dx * dx + dy * dy <= radius * radius
}

///|
fn circle_overlaps_circle(
  a_center : @math.Vec2D,
  a_radius : Double,
  b_center : @math.Vec2D,
  b_radius : Double,
) -> Bool {
  let dx = a_center[X] - b_center[X]
  let dy = a_center[Y] - b_center[Y]
  let radius_sum = a_radius + b_radius
  dx * dx + dy * dy <= radius_sum * radius_sum
}

///|
fn solid_tile_rects_near(
  center : @math.Vec2D,
  radius : Double,
  padding : Double,
) -> Array[Rect] {
  let extent = radius + padding
  let min_x = clamp_int(
    @cmath.floor((center[X] - extent - GRID_OFFSET_X) / CELL_SIZE).to_int() - 1,
    0,
    GRID_WIDTH - 1,
  )
  let max_x = clamp_int(
    @cmath.floor((center[X] + extent - GRID_OFFSET_X) / CELL_SIZE).to_int() + 1,
    0,
    GRID_WIDTH - 1,
  )
  let min_y = clamp_int(
    @cmath.floor((center[Y] - extent - GRID_OFFSET_Y) / CELL_SIZE).to_int() - 1,
    0,
    GRID_HEIGHT - 1,
  )
  let max_y = clamp_int(
    @cmath.floor((center[Y] + extent - GRID_OFFSET_Y) / CELL_SIZE).to_int() + 1,
    0,
    GRID_HEIGHT - 1,
  )
  let rects : Array[Rect] = []
  for y in min_y..<=max_y {
    for x in min_x..<=max_x {
      if tile_is_solid(x, y) {
        rects.push(cell_bounds(x, y))
      }
    }
  }
  rects
}

///|
fn solid_bomb_centers_for_player() -> Array[@math.Vec2D] {
  let centers : Array[@math.Vec2D] = []
  for bomb in bombs {
    if !bomb.passable_for_player {
      centers.push(cell_center(bomb.cell_x, bomb.cell_y))
    }
  }
  centers
}

///|
fn solid_bomb_centers_for_enemy() -> Array[@math.Vec2D] {
  let centers : Array[@math.Vec2D] = []
  for bomb in bombs {
    centers.push(cell_center(bomb.cell_x, bomb.cell_y))
  }
  centers
}

///|
fn resolve_circle_rects_on_x(
  x : Double,
  y : Double,
  radius : Double,
  delta_x : Double,
  rects : Array[Rect],
) -> Double {
  let mut resolved_x = x
  if delta_x == 0.0 {
    return resolved_x
  }
  for rect in rects {
    if circle_overlaps_rect(@math.Vec2D(resolved_x, y), radius, rect) {
      if delta_x > 0.0 {
        let candidate = rect.left - radius
        if resolved_x > candidate {
          resolved_x = candidate
        }
      } else {
        let candidate = rect.right + radius
        if resolved_x < candidate {
          resolved_x = candidate
        }
      }
    }
  }
  resolved_x
}

///|
fn resolve_circle_rects_on_y(
  x : Double,
  y : Double,
  radius : Double,
  delta_y : Double,
  rects : Array[Rect],
) -> Double {
  let mut resolved_y = y
  if delta_y == 0.0 {
    return resolved_y
  }
  for rect in rects {
    if circle_overlaps_rect(@math.Vec2D(x, resolved_y), radius, rect) {
      if delta_y > 0.0 {
        let candidate = rect.top - radius
        if resolved_y > candidate {
          resolved_y = candidate
        }
      } else {
        let candidate = rect.bottom + radius
        if resolved_y < candidate {
          resolved_y = candidate
        }
      }
    }
  }
  resolved_y
}

///|
fn resolve_circle_bombs_on_x(
  x : Double,
  y : Double,
  radius : Double,
  delta_x : Double,
  bomb_centers : Array[@math.Vec2D],
) -> Double {
  let mut resolved_x = x
  if delta_x == 0.0 {
    return resolved_x
  }
  let radius_sum = radius + BOMB_RADIUS
  for bomb_center in bomb_centers {
    let dy = y - bomb_center[Y]
    if abs_double(dy) >= radius_sum {
      continue
    }
    if circle_overlaps_circle(
        @math.Vec2D(resolved_x, y),
        radius,
        bomb_center,
        BOMB_RADIUS,
      ) {
      let span = @cmath.pow(radius_sum * radius_sum - dy * dy, 0.5)
      if delta_x > 0.0 {
        let candidate = bomb_center[X] - span
        if resolved_x > candidate {
          resolved_x = candidate
        }
      } else {
        let candidate = bomb_center[X] + span
        if resolved_x < candidate {
          resolved_x = candidate
        }
      }
    }
  }
  resolved_x
}

///|
fn resolve_circle_bombs_on_y(
  x : Double,
  y : Double,
  radius : Double,
  delta_y : Double,
  bomb_centers : Array[@math.Vec2D],
) -> Double {
  let mut resolved_y = y
  if delta_y == 0.0 {
    return resolved_y
  }
  let radius_sum = radius + BOMB_RADIUS
  for bomb_center in bomb_centers {
    let dx = x - bomb_center[X]
    if abs_double(dx) >= radius_sum {
      continue
    }
    if circle_overlaps_circle(
        @math.Vec2D(x, resolved_y),
        radius,
        bomb_center,
        BOMB_RADIUS,
      ) {
      let span = @cmath.pow(radius_sum * radius_sum - dx * dx, 0.5)
      if delta_y > 0.0 {
        let candidate = bomb_center[Y] - span
        if resolved_y > candidate {
          resolved_y = candidate
        }
      } else {
        let candidate = bomb_center[Y] + span
        if resolved_y < candidate {
          resolved_y = candidate
        }
      }
    }
  }
  resolved_y
}

///|
fn move_circle_with_colliders(
  center : @math.Vec2D,
  radius : Double,
  direction : Direction,
  distance : Double,
  bomb_centers : Array[@math.Vec2D],
) -> @math.Vec2D {
  let direction_vec = direction_vector(direction)
  let delta_x = direction_vec[X] * distance
  let delta_y = direction_vec[Y] * distance
  let tile_rects = solid_tile_rects_near(center, radius, distance)
  let x = resolve_circle_bombs_on_x(
    resolve_circle_rects_on_x(
      center[X] + delta_x,
      center[Y],
      radius,
      delta_x,
      tile_rects,
    ),
    center[Y],
    radius,
    delta_x,
    bomb_centers,
  )
  let moved_x = @math.Vec2D(x, center[Y])
  let y = resolve_circle_bombs_on_y(
    moved_x[X],
    resolve_circle_rects_on_y(
      moved_x[X],
      moved_x[Y] + delta_y,
      radius,
      delta_y,
      tile_rects,
    ),
    radius,
    delta_y,
    bomb_centers,
  )
  @math.Vec2D(moved_x[X], y)
}

///|
fn distance_moved_in_direction(
  start : @math.Vec2D,
  end_ : @math.Vec2D,
  direction : Direction,
) -> Double {
  match direction {
    Left | Right => abs_double(end_[X] - start[X])
    Up | Down => abs_double(end_[Y] - start[Y])
  }
}

///|
fn snap_center_for_direction(
  center : @math.Vec2D,
  direction : Direction,
) -> @math.Vec2D {
  match direction {
    Up | Down => @math.Vec2D(nearest_lane_center_x(center[X]), center[Y])
    Left | Right => @math.Vec2D(center[X], nearest_lane_center_y(center[Y]))
  }
}

///|
fn within_turn_assist(center : @math.Vec2D, direction : Direction) -> Bool {
  match direction {
    Up | Down =>
      abs_double(center[X] - nearest_lane_center_x(center[X])) <= TURN_ASSIST_PX
    Left | Right =>
      abs_double(center[Y] - nearest_lane_center_y(center[Y])) <= TURN_ASSIST_PX
  }
}

///|
fn move_player_in_direction(
  center : @math.Vec2D,
  direction : Direction,
  distance : Double,
) -> @math.Vec2D {
  move_circle_with_colliders(
    center,
    player.val.radius,
    direction,
    distance,
    solid_bomb_centers_for_player(),
  )
}

///|
fn move_enemy_in_direction(
  center : @math.Vec2D,
  radius : Double,
  direction : Direction,
  distance : Double,
) -> @math.Vec2D {
  move_circle_with_colliders(
    center,
    radius,
    direction,
    distance,
    solid_bomb_centers_for_enemy(),
  )
}

///|
fn update_player_bomb_passability() -> Unit {
  for bomb in bombs {
    if bomb.passable_for_player {
      let overlaps = circle_overlaps_circle(
        player.val.center,
        player.val.radius,
        cell_center(bomb.cell_x, bomb.cell_y),
        BOMB_RADIUS,
      )
      if !overlaps {
        bomb.passable_for_player = false
      }
    }
  }
}

///|
fn tick_player_motion(delta : Double) -> Unit {
  if !player.val.alive {
    return
  }
  match player.val.desired_direction {
    None => {
      player.val = { ..player.val, direction: None }
      update_player_bomb_passability()
    }
    Some(desired_direction) => {
      let move_distance = player.val.speed * delta
      let start_center = player.val.center
      let mut next_center = start_center
      let mut next_direction : Direction? = None
      let mut moved = false
      let needs_turn_snap = match player.val.direction {
        Some(current_direction) =>
          are_perpendicular(current_direction, desired_direction)
        None => true
      }
      let can_attempt_desired = match player.val.direction {
        Some(current_direction) =>
          if are_perpendicular(current_direction, desired_direction) {
            within_turn_assist(start_center, desired_direction)
          } else {
            true
          }
        None => within_turn_assist(start_center, desired_direction)
      }
      if can_attempt_desired {
        let desired_start = if needs_turn_snap {
          snap_center_for_direction(start_center, desired_direction)
        } else {
          start_center
        }
        let desired_center = move_player_in_direction(
          desired_start, desired_direction, move_distance,
        )
        if distance_moved_in_direction(
            desired_start, desired_center, desired_direction,
          ) >
          COLLISION_EPSILON {
          next_center = desired_center
          next_direction = Some(desired_direction)
          moved = true
        }
      }
      if !moved {
        match player.val.direction {
          Some(current_direction) if current_direction != desired_direction => {
            let current_center = move_player_in_direction(
              start_center, current_direction, move_distance,
            )
            if distance_moved_in_direction(
                start_center, current_center, current_direction,
              ) >
              COLLISION_EPSILON {
              next_center = current_center
              next_direction = Some(current_direction)
              moved = true
            }
          }
          _ => ()
        }
      }
      player.val = {
        ..player.val,
        center: next_center,
        direction: next_direction,
      }
      update_player_bomb_passability()
    }
  }
}

///|
fn tick_bombs(delta : Double) -> Unit {
  for bomb in bombs {
    bomb.timer = bomb.timer - delta
  }
}

///|
fn resolve_bomb_explosions() -> Unit {
  let mut searching = true
  while searching {
    let pending = bombs.search_by(fn(bomb) { bomb.timer <= 0.0 })
    match pending {
      Some(index) => explode_bomb_at(index)
      None => searching = false
    }
  }
}

///|
fn tick_flames(delta : Double) -> Unit {
  let mut index = flames.length()
  while index > 0 {
    index -= 1
    let flame = flames[index]
    let next_timer = flame.timer - delta
    if next_timer > 0.0 {
      flame.timer = next_timer
    } else {
      hide_entity(flame.entity)
      ignore(flames.remove(index))
    }
  }
}

///|
fn enemy_at_junction(center : @math.Vec2D, step : Double) -> Bool {
  abs_double(center[X] - nearest_lane_center_x(center[X])) <=
  step + COLLISION_EPSILON &&
  abs_double(center[Y] - nearest_lane_center_y(center[Y])) <=
  step + COLLISION_EPSILON
}

///|
fn choose_enemy_direction(enemy : EnemyState) -> Direction {
  let priorities = [
    enemy.direction,
    turn_left(enemy.direction),
    turn_right(enemy.direction),
    opposite_direction(enemy.direction),
  ]
  for direction in priorities {
    if enemy_can_enter_cell(enemy.cell_x, enemy.cell_y, direction) {
      return direction
    }
  }
  enemy.direction
}

///|
fn tick_enemies(delta : Double) -> Unit {
  for enemy in enemies {
    if !enemy.alive {
      continue
    }
    let move_distance = enemy.speed * delta
    let mut center = enemy.center
    let (cell_x, cell_y) = world_to_cell(center)
    enemy.cell_x = cell_x
    enemy.cell_y = cell_y
    if enemy_at_junction(center, move_distance) {
      center = cell_center(cell_x, cell_y)
      enemy.center = center
      enemy.desired_direction = choose_enemy_direction(enemy)
      enemy.direction = enemy.desired_direction
    }
    let next_center = move_enemy_in_direction(
      enemy.center,
      enemy.radius,
      enemy.direction,
      move_distance,
    )
    if distance_moved_in_direction(enemy.center, next_center, enemy.direction) <=
      COLLISION_EPSILON {
      enemy.desired_direction = choose_enemy_direction(enemy)
      enemy.direction = enemy.desired_direction
      enemy.center = move_enemy_in_direction(
        enemy.center,
        enemy.radius,
        enemy.direction,
        move_distance,
      )
    } else {
      enemy.center = next_center
    }
    let (next_cell_x, next_cell_y) = world_to_cell(enemy.center)
    enemy.cell_x = next_cell_x
    enemy.cell_y = next_cell_y
  }
}

///|
fn flame_contains_center(center : @math.Vec2D) -> Bool {
  let (cell_x, cell_y) = world_to_cell(center)
  flames.any(fn(flame) { flame.cell_x == cell_x && flame.cell_y == cell_y })
}

///|
fn resolve_flame_hits() -> Unit {
  if player.val.alive && flame_contains_center(player.val.center) {
    player.val = {
      ..player.val,
      alive: false,
      direction: None,
      desired_direction: None,
    }
  }
  for enemy in enemies {
    if enemy.alive && flame_contains_center(enemy.center) {
      enemy.alive = false
      hide_entity(enemy.entity)
    }
  }
}

///|
fn resolve_enemy_contact() -> Unit {
  if !player.val.alive {
    return
  }
  for enemy in enemies {
    if enemy.alive &&
      circle_overlaps_circle(
        player.val.center,
        player.val.radius,
        enemy.center,
        enemy.radius,
      ) {
      player.val = {
        ..player.val,
        alive: false,
        direction: None,
        desired_direction: None,
      }
      break
    }
  }
}

///|
fn resolve_phase() -> Unit {
  if phase.val != Playing {
    return
  }
  if !player.val.alive {
    phase.val = Lost
    return
  }
  if active_enemy_count() == 0 {
    phase.val = Won
  }
}

///|
pub fn simulation_system(_world : @ecs.World) -> Unit {
  let delta = @time.delta()
  if phase.val != Playing {
    return
  }
  tick_player_motion(delta)
  tick_bombs(delta)
  resolve_bomb_explosions()
  tick_flames(delta)
  tick_enemies(delta)
  resolve_flame_hits()
  resolve_enemy_contact()
  resolve_phase()
}

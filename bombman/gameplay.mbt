///|
fn request_exit() -> Unit {
  exit_request_count.val += 1
  if !suppress_exit_for_tests.val {
    @system.exit()
  }
}

///|
fn request_restart_round() -> Unit {
  if phase.val != MainMenu {
    start_round(current_mode.val)
  }
}

///|
fn continue_after_round_over() -> Unit {
  if phase.val != RoundOver {
    return
  }
  match current_mode.val {
    Versus => start_round(Versus)
    SinglePlayer | Coop =>
      match round_outcome.val {
        LevelClear => {
          current_level.val = (current_level.val + 1) % levels.length()
          start_round(current_mode.val)
        }
        Defeat | P1Win | P2Win | Draw => start_round(current_mode.val)
      }
  }
}

///|
fn activate_menu_option(option : MenuOption) -> Unit {
  menu_selection.val = option
  match option {
    Exit => request_exit()
    OnePlayer => start_round(SinglePlayer)
    TwoPlayersA => start_round(Coop)
    TwoPlayersB => start_round(Versus)
  }
}

///|
fn set_round_over(outcome : RoundOutcome) -> Unit {
  round_outcome.val = outcome
  phase.val = RoundOver
}

///|
fn handle_global_input() -> Unit {
  if @inputs.is_just_pressed(KeyR) {
    request_restart_round()
  }
  if @inputs.is_just_pressed(Escape) {
    match phase.val {
      MainMenu => request_exit()
      Playing | RoundOver => return_to_menu()
    }
  }
}

///|
fn handle_menu_input() -> Unit {
  if phase.val != MainMenu {
    return
  }
  if @inputs.is_just_pressed(KeyW) || @inputs.is_just_pressed(ArrowUp) {
    menu_selection.val = previous_menu_option(menu_selection.val)
  }
  if @inputs.is_just_pressed(KeyS) || @inputs.is_just_pressed(ArrowDown) {
    menu_selection.val = next_menu_option(menu_selection.val)
  }
  if @inputs.is_just_pressed(KeyA) || @inputs.is_just_pressed(ArrowLeft) {
    current_level.val = previous_level_index(current_level.val)
  }
  if @inputs.is_just_pressed(KeyD) || @inputs.is_just_pressed(ArrowRight) {
    current_level.val = next_level_index(current_level.val)
  }
  if @inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space) {
    activate_menu_option(menu_selection.val)
  }
}

///|
fn handle_round_over_input() -> Unit {
  if phase.val == RoundOver &&
    (@inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space)) {
    continue_after_round_over()
  }
}

///|
fn input_mapping_pressed(player_id : PlayerId, direction : Direction) -> Bool {
  match current_mode.val {
    SinglePlayer =>
      match direction {
        Up => @inputs.is_pressed(KeyW) || @inputs.is_pressed(ArrowUp)
        Down => @inputs.is_pressed(KeyS) || @inputs.is_pressed(ArrowDown)
        Left => @inputs.is_pressed(KeyA) || @inputs.is_pressed(ArrowLeft)
        Right => @inputs.is_pressed(KeyD) || @inputs.is_pressed(ArrowRight)
      }
    Coop | Versus =>
      match player_id {
        P1 =>
          match direction {
            Up => @inputs.is_pressed(KeyW)
            Down => @inputs.is_pressed(KeyS)
            Left => @inputs.is_pressed(KeyA)
            Right => @inputs.is_pressed(KeyD)
          }
        P2 =>
          match direction {
            Up => @inputs.is_pressed(KeyI)
            Down => @inputs.is_pressed(KeyK)
            Left => @inputs.is_pressed(KeyJ)
            Right => @inputs.is_pressed(KeyL)
          }
      }
  }
}

///|
fn record_direction_press(player_id : PlayerId, direction : Direction) -> Unit {
  let state = direction_input_state[player_index(player_id)]
  state.sequence += 1
  let stamp = state.sequence
  match direction {
    Up => state.up = stamp
    Down => state.down = stamp
    Left => state.left = stamp
    Right => state.right = stamp
  }
}

///|
fn direction_press_stamp(player_id : PlayerId, direction : Direction) -> Int {
  let state = direction_input_state[player_index(player_id)]
  match direction {
    Up => state.up
    Down => state.down
    Left => state.left
    Right => state.right
  }
}

///|
fn refresh_direction_press_stamps() -> Unit {
  let single = current_mode.val == SinglePlayer
  if @inputs.is_just_pressed(KeyW) ||
    (single && @inputs.is_just_pressed(ArrowUp)) {
    record_direction_press(P1, Up)
  }
  if @inputs.is_just_pressed(KeyS) ||
    (single && @inputs.is_just_pressed(ArrowDown)) {
    record_direction_press(P1, Down)
  }
  if @inputs.is_just_pressed(KeyA) ||
    (single && @inputs.is_just_pressed(ArrowLeft)) {
    record_direction_press(P1, Left)
  }
  if @inputs.is_just_pressed(KeyD) ||
    (single && @inputs.is_just_pressed(ArrowRight)) {
    record_direction_press(P1, Right)
  }
  if current_mode.val != SinglePlayer {
    if @inputs.is_just_pressed(KeyI) {
      record_direction_press(P2, Up)
    }
    if @inputs.is_just_pressed(KeyK) {
      record_direction_press(P2, Down)
    }
    if @inputs.is_just_pressed(KeyJ) {
      record_direction_press(P2, Left)
    }
    if @inputs.is_just_pressed(KeyL) {
      record_direction_press(P2, Right)
    }
  }
}

///|
fn latest_held_direction(player_id : PlayerId) -> Direction? {
  let mut best_direction : Direction? = None
  let mut best_stamp = -1
  for direction in [Up, Down, Left, Right] {
    if input_mapping_pressed(player_id, direction) {
      let stamp = direction_press_stamp(player_id, direction)
      if stamp > best_stamp || best_direction is None {
        best_direction = Some(direction)
        best_stamp = stamp
      }
    }
  }
  best_direction
}

///|
fn p2_bomb_just_pressed() -> Bool {
  let pressed = @raylib.is_key_pressed(@raylib.KeyApostrophe) ||
    p2_bomb_test_override.val
  p2_bomb_test_override.val = false
  pressed
}

///|
fn handle_player_inputs() -> Unit {
  for player in players {
    if !player.active || !player.alive {
      player.desired_direction = None
      player.direction = None
      continue
    }
    player.desired_direction = latest_held_direction(player.id)
  }
  match current_mode.val {
    SinglePlayer =>
      if @inputs.is_just_pressed(Space) {
        place_bomb_for_player(0)
      }
    Coop | Versus => {
      if players[0].active && players[0].alive && @inputs.is_just_pressed(KeyG) {
        place_bomb_for_player(0)
      }
      if players[1].active && players[1].alive && p2_bomb_just_pressed() {
        place_bomb_for_player(1)
      }
    }
  }
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  handle_global_input()
  if phase.val == MainMenu {
    handle_menu_input()
    return
  }
  if phase.val == RoundOver {
    handle_round_over_input()
    return
  }
  refresh_direction_press_stamps()
  handle_player_inputs()
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
fn solid_bomb_centers_for_player(index : Int) -> Array[@math.Vec2D] {
  let player = players[index]
  let centers : Array[@math.Vec2D] = []
  for bomb in bombs {
    let solid = bomb.owner != player.id || !bomb.passable_for_owner
    if solid {
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
  player_index_ : Int,
  center : @math.Vec2D,
  direction : Direction,
  distance : Double,
) -> @math.Vec2D {
  move_circle_with_colliders(
    center,
    players[player_index_].radius,
    direction,
    distance,
    solid_bomb_centers_for_player(player_index_),
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
fn update_bomb_passability() -> Unit {
  for bomb in bombs {
    if bomb.passable_for_owner {
      let owner = players[player_index(bomb.owner)]
      if !owner.active ||
        !circle_overlaps_circle(
          owner.center,
          owner.radius,
          cell_center(bomb.cell_x, bomb.cell_y),
          BOMB_RADIUS,
        ) {
        bomb.passable_for_owner = false
      }
    }
  }
}

///|
fn apply_item_to_player(player : PlayerState, kind : ItemKind) -> Unit {
  match kind {
    Shoes =>
      player.speed = clamp_double(
        player.speed + CELL_SIZE,
        0.0,
        PLAYER_MAX_SPEED,
      )
    BombUp =>
      player.max_bombs = clamp_int(player.max_bombs + 1, 0, PLAYER_MAX_BOMBS)
    PowerUp =>
      player.blast_radius = clamp_int(
        player.blast_radius + 1,
        0,
        PLAYER_MAX_BLAST_RADIUS,
      )
  }
}

///|
fn resolve_item_pickups() -> Unit {
  let mut index = items.length()
  while index > 0 {
    index -= 1
    let item = items[index]
    let mut picked_up = false
    for player in players {
      if player.active && player.alive {
        let (cell_x, cell_y) = world_to_cell(player.center)
        if cell_x == item.cell_x && cell_y == item.cell_y {
          apply_item_to_player(player, item.kind)
          picked_up = true
          break
        }
      }
    }
    if picked_up {
      hide_entity(item.entity)
      ignore(items.remove(index))
    }
  }
}

///|
fn tick_player_motion(index : Int, delta : Double) -> Unit {
  let player = players[index]
  if !player.active || !player.alive {
    player.direction = None
    player.desired_direction = None
    return
  }
  match player.desired_direction {
    None => player.direction = None
    Some(desired_direction) => {
      let move_distance = player.speed * delta
      let start_center = player.center
      let mut next_center = start_center
      let mut next_direction : Direction? = None
      let mut moved = false
      let needs_turn_snap = match player.direction {
        Some(current_direction) =>
          are_perpendicular(current_direction, desired_direction)
        None => true
      }
      let can_attempt_desired = match player.direction {
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
          index, desired_start, desired_direction, move_distance,
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
        match player.direction {
          Some(current_direction) if current_direction != desired_direction => {
            let current_center = move_player_in_direction(
              index, start_center, current_direction, move_distance,
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
          Some(current_direction) => {
            let current_center = move_player_in_direction(
              index, start_center, current_direction, move_distance,
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
          None => ()
        }
      }
      player.center = next_center
      player.direction = next_direction
    }
  }
}

///|
fn tick_players_motion(delta : Double) -> Unit {
  for index in 0..<players.length() {
    tick_player_motion(index, delta)
  }
  update_bomb_passability()
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
  for player in players {
    if player.active && player.alive && flame_contains_center(player.center) {
      player.alive = false
      player.direction = None
      player.desired_direction = None
    }
  }
  for enemy in enemies {
    if enemy.alive && flame_contains_center(enemy.center) {
      enemy.alive = false
      hide_entity(enemy.entity)
      let (cell_x, cell_y) = world_to_cell(enemy.center)
      maybe_spawn_random_item(cell_x, cell_y, ENEMY_ITEM_DROP_CHANCE)
    }
  }
}

///|
fn resolve_enemy_contact() -> Unit {
  if current_mode.val == Versus {
    return
  }
  for player in players {
    if !player.active || !player.alive {
      continue
    }
    for enemy in enemies {
      if enemy.alive &&
        circle_overlaps_circle(
          player.center,
          player.radius,
          enemy.center,
          enemy.radius,
        ) {
        player.alive = false
        player.direction = None
        player.desired_direction = None
        break
      }
    }
  }
}

///|
fn resolve_phase() -> Unit {
  if phase.val != Playing {
    return
  }
  match current_mode.val {
    Versus => {
      let p1_alive = players[0].active && players[0].alive
      let p2_alive = players[1].active && players[1].alive
      if p1_alive && !p2_alive {
        set_round_over(P1Win)
      } else if p2_alive && !p1_alive {
        set_round_over(P2Win)
      } else if !p1_alive && !p2_alive {
        set_round_over(Draw)
      }
    }
    SinglePlayer | Coop =>
      if active_enemy_count() == 0 && alive_player_count() > 0 {
        set_round_over(LevelClear)
      } else if alive_player_count() == 0 {
        set_round_over(Defeat)
      }
  }
}

///|
pub fn simulation_system(_world : @ecs.World) -> Unit {
  if phase.val != Playing {
    return
  }
  let delta = @time.delta()
  tick_players_motion(delta)
  resolve_item_pickups()
  tick_bombs(delta)
  resolve_bomb_explosions()
  tick_flames(delta)
  tick_enemies(delta)
  resolve_flame_hits()
  resolve_enemy_contact()
  resolve_phase()
}

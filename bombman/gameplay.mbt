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
const NET_ACTION_PLACE_BOMB : Int = 1

///|
fn direction_to_net_axes(direction : Direction?) -> (Int, Int) {
  match direction {
    Some(Up) => (0, -1)
    Some(Down) => (0, 1)
    Some(Left) => (-1, 0)
    Some(Right) => (1, 0)
    None => (0, 0)
  }
}

///|
fn direction_from_net_axes(axis_x : Int, axis_y : Int) -> Direction? {
  if axis_x < 0 {
    Some(Left)
  } else if axis_x > 0 {
    Some(Right)
  } else if axis_y < 0 {
    Some(Up)
  } else if axis_y > 0 {
    Some(Down)
  } else {
    None
  }
}

///|
fn netplay_loopback_input_bridge_enabled() -> Bool {
  phase.val == Playing &&
  current_mode.val != SinglePlayer &&
  netplay_mode.val == Loopback &&
  netplay_host_session.val is Some(_) &&
  netplay_client_session.val is Some(_)
}

///|
fn netplay_remote_input_bridge_enabled() -> Bool {
  phase.val == Playing &&
  current_mode.val != SinglePlayer &&
  (netplay_mode.val == Host || netplay_mode.val == Client) &&
  netplay_session.val is Some(_) &&
  netplay_link.val is Some(_)
}

///|
fn handle_player_inputs_local() -> Unit {
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
fn apply_remote_input_to_player(
  player_index_ : Int,
  input : @netplay.PlayerInput,
) -> Unit {
  let player = players[player_index_]
  if !player.active || !player.alive {
    return
  }
  player.desired_direction = direction_from_net_axes(input.axis_x, input.axis_y)
  if input.action_mask == NET_ACTION_PLACE_BOMB &&
    input.frame_id > netplay_last_remote_action_frame.val {
    place_bomb_for_player(player_index_)
    netplay_last_remote_action_frame.val = input.frame_id
  }
}

///|
fn local_loopback_p2_input() -> @netplay.PlayerInput {
  let (axis_x, axis_y) = direction_to_net_axes(latest_held_direction(P2))
  let action_mask = if players[1].active &&
    players[1].alive &&
    p2_bomb_just_pressed() {
    NET_ACTION_PLACE_BOMB
  } else {
    0
  }
  @netplay.PlayerInput::new(
    frame_id=netplay_local_frame.val,
    axis_x~,
    axis_y~,
    action_mask~,
  )
}

///|
fn handle_player_inputs_with_netplay_bridge() -> Unit {
  if players[0].active && players[0].alive {
    players[0].desired_direction = latest_held_direction(P1)
  } else {
    players[0].desired_direction = None
    players[0].direction = None
  }
  if players[1].active && players[1].alive {
    players[1].desired_direction = None
  } else {
    players[1].desired_direction = None
    players[1].direction = None
  }
  if current_mode.val == SinglePlayer {
    return
  }
  if players[0].active && players[0].alive && @inputs.is_just_pressed(KeyG) {
    place_bomb_for_player(0)
  }
  match netplay_host_session.val {
    Some(host0) =>
      match netplay_client_session.val {
        Some(client0) => {
          let mut host = host0
          let mut client = client0
          client = client.submit_local_input(local_loopback_p2_input())
          let (next_host, next_client) = netplay_loopback_exchange(host, client)
          host = next_host
          client = next_client
          let (host_after_events, _) = host.drain_events()
          let (client_after_events, _) = client.drain_events()
          let (host_after_inputs, remote_inputs) = host_after_events.drain_remote_inputs()
          if remote_inputs.is_empty() {
            if players[1].active && players[1].alive {
              players[1].desired_direction = None
            }
          } else {
            let mut latest = remote_inputs[0]
            for input in remote_inputs {
              latest = input
            }
            apply_remote_input_to_player(1, latest)
          }
          netplay_host_session.val = Some(host_after_inputs.tick())
          netplay_client_session.val = Some(client_after_events.tick())
          netplay_local_frame.val += 1
        }
        None => handle_player_inputs_local()
      }
    None => handle_player_inputs_local()
  }
}

///|
fn clear_player_input(index : Int) -> Unit {
  if players[index].active && players[index].alive {
    players[index].desired_direction = None
  } else {
    players[index].desired_direction = None
    players[index].direction = None
  }
}

///|
fn local_bomb_pressed_for_network(player_id : PlayerId) -> Bool {
  match player_id {
    P1 => @inputs.is_just_pressed(KeyG)
    P2 => p2_bomb_just_pressed()
  }
}

///|
fn make_network_input(
  frame_id : Int,
  player_id : PlayerId,
  bomb_pressed : Bool,
) -> @netplay.PlayerInput {
  let desired = latest_held_direction(player_id)
  let (axis_x, axis_y) = direction_to_net_axes(desired)
  let action_mask = if bomb_pressed { NET_ACTION_PLACE_BOMB } else { 0 }
  @netplay.PlayerInput::new(frame_id~, axis_x~, axis_y~, action_mask~)
}

///|
fn netplay_send_outgoing(
  session : @netplay.NetSession,
  link : @netplay.TcpLink,
) -> (@netplay.NetSession, @netplay.TcpLink) {
  if !link.is_connected() {
    return (session, link)
  }
  let (next_session, outgoing) = session.drain_outgoing()
  let mut session_after_send = next_session
  let mut next_link = link
  let mut keep_index = -1
  for index in 0..<outgoing.length() {
    let message = outgoing[index]
    let (updated, _) = next_link.send_line(@netplay.encode_message(message))
    if !updated.is_connected() {
      keep_index = index
      next_link = updated
      break
    }
    next_link = updated
  }
  if keep_index >= 0 {
    for index in keep_index..<outgoing.length() {
      session_after_send = session_after_send.enqueue_outgoing(outgoing[index])
    }
  }
  (session_after_send, next_link)
}

///|
fn netplay_poll_and_ingest(
  session : @netplay.NetSession,
  link : @netplay.TcpLink,
) -> (@netplay.NetSession, @netplay.TcpLink) {
  let mut next_session = session
  let (next_link, lines, _) = link.poll()
  for line in lines {
    match @netplay.decode_message(line) {
      Some(message) => next_session = next_session.ingest_remote(message)
      None => ()
    }
  }
  (next_session, next_link)
}

///|
fn update_remote_input_cache_from_session(
  session : @netplay.NetSession,
) -> @netplay.NetSession {
  let (after_events, events) = session.drain_events()
  if netplay_mode.val == Client {
    for event in events {
      match event {
        RoundStarted(seed, _, _) => apply_remote_round_seed(seed)
        _ => ()
      }
    }
  }
  let (after_inputs, remote_inputs) = after_events.drain_remote_inputs()
  if !remote_inputs.is_empty() {
    let mut latest = remote_inputs[0]
    for input in remote_inputs {
      latest = input
    }
    netplay_last_remote_input.val = Some(latest)
  }
  after_inputs
}

///|
fn handle_player_inputs_with_remote_netplay() -> Unit {
  let (local_player_index, local_player_id, remote_player_index) = match
    netplay_mode.val {
    Host => (0, P1, 1)
    Client => (1, P2, 0)
    Off | Loopback => {
      handle_player_inputs_local()
      return
    }
  }
  clear_player_input(local_player_index)
  clear_player_input(remote_player_index)

  match netplay_session.val {
    Some(session0) =>
      match netplay_link.val {
        Some(link0) => {
          let mut session = session0
          let mut link = link0

          let (after_send1, link_after_send1) = netplay_send_outgoing(
            session, link,
          )
          session = after_send1
          link = link_after_send1

          let (after_ingest, link_after_ingest) = netplay_poll_and_ingest(
            session, link,
          )
          session = after_ingest
          link = link_after_ingest

          let (after_send2, link_after_send2) = netplay_send_outgoing(
            session, link,
          )
          session = after_send2
          link = link_after_send2

          session = update_remote_input_cache_from_session(session)

          if session.is_running() {
            let local_bomb_pressed = local_bomb_pressed_for_network(
              local_player_id,
            )
            let local_input = make_network_input(
              session.current_frame(),
              local_player_id,
              local_bomb_pressed,
            )
            session = session.submit_local_input(local_input)
            if players[local_player_index].active &&
              players[local_player_index].alive {
              players[local_player_index].desired_direction = latest_held_direction(
                local_player_id,
              )
              if local_bomb_pressed {
                place_bomb_for_player(local_player_index)
              }
            }
            match netplay_last_remote_input.val {
              Some(remote_input) =>
                apply_remote_input_to_player(remote_player_index, remote_input)
              None => ()
            }
            session = session.tick()
          }
          let (after_send3, link_after_send3) = netplay_send_outgoing(
            session, link,
          )
          session = after_send3
          link = link_after_send3

          netplay_session.val = Some(session)
          netplay_link.val = Some(link)
        }
        None => handle_player_inputs_local()
      }
    None => handle_player_inputs_local()
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
  if netplay_loopback_input_bridge_enabled() {
    handle_player_inputs_with_netplay_bridge()
  } else if netplay_remote_input_bridge_enabled() {
    handle_player_inputs_with_remote_netplay()
  } else {
    handle_player_inputs_local()
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
  movement_tile_rects_cache.clear()
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
  for y in min_y..<=max_y {
    for x in min_x..<=max_x {
      if tile_is_solid(x, y) {
        movement_tile_rects_cache.push(cell_bounds(x, y))
      }
    }
  }
  movement_tile_rects_cache
}

///|
fn solid_bomb_centers_for_player(index : Int) -> Array[@math.Vec2D] {
  movement_player_bomb_centers[index]
}

///|
fn solid_bomb_centers_for_enemy() -> Array[@math.Vec2D] {
  movement_enemy_bomb_centers
}

///|
fn refresh_movement_collision_cache() -> Unit {
  movement_player_bomb_centers[0].clear()
  movement_player_bomb_centers[1].clear()
  movement_enemy_bomb_centers.clear()
  for bomb in bombs {
    let bomb_center = cell_center(bomb.cell_x, bomb.cell_y)
    movement_enemy_bomb_centers.push(bomb_center)
    for index in 0..<players.length() {
      let player = players[index]
      if bomb.owner != player.id || !bomb.passable_for_owner {
        movement_player_bomb_centers[index].push(bomb_center)
      }
    }
  }
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
      hide_entity(item.label_entity)
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
  refresh_movement_collision_cache()
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
  if netplay_mode.val == Host || netplay_mode.val == Client {
    match netplay_session.val {
      Some(session) => if !session.is_running() { return }
      None => return
    }
  }
  let sim_started_at = @time.elapsed_raw()
  let delta = if netplay_mode.val == Host || netplay_mode.val == Client {
    1.0 / FPS.to_double()
  } else {
    @time.delta()
  }
  let motion_started_at = @time.elapsed_raw()
  tick_players_motion(delta)
  profile_motion_total.val += @time.elapsed_raw() - motion_started_at
  let bombs_started_at = @time.elapsed_raw()
  resolve_item_pickups()
  tick_bombs(delta)
  resolve_bomb_explosions()
  profile_bombs_total.val += @time.elapsed_raw() - bombs_started_at
  refresh_movement_collision_cache()
  let flames_started_at = @time.elapsed_raw()
  tick_flames(delta)
  profile_flames_total.val += @time.elapsed_raw() - flames_started_at
  let enemies_started_at = @time.elapsed_raw()
  tick_enemies(delta)
  profile_enemies_total.val += @time.elapsed_raw() - enemies_started_at
  let hits_started_at = @time.elapsed_raw()
  resolve_flame_hits()
  resolve_enemy_contact()
  profile_hits_total.val += @time.elapsed_raw() - hits_started_at
  let phase_started_at = @time.elapsed_raw()
  resolve_phase()
  profile_phase_total.val += @time.elapsed_raw() - phase_started_at
  profile_sim_total.val += @time.elapsed_raw() - sim_started_at
}

///|
fn emit_profile_report_if_needed(now : Double) -> Unit {
  if !profile_enabled.val || now - profile_last_report_at.val < 1.0 {
    return
  }
  let window_seconds = now - profile_last_report_at.val
  let frames = if profile_frame_count.val <= 0 {
    1
  } else {
    profile_frame_count.val
  }
  let frames_f = frames.to_double()
  let sim_avg_ms = profile_sim_total.val * 1000.0 / frames_f
  let render_avg_ms = profile_render_total.val * 1000.0 / frames_f
  let fps_avg = if window_seconds <= 0.0 {
    0.0
  } else {
    frames_f / window_seconds
  }
  let fps_window = fps_avg
  let fps_from_frame_dt = if profile_frame_dt_total.val <= 0.0 {
    0.0
  } else {
    frames_f / profile_frame_dt_total.val
  }
  println(
    "[bombman][profile] t=\{now - profile_started_at.val} window=\{window_seconds} frames=\{profile_frame_count.val} fps_avg=\{fps_avg} fps_window=\{fps_window} fps=\{fps_avg} fps_frame_dt=\{fps_from_frame_dt} raylib_fps=\{@raylib.get_fps()} sim_avg_ms=\{sim_avg_ms} render_avg_ms=\{render_avg_ms}",
  )
  profile_last_report_at.val = now
  profile_frame_count.val = 0
  profile_sim_total.val = 0.0
  profile_render_total.val = 0.0
  profile_frame_dt_total.val = 0.0
  profile_motion_total.val = 0.0
  profile_bombs_total.val = 0.0
  profile_flames_total.val = 0.0
  profile_enemies_total.val = 0.0
  profile_hits_total.val = 0.0
  profile_phase_total.val = 0.0
}

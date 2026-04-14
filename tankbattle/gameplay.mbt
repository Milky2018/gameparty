///|
fn request_exit() -> Unit {
  @system.exit()
}

///|
fn request_restart_round() -> Unit {
  if phase.val != MainMenu {
    start_round()
  }
}

///|
fn profile_phase(label : String, started_at : Double) -> Unit {
  if profile_enabled.val {
    let elapsed = @time.elapsed() - started_at
    if label == "input" {
      profile_input_total.val += elapsed
    } else if label == "simulation" {
      profile_sim_total.val += elapsed
    } else if label == "render" {
      profile_render_total.val += elapsed
    }
  }
}

///|
const PROFILE_REPORT_SECONDS : Double = 0.75

///|
fn maybe_report_profile() -> Unit {
  if !profile_enabled.val {
    return
  }
  let now = @time.elapsed()
  if now - profile_last_report_at.val < PROFILE_REPORT_SECONDS {
    return
  }
  let window = now - profile_last_report_at.val
  if window <= 0.0 {
    return
  }
  let frame_count = if profile_frame_count.val <= 0 {
    1
  } else {
    profile_frame_count.val
  }
  let frame_count_f = frame_count.to_double()
  let fps = frame_count_f / window
  let min_fps = if profile_slowest_frame.val > 0.0 {
    1.0 / profile_slowest_frame.val
  } else {
    0.0
  }
  let input_ms = profile_input_total.val / frame_count_f * 1000.0
  let sim_ms = profile_sim_total.val / frame_count_f * 1000.0
  let render_ms = profile_render_total.val / frame_count_f * 1000.0
  let slowest_frame_ms = profile_slowest_frame.val * 1000.0
  let phase_text = match phase.val {
    MainMenu => "MainMenu"
    Playing => "Playing"
    RoundOver => "RoundOver"
  }
  println(
    "[tankbattle][profile] elapsed_total=\{now - profile_started_at.val}s window=\{window}s frames=\{profile_frame_count.val} fps_avg=\{fps} fps_min=\{min_fps} input_avg_ms=\{input_ms} sim_avg_ms=\{sim_ms} render_avg_ms=\{render_ms} slowest_frame_ms=\{slowest_frame_ms} level=\{current_level.val + 1} phase=\{phase_text}",
  )
  profile_last_report_at.val = now
  profile_frame_count.val = 0
  profile_input_total.val = 0.0
  profile_sim_total.val = 0.0
  profile_render_total.val = 0.0
  profile_slowest_frame.val = 0.0
}

///|
fn start_round() -> Unit {
  setup_level_from_config(level_at(current_level.val))
  reset_direction_stamps()
  setup_playing_phase()
}

///|
fn return_to_menu() -> Unit {
  reset_direction_stamps()
  setup_menu_phase()
}

///|
fn continue_after_round_over() -> Unit {
  if phase.val == RoundOver {
    start_round()
  }
}

///|
fn activate_menu_option(option : MenuOption) -> Unit {
  match option {
    Start => start_round()
    Exit => request_exit()
  }
}

///|
fn handle_global_input() -> Unit {
  if @raylib.is_key_pressed(@raylib.KeyF3) {
    debug_fps_enabled.val = !debug_fps_enabled.val
  }
  if @inputs.is_just_pressed(KeyR) && phase.val != MainMenu {
    request_restart_round()
  }
  if @inputs.is_just_pressed(Escape) {
    match phase.val {
      MainMenu => request_exit()
      Playing | RoundOver => return_to_menu()
    }
  }
  if phase.val == RoundOver &&
    (@inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space)) {
    continue_after_round_over()
  }
}

///|
fn handle_menu_input() -> Unit {
  if phase.val != MainMenu {
    return
  }
  if @inputs.is_just_pressed(KeyW) || @inputs.is_just_pressed(ArrowUp) {
    current_menu_option.val = previous_menu_option(current_menu_option.val)
  }
  if @inputs.is_just_pressed(KeyS) || @inputs.is_just_pressed(ArrowDown) {
    current_menu_option.val = next_menu_option(current_menu_option.val)
  }
  if @inputs.is_just_pressed(KeyA) || @inputs.is_just_pressed(ArrowLeft) {
    current_level.val = previous_level_index(current_level.val)
  }
  if @inputs.is_just_pressed(KeyD) || @inputs.is_just_pressed(ArrowRight) {
    current_level.val = next_level_index(current_level.val)
  }
  if @inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space) {
    activate_menu_option(current_menu_option.val)
  }
}

///|
fn movement_input_pressed(direction : Direction) -> Bool {
  match direction {
    Up => @inputs.is_pressed(KeyW) || @inputs.is_pressed(ArrowUp)
    Down => @inputs.is_pressed(KeyS) || @inputs.is_pressed(ArrowDown)
    Left => @inputs.is_pressed(KeyA) || @inputs.is_pressed(ArrowLeft)
    Right => @inputs.is_pressed(KeyD) || @inputs.is_pressed(ArrowRight)
  }
}

///|
fn record_direction_press(direction : Direction) -> Unit {
  key_stamp_counter.val += 1
  let stamp = key_stamp_counter.val
  match direction {
    Up => key_stamp_up.val = stamp
    Down => key_stamp_down.val = stamp
    Left => key_stamp_left.val = stamp
    Right => key_stamp_right.val = stamp
  }
}

///|
fn direction_press_stamp(direction : Direction) -> Int {
  match direction {
    Up => key_stamp_up.val
    Down => key_stamp_down.val
    Left => key_stamp_left.val
    Right => key_stamp_right.val
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
  let mut best : Direction? = None
  let mut best_stamp = -1
  if movement_input_pressed(Up) {
    let stamp = direction_press_stamp(Up)
    if best is None || stamp > best_stamp {
      best = Some(Up)
      best_stamp = stamp
    }
  }
  if movement_input_pressed(Down) {
    let stamp = direction_press_stamp(Down)
    if best is None || stamp > best_stamp {
      best = Some(Down)
      best_stamp = stamp
    }
  }
  if movement_input_pressed(Left) {
    let stamp = direction_press_stamp(Left)
    if best is None || stamp > best_stamp {
      best = Some(Left)
      best_stamp = stamp
    }
  }
  if movement_input_pressed(Right) {
    let stamp = direction_press_stamp(Right)
    if best is None || stamp > best_stamp {
      best = Some(Right)
      best_stamp = stamp
    }
  }
  best
}

///|
fn mouse_turret_direction(
  center : @math.Vec2,
  fallback : Direction,
) -> Direction {
  let mouse = @inputs.mouse.pos
  let dx = mouse[X] - center[X]
  let dy = mouse[Y] - center[Y]
  if abs_double(dx) < 0.0001 && abs_double(dy) < 0.0001 {
    fallback
  } else if abs_double(dx) >= abs_double(dy) {
    if dx >= 0.0 {
      Right
    } else {
      Left
    }
  } else if dy >= 0.0 {
    Down
  } else {
    Up
  }
}

///|
fn active_enemy_count() -> Int {
  let mut count = 0
  for enemy in enemies {
    if enemy.alive {
      count += 1
    }
  }
  count
}

///|
fn solid_tile_rects_near(
  center : @math.Vec2,
  radius : Double,
  padding : Double,
) -> Array[Rect] {
  let min_x = ((center[X] - radius - padding - ARENA_ORIGIN_X) / TILE_SIZE)
    .floor()
    .to_int() -
    1
  let max_x = ((center[X] + radius + padding - ARENA_ORIGIN_X) / TILE_SIZE)
    .floor()
    .to_int() +
    1
  let min_y = ((center[Y] - radius - padding - ARENA_ORIGIN_Y) / TILE_SIZE)
    .floor()
    .to_int() -
    1
  let max_y = ((center[Y] + radius + padding - ARENA_ORIGIN_Y) / TILE_SIZE)
    .floor()
    .to_int() +
    1
  let rects : Array[Rect] = []
  for y in min_y..<(max_y + 1) {
    for x in min_x..<(max_x + 1) {
      if tile_is_solid(tile_at(x, y)) {
        rects.push(tile_rect(x, y))
      }
    }
  }
  rects
}

///|
fn resolve_circle_rects_on_x(
  x : Double,
  y : Double,
  radius : Double,
  delta_x : Double,
  rects : Array[Rect],
) -> Double {
  let mut next = x + delta_x
  for rect in rects {
    if circle_overlaps_rect(vec2(next, y), radius, rect) {
      if delta_x > 0.0 {
        next = rect.x - radius
      } else if delta_x < 0.0 {
        next = rect.x + rect.width + radius
      }
    }
  }
  next
}

///|
fn resolve_circle_rects_on_y(
  x : Double,
  y : Double,
  radius : Double,
  delta_y : Double,
  rects : Array[Rect],
) -> Double {
  let mut next = y + delta_y
  for rect in rects {
    if circle_overlaps_rect(vec2(x, next), radius, rect) {
      if delta_y > 0.0 {
        next = rect.y - radius
      } else if delta_y < 0.0 {
        next = rect.y + rect.height + radius
      }
    }
  }
  next
}

///|
fn move_circle_with_tiles(
  center : @math.Vec2,
  radius : Double,
  direction : Direction,
  distance : Double,
) -> @math.Vec2 {
  let rects = solid_tile_rects_near(center, radius, distance + 2.0)
  match direction {
    Up =>
      vec2(
        center[X],
        resolve_circle_rects_on_y(
          center[X],
          center[Y],
          radius,
          -distance,
          rects,
        ),
      )
    Down =>
      vec2(
        center[X],
        resolve_circle_rects_on_y(center[X], center[Y], radius, distance, rects),
      )
    Left =>
      vec2(
        resolve_circle_rects_on_x(
          center[X],
          center[Y],
          radius,
          -distance,
          rects,
        ),
        center[Y],
      )
    Right =>
      vec2(
        resolve_circle_rects_on_x(center[X], center[Y], radius, distance, rects),
        center[Y],
      )
  }
}

///|
fn tank_can_move(
  center : @math.Vec2,
  radius : Double,
  direction : Direction,
  distance : Double,
) -> Bool {
  let next = move_circle_with_tiles(center, radius, direction, distance)
  abs_double(next[X] - center[X]) > 0.001 ||
  abs_double(next[Y] - center[Y]) > 0.001
}

///|
fn direction_toward_player(center : @math.Vec2) -> Direction {
  let dx = player.center[X] - center[X]
  let dy = player.center[Y] - center[Y]
  if abs_double(dx) >= abs_double(dy) {
    if dx >= 0.0 {
      Right
    } else {
      Left
    }
  } else if dy >= 0.0 {
    Down
  } else {
    Up
  }
}

///|
fn line_clear_horizontal(y : Int, from_x : Int, to_x : Int) -> Bool {
  let start = if from_x < to_x { from_x + 1 } else { to_x + 1 }
  let end = if from_x < to_x { to_x - 1 } else { from_x - 1 }
  if start > end {
    return true
  }
  for x in start..<(end + 1) {
    if tile_blocks_bullet(tile_at(x, y)) {
      return false
    }
  }
  true
}

///|
fn line_clear_vertical(x : Int, from_y : Int, to_y : Int) -> Bool {
  let start = if from_y < to_y { from_y + 1 } else { to_y + 1 }
  let end = if from_y < to_y { to_y - 1 } else { from_y - 1 }
  if start > end {
    return true
  }
  for y in start..<(end + 1) {
    if tile_blocks_bullet(tile_at(x, y)) {
      return false
    }
  }
  true
}

///|
fn enemy_should_fire(enemy : EnemyState) -> Bool {
  if !player.alive {
    return false
  }
  let (enemy_x, enemy_y) = world_to_grid(enemy.center)
  let (player_x, player_y) = world_to_grid(player.center)
  if enemy_x == player_x {
    return line_clear_vertical(enemy_x, enemy_y, player_y)
  }
  if enemy_y == player_y {
    return line_clear_horizontal(enemy_y, enemy_x, player_x)
  }
  false
}

///|
fn spawn_bullet_from_tank(
  center : @math.Vec2,
  direction : Direction,
  owner : BulletOwner,
) -> Unit {
  let muzzle = tank_barrel_position(center, direction)
  spawn_bullet_entity(muzzle, direction, owner)
  play_shoot_sound()
}

///|
fn player_fire_if_requested() -> Unit {
  if !player.alive || player.reload_timer > 0.0 {
    return
  }
  if @inputs.just_pressed_mouse.left_button || @inputs.is_just_pressed(Space) {
    spawn_bullet_from_tank(player.center, player.turret_direction, Player)
    player.reload_timer = PLAYER_SHOT_COOLDOWN
  }
}

///|
fn fire_enemy_if_possible(index : Int) -> Unit {
  if !enemies[index].alive || enemies[index].reload_timer > 0.0 {
    return
  }
  if !enemy_should_fire(enemies[index]) {
    return
  }
  let direction = direction_toward_player(enemies[index].center)
  enemies[index].turret_direction = direction
  spawn_bullet_from_tank(enemies[index].center, direction, Enemy)
  enemies[index].reload_timer = ENEMY_SHOT_COOLDOWN
}

///|
fn move_player(delta : Double) -> Unit {
  if !player.alive {
    return
  }
  match latest_held_direction() {
    Some(direction) => {
      player.direction = direction
      let next = move_circle_with_tiles(
        player.center,
        PLAYER_RADIUS,
        direction,
        PLAYER_SPEED * delta,
      )
      player.center = next
    }
    None => ()
  }
  player.turret_direction = mouse_turret_direction(
    player.center,
    player.direction,
  )
  if player.reload_timer > 0.0 {
    player.reload_timer = clamp_double(
      player.reload_timer - delta,
      0.0,
      PLAYER_SHOT_COOLDOWN,
    )
  }
  player_fire_if_requested()
}

///|
fn choose_enemy_direction(enemy : EnemyState, delta : Double) -> Direction {
  let dx = player.center[X] - enemy.center[X]
  let dy = player.center[Y] - enemy.center[Y]
  let primary = if abs_double(dx) >= abs_double(dy) {
    if dx >= 0.0 {
      Right
    } else {
      Left
    }
  } else if dy >= 0.0 {
    Down
  } else {
    Up
  }
  let secondary = if abs_double(dx) >= abs_double(dy) {
    if dy >= 0.0 {
      Down
    } else {
      Up
    }
  } else if dx >= 0.0 {
    Right
  } else {
    Left
  }
  let fallback = opposite_direction(primary)
  let alternate = opposite_direction(secondary)
  let probe = clamp_double(ENEMY_SPEED * delta + 2.0, 4.0, 12.0)
  if tank_can_move(enemy.center, ENEMY_RADIUS, primary, probe) {
    primary
  } else if tank_can_move(enemy.center, ENEMY_RADIUS, enemy.direction, probe) {
    enemy.direction
  } else if tank_can_move(enemy.center, ENEMY_RADIUS, secondary, probe) {
    secondary
  } else if tank_can_move(enemy.center, ENEMY_RADIUS, fallback, probe) {
    fallback
  } else if tank_can_move(enemy.center, ENEMY_RADIUS, alternate, probe) {
    alternate
  } else {
    enemy.direction
  }
}

///|
fn move_enemy(index : Int, delta : Double) -> Unit {
  if !enemies[index].alive {
    return
  }
  enemies[index].think_timer += delta
  if enemies[index].think_timer >= ENEMY_THINK_INTERVAL {
    enemies[index].think_timer = 0.0
    let chosen = choose_enemy_direction(enemies[index], delta)
    enemies[index].direction = chosen
  }
  let move_distance = ENEMY_SPEED * delta
  let next = move_circle_with_tiles(
    enemies[index].center,
    ENEMY_RADIUS,
    enemies[index].direction,
    move_distance,
  )
  if abs_double(next[X] - enemies[index].center[X]) <= 0.001 &&
    abs_double(next[Y] - enemies[index].center[Y]) <= 0.001 {
    enemies[index].direction = choose_enemy_direction(enemies[index], delta)
  } else {
    enemies[index].center = next
  }
  enemies[index].turret_direction = direction_toward_player(
    enemies[index].center,
  )
  if enemies[index].reload_timer > 0.0 {
    enemies[index].reload_timer = clamp_double(
      enemies[index].reload_timer - delta,
      0.0,
      ENEMY_SHOT_COOLDOWN,
    )
  }
  fire_enemy_if_possible(index)
}

///|
fn destroy_bullet(index : Int) -> Unit {
  bullets[index].entity.destroy()
  ignore(bullet_entities.remove(index))
  ignore(bullets.remove(index))
}

///|
fn destroy_enemy(index : Int) -> Unit {
  if enemies[index].alive {
    enemies[index].alive = false
    play_boom_sound()
  }
}

///|
fn kill_player() -> Unit {
  if player.alive {
    player.alive = false
    play_lose_sound()
    round_outcome.val = Defeat
    setup_round_over_phase()
  }
}

///|
fn maybe_destroy_brick_at(x : Int, y : Int) -> Bool {
  if tile_at(x, y) == Brick {
    set_tile_code(x, y, TILE_EMPTY)
    play_hit_sound()
    return true
  }
  false
}

///|
fn bullet_hits_tile(bullet : BulletState) -> Bool {
  let (x, y) = world_to_grid(bullet.center)
  if !tile_in_bounds(x, y) {
    return true
  }
  match tile_at(x, y) {
    Floor => false
    Steel => true
    Brick => maybe_destroy_brick_at(x, y)
  }
}

///|
fn resolve_bullet_hits() -> Unit {
  let mut index = bullets.length() - 1
  while index >= 0 {
    let bullet = bullets[index]
    let direction = direction_vector(bullet.direction)
    let next_center = vec2(
      bullet.center[X] + direction[X] * bullet.speed * @time.delta(),
      bullet.center[Y] + direction[Y] * bullet.speed * @time.delta(),
    )
    bullets[index].center = next_center
    bullets[index].life_time += @time.delta()
    if bullets[index].life_time >= 2.0 {
      destroy_bullet(index)
      index -= 1
      continue
    }
    if bullet_hits_tile(bullets[index]) {
      destroy_bullet(index)
      index -= 1
      continue
    }
    match bullets[index].owner {
      Player => {
        let mut hit = false
        for enemy_index in 0..<enemies.length() {
          if enemies[enemy_index].alive &&
            circle_overlaps_circle(
              bullets[index].center,
              BULLET_RADIUS,
              enemies[enemy_index].center,
              ENEMY_RADIUS,
            ) {
            destroy_enemy(enemy_index)
            hit = true
            break
          }
        }
        if hit {
          destroy_bullet(index)
          index -= 1
          continue
        }
      }
      Enemy =>
        if player.alive &&
          circle_overlaps_circle(
            bullets[index].center,
            BULLET_RADIUS,
            player.center,
            PLAYER_RADIUS,
          ) {
          destroy_bullet(index)
          kill_player()
          return
        }
    }
    index -= 1
  }
}

///|
fn resolve_enemy_contact() -> Unit {
  if !player.alive {
    return
  }
  for enemy in enemies {
    if enemy.alive &&
      circle_overlaps_circle(
        player.center,
        PLAYER_RADIUS,
        enemy.center,
        ENEMY_RADIUS,
      ) {
      kill_player()
      return
    }
  }
}

///|
fn sync_menu_visuals() -> Unit {
  update_text_entity_if_changed(
    status_entity,
    last_status_text,
    "Level \{current_level.val + 1}/\{level_count()}  \{level_at(current_level.val).name}",
  )
  update_text_entity_if_changed(
    menu_option_entities[0],
    last_menu_start_text,
    if current_menu_option.val == Start {
      "> START GAME"
    } else {
      "  START GAME"
    },
  )
  update_text_entity_if_changed(
    menu_option_entities[1],
    last_menu_exit_text,
    if current_menu_option.val == Exit {
      "> EXIT"
    } else {
      "  EXIT"
    },
  )
  show_entity(menu_option_entities[0])
  show_entity(menu_option_entities[1])
  hide_entity(player_body_entity)
  hide_entity(player_barrel_entity)
  for i in 0..<enemy_body_entities.length() {
    hide_entity(enemy_body_entities[i])
    hide_entity(enemy_barrel_entities[i])
  }
  hide_entity(box_entity)
  for entity in tile_entities {
    hide_entity(entity)
  }
}

///|
fn sync_playing_visuals() -> Unit {
  update_text_entity_if_changed(
    status_entity,
    last_status_text,
    "Level \{current_level.val + 1}/\{level_count()}  \{level_at(current_level.val).name}  Enemies \{active_enemy_count()}",
  )
  update_text_entity_if_changed(
    menu_option_entities[0],
    last_menu_start_text,
    "",
  )
  update_text_entity_if_changed(
    menu_option_entities[1],
    last_menu_exit_text,
    "",
  )
  hide_entity(menu_option_entities[0])
  hide_entity(menu_option_entities[1])
  show_entity(box_entity)
  for entity in tile_entities {
    show_entity(entity)
  }
  if player.alive {
    show_entity(player_body_entity)
    show_entity(player_barrel_entity)
    set_rotated_rect_entity(
      player_body_entity,
      player.center,
      tank_body_size(),
      PLAYER_COLOR,
      PLAYER_Z,
      tank_angle(player.direction),
    )
    set_rotated_rect_entity(
      player_barrel_entity,
      tank_barrel_position(player.center, player.turret_direction),
      tank_barrel_size(),
      PLAYER_BARREL_COLOR,
      PLAYER_Z + 1,
      tank_angle(player.turret_direction),
    )
  } else {
    hide_entity(player_body_entity)
    hide_entity(player_barrel_entity)
  }
  for i in 0..<enemy_body_entities.length() {
    if enemies[i].alive {
      show_entity(enemy_body_entities[i])
      show_entity(enemy_barrel_entities[i])
      set_rotated_rect_entity(
        enemy_body_entities[i],
        enemies[i].center,
        tank_body_size(),
        ENEMY_COLOR,
        ENEMY_Z,
        tank_angle(enemies[i].direction),
      )
      set_rotated_rect_entity(
        enemy_barrel_entities[i],
        tank_barrel_position(enemies[i].center, enemies[i].turret_direction),
        tank_barrel_size(),
        ENEMY_BARREL_COLOR,
        ENEMY_Z + 1,
        tank_angle(enemies[i].turret_direction),
      )
    } else {
      hide_entity(enemy_body_entities[i])
      hide_entity(enemy_barrel_entities[i])
    }
  }
  for i in 0..<bullets.length() {
    let bullet = bullets[i]
    let entity = bullet_entities[i]
    show_entity(entity)
    let color = match bullet.owner {
      Player => BULLET_PLAYER_COLOR
      Enemy => BULLET_ENEMY_COLOR
    }
    set_rect_entity(entity, bullet.center, bullet_size(), color, BULLET_Z)
  }
}

///|
fn sync_round_over_visuals() -> Unit {
  update_text_entity_if_changed(
    status_entity,
    last_status_text,
    "\{phase_label()}  Level \{current_level.val + 1}/\{level_count()}  \{level_at(current_level.val).name}",
  )
  update_text_entity_if_changed(
    round_entity,
    last_round_text,
    match round_outcome.val {
      Victory => "VICTORY"
      Defeat => "DEFEAT"
    },
  )
  update_text_entity_if_changed(
    menu_option_entities[0],
    last_menu_start_text,
    if current_menu_option.val == Start {
      "> START GAME"
    } else {
      "  START GAME"
    },
  )
  update_text_entity_if_changed(
    menu_option_entities[1],
    last_menu_exit_text,
    if current_menu_option.val == Exit {
      "> EXIT"
    } else {
      "  EXIT"
    },
  )
  show_entity(menu_option_entities[0])
  show_entity(menu_option_entities[1])
  hide_entity(player_body_entity)
  hide_entity(player_barrel_entity)
  for i in 0..<enemy_body_entities.length() {
    hide_entity(enemy_body_entities[i])
    hide_entity(enemy_barrel_entities[i])
  }
  hide_entity(box_entity)
  for entity in tile_entities {
    show_entity(entity)
  }
  for entity in bullet_entities {
    hide_entity(entity)
  }
}

///|
fn sync_fps_overlay() -> Unit {
  if debug_fps_enabled.val {
    show_entity(fps_entity)
    update_text_entity_if_changed(
      fps_entity,
      last_fps_text,
      "FPS \{@raylib.get_fps()}",
    )
  } else {
    hide_entity(fps_entity)
  }
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  handle_global_input()
  match phase.val {
    MainMenu => handle_menu_input()
    Playing => {
      refresh_direction_press_stamps()
      if player.alive {
        player.turret_direction = mouse_turret_direction(
          player.center,
          player.direction,
        )
      }
      if @inputs.is_just_pressed(Space) ||
        @inputs.just_pressed_mouse.left_button {
        player_fire_if_requested()
      }
    }
    RoundOver => ()
  }
  profile_phase("input", started_at)
}

///|
pub fn simulation_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  if phase.val != Playing {
    return
  }
  let delta = @time.delta()
  move_player(delta)
  for i in 0..<enemies.length() {
    move_enemy(i, delta)
  }
  resolve_bullet_hits()
  resolve_enemy_contact()
  if phase.val == Playing && active_enemy_count() == 0 {
    round_outcome.val = Victory
    play_win_sound()
    setup_round_over_phase()
  }
  profile_phase("simulation", started_at)
}

///|
pub fn render_sync_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  sync_background()
  sync_fps_overlay()
  match phase.val {
    MainMenu => sync_menu_visuals()
    Playing => {
      sync_playing_visuals()
      update_text_entity(round_entity, "")
    }
    RoundOver => sync_round_over_visuals()
  }
  profile_phase("render", started_at)
  let frame_dt = @time.delta()
  profile_frame_count.val = profile_frame_count.val + 1
  if frame_dt > profile_slowest_frame.val {
    profile_slowest_frame.val = frame_dt
  }
  maybe_report_profile()
}

///|
pub fn capture_after_render_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  if !debug_capture_enabled.val || debug_capture_taken.val {
    return
  }
  // Keep QA captures focused on active gameplay instead of transient round-over screens.
  if phase.val != Playing && !debug_capture_forced_start.val {
    start_round()
    debug_capture_forced_start.val = true
    debug_capture_started_at.val = @time.elapsed()
    return
  }
  let capture_delay = if debug_capture_forced_start.val {
    1.0
  } else {
    DEBUG_CAPTURE_DELAY_SECONDS
  }
  if @time.elapsed() - debug_capture_started_at.val < capture_delay {
    return
  }
  @raylib.take_screenshot(DEBUG_CAPTURE_PATH)
  println("[tankbattle][capture] path=\{DEBUG_CAPTURE_PATH}")
  debug_capture_taken.val = true
  profile_phase("capture", started_at)
  @system.exit()
}

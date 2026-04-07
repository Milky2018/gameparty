///|
let hud_text_cache : Ref[String] = { val: "" }

///|
let message_text_cache : Ref[String] = { val: "" }

///|
let debug_text_cache : Ref[String] = { val: "" }

///|
let title_text_cache : Ref[String] = { val: "" }

///|
fn sync_hud_text(
  entity : @entity.Entity,
  next_text : String,
  cache : Ref[String],
) -> Unit {
  if cache.val == next_text {
    return
  }
  @ui.texts().set(entity, @ui.Text::new(next_text))
  cache.val = next_text
}

///|
fn request_restart() -> Unit {
  reset_game_state()
  reset_entities()
  hud_text_cache.val = ""
  message_text_cache.val = ""
  debug_text_cache.val = ""
  title_text_cache.val = ""
}

///|
fn request_game_over(lost : Bool) -> Unit {
  game_state.phase = if lost { Lost } else { Won }
  if lost {
    play_sound(lose_sound)
  } else {
    play_sound(win_sound)
  }
}

///|
fn handle_global_input() -> Unit {
  if @inputs.is_just_pressed(Escape) {
    @system.exit()
    return
  }
  if @inputs.is_just_pressed(KeyR) {
    request_restart()
    return
  }
  if (@inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space)) &&
    game_state.phase != Playing {
    request_restart()
    return
  }
  if @raylib.is_key_pressed(@raylib.KeyF3) {
    game_state.debug_overlay = !game_state.debug_overlay
  }
}

///|
fn player_move_input() -> @math.Vec2D {
  let x = (if @inputs.is_pressed(KeyD) || @inputs.is_pressed(ArrowRight) {
      1.0
    } else {
      0.0
    }) +
    (if @inputs.is_pressed(KeyA) || @inputs.is_pressed(ArrowLeft) {
      -1.0
    } else {
      0.0
    })
  let y = (if @inputs.is_pressed(KeyS) || @inputs.is_pressed(ArrowDown) {
      1.0
    } else {
      0.0
    }) +
    (if @inputs.is_pressed(KeyW) || @inputs.is_pressed(ArrowUp) {
      -1.0
    } else {
      0.0
    })
  let input = @math.Vec2D(x, y)
  if vec_length(input) <= 0.0001 {
    @math.Vec2D::zero()
  } else {
    input.normalize()
  }
}

///|
fn aim_vector() -> @math.Vec2D {
  let mouse = @inputs.mouse.pos
  let raw = mouse - player_state.pos
  if vec_length(raw) <= 0.0001 {
    moving_direction(player_state.facing)
  } else {
    raw.normalize()
  }
}

///|
fn fire_player_if_requested() -> Unit {
  if !can_fire_player() {
    return
  }
  if !@inputs.is_mouse_pressed(@inputs.MouseButton::Left) &&
    !@inputs.is_just_pressed(Space) {
    return
  }
  let direction = aim_vector()
  spawn_player_bullet(player_state.pos, direction)
  player_state.fire_cd = PLAYER_FIRE_COOLDOWN
  play_sound(shoot_sound)
}

///|
fn step_position_x(
  center : @math.Vec2D,
  radius : Double,
  delta_x : Double,
  rects : Array[@math.Rect],
) -> @math.Vec2D {
  let mut next = center[X] + delta_x
  for rect in rects {
    if rect_intersects_circle(rect, @math.Vec2D(next, center[Y]), radius) {
      if delta_x > 0.0 {
        next = rect.position[X] - radius
      } else if delta_x < 0.0 {
        next = rect.position[X] + rect.size[X] + radius
      }
    }
  }
  @math.Vec2D(next, center[Y])
}

///|
fn step_position_y(
  center : @math.Vec2D,
  radius : Double,
  delta_y : Double,
  rects : Array[@math.Rect],
) -> @math.Vec2D {
  let mut next = center[Y] + delta_y
  for rect in rects {
    if rect_intersects_circle(rect, @math.Vec2D(center[X], next), radius) {
      if delta_y > 0.0 {
        next = rect.position[Y] - radius
      } else if delta_y < 0.0 {
        next = rect.position[Y] + rect.size[Y] + radius
      }
    }
  }
  @math.Vec2D(center[X], next)
}

///|
fn obstacle_rects() -> Array[@math.Rect] {
  obstacle_rect_cache
}

///|
fn refresh_obstacle_rect_cache() -> Unit {
  obstacle_rect_cache.clear()
  for obstacle in obstacle_states {
    if obstacle.alive {
      obstacle_rect_cache.push(obstacle.rect)
    }
  }
}

///|
fn bullet_hits_obstacle(bullet : BulletState) -> Int? {
  for i in 0..<obstacle_states.length() {
    let obstacle = obstacle_states[i]
    if !obstacle.alive {
      continue
    }
    if rect_intersects_circle(obstacle.rect, bullet.pos, BULLET_RADIUS) {
      return Some(i)
    }
  }
  None
}

///|
fn bullet_hits_enemy(bullet : BulletState) -> Int? {
  for i in 0..<enemy_states.length() {
    let enemy = enemy_states[i]
    if !enemy.alive {
      continue
    }
    if circle_intersects_circle(
        enemy.pos,
        ENEMY_RADIUS,
        bullet.pos,
        BULLET_RADIUS,
      ) {
      return Some(i)
    }
  }
  None
}

///|
fn bullet_hits_player(bullet : BulletState) -> Bool {
  if !player_state.alive {
    return false
  }
  circle_intersects_circle(
    player_state.pos,
    PLAYER_RADIUS,
    bullet.pos,
    BULLET_RADIUS,
  )
}

///|
fn enemy_at_player(enemy : EnemyState) -> Bool {
  circle_intersects_circle(
    enemy.pos,
    ENEMY_RADIUS,
    player_state.pos,
    PLAYER_RADIUS,
  )
}

///|
fn enemy_line_of_sight(enemy : EnemyState) -> Bool {
  let delta = player_state.pos - enemy.pos
  vec_length(delta) < 420.0
}

///|
fn enemy_desired_direction(enemy : EnemyState) -> @math.Vec2D {
  let delta = player_state.pos - enemy.pos
  if vec_length(delta) <= 0.0001 {
    @math.Vec2D::zero()
  } else {
    delta.normalize()
  }
}

///|
fn update_player(delta : Double) -> Unit {
  if !player_state.alive {
    return
  }
  if player_state.invuln > 0.0 {
    player_state.invuln = clamp_double(
      player_state.invuln - delta,
      0.0,
      PLAYER_RESPAWN_INVULN,
    )
  }
  if player_state.fire_cd > 0.0 {
    player_state.fire_cd = clamp_double(
      player_state.fire_cd - delta,
      0.0,
      PLAYER_FIRE_COOLDOWN,
    )
  }
  let input = player_move_input()
  if vec_length(input) > 0.0001 {
    player_state.facing = facing_from_vector(input)
  }
  let desired = input.scalar_mul(PLAYER_SPEED * delta)
  let rects = obstacle_rects()
  let next_x = step_position_x(
    player_state.pos,
    PLAYER_RADIUS,
    desired[X],
    rects,
  )
  let next_xy = step_position_y(next_x, PLAYER_RADIUS, desired[Y], rects)
  player_state.pos = in_world(next_xy, PLAYER_RADIUS)
  fire_player_if_requested()
  if wave_state.extraction_open &&
    extract_world_rect().intersects(
      body_rect_for(player_state.pos, PLAYER_RADIUS),
    ) {
    request_game_over(false)
  }
}

///|
fn update_enemies(delta : Double) -> Unit {
  let rects = obstacle_rects()
  for i in 0..<enemy_states.length() {
    let enemy = enemy_states[i]
    if !enemy.alive {
      continue
    }
    if enemy.fire_cd > 0.0 {
      enemy.fire_cd = clamp_double(enemy.fire_cd - delta, 0.0, 999.0)
    }
    match enemy.kind {
      Soldier => {
        let desired = enemy_desired_direction(enemy)
        if vec_length(desired) > 0.0001 {
          enemy.facing = facing_from_vector(desired)
        }
        let movement = desired.scalar_mul(SOLDIER_SPEED * delta)
        let next_x = step_position_x(
          enemy.pos,
          ENEMY_RADIUS,
          movement[X],
          rects,
        )
        let next_xy = step_position_y(next_x, ENEMY_RADIUS, movement[Y], rects)
        enemy.pos = in_world(next_xy, ENEMY_RADIUS)
        if enemy.fire_cd <= 0.0 &&
          enemy_line_of_sight(enemy) &&
          vec_length(player_state.pos - enemy.pos) < 400.0 {
          let aim = vec_normalize(player_state.pos - enemy.pos)
          spawn_enemy_bullet(enemy.pos, aim)
          enemy.fire_cd = SOLDIER_FIRE_COOLDOWN
        }
      }
      Turret => {
        let aim = player_state.pos - enemy.pos
        if vec_length(aim) > 0.0001 {
          enemy.facing = facing_from_vector(aim)
        }
        if enemy.fire_cd <= 0.0 && enemy_line_of_sight(enemy) {
          spawn_enemy_bullet(enemy.pos, vec_normalize(aim))
          enemy.fire_cd = TURRET_FIRE_COOLDOWN
        }
      }
    }
    if enemy.alive && enemy_at_player(enemy) {
      damage_player(1)
    }
    enemy_states[i] = enemy
  }
}

///|
fn update_bullets(delta : Double) -> Unit {
  for i in 0..<bullet_states.length() {
    let bullet = bullet_states[i]
    if !bullet.alive {
      continue
    }
    bullet.ttl = bullet.ttl - delta
    if bullet.ttl <= 0.0 {
      bullet.alive = false
      bullet_states[i] = bullet
      continue
    }
    bullet.pos = bullet.pos + bullet.vel.scalar_mul(delta)
    if bullet.pos[X] < WORLD_MIN_X - 24.0 ||
      bullet.pos[X] > WORLD_MAX_X + 24.0 ||
      bullet.pos[Y] < WORLD_MIN_Y - 24.0 ||
      bullet.pos[Y] > WORLD_MAX_Y + 24.0 {
      bullet.alive = false
      bullet_states[i] = bullet
      continue
    }
    match bullet.owner {
      Player =>
        match bullet_hits_enemy(bullet) {
          Some(enemy_index) => {
            damage_enemy(enemy_index, 1)
            bullet.alive = false
            play_sound(hit_sound)
          }
          None =>
            match bullet_hits_obstacle(bullet) {
              Some(obstacle_index) => {
                damage_obstacle(obstacle_index, 1)
                bullet.alive = false
                play_sound(boom_sound)
              }
              None => ()
            }
        }
      Enemy =>
        if bullet_hits_player(bullet) {
          bullet.alive = false
          damage_player(1)
          play_sound(hit_sound)
        } else {
          match bullet_hits_obstacle(bullet) {
            Some(obstacle_index) => {
              damage_obstacle(obstacle_index, 1)
              bullet.alive = false
            }
            None => ()
          }
        }
    }
    bullet_states[i] = bullet
  }
}

///|
fn spawn_wave_if_needed() -> Unit {
  if game_state.phase != Playing {
    return
  }
  if wave_state.spawn_left <= 0 {
    maybe_finish_wave()
    return
  }
  wave_state.spawn_timer -= @time.delta()
  if wave_state.spawn_timer > 0.0 {
    return
  }
  wave_state.spawn_timer = wave_spawn_interval(wave_state.index)
  spawn_enemy_batch()
}

///|
fn cleanup_dead_entities() -> Unit {
  let alive_enemies : Array[EnemyState] = []
  for enemy in enemy_states {
    if enemy.alive {
      alive_enemies.push(enemy)
    } else {
      destroy_and_clear(enemy.entity)
    }
  }
  enemy_states.clear()
  for enemy in alive_enemies {
    enemy_states.push(enemy)
  }

  let alive_bullets : Array[BulletState] = []
  for bullet in bullet_states {
    if bullet.alive {
      alive_bullets.push(bullet)
    } else {
      destroy_and_clear(bullet.entity)
    }
  }
  bullet_states.clear()
  for bullet in alive_bullets {
    bullet_states.push(bullet)
  }

  let alive_obstacles : Array[ObstacleState] = []
  for obstacle in obstacle_states {
    if obstacle.alive {
      alive_obstacles.push(obstacle)
    } else {
      destroy_and_clear(obstacle.entity)
    }
  }
  obstacle_states.clear()
  for obstacle in alive_obstacles {
    obstacle_states.push(obstacle)
  }
}

///|
fn sync_visuals() -> Unit {
  spawn_player_visual()
  for enemy in enemy_states {
    spawn_enemy_visual(enemy.entity, enemy.kind, enemy.pos, enemy.facing)
  }
  for bullet in bullet_states {
    spawn_bullet_visual(bullet.entity, bullet.owner, bullet.pos, bullet.vel)
  }
  for obstacle in obstacle_states {
    spawn_obstacle_visual(obstacle.entity, obstacle)
  }
  spawn_extraction()
}

///|
fn update_message_text() -> Unit {
  let main = "Lives \{player_state.lives}  HP \{player_state.hp}  Score \{game_state.score}  Wave \{clamp_int(wave_state.index + 1, 1, wave_total_count() + 1)}/\{wave_total_count()}"
  let mission = if game_state.phase == Playing {
    if wave_state.extraction_open {
      "Objective: move to the green extraction zone"
    } else {
      "Objective: clear the enemy waves"
    }
  } else if game_state.phase == Won {
    "Mission complete. Press Enter/Space or R to restart."
  } else {
    "Jeep destroyed. Press Enter/Space or R to retry."
  }
  let debug = if game_state.debug_overlay {
    "FPS \{(1.0 / clamp_double(@time.delta(), 0.0001, 1.0)).to_int()}  Enemies \{active_enemies()}  Bullets \{bullet_states.length()}  Obstacles \{obstacle_states.length()}"
  } else {
    "F3 toggles FPS overlay"
  }
  sync_hud_text(hud_entity, main, hud_text_cache)
  sync_hud_text(message_entity, mission, message_text_cache)
  sync_hud_text(debug_entity, debug, debug_text_cache)
  sync_hud_text(title_entity, "JACKAL", title_text_cache)
}

///|
fn maybe_report_profile() -> Unit {
  if !game_state.profile_enabled {
    return
  }
  let now = @time.elapsed()
  if game_state.profile_frame_count == 0 {
    game_state.profile_started_at = now
    game_state.profile_last_report_at = now
  }
  game_state.profile_frame_count += 1
  let window_s = now - game_state.profile_last_report_at
  if window_s < PROFILE_REPORT_SECONDS {
    return
  }
  let frame_count = game_state.profile_frame_count.to_double()
  let sample_s = now - game_state.profile_started_at
  if sample_s < 0.5 {
    game_state.profile_frame_count = 0
    game_state.profile_last_report_at = now
    return
  }
  let fps_avg = if window_s <= 0.0001 { 0.0 } else { frame_count / window_s }
  let fps_window = fps_avg
  let fps_frame_dt = if window_s <= 0.0001 {
    0.0
  } else {
    frame_count / window_s
  }
  let fps = fps_avg.to_int()
  let avg_ms = if frame_count > 0.0 {
    window_s * 1000.0 / frame_count
  } else {
    0.0
  }
  println(
    "[jackal][profile] fps_avg=\{fps_avg} fps_window=\{fps_window} fps_frame_dt=\{fps_frame_dt} fps=\{fps} avg_ms=\{avg_ms} window_s=\{window_s} sample_s=\{sample_s} score=\{game_state.score} enemies=\{active_enemies()} bullets=\{bullet_states.length()} obstacles=\{obstacle_states.length()} wave=\{clamp_int(wave_state.index + 1, 1, wave_total_count() + 1)}/\{wave_total_count()}",
  )
  game_state.profile_frame_count = 0
  game_state.profile_last_report_at = now
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  handle_global_input()
}

///|
pub fn simulation_system(_world : @ecs.World) -> Unit {
  if game_state.phase != Playing {
    update_message_text()
    maybe_report_profile()
    return
  }
  let delta = @time.delta()
  refresh_obstacle_rect_cache()
  update_player(delta)
  update_enemies(delta)
  update_bullets(delta)
  spawn_wave_if_needed()
  cleanup_dead_entities()
  sync_visuals()
  update_message_text()
  maybe_report_profile()
}

///|
pub fn render_sync_system(_world : @ecs.World) -> Unit {
  sync_visuals()
  update_message_text()
}

///|
pub fn capture_after_render_system(_world : @ecs.World) -> Unit {
  if !game_state.capture_enabled || game_state.capture_taken {
    return
  }
  if @time.elapsed() - game_state.capture_started_at <
    DEBUG_CAPTURE_DELAY_SECONDS {
    return
  }
  @raylib.take_screenshot(DEBUG_CAPTURE_PATH)
  println("[jackal][capture] path=\{DEBUG_CAPTURE_PATH}")
  game_state.capture_taken = true
  @system.exit()
}

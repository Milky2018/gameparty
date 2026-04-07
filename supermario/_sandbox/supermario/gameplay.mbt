///|
fn rect_intersects(a : @math.Rect, b : @math.Rect) -> Bool {
  a.intersects(b)
}

///|
fn player_rect() -> @math.Rect {
  rect_from_center(player_state.val.center, vec2(PLAYER_WIDTH, PLAYER_HEIGHT))
}

///|
fn enemy_rect(enemy : EnemyState) -> @math.Rect {
  rect_from_center(enemy.center, vec2(ENEMY_WIDTH, ENEMY_HEIGHT))
}

///|
fn block_rect(block : SolidBlock) -> @math.Rect {
  rect_from_center(block.center, block.size)
}

///|
fn goal_rect(level : LevelSpec) -> @math.Rect {
  rect_from_center(level.goal_center, level.goal_size)
}

///|
fn movement_axis_resolution(rect : @math.Rect, delta : Double, solids : Array[SolidBlock], axis_x : Bool) -> (Double, Bool) {
  let mut moved = delta
  let mut touching = false
  if delta == 0.0 {
    return (0.0, false)
  }
  let mut probe = rect
  if axis_x {
    probe = probe.shift(vec2(delta, 0.0))
  } else {
    probe = probe.shift(vec2(0.0, delta))
  }
  for block in solids {
    let block_r = block_rect(block)
    if rect_intersects(probe, block_r) {
      touching = true
      if delta > 0.0 {
        if axis_x {
          moved = block_r.position[X] - (rect.position[X] + rect.size[X])
        } else {
          moved = block_r.position[Y] - (rect.position[Y] + rect.size[Y])
        }
      } else {
        if axis_x {
          moved = block_r.position[X] + block_r.size[X] - rect.position[X]
        } else {
          moved = block_r.position[Y] + block_r.size[Y] - rect.position[Y]
        }
      }
      break
    }
  }
  (moved, touching)
}

///|
fn set_phase(new_phase : GamePhase) -> Unit {
  game_phase.val = new_phase
  if new_phase == Playing {
    set_message_visible(false)
  } else {
    set_message_visible(true)
    let message = if new_phase == Won { "STAGE CLEAR" } else { "TOUCHED! PRESS R OR ENTER" }
    @ui.texts().set(hud_message_entity, @ui.Text::new(message))
  }
}

///|
fn restart_level(next_level? : Bool = false) -> Unit {
  if next_level {
    current_level_index.val = (current_level_index.val + 1) % level_specs.length()
  }
  set_current_level(current_level_index.val)
  set_phase(Playing)
}

///|
fn enemy_should_turn(enemy : EnemyState, next_x : Double) -> Bool {
  next_x < enemy.patrol_left || next_x > enemy.patrol_right
}

///|
fn stomp_check(player_before : @math.Rect, player_after : @math.Rect, enemy : EnemyState) -> Bool {
  let enemy_r = enemy_rect(enemy)
  if !rect_intersects(player_after, enemy_r) {
    return false
  }
  if player_before.position[Y] + player_before.size[Y] <= enemy_r.position[Y] + 8.0 &&
    player_state.val.velocity[Y] >= 0.0 {
    return true
  }
  false
}

///|
fn kill_player() -> Unit {
  if player_state.val.hurt_timer > 0.0 {
    return
  }
  player_state.val.alive = false
  player_state.val.hurt_timer = PLAYER_HURT_INVULN_SECONDS
  if audio_bank.val is Some(bank) {
    play_sound(bank.hit)
  }
  set_phase(Lost)
}

///|
fn bounce_player_after_stomp() -> Unit {
  player_state.val.velocity = player_state.val.velocity.update(Y, -PLAYER_JUMP_SPEED * 0.72)
  player_state.val.on_ground = false
  player_state.val.coyote_timer = 0.0
  if audio_bank.val is Some(bank) {
    play_sound(bank.stomp)
  }
}

///|
fn stomp_enemy(entity : @entity.Entity) -> Unit {
  match enemy_entities.get(entity) {
    Some(enemy) => {
      enemy.alive = false
      enemy_entities.set(entity, enemy)
      set_visibility(entity, false)
      if audio_bank.val is Some(bank) {
        play_sound(bank.stomp)
      }
    }
    None => ()
  }
}

///|
fn handle_player_input() -> Unit {
  let mut horizontal = 0.0
  if @raylib.is_key_down(@raylib.KeyA) || @raylib.is_key_down(@raylib.KeyLeft) {
    horizontal -= 1.0
  }
  if @raylib.is_key_down(@raylib.KeyD) || @raylib.is_key_down(@raylib.KeyRight) {
    horizontal += 1.0
  }
  player_state.val.velocity = player_state.val.velocity.update(X, horizontal * PLAYER_MOVE_SPEED)
  if horizontal < 0.0 {
    player_state.val.facing_right = false
  } else if horizontal > 0.0 {
    player_state.val.facing_right = true
  }
  if @raylib.is_key_pressed(@raylib.KeySpace) || @raylib.is_key_pressed(@raylib.KeyUp) {
    player_state.val.jump_buffer = JUMP_BUFFER_SECONDS
  } else {
    player_state.val.jump_buffer = clamp_double(
      player_state.val.jump_buffer - @time.delta(),
      0.0,
      JUMP_BUFFER_SECONDS,
    )
  }
  if @raylib.is_key_pressed(@raylib.KeyF3) {
    debug_overlay.val = !debug_overlay.val
  }
  if @raylib.is_key_pressed(@raylib.KeyEnter) &&
    (game_phase.val == Won || game_phase.val == Lost) {
    restart_level(next_level=true)
  }
}

///|
fn update_player() -> Unit {
  if !player_state.val.alive {
    return
  }
  let delta = @time.delta()
  if player_state.val.hurt_timer > 0.0 {
    player_state.val.hurt_timer = clamp_double(
      player_state.val.hurt_timer - delta,
      0.0,
      PLAYER_HURT_INVULN_SECONDS,
    )
  }
  if player_state.val.coyote_timer > 0.0 {
    player_state.val.coyote_timer = clamp_double(
      player_state.val.coyote_timer - delta,
      0.0,
      COYOTE_TIME_SECONDS,
    )
  }
  let pre_rect = player_rect()
  player_state.val.velocity = player_state.val.velocity.update(
    Y,
    clamp_double(player_state.val.velocity[Y] + PLAYER_GRAVITY * delta, -2000.0, PLAYER_MAX_FALL_SPEED),
  )
  if player_state.val.jump_buffer > 0.0 &&
    (player_state.val.on_ground || player_state.val.coyote_timer > 0.0) {
    player_state.val.velocity = player_state.val.velocity.update(Y, -PLAYER_JUMP_SPEED)
    player_state.val.on_ground = false
    player_state.val.jump_buffer = 0.0
    player_state.val.coyote_timer = 0.0
    if audio_bank.val is Some(bank) {
      play_sound(bank.jump)
    }
  }
  let x_rect = pre_rect
  let (dx, _) = movement_axis_resolution(x_rect, player_state.val.velocity[X] * delta, solid_blocks, true)
  player_state.val.center = player_state.val.center.update(X, player_state.val.center[X] + dx)
  let after_x_rect = rect_from_center(player_state.val.center, vec2(PLAYER_WIDTH, PLAYER_HEIGHT))
  let (dy, hit_ground) = movement_axis_resolution(after_x_rect, player_state.val.velocity[Y] * delta, solid_blocks, false)
  player_state.val.center = player_state.val.center.update(Y, player_state.val.center[Y] + dy)
  if hit_ground && player_state.val.velocity[Y] > 0.0 {
    player_state.val.on_ground = true
    player_state.val.coyote_timer = COYOTE_TIME_SECONDS
  } else if !hit_ground {
    player_state.val.on_ground = false
  }
  if dy != player_state.val.velocity[Y] * delta {
    if player_state.val.velocity[Y] > 0.0 {
      player_state.val.on_ground = true
      player_state.val.coyote_timer = COYOTE_TIME_SECONDS
    }
    player_state.val.velocity = player_state.val.velocity.update(Y, 0.0)
  }
  let now_rect = player_rect()
  for entity in enemy_entities_order {
    match enemy_entities.get(entity) {
      Some(enemy) => {
        if !enemy.alive {
          continue
        }
        if stomp_check(pre_rect, now_rect, enemy) {
          stomp_enemy(entity)
          bounce_player_after_stomp()
          continue
        }
        if rect_intersects(now_rect, enemy_rect(enemy)) {
          kill_player()
          break
        }
      }
      None => ()
    }
  }
  if game_phase.val == Playing {
    match current_level.val {
      Some(level) =>
        if rect_intersects(now_rect, goal_rect(level)) {
          if audio_bank.val is Some(bank) {
            play_sound(bank.goal)
          }
          set_phase(Won)
        }
      None => ()
    }
  }
  if player_state.val.center[Y] > WORLD_HEIGHT + 240.0 {
    kill_player()
  }
}

///|
fn update_enemies() -> Unit {
  if game_phase.val != Playing {
    return
  }
  let delta = @time.delta()
  for entity in enemy_entities_order {
    match enemy_entities.get(entity) {
      Some(enemy) => {
        if !enemy.alive {
          continue
        }
        enemy.velocity = enemy.velocity.update(
          Y,
          clamp_double(enemy.velocity[Y] + ENEMY_GRAVITY * delta, -2000.0, ENEMY_MAX_FALL_SPEED),
        )
        enemy.velocity = enemy.velocity.update(
          X,
          if enemy.facing_right { ENEMY_MOVE_SPEED } else { -ENEMY_MOVE_SPEED },
        )
        let start_rect = enemy_rect(enemy)
        let (dx, hit_wall_x) = movement_axis_resolution(start_rect, enemy.velocity[X] * delta, solid_blocks, true)
        enemy.center = enemy.center.update(X, enemy.center[X] + dx)
        let moved_rect = rect_from_center(enemy.center, vec2(ENEMY_WIDTH, ENEMY_HEIGHT))
        let (dy, _hit_wall_y) = movement_axis_resolution(moved_rect, enemy.velocity[Y] * delta, solid_blocks, false)
        enemy.center = enemy.center.update(Y, enemy.center[Y] + dy)
        if dy != enemy.velocity[Y] * delta {
          enemy.velocity = enemy.velocity.update(Y, 0.0)
          enemy.on_ground = true
        } else {
          enemy.on_ground = false
        }
        if hit_wall_x || enemy_should_turn(enemy, enemy.center[X]) {
          enemy.facing_right = !enemy.facing_right
        }
        let pos = enemy.center
        let ledge_probe = rect_from_center(
          vec2(if enemy.facing_right { pos[X] + ENEMY_WIDTH * 0.55 } else { pos[X] - ENEMY_WIDTH * 0.55 }, pos[Y] + ENEMY_HEIGHT * 0.6),
          vec2(10.0, 10.0),
        )
        let mut has_ground_ahead = false
        for block in solid_blocks {
          if rect_intersects(ledge_probe, block_rect(block)) {
            has_ground_ahead = true
            break
          }
        }
        if !has_ground_ahead && enemy.on_ground {
          enemy.facing_right = !enemy.facing_right
        }
        enemy_entities.set(entity, enemy)
      }
      None => ()
    }
  }
  for entity in enemy_entities_order {
    match enemy_entities.get(entity) {
      Some(enemy) =>
        if enemy.alive {
          set_sprite_entity(entity, enemy_sprite_color, vec2(ENEMY_WIDTH, ENEMY_HEIGHT), enemy.center, 4.0)
        } else {
          set_visibility(entity, false)
        }
      None => ()
    }
  }
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  if @raylib.is_key_pressed(@raylib.KeyEscape) {
    @system.exit()
    return
  }
  if @raylib.is_key_pressed(@raylib.KeyR) && game_phase.val == Playing {
    restart_level()
    return
  }
  handle_player_input()
  if @raylib.is_key_pressed(@raylib.KeyEnter) &&
    (game_phase.val == Won || game_phase.val == Lost) {
    restart_level(next_level=true)
  }
}

///|
pub fn update_system(_world : @ecs.World) -> Unit {
  if game_phase.val != Playing {
    return
  }
  update_player()
  update_enemies()
}

///|
fn camera_left_bound(level : LevelSpec) -> Double {
  let max_left = level.world_width - VIEWPORT_WIDTH
  if max_left < 0.0 {
    0.0
  } else {
    max_left
  }
}

///|
pub fn camera_system(_world : @ecs.World) -> Unit {
  match current_level.val {
    Some(level) => {
      let left = clamp_double(
        player_state.val.center[X] - VIEWPORT_WIDTH * 0.42,
        0.0,
        camera_left_bound(level),
      )
      let center = vec2(left + VIEWPORT_WIDTH * 0.5, CAMERA_TOP_LEFT_Y + VIEWPORT_HEIGHT * 0.5)
      @transform.transforms().set(camera_entity, @transform.Transform::from_xyz(center[X], center[Y], 999.0))
    }
    None => ()
  }
}

///|
pub fn sync_system(_world : @ecs.World) -> Unit {
  if player_state.val.alive {
    set_sprite_entity(
      player_entity,
      player_sprite_color,
      vec2(PLAYER_WIDTH, PLAYER_HEIGHT),
      player_state.val.center,
      5.0,
    )
    let mut player_visible = true
    if player_state.val.hurt_timer > 0.0 {
      let blink = (@cmath.floor(@time.elapsed() * 12.0).to_int() % 2) == 0
      player_visible = blink
    }
    set_visibility(player_entity, player_visible)
  } else {
    set_visibility(player_entity, false)
  }

  for entity in enemy_entities_order {
    match enemy_entities.get(entity) {
      Some(enemy) => {
        if enemy.alive {
          set_sprite_entity(
            entity,
            enemy_sprite_color,
            vec2(ENEMY_WIDTH, ENEMY_HEIGHT),
            enemy.center,
            4.0,
          )
        } else {
          set_visibility(entity, false)
        }
      }
      None => ()
    }
  }
}

///|
pub fn hud_system(_world : @ecs.World) -> Unit {
  match current_level.val {
    Some(level) => {
      let title = "SUPER MARIO  \{level.name}"
      let mode_text = match game_phase.val {
        Playing => "PLAYING"
        Won => "CLEAR"
        Lost => "HURT"
      }
      let sub = "LEVEL \{current_level_index.val + 1}/\{level_specs.length()}  ENEMIES \{enemy_entities.length()}  MODE \{mode_text}"
      let hint = "A/D or arrows: move  SPACE/UP: jump  R: restart  F3: FPS overlay  ESC: quit"
      @ui.texts().set(hud_title_entity, @ui.Text::new(title))
      @ui.texts().set(hud_sub_entity, @ui.Text::new(sub))
      @ui.texts().set(hud_hint_entity, @ui.Text::new(hint))
      if game_phase.val == Won {
        set_message_visible(true)
        @ui.texts().set(hud_message_entity, @ui.Text::new("STAGE CLEAR"))
      } else if game_phase.val == Lost {
        set_message_visible(true)
        @ui.texts().set(hud_message_entity, @ui.Text::new("TOUCHED! PRESS R OR ENTER"))
      } else {
        set_message_visible(false)
      }
      if debug_overlay.val {
        let fps = if @time.delta() > 0.0 {
          (1.0 / @time.delta()).to_int()
        } else {
          0
        }
        @ui.texts().set(
          hud_message_entity,
          @ui.Text::new(
            "FPS \{fps}  P=\{player_state.val.center}  LVL=\{current_level_index.val}",
          ),
        )
        set_message_visible(true)
      }
    }
    None => ()
  }
}

///|
pub fn capture_system(_world : @ecs.World) -> Unit {
  if !capture_enabled.val || capture_taken.val {
    return
  }
  if @time.elapsed() - capture_started_at.val < DEBUG_CAPTURE_DELAY_SECONDS {
    return
  }
  @raylib.take_screenshot(DEBUG_CAPTURE_PATH)
  capture_taken.val = true
  @system.exit()
}

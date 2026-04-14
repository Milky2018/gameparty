///|
fn rect_intersects(a : @math.Rect, b : @math.Rect) -> Bool {
  a.intersects(b)
}

///|
fn debug_vec2_string(value : @math.Vec2) -> String {
  "(\{value[X]}, \{value[Y]})"
}

///|
fn debug_transform_option_string(value : @transform.Transform?) -> String {
  match value {
    Some(transform) =>
      "translation=(\{transform.translation.x}, \{transform.translation.y}, \{transform.translation.z}) scale=(\{transform.scale.x}, \{transform.scale.y}, \{transform.scale.z})"
    None => "<none>"
  }
}

///|
fn debug_visibility_option_string(value : @visibility.Visibility?) -> String {
  match value {
    Some(Visible) => "Visible"
    Some(Hidden) => "Hidden"
    None => "<none>"
  }
}

///|
fn player_height() -> Double {
  if player_state.val.power == Small {
    PLAYER_HEIGHT_SMALL
  } else {
    PLAYER_HEIGHT_BIG
  }
}

///|
fn player_rect() -> @math.Rect {
  rect_from_center(player_state.val.center, vec2(PLAYER_WIDTH, player_height()))
}

///|
fn enemy_rect(enemy : EnemyState) -> @math.Rect {
  rect_from_center(enemy.center, vec2(ENEMY_WIDTH, ENEMY_HEIGHT))
}

///|
fn item_rect(item : ItemState) -> @math.Rect {
  rect_from_center(item.center, vec2(ITEM_WIDTH, ITEM_HEIGHT))
}

///|
fn fireball_rect(fireball : FireballState) -> @math.Rect {
  rect_from_center(fireball.center, vec2(FIREBALL_SIZE, FIREBALL_SIZE))
}

///|
fn block_rect(block : SolidBlock) -> @math.Rect {
  rect_from_center(block.base_center, block.size)
}

///|
fn block_is_solid(kind : TileKind) -> Bool {
  kind != UsedBlock && kind != Spike && kind != DashCrystal && kind != Spring
}

///|
fn block_is_hazard(kind : TileKind) -> Bool {
  kind == Spike
}

///|
fn block_is_dash_crystal(kind : TileKind) -> Bool {
  kind == DashCrystal
}

///|
fn block_is_spring(kind : TileKind) -> Bool {
  kind == Spring
}

///|
fn goal_rect(level : LevelSpec) -> @math.Rect {
  rect_from_center(level.goal_center, level.goal_size)
}

///|
fn player_touches_hazard(rect : @math.Rect) -> Bool {
  for block in solid_blocks {
    if !block_is_hazard(block.kind) {
      continue
    }
    if rect_intersects(rect, block_rect(block)) {
      return true
    }
  }
  false
}

///|
const MAX_SIM_DELTA_SECONDS : Double = 1.0 / 60.0

///|
fn sim_delta() -> Double {
  clamp_double(@time.delta(), 0.0, MAX_SIM_DELTA_SECONDS)
}

///|
fn update_dash_crystal_respawns(delta : Double) -> Unit {
  let expired : Array[Int] = []
  for idx, timer in dash_crystal_respawn_timers {
    let next_timer = timer - delta
    if next_timer <= 0.0 {
      expired.push(idx)
    } else {
      dash_crystal_respawn_timers.set(idx, next_timer)
    }
  }
  for idx in expired {
    dash_crystal_respawn_timers.remove(idx)
  }
}

///|
fn try_collect_dash_crystal(
  player_hitbox : @math.Rect,
  movement : MovementProfile,
) -> Unit {
  if movement.max_air_dashes <= 0 {
    return
  }
  for idx in 0..<solid_blocks.length() {
    let block = solid_blocks[idx]
    if !block_is_dash_crystal(block.kind) {
      continue
    }
    if dash_crystal_respawn_timers.get(idx) is Some(_) {
      continue
    }
    if !rect_intersects(player_hitbox, block_rect(block)) {
      continue
    }
    dash_crystal_respawn_timers.set(idx, DASH_CRYSTAL_RESPAWN_SECONDS)
    player_state.val.air_dashes_left = movement.max_air_dashes
    player_state.val.dash_cooldown_timer = 0.0
    player_state.val.wall_stamina = movement.wall_stamina_max
    if audio_bank.val is Some(bank) {
      play_sound(bank.collect)
    }
    break
  }
}

///|
fn try_trigger_spring(
  player_hitbox : @math.Rect,
  movement : MovementProfile,
) -> Unit {
  if player_state.val.spring_cooldown_timer > 0.0 {
    return
  }
  for block in solid_blocks {
    if !block_is_spring(block.kind) {
      continue
    }
    let spring_r = block_rect(block)
    if !rect_intersects(player_hitbox, spring_r) {
      continue
    }
    let player_bottom = player_hitbox.position[Y] + player_hitbox.size[Y]
    let spring_mid_y = spring_r.position[Y] + spring_r.size[Y] * 0.6
    if player_bottom > spring_mid_y {
      continue
    }
    player_state.val.velocity = player_state.val.velocity.update(
      Y,
      -movement.spring_boost_speed,
    )
    player_state.val.on_ground = false
    player_state.val.coyote_timer = 0.0
    player_state.val.jump_buffer = 0.0
    player_state.val.spring_cooldown_timer = PLAYER_SPRING_COOLDOWN_SECONDS
    if audio_bank.val is Some(bank) {
      play_sound(bank.jump)
    }
    break
  }
}

///|
fn movement_axis_resolution(
  rect : @math.Rect,
  delta : Double,
  solids : Array[SolidBlock],
  axis_x : Bool,
) -> (Double, Bool) {
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
    if !block_is_solid(block.kind) {
      continue
    }
    let block_r = block_rect(block)
    if rect_intersects(probe, block_r) {
      touching = true
      if delta > 0.0 {
        if axis_x {
          moved = block_r.position[X] - (rect.position[X] + rect.size[X])
        } else {
          moved = block_r.position[Y] - (rect.position[Y] + rect.size[Y])
        }
      } else if axis_x {
        moved = block_r.position[X] + block_r.size[X] - rect.position[X]
      } else {
        moved = block_r.position[Y] + block_r.size[Y] - rect.position[Y]
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
    let message = if new_phase == Won {
      "STAGE CLEAR"
    } else {
      "TOUCHED! PRESS R OR ENTER"
    }
    update_text_entity_if_changed(
      hud_message_entity, last_hud_message_text, message,
    )
  }
}

///|
fn restart_level(next_level? : Bool = false) -> Unit {
  if next_level {
    current_level_index.val = (current_level_index.val + 1) %
      level_specs.length()
  } else {
    player_state.val.power = Small
  }
  set_current_level(current_level_index.val)
  set_phase(Playing)
}

///|
fn enemy_should_turn(enemy : EnemyState, next_x : Double) -> Bool {
  next_x < enemy.patrol_left || next_x > enemy.patrol_right
}

///|
fn stomp_check(
  player_before : @math.Rect,
  player_after : @math.Rect,
  enemy : EnemyState,
) -> Bool {
  let enemy_r = enemy_rect(enemy)
  if !rect_intersects(player_after, enemy_r) {
    return false
  }
  if player_before.position[Y] + player_before.size[Y] <=
    enemy_r.position[Y] + 8.0 &&
    player_state.val.velocity[Y] >= 0.0 {
    return true
  }
  false
}

///|
fn kill_player() -> Unit {
  if player_state.val.hurt_timer > 0.0 ||
    player_state.val.startup_grace_timer > 0.0 {
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
fn damage_player() -> Unit {
  if player_state.val.hurt_timer > 0.0 ||
    player_state.val.startup_grace_timer > 0.0 {
    return
  }
  if player_state.val.power == Small {
    kill_player()
    return
  }
  player_state.val.power = Small
  player_state.val.hurt_timer = PLAYER_HURT_INVULN_SECONDS
  if audio_bank.val is Some(bank) {
    play_sound(bank.hit)
  }
}

///|
fn add_score(score : Int) -> Unit {
  player_state.val.score = player_state.val.score + score
}

///|
fn collect_coin() -> Unit {
  player_state.val.coin_count = player_state.val.coin_count + 1
  add_score(SCORE_COLLECT_COIN)
  if audio_bank.val is Some(bank) {
    play_sound(bank.collect)
  }
}

///|
fn apply_item_effect(kind : ItemKind) -> Unit {
  run_hook_on_item_collected(kind)
  match kind {
    Mushroom =>
      if player_state.val.power == Small {
        player_state.val.power = Big
      } else {
        add_score(SCORE_COLLECT_COIN)
      }
    FireFlower => player_state.val.power = Fire
    Coin => collect_coin()
  }
}

///|
fn spawn_block_payload(block : SolidBlock) -> Unit {
  match block.payload {
    Some(payload) =>
      if payload == Coin {
        collect_coin()
      } else {
        spawn_item(payload, block.base_center, emerging=true)
      }
    None => ()
  }
}

///|
fn try_activate_block_from_below(
  player_before : @math.Rect,
  player_after : @math.Rect,
) -> Unit {
  if player_state.val.velocity[Y] >= 0.0 {
    return
  }
  for idx in 0..<solid_blocks.length() {
    let block = solid_blocks[idx]
    if block.kind == UsedBlock {
      continue
    }
    let block_r = block_rect(block)
    if !rect_intersects(player_after, block_r) {
      continue
    }
    let block_bottom = block_r.position[Y] + block_r.size[Y]
    if player_before.position[Y] < block_bottom - 2.0 {
      continue
    }
    if player_before.position[X] + player_before.size[X] <= block_r.position[X] ||
      player_before.position[X] >= block_r.position[X] + block_r.size[X] {
      continue
    }
    spawn_block_payload(block)
    if block.kind == Brick ||
      block.kind == QuestionMushroom ||
      block.kind == QuestionFlower ||
      block.kind == QuestionCoin {
      block.kind = UsedBlock
      solid_blocks[idx] = block
    }
    player_state.val.velocity = player_state.val.velocity.update(Y, 0.0)
    break
  }
}

///|
fn try_shoot_fireball() -> Unit {
  if player_state.val.power != Fire ||
    player_state.val.fire_cooldown_timer > 0.0 {
    return
  }
  if fireball_entities.length() >= 4 {
    return
  }
  let height = player_height()
  let x_offset = if player_state.val.facing_right {
    PLAYER_WIDTH * 0.56
  } else {
    -PLAYER_WIDTH * 0.56
  }
  let center = vec2(
    player_state.val.center[X] + x_offset,
    player_state.val.center[Y] - height * 0.1,
  )
  spawn_player_fireball(center, player_state.val.facing_right)
  player_state.val.fire_cooldown_timer = PLAYER_FIRE_COOLDOWN_SECONDS
  if audio_bank.val is Some(bank) {
    play_sound(bank.shoot)
  }
}

///|
fn bounce_player_after_stomp() -> Unit {
  let movement = current_movement_profile()
  player_state.val.velocity = player_state.val.velocity.update(
    Y,
    -movement.jump_speed * 0.72,
  )
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
      add_score(SCORE_STOMP_ENEMY)
      run_hook_on_enemy_stomped(enemy.kind)
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
  let movement = current_movement_profile()
  let mut horizontal = 0.0
  if @raylib.is_key_down(@raylib.KeyA) || @raylib.is_key_down(@raylib.KeyLeft) {
    horizontal -= 1.0
  }
  if @raylib.is_key_down(@raylib.KeyD) || @raylib.is_key_down(@raylib.KeyRight) {
    horizontal += 1.0
  }
  if player_state.val.dash_timer <= 0.0 {
    player_state.val.velocity = player_state.val.velocity.update(
      X,
      horizontal * movement.move_speed,
    )
  }
  if horizontal < 0.0 {
    player_state.val.facing_right = false
  } else if horizontal > 0.0 {
    player_state.val.facing_right = true
  }
  if @raylib.is_key_pressed(@raylib.KeySpace) ||
    @raylib.is_key_pressed(@raylib.KeyUp) {
    player_state.val.jump_buffer = movement.jump_buffer
  } else {
    player_state.val.jump_buffer = clamp_double(
      player_state.val.jump_buffer - sim_delta(),
      0.0,
      movement.jump_buffer,
    )
  }
  if @raylib.is_key_pressed(@raylib.KeyF3) {
    debug_overlay.val = !debug_overlay.val
  }
  if @raylib.is_key_pressed(@raylib.KeyC) ||
    @raylib.is_key_pressed(@raylib.KeyLeftShift) {
    let can_dash = movement.max_air_dashes > 0 &&
      player_state.val.air_dashes_left > 0 &&
      player_state.val.dash_timer <= 0.0 &&
      player_state.val.dash_cooldown_timer <= 0.0
    if can_dash {
      let mut vertical = 0.0
      if @raylib.is_key_down(@raylib.KeyW) || @raylib.is_key_down(@raylib.KeyUp) {
        vertical -= 1.0
      }
      if @raylib.is_key_down(@raylib.KeyS) ||
        @raylib.is_key_down(@raylib.KeyDown) {
        vertical += 1.0
      }
      let mut direction = vec2(horizontal, vertical)
      if direction.distance() <= 0.0001 {
        direction = vec2(
          if player_state.val.facing_right {
            1.0
          } else {
            -1.0
          },
          0.0,
        )
      }
      direction = direction.normalize()
      player_state.val.dash_dir = direction
      player_state.val.dash_timer = movement.dash_duration
      player_state.val.dash_cooldown_timer = movement.dash_cooldown
      player_state.val.air_dashes_left = player_state.val.air_dashes_left - 1
      player_state.val.velocity = direction.scalar_mul(movement.dash_speed)
      player_state.val.on_ground = false
      player_state.val.coyote_timer = 0.0
      if direction[X] < -0.01 {
        player_state.val.facing_right = false
      } else if direction[X] > 0.01 {
        player_state.val.facing_right = true
      }
      if audio_bank.val is Some(bank) {
        play_sound(bank.jump)
      }
    }
  }
  if @raylib.is_key_pressed(@raylib.KeyX) ||
    @raylib.is_key_pressed(@raylib.KeyLeftControl) {
    try_shoot_fireball()
  }
  if @raylib.is_key_pressed(@raylib.KeyEnter) &&
    (game_phase.val == Won || game_phase.val == Lost) {
    restart_level(next_level=game_phase.val == Won)
  }
}

///|
fn update_player() -> Unit {
  if !player_state.val.alive {
    return
  }
  let movement = current_movement_profile()
  let delta = sim_delta()
  if player_state.val.startup_grace_timer > 0.0 {
    player_state.val.startup_grace_timer = clamp_double(
      player_state.val.startup_grace_timer - delta,
      0.0,
      PLAYER_STARTUP_GRACE_SECONDS,
    )
  }
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
      movement.coyote_time,
    )
  }
  if player_state.val.fire_cooldown_timer > 0.0 {
    player_state.val.fire_cooldown_timer = clamp_double(
      player_state.val.fire_cooldown_timer - delta,
      0.0,
      PLAYER_FIRE_COOLDOWN_SECONDS,
    )
  }
  if player_state.val.spring_cooldown_timer > 0.0 {
    player_state.val.spring_cooldown_timer = clamp_double(
      player_state.val.spring_cooldown_timer - delta,
      0.0,
      PLAYER_SPRING_COOLDOWN_SECONDS,
    )
  }
  if player_state.val.dash_cooldown_timer > 0.0 {
    player_state.val.dash_cooldown_timer = clamp_double(
      player_state.val.dash_cooldown_timer - delta,
      0.0,
      movement.dash_cooldown,
    )
  }
  if player_state.val.dash_timer > 0.0 {
    player_state.val.dash_timer = clamp_double(
      player_state.val.dash_timer - delta,
      0.0,
      movement.dash_duration,
    )
  }
  if player_state.val.on_ground {
    player_state.val.air_dashes_left = movement.max_air_dashes
    player_state.val.wall_stamina = movement.wall_stamina_max
  }
  let pre_rect = player_rect()
  let is_dashing = player_state.val.dash_timer > 0.0
  if is_dashing {
    player_state.val.velocity = player_state.val.dash_dir.scalar_mul(
      movement.dash_speed,
    )
  } else {
    player_state.val.velocity = player_state.val.velocity.update(
      Y,
      clamp_double(
        player_state.val.velocity[Y] + movement.gravity * delta,
        -2000.0,
        movement.max_fall_speed,
      ),
    )
  }
  if player_state.val.jump_buffer > 0.0 && !is_dashing {
    let mut jumped = false
    if player_state.val.on_ground || player_state.val.coyote_timer > 0.0 {
      player_state.val.velocity = player_state.val.velocity.update(
        Y,
        -movement.jump_speed,
      )
      jumped = true
    } else if movement.allow_wall_jump &&
      player_state.val.wall_contact_dir != 0 &&
      player_state.val.wall_stamina >= movement.wall_jump_stamina_cost {
      player_state.val.velocity = vec2(
        movement.wall_jump_speed_x *
        player_state.val.wall_contact_dir.to_double(),
        -movement.wall_jump_speed_y,
      )
      if player_state.val.wall_contact_dir > 0 {
        player_state.val.facing_right = true
      } else {
        player_state.val.facing_right = false
      }
      jumped = true
    }
    if jumped {
      player_state.val.on_ground = false
      player_state.val.jump_buffer = 0.0
      player_state.val.coyote_timer = 0.0
      if movement.allow_wall_jump &&
        player_state.val.wall_contact_dir != 0 &&
        movement.wall_jump_stamina_cost > 0.0 {
        player_state.val.wall_stamina = clamp_double(
          player_state.val.wall_stamina - movement.wall_jump_stamina_cost,
          0.0,
          movement.wall_stamina_max,
        )
      }
      player_state.val.wall_contact_dir = 0
      if audio_bank.val is Some(bank) {
        play_sound(bank.jump)
      }
    }
  }
  let x_rect = pre_rect
  let requested_dx = player_state.val.velocity[X] * delta
  let (dx, _) = movement_axis_resolution(
    x_rect, requested_dx, solid_blocks, true,
  )
  player_state.val.center = player_state.val.center.update(
    X,
    player_state.val.center[X] + dx,
  )
  if dx != requested_dx {
    if requested_dx > 0.0 {
      player_state.val.wall_contact_dir = -1
    } else if requested_dx < 0.0 {
      player_state.val.wall_contact_dir = 1
    }
    if player_state.val.dash_timer > 0.0 {
      player_state.val.dash_timer = 0.0
    }
    player_state.val.velocity = player_state.val.velocity.update(X, 0.0)
  } else {
    player_state.val.wall_contact_dir = 0
  }
  let after_x_rect = rect_from_center(
    player_state.val.center,
    vec2(PLAYER_WIDTH, player_height()),
  )
  let requested_dy = player_state.val.velocity[Y] * delta
  let (dy, hit_ground) = movement_axis_resolution(
    after_x_rect, requested_dy, solid_blocks, false,
  )
  player_state.val.center = player_state.val.center.update(
    Y,
    player_state.val.center[Y] + dy,
  )
  let post_move_rect = player_rect()
  try_activate_block_from_below(pre_rect, post_move_rect)
  if hit_ground && player_state.val.velocity[Y] > 0.0 {
    player_state.val.on_ground = true
    player_state.val.coyote_timer = movement.coyote_time
    player_state.val.air_dashes_left = movement.max_air_dashes
  } else if !hit_ground {
    player_state.val.on_ground = false
  }
  if dy != requested_dy {
    if player_state.val.velocity[Y] > 0.0 {
      player_state.val.on_ground = true
      player_state.val.coyote_timer = movement.coyote_time
      player_state.val.air_dashes_left = movement.max_air_dashes
    }
    if player_state.val.dash_timer > 0.0 {
      player_state.val.dash_timer = 0.0
    }
    player_state.val.velocity = player_state.val.velocity.update(Y, 0.0)
  }
  if movement.allow_wall_jump &&
    !player_state.val.on_ground &&
    player_state.val.wall_contact_dir != 0 &&
    player_state.val.velocity[Y] > movement.wall_slide_speed &&
    player_state.val.wall_stamina > 0.0 &&
    player_state.val.dash_timer <= 0.0 {
    player_state.val.velocity = player_state.val.velocity.update(
      Y,
      movement.wall_slide_speed,
    )
    player_state.val.wall_stamina = clamp_double(
      player_state.val.wall_stamina -
      movement.wall_stamina_drain_per_second * delta,
      0.0,
      movement.wall_stamina_max,
    )
  }
  let now_rect = player_rect()
  try_collect_dash_crystal(now_rect, movement)
  try_trigger_spring(now_rect, movement)
  if player_touches_hazard(now_rect) {
    kill_player()
    return
  }
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
          damage_player()
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
          add_score(SCORE_HIT_GOAL)
          run_hook_on_level_won(current_level_index.val)
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
  let delta = sim_delta()
  for entity in enemy_entities_order {
    match enemy_entities.get(entity) {
      Some(enemy) => {
        if !enemy.alive {
          continue
        }
        enemy.velocity = enemy.velocity.update(
          Y,
          clamp_double(
            enemy.velocity[Y] + ENEMY_GRAVITY * delta,
            -2000.0,
            ENEMY_MAX_FALL_SPEED,
          ),
        )
        enemy.velocity = enemy.velocity.update(
          X,
          if enemy.facing_right {
            if enemy.kind == Koopa {
              ENEMY_MOVE_SPEED * 0.82
            } else {
              ENEMY_MOVE_SPEED
            }
          } else if enemy.kind == Koopa {
            -ENEMY_MOVE_SPEED * 0.82
          } else {
            -ENEMY_MOVE_SPEED
          },
        )
        let start_rect = enemy_rect(enemy)
        let (dx, hit_wall_x) = movement_axis_resolution(
          start_rect,
          enemy.velocity[X] * delta,
          solid_blocks,
          true,
        )
        enemy.center = enemy.center.update(X, enemy.center[X] + dx)
        let moved_rect = rect_from_center(
          enemy.center,
          vec2(ENEMY_WIDTH, ENEMY_HEIGHT),
        )
        let (dy, _hit_wall_y) = movement_axis_resolution(
          moved_rect,
          enemy.velocity[Y] * delta,
          solid_blocks,
          false,
        )
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
          vec2(
            if enemy.facing_right {
              pos[X] + ENEMY_WIDTH * 0.55
            } else {
              pos[X] - ENEMY_WIDTH * 0.55
            },
            pos[Y] + ENEMY_HEIGHT * 0.6,
          ),
          vec2(10.0, 10.0),
        )
        let mut has_ground_ahead = false
        for block in solid_blocks {
          if !block_is_solid(block.kind) {
            continue
          }
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
      None => ()
    }
  }
}

///|
fn update_items() -> Unit {
  if game_phase.val != Playing {
    return
  }
  let delta = sim_delta()
  let player_hitbox = player_rect()
  for entity in item_entities_order {
    match item_entities.get(entity) {
      Some(item) => {
        if !item.alive {
          continue
        }
        if item.emerging {
          let next_y = item.center[Y] - 96.0 * delta
          if next_y <= item.emerge_target_y {
            item.center = item.center.update(Y, item.emerge_target_y)
            item.emerging = false
            if item.kind == Mushroom {
              item.velocity = item.velocity.update(X, ITEM_MOVE_SPEED)
            } else {
              item.velocity = @math.Vec2::zero()
            }
          } else {
            item.center = item.center.update(Y, next_y)
          }
          item_entities.set(entity, item)
          continue
        }
        if item.kind == Coin {
          item.alive = false
          item_entities.set(entity, item)
          set_visibility(entity, false)
          continue
        }
        item.velocity = item.velocity.update(
          Y,
          clamp_double(
            item.velocity[Y] + ITEM_GRAVITY * delta,
            -2000.0,
            PLAYER_MAX_FALL_SPEED,
          ),
        )
        let item_start = item_rect(item)
        let (dx, hit_x) = movement_axis_resolution(
          item_start,
          item.velocity[X] * delta,
          solid_blocks,
          true,
        )
        item.center = item.center.update(X, item.center[X] + dx)
        if hit_x {
          item.velocity = item.velocity.update(X, -item.velocity[X])
        }
        let moved_rect = item_rect(item)
        let (dy, hit_y) = movement_axis_resolution(
          moved_rect,
          item.velocity[Y] * delta,
          solid_blocks,
          false,
        )
        item.center = item.center.update(Y, item.center[Y] + dy)
        if hit_y {
          item.velocity = item.velocity.update(Y, 0.0)
        }
        let overlap_player = rect_intersects(item_rect(item), player_hitbox)
        if overlap_player {
          apply_item_effect(item.kind)
          item.alive = false
          set_visibility(entity, false)
        }
        item_entities.set(entity, item)
      }
      None => ()
    }
  }
}

///|
fn update_fireballs() -> Unit {
  if game_phase.val != Playing {
    return
  }
  let delta = sim_delta()
  for entity in fireball_entities_order {
    match fireball_entities.get(entity) {
      Some(fireball) => {
        if !fireball.alive {
          continue
        }
        fireball.lifetime = fireball.lifetime - delta
        if fireball.lifetime <= 0.0 {
          fireball.alive = false
          fireball_entities.set(entity, fireball)
          set_visibility(entity, false)
          continue
        }
        fireball.velocity = fireball.velocity.update(
          Y,
          clamp_double(
            fireball.velocity[Y] + FIREBALL_GRAVITY * delta,
            -2000.0,
            PLAYER_MAX_FALL_SPEED,
          ),
        )
        let start_rect = fireball_rect(fireball)
        let (dx, hit_x) = movement_axis_resolution(
          start_rect,
          fireball.velocity[X] * delta,
          solid_blocks,
          true,
        )
        fireball.center = fireball.center.update(X, fireball.center[X] + dx)
        if hit_x {
          fireball.alive = false
          fireball_entities.set(entity, fireball)
          set_visibility(entity, false)
          continue
        }
        let moved_rect = fireball_rect(fireball)
        let (dy, hit_y) = movement_axis_resolution(
          moved_rect,
          fireball.velocity[Y] * delta,
          solid_blocks,
          false,
        )
        fireball.center = fireball.center.update(Y, fireball.center[Y] + dy)
        if hit_y && fireball.velocity[Y] > 0.0 {
          fireball.velocity = fireball.velocity.update(
            Y,
            -FIREBALL_BOUNCE_VELOCITY,
          )
        }
        let mut hit_enemy = false
        for enemy_entity in enemy_entities_order {
          match enemy_entities.get(enemy_entity) {
            Some(enemy) => {
              if !enemy.alive {
                continue
              }
              if rect_intersects(fireball_rect(fireball), enemy_rect(enemy)) {
                enemy.alive = false
                enemy_entities.set(enemy_entity, enemy)
                set_visibility(enemy_entity, false)
                add_score(SCORE_STOMP_ENEMY)
                hit_enemy = true
                break
              }
            }
            None => ()
          }
        }
        if hit_enemy {
          fireball.alive = false
          set_visibility(entity, false)
        }
        fireball_entities.set(entity, fireball)
      }
      None => ()
    }
  }
}

///|
fn input_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
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
    restart_level(next_level=game_phase.val == Won)
  }
  profile_phase("input", started_at)
}

///|
fn update_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  if game_phase.val != Playing {
    return
  }
  update_dash_crystal_respawns(sim_delta())
  update_player()
  update_enemies()
  update_items()
  update_fireballs()
  profile_phase("update", started_at)
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
fn camera_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  match current_level.val {
    Some(level) => {
      let left = clamp_double(
        player_state.val.center[X] - VIEWPORT_WIDTH * 0.42,
        0.0,
        camera_left_bound(level),
      )
      let center = vec2(
        left + VIEWPORT_WIDTH * 0.5,
        CAMERA_TOP_LEFT_Y + VIEWPORT_HEIGHT * 0.5,
      )
      @transform.transforms().set(
        camera_entity,
        @transform.Transform::from_xyz(center[X], center[Y], 999.0),
      )
    }
    None => ()
  }
  profile_phase("camera", started_at)
}

///|
const PLAYER_ANIM_FPS : Double = 10.0

///|
const ENEMY_ANIM_FPS : Double = 8.0

///|
fn animated_region(
  regions : Array[SpriteRegion]?,
  fps : Double,
  phase_offset? : Double = 0.0,
) -> SpriteRegion? {
  match regions {
    Some(frames) =>
      if frames.length() == 0 {
        None
      } else {
        let frame_index = @cmath.floor(@time.elapsed() * fps + phase_offset).to_int() %
          frames.length()
        Some(frames[frame_index])
      }
    None => None
  }
}

///|
fn player_visual_region() -> (SpriteRegion?, Bool) {
  let flip_x = !player_state.val.facing_right
  let speed_x = player_state.val.velocity[X]
  let moving_speed = if speed_x < 0.0 { -speed_x } else { speed_x }
  let moving = moving_speed > 8.0
  if moving {
    match animated_region(sprite_regions_for_player_run(), PLAYER_ANIM_FPS) {
      Some(region) => (Some(region), flip_x)
      None => (sprite_region_for_player_idle(), flip_x)
    }
  } else {
    (sprite_region_for_player_idle(), flip_x)
  }
}

///|
fn enemy_visual_region(enemy : EnemyState) -> (SpriteRegion?, Bool) {
  let flip_x = !enemy.facing_right
  let phase = enemy.center[X] * 0.03125
  (
    animated_region(
      sprite_regions_for_enemy(enemy.kind),
      ENEMY_ANIM_FPS,
      phase_offset=phase,
    ),
    flip_x,
  )
}

///|
fn same_lane(a : Double, b : Double) -> Bool {
  let diff = a - b
  if diff < 0.0 {
    -diff < 0.01
  } else {
    diff < 0.01
  }
}

///|
fn has_pipe_above(idx : Int) -> Bool {
  let block = solid_blocks[idx]
  let target_y = block.base_center[Y] - block.size[Y]
  for check_idx in 0..<solid_blocks.length() {
    if check_idx == idx {
      continue
    }
    let candidate = solid_blocks[check_idx]
    if candidate.kind != Pipe {
      continue
    }
    if same_lane(candidate.base_center[X], block.base_center[X]) &&
      same_lane(candidate.base_center[Y], target_y) {
      return true
    }
  }
  false
}

///|
fn sprite_region_for_block(idx : Int, block : SolidBlock) -> SpriteRegion? {
  if block.kind == Pipe {
    if has_pipe_above(idx) {
      return sprite_region_for_pipe_body()
    }
    return sprite_region_for_tile(Pipe)
  }
  sprite_region_for_tile(block.kind)
}

///|
fn sync_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  for idx in 0..<solid_blocks.length() {
    if idx >= block_entities.length() {
      continue
    }
    let block = solid_blocks[idx]
    let entity = block_entities[idx]
    if block_is_dash_crystal(block.kind) &&
      dash_crystal_respawn_timers.get(idx) is Some(_) {
      set_visibility(entity, false)
      continue
    }
    set_sprite_entity_with_image(
      entity,
      sprite_region_for_block(idx, block),
      block_color(block.kind),
      block.size,
      block.base_center,
      0.0,
    )
  }
  if player_state.val.alive {
    let player_color = match player_state.val.power {
      Small => player_sprite_color
      Big => rgb(64U, 138U, 236U)
      Fire => rgb(255U, 191U, 103U)
    }
    let (player_region, player_flip_x) = player_visual_region()
    set_sprite_entity_with_image(
      player_entity,
      player_region,
      player_color,
      vec2(PLAYER_WIDTH, player_height()),
      player_state.val.center,
      5.0,
      flip_x=player_flip_x,
    )
    let mut player_visible = true
    if player_state.val.hurt_timer > 0.0 {
      let blink = @cmath.floor(@time.elapsed() * 12.0).to_int() % 2 == 0
      player_visible = blink
    }
    set_visibility(player_entity, player_visible)
  } else {
    set_visibility(player_entity, false)
  }

  for entity in enemy_entities_order {
    match enemy_entities.get(entity) {
      Some(enemy) =>
        if enemy.alive {
          let (enemy_region, enemy_flip_x) = enemy_visual_region(enemy)
          set_sprite_entity_with_image(
            entity,
            enemy_region,
            enemy_color(enemy.kind),
            vec2(ENEMY_WIDTH, ENEMY_HEIGHT),
            enemy.center,
            4.0,
            flip_x=enemy_flip_x,
          )
        } else {
          set_visibility(entity, false)
        }
      None => ()
    }
  }
  for entity in item_entities_order {
    match item_entities.get(entity) {
      Some(item) =>
        if item.alive {
          set_sprite_entity(
            entity,
            item_color(item.kind),
            vec2(ITEM_WIDTH, ITEM_HEIGHT),
            item.center,
            4.5,
          )
        } else {
          set_visibility(entity, false)
        }
      None => ()
    }
  }
  for entity in fireball_entities_order {
    match fireball_entities.get(entity) {
      Some(fireball) =>
        if fireball.alive {
          set_sprite_entity(
            entity,
            fireball_color,
            vec2(FIREBALL_SIZE, FIREBALL_SIZE),
            fireball.center,
            4.6,
          )
        } else {
          set_visibility(entity, false)
        }
      None => ()
    }
  }
  profile_phase("sync", started_at)
}

///|
fn hud_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  match current_level.val {
    Some(level) => {
      let movement = current_movement_profile()
      let title = "\{current_plugin().ui_theme.title}  \{level.name}"
      let mode_text = match game_phase.val {
        Playing => "PLAYING"
        Won => "CLEAR"
        Lost => "HURT"
      }
      let power_text = match player_state.val.power {
        Small => "SMALL"
        Big => "BIG"
        Fire => "FIRE"
      }
      let dash_text = if movement.max_air_dashes > 0 {
        "  DASH \{player_state.val.air_dashes_left}/\{movement.max_air_dashes}"
      } else {
        ""
      }
      let wall_text = if movement.allow_wall_jump {
        "  WALL \{@cmath.floor(player_state.val.wall_stamina).to_int()}"
      } else {
        ""
      }
      let sub = "LEVEL \{current_level_index.val + 1}/\{level_specs.length()}  ENEMIES \{alive_enemy_count()}  MODE \{mode_text}  POWER \{power_text}  COINS \{player_state.val.coin_count}  SCORE \{player_state.val.score}\{dash_text}\{wall_text}"
      let hint = current_plugin().ui_theme.hud_hint
      update_text_entity_if_changed(
        hud_title_entity, last_hud_title_text, title,
      )
      update_text_entity_if_changed(hud_sub_entity, last_hud_sub_text, sub)
      update_text_entity_if_changed(hud_hint_entity, last_hud_hint_text, hint)
      if game_phase.val == Won {
        set_message_visible(true)
        update_text_entity_if_changed(
          hud_message_entity, last_hud_message_text, "STAGE CLEAR",
        )
      } else if game_phase.val == Lost {
        set_message_visible(true)
        update_text_entity_if_changed(
          hud_message_entity, last_hud_message_text, "TOUCHED! PRESS R OR ENTER",
        )
      } else {
        set_message_visible(false)
      }
      if debug_overlay.val {
        let fps = if @time.delta() > 0.0 {
          (1.0 / @time.delta()).to_int()
        } else {
          0
        }
        update_text_entity_if_changed(
          hud_message_entity,
          last_hud_message_text,
          "FPS \{fps}  P=\{debug_vec2_string(player_state.val.center)}  LVL=\{current_level_index.val}",
        )
        set_message_visible(true)
      }
    }
    None => ()
  }
  profile_phase("hud", started_at)
  let frame_dt = @time.delta()
  profile_frame_count.val = profile_frame_count.val + 1
  if frame_dt > profile_slowest_frame.val {
    profile_slowest_frame.val = frame_dt
  }
  maybe_report_profile()
}

///|
fn capture_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  if !capture_enabled.val || capture_taken.val {
    return
  }
  if @time.elapsed() - capture_started_at.val < DEBUG_CAPTURE_DELAY_SECONDS {
    return
  }
  let player_transform = @transform.transforms().get(player_entity)
  let has_player_sprite = @sprite.sprites().contains(player_entity)
  let player_visibility = @visibility.visibilities().get(player_entity)
  let player_transform_text = debug_transform_option_string(player_transform)
  let player_visibility_text = debug_visibility_option_string(player_visibility)
  let sprite_entries = @runtime_debug.sprite_inspector_entries()
  let seen_signatures : Map[String, Bool] = Map::new()
  let mut printed = 0
  for entry in sprite_entries {
    if printed >= 32 {
      break
    }
    match entry.image_path {
      Some(path) =>
        if path.contains("supermario/sfc/") {
          let source_rect_signature = match entry.source_rect {
            Some(rect) => rect.to_json().to_string()
            None => "none"
          }
          let signature = path + "|" + source_rect_signature
          if !seen_signatures.contains(signature) {
            seen_signatures.set(signature, true)
            println("[platformer][sprite] \{entry.to_json().to_string()}")
            printed = printed + 1
          }
        }
      None => ()
    }
  }
  println(
    "[platformer][capture] player_alive=\{player_state.val.alive} player_center=\{debug_vec2_string(player_state.val.center)} has_sprite=\{has_player_sprite} transform=\{player_transform_text} visibility=\{player_visibility_text}",
  )
  let debug_capture_path = "/tmp/platformer_capture.png"
  let captured = @runtime_debug.capture_frame_png_to_file(debug_capture_path)
  if !captured {
    @raylib.take_screenshot(DEBUG_CAPTURE_PATH)
    println(
      "[platformer][capture] path=\{DEBUG_CAPTURE_PATH} (raylib fallback)",
    )
  } else {
    println("[platformer][capture] path=\{debug_capture_path} (runtime_debug)")
  }
  capture_taken.val = true
  profile_phase("capture", started_at)
  @system.exit()
}

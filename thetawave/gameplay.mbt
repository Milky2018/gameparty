///|
fn menu_state_system(_delta : Double) -> Unit {
  match game_state.screen {
    MainMenu =>
      if @inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space) {
        enter_character_selection()
      }
    CharacterSelection => {
      if @inputs.is_just_pressed(KeyA) || @inputs.is_just_pressed(ArrowLeft) {
        game_state.selected_character = Captain
      }
      if @inputs.is_just_pressed(KeyD) || @inputs.is_just_pressed(ArrowRight) {
        game_state.selected_character = Juggernaut
      }
      if @inputs.is_just_pressed(Escape) {
        enter_main_menu()
      } else if @inputs.is_just_pressed(Enter) {
        start_game_with_selected_character()
      }
    }
    InGame =>
      if game_state.phase is GameOver || game_state.phase is Victory {
        if @inputs.is_just_pressed(Enter) {
          enter_character_selection()
        } else if @inputs.is_just_pressed(Escape) {
          enter_main_menu()
        }
      } else if game_state.phase is Paused {
        if @inputs.is_just_pressed(Escape) || @inputs.is_just_pressed(Enter) {
          game_state.phase = Playing
        } else if @inputs.is_just_pressed(KeyR) {
          enter_main_menu()
        }
      } else if @inputs.is_just_pressed(Escape) {
        game_state.phase = Paused
      }
  }
}

///|
fn player_input_system(delta : Double) -> Unit {
  guard is_run_playing() else { return }
  guard game_state.allow_move else { return }
  if game_state.charge_time_left > 0.0 {
    return
  }
  guard @transform.positions.get(game_state.player) is Some(player_position)

  let wasd = @inputs.key_vector(KeyW, KeyS, KeyA, KeyD)
  let arrows = @inputs.key_vector(ArrowUp, ArrowDown, ArrowLeft, ArrowRight)
  let direction = (wasd + arrows).normalize()
  let next = player_position.0 +
    direction.scalar_mul(game_state.player_speed * delta)
  @transform.positions.set(
    game_state.player,
    @math.Vec2D(
      clamp(next[X], PLAYER_HALF_SIZE, VIEWPORT_WIDTH - PLAYER_HALF_SIZE),
      clamp(next[Y], PLAYER_HALF_SIZE, VIEWPORT_HEIGHT - PLAYER_HALF_SIZE),
    ),
  )
}

///|
fn player_shoot_system(delta : Double) -> Unit {
  guard is_run_playing() else { return }
  guard game_state.allow_main_attack else { return }
  if game_state.shoot_cooldown > 0.0 {
    game_state.shoot_cooldown -= delta
  }
  let fire_pressed = @inputs.is_pressed(Space) || @inputs.is_mouse_pressed(Left)
  if game_state.shoot_cooldown <= 0.0 && fire_pressed {
    spawn_player_burst()
    game_state.shoot_cooldown = current_shoot_interval()
  }
}

///|
fn player_special_system(delta : Double) -> Unit {
  guard is_run_playing() else { return }
  guard game_state.allow_special else { return }
  if game_state.special_cooldown > 0.0 {
    game_state.special_cooldown -= delta
  }
  let special_pressed = @inputs.is_just_pressed(KeyQ) ||
    @inputs.is_mouse_just_pressed(Right)
  if game_state.special_cooldown <= 0.0 && special_pressed {
    trigger_special_ability()
    game_state.special_cooldown = special_cooldown_duration()
  }
}

///|
fn trigger_special_ability() -> Unit {
  match game_state.special_ability {
    MegaBlast => trigger_mega_blast()
    Charge => trigger_charge()
  }
}

///|
fn trigger_mega_blast() -> Unit {
  guard @transform.positions.get(game_state.player) is Some(player_position)
  let base = @math.Vec2D(
    player_position.0[X],
    player_position.0[Y] - PLAYER_HALF_SIZE - 2.0,
  )
  let count = @cmp.maximum(
    1,
    @cmath.round(game_state.projectile_count.to_double() * 0.5).to_int(),
  )
  let spread = 1.5708
  for i in 0..<count {
    let t = if count <= 1 {
      0.5
    } else {
      i.to_double() / (count - 1).to_double()
    }
    let angle = -1.5708 + (t - 0.5) * spread
    let velocity = @math.Vec2D(
      @cmath.cos(angle) * game_state.projectile_speed * 2.0,
      @cmath.sin(angle) * game_state.projectile_speed * 2.0,
    )
    spawn_player_projectile(
      base + @math.Vec2D((t - 0.5) * 18.0, 0.0),
      velocity,
      @cmath.round(game_state.projectile_damage.to_double() * 3.0).to_int(),
      Blast,
      game_state.projectile_ttl,
    )
  }
  @audio.play_audio(SFX_MEGABLAST, volume=0.35)
}

///|
fn trigger_charge() -> Unit {
  guard @transform.positions.get(game_state.player) is Some(_player_position)
  let wasd = @inputs.key_vector(KeyW, KeyS, KeyA, KeyD)
  let arrows = @inputs.key_vector(ArrowUp, ArrowDown, ArrowLeft, ArrowRight)
  let input_dir = (wasd + arrows).normalize()
  let direction = if input_dir.distance() <= 0.0001 {
    @math.Vec2D(0.0, -1.0)
  } else {
    input_dir
  }
  game_state.charge_time_left = 0.50
  game_state.charge_velocity = direction.scalar_mul(520.0)
  game_state.player_invulnerable = 0.50
  @audio.play_audio(SFX_MEGABLAST, volume=0.20)
}

///|
fn enemy_spawn_system(delta : Double) -> Unit {
  guard is_run_playing() else { return }
  update_stage_progress(delta)
  guard current_stage() is Some(stage) else { return }

  game_state.stage_spawn_timer -= delta
  match stage.kind {
    Formation =>
      while game_state.stage_spawn_timer <= 0.0 {
        let next_period = spawn_random_formation(stage)
        game_state.stage_spawn_timer += next_period
      }
    Boss => spawn_boss_for_stage(stage)
    Tutorial =>
      if tick_tutorial(delta) {
        game_state.stage_index += 1
        enter_stage()
      }
    Break => ()
  }
}

///|
fn spawn_boss_for_stage(stage : RunStage) -> Unit {
  if game_state.boss_spawned || game_state.stage_spawn_timer > 0.0 {
    return
  }
  if stage.boss_kind is Some(boss_kind) &&
    stage.boss_world_pos is Some(world_pos) {
    spawn_enemy(boss_kind, spawn_from_world_for(boss_kind, world_pos))
    game_state.boss_spawned = true
  } else {
    // Advance safely if stage data is incomplete.
    game_state.boss_spawned = true
  }
}

///|
fn spawn_random_formation(stage : RunStage) -> Double {
  if stage.formations.length() == 0 {
    return 1.0
  }

  let mut total_weight = 0.0
  for formation in stage.formations {
    total_weight += @cmp.maximum(0.0, formation.weight)
  }
  if total_weight <= 0.0 {
    return 1.0
  }

  let mut roll = game_state.rand.double() * total_weight
  let mut selected = stage.formations[0]
  for formation in stage.formations {
    roll -= @cmp.maximum(0.0, formation.weight)
    if roll <= 0.0 {
      selected = formation
      break
    }
  }

  let formation = selected
  for mob in formation.members {
    spawn_enemy(mob.kind, spawn_from_world_for(mob.kind, mob.world_pos))
  }
  formation.period
}

///|
fn update_stage_progress(delta : Double) -> Unit {
  guard current_stage() is Some(stage) else { return }
  game_state.stage_elapsed += delta
  match stage.kind {
    Formation | Break =>
      if game_state.stage_elapsed >= stage.duration {
        game_state.stage_index += 1
        enter_stage()
      }
    Tutorial => ()
    Boss => {
      if !game_state.boss_spawned {
        return
      }
      if stage.boss_kind is Some(boss_kind) {
        if has_enemy_kind(boss_kind) || enemies.length() > 0 {
          return
        }
      } else if game_state.stage_elapsed < stage.duration {
        return
      }
      game_state.stage_index += 1
      enter_stage()
    }
  }
}

///|
const TUTORIAL_DIRECTION_SECONDS : Double = 0.35

///|
const TUTORIAL_SPAWN_DELAY_SECONDS : Double = 0.45

///|
fn refresh_cooldown_multiplier() -> Unit {
  let base = game_state.base_cooldown_multiplier
  let money_term = @cmath.exp(-0.1 * game_state.money.to_double())
  game_state.cooldown_multiplier = 1.0 + (base - 1.0) * money_term
}

///|
fn reset_tutorial_lesson() -> Unit {
  game_state.tutorial_lesson = 0
  game_state.tutorial_up_progress = 0.0
  game_state.tutorial_down_progress = 0.0
  game_state.tutorial_left_progress = 0.0
  game_state.tutorial_right_progress = 0.0
  game_state.tutorial_up_left_progress = 0.0
  game_state.tutorial_up_right_progress = 0.0
  game_state.tutorial_down_left_progress = 0.0
  game_state.tutorial_down_right_progress = 0.0
  game_state.tutorial_slot1_destroy = 3
  game_state.tutorial_slot1_protect = 2
  game_state.tutorial_slot2_destroy = 2
  game_state.tutorial_spawn_timer = 0.0
  game_state.allow_move = true
  game_state.allow_main_attack = false
  game_state.allow_special = false
}

///|
fn begin_tutorial_lesson(lesson : Int) -> Unit {
  clear_dynamic_entities()
  game_state.tutorial_lesson = lesson
  game_state.tutorial_spawn_timer = 0.0
  match lesson {
    0 => {
      game_state.allow_move = true
      game_state.allow_main_attack = false
      game_state.allow_special = false
    }
    1 => {
      game_state.allow_move = true
      game_state.allow_main_attack = true
      game_state.allow_special = false
      game_state.tutorial_slot1_destroy = 3
      game_state.tutorial_slot1_protect = 2
      game_state.tutorial_spawn_timer = TUTORIAL_SPAWN_DELAY_SECONDS
    }
    2 => {
      game_state.allow_move = true
      game_state.allow_main_attack = false
      game_state.allow_special = true
      game_state.tutorial_slot2_destroy = 2
      game_state.tutorial_spawn_timer = TUTORIAL_SPAWN_DELAY_SECONDS
    }
    _ => {
      game_state.allow_move = true
      game_state.allow_main_attack = true
      game_state.allow_special = true
    }
  }
}

///|
fn spawn_tutorial_enemy(kind : EnemyKind) -> Unit {
  let radius = enemy_radius(kind)
  let x = game_state.rand.double() * (VIEWPORT_WIDTH - 2.0 * radius) + radius
  spawn_enemy(kind, @math.Vec2D(x, -radius - 6.0))
}

///|
fn tick_tutorial(delta : Double) -> Bool {
  match game_state.tutorial_lesson {
    0 => if tick_tutorial_movement(delta) { begin_tutorial_lesson(1) }
    1 => if tick_tutorial_slot1(delta) { begin_tutorial_lesson(2) }
    2 =>
      if tick_tutorial_slot2(delta) {
        clear_dynamic_entities()
        game_state.allow_move = true
        game_state.allow_main_attack = true
        game_state.allow_special = true
        return true
      }
    _ => ()
  }
  false
}

///|
fn tick_tutorial_movement(delta : Double) -> Bool {
  let up = @inputs.is_pressed(KeyW) || @inputs.is_pressed(ArrowUp)
  let down = @inputs.is_pressed(KeyS) || @inputs.is_pressed(ArrowDown)
  let left = @inputs.is_pressed(KeyA) || @inputs.is_pressed(ArrowLeft)
  let right = @inputs.is_pressed(KeyD) || @inputs.is_pressed(ArrowRight)

  if up && !down && !left && !right {
    game_state.tutorial_up_progress = clamp(
      game_state.tutorial_up_progress + delta,
      0.0,
      TUTORIAL_DIRECTION_SECONDS,
    )
  } else if !up && down && !left && !right {
    game_state.tutorial_down_progress = clamp(
      game_state.tutorial_down_progress + delta,
      0.0,
      TUTORIAL_DIRECTION_SECONDS,
    )
  } else if !up && !down && left && !right {
    game_state.tutorial_left_progress = clamp(
      game_state.tutorial_left_progress + delta,
      0.0,
      TUTORIAL_DIRECTION_SECONDS,
    )
  } else if !up && !down && !left && right {
    game_state.tutorial_right_progress = clamp(
      game_state.tutorial_right_progress + delta,
      0.0,
      TUTORIAL_DIRECTION_SECONDS,
    )
  } else if up && !down && left && !right {
    game_state.tutorial_up_left_progress = clamp(
      game_state.tutorial_up_left_progress + delta,
      0.0,
      TUTORIAL_DIRECTION_SECONDS,
    )
  } else if up && !down && !left && right {
    game_state.tutorial_up_right_progress = clamp(
      game_state.tutorial_up_right_progress + delta,
      0.0,
      TUTORIAL_DIRECTION_SECONDS,
    )
  } else if !up && down && left && !right {
    game_state.tutorial_down_left_progress = clamp(
      game_state.tutorial_down_left_progress + delta,
      0.0,
      TUTORIAL_DIRECTION_SECONDS,
    )
  } else if !up && down && !left && right {
    game_state.tutorial_down_right_progress = clamp(
      game_state.tutorial_down_right_progress + delta,
      0.0,
      TUTORIAL_DIRECTION_SECONDS,
    )
  }

  game_state.tutorial_up_progress >= TUTORIAL_DIRECTION_SECONDS &&
  game_state.tutorial_down_progress >= TUTORIAL_DIRECTION_SECONDS &&
  game_state.tutorial_left_progress >= TUTORIAL_DIRECTION_SECONDS &&
  game_state.tutorial_right_progress >= TUTORIAL_DIRECTION_SECONDS &&
  game_state.tutorial_up_left_progress >= TUTORIAL_DIRECTION_SECONDS &&
  game_state.tutorial_up_right_progress >= TUTORIAL_DIRECTION_SECONDS &&
  game_state.tutorial_down_left_progress >= TUTORIAL_DIRECTION_SECONDS &&
  game_state.tutorial_down_right_progress >= TUTORIAL_DIRECTION_SECONDS
}

///|
fn tick_tutorial_slot1(delta : Double) -> Bool {
  if game_state.tutorial_slot1_destroy > 0 {
    game_state.tutorial_spawn_timer -= delta
    if !has_enemy_kind(Drone) && game_state.tutorial_spawn_timer <= 0.0 {
      spawn_tutorial_enemy(Drone)
      game_state.tutorial_spawn_timer = TUTORIAL_SPAWN_DELAY_SECONDS
    }
    return false
  }
  if game_state.tutorial_slot1_protect > 0 {
    game_state.tutorial_spawn_timer -= delta
    if !has_enemy_kind(Hauler) && game_state.tutorial_spawn_timer <= 0.0 {
      spawn_tutorial_enemy(Hauler)
      game_state.tutorial_spawn_timer = TUTORIAL_SPAWN_DELAY_SECONDS
    }
    return false
  }
  true
}

///|
fn tick_tutorial_slot2(delta : Double) -> Bool {
  if game_state.tutorial_slot2_destroy > 0 {
    game_state.tutorial_spawn_timer -= delta
    if !has_enemy_kind(Drone) && game_state.tutorial_spawn_timer <= 0.0 {
      spawn_tutorial_enemy(Drone)
      game_state.tutorial_spawn_timer = TUTORIAL_SPAWN_DELAY_SECONDS
    }
    return false
  }
  true
}

///|
fn on_enemy_defeated(kind : EnemyKind) -> Unit {
  if !is_tutorial_stage() {
    return
  }
  match game_state.tutorial_lesson {
    1 =>
      if kind is Drone {
        game_state.tutorial_slot1_destroy = clamp_int(
          game_state.tutorial_slot1_destroy - 1,
          0,
          99,
        )
        game_state.tutorial_spawn_timer = 0.0
      }
    2 =>
      if kind is Drone {
        game_state.tutorial_slot2_destroy = clamp_int(
          game_state.tutorial_slot2_destroy - 1,
          0,
          99,
        )
        game_state.tutorial_spawn_timer = 0.0
      }
    _ => ()
  }
}

///|
fn on_enemy_escaped(kind : EnemyKind) -> Unit {
  if !is_tutorial_stage() {
    return
  }
  match game_state.tutorial_lesson {
    1 =>
      if game_state.tutorial_slot1_destroy > 0 && kind is Drone {
        game_state.tutorial_spawn_timer = 0.0
      } else if game_state.tutorial_slot1_destroy == 0 && kind is Hauler {
        game_state.tutorial_slot1_protect = clamp_int(
          game_state.tutorial_slot1_protect - 1,
          0,
          99,
        )
        game_state.tutorial_spawn_timer = 0.0
      }
    2 => if kind is Drone { game_state.tutorial_spawn_timer = 0.0 }
    _ => ()
  }
}

///|
fn has_enemy_kind(kind : EnemyKind) -> Bool {
  for _, enemy in enemies {
    if enemy.kind == kind {
      return true
    }
  }
  false
}

///|
fn simulation_system(delta : Double) -> Unit {
  guard is_run_playing() else { return }
  game_state.elapsed += delta
  if game_state.player_invulnerable > 0.0 {
    game_state.player_invulnerable -= delta
  }
  tick_shield_recharge(delta)
  tick_charge(delta)
  move_bullets(delta)
  move_enemies(delta)
  enemy_attack_system(delta)
  move_consumables(delta)
  move_items(delta)
}

///|
fn tick_shield_recharge(delta : Double) -> Unit {
  if game_state.shield >= game_state.max_shield {
    return
  }
  if game_state.shield_recharge_delay > 0.0 {
    game_state.shield_recharge_delay -= delta
    return
  }
  game_state.shield_recharge_progress += game_state.shield_recharge_rate * delta
  while game_state.shield_recharge_progress >= 1.0 &&
        game_state.shield < game_state.max_shield {
    game_state.shield += 1
    game_state.shield_recharge_progress -= 1.0
  }
}

///|
fn tick_charge(delta : Double) -> Unit {
  if game_state.charge_time_left <= 0.0 {
    return
  }
  guard @transform.positions.get(game_state.player) is Some(player_position)
  let next = player_position.0 + game_state.charge_velocity.scalar_mul(delta)
  @transform.positions.set(
    game_state.player,
    @math.Vec2D(
      clamp(next[X], PLAYER_HALF_SIZE, VIEWPORT_WIDTH - PLAYER_HALF_SIZE),
      clamp(next[Y], PLAYER_HALF_SIZE, VIEWPORT_HEIGHT - PLAYER_HALF_SIZE),
    ),
  )
  game_state.charge_time_left -= delta
}

///|
fn move_bullets(delta : Double) -> Unit {
  let to_remove = []
  for bullet_entity, bullet in bullets {
    guard @transform.positions.get(bullet_entity) is Some(position) else {
      to_remove.push(bullet_entity)
      continue
    }
    let next = position.0 + bullet.velocity.scalar_mul(delta)
    @transform.positions.set(bullet_entity, next)
    bullet.ttl -= delta
    if bullet.ttl <= 0.0 ||
      next[Y] < -bullet.radius ||
      next[Y] > VIEWPORT_HEIGHT + bullet.radius ||
      next[X] < -bullet.radius ||
      next[X] > VIEWPORT_WIDTH + bullet.radius {
      to_remove.push(bullet_entity)
    }
  }
  for bullet_entity in to_remove {
    if bullets.contains(bullet_entity) {
      despawn_bullet(bullet_entity)
    }
  }
}

///|
fn move_enemies(delta : Double) -> Unit {
  let to_remove = []
  let player_pos = @transform.positions.get(game_state.player)
  for enemy_entity, enemy in enemies {
    guard @transform.positions.get(enemy_entity) is Some(position) else {
      to_remove.push((enemy_entity, 0, enemy.kind, false))
      continue
    }

    let radius = enemy_radius(enemy.kind)
    let mut next = position.0
    match enemy.movement {
      DownBrake => next = @math.Vec2D(next[X], next[Y] + enemy.speed_y * delta)
      DownOnly => next = @math.Vec2D(next[X], next[Y] + enemy.speed_y * delta)
      DownHorizontal => {
        let mut next_x = next[X] + enemy.speed_x * enemy.horizontal_dir * delta
        if next_x < radius {
          next_x = radius
          enemy.horizontal_dir = 1.0
        } else if next_x > VIEWPORT_WIDTH - radius {
          next_x = VIEWPORT_WIDTH - radius
          enemy.horizontal_dir = -1.0
        }
        next = @math.Vec2D(next_x, next[Y] + enemy.speed_y * delta)
      }
      Homing =>
        if player_pos is Some(pp) {
          let dir = (pp.0 - next).normalize()
          let speed = @math.Vec2D(
            enemy.speed_x * dir[X],
            enemy.speed_y * dir[Y],
          )
          next = next + speed.scalar_mul(delta)
        } else {
          next = @math.Vec2D(next[X], next[Y] + enemy.speed_y * delta)
        }
      BossHover => {
        let hover_y = 72.0
        let mut next_y = next[Y]
        if next_y < hover_y {
          next_y = @cmp.minimum(hover_y, next_y + enemy.speed_y * delta)
        } else {
          next_y = hover_y
        }
        let mut next_x = next[X] + enemy.speed_x * enemy.horizontal_dir * delta
        let left = radius + 30.0
        let right = VIEWPORT_WIDTH - radius - 30.0
        if next_x < left {
          next_x = left
          enemy.horizontal_dir = 1.0
        } else if next_x > right {
          next_x = right
          enemy.horizontal_dir = -1.0
        }
        next = @math.Vec2D(next_x, next_y)
      }
    }
    @transform.positions.set(enemy_entity, next)
    if next[Y] > VIEWPORT_HEIGHT + radius ||
      next[X] < -80.0 ||
      next[X] > VIEWPORT_WIDTH + 80.0 {
      to_remove.push(
        (enemy_entity, enemy.escape_defense_delta, enemy.kind, true),
      )
    }
  }
  for remove_info in to_remove {
    let enemy_entity = remove_info.0
    let defense_delta = remove_info.1
    let enemy_kind = remove_info.2
    let escaped = remove_info.3
    if enemies.contains(enemy_entity) {
      despawn_enemy(enemy_entity)
      apply_defense_delta(defense_delta)
      if escaped {
        on_enemy_escaped(enemy_kind)
      }
    }
  }
}

///|
fn enemy_attack_system(delta : Double) -> Unit {
  let projectile_spawns = []
  let enemy_spawns = []

  for enemy_entity, enemy in enemies {
    if enemy.shooter is NoShooter {
      continue
    }
    enemy.shoot_cooldown -= delta
    if enemy.shoot_cooldown > 0.0 {
      continue
    }
    guard @transform.positions.get(enemy_entity) is Some(position) else {
      enemy.shoot_cooldown = enemy.shoot_interval
      continue
    }

    match enemy.shooter {
      NoShooter => ()
      PawnBlaster => {
        let dir1 = @math.Vec2D(-0.35, 0.94).normalize().scalar_mul(400.0)
        let dir2 = @math.Vec2D(0.35, 0.94).normalize().scalar_mul(400.0)
        projectile_spawns.push(
          (position.0 + @math.Vec2D(-4.0, 12.0), dir1, 10, Blast, 1.0),
        )
        projectile_spawns.push(
          (position.0 + @math.Vec2D(4.0, 12.0), dir2, 10, Blast, 1.0),
        )
      }
      StraferBlaster =>
        projectile_spawns.push(
          (
            position.0 + @math.Vec2D(0.0, 10.0),
            @math.Vec2D(0.0, 400.0),
            8,
            Blast,
            1.0,
          ),
        )
      ShellyRing => {
        let base_dirs = [
          @math.Vec2D(1.0, 0.0),
          @math.Vec2D(0.7071, 0.7071),
          @math.Vec2D(0.0, 1.0),
          @math.Vec2D(-0.7071, 0.7071),
          @math.Vec2D(-1.0, 0.0),
          @math.Vec2D(-0.7071, -0.7071),
          @math.Vec2D(0.0, -1.0),
          @math.Vec2D(0.7071, -0.7071),
        ]
        for base_dir in base_dirs {
          let jitter_x = (game_state.rand.double() - 0.5) * 0.18
          let jitter_y = (game_state.rand.double() - 0.5) * 0.18
          let dir = (base_dir + @math.Vec2D(jitter_x, jitter_y)).normalize()
          let speed = 300.0 * (0.75 + game_state.rand.double() * 0.5)
          projectile_spawns.push(
            (position.0, dir.scalar_mul(speed), 10, Bullet, 0.3),
          )
        }
      }
      MissileLauncherSpawner =>
        enemy_spawns.push((Missile, position.0 + @math.Vec2D(0.0, -35.0)))
      BossSpawner => {
        let escort_y = position.0[Y] + 22.0
        enemy_spawns.push((Pawn, @math.Vec2D(120.0, escort_y)))
        enemy_spawns.push((Pawn, @math.Vec2D(VIEWPORT_WIDTH - 120.0, escort_y)))
        if game_state.rand.double() < 0.7 {
          enemy_spawns.push((Drone, @math.Vec2D(200.0, escort_y + 25.0)))
          enemy_spawns.push(
            (Drone, @math.Vec2D(VIEWPORT_WIDTH - 200.0, escort_y + 25.0)),
          )
        }
        for offset in [-0.9, -0.45, 0.0, 0.45, 0.9] {
          let dir = @math.Vec2D(offset, 1.0).normalize()
          projectile_spawns.push(
            (position.0, dir.scalar_mul(360.0), 12, Blast, 1.1),
          )
        }
      }
    }

    if enemy.shoot_interval > 0.0 {
      enemy.shoot_cooldown += enemy.shoot_interval
    } else {
      enemy.shoot_cooldown = 9999.0
    }
  }

  for spawn in projectile_spawns {
    spawn_enemy_projectile(spawn.0, spawn.1, spawn.2, spawn.3, spawn.4)
  }
  for spawn in enemy_spawns {
    spawn_enemy(spawn.0, spawn.1)
  }

  if projectile_spawns.length() > 0 {
    @audio.play_audio(SFX_ENEMY_FIRE, volume=0.15)
  }
}

///|
fn move_consumables(delta : Double) -> Unit {
  let to_remove = []
  let player_pos = @transform.positions.get(game_state.player)
  for consumable_entity, consumable in consumables {
    guard @transform.positions.get(consumable_entity) is Some(position) else {
      to_remove.push(consumable_entity)
      continue
    }
    let mut next = @math.Vec2D(
      position.0[X],
      position.0[Y] + consumable.speed * delta,
    )
    if player_pos is Some(pp) {
      let to_player = pp.0 - position.0
      let distance = to_player.distance()
      if distance > 0.0001 && distance <= game_state.attraction_distance {
        next = next +
          to_player
          .normalize()
          .scalar_mul(game_state.attraction_acceleration * 15.0 * delta)
      }
    }
    @transform.positions.set(consumable_entity, next)
    if next[Y] > VIEWPORT_HEIGHT + CONSUMABLE_HALF_SIZE {
      to_remove.push(consumable_entity)
    }
  }
  for entity in to_remove {
    if consumables.contains(entity) {
      despawn_consumable(entity)
    }
  }
}

///|
fn move_items(delta : Double) -> Unit {
  let to_remove = []
  let player_pos = @transform.positions.get(game_state.player)
  for item_entity, item in items {
    guard @transform.positions.get(item_entity) is Some(position) else {
      to_remove.push(item_entity)
      continue
    }
    let mut next = @math.Vec2D(
      position.0[X],
      position.0[Y] + item.speed * delta,
    )
    if player_pos is Some(pp) {
      let to_player = pp.0 - position.0
      let distance = to_player.distance()
      if distance > 0.0001 && distance <= game_state.attraction_distance {
        next = next +
          to_player
          .normalize()
          .scalar_mul(game_state.attraction_acceleration * 15.0 * delta)
      }
    }
    @transform.positions.set(item_entity, next)
    if next[Y] > VIEWPORT_HEIGHT + ITEM_HALF_SIZE {
      to_remove.push(item_entity)
    }
  }
  for entity in to_remove {
    if items.contains(entity) {
      despawn_item(entity)
    }
  }
}

///|
fn combat_system(_delta : Double) -> Unit {
  guard is_run_playing() else { return }
  bullet_enemy_collision()
  enemy_bullet_player_collision()
  enemy_player_collision()
  consumable_player_collision()
  item_player_collision()
}

///|
fn bullet_enemy_collision() -> Unit {
  let dead_bullets = []
  let defeated_enemies = []

  for bullet_entity, bullet in bullets {
    if bullet.faction is Enemy {
      continue
    }
    guard @transform.positions.get(bullet_entity) is Some(bullet_position) else {
      dead_bullets.push(bullet_entity)
      continue
    }
    for enemy_entity, enemy in enemies {
      if enemy.kind is Hauler {
        continue
      }
      guard @transform.positions.get(enemy_entity) is Some(enemy_position) else {
        continue
      }
      if overlaps(
          bullet_position.0,
          bullet.radius,
          enemy_position.0,
          enemy_radius(enemy.kind),
        ) {
        dead_bullets.push(bullet_entity)
        enemy.hp -= bullet.damage
        if enemy.hp <= 0 {
          defeated_enemies.push((enemy_entity, enemy.kind, enemy_position.0))
        }
        break
      }
    }
  }

  for pair in defeated_enemies {
    let enemy_entity = pair.0
    let enemy_kind = pair.1
    let enemy_pos = pair.2
    if enemies.contains(enemy_entity) {
      despawn_enemy(enemy_entity)
      game_state.score += SCORE_PER_KILL
      maybe_spawn_drop(enemy_kind, enemy_pos)
      on_enemy_defeated(enemy_kind)
    }
  }

  for bullet_entity in dead_bullets {
    if bullets.contains(bullet_entity) {
      despawn_bullet(bullet_entity)
    }
  }
}

///|
fn enemy_bullet_player_collision() -> Unit {
  guard @transform.positions.get(game_state.player) is Some(player_position)
  let dead_bullets = []
  for bullet_entity, bullet in bullets {
    if bullet.faction is Ally {
      continue
    }
    guard @transform.positions.get(bullet_entity) is Some(bullet_position) else {
      dead_bullets.push(bullet_entity)
      continue
    }
    if overlaps(
        bullet_position.0,
        bullet.radius,
        player_position.0,
        PLAYER_HALF_SIZE,
      ) {
      dead_bullets.push(bullet_entity)
      damage_player(bullet.damage)
    }
  }
  for bullet_entity in dead_bullets {
    if bullets.contains(bullet_entity) {
      despawn_bullet(bullet_entity)
    }
  }
}

///|
priv struct DropRule {
  kind : ConsumableKind
  rolls : Int
  probability : Double
}

///|
enum DropListType {
  Standard
  MoneyAsteroid
  Boss
} derive(Eq)

///|
let standard_drop_rules : Array[DropRule] = [
  { kind: Armor, rolls: 1, probability: 0.03 },
  { kind: HealthWrench, rolls: 1, probability: 0.06 },
  { kind: Money1, rolls: 2, probability: 0.10 },
]

///|
let money_asteroid_drop_rules : Array[DropRule] = [
  { kind: Money1, rolls: 1, probability: 1.00 },
  { kind: Money1, rolls: 5, probability: 0.20 },
  { kind: Money3, rolls: 1, probability: 0.10 },
]

///|
let boss_drop_rules : Array[DropRule] = [
  { kind: Armor, rolls: 1, probability: 0.03 },
  { kind: HealthWrench, rolls: 2, probability: 0.40 },
  { kind: Money1, rolls: 2, probability: 0.10 },
  { kind: GainProjectiles, rolls: 1, probability: 1.00 },
]

///|
let boss_item_drops : Array[ItemKind] = [EnhancedPlating]

///|
fn drop_list_for_enemy(kind : EnemyKind) -> DropListType {
  if kind is MoneyAsteroid {
    MoneyAsteroid
  } else if kind is Ferritharax ||
    kind is MechaFerritharax ||
    kind is MechaSaucetron {
    Boss
  } else {
    Standard
  }
}

///|
fn drop_rules(drop_list : DropListType) -> Array[DropRule] {
  match drop_list {
    Standard => standard_drop_rules
    MoneyAsteroid => money_asteroid_drop_rules
    Boss => boss_drop_rules
  }
}

///|
fn maybe_spawn_drop(kind : EnemyKind, position : @math.Vec2D) -> Unit {
  let drop_list = drop_list_for_enemy(kind)
  let rules = drop_rules(drop_list)
  for rule in rules {
    for _ in 0..<rule.rolls {
      if game_state.rand.double() <= rule.probability {
        let offset = @math.Vec2D(
          (game_state.rand.double() - 0.5) * 26.0,
          (game_state.rand.double() - 0.5) * 18.0,
        )
        spawn_consumable(rule.kind, position + offset)
      }
    }
  }
  if drop_list is Boss {
    for item in boss_item_drops {
      let offset = @math.Vec2D(
        (game_state.rand.double() - 0.5) * 24.0,
        (game_state.rand.double() - 0.5) * 12.0,
      )
      spawn_item(item, position + offset)
    }
  }
}

///|
fn enemy_player_collision() -> Unit {
  if game_state.player_invulnerable > 0.0 {
    return
  }
  guard @transform.positions.get(game_state.player) is Some(player_position)
  let mut collided : (@entity.Entity, EnemyKind, Int)? = None
  for enemy_entity, enemy in enemies {
    if enemy.kind is Hauler {
      continue
    }
    guard @transform.positions.get(enemy_entity) is Some(enemy_position) else {
      continue
    }
    if overlaps(
        player_position.0,
        PLAYER_HALF_SIZE,
        enemy_position.0,
        enemy_radius(enemy.kind),
      ) {
      collided = Some((enemy_entity, enemy.kind, enemy.collision_damage))
      break
    }
  }
  guard collided is Some(hit) else { return }
  if enemies.contains(hit.0) {
    despawn_enemy(hit.0)
    on_enemy_escaped(hit.1)
    damage_player(hit.2)
  }
}

///|
fn consumable_player_collision() -> Unit {
  guard @transform.positions.get(game_state.player) is Some(player_position)
  let picked = []
  for entity, consumable in consumables {
    guard @transform.positions.get(entity) is Some(consumable_position) else {
      picked.push((entity, consumable.kind))
      continue
    }
    if overlaps(
        player_position.0,
        PLAYER_HALF_SIZE,
        consumable_position.0,
        CONSUMABLE_HALF_SIZE,
      ) {
      picked.push((entity, consumable.kind))
    }
  }
  for pair in picked {
    let entity = pair.0
    let kind = pair.1
    if consumables.contains(entity) {
      apply_consumable(kind)
      despawn_consumable(entity)
    }
  }
}

///|
fn item_player_collision() -> Unit {
  guard @transform.positions.get(game_state.player) is Some(player_position)
  let picked = []
  for entity, item in items {
    guard @transform.positions.get(entity) is Some(item_position) else {
      picked.push((entity, item.kind))
      continue
    }
    if overlaps(
        player_position.0,
        PLAYER_HALF_SIZE,
        item_position.0,
        ITEM_HALF_SIZE,
      ) {
      picked.push((entity, item.kind))
    }
  }
  for pair in picked {
    let entity = pair.0
    let kind = pair.1
    if items.contains(entity) {
      apply_item(kind)
      despawn_item(entity)
    }
  }
}

///|
fn apply_consumable(kind : ConsumableKind) -> Unit {
  let mut money_changed = false
  match kind {
    Money1 => {
      game_state.money += 1
      game_state.score += 1
      money_changed = true
    }
    Money3 => {
      game_state.money += 3
      game_state.score += 3
      money_changed = true
    }
    HealthWrench =>
      game_state.hull = clamp_int(game_state.hull + 20, 0, game_state.max_hull)
    Armor => game_state.armor += 1
    GainProjectiles =>
      game_state.projectile_count = clamp_int(
        game_state.projectile_count + 1,
        1,
        MAX_PROJECTILE_COUNT,
      )
  }
  if money_changed {
    refresh_cooldown_multiplier()
  }
  @audio.play_audio(SFX_CONSUMABLE_PICKUP, volume=0.2)
}

///|
fn apply_item(kind : ItemKind) -> Unit {
  match kind {
    EnhancedPlating => {
      game_state.max_hull += 100
      game_state.hull = game_state.max_hull
      game_state.plating_count += 1
    }
  }
  @audio.play_audio(SFX_CONSUMABLE_PICKUP, volume=0.25)
}

///|
fn damage_player(amount : Int) -> Unit {
  guard is_run_playing() else { return }
  if game_state.player_invulnerable > 0.0 {
    return
  }
  if game_state.armor > 0 {
    game_state.armor -= 1
    game_state.player_invulnerable = PLAYER_INVULNERABLE_SECONDS
    return
  }
  let mut remaining = amount
  if game_state.shield > 0 {
    let absorbed = @cmp.minimum(game_state.shield, remaining)
    game_state.shield -= absorbed
    remaining -= absorbed
  }
  if remaining > 0 {
    game_state.hull = clamp_int(
      game_state.hull - remaining,
      0,
      game_state.max_hull,
    )
  }
  game_state.shield_recharge_delay = SHIELD_RECHARGE_DELAY_SECONDS
  game_state.shield_recharge_progress = 0.0
  game_state.player_invulnerable = PLAYER_INVULNERABLE_SECONDS
  @audio.play_audio(SFX_PLAYER_HIT, volume=0.25)
  if game_state.hull == 0 {
    game_state.phase = GameOver
  }
}

///|
fn apply_defense_delta(delta : Int) -> Unit {
  guard is_run_playing() else { return }
  game_state.defense = clamp_int(game_state.defense + delta, 0, 100)
  if delta < 0 {
    @audio.play_audio(SFX_DEFENSE_DAMAGE, volume=0.20)
  } else if delta > 0 {
    @audio.play_audio(SFX_DEFENSE_HEAL, volume=0.20)
  }
  if game_state.defense == 0 {
    game_state.phase = GameOver
  }
}

///|
fn victory_system(_delta : Double) -> Unit {
  if is_run_playing() &&
    game_state.stage_index >= run_stages.length() &&
    enemies.length() == 0 {
    game_state.phase = Victory
  }
}

///|
fn ui_system(_delta : Double) -> Unit {
  match game_state.screen {
    MainMenu => ui_main_menu()
    CharacterSelection => ui_character_selection()
    InGame => ui_in_game()
  }
}

///|
fn ui_main_menu() -> Unit {
  game_state.score_text.content = ""
  game_state.hull_text.content = ""
  game_state.shield_text.content = ""
  game_state.defense_text.content = ""
  game_state.stage_text.content = "THETAWAVE"
  game_state.timer_text.content = "Press Enter"
  game_state.banner_text.content = "MoonBit Port 2026"
}

///|
fn ui_character_selection() -> Unit {
  let config = character_config(game_state.selected_character)
  game_state.score_text.content = "Select Character"
  game_state.hull_text.content = "Name: \{config.name}"
  game_state.shield_text.content = "Hull \{config.max_hull}  Shield \{config.max_shield}"
  game_state.defense_text.content = "Speed \{config.speed.to_int()}"
  game_state.stage_text.content = "A/Left: Captain  D/Right: Juggernaut"
  game_state.timer_text.content = "Enter: Start  Esc: Back"
  game_state.banner_text.content = if game_state.selected_character is Captain {
    "Captain: Blast + MegaBlast"
  } else {
    "Juggernaut: Bullet + Charge"
  }
}

///|
fn ui_in_game() -> Unit {
  game_state.score_text.content = "Score: \{game_state.score}  Money: \{game_state.money}"
  game_state.hull_text.content = "Hull: \{game_state.hull}/\{game_state.max_hull}"
  game_state.shield_text.content = "Shield: \{game_state.shield}/\{game_state.max_shield}"
  game_state.defense_text.content = "Defense: \{game_state.defense}/100  Armor: \{game_state.armor}"
  if game_state.plating_count > 0 {
    game_state.defense_text.content = "Defense: \{game_state.defense}/100  Armor: \{game_state.armor}  Plating: \{game_state.plating_count}"
  }
  game_state.stage_text.content = if game_state.stage_index >=
    run_stages.length() {
    "Stage: Run Clear"
  } else if is_tutorial_stage() {
    "Stage: Tutorial - \{tutorial_lesson_name()}"
  } else {
    "Stage: \{game_state.stage_label}"
  }
  game_state.timer_text.content = "Run: \{game_state.elapsed.to_int()}s"
  game_state.banner_text.content = match game_state.phase {
    Playing =>
      if is_tutorial_stage() {
        tutorial_status_text()
      } else if game_state.special_cooldown <= 0.0 {
        "Space/LMB Fire  Q/RMB Special"
      } else {
        "Special CD: \{game_state.special_cooldown.to_int()}s"
      }
    Paused => "PAUSED  Esc/Enter Resume  R Main Menu"
    GameOver => "GAME OVER  Enter: Character Select  Esc: Main Menu"
    Victory => "VICTORY  Enter: Character Select  Esc: Main Menu"
  }
}

///|
fn is_run_playing() -> Bool {
  game_state.screen is InGame && game_state.phase is Playing
}

///|
fn is_tutorial_stage() -> Bool {
  if current_stage() is Some(stage) {
    stage.kind is Tutorial
  } else {
    false
  }
}

///|
fn tutorial_lesson_name() -> String {
  match game_state.tutorial_lesson {
    0 => "Movement"
    1 => "Main Weapon"
    2 => "Special Ability"
    _ => "Complete"
  }
}

///|
fn tutorial_movement_completed_count() -> Int {
  let mut count = 0
  if game_state.tutorial_up_progress >= TUTORIAL_DIRECTION_SECONDS {
    count += 1
  }
  if game_state.tutorial_down_progress >= TUTORIAL_DIRECTION_SECONDS {
    count += 1
  }
  if game_state.tutorial_left_progress >= TUTORIAL_DIRECTION_SECONDS {
    count += 1
  }
  if game_state.tutorial_right_progress >= TUTORIAL_DIRECTION_SECONDS {
    count += 1
  }
  if game_state.tutorial_up_left_progress >= TUTORIAL_DIRECTION_SECONDS {
    count += 1
  }
  if game_state.tutorial_up_right_progress >= TUTORIAL_DIRECTION_SECONDS {
    count += 1
  }
  if game_state.tutorial_down_left_progress >= TUTORIAL_DIRECTION_SECONDS {
    count += 1
  }
  if game_state.tutorial_down_right_progress >= TUTORIAL_DIRECTION_SECONDS {
    count += 1
  }
  count
}

///|
fn tutorial_status_text() -> String {
  match game_state.tutorial_lesson {
    0 => "Movement checkpoints: \{tutorial_movement_completed_count()}/8"
    1 =>
      if game_state.tutorial_slot1_destroy > 0 {
        "Destroy drones: \{game_state.tutorial_slot1_destroy} left"
      } else {
        "Protect haulers: \{game_state.tutorial_slot1_protect} left"
      }
    2 =>
      "Use special to destroy drones: \{game_state.tutorial_slot2_destroy} left"
    _ => "Tutorial complete"
  }
}

///|
fn current_shoot_interval() -> Double {
  @cmp.maximum(0.08, game_state.shoot_interval * game_state.cooldown_multiplier)
}

///|
fn special_cooldown_duration() -> Double {
  @cmp.maximum(
    0.6,
    game_state.special_cooldown_base * game_state.cooldown_multiplier,
  )
}

///|
fn enemy_radius(kind : EnemyKind) -> Double {
  match kind {
    Ferritharax | MechaFerritharax | MechaSaucetron => 22.0
    Hauler => 10.0
    Missile => 9.0
    _ => ENEMY_HALF_SIZE
  }
}

///|
fn overlaps(
  a : @math.Vec2D,
  a_radius : Double,
  b : @math.Vec2D,
  b_radius : Double,
) -> Bool {
  a.distance_to(b) <= a_radius + b_radius
}

///|
fn clamp(value : Double, lo : Double, hi : Double) -> Double {
  @cmp.minimum(hi, @cmp.maximum(lo, value))
}

///|
fn clamp_int(value : Int, lo : Int, hi : Int) -> Int {
  @cmp.minimum(hi, @cmp.maximum(lo, value))
}

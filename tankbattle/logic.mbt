///|
fn ensure_runtime_storage() -> Unit {
  if terrain_tiles.is_empty() {
    for _ in 0..<(STAGE_COLS * STAGE_ROWS) {
      terrain_tiles.push(Empty)
      terrain_entities.push(@entity.Entity::new())
      terrain_overlay_entities.push(@entity.Entity::new())
    }
  }
  if enemy_tanks.is_empty() {
    for _ in 0..<MAX_ACTIVE_ENEMIES {
      enemy_tanks.push(default_enemy_state())
      enemy_entities.push(@entity.Entity::new())
      enemy_effect_entities.push(@entity.Entity::new())
    }
  }
  if projectiles.is_empty() {
    for _ in 0..<MAX_PROJECTILES {
      projectiles.push(default_projectile_state())
      projectile_entities.push(@entity.Entity::new())
    }
  }
  if explosions.is_empty() {
    for _ in 0..<MAX_EXPLOSIONS {
      explosions.push(default_explosion_state())
      explosion_entities.push(@entity.Entity::new())
    }
  }
  if queue_icon_entities.is_empty() {
    for _ in 0..<ENEMIES_PER_STAGE {
      queue_icon_entities.push(@entity.Entity::new())
    }
  }
  if current_enemy_spawn_points.is_empty() {
    current_enemy_spawn_points.push((0, 0))
    current_enemy_spawn_points.push((6, 0))
    current_enemy_spawn_points.push((12, 0))
  }
  if fortress_positions.is_empty() {
    fortress_positions.push((5, 11))
    fortress_positions.push((6, 11))
    fortress_positions.push((7, 11))
    fortress_positions.push((5, 12))
    fortress_positions.push((7, 12))
  }
}

///|
fn reset_menu_state() -> Unit {
  campaign_state.phase = MainMenu
  campaign_state.phase_seconds = 0.0
  campaign_state.menu_option = OnePlayer
  campaign_state.base_destroyed = false
}

///|
fn clear_dynamic_runtime() -> Unit {
  for index in 0..<MAX_ACTIVE_ENEMIES {
    enemy_tanks[index] = default_enemy_state()
  }
  for index in 0..<MAX_PROJECTILES {
    projectiles[index] = default_projectile_state()
  }
  for index in 0..<MAX_EXPLOSIONS {
    explosions[index] = default_explosion_state()
  }
  active_powerup.active = false
  active_powerup.seconds_remaining = 0.0
  campaign_state.freeze_seconds = 0.0
  campaign_state.shovel_seconds = 0.0
  campaign_state.pending_respawn_seconds = 0.0
  campaign_state.spawn_seconds = SPAWN_INTERVAL_SECONDS
  campaign_state.queue_index = 0
}

///|
fn stage_at(index : Int) -> StageSpec {
  stages[clamp_int(index, 0, stage_count() - 1)]
}

///|
fn count_active_projectiles(owner : TankOwner) -> Int {
  let mut count = 0
  for projectile in projectiles {
    if projectile.active && projectile.owner == owner {
      count += 1
    }
  }
  count
}

///|
fn active_enemy_count() -> Int {
  let mut count = 0
  for enemy in enemy_tanks {
    if enemy.active {
      count += 1
    }
  }
  count
}

///|
fn remaining_enemy_count() -> Int {
  let queue_remaining = ENEMIES_PER_STAGE - campaign_state.queue_index
  queue_remaining + active_enemy_count()
}

///|
fn clear_stage_tiles() -> Unit {
  for y in 0..<STAGE_ROWS {
    for x in 0..<STAGE_COLS {
      set_tile(x, y, Empty)
    }
  }
}

///|
fn apply_fortress_material(tile : TerrainKind) -> Unit {
  for position in fortress_positions {
    let (x, y) = position
    if tile_at(x, y) != Base {
      set_tile(x, y, tile)
    }
  }
}

///|
fn parse_stage_layout(stage : StageSpec) -> Unit {
  clear_stage_tiles()
  current_enemy_spawn_points.clear()
  for y in 0..<STAGE_ROWS {
    let row = stage.tiles[y]
    for x in 0..<STAGE_COLS {
      let tile = row[x]
      match tile {
        '.' => set_tile(x, y, Empty)
        '#' => set_tile(x, y, Brick)
        'S' => set_tile(x, y, Steel)
        'W' => set_tile(x, y, Water)
        'F' => set_tile(x, y, Forest)
        'I' => set_tile(x, y, Ice)
        'B' => {
          set_tile(x, y, Base)
          current_base_grid.val = (x, y)
        }
        'P' => {
          set_tile(x, y, Empty)
          current_player_spawn.val = (x, y)
        }
        'A' | 'C' | 'E' => {
          set_tile(x, y, Empty)
          current_enemy_spawn_points.push((x, y))
        }
        _ => set_tile(x, y, Empty)
      }
    }
  }
  if current_enemy_spawn_points.length() == 0 {
    current_enemy_spawn_points.push((0, 0))
    current_enemy_spawn_points.push((6, 0))
    current_enemy_spawn_points.push((12, 0))
  }
}

///|
fn reset_player_state(center : @math.Vec2, keep_rank : Bool) -> Unit {
  player_tank.active = true
  player_tank.center = center
  player_tank.direction = Up
  if !keep_rank {
    player_tank.rank = Basic
  }
  player_tank.kind = Basic
  player_tank.hp = 1
  player_tank.fire_cooldown = 0.0
  player_tank.born_seconds = SPAWN_FLASH_SECONDS
  player_tank.shield_seconds = RESPAWN_SHIELD_SECONDS
  player_tank.turn_seconds = 0.0
  player_tank.carrier_drop = None
}

///|
fn start_stage(index : Int, keep_rank : Bool) -> Unit {
  ensure_runtime_storage()
  clear_dynamic_runtime()
  campaign_state.current_stage = index
  campaign_state.base_destroyed = false
  campaign_state.phase = StageIntro
  campaign_state.phase_seconds = 0.0
  parse_stage_layout(stage_at(index))
  let (spawn_x, spawn_y) = current_player_spawn.val
  reset_player_state(tile_center(spawn_x, spawn_y), keep_rank)
}

///|
fn start_new_campaign() -> Unit {
  campaign_state.lives = STARTING_LIVES
  start_stage(0, false)
}

///|
fn set_game_over() -> Unit {
  campaign_state.phase = GameOver
  campaign_state.phase_seconds = 0.0
}

///|
fn set_campaign_clear() -> Unit {
  campaign_state.phase = CampaignClear
  campaign_state.phase_seconds = 0.0
}

///|
fn next_stage_or_campaign_clear() -> Unit {
  if campaign_state.current_stage + 1 >= stage_count() {
    set_campaign_clear()
  } else {
    start_stage(campaign_state.current_stage + 1, true)
  }
}

///|
fn set_stage_clear() -> Unit {
  campaign_state.phase = StageClear
  campaign_state.phase_seconds = 0.0
}

///|
fn spawn_enemy_from_queue() -> Bool {
  let stage = stage_at(campaign_state.current_stage)
  if campaign_state.queue_index >= stage.queue.length() {
    return false
  }
  for index in 0..<MAX_ACTIVE_ENEMIES {
    if enemy_tanks[index].active {
      continue
    }
    let spec = stage.queue[campaign_state.queue_index]
    campaign_state.queue_index += 1
    let spawn_index = (campaign_state.queue_index - 1) %
      current_enemy_spawn_points.length()
    let (grid_x, grid_y) = current_enemy_spawn_points[spawn_index]
    enemy_tanks[index] = {
      active: true,
      center: tile_center(grid_x, grid_y),
      direction: Down,
      rank: Basic,
      kind: spec.kind,
      hp: enemy_hit_points(spec.kind),
      fire_cooldown: enemy_fire_cooldown(spec.kind) * 0.65,
      born_seconds: SPAWN_FLASH_SECONDS,
      shield_seconds: SPAWN_FLASH_SECONDS,
      turn_seconds: ENEMY_TURN_SECONDS + index.to_double() * 0.07,
      carrier_drop: spec.drop,
    }
    return true
  }
  false
}

///|
fn create_explosion(center : @math.Vec2, kind : ExplosionKind) -> Unit {
  for index in 0..<MAX_EXPLOSIONS {
    if !explosions[index].active {
      explosions[index].active = true
      explosions[index].kind = kind
      explosions[index].center = center
      explosions[index].seconds_remaining = match kind {
        Bullet => BULLET_EXPLOSION_SECONDS
        Big => BIG_EXPLOSION_SECONDS
      }
      return
    }
  }
}

///|
fn destroy_projectile(index : Int, spawn_effect : Bool) -> Unit {
  if spawn_effect {
    create_explosion(projectiles[index].center, Bullet)
  }
  projectiles[index] = default_projectile_state()
}

///|
fn destroy_enemy(index : Int, drop_override? : Bool = true) -> Unit {
  if !enemy_tanks[index].active {
    return
  }
  let center = enemy_tanks[index].center
  let drop = enemy_tanks[index].carrier_drop
  enemy_tanks[index] = default_enemy_state()
  create_explosion(center, Big)
  if drop_override {
    match drop {
      Some(kind) => {
        active_powerup.active = true
        active_powerup.kind = kind
        active_powerup.center = center
        active_powerup.seconds_remaining = POWERUP_VISIBLE_SECONDS
      }
      None => ()
    }
  }
}

///|
fn destroy_player() -> Unit {
  if !player_tank.active {
    return
  }
  create_explosion(player_tank.center, Big)
  player_tank.active = false
  if campaign_state.lives > 1 {
    campaign_state.lives -= 1
    campaign_state.pending_respawn_seconds = PLAYER_RESPAWN_DELAY
  } else {
    campaign_state.lives = 0
    set_game_over()
  }
}

///|
fn player_alive() -> Bool {
  player_tank.active
}

///|
fn first_active_player_projectile_slot() -> Int? {
  for index in 0..<MAX_PROJECTILES {
    if projectiles[index].active && projectiles[index].owner == Player {
      return Some(index)
    }
  }
  None
}

///|
fn spawn_projectile(
  owner : TankOwner,
  center : @math.Vec2,
  direction : Direction,
  speed : Double,
  can_break_steel : Bool,
) -> Bool {
  for index in 0..<MAX_PROJECTILES {
    if !projectiles[index].active {
      projectiles[index].active = true
      projectiles[index].owner = owner
      projectiles[index].center = center
      projectiles[index].direction = direction
      projectiles[index].speed = speed
      projectiles[index].can_break_steel = can_break_steel
      return true
    }
  }
  false
}

///|
fn muzzle_position(center : @math.Vec2, direction : Direction) -> @math.Vec2 {
  let step = direction_step(direction, TILE_SIZE * 0.42)
  vec2(center[X] + step[X], center[Y] + step[Y])
}

///|
fn try_fire_player() -> Bool {
  if !player_tank.active || player_tank.born_seconds > 0.0 {
    return false
  }
  if player_tank.fire_cooldown > 0.0 {
    return false
  }
  if count_active_projectiles(Player) >=
    player_projectile_limit(player_tank.rank) {
    return false
  }
  let fired = spawn_projectile(
    Player,
    muzzle_position(player_tank.center, player_tank.direction),
    player_tank.direction,
    player_projectile_speed(player_tank.rank),
    player_can_break_steel(player_tank.rank),
  )
  if fired {
    player_tank.fire_cooldown = PLAYER_FIRE_COOLDOWN
  }
  fired
}

///|
fn line_clear_for_enemy_fire(from_ : @math.Vec2, direction : Direction) -> Bool {
  let (start_x, start_y) = world_to_grid(from_)
  let (target_x, target_y) = if player_tank.active {
    world_to_grid(player_tank.center)
  } else {
    current_base_grid.val
  }
  match direction {
    Up | Down => {
      if start_x != target_x {
        return false
      }
      let from_y = if start_y < target_y { start_y + 1 } else { target_y + 1 }
      let to_y = if start_y < target_y { target_y - 1 } else { start_y - 1 }
      for y in from_y..<=to_y {
        if terrain_blocks_bullet(tile_at(start_x, y)) {
          return false
        }
      }
      true
    }
    Left | Right => {
      if start_y != target_y {
        return false
      }
      let from_x = if start_x < target_x { start_x + 1 } else { target_x + 1 }
      let to_x = if start_x < target_x { target_x - 1 } else { start_x - 1 }
      for x in from_x..<=to_x {
        if terrain_blocks_bullet(tile_at(x, start_y)) {
          return false
        }
      }
      true
    }
  }
}

///|
fn choose_enemy_direction(enemy : TankState) -> Direction {
  let target = if player_tank.active {
    player_tank.center
  } else {
    let (base_x, base_y) = current_base_grid.val
    tile_center(base_x, base_y)
  }
  let dx = target[X] - enemy.center[X]
  let dy = target[Y] - enemy.center[Y]
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
  let secondary = if primary == Up || primary == Down {
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
  let rotation = [
    primary,
    secondary,
    if primary == Up {
      Left
    } else if primary == Down {
      Right
    } else {
      Up
    },
    if primary == Up {
      Right
    } else if primary == Down {
      Left
    } else {
      Down
    },
  ]
  for direction in rotation {
    if direction == enemy.direction ||
      terrain_step_available(
        enemy.center,
        direction,
        PLAYER_COLLIDER_SIZE,
        enemy.center,
      ) {
      return direction
    }
  }
  enemy.direction
}

///|
fn terrain_step_available(
  center : @math.Vec2,
  direction : Direction,
  collider_size : Double,
  original_center : @math.Vec2,
) -> Bool {
  let step = direction_step(direction, 8.0)
  let candidate = vec2(center[X] + step[X], center[Y] + step[Y])
  let hitbox = rect(
    candidate[X] - collider_size * 0.5,
    candidate[Y] - collider_size * 0.5,
    collider_size,
    collider_size,
  )
  if hitbox.left < BOARD_LEFT ||
    hitbox.top < BOARD_TOP ||
    hitbox.left + hitbox.width > BOARD_RIGHT ||
    hitbox.top + hitbox.height > BOARD_BOTTOM {
    return false
  }
  for y in 0..<STAGE_ROWS {
    for x in 0..<STAGE_COLS {
      let tile = tile_at(x, y)
      if !terrain_blocks_tank(tile) {
        continue
      }
      if rects_overlap(hitbox, tile_rect(x, y)) {
        return false
      }
    }
  }
  if player_tank.active &&
    (candidate[X] != original_center[X] || candidate[Y] != original_center[Y]) {
    if rects_overlap(hitbox, tank_rect(player_tank.center)) &&
      (
        candidate[X] != player_tank.center[X] ||
        candidate[Y] != player_tank.center[Y]
      ) {
      return false
    }
  }
  for enemy in enemy_tanks {
    if !enemy.active {
      continue
    }
    if rects_overlap(hitbox, tank_rect(enemy.center)) &&
      (candidate[X] != enemy.center[X] || candidate[Y] != enemy.center[Y]) {
      return false
    }
  }
  true
}

///|
fn move_tank(
  center : @math.Vec2,
  direction : Direction,
  speed : Double,
  delta : Double,
  turning : Bool,
) -> @math.Vec2 {
  let max_step = speed * delta
  let starting = if turning {
    aligned_center_for_turn(center, direction, max_step)
  } else {
    center
  }
  let step = direction_step(direction, max_step)
  let candidate = vec2(starting[X] + step[X], starting[Y] + step[Y])
  let hitbox = tank_rect(candidate)
  if hitbox.left < BOARD_LEFT ||
    hitbox.top < BOARD_TOP ||
    hitbox.left + hitbox.width > BOARD_RIGHT ||
    hitbox.top + hitbox.height > BOARD_BOTTOM {
    return starting
  }
  for y in 0..<STAGE_ROWS {
    for x in 0..<STAGE_COLS {
      let tile = tile_at(x, y)
      if !terrain_blocks_tank(tile) {
        continue
      }
      if rects_overlap(hitbox, tile_rect(x, y)) {
        return starting
      }
    }
  }
  candidate
}

///|
fn can_tank_overlap_enemy(center : @math.Vec2, enemy_index : Int) -> Bool {
  for index in 0..<MAX_ACTIVE_ENEMIES {
    if index == enemy_index || !enemy_tanks[index].active {
      continue
    }
    if rects_overlap(tank_rect(center), tank_rect(enemy_tanks[index].center)) {
      return false
    }
  }
  if player_tank.active &&
    rects_overlap(tank_rect(center), tank_rect(player_tank.center)) {
    return false
  }
  true
}

///|
fn can_player_move_to(center : @math.Vec2) -> Bool {
  if !player_tank.active {
    return false
  }
  for enemy in enemy_tanks {
    if enemy.active && rects_overlap(tank_rect(center), tank_rect(enemy.center)) {
      return false
    }
  }
  true
}

///|
fn decrement_timers(delta : Double) -> Unit {
  if player_tank.active {
    player_tank.fire_cooldown = clamp_double(
      player_tank.fire_cooldown - delta,
      0.0,
      PLAYER_FIRE_COOLDOWN,
    )
    player_tank.born_seconds = clamp_double(
      player_tank.born_seconds - delta,
      0.0,
      SPAWN_FLASH_SECONDS,
    )
    player_tank.shield_seconds = if player_tank.shield_seconds > 0.0 {
      player_tank.shield_seconds - delta
    } else {
      0.0
    }
  }
  if campaign_state.freeze_seconds > 0.0 {
    campaign_state.freeze_seconds = if campaign_state.freeze_seconds - delta <
      0.0 {
      0.0
    } else {
      campaign_state.freeze_seconds - delta
    }
  }
  if campaign_state.shovel_seconds > 0.0 {
    campaign_state.shovel_seconds = if campaign_state.shovel_seconds - delta <
      0.0 {
      0.0
    } else {
      campaign_state.shovel_seconds - delta
    }
    if campaign_state.shovel_seconds == 0.0 {
      apply_fortress_material(Brick)
    }
  }
  if active_powerup.active {
    active_powerup.seconds_remaining -= delta
    if active_powerup.seconds_remaining <= 0.0 {
      active_powerup.active = false
    }
  }
  for index in 0..<MAX_ACTIVE_ENEMIES {
    if !enemy_tanks[index].active {
      continue
    }
    enemy_tanks[index].fire_cooldown = if enemy_tanks[index].fire_cooldown > 0.0 {
      enemy_tanks[index].fire_cooldown - delta
    } else {
      0.0
    }
    enemy_tanks[index].born_seconds = if enemy_tanks[index].born_seconds > 0.0 {
      enemy_tanks[index].born_seconds - delta
    } else {
      0.0
    }
    enemy_tanks[index].shield_seconds = if enemy_tanks[index].shield_seconds >
      0.0 {
      enemy_tanks[index].shield_seconds - delta
    } else {
      0.0
    }
    enemy_tanks[index].turn_seconds -= delta
  }
  for index in 0..<MAX_EXPLOSIONS {
    if explosions[index].active {
      explosions[index].seconds_remaining -= delta
      if explosions[index].seconds_remaining <= 0.0 {
        explosions[index] = default_explosion_state()
      }
    }
  }
}

///|
fn apply_powerup(kind : PowerUpKind) -> Unit {
  match kind {
    Helmet => player_tank.shield_seconds = HELMET_SECONDS
    Timer => campaign_state.freeze_seconds = TIMER_SECONDS
    Shovel => {
      campaign_state.shovel_seconds = SHOVEL_SECONDS
      apply_fortress_material(Steel)
    }
    Star => player_tank.rank = next_rank(player_tank.rank)
    Grenade =>
      for index in 0..<MAX_ACTIVE_ENEMIES {
        if enemy_tanks[index].active {
          destroy_enemy(index)
        }
      }
    Tank => campaign_state.lives += 1
  }
  active_powerup.active = false
}

///|
fn maybe_collect_powerup() -> Unit {
  if player_tank.active &&
    active_powerup.active &&
    rects_overlap(
      tank_rect(player_tank.center),
      powerup_rect(active_powerup.center),
    ) {
    apply_powerup(active_powerup.kind)
  }
}

///|
fn try_destroy_tile(projectile_index : Int, grid_x : Int, grid_y : Int) -> Bool {
  let tile = tile_at(grid_x, grid_y)
  match tile {
    Brick => {
      set_tile(grid_x, grid_y, Empty)
      true
    }
    Steel =>
      if projectiles[projectile_index].can_break_steel {
        set_tile(grid_x, grid_y, Empty)
        true
      } else {
        false
      }
    Base => {
      campaign_state.base_destroyed = true
      set_game_over()
      true
    }
    _ => false
  }
}

///|
fn update_projectiles(delta : Double) -> Unit {
  for index in 0..<MAX_PROJECTILES {
    if !projectiles[index].active {
      continue
    }
    let step = direction_step(
      projectiles[index].direction,
      projectiles[index].speed * delta,
    )
    projectiles[index].center = vec2(
      projectiles[index].center[X] + step[X],
      projectiles[index].center[Y] + step[Y],
    )
    let center = projectiles[index].center
    if center[X] < BOARD_LEFT ||
      center[X] > BOARD_RIGHT ||
      center[Y] < BOARD_TOP ||
      center[Y] > BOARD_BOTTOM {
      destroy_projectile(index, false)
      continue
    }
    let (grid_x, grid_y) = world_to_grid(center)
    let tile = tile_at(grid_x, grid_y)
    if terrain_blocks_bullet(tile) {
      ignore(try_destroy_tile(index, grid_x, grid_y))
      destroy_projectile(index, true)
      if campaign_state.phase == GameOver {
        return
      }
      continue
    }
    match projectiles[index].owner {
      Player =>
        for enemy_index in 0..<MAX_ACTIVE_ENEMIES {
          if !enemy_tanks[enemy_index].active ||
            enemy_tanks[enemy_index].born_seconds > 0.0 ||
            enemy_tanks[enemy_index].shield_seconds > 0.0 {
            continue
          }
          if rects_overlap(
              projectile_rect(center),
              tank_rect(enemy_tanks[enemy_index].center),
            ) {
            destroy_projectile(index, true)
            enemy_tanks[enemy_index].hp -= 1
            if enemy_tanks[enemy_index].hp <= 0 {
              destroy_enemy(enemy_index)
            }
            break
          }
        }
      Enemy =>
        if player_tank.active &&
          player_tank.born_seconds <= 0.0 &&
          rects_overlap(projectile_rect(center), tank_rect(player_tank.center)) {
          destroy_projectile(index, true)
          if player_tank.shield_seconds <= 0.0 {
            destroy_player()
            if campaign_state.phase == GameOver {
              return
            }
          }
        }
    }
  }

  for left in 0..<MAX_PROJECTILES {
    if !projectiles[left].active {
      continue
    }
    for right in (left + 1)..<MAX_PROJECTILES {
      if !projectiles[right].active ||
        projectiles[left].owner == projectiles[right].owner {
        continue
      }
      if rects_overlap(
          projectile_rect(projectiles[left].center),
          projectile_rect(projectiles[right].center),
        ) {
        destroy_projectile(left, true)
        destroy_projectile(right, true)
        break
      }
    }
  }
}

///|
fn maybe_finish_stage() -> Unit {
  if campaign_state.phase != Playing {
    return
  }
  if campaign_state.queue_index >= ENEMIES_PER_STAGE &&
    active_enemy_count() == 0 {
    set_stage_clear()
  }
}

///|
fn enemy_fire_direction(enemy : TankState) -> Direction {
  if player_tank.active {
    let dx = player_tank.center[X] - enemy.center[X]
    let dy = player_tank.center[Y] - enemy.center[Y]
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
  } else {
    let (base_x, base_y) = current_base_grid.val
    let base_center = tile_center(base_x, base_y)
    let dx = base_center[X] - enemy.center[X]
    let dy = base_center[Y] - enemy.center[Y]
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
}

///|
fn update_enemies(delta : Double) -> Unit {
  if campaign_state.freeze_seconds > 0.0 {
    return
  }
  for index in 0..<MAX_ACTIVE_ENEMIES {
    if !enemy_tanks[index].active {
      continue
    }
    if enemy_tanks[index].born_seconds > 0.0 {
      continue
    }
    if enemy_tanks[index].turn_seconds <= 0.0 {
      enemy_tanks[index].direction = choose_enemy_direction(enemy_tanks[index])
      enemy_tanks[index].turn_seconds = ENEMY_TURN_SECONDS +
        index.to_double() * 0.09
    }
    let next_center = move_tank(
      enemy_tanks[index].center,
      enemy_tanks[index].direction,
      enemy_move_speed(enemy_tanks[index].kind),
      delta,
      false,
    )
    if can_tank_overlap_enemy(next_center, index) {
      enemy_tanks[index].center = next_center
    } else {
      enemy_tanks[index].direction = choose_enemy_direction(enemy_tanks[index])
    }
    let fire_direction = enemy_fire_direction(enemy_tanks[index])
    enemy_tanks[index].direction = fire_direction
    if enemy_tanks[index].fire_cooldown <= 0.0 &&
      count_active_projectiles(Enemy) < MAX_ACTIVE_ENEMIES &&
      line_clear_for_enemy_fire(enemy_tanks[index].center, fire_direction) {
      if spawn_projectile(
          Enemy,
          muzzle_position(enemy_tanks[index].center, fire_direction),
          fire_direction,
          ENEMY_PROJECTILE_SPEED,
          false,
        ) {
        enemy_tanks[index].fire_cooldown = enemy_fire_cooldown(
          enemy_tanks[index].kind,
        )
      }
    }
  }
}

///|
fn tick_spawn_queue(delta : Double) -> Unit {
  if campaign_state.queue_index >= ENEMIES_PER_STAGE {
    return
  }
  if active_enemy_count() >= MAX_ACTIVE_ENEMIES {
    return
  }
  campaign_state.spawn_seconds -= delta
  if campaign_state.spawn_seconds > 0.0 {
    return
  }
  if spawn_enemy_from_queue() {
    campaign_state.spawn_seconds = SPAWN_INTERVAL_SECONDS
  }
}

///|
fn tick_respawn(delta : Double) -> Unit {
  if player_tank.active || campaign_state.pending_respawn_seconds <= 0.0 {
    return
  }
  campaign_state.pending_respawn_seconds -= delta
  if campaign_state.pending_respawn_seconds <= 0.0 {
    let (spawn_x, spawn_y) = current_player_spawn.val
    reset_player_state(tile_center(spawn_x, spawn_y), false)
  }
}

///|
fn update_playing(
  delta : Double,
  desired_direction : Direction?,
  fire_requested : Bool,
) -> Unit {
  decrement_timers(delta)
  tick_respawn(delta)
  if fire_requested {
    ignore(try_fire_player())
  }
  if player_tank.active {
    let tank_tile = tile_at(
      world_to_grid(player_tank.center).0,
      world_to_grid(player_tank.center).1,
    )
    let direction_to_use = match desired_direction {
      Some(direction) => Some(direction)
      None =>
        if terrain_is_slippery(tank_tile) {
          Some(player_tank.direction)
        } else {
          None
        }
    }
    match direction_to_use {
      Some(direction) => {
        let turning = direction != player_tank.direction
        player_tank.direction = direction
        let next_center = move_tank(
          player_tank.center,
          direction,
          player_move_speed(player_tank.rank),
          delta,
          turning,
        )
        if can_player_move_to(next_center) {
          player_tank.center = next_center
        }
      }
      None => ()
    }
  }
  update_enemies(delta)
  update_projectiles(delta)
  if campaign_state.phase == Playing {
    maybe_collect_powerup()
    tick_spawn_queue(delta)
    maybe_finish_stage()
  }
}

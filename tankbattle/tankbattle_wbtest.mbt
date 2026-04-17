///|
fn reset_test_stage(index : Int) -> Unit {
  ensure_runtime_storage()
  start_stage(index, false)
  campaign_state.phase = Playing
  campaign_state.phase_seconds = 0.0
  campaign_state.queue_index = 0
  campaign_state.spawn_seconds = 0.0
  campaign_state.freeze_seconds = 0.0
  campaign_state.shovel_seconds = 0.0
  campaign_state.pending_respawn_seconds = 0.0
  campaign_state.base_destroyed = false
  active_powerup.active = false
  active_powerup.seconds_remaining = 0.0
}

///|
fn activate_projectile(
  index : Int,
  owner : TankOwner,
  center : @math.Vec2,
  direction : Direction,
  can_break_steel? : Bool = false,
) -> Unit {
  projectiles[index] = default_projectile_state()
  projectiles[index].active = true
  projectiles[index].owner = owner
  projectiles[index].center = center
  projectiles[index].direction = direction
  projectiles[index].speed = 0.0
  projectiles[index].can_break_steel = can_break_steel
}

///|
fn activate_enemy(
  index : Int,
  kind : EnemyKind,
  center : @math.Vec2,
  hp? : Int = enemy_hit_points(kind),
  drop? : PowerUpKind? = None,
) -> Unit {
  enemy_tanks[index] = default_enemy_state(kind~)
  enemy_tanks[index].active = true
  enemy_tanks[index].center = center
  enemy_tanks[index].born_seconds = 0.0
  enemy_tanks[index].shield_seconds = 0.0
  enemy_tanks[index].hp = hp
  enemy_tanks[index].carrier_drop = drop
}

///|
test "terrain rules match battle city semantics" {
  assert_true(terrain_blocks_tank(Brick))
  assert_true(terrain_blocks_tank(Steel))
  assert_true(terrain_blocks_tank(Water))
  assert_false(terrain_blocks_tank(Forest))
  assert_false(terrain_blocks_tank(Ice))
  assert_true(terrain_blocks_bullet(Brick))
  assert_true(terrain_blocks_bullet(Steel))
  assert_false(terrain_blocks_bullet(Water))
  assert_true(terrain_uses_overlay(Forest))
  assert_true(terrain_is_slippery(Ice))
}

///|
test "player movement keeps upward direction and turn alignment stays smooth" {
  reset_test_stage(0)
  let start = tile_center(3, 12)
  let upward = move_tank(start, Up, player_move_speed(Basic), 1.0 / 60.0, false)
  assert_true(upward[Y] < start[Y])

  let offset = vec2(start[X], start[Y] - 11.0)
  let turned = move_tank(
    offset,
    Right,
    player_move_speed(Basic),
    1.0 / 60.0,
    true,
  )
  let max_step = player_move_speed(Basic) / 60.0 + 0.001
  assert_true(turned[X] > offset[X])
  assert_true(abs_double(turned[Y] - offset[Y]) <= max_step)
}

///|
test "player rank upgrades change projectile cap and steel breaking" {
  reset_test_stage(0)
  assert_true(player_tank.rank == Basic)
  assert_eq(player_projectile_limit(player_tank.rank), 1)
  assert_false(player_can_break_steel(player_tank.rank))

  apply_powerup(Star)
  apply_powerup(Star)
  apply_powerup(Star)

  assert_true(player_tank.rank == Power)
  assert_eq(player_projectile_limit(player_tank.rank), 2)
  assert_true(player_can_break_steel(player_tank.rank))
}

///|
test "helmet and shovel powerups apply and expire" {
  reset_test_stage(0)
  apply_fortress_material(Brick)
  player_tank.shield_seconds = 0.0

  apply_powerup(Helmet)
  assert_true(player_tank.shield_seconds >= HELMET_SECONDS)

  apply_powerup(Shovel)
  for position in fortress_positions {
    let (x, y) = position
    assert_true(tile_at(x, y) == Steel)
  }

  decrement_timers(SHOVEL_SECONDS + 0.2)
  for position in fortress_positions {
    let (x, y) = position
    assert_true(tile_at(x, y) == Brick)
  }
}

///|
test "tick spawn queue creates active enemies and stage clear waits for queue empty" {
  reset_test_stage(0)
  assert_eq(active_enemy_count(), 0)
  tick_spawn_queue(0.1)
  assert_eq(active_enemy_count(), 1)
  assert_eq(campaign_state.queue_index, 1)

  for index in 0..<MAX_ACTIVE_ENEMIES {
    enemy_tanks[index] = default_enemy_state()
  }
  campaign_state.queue_index = ENEMIES_PER_STAGE
  maybe_finish_stage()
  assert_true(campaign_state.phase == StageClear)
}

///|
test "projectiles resolve brick steel base and projectile collisions" {
  reset_test_stage(0)

  set_tile(2, 2, Brick)
  activate_projectile(0, Player, tile_center(2, 2), Up)
  update_projectiles(0.0)
  assert_true(tile_at(2, 2) == Empty)

  set_tile(3, 2, Steel)
  activate_projectile(0, Player, tile_center(3, 2), Up)
  update_projectiles(0.0)
  assert_true(tile_at(3, 2) == Steel)

  activate_projectile(0, Player, tile_center(3, 2), Up, can_break_steel=true)
  update_projectiles(0.0)
  assert_true(tile_at(3, 2) == Empty)

  let (base_x, base_y) = current_base_grid.val
  activate_projectile(0, Enemy, tile_center(base_x, base_y), Down)
  update_projectiles(0.0)
  assert_true(campaign_state.base_destroyed)
  assert_true(campaign_state.phase == GameOver)

  reset_test_stage(0)
  activate_projectile(0, Player, vec2(220.0, 220.0), Up)
  activate_projectile(1, Enemy, vec2(220.0, 220.0), Down)
  update_projectiles(0.0)
  assert_false(projectiles[0].active)
  assert_false(projectiles[1].active)
}

///|
test "strong armor enemy needs repeated hits and drops carrier powerup" {
  reset_test_stage(0)
  set_tile(6, 4, Empty)
  let center = tile_center(6, 4)
  activate_enemy(0, Armor, center, drop=Some(Star))

  activate_projectile(0, Player, center, Up)
  update_projectiles(0.0)
  assert_true(enemy_tanks[0].active)
  assert_eq(enemy_tanks[0].hp, 3)

  activate_projectile(0, Player, center, Up)
  update_projectiles(0.0)
  activate_projectile(0, Player, center, Up)
  update_projectiles(0.0)
  assert_true(enemy_tanks[0].active)
  assert_eq(enemy_tanks[0].hp, 1)

  activate_projectile(0, Player, center, Up)
  update_projectiles(0.0)
  assert_false(enemy_tanks[0].active)
  assert_true(active_powerup.active)
  assert_true(active_powerup.kind == Star)
}

///|
test "timer freezes enemies and tank grants an extra life" {
  reset_test_stage(0)
  activate_enemy(0, Fast, tile_center(1, 1))
  let before = enemy_tanks[0].center
  let lives_before = campaign_state.lives
  apply_powerup(Timer)
  apply_powerup(Tank)
  update_enemies(0.5)
  assert_true(enemy_tanks[0].center == before)
  assert_eq(campaign_state.lives, lives_before + 1)
}

///|
test "final player death ends the campaign" {
  reset_test_stage(0)
  campaign_state.lives = 1
  player_tank.active = true
  player_tank.born_seconds = 0.0
  player_tank.shield_seconds = 0.0
  destroy_player()
  assert_eq(campaign_state.lives, 0)
  assert_true(campaign_state.phase == GameOver)
}

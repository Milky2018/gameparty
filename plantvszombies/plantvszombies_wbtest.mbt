///|
test "wave plans ramp as expected" {
  assert_eq(wave_plan_count(0), 5)
  assert_eq(wave_plan_count(1), 7)
  assert_eq(wave_plan_count(2), 9)
  assert_true(wave_plan_interval(0) > wave_plan_interval(1))
  assert_true(wave_plan_speed(2) > wave_plan_speed(0))
  assert_true(wave_plan_hp(2) > wave_plan_hp(0))
}

///|
test "plant placement requires empty cell and enough sun" {
  assert_true(can_place_plant(Shooter, 150, false))
  assert_true(!can_place_plant(Shooter, 99, false))
  assert_true(!can_place_plant(Wall, 50, true))
  assert_true(can_place_plant(Wall, 50, false))
}

///|
test "projectile collision uses lane x overlap" {
  assert_true(projectile_hits_zombie(320.0, 334.0))
  assert_true(!projectile_hits_zombie(320.0, 370.0))
}

///|
test "zombie house threshold is on the left edge" {
  assert_true(zombie_reaches_house(HOUSE_X + 12.0))
  assert_true(!zombie_reaches_house(HOUSE_X + 48.0))
}

///|
test "world to cell maps to expected grid positions" {
  let center = cell_center(3, 2)
  let (x, y) = world_to_cell(center)
  assert_eq(x, 3)
  assert_eq(y, 2)
}

///|
test "finalize wave state declares a win after the last wave is cleared" {
  phase.val = Playing
  zombies.clear()
  wave_state.val = {
    wave_index: WAVE_COUNT,
    spawned_in_wave: 0,
    spawn_timer: 0.0,
  }
  finalize_wave_state()
  assert_true(phase.val is Won)
}

///|
test "advance zombies declares a loss when the house is reached" {
  phase.val = Playing
  plants.clear()
  zombies.clear()
  zombies.push({
    x: HOUSE_X + 10.0,
    y: BOARD_TOP + 20.0,
    lane: 0,
    hp: 1,
    speed: 0.0,
    chew_timer: 0.0,
    entity: @entity.Entity::new(),
    alive: true,
  })
  advance_zombies(0.0)
  assert_true(phase.val is Lost)
}

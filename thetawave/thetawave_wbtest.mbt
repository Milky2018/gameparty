///|
test "clamp keeps value inside bounds" {
  assert_eq(clamp(5.0, 0.0, 10.0), 5.0)
  assert_eq(clamp(-1.0, 0.0, 10.0), 0.0)
  assert_eq(clamp(42.0, 0.0, 10.0), 10.0)
}

///|
test "overlaps checks circle intersection" {
  assert_true(overlaps(@math.Vec2D(0.0, 0.0), 3.0, @math.Vec2D(5.0, 0.0), 2.0))
  assert_true(!overlaps(@math.Vec2D(0.0, 0.0), 2.0, @math.Vec2D(5.1, 0.0), 2.0))
}

///|
test "campaign includes three ordered boss stages" {
  let boss_kinds = []
  for stage in run_stages {
    if stage.kind is Boss && stage.boss_kind is Some(kind) {
      boss_kinds.push(kind)
    }
  }
  assert_eq(boss_kinds.length(), 3)
  assert_true(boss_kinds[0] is Ferritharax)
  assert_true(boss_kinds[1] is MechaFerritharax)
  assert_true(boss_kinds[2] is MechaSaucetron)
}

///|
test "campaign starts with tutorial stage" {
  assert_true(run_stages.length() >= 1)
  assert_true(run_stages[0].kind is Tutorial)
  assert_true(run_stages[0].label == "Tutorial")
}

///|
test "all boss kinds use boss drop list with gain projectiles" {
  assert_true(drop_list_for_enemy(Ferritharax) is Boss)
  assert_true(drop_list_for_enemy(MechaFerritharax) is Boss)
  assert_true(drop_list_for_enemy(MechaSaucetron) is Boss)
  let mut has_gain_projectiles = false
  for rule in drop_rules(Boss) {
    if rule.kind is GainProjectiles {
      has_gain_projectiles = true
      break
    }
  }
  assert_true(has_gain_projectiles)
  assert_eq(boss_item_drops.length(), 1)
  assert_true(boss_item_drops[0] is EnhancedPlating)
}

///|
test "campaign includes asteroid and hard phases before final boss" {
  assert_true(run_stages.length() >= 24)
  assert_true(run_stages[15].label == "Harvest the Asteroids!")
  assert_true(run_stages[17].label == "Destroy the invaders!")
  assert_true(run_stages[23].boss_kind is Some(MechaSaucetron))
}

///|
test "boss enemies use larger collision radius" {
  assert_eq(enemy_radius(Pawn), ENEMY_HALF_SIZE)
  assert_eq(enemy_radius(Hauler), 10.0)
  assert_eq(enemy_radius(Ferritharax), 22.0)
  assert_eq(enemy_radius(MechaFerritharax), 22.0)
  assert_eq(enemy_radius(MechaSaucetron), 22.0)
}

///|
test "enhanced plating increases max hull and fully heals" {
  let old_max_hull = game_state.max_hull
  let old_hull = game_state.hull
  let old_plating_count = game_state.plating_count
  game_state.max_hull = 80
  game_state.hull = 24
  game_state.plating_count = 0

  apply_item(EnhancedPlating)

  assert_eq(game_state.max_hull, 180)
  assert_eq(game_state.hull, 180)
  assert_eq(game_state.plating_count, 1)

  game_state.max_hull = old_max_hull
  game_state.hull = old_hull
  game_state.plating_count = old_plating_count
}

///|
test "cooldown multiplier decays as money increases" {
  let old_money = game_state.money
  let old_base = game_state.base_cooldown_multiplier
  let old_cooldown = game_state.cooldown_multiplier

  game_state.base_cooldown_multiplier = 2.0
  game_state.money = 0
  refresh_cooldown_multiplier()
  let cooldown_at_zero = game_state.cooldown_multiplier

  game_state.money = 30
  refresh_cooldown_multiplier()
  let cooldown_at_thirty = game_state.cooldown_multiplier

  assert_true(cooldown_at_zero > cooldown_at_thirty)
  assert_true(cooldown_at_thirty > 1.0)

  game_state.money = old_money
  game_state.base_cooldown_multiplier = old_base
  game_state.cooldown_multiplier = old_cooldown
}

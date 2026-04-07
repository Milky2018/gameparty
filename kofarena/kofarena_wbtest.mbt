///|
fn make_test_fighter(
  id : PlayerId,
  facing : Facing,
  x : Double,
  y : Double,
) -> FighterState {
  {
    id,
    alive: true,
    x,
    y,
    vx: 0.0,
    vy: 0.0,
    facing,
    pose: Idle,
    on_ground: true,
    crouching: false,
    health: MAX_HEALTH,
    attack_kind: None,
    attack_elapsed: 0.0,
    attack_cooldown: 0.0,
    attack_hit: false,
    hitstun: 0.0,
    invuln: 0.0,
    backstep_timer: 0.0,
    ai_timer: 0.0,
    last_human_input: 0.0,
    input_mode: Human,
  }
}

///|
fn approx_zero(value : Double) -> Bool {
  abs_double(value) < 0.0001
}

///|
test "attack timing windows and cooldown are consistent" {
  assert_true(!attack_active(Light, LIGHT_STARTUP - 0.001))
  assert_true(attack_active(Light, LIGHT_STARTUP + 0.001))
  assert_true(!attack_active(Light, LIGHT_STARTUP + LIGHT_ACTIVE + 0.001))
  assert_true(
    approx_zero(
      attack_total_time(Light) - (LIGHT_STARTUP + LIGHT_ACTIVE + LIGHT_RECOVERY),
    ),
  )

  let fighter = make_test_fighter(P1, Right, 100.0, 400.0)
  start_attack(fighter, Heavy)
  let heavy_started = match fighter.attack_kind {
    Some(Heavy) => true
    None => false
    Some(_) => false
  }
  assert_true(heavy_started)
  assert_true(approx_zero(fighter.attack_elapsed))
  assert_true(approx_zero(fighter.attack_cooldown - HEAVY_COOLDOWN))
  assert_true(!fighter.attack_hit)
}

///|
test "active hitbox resolves once and applies damage" {
  let attacker = make_test_fighter(P1, Right, 100.0, 400.0)
  let defender = make_test_fighter(P2, Left, 140.0, 400.0)
  start_attack(attacker, Light)
  attacker.attack_elapsed = LIGHT_STARTUP + 0.01

  resolve_attack_hit(attacker, defender)

  assert_true(attacker.attack_hit)
  assert_eq(defender.health, MAX_HEALTH - LIGHT_DAMAGE)
  assert_true(defender.hitstun > 0.0)
  assert_true(defender.invuln > 0.0)
}

///|
test "inactive attack window does not deal damage" {
  let attacker = make_test_fighter(P1, Right, 100.0, 400.0)
  let defender = make_test_fighter(P2, Left, 140.0, 400.0)
  start_attack(attacker, Light)
  attacker.attack_elapsed = LIGHT_STARTUP + LIGHT_ACTIVE + 0.01

  resolve_attack_hit(attacker, defender)

  assert_true(!attacker.attack_hit)
  assert_eq(defender.health, MAX_HEALTH)
  assert_true(approx_zero(defender.hitstun))
}

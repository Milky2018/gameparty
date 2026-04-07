///|
fn reset_for_test() -> Unit {
  reset_run_state(123456)
  best_score.val = 0
}

///|
test "difficulty tier ramps every 120 seconds and clamps at tier 4" {
  assert_eq(difficulty_tier_for_elapsed(0.0), 0)
  assert_eq(difficulty_tier_for_elapsed(119.99), 0)
  assert_eq(difficulty_tier_for_elapsed(120.0), 1)
  assert_eq(difficulty_tier_for_elapsed(240.0), 2)
  assert_eq(difficulty_tier_for_elapsed(480.0), 4)
  assert_eq(difficulty_tier_for_elapsed(9999.0), 4)
}

///|
test "combo multiplier starts at 1 and clamps at 3" {
  assert_eq(combo_multiplier(0), 1.0)
  assert_eq(combo_multiplier(1), 1.0)
  assert_eq(combo_multiplier(2), 1.1)
  assert_eq(combo_multiplier(10), 1.9)
  assert_eq(combo_multiplier(40), 3.0)
}

///|
test "regen step restores charge by accumulated regen rate" {
  let (charge1, accum1) = regen_charge_step(5, 8, 0.0, INITIAL_REGEN_RATE, 0.75)
  assert_eq(charge1, 6)
  assert_eq(accum1, 0.0)

  let (charge2, accum2) = regen_charge_step(7, 8, 0.2, INITIAL_REGEN_RATE, 0.4)
  assert_eq(charge2, 7)
  assert_true(accum2 > 0.7 && accum2 < 0.8)

  let (charge3, accum3) = regen_charge_step(8, 8, 0.9, INITIAL_REGEN_RATE, 1.0)
  assert_eq(charge3, 8)
  assert_eq(accum3, 0.0)
}

///|
test "chest trigger supports random trigger and pity trigger" {
  assert_true(chest_should_trigger(0.03, 3.0))
  assert_true(!chest_should_trigger(0.5, 10.0))
  assert_true(chest_should_trigger(0.99, CHEST_PITY_SECONDS))
  assert_true(chest_should_trigger(0.99, CHEST_PITY_SECONDS + 1.0))
}

///|
test "upgrade conflicts and unique rules are enforced" {
  reset_for_test()
  apply_upgrade(HeavyCoin)
  assert_true(!upgrade_can_roll(HeavyCoin))
  assert_true(!upgrade_can_roll(CooldownCut))
  assert_true(!upgrade_can_roll(RegenBoost))
  assert_true(upgrade_can_roll(ScoreBoost))

  reset_for_test()
  apply_upgrade(SplitCoin)
  assert_true(!upgrade_can_roll(SplitCoin))
  assert_true(upgrade_can_roll(MaxCharge))
}

///|
test "apply upgrade mutates economy and score settings" {
  reset_for_test()
  let base_max = economy_state.coin_charge_max
  let base_regen = economy_state.regen_rate
  let base_cd = economy_state.drop_cooldown
  let base_score_mul = run_state.score_multiplier
  let base_combo_window = run_state.combo_window

  apply_upgrade(MaxCharge)
  assert_eq(economy_state.coin_charge_max, base_max + 2)
  assert_true(economy_state.coin_charge <= economy_state.coin_charge_max)

  apply_upgrade(RegenBoost)
  assert_true(economy_state.regen_rate > base_regen)

  apply_upgrade(CooldownCut)
  assert_true(economy_state.drop_cooldown < base_cd)

  apply_upgrade(ScoreBoost)
  assert_true(run_state.score_multiplier > base_score_mul)

  apply_upgrade(ComboWindowBoost)
  assert_true(run_state.combo_window > base_combo_window)
}

///|
test "rolled chest options stay within eligible pool and max count" {
  reset_for_test()
  apply_upgrade(HeavyCoin)
  let options = roll_chest_options()
  assert_true(options.length() <= 3)
  for option in options {
    assert_true(option != HeavyCoin)
    assert_true(option != RegenBoost)
    assert_true(option != CooldownCut)
  }
}

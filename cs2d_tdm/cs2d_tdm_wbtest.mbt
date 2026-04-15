///|
test "cs2d_tdm plugin validates" {
  assert_eq(@topdown_shooter.validate_plugin(plugin), None)
}

///|
test "cs2d_tdm plugin exposes at least one bot profile and four pickups" {
  assert_true(plugin.bots.length() >= 1)
  assert_eq(plugin.pickup_spawns.length(), 4)
}

///|
test "cs2d_tdm match rules are arcade-sized" {
  assert_eq(plugin.score_rules.match_seconds.to_int(), 180)
  assert_true(plugin.score_rules.kill_score > 0)
}

///|
test "rogue proto plugin passes platform validation" {
  assert_eq(@topdown_action.validate_plugin(plugin), None)
}

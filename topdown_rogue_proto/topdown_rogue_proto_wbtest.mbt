///|
test "rogue proto plugin passes platform validation" {
  assert_eq(@topdown_platform.validate_plugin(plugin), None)
}

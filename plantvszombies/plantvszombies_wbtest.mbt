///|
test "plantvszombies plugin passes topdown platform validation" {
  assert_eq(@topdown_platform.validate_plugin(plugin), None)
}

///|
test "plantvszombies map has five lane spawn tags" {
  let mut lane1 = false
  let mut lane2 = false
  let mut lane3 = false
  let mut lane4 = false
  let mut lane5 = false
  for _, rule in plugin.map.legend {
    match rule.enemy_spawn_tag {
      Some(tag) =>
        if tag == "lane1" {
          lane1 = true
        } else if tag == "lane2" {
          lane2 = true
        } else if tag == "lane3" {
          lane3 = true
        } else if tag == "lane4" {
          lane4 = true
        } else if tag == "lane5" {
          lane5 = true
        }
      None => ()
    }
  }
  assert_true(lane1 && lane2 && lane3 && lane4 && lane5)
}

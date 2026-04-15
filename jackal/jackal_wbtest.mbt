///|
test "jackal plugin passes topdown platform validation" {
  assert_eq(@topdown_action.validate_plugin(plugin), None)
}

///|
test "jackal waves use only declared spawn tags" {
  let tagged_spawns = Map::new()
  for _, rule in plugin.map.legend {
    match rule.actor_spawn_tag {
      Some(tag) => tagged_spawns.set(tag, true)
      None => ()
    }
  }
  for wave in plugin.waves {
    for entry in wave.entries {
      match entry.spawn_tag {
        Some(tag) => assert_true(tagged_spawns.get(tag).unwrap_or(false))
        None => ()
      }
    }
  }
}

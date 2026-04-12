///|
test "supermario plugin exposes two valid levels" {
  let plugin = plugin_def()
  inspect(plugin.meta.id, content="supermario")
  inspect(plugin.levels.length(), content="2")
  inspect(plugin.levels[0].name, content="Green Plains")
  inspect(plugin.levels[1].name, content="Castle Gauntlet")
}

///|
test "question blocks in plugin carry payloads" {
  let plugin = plugin_def()
  let level = plugin.levels[0]
  let mut found_payload = false
  for block in level.blocks {
    if block.payload is Some(_) {
      found_payload = true
      break
    }
  }
  inspect(found_payload, content="true")
}

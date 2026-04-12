///|
test "celeste plugin enables dash and wall jump" {
  let plugin = plugin_def()
  inspect(plugin.meta.id, content="celeste")
  inspect(plugin.levels.length(), content="2")
  inspect(plugin.movement is Some(_), content="true")
  match plugin.movement {
    Some(movement) => {
      inspect(movement.max_air_dashes, content="1")
      inspect(movement.allow_wall_jump, content="true")
    }
    None => ()
  }
}

///|
test "celeste levels include hazard spikes" {
  let plugin = plugin_def()
  let mut has_spike = false
  let mut has_dash_crystal = false
  let mut has_spring = false
  for level in plugin.levels {
    for block in level.blocks {
      if block.kind == @platformer_platform.Spike {
        has_spike = true
      }
      if block.kind == @platformer_platform.DashCrystal {
        has_dash_crystal = true
      }
      if block.kind == @platformer_platform.Spring {
        has_spring = true
      }
    }
    if has_spike && has_dash_crystal && has_spring {
      break
    }
  }
  inspect(has_spike, content="true")
  inspect(has_dash_crystal, content="true")
  inspect(has_spring, content="true")
}

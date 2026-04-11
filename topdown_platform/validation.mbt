///|
fn archetype_by_id(plugin : TopDownPluginDef, id : String) -> ArchetypeDef? {
  for archetype in plugin.archetypes {
    if archetype.id == id {
      return Some(archetype)
    }
  }
  None
}

///|
fn skill_by_id(plugin : TopDownPluginDef, id : String) -> SkillDef? {
  for skill in plugin.skills {
    if skill.id == id {
      return Some(skill)
    }
  }
  None
}

///|
fn drop_table_by_id(plugin : TopDownPluginDef, id : String) -> DropTableDef? {
  for table in plugin.drops {
    if table.id == id {
      return Some(table)
    }
  }
  None
}

///|
fn validate_visual(visual : ImageVisualDef, context : String) -> String? {
  if visual.path == "" {
    return Some("\{context} image path must not be empty")
  }
  if visual.scale <= 0.0 {
    return Some("\{context} image scale must be > 0")
  }
  None
}

///|
fn validate_anim(anim : SpriteAnimDef, context : String) -> String? {
  if anim.image == "" {
    return Some("\{context} sprite image must not be empty")
  }
  if anim.frame_width <= 0.0 || anim.frame_height <= 0.0 {
    return Some("\{context} frame size must be > 0")
  }
  if anim.columns <= 0 {
    return Some("\{context} columns must be > 0")
  }
  if anim.frame_count <= 0 {
    return Some("\{context} frame_count must be > 0")
  }
  if anim.fps <= 0.0 {
    return Some("\{context} fps must be > 0")
  }
  if anim.scale <= 0.0 {
    return Some("\{context} scale must be > 0")
  }
  None
}

///|
pub fn validate_plugin(plugin : TopDownPluginDef) -> String? {
  if plugin.meta.id == "" {
    return Some("plugin.meta.id must not be empty")
  }
  if plugin.map.rows.length() == 0 {
    return Some("plugin.map.rows must not be empty")
  }
  let width = plugin.map.rows[0].length()
  if width <= 0 {
    return Some("plugin.map.rows first row must not be empty")
  }
  if plugin.map.tile_size <= 1.0 {
    return Some("plugin.map.tile_size must be > 1.0")
  }
  match
    validate_visual(plugin.map.default_floor_image, "map.default_floor_image") {
    Some(err) => return Some(err)
    None => ()
  }
  for row in plugin.map.rows {
    if row.length() != width {
      return Some("plugin.map.rows must have equal width")
    }
  }
  for code, rule in plugin.map.legend {
    match rule.kind {
      EnemySpawn =>
        match rule.enemy_spawn_tag {
          Some(tag) =>
            if tag == "" {
              return Some("legend '\{code}' enemy_spawn_tag must not be empty")
            }
          None => ()
        }
      _ =>
        if rule.enemy_spawn_tag is Some(_) {
          return Some(
            "legend '\{code}' enemy_spawn_tag is only valid for EnemySpawn tiles",
          )
        }
    }
    match rule.floor_image {
      Some(visual) =>
        match validate_visual(visual, "legend '\{code}' floor") {
          Some(err) => return Some(err)
          None => ()
        }
      None => ()
    }
    match rule.prop_image {
      Some(visual) =>
        match validate_visual(visual, "legend '\{code}' prop") {
          Some(err) => return Some(err)
          None => ()
        }
      None => ()
    }
  }

  let mut player_spawns = 0
  let mut enemy_spawns = 0
  let enemy_spawn_tags : Array[String] = []
  for row = 0; row < plugin.map.rows.length(); row = row + 1 {
    let line = plugin.map.rows[row]
    for col = 0; col < width; col = col + 1 {
      let ch = line.unsafe_get(col).unsafe_to_char()
      match plugin.map.legend.get(ch) {
        Some(rule) =>
          match rule.kind {
            PlayerSpawn => player_spawns += 1
            EnemySpawn => {
              enemy_spawns += 1
              match rule.enemy_spawn_tag {
                Some(tag) => {
                  let mut exists = false
                  for saved in enemy_spawn_tags {
                    if saved == tag {
                      exists = true
                      break
                    }
                  }
                  if !exists {
                    enemy_spawn_tags.push(tag)
                  }
                }
                None => ()
              }
            }
            _ => ()
          }
        None => return Some("map legend missing char '\{ch}'")
      }
    }
  }
  if player_spawns != 1 {
    return Some("map must contain exactly one PlayerSpawn tile")
  }
  if plugin.waves.length() > 0 && enemy_spawns <= 0 {
    return Some("waves configured but map has no EnemySpawn tile")
  }

  if archetype_by_id(plugin, plugin.progression.player_archetype_id) is None {
    return Some(
      "missing player archetype '\{plugin.progression.player_archetype_id}'",
    )
  }

  for archetype in plugin.archetypes {
    if archetype.id == "" {
      return Some("archetype id must not be empty")
    }
    if archetype.max_hp <= 0 {
      return Some("archetype '\{archetype.id}' max_hp must be > 0")
    }
    if archetype.move_speed <= 0.0 {
      return Some("archetype '\{archetype.id}' move_speed must be > 0")
    }
    if archetype.radius <= 2.0 {
      return Some("archetype '\{archetype.id}' radius must be > 2")
    }
    if archetype.preferred_range < 0.0 {
      return Some("archetype '\{archetype.id}' preferred_range must be >= 0")
    }
    if archetype.ai_mode == HoldDistance && archetype.preferred_range <= 0.0 {
      return Some(
        "archetype '\{archetype.id}' HoldDistance ai requires preferred_range > 0",
      )
    }
    match
      validate_anim(
        archetype.sprites.up,
        "archetype '\{archetype.id}' sprites.up",
      ) {
      Some(err) => return Some(err)
      None => ()
    }
    match
      validate_anim(
        archetype.sprites.down,
        "archetype '\{archetype.id}' sprites.down",
      ) {
      Some(err) => return Some(err)
      None => ()
    }
    match
      validate_anim(
        archetype.sprites.left,
        "archetype '\{archetype.id}' sprites.left",
      ) {
      Some(err) => return Some(err)
      None => ()
    }
    match
      validate_anim(
        archetype.sprites.right,
        "archetype '\{archetype.id}' sprites.right",
      ) {
      Some(err) => return Some(err)
      None => ()
    }
    match archetype.primary_skill_id {
      Some(skill_id) =>
        if skill_by_id(plugin, skill_id) is None {
          return Some(
            "archetype '\{archetype.id}' references missing skill '\{skill_id}'",
          )
        }
      None => ()
    }
    match archetype.secondary_skill_id {
      Some(skill_id) =>
        if skill_by_id(plugin, skill_id) is None {
          return Some(
            "archetype '\{archetype.id}' references missing skill '\{skill_id}'",
          )
        }
      None => ()
    }
    match archetype.drop_table_id {
      Some(table_id) =>
        if drop_table_by_id(plugin, table_id) is None {
          return Some(
            "archetype '\{archetype.id}' references missing drop table '\{table_id}'",
          )
        }
      None => ()
    }
  }

  for wave in plugin.waves {
    if wave.entries.length() == 0 {
      return Some("wave '\{wave.id}' has no entries")
    }
    for entry in wave.entries {
      if archetype_by_id(plugin, entry.archetype_id) is None {
        return Some(
          "wave '\{wave.id}' references missing archetype '\{entry.archetype_id}'",
        )
      }
      if entry.count <= 0 {
        return Some("wave '\{wave.id}' entry count must be > 0")
      }
      if entry.spawn_interval < 0.0 {
        return Some("wave '\{wave.id}' entry spawn_interval must be >= 0")
      }
      match entry.spawn_tag {
        Some(tag) =>
          if tag == "" {
            return Some("wave '\{wave.id}' entry spawn_tag must not be empty")
          } else {
            let mut found = false
            for existing in enemy_spawn_tags {
              if existing == tag {
                found = true
                break
              }
            }
            if !found {
              return Some(
                "wave '\{wave.id}' entry spawn_tag '\{tag}' has no matching EnemySpawn tile",
              )
            }
          }
        None => ()
      }
    }
  }

  for table in plugin.drops {
    if table.id == "" {
      return Some("drop table id must not be empty")
    }
    if table.chance < 0.0 || table.chance > 1.0 {
      return Some("drop table '\{table.id}' chance must be in [0,1]")
    }
    if table.items.length() == 0 {
      return Some("drop table '\{table.id}' has no items")
    }
    let mut total_weight = 0
    for item in table.items {
      if item.id == "" {
        return Some("drop item id must not be empty in table '\{table.id}'")
      }
      if item.weight <= 0 {
        return Some(
          "drop item '\{item.id}' in table '\{table.id}' must have positive weight",
        )
      }
      total_weight += item.weight
    }
    if total_weight <= 0 {
      return Some("drop table '\{table.id}' total weight must be positive")
    }
  }

  if plugin.progression.run_seconds <= 0.0 {
    return Some("progression.run_seconds must be > 0")
  }
  if plugin.ui_theme.control_hint == "" {
    return Some("ui_theme.control_hint must not be empty")
  }

  None
}

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
fn contains_tag(tags : Array[String], target : String) -> Bool {
  for tag in tags {
    if tag == target {
      return true
    }
  }
  false
}

///|
fn collect_map_actor_spawn_tags(plugin : TopDownPluginDef) -> Array[String] {
  let tags : Array[String] = []
  for row in plugin.map.rows {
    for col = 0; col < row.length(); col = col + 1 {
      let ch = row.unsafe_get(col).unsafe_to_char()
      match plugin.map.legend.get(ch) {
        Some(rule) =>
          if rule.kind == @topdown_platform.ActorSpawn {
            match rule.actor_spawn_tag {
              Some(tag) =>
                if tag != "" && !contains_tag(tags, tag) {
                  tags.push(tag)
                }
              None => ()
            }
          }
        None => ()
      }
    }
  }
  tags
}

///|
fn count_map_actor_spawn_tiles(plugin : TopDownPluginDef) -> Int {
  let mut count = 0
  for row in plugin.map.rows {
    for col = 0; col < row.length(); col = col + 1 {
      let ch = row.unsafe_get(col).unsafe_to_char()
      match plugin.map.legend.get(ch) {
        Some(rule) =>
          if rule.kind == @topdown_platform.ActorSpawn {
            count += 1
          }
        None => ()
      }
    }
  }
  count
}

///|
fn to_core_archetype(
  archetype : ArchetypeDef,
) -> @topdown_platform.ArchetypeDef {
  {
    id: archetype.id,
    move_speed: archetype.move_speed,
    radius: archetype.radius,
    sprites: archetype.sprites,
  }
}

///|
fn inferred_actor_spawns(
  plugin : TopDownPluginDef,
) -> Array[@topdown_platform.ActorSpawnDef] {
  let actor_spawns : Array[@topdown_platform.ActorSpawnDef] = []
  let seen_tags : Array[String] = []
  for wave in plugin.waves {
    for entry in wave.entries {
      match entry.spawn_tag {
        Some(tag) =>
          if tag != "" && !contains_tag(seen_tags, tag) {
            seen_tags.push(tag)
            actor_spawns.push({
              archetype_id: plugin.progression.player_archetype_id,
              spawn_tag: Some(tag),
              facing: @topdown_platform.Down,
            })
          }
        None => ()
      }
    }
  }
  actor_spawns
}

///|
fn validate_skill(skill : SkillDef) -> String? {
  if skill.id == "" {
    return Some("skill id must not be empty")
  }
  if skill.cooldown < 0.0 {
    return Some("skill '\{skill.id}' cooldown must be >= 0")
  }
  if skill.damage <= 0 {
    return Some("skill '\{skill.id}' damage must be > 0")
  }
  if skill.range <= 0.0 {
    return Some("skill '\{skill.id}' range must be > 0")
  }
  match skill.kind {
    Melee => ()
    Projectile => {
      if skill.projectile_speed <= 0.0 {
        return Some("skill '\{skill.id}' projectile_speed must be > 0")
      }
      if skill.projectile_radius <= 0.0 {
        return Some("skill '\{skill.id}' projectile_radius must be > 0")
      }
    }
  }
  None
}

///|
pub fn validate_plugin(plugin : TopDownPluginDef) -> String? {
  let core_plugin : @topdown_platform.TopDownPluginDef = {
    meta: plugin.meta,
    map: plugin.map,
    player_archetype_id: plugin.progression.player_archetype_id,
    archetypes: plugin.archetypes.map(to_core_archetype),
    actor_spawns: inferred_actor_spawns(plugin),
    ui_theme: plugin.ui_theme,
    hooks: None,
  }
  match @topdown_platform.validate_plugin(core_plugin) {
    Some(error) => return Some("topdown core: \{error}")
    None => ()
  }

  let map_actor_spawn_tags = collect_map_actor_spawn_tags(plugin)
  let map_actor_spawn_tiles = count_map_actor_spawn_tiles(plugin)
  if plugin.waves.length() > 0 && map_actor_spawn_tiles <= 0 {
    return Some("waves configured but map has no ActorSpawn tile")
  }

  for archetype in plugin.archetypes {
    if archetype.max_hp <= 0 {
      return Some("archetype '\{archetype.id}' max_hp must be > 0")
    }
    if archetype.preferred_range < 0.0 {
      return Some("archetype '\{archetype.id}' preferred_range must be >= 0")
    }
    if archetype.ai_mode == HoldDistance && archetype.preferred_range <= 0.0 {
      return Some(
        "archetype '\{archetype.id}' HoldDistance ai requires preferred_range > 0",
      )
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

  for skill in plugin.skills {
    match validate_skill(skill) {
      Some(error) => return Some(error)
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
          } else if !contains_tag(map_actor_spawn_tags, tag) {
            return Some(
              "wave '\{wave.id}' entry spawn_tag '\{tag}' has no matching ActorSpawn tile",
            )
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

  None
}

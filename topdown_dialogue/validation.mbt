///|
fn validate_dialogue_theme(theme : DialogueThemeDef) -> String? {
  if theme.prompt_color_css == "" {
    return Some("dialogue_theme.prompt_color_css must not be empty")
  }
  if theme.speaker_color_css == "" {
    return Some("dialogue_theme.speaker_color_css must not be empty")
  }
  if theme.text_color_css == "" {
    return Some("dialogue_theme.text_color_css must not be empty")
  }
  if theme.hint_color_css == "" {
    return Some("dialogue_theme.hint_color_css must not be empty")
  }
  if theme.panel_color.a < 0.0 || theme.panel_color.a > 1.0 {
    return Some("dialogue_theme.panel_color.a must be in [0, 1]")
  }
  None
}

///|
fn validate_dialogue_script(script : DialogueScriptDef) -> String? {
  if script.id == "" {
    return Some("dialogues: id must not be empty")
  }
  if script.lines.length() == 0 {
    return Some("dialogue '\{script.id}' must contain at least one line")
  }
  for i = 0; i < script.lines.length(); i = i + 1 {
    let line = script.lines[i]
    if line.speaker == "" {
      return Some(
        "dialogue '\{script.id}' line \{i}: speaker must not be empty",
      )
    }
    if line.text == "" {
      return Some("dialogue '\{script.id}' line \{i}: text must not be empty")
    }
  }
  None
}

///|
fn actor_spawn_tag_counts(map : @topdown_platform.MapDef) -> Map[String, Int] {
  let counts : Map[String, Int] = Map::new()
  for row = 0; row < map.rows.length(); row = row + 1 {
    let line = map.rows[row]
    for col = 0; col < line.length(); col = col + 1 {
      let code = line.unsafe_get(col).unsafe_to_char()
      match map.legend.get(code) {
        Some(rule) =>
          match rule.kind {
            @topdown_platform.ActorSpawn =>
              match rule.actor_spawn_tag {
                Some(tag) =>
                  counts.set(
                    tag,
                    match counts.get(tag) {
                      Some(value) => value + 1
                      None => 1
                    },
                  )
                None => ()
              }
            _ => ()
          }
        None => ()
      }
    }
  }
  counts
}

///|
fn build_core_plugin(
  plugin : TopDownPluginDef,
) -> @topdown_platform.TopDownPluginDef {
  let actor_spawns : Array[@topdown_platform.ActorSpawnDef] = []
  for npc in plugin.npcs {
    actor_spawns.push({
      archetype_id: npc.archetype_id,
      spawn_tag: Some(npc.spawn_tag),
      facing: npc.facing,
    })
  }
  {
    meta: plugin.meta,
    map: plugin.map,
    player_archetype_id: plugin.player_archetype_id,
    archetypes: plugin.archetypes,
    actor_spawns,
    ui_theme: plugin.ui_theme,
    hooks: None,
  }
}

///|
pub fn validate_plugin(plugin : TopDownPluginDef) -> String? {
  match @topdown_platform.validate_plugin(build_core_plugin(plugin)) {
    Some(error) => return Some(error)
    None => ()
  }
  if plugin.settings.interaction_radius <= 0.0 {
    return Some("settings.interaction_radius must be > 0")
  }
  if plugin.settings.interact_prompt == "" {
    return Some("settings.interact_prompt must not be empty")
  }
  if plugin.settings.advance_hint == "" {
    return Some("settings.advance_hint must not be empty")
  }
  match validate_dialogue_theme(plugin.dialogue_theme) {
    Some(error) => return Some(error)
    None => ()
  }

  let seen_dialogues : Map[String, Bool] = Map::new()
  for script in plugin.dialogues {
    if seen_dialogues.get(script.id) is Some(_) {
      return Some("duplicate dialogue id '\{script.id}'")
    }
    seen_dialogues.set(script.id, true)
    match validate_dialogue_script(script) {
      Some(error) => return Some(error)
      None => ()
    }
  }

  let spawn_counts = actor_spawn_tag_counts(plugin.map)
  let seen_npcs : Map[String, Bool] = Map::new()
  let seen_spawn_tags : Map[String, Bool] = Map::new()
  for npc in plugin.npcs {
    if npc.id == "" {
      return Some("npcs: id must not be empty")
    }
    if seen_npcs.get(npc.id) is Some(_) {
      return Some("duplicate npc id '\{npc.id}'")
    }
    seen_npcs.set(npc.id, true)
    if npc.archetype_id == "" {
      return Some("npc '\{npc.id}': archetype_id must not be empty")
    }
    if archetype_by_id(plugin, npc.archetype_id) is None {
      return Some("npc '\{npc.id}': unknown archetype '\{npc.archetype_id}'")
    }
    if npc.spawn_tag == "" {
      return Some("npc '\{npc.id}': spawn_tag must not be empty")
    }
    if seen_spawn_tags.get(npc.spawn_tag) is Some(_) {
      return Some("npc '\{npc.id}': duplicate npc spawn_tag '\{npc.spawn_tag}'")
    }
    seen_spawn_tags.set(npc.spawn_tag, true)
    let count = match spawn_counts.get(npc.spawn_tag) {
      Some(value) => value
      None => 0
    }
    if count != 1 {
      return Some(
        "npc '\{npc.id}': spawn_tag '\{npc.spawn_tag}' must appear exactly once in the map",
      )
    }
    if npc.display_name == "" {
      return Some("npc '\{npc.id}': display_name must not be empty")
    }
    if npc.dialogue_id == "" {
      return Some("npc '\{npc.id}': dialogue_id must not be empty")
    }
    if dialogue_by_id(plugin, npc.dialogue_id) is None {
      return Some("npc '\{npc.id}': unknown dialogue '\{npc.dialogue_id}'")
    }
  }

  None
}

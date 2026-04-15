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
fn validate_visual(visual : ImageVisualDef, context : String) -> String? {
  if visual.path == "" {
    return Some("\{context}: image path must not be empty")
  }
  if visual.scale <= 0.0 {
    return Some("\{context}: scale must be > 0")
  }
  None
}

///|
fn validate_anim(anim : SpriteAnimDef, context : String) -> String? {
  if anim.image == "" {
    return Some("\{context}: image must not be empty")
  }
  if anim.frame_width <= 0.0 || anim.frame_height <= 0.0 {
    return Some("\{context}: frame size must be > 0")
  }
  if anim.columns <= 0 {
    return Some("\{context}: columns must be > 0")
  }
  if anim.frame_count <= 0 {
    return Some("\{context}: frame_count must be > 0")
  }
  if anim.fps <= 0.0 {
    return Some("\{context}: fps must be > 0")
  }
  if anim.scale <= 0.0 {
    return Some("\{context}: scale must be > 0")
  }
  None
}

///|
fn validate_archetype(archetype : ArchetypeDef) -> String? {
  if archetype.id == "" {
    return Some("archetype: id must not be empty")
  }
  if archetype.move_speed < 0.0 {
    return Some("archetype '\{archetype.id}': move_speed must be >= 0")
  }
  if archetype.radius <= 0.0 {
    return Some("archetype '\{archetype.id}': radius must be > 0")
  }
  match validate_anim(archetype.sprites.up, "archetype '\{archetype.id}' up") {
    Some(error) => return Some(error)
    None => ()
  }
  match
    validate_anim(archetype.sprites.down, "archetype '\{archetype.id}' down") {
    Some(error) => return Some(error)
    None => ()
  }
  match
    validate_anim(archetype.sprites.left, "archetype '\{archetype.id}' left") {
    Some(error) => return Some(error)
    None => ()
  }
  validate_anim(archetype.sprites.right, "archetype '\{archetype.id}' right")
}

///|
fn actor_spawn_tags_contains(tags : Array[String], target : String) -> Bool {
  for tag in tags {
    if tag == target {
      return true
    }
  }
  false
}

///|
pub fn validate_plugin(plugin : TopDownPluginDef) -> String? {
  if plugin.meta.id == "" {
    return Some("meta.id must not be empty")
  }
  if plugin.meta.name == "" {
    return Some("meta.name must not be empty")
  }
  if plugin.meta.version == "" {
    return Some("meta.version must not be empty")
  }
  if plugin.map.rows.length() == 0 {
    return Some("map.rows must not be empty")
  }
  if plugin.map.tile_size <= 0.0 {
    return Some("map.tile_size must be > 0")
  }
  let cols = plugin.map.rows[0].length()
  if cols == 0 {
    return Some("map rows must not be empty strings")
  }
  match
    validate_visual(plugin.map.default_floor_image, "map.default_floor_image") {
    Some(error) => return Some(error)
    None => ()
  }
  let mut player_spawns = 0
  let actor_spawn_tags : Array[String] = []
  for row = 0; row < plugin.map.rows.length(); row = row + 1 {
    let line = plugin.map.rows[row]
    if line.length() != cols {
      return Some("map row \{row} has inconsistent width")
    }
    for col = 0; col < cols; col = col + 1 {
      let code = line.unsafe_get(col).unsafe_to_char()
      match plugin.map.legend.get(code) {
        Some(rule) => {
          match rule.floor_image {
            Some(visual) =>
              match validate_visual(visual, "legend '\{code}' floor_image") {
                Some(error) => return Some(error)
                None => ()
              }
            None => ()
          }
          match rule.prop_image {
            Some(visual) =>
              match validate_visual(visual, "legend '\{code}' prop_image") {
                Some(error) => return Some(error)
                None => ()
              }
            None => ()
          }
          match rule.kind {
            PlayerSpawn => player_spawns += 1
            ActorSpawn =>
              match rule.actor_spawn_tag {
                Some(tag) => if tag != "" { actor_spawn_tags.push(tag) }
                None => ()
              }
            _ => ()
          }
        }
        None => return Some("map tile '\{code}' is missing from legend")
      }
    }
  }
  if player_spawns != 1 {
    return Some("map must contain exactly one PlayerSpawn tile")
  }
  if plugin.player_archetype_id == "" {
    return Some("player_archetype_id must not be empty")
  }
  match archetype_by_id(plugin, plugin.player_archetype_id) {
    Some(_) => ()
    None =>
      return Some(
        "player_archetype_id '\{plugin.player_archetype_id}' does not exist",
      )
  }
  let seen_archetypes : Map[String, Bool] = Map::new()
  for archetype in plugin.archetypes {
    if seen_archetypes.get(archetype.id) is Some(_) {
      return Some("duplicate archetype id '\{archetype.id}'")
    }
    seen_archetypes.set(archetype.id, true)
    match validate_archetype(archetype) {
      Some(error) => return Some(error)
      None => ()
    }
  }
  for actor_spawn in plugin.actor_spawns {
    if actor_spawn.archetype_id == "" {
      return Some("actor_spawns: archetype_id must not be empty")
    }
    match archetype_by_id(plugin, actor_spawn.archetype_id) {
      Some(_) => ()
      None =>
        return Some(
          "actor_spawns: unknown archetype '\{actor_spawn.archetype_id}'",
        )
    }
    match actor_spawn.spawn_tag {
      Some(tag) =>
        if tag == "" {
          return Some("actor_spawns: spawn_tag must not be empty when present")
        } else if !actor_spawn_tags_contains(actor_spawn_tags, tag) {
          return Some("actor_spawns: unknown spawn_tag '\{tag}'")
        }
      None =>
        if actor_spawn_tags.length() == 0 {
          return Some(
            "actor_spawns require at least one ActorSpawn tile in the map",
          )
        }
    }
  }
  if plugin.ui_theme.title == "" {
    return Some("ui_theme.title must not be empty")
  }
  if plugin.ui_theme.font_path == "" {
    return Some("ui_theme.font_path must not be empty")
  }
  if plugin.ui_theme.font_family == "" {
    return Some("ui_theme.font_family must not be empty")
  }
  if plugin.ui_theme.hud_color_css == "" {
    return Some("ui_theme.hud_color_css must not be empty")
  }
  if plugin.ui_theme.control_hint == "" {
    return Some("ui_theme.control_hint must not be empty")
  }
  None
}

///|
fn campaign_archetype_by_id_in_plugin(
  plugin : TopDownCampaignPluginDef,
  id : String,
) -> ArchetypeDef? {
  for archetype in plugin.archetypes {
    if archetype.id == id {
      return Some(archetype)
    }
  }
  None
}

///|
fn campaign_skill_by_id_in_plugin(
  plugin : TopDownCampaignPluginDef,
  id : String,
) -> SkillDef? {
  for skill in plugin.skills {
    if skill.id == id {
      return Some(skill)
    }
  }
  None
}

///|
fn campaign_drop_table_by_id_in_plugin(
  plugin : TopDownCampaignPluginDef,
  id : String,
) -> DropTableDef? {
  for table in plugin.drops {
    if table.id == id {
      return Some(table)
    }
  }
  None
}

///|
fn campaign_contains_tag(tags : Array[String], target : String) -> Bool {
  for tag in tags {
    if tag == target {
      return true
    }
  }
  false
}

///|
fn campaign_collect_actor_spawn_tags(
  map : @topdown_platform.MapDef,
) -> Array[String] {
  let tags : Array[String] = []
  for row in map.rows {
    for col = 0; col < row.length(); col = col + 1 {
      let ch = row.unsafe_get(col).unsafe_to_char()
      match map.legend.get(ch) {
        Some(rule) =>
          if rule.kind == @topdown_platform.ActorSpawn {
            match rule.actor_spawn_tag {
              Some(tag) =>
                if tag != "" && !campaign_contains_tag(tags, tag) {
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
fn campaign_collect_point_tags(map : @topdown_platform.MapDef) -> Array[String] {
  let tags : Array[String] = []
  for row in map.rows {
    for col = 0; col < row.length(); col = col + 1 {
      let ch = row.unsafe_get(col).unsafe_to_char()
      match map.legend.get(ch) {
        Some(rule) =>
          match rule.point_tag {
            Some(tag) =>
              if tag != "" && !campaign_contains_tag(tags, tag) {
                tags.push(tag)
              }
            None => ()
          }
        None => ()
      }
    }
  }
  tags
}

///|
fn campaign_stage_inferred_actor_spawns(
  stage : CampaignStageDef,
  player_archetype_id : String,
) -> Array[@topdown_platform.ActorSpawnDef] {
  let seen_tags : Array[String] = []
  let inferred : Array[@topdown_platform.ActorSpawnDef] = []
  for wave in stage.waves {
    for entry in wave.entries {
      match entry.spawn_tag {
        Some(tag) =>
          if tag != "" && !campaign_contains_tag(seen_tags, tag) {
            seen_tags.push(tag)
            inferred.push({
              archetype_id: player_archetype_id,
              spawn_tag: Some(tag),
              facing: @topdown_platform.Down,
            })
          }
        None => ()
      }
    }
  }
  inferred
}

///|
fn campaign_validate_stage_map(
  plugin : TopDownCampaignPluginDef,
  stage : CampaignStageDef,
) -> String? {
  let core_plugin : @topdown_platform.TopDownPluginDef = {
    meta: plugin.meta,
    map: stage.map,
    player_archetype_id: plugin.player_archetype_id,
    archetypes: plugin.archetypes.map(to_core_archetype),
    actor_spawns: campaign_stage_inferred_actor_spawns(
      stage,
      plugin.player_archetype_id,
    ),
    ui_theme: plugin.ui_theme,
    hooks: None,
  }
  match @topdown_platform.validate_plugin(core_plugin) {
    Some(error) => Some("stage '\{stage.id}' map invalid: \{error}")
    None => None
  }
}

///|
fn campaign_validate_stage(
  plugin : TopDownCampaignPluginDef,
  stage : CampaignStageDef,
) -> String? {
  if stage.title == "" {
    return Some("stage '\{stage.id}': title must not be empty")
  }
  if stage.required_rescued < 0 {
    return Some("stage '\{stage.id}': required_rescued must be >= 0")
  }
  match campaign_validate_stage_map(plugin, stage) {
    Some(error) => return Some(error)
    None => ()
  }
  let actor_spawn_tags = campaign_collect_actor_spawn_tags(stage.map)
  let point_tags = campaign_collect_point_tags(stage.map)
  let mut rescue_capacity = 0
  let mut exit_objective_count = 0
  for objective in stage.objectives {
    if objective.tag == "" {
      return Some("stage '\{stage.id}': objective tag must not be empty")
    }
    if !campaign_contains_tag(point_tags, objective.tag) {
      return Some(
        "stage '\{stage.id}': objective tag '\{objective.tag}' has no tagged point in map",
      )
    }
    match objective.kind {
      RescueCamp => {
        if objective.rescue_count <= 0 {
          return Some(
            "stage '\{stage.id}': rescue objective '\{objective.tag}' requires rescue_count > 0",
          )
        }
        rescue_capacity += objective.rescue_count
      }
      ExitZone => exit_objective_count += 1
    }
  }
  if exit_objective_count == 0 {
    return Some("stage '\{stage.id}': missing ExitZone objective")
  }
  if stage.required_rescued > rescue_capacity {
    return Some(
      "stage '\{stage.id}': required_rescued exceeds rescue objective capacity",
    )
  }
  for wave in stage.waves {
    if wave.entries.length() == 0 {
      return Some("stage '\{stage.id}' wave '\{wave.id}' has no entries")
    }
    for entry in wave.entries {
      if campaign_archetype_by_id_in_plugin(plugin, entry.archetype_id) is None {
        return Some(
          "stage '\{stage.id}' wave '\{wave.id}' references unknown archetype '\{entry.archetype_id}'",
        )
      }
      if entry.count <= 0 {
        return Some(
          "stage '\{stage.id}' wave '\{wave.id}' entry count must be > 0",
        )
      }
      if entry.spawn_interval < 0.0 {
        return Some(
          "stage '\{stage.id}' wave '\{wave.id}' entry spawn_interval must be >= 0",
        )
      }
      match entry.spawn_tag {
        Some(tag) =>
          if tag == "" {
            return Some(
              "stage '\{stage.id}' wave '\{wave.id}' spawn_tag must not be empty",
            )
          } else if !campaign_contains_tag(actor_spawn_tags, tag) {
            return Some(
              "stage '\{stage.id}' wave '\{wave.id}' spawn_tag '\{tag}' missing in map",
            )
          }
        None => ()
      }
    }
  }
  None
}

///|
pub fn validate_campaign_plugin(plugin : TopDownCampaignPluginDef) -> String? {
  if plugin.meta.id == "" || plugin.meta.name == "" || plugin.meta.version == "" {
    return Some("meta.id/name/version must not be empty")
  }
  if plugin.player_archetype_id == "" {
    return Some("player_archetype_id must not be empty")
  }
  if plugin.campaign.lives <= 0 {
    return Some("campaign.lives must be > 0")
  }
  if plugin.campaign.intro_seconds < 0.0 || plugin.campaign.clear_seconds < 0.0 {
    return Some("campaign intro/clear seconds must be >= 0")
  }
  if plugin.campaign.stages.length() == 0 {
    return Some("campaign requires at least one stage")
  }
  if plugin.follower.spacing_steps <= 0 {
    return Some("follower.spacing_steps must be > 0")
  }
  if plugin.follower.radius <= 0.0 {
    return Some("follower.radius must be > 0")
  }
  if campaign_archetype_by_id_in_plugin(plugin, plugin.player_archetype_id)
    is None {
    return Some("player_archetype_id '\{plugin.player_archetype_id}' not found")
  }
  for archetype in plugin.archetypes {
    if archetype.id == "" {
      return Some("archetype id must not be empty")
    }
    if archetype.max_hp <= 0 {
      return Some("archetype '\{archetype.id}' max_hp must be > 0")
    }
    if archetype.move_speed < 0.0 {
      return Some("archetype '\{archetype.id}' move_speed must be >= 0")
    }
    if archetype.radius <= 0.0 {
      return Some("archetype '\{archetype.id}' radius must be > 0")
    }
    match archetype.primary_skill_id {
      Some(skill_id) =>
        if campaign_skill_by_id_in_plugin(plugin, skill_id) is None {
          return Some(
            "archetype '\{archetype.id}' missing primary skill '\{skill_id}'",
          )
        }
      None => ()
    }
    match archetype.secondary_skill_id {
      Some(skill_id) =>
        if campaign_skill_by_id_in_plugin(plugin, skill_id) is None {
          return Some(
            "archetype '\{archetype.id}' missing secondary skill '\{skill_id}'",
          )
        }
      None => ()
    }
    match archetype.drop_table_id {
      Some(table_id) =>
        if campaign_drop_table_by_id_in_plugin(plugin, table_id) is None {
          return Some(
            "archetype '\{archetype.id}' missing drop table '\{table_id}'",
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
  for drop in plugin.drops {
    if drop.id == "" {
      return Some("drop table id must not be empty")
    }
    if drop.chance < 0.0 || drop.chance > 1.0 {
      return Some("drop table '\{drop.id}' chance must be in [0,1]")
    }
    if drop.items.length() == 0 {
      return Some("drop table '\{drop.id}' requires items")
    }
  }
  for stage in plugin.campaign.stages {
    match campaign_validate_stage(plugin, stage) {
      Some(error) => return Some(error)
      None => ()
    }
  }
  if plugin.ui_theme.title == "" ||
    plugin.ui_theme.font_path == "" ||
    plugin.ui_theme.font_family == "" ||
    plugin.ui_theme.hud_color_css == "" ||
    plugin.ui_theme.control_hint == "" {
    return Some("ui_theme fields must not be empty")
  }
  None
}

///|
fn campaign_plugin() -> TopDownCampaignPluginDef {
  match campaign_active_plugin.val {
    Some(plugin) => plugin
    None => abort("topdown_action campaign: no active plugin configured")
  }
}

///|
fn campaign_stage() -> CampaignStageDef {
  let plugin = campaign_plugin()
  let index = campaign_run_state.stage_index
  if index < 0 || index >= plugin.campaign.stages.length() {
    abort("topdown_action campaign: invalid stage index \{index}")
  }
  plugin.campaign.stages[index]
}

///|
fn campaign_skill_by_id(id : String) -> SkillDef? {
  for skill in campaign_plugin().skills {
    if skill.id == id {
      return Some(skill)
    }
  }
  None
}

///|
fn campaign_archetype_by_id(id : String) -> ArchetypeDef {
  for archetype in campaign_plugin().archetypes {
    if archetype.id == id {
      return archetype
    }
  }
  abort("topdown_action campaign: missing archetype '\{id}'")
}

///|
fn campaign_image_handle(path : String) -> @asset.ImageHandle {
  @topdown_platform.load_cached_image(
    path, asset_path_prefixes, campaign_image_cache,
  )
}

///|
fn campaign_register_font_once() -> Unit {
  if campaign_font_registered.val {
    return
  }
  let theme = campaign_plugin().ui_theme
  ignore(
    @asset.load_font(
      @topdown_platform.resolve_asset_path(theme.font_path, asset_path_prefixes),
      family=theme.font_family,
    ),
  )
  campaign_font_registered.val = true
}

///|
fn campaign_clear_dynamic_entities() -> Unit {
  for entity in campaign_dynamic_entities {
    if entity.is_alive() {
      entity.destroy()
    }
  }
  campaign_dynamic_entities.clear()
  campaign_enemy_runtimes.clear()
  campaign_projectile_runtimes.clear()
  campaign_follower_runtimes.clear()
  campaign_player_runtime.val = None
  campaign_player_trail.clear()
}

///|
fn campaign_clear_world_entities() -> Unit {
  for tile in campaign_world_tiles {
    if tile.floor_entity.is_alive() {
      tile.floor_entity.destroy()
    }
    match tile.prop_entity {
      Some(entity) => if entity.is_alive() { entity.destroy() }
      None => ()
    }
  }
  campaign_world_tiles.clear()
}

///|
fn campaign_world_to_screen(world_position : @math.Vec2) -> @math.Vec2 {
  @topdown_platform.world_to_screen(
    world_position,
    campaign_world_state.camera_origin,
  )
}

///|
fn campaign_spawn_world_tiles(
  layout : @topdown_platform.WorldMapLayout,
) -> Unit {
  for tile in layout.tiles {
    let floor = @entity.Entity::new()
    let floor_screen = campaign_world_to_screen(tile.center)
    @topdown_platform.apply_image_sprite_entity(
      floor,
      tile.floor_image,
      floor_screen,
      campaign_world_state.tile_size,
      CAMPAIGN_TILE_Z,
      asset_path_prefixes,
      campaign_image_cache,
    )
    let mut prop_entity : @entity.Entity? = None
    match tile.prop_image {
      Some(visual) => {
        let prop = @entity.Entity::new()
        @topdown_platform.apply_image_sprite_entity(
          prop,
          visual,
          floor_screen,
          campaign_world_state.tile_size,
          CAMPAIGN_PROP_Z,
          asset_path_prefixes,
          campaign_image_cache,
        )
        prop_entity = Some(prop)
      }
      None => ()
    }
    campaign_world_tiles.push({
      floor_entity: floor,
      prop_entity,
      center: tile.center,
      floor_visual: tile.floor_image,
      prop_visual: tile.prop_image,
    })
  }
}

///|
fn campaign_find_points(tag : String) -> Array[@topdown_platform.TaggedPoint] {
  let points : Array[@topdown_platform.TaggedPoint] = []
  for point in campaign_world_state.tagged_points {
    if point.tag == tag {
      points.push(point)
    }
  }
  points
}

///|
fn campaign_setup_objectives() -> Unit {
  campaign_camps.clear()
  campaign_exit_zone.val = None
  let stage = campaign_stage()
  let exit_radius = campaign_world_state.tile_size * 0.70
  for objective in stage.objectives {
    let points = campaign_find_points(objective.tag)
    match objective.kind {
      RescueCamp =>
        for point in points {
          campaign_camps.push({
            position: point.position,
            rescue_count: objective.rescue_count.max(1),
            triggered: false,
          })
        }
      ExitZone =>
        if points.length() > 0 && campaign_exit_zone.val is None {
          campaign_exit_zone.val = Some({
            position: points[0].position,
            radius: exit_radius,
          })
        }
    }
  }
}

///|
fn campaign_parse_stage_world() -> Unit {
  campaign_clear_world_entities()
  let stage = campaign_stage()
  let layout = @topdown_platform.build_world_map_layout(
    stage.map,
    CAMPAIGN_WORLD_PADDING,
  )
  campaign_world_state.tile_size = layout.tile_size
  campaign_world_state.rows = layout.rows
  campaign_world_state.cols = layout.cols
  campaign_world_state.world_width = layout.world_width
  campaign_world_state.world_height = layout.world_height
  campaign_world_state.player_spawn = layout.player_spawn
  campaign_world_state.enemy_spawns.clear()
  for spawn in layout.actor_spawns {
    campaign_world_state.enemy_spawns.push(spawn)
  }
  campaign_world_state.tagged_points.clear()
  for point in layout.tagged_points {
    campaign_world_state.tagged_points.push(point)
  }
  campaign_world_state.blocking_rects.clear()
  for rect in layout.blocking_rects {
    campaign_world_state.blocking_rects.push(rect)
  }
  campaign_world_state.camera_origin = @math.Vec2(0.0, 0.0)
  campaign_spawn_world_tiles(layout)
  campaign_setup_objectives()
}

///|
fn campaign_reset_spawn_cursor() -> Unit {
  let stage = campaign_stage()
  campaign_run_state.spawn_cursor.wave_index = 0
  campaign_run_state.spawn_cursor.entry_index = 0
  campaign_run_state.spawn_cursor.spawned_in_entry = 0
  campaign_run_state.spawn_cursor.wave_started = false
  campaign_run_state.spawn_cursor.all_spawned = stage.waves.length() == 0
  campaign_run_state.spawn_cursor.wait_timer = if stage.waves.length() > 0 {
    stage.waves[0].start_delay
  } else {
    0.0
  }
}

///|
fn campaign_spawn_player() -> Unit {
  let archetype = campaign_archetype_by_id(
    campaign_plugin().player_archetype_id,
  )
  let entity = @entity.Entity::new()
  campaign_dynamic_entities.push(entity)
  campaign_player_runtime.val = Some({
    entity,
    archetype_id: archetype.id,
    hp: archetype.max_hp,
    position: campaign_world_state.player_spawn,
    facing: @topdown_platform.Up,
    moving: false,
    anim_elapsed: 0.0,
    attack_cd: 0.0,
    invuln_ttl: CAMPAIGN_PLAYER_RESPAWN_SECONDS,
    last_sprite_path: "",
    ai_wander_dir: @math.Vec2(0.0, 0.0),
    ai_wander_timer: 0.0,
  })
  campaign_player_trail.push(campaign_world_state.player_spawn)
}

///|
fn campaign_setup_ui_entities() -> Unit {
  @topdown_platform.apply_text_entity(
    campaign_title_entity,
    campaign_plugin().ui_theme.title,
    24.0,
    18.0,
    CAMPAIGN_HUD_Z,
    "rgb(235,244,255)",
    34,
    campaign_plugin().ui_theme.font_family,
  )
  @topdown_platform.apply_text_entity(
    campaign_hud_entity,
    "",
    24.0,
    60.0,
    CAMPAIGN_HUD_Z,
    campaign_plugin().ui_theme.hud_color_css,
    22,
    campaign_plugin().ui_theme.font_family,
  )
  @topdown_platform.apply_text_entity(
    campaign_message_entity,
    "",
    24.0,
    VIEWPORT_HEIGHT - 72.0,
    CAMPAIGN_HUD_Z,
    "rgb(255,212,120)",
    22,
    campaign_plugin().ui_theme.font_family,
  )
  @topdown_platform.apply_text_entity(
    campaign_overlay_entity,
    "",
    VIEWPORT_WIDTH * 0.5 - 220.0,
    VIEWPORT_HEIGHT * 0.5 - 28.0,
    CAMPAIGN_HUD_Z,
    "rgb(242,246,252)",
    32,
    campaign_plugin().ui_theme.font_family,
  )
}

///|
fn campaign_clear_stage_runtime() -> Unit {
  campaign_clear_dynamic_entities()
  campaign_run_state.rescued_total = 0
  campaign_run_state.rescued_delivered = 0
  campaign_run_state.required_rescued = campaign_stage().required_rescued
  campaign_run_state.stage_clear_ttl = 0.0
  campaign_run_state.status_message = ""
  campaign_input_state.move_intent = @math.Vec2(0.0, 0.0)
  campaign_input_state.primary_requested = false
  campaign_input_state.secondary_requested = false
  campaign_reset_spawn_cursor()
  campaign_spawn_player()
}

///|
fn campaign_load_stage(index : Int) -> Unit {
  campaign_run_state.stage_index = index
  campaign_parse_stage_world()
  campaign_clear_stage_runtime()
  campaign_run_state.phase = StageIntro
  campaign_run_state.stage_intro_ttl = campaign_plugin().campaign.intro_seconds
}

///|
fn campaign_enter_menu() -> Unit {
  campaign_run_state.phase = MainMenu
  campaign_run_state.stage_index = 0
  campaign_run_state.lives = campaign_plugin().campaign.lives
  campaign_run_state.score = 0
  campaign_run_state.rescued_total = 0
  campaign_run_state.rescued_delivered = 0
  campaign_run_state.required_rescued = 0
  campaign_run_state.stage_intro_ttl = 0.0
  campaign_run_state.stage_clear_ttl = 0.0
  campaign_run_state.status_message = ""
  campaign_clear_dynamic_entities()
  campaign_clear_world_entities()
}

///|
pub fn campaign_setup_plugin(plugin : TopDownCampaignPluginDef) -> Unit {
  campaign_active_plugin.val = Some(plugin)
}

///|
pub fn campaign_startup_system(_world : @ecs.World) -> Unit {
  campaign_capture_done.val = false
  campaign_capture_timer.val = 0.0
  campaign_debug_overlay_enabled.val = env_flag_enabled(CAMPAIGN_PROFILE_ENV)
  campaign_register_font_once()
  @topdown_platform.apply_world_background(
    campaign_world_bg_entity,
    VIEWPORT_WIDTH,
    VIEWPORT_HEIGHT,
    color_rgba(23U, 28U, 34U, 1.0),
  )
  campaign_setup_ui_entities()
  campaign_enter_menu()
}

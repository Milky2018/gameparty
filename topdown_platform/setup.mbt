///|
fn maybe_enable_hidden_window() -> Unit {
  @host.prepare_run(env_flag_enabled(CAPTURE_ENV))
}

///|
fn runtime_fps() -> UInt {
  FPS
}

///|
fn plugin() -> TopDownPluginDef {
  match active_plugin.val {
    Some(plugin) => plugin
    None => abort("topdown_platform: no active plugin configured")
  }
}

///|
fn image_handle(path : String) -> @asset.ImageHandle {
  load_cached_image(path, asset_path_prefixes, image_cache)
}

///|
fn register_font_once() -> Unit {
  if topdown_font_registered.val {
    return
  }
  let theme = plugin().ui_theme
  ignore(
    @asset.load_font(
      resolve_asset_path(theme.font_path, asset_path_prefixes),
      family=theme.font_family,
    ),
  )
  topdown_font_registered.val = true
}

///|
fn clear_dynamic_entities() -> Unit {
  for entity in dynamic_entities {
    if entity.is_alive() {
      entity.destroy()
    }
  }
  dynamic_entities.clear()
  actor_runtimes.clear()
  player_runtime.val = None
}

///|
fn clear_world_entities() -> Unit {
  for tile in world_tiles {
    if tile.floor_entity.is_alive() {
      tile.floor_entity.destroy()
    }
    match tile.prop_entity {
      Some(entity) => if entity.is_alive() { entity.destroy() }
      None => ()
    }
  }
  world_tiles.clear()
}

///|
fn parse_world_map() -> Unit {
  clear_world_entities()
  let layout = build_world_map_layout(plugin().map, WALL_PADDING)
  world_state.tile_size = layout.tile_size
  world_state.rows = layout.rows
  world_state.cols = layout.cols
  world_state.world_width = layout.world_width
  world_state.world_height = layout.world_height
  world_state.player_spawn = layout.player_spawn
  world_state.actor_spawns.clear()
  for spawn in layout.actor_spawns {
    world_state.actor_spawns.push(spawn)
  }
  world_state.blocking_rects.clear()
  for rect in layout.blocking_rects {
    world_state.blocking_rects.push(rect)
  }

  for tile in layout.tiles {
    let floor = @entity.Entity::new()
    apply_image_sprite_entity(
      floor,
      tile.floor_image,
      tile.center,
      world_state.tile_size,
      TILE_Z,
      asset_path_prefixes,
      image_cache,
    )
    let mut prop_entity : @entity.Entity? = None
    match tile.prop_image {
      Some(visual) => {
        let prop = @entity.Entity::new()
        apply_image_sprite_entity(
          prop,
          visual,
          tile.center,
          world_state.tile_size,
          PROP_Z,
          asset_path_prefixes,
          image_cache,
        )
        prop_entity = Some(prop)
      }
      None => ()
    }
    world_tiles.push({ floor_entity: floor, prop_entity })
  }
}

///|
fn setup_ui_entities() -> Unit {
  apply_text_entity(
    title_entity,
    plugin().ui_theme.title,
    24.0,
    18.0,
    HUD_Z,
    "rgb(235,244,255)",
    36,
    plugin().ui_theme.font_family,
  )
  apply_text_entity(
    hud_entity,
    "",
    24.0,
    70.0,
    HUD_Z,
    plugin().ui_theme.hud_color_css,
    24,
    plugin().ui_theme.font_family,
  )
  apply_text_entity(
    message_entity,
    "",
    24.0,
    VIEWPORT_HEIGHT - 74.0,
    HUD_Z,
    "rgb(255,212,120)",
    24,
    plugin().ui_theme.font_family,
  )
}

///|
fn make_runtime_snapshot() -> PluginRuntimeState {
  let tile_size = world_state.tile_size.max(1.0)
  let player_position = match player_runtime.val {
    Some(player) => player.position
    None => @math.Vec2(0.0, 0.0)
  }
  {
    phase: run_state.phase,
    player_cell_x: (player_position[X] / tile_size).floor().to_int(),
    player_cell_y: (player_position[Y] / tile_size).floor().to_int(),
    actor_count: actor_runtimes.length(),
  }
}

///|
fn trigger_on_run_start_hook() -> Unit {
  plugin_runtime_state.snapshot = make_runtime_snapshot()
  match plugin().hooks {
    Some(hooks) =>
      match hooks.on_run_start {
        Some(f) => f(plugin_runtime_state.snapshot)
        None => ()
      }
    None => ()
  }
}

///|
fn reset_run_state() -> Unit {
  run_state.phase = Playing
  run_state.elapsed = 0.0
  run_state.status_message = ""
  input_state.move_intent = @math.Vec2(0.0, 0.0)
}

///|
fn spawn_player() -> Unit {
  let entity = @entity.Entity::new()
  dynamic_entities.push(entity)
  player_runtime.val = Some({
    entity,
    archetype_id: plugin().player_archetype_id,
    position: world_state.player_spawn,
    facing: Down,
    moving: false,
    anim_elapsed: 0.0,
    last_sprite_path: "",
  })
}

///|
fn spawn_actor(
  archetype_id : String,
  position : @math.Vec2,
  facing : Facing,
) -> Unit {
  let entity = @entity.Entity::new()
  dynamic_entities.push(entity)
  actor_runtimes.push({
    entity,
    archetype_id,
    position,
    facing,
    moving: false,
    anim_elapsed: 0.0,
    last_sprite_path: "",
  })
}

///|
fn spawn_configured_actors() -> Unit {
  for actor_spawn in plugin().actor_spawns {
    let matches : Array[ActorSpawnPoint] = []
    for point in world_state.actor_spawns {
      if actor_spawn.spawn_tag is None || point.tag == actor_spawn.spawn_tag {
        matches.push(point)
      }
    }
    for point in matches {
      spawn_actor(actor_spawn.archetype_id, point.position, actor_spawn.facing)
    }
  }
}

///|
fn restart_world() -> Unit {
  clear_dynamic_entities()
  parse_world_map()
  reset_run_state()
  spawn_player()
  spawn_configured_actors()
  setup_ui_entities()
  trigger_on_run_start_hook()
}

///|
pub fn setup_plugin(plugin : TopDownPluginDef) -> Unit {
  active_plugin.val = Some(plugin)
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  maybe_enable_hidden_window()
  debug_overlay_enabled.val = env_flag_enabled(PROFILE_ENV)
  register_font_once()
  apply_world_background(
    world_bg_entity,
    VIEWPORT_WIDTH,
    VIEWPORT_HEIGHT,
    color_rgba(29U, 35U, 43U, 1.0),
  )
  restart_world()
}

///|
fn maybe_enable_hidden_window() -> Unit {
  if env_flag_enabled(CAPTURE_ENV) {
    @raylib.set_config_flags(@raylib.FlagWindowHidden)
  }
}

///|
fn runtime_fps() -> UInt {
  FPS
}

///|
fn plugin() -> TopDownPluginDef {
  match active_plugin.val {
    Some(plugin) => plugin
    None => abort("topdown_action: no active plugin configured")
  }
}

///|
fn image_handle(path : String) -> @asset.ImageHandle {
  @topdown_platform.load_cached_image(path, asset_path_prefixes, image_cache)
}

///|
fn register_font_once() -> Unit {
  if topdown_font_registered.val {
    return
  }
  let theme = plugin().ui_theme
  ignore(
    @asset.load_font(
      @topdown_platform.resolve_asset_path(theme.font_path, asset_path_prefixes),
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
  enemy_runtimes.clear()
  projectile_runtimes.clear()
  pickup_runtimes.clear()
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
  let layout = @topdown_platform.build_world_map_layout(
    plugin().map,
    WALL_PADDING,
  )
  world_state.enemy_spawns.clear()
  for spawn in layout.actor_spawns {
    world_state.enemy_spawns.push(spawn)
  }
  world_state.blocking_rects.clear()
  for rect in layout.blocking_rects {
    world_state.blocking_rects.push(rect)
  }

  world_state.tile_size = layout.tile_size
  world_state.rows = layout.rows
  world_state.cols = layout.cols
  world_state.world_width = layout.world_width
  world_state.world_height = layout.world_height
  world_state.player_spawn = layout.player_spawn

  for tile in layout.tiles {
    let floor = @entity.Entity::new()
    @topdown_platform.apply_image_sprite_entity(
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
        @topdown_platform.apply_image_sprite_entity(
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
  @topdown_platform.apply_text_entity(
    title_entity,
    plugin().ui_theme.title,
    24.0,
    18.0,
    HUD_Z,
    "rgb(235,244,255)",
    36,
    plugin().ui_theme.font_family,
  )
  @topdown_platform.apply_text_entity(
    hud_entity,
    "",
    24.0,
    70.0,
    HUD_Z,
    plugin().ui_theme.hud_color_css,
    24,
    plugin().ui_theme.font_family,
  )
  @topdown_platform.apply_text_entity(
    message_entity,
    "",
    24.0,
    VIEWPORT_HEIGHT - 74.0,
    HUD_Z,
    "rgb(255,212,120)",
    24,
    plugin().ui_theme.font_family,
  )
  let flash = @sprite.Sprite::from_color(
    color_rgba(255U, 255U, 255U, 0.0),
    @math.Vec2(VIEWPORT_WIDTH, VIEWPORT_HEIGHT),
  )
  flash.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  @sprite.sprites().set(attack_flash_entity, flash)
  @transform.transforms().set(
    attack_flash_entity,
    transform_xy(0.0, 0.0, HUD_Z - 2.0),
  )
  set_entity_visible(attack_flash_entity, false)
}

///|
fn make_runtime_snapshot() -> PluginRuntimeState {
  {
    phase: run_state.phase,
    score: run_state.score,
    player_hp: match player_runtime.val {
      Some(player) => player.hp
      None => 0
    },
    player_hp_max: match player_runtime.val {
      Some(player) =>
        archetype_by_id(plugin(), player.archetype_id).unwrap().max_hp
      None => 0
    },
    wave: spawn_state.cursor.wave_index + 1,
    waves_total: plugin().waves.length(),
    time_left: run_state.time_left,
    enemies_alive: enemy_runtimes.length(),
    enemies_killed: run_state.enemies_killed,
    pickups_collected: run_state.pickups_collected,
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
  run_state.time_left = plugin().progression.run_seconds
  run_state.score = 0
  run_state.enemies_killed = 0
  run_state.pickups_collected = 0
  run_state.status_message = ""

  combat_state.move_intent = @math.Vec2(0.0, 0.0)
  combat_state.primary_requested = false
  combat_state.secondary_requested = false
  combat_state.attack_flash_ttl = 0.0

  spawn_state.cursor.wave_index = 0
  spawn_state.cursor.entry_index = 0
  spawn_state.cursor.spawned_in_entry = 0
  spawn_state.cursor.wait_timer = if plugin().waves.length() > 0 {
    plugin().waves[0].start_delay
  } else {
    0.0
  }
  spawn_state.cursor.wave_started = false
  spawn_state.cursor.all_spawned = plugin().waves.length() == 0

  loot_state.live_pickups = 0
}

///|
fn spawn_player() -> Unit {
  let archetype = archetype_by_id(
    plugin(),
    plugin().progression.player_archetype_id,
  ).unwrap()
  let entity = @entity.Entity::new()
  dynamic_entities.push(entity)
  player_runtime.val = Some({
    entity,
    archetype_id: archetype.id,
    hp: archetype.max_hp,
    position: world_state.player_spawn,
    facing: @topdown_platform.Down,
    attack_cd: 0.0,
    moving: false,
    anim_elapsed: 0.0,
    last_sprite_path: "",
    ai_wander_dir: @math.Vec2(0.0, 0.0),
    ai_wander_timer: 0.0,
  })
}

///|
fn restart_world() -> Unit {
  clear_dynamic_entities()
  parse_world_map()
  reset_run_state()
  spawn_player()
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
  @topdown_platform.apply_world_background(
    world_bg_entity,
    VIEWPORT_WIDTH,
    VIEWPORT_HEIGHT,
    color_rgba(29U, 35U, 43U, 1.0),
  )
  restart_world()
}

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
    None => abort("topdown_platform: no active plugin configured")
  }
}

///|
fn resolved_asset_path(path : String) -> String {
  for prefix in asset_path_prefixes {
    let candidate = "\{prefix}\{path}"
    if @asset.read_bytes(candidate) is Some(_) {
      return candidate
    }
  }
  path
}

///|
fn image_handle(path : String) -> @asset.ImageHandle {
  let key = resolved_asset_path(path)
  match image_cache.get(key) {
    Some(handle) => handle
    None => {
      let handle = @asset.load_image(key)
      image_cache.set(key, handle)
      handle
    }
  }
}

///|
fn register_font_once() -> Unit {
  if topdown_font_registered.val {
    return
  }
  let theme = plugin().ui_theme
  ignore(
    @asset.load_font(
      resolved_asset_path(theme.font_path),
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
fn ensure_text_entity(
  entity : @entity.Entity,
  text : String,
  x : Double,
  y : Double,
  z : Double,
  color_css : String,
  size : Int,
) -> Unit {
  @ui.texts().set(entity, @ui.Text::new(text))
  @ui.text_fonts().set(
    entity,
    @ui.TextFont::from_css("\{size}px \{plugin().ui_theme.font_family}"),
  )
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color_css))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2D(-0.5, 0.5)))
  @transform.transforms().set(entity, transform_xy(x, y, z))
  set_entity_visible(entity, true)
}

///|
fn ensure_world_background() -> Unit {
  let sprite = @sprite.Sprite::from_color(
    color_rgba(29U, 35U, 43U, 1.0),
    @math.Vec2D(VIEWPORT_WIDTH, VIEWPORT_HEIGHT),
  )
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(world_bg_entity, sprite)
  @transform.transforms().set(world_bg_entity, transform_xy(0.0, 0.0, 0.0))
  set_entity_visible(world_bg_entity, true)
}

///|
fn set_image_sprite_entity(
  entity : @entity.Entity,
  visual : ImageVisualDef,
  center : @math.Vec2D,
  base_size : Double,
  z : Double,
) -> Unit {
  let size = base_size * visual.scale
  let sprite = @sprite.Sprite::from_image(
    image_handle(visual.path),
    custom_size=Some(@math.Vec2D(size, size)),
  )
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    transform_xy(
      center[X] - size * 0.5,
      center[Y] - size * 0.5 + visual.y_offset,
      z,
    ),
  )
  set_entity_visible(entity, true)
}

///|
fn parse_world_map() -> Unit {
  clear_world_entities()
  world_state.enemy_spawns.clear()
  world_state.blocking_rects.clear()

  let map = plugin().map
  world_state.tile_size = map.tile_size
  world_state.rows = map.rows.length()
  world_state.cols = map.rows[0].length()
  world_state.world_width = world_state.cols.to_double() * world_state.tile_size
  world_state.world_height = world_state.rows.to_double() *
    world_state.tile_size

  for row = 0; row < world_state.rows; row = row + 1 {
    let line = map.rows[row]
    for col = 0; col < world_state.cols; col = col + 1 {
      let code = line.unsafe_get(col).unsafe_to_char()
      let rule = map.legend.get(code).unwrap()
      let center = @math.Vec2D(
        (col.to_double() + 0.5) * world_state.tile_size,
        (row.to_double() + 0.5) * world_state.tile_size,
      )
      let floor = @entity.Entity::new()
      let floor_image = match rule.floor_image {
        Some(visual) => visual
        None =>
          {
            path: "assets/top-down-summer/Top-Down Simple Summer_Ground 01.png",
            scale: 1.0,
            y_offset: 0.0,
          }
      }
      set_image_sprite_entity(
        floor,
        floor_image,
        center,
        world_state.tile_size,
        TILE_Z,
      )
      let mut prop_entity : @entity.Entity? = None
      match rule.prop_image {
        Some(path) => {
          let prop = @entity.Entity::new()
          set_image_sprite_entity(
            prop,
            path,
            center,
            world_state.tile_size,
            PROP_Z,
          )
          prop_entity = Some(prop)
        }
        None => ()
      }

      if rule.blocks || rule.kind == Wall {
        world_state.blocking_rects.push({
          position: @math.Vec2D(
            col.to_double() * world_state.tile_size + WALL_PADDING,
            row.to_double() * world_state.tile_size + WALL_PADDING,
          ),
          size: @math.Vec2D(
            world_state.tile_size - WALL_PADDING * 2.0,
            world_state.tile_size - WALL_PADDING * 2.0,
          ),
        })
      }
      match rule.kind {
        PlayerSpawn => world_state.player_spawn = center
        EnemySpawn => world_state.enemy_spawns.push(center)
        _ => ()
      }

      world_tiles.push({ floor_entity: floor, prop_entity })
    }
  }
}

///|
fn setup_ui_entities() -> Unit {
  ensure_text_entity(
    title_entity,
    plugin().ui_theme.title,
    24.0,
    18.0,
    HUD_Z,
    "rgb(235,244,255)",
    36,
  )
  ensure_text_entity(
    hud_entity,
    "",
    24.0,
    70.0,
    HUD_Z,
    plugin().ui_theme.hud_color_css,
    24,
  )
  ensure_text_entity(
    message_entity,
    "",
    24.0,
    VIEWPORT_HEIGHT - 74.0,
    HUD_Z,
    "rgb(255,212,120)",
    24,
  )
  let flash = @sprite.Sprite::from_color(
    color_rgba(255U, 255U, 255U, 0.0),
    @math.Vec2D(VIEWPORT_WIDTH, VIEWPORT_HEIGHT),
  )
  flash.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
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

  combat_state.move_intent = @math.Vec2D(0.0, 0.0)
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
    facing: Down,
    attack_cd: 0.0,
    moving: false,
    anim_elapsed: 0.0,
    last_sprite_path: "",
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
  ensure_world_background()
  restart_world()
}

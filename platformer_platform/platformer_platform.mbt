///|
const HIDDEN_WINDOW_ENV : String = "PLATFORMER_HIDDEN_WINDOW"

///|
fn maybe_enable_hidden_window() -> Unit {
  if env_flag_enabled(HIDDEN_WINDOW_ENV) {
    @raylib.set_config_flags(@raylib.FlagWindowHidden)
  }
}

///|
fn runtime_fps() -> UInt {
  if env_flag_enabled(DEBUG_CAPTURE_ENV) || env_flag_enabled(PROFILE_ENV) {
    66U
  } else {
    FPS
  }
}

///|
fn validate_plugin(plugin : PlatformerPluginDef) -> String? {
  if plugin.meta.id.is_empty() {
    return Some("meta.id must not be empty")
  }
  match plugin.movement {
    Some(movement) => {
      if movement.move_speed <= 0.0 || movement.jump_speed <= 0.0 {
        return Some("movement move/jump speed must be > 0")
      }
      if movement.gravity <= 0.0 || movement.max_fall_speed <= 0.0 {
        return Some("movement gravity/fall speed must be > 0")
      }
      if movement.coyote_time < 0.0 || movement.jump_buffer < 0.0 {
        return Some("movement coyote/jump_buffer must be >= 0")
      }
      if movement.max_air_dashes < 0 {
        return Some("movement max_air_dashes must be >= 0")
      }
      if movement.max_air_dashes > 0 &&
        (
          movement.dash_speed <= 0.0 ||
          movement.dash_duration <= 0.0 ||
          movement.dash_cooldown < 0.0
        ) {
        return Some("movement dash values are invalid")
      }
      if movement.allow_wall_jump &&
        (
          movement.wall_slide_speed <= 0.0 ||
          movement.wall_jump_speed_x <= 0.0 ||
          movement.wall_jump_speed_y <= 0.0
        ) {
        return Some("movement wall jump values are invalid")
      }
      if movement.wall_stamina_max < 0.0 ||
        movement.wall_stamina_drain_per_second < 0.0 ||
        movement.wall_jump_stamina_cost < 0.0 {
        return Some("movement wall stamina values must be >= 0")
      }
      if movement.spring_boost_speed <= 0.0 {
        return Some("movement spring_boost_speed must be > 0")
      }
    }
    None => ()
  }
  if plugin.levels.is_empty() {
    return Some("levels must not be empty")
  }
  for idx in 0..<plugin.levels.length() {
    let level = plugin.levels[idx]
    if level.blocks.is_empty() {
      return Some("level[\{idx}] '\{level.name}' has no blocks")
    }
    if level.world_width <= 0.0 {
      return Some("level[\{idx}] '\{level.name}' has invalid world_width")
    }
  }
  None
}

///|
pub fn run(plugin : PlatformerPluginDef) -> Unit {
  match validate_plugin(plugin) {
    Some(message) =>
      abort(
        "platformer_platform plugin validation failed for '\{plugin.meta.id}': \{message}",
      )
    None => ()
  }
  active_plugin.val = Some(plugin)
  @raylib.set_trace_log_level(@raylib.LogError)
  maybe_enable_hidden_window()
  let app = @app.App::new()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(1.0)
    .with_fps(runtime_fps())
    .with_image_smooth(true)
    .add_plugin(@plugins.default_plugin)
    .add_system(Startup, startup_system)
    .add_system(Update, input_system)
    .add_system(Update, update_system)
    .add_system(Update, sync_system)
    .add_system(Update, camera_system)
    .add_system(Render, hud_system)
    .add_system(RenderCleanup, capture_system)
  app.run()
}

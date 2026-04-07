///|
const HIDDEN_WINDOW_ENV : String = "SUPERMARIO_HIDDEN_WINDOW"

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
pub fn run() -> Unit {
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

///|
fn maybe_enable_hidden_window() -> Unit {
  @host.prepare_run(
    env_flag_enabled(DEBUG_CAPTURE_ENV) ||
    env_flag_enabled(BEJEWELED_PROFILE_ENV),
  )
}

///|
fn runtime_fps() -> UInt {
  if env_flag_enabled(DEBUG_CAPTURE_ENV) ||
    env_flag_enabled(BEJEWELED_PROFILE_ENV) {
    66U
  } else {
    FPS
  }
}

///|
pub fn run() -> Unit {
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
    .add_system(Render, render_system)
    .add_system(RenderCleanup, capture_after_render_system)
  app.run()
}

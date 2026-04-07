///|
pub fn run() -> Unit {
  @raylib.set_trace_log_level(@raylib.LogError)
  let capture_mode = env_flag_enabled(DEBUG_CAPTURE_ENV)
  // Keep capture-mode rendering lightweight for stable QA perf sampling.
  let viewport_width = if capture_mode { 560.0 } else { VIEWPORT_WIDTH }
  let viewport_height = if capture_mode { 315.0 } else { VIEWPORT_HEIGHT }
  let target_fps = if capture_mode { 66U } else { FPS }
  let app = @app.App::new()
    .with_viewport_width(viewport_width)
    .with_viewport_height(viewport_height)
    .with_zoom(1.0)
    .with_fps(target_fps)
    .add_plugin(@plugins.default_3d_plugin)
    .add_system(Startup, startup_system)
    .add_system(Update, update_system)
    .add_system(RenderCleanup, capture_after_render_system)
  app.run()
}

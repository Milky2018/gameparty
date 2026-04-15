///|
fn runtime_qa_enabled() -> Bool {
  match @env.get_env_var(CAPTURE_ENV) {
    Some(raw) =>
      raw == "1" ||
      raw == "true" ||
      raw == "TRUE" ||
      raw == "yes" ||
      raw == "on"
    None =>
      match @env.get_env_var(PROFILE_ENV) {
        Some(profile_raw) =>
          profile_raw == "1" ||
          profile_raw == "true" ||
          profile_raw == "TRUE" ||
          profile_raw == "yes" ||
          profile_raw == "on"
        None => false
      }
  }
}

///|
pub fn run() -> Unit {
  @host.prepare_run(false)
  let target_fps = if runtime_qa_enabled() { 64U } else { FPS }
  let app = @app.App::new()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(1.0)
    .with_fps(target_fps)
    .with_image_smooth(true)
    .add_plugin(@plugins.default_plugin)
    .add_system(Startup, startup_system)
    .add_system(Update, input_system)
    .add_system(Update, gameplay_system)
    .add_system(Render, render_sync_system)
    .add_system(RenderCleanup, capture_after_render_system)
  app.run()
}

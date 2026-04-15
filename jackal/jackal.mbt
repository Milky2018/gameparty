///|
pub fn run() -> Unit {
  @host.prepare_run(false)
  let runtime_qa = is_capture_enabled() || is_profile_enabled()
  let target_fps = if runtime_qa { 64U } else { FPS }
  let app = @app.App::new()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(1.0)
    .with_fps(target_fps)
    .with_image_smooth(false)
    .add_plugin(@plugins.default_plugin)
    .add_system(Startup, startup_system)
    .add_system(Update, input_system)
    .add_system(Update, simulation_system)
    .add_system(Render, render_sync_system)
    .add_system(RenderCleanup, capture_after_render_system)
  app.run()
}

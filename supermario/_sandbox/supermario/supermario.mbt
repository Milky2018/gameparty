///|
pub fn run() -> Unit {
  let app = @app.App::new()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(1.0)
    .with_fps(FPS)
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

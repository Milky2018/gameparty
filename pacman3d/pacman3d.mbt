///|
pub fn run() -> Unit {
  @system.App::new()
  .with_viewport_width(VIEWPORT_WIDTH)
  .with_viewport_height(VIEWPORT_HEIGHT)
  .with_zoom(1.0)
  .with_fps(FPS)
  .with_image_smooth(true)
  .add_plugin(@plugins.default_3d_plugin)
  .add_system(startup_system, schedule=Startup)
  .add_system(player_input_system)
  .add_system(ghost_update_system)
  .add_system(minimap_system)
  .add_system(hud_system, schedule=Render)
  .run()
}

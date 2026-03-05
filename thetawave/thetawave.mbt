///|
fn add_background_3d_pipeline(app : @system.App) -> Unit {
  app.systems
  ..push(
    (
      @transform3d.capture_previous_global_transforms3d_system,
      FixedFirst,
      "Capture Previous Transform3D System",
    ),
  )
  ..push(
    (
      @transform3d.transform3d_propagate_system,
      FixedPostUpdate,
      "Transform3D Propagation System",
    ),
  )
  ..push(
    (
      @transform3d.transform3d_propagate_system,
      PostUpdate,
      "Transform3D Propagation System (Frame)",
    ),
  )
  ..push((@camera3d.camera3d_extract_system, RenderExtract, "Camera3D Extract"))
  ..push((@render3d.render3d_extract_system, RenderExtract, "Render3D Extract"))
  .push(
    (
      @render3d_pipeline.render3d_prepare_system,
      RenderPrepare,
      "Render3D Prepare",
    ),
  )
}

///|
pub fn run() -> Unit {
  @system.App::new()
  .with_viewport_width(VIEWPORT_WIDTH)
  .with_viewport_height(VIEWPORT_HEIGHT)
  .with_zoom(ZOOM)
  .with_fps(FPS)
  .with_image_smooth(false)
  .add_plugin(add_background_3d_pipeline)
  .add_plugin(@plugins.default_plugin)
  .add_system(startup_system, schedule=Startup)
  .add_system(background3d_system)
  .add_system(menu_state_system)
  .add_system(player_input_system)
  .add_system(player_shoot_system)
  .add_system(player_special_system)
  .add_system(enemy_spawn_system)
  .add_system(simulation_system)
  .add_system(combat_system)
  .add_system(victory_system)
  .add_system(ui_system)
  .run()
}

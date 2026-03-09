///|
fn default_exit_handler() -> Unit {
  @system.exit()
}

///|
let exit_handler : Ref[() -> Unit] = { val: default_exit_handler }

///|
fn request_exit() -> Unit {
  (exit_handler.val)()
}

///|
pub fn set_exit_handler(handler : () -> Unit) -> Unit {
  exit_handler.val = handler
}

///|
pub fn reset_exit_handler() -> Unit {
  exit_handler.val = default_exit_handler
}

///|
pub fn enter_from_host() -> Unit {
  startup_system(0.0)
}

///|
pub fn add_runtime_systems(
  app : @system.App,
  run_if : () -> Bool,
) -> @system.App {
  app
  .add_system(player_input_system, run_if~)
  .add_system(ghost_update_system, run_if~)
  .add_system(lighting_debug_system, run_if~)
  .add_system(minimap_system, run_if~)
  .add_system(hud_system, schedule=Render, run_if~)
}

///|
pub fn run() -> Unit {
  reset_exit_handler()
  let app = @system.App::new()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(1.0)
    .with_fps(FPS)
    .with_image_smooth(true)
    .add_plugin(@plugins.default_3d_plugin)
    .add_system(startup_system, schedule=Startup)
  let app = add_runtime_systems(app, fn() { true })
  app.run()
}

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
  startup_system(@ecs.require_current_world())
}

///|
pub fn add_runtime_systems(app : @app.App, run_if : () -> Bool) -> @app.App {
  app
  .add_system(fn(world, _delta) { player_input_system(world) }, run_if=fn(
    _world,
  ) {
    run_if()
  })
  .add_system(fn(world, _delta) { ghost_update_system(world) }, run_if=fn(
    _world,
  ) {
    run_if()
  })
  .add_system(fn(world, _delta) { lighting_debug_system(world) }, run_if=fn(
    _world,
  ) {
    run_if()
  })
  .add_system(fn(world, _delta) { minimap_system(world) }, run_if=fn(_world) {
    run_if()
  })
  .add_system(fn(world, _delta) { hud_system(world) }, schedule=Render, run_if=fn(
    _world,
  ) {
    run_if()
  })
}

///|
pub fn run() -> Unit {
  reset_exit_handler()
  let app = @app.App::new()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(1.0)
    .with_fps(FPS)
    .with_image_smooth(true)
    .add_plugin(@plugins.default_3d_plugin)
    .add_system(fn(world, _delta) { startup_system(world) }, schedule=Startup)
  let app = add_runtime_systems(app, fn() { true })
  app.run()
}

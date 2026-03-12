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
  .add_system(Update, menu_state_system, run_if=fn(_world) { run_if() })
  .add_system(Update, player_input_system, run_if=fn(_world) { run_if() })
  .add_system(Update, player_shoot_system, run_if=fn(_world) { run_if() })
  .add_system(Update, player_special_system, run_if=fn(_world) { run_if() })
  .add_system(Update, enemy_spawn_system, run_if=fn(_world) { run_if() })
  .add_system(Update, simulation_system, run_if=fn(_world) { run_if() })
  .add_system(Update, combat_system, run_if=fn(_world) { run_if() })
  .add_system(Update, victory_system, run_if=fn(_world) { run_if() })
  .add_system(Update, ui_system, run_if=fn(_world) { run_if() })
}

///|
pub fn run() -> Unit {
  reset_exit_handler()
  let app = @app.App::new()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(ZOOM)
    .with_fps(FPS)
    .with_image_smooth(false)
    .add_plugin(@plugins.default_plugin)
    .add_system(Startup, startup_system)
  let app = add_runtime_systems(app, fn() { true })
  app.run()
}

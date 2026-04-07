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
  .add_system(Update, debug_runtime_system, run_if=fn(_world) { run_if() })
  .add_system(Update, player_input_system, run_if=fn(_world) { run_if() })
  .add_system(Update, ghost_update_system, run_if=fn(_world) { run_if() })
  .add_system(Update, lighting_debug_system, run_if=fn(_world) { run_if() })
  .add_system(Update, minimap_system, run_if=fn(_world) { run_if() })
  .add_system(Render, hud_system, run_if=fn(_world) { run_if() })
  .add_system(RenderCleanup, capture_after_render_system, run_if=fn(_world) {
    run_if()
  })
}

///|
pub fn run() -> Unit {
  @raylib.set_trace_log_level(@raylib.LogError)
  reset_exit_handler()
  let runtime_qa = env_flag_enabled(DEBUG_CAPTURE_ENV) ||
    env_flag_enabled(DEBUG_PROFILE_ENV)
  let target_fps = if runtime_qa { 66U } else { FPS }
  let app = @app.App::new()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(1.0)
    .with_fps(target_fps)
    .with_image_smooth(true)
    .add_plugin(@plugins.default_3d_plugin)
    .add_system(Startup, startup_system)
  let app = add_runtime_systems(app, fn() { true })
  app.run()
}

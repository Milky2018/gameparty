///|
pub fn run(plugin : TopDownPluginDef) -> Unit {
  match validate_plugin(plugin) {
    Some(message) =>
      abort(
        "topdown_action plugin validation failed for '\{plugin.meta.id}': \{message}",
      )
    None => ()
  }
  setup_plugin(plugin)
  @raylib.set_trace_log_level(@raylib.LogError)
  let app = @app.App::new()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(1.0)
    .with_fps(runtime_fps())
    .with_image_smooth(true)
    .add_plugin(@plugins.default_plugin)
    .add_system(Startup, startup_system)
    .add_system(FixedPostUpdate, input_system)
    .add_system(FixedPostUpdate, intent_system)
    .add_system(FixedPostUpdate, movement_collision_system)
    .add_system(FixedPostUpdate, combat_system)
    .add_system(FixedPostUpdate, spawn_loot_system)
    .add_system(FixedPostUpdate, state_transition_system)
    .add_system(Update, render_sync_system)
    .add_system(RenderCleanup, capture_after_render_system)
  app.run()
}

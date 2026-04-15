///|
pub fn run(plugin : TopDownShooterPluginDef) -> Unit {
  match validate_plugin(plugin) {
    Some(message) =>
      abort(
        "topdown_shooter plugin validation failed for '\{plugin.meta.id}': \{message}",
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
    .add_system(FixedPostUpdate, aim_system)
    .add_system(FixedPostUpdate, movement_collision_system)
    .add_system(FixedPostUpdate, pickups_system)
    .add_system(FixedPostUpdate, fire_projectiles_system)
    .add_system(FixedPostUpdate, damage_respawn_system)
    .add_system(FixedPostUpdate, bot_update_system)
    .add_system(FixedPostUpdate, score_time_system)
    .add_system(Update, ui_sync_system)
    .add_system(RenderCleanup, capture_after_render_system)
  app.run()
}

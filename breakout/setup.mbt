///|
fn setup_overlay_entities() -> Unit {
  panel_entity(
    overlay_panel_entity,
    color_rgba(16U, 22U, 32U, 0.82),
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5,
    220.0,
    72.0,
    280.0,
  )
  centered_text_entity(
    overlay_text_entity,
    "",
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5,
    200.0,
    52.0,
    22,
    "rgb(255,255,255)",
    290.0,
  )
  set_entity_visible(overlay_panel_entity, false)
  set_entity_visible(overlay_text_entity, false)
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  ensure_runtime_storage()
  setup_overlay_entities()
  ensure_sounds_loaded()
  reset_run_state()
}

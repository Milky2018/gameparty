///|
fn ensure_segment_entities_created() -> Unit {
  if !segment_entities.is_empty() {
    return
  }
  for _ in 0..<TOTAL_CELLS {
    segment_entities.push(@entity.Entity::Entity())
  }
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  ensure_segment_entities_created()
  ensure_sounds_loaded()
  reset_to_title()
}

///|
test "level index wraps around" {
  init_levels_once()
  let count = level_count()
  assert_true(count > 0)
  assert_eq(previous_level_index(0), count - 1)
  assert_eq(next_level_index(count - 1), 0)
}

///|
test "grid center converts back to same cell" {
  let center = grid_to_world_center(6, 8)
  assert_eq(world_to_grid(center), (6, 8))
}

///|
test "circle overlap helper basic cases" {
  let a = vec2(10.0, 10.0)
  let b = vec2(20.0, 10.0)
  let c = vec2(40.0, 10.0)
  assert_true(circle_overlaps_circle(a, 12.0, b, 8.0))
  assert_false(circle_overlaps_circle(a, 6.0, c, 6.0))
}

///|
test "enemy bullet hit clears round without aborting" {
  let old_phase = phase.val
  let old_round_outcome = round_outcome.val
  let old_player_alive = player.alive
  let old_player_center = player.center

  phase.val = Playing
  round_outcome.val = Victory
  player.alive = true
  player.center = vec2(200.0, 200.0)
  clear_tiles()
  bullets.clear()
  bullet_entities.clear()
  let bullet_entity = @entity.Entity::new()
  bullets.push({
    center: vec2(200.0, 200.0),
    direction: Up,
    speed: BULLET_SPEED,
    life_time: 0.0,
    owner: Enemy,
    entity: bullet_entity,
  })
  bullet_entities.push(bullet_entity)

  resolve_bullet_hits()

  assert_true(phase.val is RoundOver)
  assert_true(bullets.length() == 0)
  assert_true(bullet_entities.length() == 0)

  phase.val = old_phase
  round_outcome.val = old_round_outcome
  player.alive = old_player_alive
  player.center = old_player_center
}

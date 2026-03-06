///|
test "tile and world conversion round-trip keeps map cell stable" {
  let x = world_x_for_tile(3)
  let z = world_z_for_tile(4)
  assert_eq(tile_x_for_world(x), 3)
  assert_eq(tile_y_for_world(z), 4)
}

///|
test "minimap world projection keeps tile centers aligned" {
  let world_x = world_x_for_tile(2)
  let world_z = world_z_for_tile(5)
  let pos = minimap_pos_for_world(world_x, world_z, MINIMAP_MARKER_SIZE)
  assert_true(pos[X] >= MINIMAP_OFFSET_X)
  assert_true(pos[Y] >= MINIMAP_OFFSET_Y)
}

///|
test "wall query respects bounds and wall cells" {
  let map = level1
  assert_true(is_wall_at_tile(map, 0, 0))
  assert_true(!is_wall_at_tile(map, 1, 1))
  assert_true(is_wall_at_tile(map, -1, 0))
  assert_true(is_wall_at_tile(map, 0, -1))
  assert_true(is_wall_at_tile(map, 999, 999))
}

///|
test "ghost speed tiers remain ordered by type" {
  let old_level = current_level.val
  current_level.val = 2
  let fast = ghost_speed(Fast)
  let normal = ghost_speed(Normal)
  let slow = ghost_speed(Slow)
  assert_true(fast > normal)
  assert_true(normal > slow)
  current_level.val = old_level
}

///|
test "ghost speed matches upstream tier formula" {
  let old_level = current_level.val
  current_level.val = 3
  let base = BASE_GHOST_SPEED + 3.0 * GHOST_LEVEL_SPEED_BONUS
  assert_eq(ghost_speed(Fast), base * 1.5)
  assert_eq(ghost_speed(Normal), base)
  assert_eq(ghost_speed(Slow), base * 0.7)
  current_level.val = old_level
}

///|
test "next_level wraps and marks completion after final stage" {
  let old_level = current_level.val
  let old_completed = completed_all_levels.val

  current_level.val = levels.length() - 1
  completed_all_levels.val = false
  next_level()
  assert_eq(current_level.val, 0)
  assert_true(completed_all_levels.val)

  current_level.val = old_level
  completed_all_levels.val = old_completed
}

///|
test "half_dots_collected follows upstream threshold semantics" {
  let old_dots = []
  for dot in dots {
    old_dots.push(dot)
  }
  dots.clear()

  dots.push({
    entity: @entity.Entity::new(),
    minimap_entity: @entity.Entity::new(),
    x: 0.0,
    z: 0.0,
    collected: true,
  })
  dots.push({
    entity: @entity.Entity::new(),
    minimap_entity: @entity.Entity::new(),
    x: 1.0,
    z: 0.0,
    collected: false,
  })
  assert_true(half_dots_collected())

  dots[0] = { ..dots[0], collected: false }
  assert_true(!half_dots_collected())

  dots.clear()
  for dot in old_dots {
    dots.push(dot)
  }
}

///|
test "minimap ghost markers stay hidden until half dots are collected" {
  let old_player_x = player_state.x
  let old_player_z = player_state.z
  let old_dots = []
  for dot in dots {
    old_dots.push(dot)
  }
  let old_ghosts = []
  for ghost in ghosts {
    old_ghosts.push(ghost)
  }
  dots.clear()
  ghosts.clear()

  let ghost_marker = @entity.Entity::new()
  @sprite.sprites.set(
    ghost_marker,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(2.0, 2.0), "white"),
      1,
    ),
  )
  ghosts.push({
    entity: @entity.Entity::new(),
    light_entity: @entity.Entity::new(),
    left_eye_entity: @entity.Entity::new(),
    right_eye_entity: @entity.Entity::new(),
    minimap_entity: ghost_marker,
    x: world_x_for_tile(2),
    z: world_z_for_tile(2),
    direction: Right,
    ghost_type: Normal,
  })
  dots.push({
    entity: @entity.Entity::new(),
    minimap_entity: @entity.Entity::new(),
    x: 0.0,
    z: 0.0,
    collected: false,
  })
  dots.push({
    entity: @entity.Entity::new(),
    minimap_entity: @entity.Entity::new(),
    x: 1.0,
    z: 0.0,
    collected: false,
  })

  player_state.x = world_x_for_tile(1)
  player_state.z = world_z_for_tile(1)

  minimap_system(0.0)
  if @sprite.sprites.get(ghost_marker) is Some(sprite) {
    assert_true(!sprite.visible)
  } else {
    fail("missing ghost marker sprite")
  }

  dots[0] = { ..dots[0], collected: true }
  minimap_system(0.0)
  if @sprite.sprites.get(ghost_marker) is Some(sprite) {
    assert_true(sprite.visible)
  } else {
    fail("missing ghost marker sprite")
  }

  dots.clear()
  for dot in old_dots {
    dots.push(dot)
  }
  ghosts.clear()
  for ghost in old_ghosts {
    ghosts.push(ghost)
  }
  player_state.x = old_player_x
  player_state.z = old_player_z
}

///|
test "hud strings follow upstream content" {
  let old_level = current_level.val
  let old_completed = completed_all_levels.val

  current_level.val = 1
  completed_all_levels.val = false
  assert_eq(hud_level_text(), "Level: 2")
  assert_eq(hud_completion_title(), "")
  assert_eq(hud_completion_body(), "")

  completed_all_levels.val = true
  assert_eq(hud_completion_title(), "CONGRATULATIONS!")
  assert_eq(hud_completion_body(), "You completed all levels!")

  current_level.val = old_level
  completed_all_levels.val = old_completed
}

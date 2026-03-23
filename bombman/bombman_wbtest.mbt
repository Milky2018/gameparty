///|
fn reset_test_input_state() -> Unit {
  @inputs.pressed_keys.clear()
  reset_direction_input_state()
}

///|
fn set_player_state(
  center : @math.Vec2D,
  direction : Direction?,
  desired_direction : Direction?,
  alive : Bool,
) -> Unit {
  player.val = {
    ..player.val,
    center,
    direction,
    desired_direction,
    speed: PLAYER_SPEED,
    radius: PLAYER_RADIUS,
    alive,
  }
}

///|
fn with_test_level(test_fn : () -> Unit raise) -> Unit raise {
  reset_test_input_state()
  current_level.val = 0
  reset_level()
  phase.val = Playing
  test_fn()
}

///|
test "explosion propagation stops at hard walls and soft walls" {
  with_test_level(fn() raise {
    set_tile(4, 5, Empty)
    set_tile(5, 5, Empty)
    set_tile(6, 5, Empty)
    set_tile(7, 5, SoftWall)
    set_tile(8, 5, Empty)
    set_tile(5, 4, HardWall)
    set_tile(5, 6, Empty)
    let cells = collect_explosion_cells(5, 5, 3)
    assert_true(cells.contains((5, 5)))
    assert_true(cells.contains((6, 5)))
    assert_true(cells.contains((7, 5)))
    assert_true(!cells.contains((8, 5)))
    assert_true(!cells.contains((5, 4)))
    assert_true(cells.contains((5, 6)))
  })
}

///|
test "latest held direction prefers the most recent pressed key" {
  with_test_level(fn() raise {
    @inputs.pressed_keys.add(KeyW)
    record_direction_press(Up)
    @inputs.pressed_keys.add(KeyD)
    record_direction_press(Right)
    assert_true(latest_held_direction() is Some(Right))
    @inputs.pressed_keys.remove(KeyD)
    assert_true(latest_held_direction() is Some(Up))
  })
}

///|
test "space can start the game from the title screen" {
  reset_test_input_state()
  current_level.val = 0
  reset_level()
  phase.val = Start
  @inputs.pressed_keys.add(Space)
  @inputs.advanced_key_system(1.0 / FPS.to_double())
  input_system(@ecs.require_current_world())
  assert_true(phase.val == Playing)
  @inputs.pressed_keys.clear()
  @inputs.advanced_key_system(1.0 / FPS.to_double())
}

///|
test "built-in levels load with one player spawn and empty enemy spawn cells" {
  for level_index in 0..<levels.length() {
    current_level.val = level_index
    reset_level()
    let (player_cell_x, player_cell_y) = world_to_cell(player.val.center)
    assert_true(tile_at(player_cell_x, player_cell_y) == Empty)
    assert_true(enemies.length() > 0)
    for enemy in enemies {
      assert_true(tile_at(enemy.cell_x, enemy.cell_y) == Empty)
    }
  }
  current_level.val = 0
}

///|
test "won phase advances to the next level" {
  reset_test_input_state()
  current_level.val = 0
  reset_level()
  phase.val = Won
  request_start()
  assert_eq(current_level.val, 1)
  assert_true(phase.val == Playing)
}

///|
test "player movement is continuous and frame-driven" {
  with_test_level(fn() raise {
    let start_center = cell_center(1, 1)
    set_player_state(start_center, Some(Right), Some(Right), true)
    tick_player_motion(0.25)
    assert_eq(player.val.center[Y], start_center[Y])
    assert_eq(player.val.center[X], start_center[X] + PLAYER_SPEED * 0.25)
    assert_true(player.val.center[X] < cell_center(2, 1)[X])
  })
}

///|
test "character and bomb radii are almost full-cell sized" {
  assert_eq(PLAYER_RADIUS, CELL_SIZE / 2.0 - 0.5)
  assert_eq(ENEMY_RADIUS, CELL_SIZE / 2.0 - 0.5)
  assert_eq(BOMB_RADIUS, CELL_SIZE / 2.0 - 0.5)
}

///|
test "turn assist snaps aligned turns and rejects misaligned turns" {
  with_test_level(fn() raise {
    set_tile(1, 3, Empty)
    set_tile(1, 2, Empty)
    set_tile(2, 3, Empty)
    let turn_origin = cell_center(1, 3) + @math.Vec2D(0.0, 8.0)
    set_player_state(turn_origin, Some(Up), Some(Right), true)
    tick_player_motion(0.1)
    assert_eq(player.val.center[Y], cell_center(1, 3)[Y])
    assert_true(player.val.center[X] > turn_origin[X])

    let blocked_turn_origin = cell_center(1, 3) + @math.Vec2D(0.0, 12.0)
    set_player_state(blocked_turn_origin, Some(Up), Some(Right), true)
    tick_player_motion(0.1)
    assert_eq(player.val.center[X], blocked_turn_origin[X])
    assert_true(player.val.center[Y] < blocked_turn_origin[Y])
  })
}

///|
test "player cannot pass through hard walls" {
  with_test_level(fn() raise {
    let start_center = cell_center(1, 1)
    set_player_state(start_center, Some(Left), Some(Left), true)
    tick_player_motion(0.25)
    let wall_edge = cell_bounds(0, 1).right + player.val.radius
    assert_eq(player.val.center[X], wall_edge)
    assert_eq(player.val.center[Y], start_center[Y])
  })
}

///|
test "bomb placement snaps to the current tile and becomes solid after exit" {
  with_test_level(fn() raise {
    bombs.clear()
    let off_center = cell_center(1, 1) + @math.Vec2D(7.0, 0.0)
    set_player_state(off_center, None, None, true)
    player.val = { ..player.val, active_bombs: 0 }
    place_bomb()
    assert_eq(bombs.length(), 1)
    assert_eq(bombs[0].cell_x, 1)
    assert_eq(bombs[0].cell_y, 1)
    assert_true(bombs[0].passable_for_player)

    player.val = {
      ..player.val,
      desired_direction: Some(Right),
      direction: Some(Right),
    }
    tick_player_motion(0.4)
    assert_true(!bombs[0].passable_for_player)

    let before_return = player.val.center
    player.val = {
      ..player.val,
      desired_direction: Some(Left),
      direction: Some(Left),
    }
    tick_player_motion(0.4)
    let bomb_center = cell_center(1, 1)
    let dy = player.val.center[Y] - bomb_center[Y]
    let tangent_x = bomb_center[X] +
      @cmath.pow(
        (player.val.radius + BOMB_RADIUS) * (player.val.radius + BOMB_RADIUS) -
        dy * dy,
        0.5,
      )
    assert_true(player.val.center[X] >= tangent_x - 0.01)
    assert_true(player.val.center[X] <= before_return[X])
  })
}

///|
test "exploding bomb removes soft wall and chained bombs" {
  with_test_level(fn() raise {
    bombs.clear()
    flames.clear()
    player.val = { ..player.val, active_bombs: 0 }
    set_tile(3, 1, SoftWall)
    bombs.push({
      entity: @entity.Entity::new(),
      cell_x: 2,
      cell_y: 1,
      timer: 0.0,
      radius: 2,
      passable_for_player: false,
    })
    player.val = { ..player.val, active_bombs: 1 }
    resolve_bomb_explosions()
    assert_true(tile_at(3, 1) == Empty)
    assert_true(
      flames.any(fn(flame) { flame.cell_x == 3 && flame.cell_y == 1 }),
    )
    assert_eq(player.val.active_bombs, 0)
  })
}

///|
test "flames only hit when the center enters the flame cell" {
  with_test_level(fn() raise {
    flames.clear()
    enemies.clear()
    set_player_state(cell_center(5, 4), None, None, true)
    spawn_flame(4, 4)
    resolve_flame_hits()
    assert_true(player.val.alive)

    set_player_state(cell_center(4, 4), None, None, true)
    resolve_flame_hits()
    assert_true(!player.val.alive)
  })
}

///|
test "enemy next to a blasted soft wall survives until its center enters the flame cell" {
  with_test_level(fn() raise {
    flames.clear()
    enemies.clear()
    set_tile(3, 1, SoftWall)
    bombs.clear()
    bombs.push({
      entity: @entity.Entity::new(),
      cell_x: 2,
      cell_y: 1,
      timer: 0.0,
      radius: 2,
      passable_for_player: false,
    })
    player.val = { ..player.val, active_bombs: 1 }
    let adjacent_center = cell_center(4, 1) +
      @math.Vec2D(-PLAYER_RADIUS + 1.0, 0.0)
    enemies.push({
      entity: @entity.Entity::new(),
      cell_x: 4,
      cell_y: 1,
      center: adjacent_center,
      direction: Left,
      desired_direction: Left,
      speed: ENEMY_SPEED,
      radius: ENEMY_RADIUS,
      alive: true,
    })
    resolve_bomb_explosions()
    resolve_flame_hits()
    assert_true(tile_at(3, 1) == Empty)
    assert_true(
      flames.any(fn(flame) { flame.cell_x == 3 && flame.cell_y == 1 }),
    )
    assert_true(enemies[0].alive)

    enemies[0].center = cell_center(3, 1)
    resolve_enemy_contact()
    resolve_flame_hits()
    assert_true(!enemies[0].alive)
  })
}

///|
test "enemy contact still uses continuous overlap" {
  with_test_level(fn() raise {
    enemies.clear()
    let player_contact_center = cell_center(6, 4)
    set_player_state(player_contact_center, None, None, true)
    let enemy_center = player_contact_center +
      @math.Vec2D(PLAYER_RADIUS + ENEMY_RADIUS - 1.0, 0.0)
    enemies.push({
      entity: @entity.Entity::new(),
      cell_x: 6,
      cell_y: 4,
      center: enemy_center,
      direction: Left,
      desired_direction: Left,
      speed: ENEMY_SPEED,
      radius: ENEMY_RADIUS,
      alive: true,
    })
    resolve_enemy_contact()
    assert_true(!player.val.alive)
  })
}

///|
test "enemy movement stays continuous and reroutes around blocked tiles" {
  with_test_level(fn() raise {
    bombs.clear()
    enemies.clear()
    bombs.push({
      entity: @entity.Entity::new(),
      cell_x: 3,
      cell_y: 1,
      timer: BOMB_FUSE_TIME,
      radius: PLAYER_BLAST_RADIUS,
      passable_for_player: false,
    })
    let enemy_center = cell_center(2, 1)
    enemies.push({
      entity: @entity.Entity::new(),
      cell_x: 2,
      cell_y: 1,
      center: enemy_center,
      direction: Right,
      desired_direction: Right,
      speed: ENEMY_SPEED,
      radius: ENEMY_RADIUS,
      alive: true,
    })
    tick_enemies(0.2)
    assert_true(enemies[0].center[X] < enemy_center[X])
    assert_eq(enemies[0].center[Y], enemy_center[Y])
  })
}

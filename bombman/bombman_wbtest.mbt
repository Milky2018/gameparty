///|
fn reset_test_input_state() -> Unit {
  @inputs.pressed_keys.clear()
  reset_direction_input_state()
  suppress_exit_for_tests.val = true
  exit_request_count.val = 0
}

///|
fn advance_input_frame() -> Unit {
  @inputs.advanced_key_system(1.0 / FPS.to_double())
}

///|
fn prepare_menu() -> Unit {
  reset_test_input_state()
  return_to_menu()
  menu_selection.val = OnePlayer
  phase.val = MainMenu
}

///|
fn with_round(mode : GameMode, test_fn : () -> Unit raise) -> Unit raise {
  reset_test_input_state()
  current_level.val = 0
  start_round(mode)
  test_fn()
}

///|
fn press_menu_key(key : @inputs.Code) -> Unit {
  @inputs.pressed_keys.add(key)
  advance_input_frame()
  input_system(@ecs.require_current_world())
  @inputs.pressed_keys.remove(key)
  advance_input_frame()
}

///|
test "menu navigation wraps and selection starts correct modes" {
  prepare_menu()
  assert_true(menu_selection.val == OnePlayer)
  assert_eq(current_level.val, 0)
  press_menu_key(@inputs.KeyD)
  assert_eq(current_level.val, 1)
  press_menu_key(@inputs.ArrowRight)
  assert_eq(current_level.val, 2)
  press_menu_key(@inputs.KeyA)
  assert_eq(current_level.val, 1)
  current_level.val = 0
  press_menu_key(@inputs.ArrowLeft)
  assert_eq(current_level.val, levels.length() - 1)
  press_menu_key(@inputs.KeyS)
  assert_true(menu_selection.val == TwoPlayersA)
  press_menu_key(@inputs.KeyS)
  assert_true(menu_selection.val == TwoPlayersB)
  press_menu_key(@inputs.KeyS)
  assert_true(menu_selection.val == Exit)
  press_menu_key(@inputs.KeyS)
  assert_true(menu_selection.val == OnePlayer)
  press_menu_key(@inputs.ArrowUp)
  assert_true(menu_selection.val == Exit)

  menu_selection.val = TwoPlayersA
  press_menu_key(@inputs.Enter)
  assert_true(phase.val == Playing)
  assert_true(current_mode.val == Coop)
  assert_true(players[0].active)
  assert_true(players[1].active)
}

///|
test "menu exit triggers exit path" {
  prepare_menu()
  menu_selection.val = Exit
  press_menu_key(@inputs.Space)
  assert_eq(exit_request_count.val, 1)
  assert_true(phase.val == MainMenu)
}

///|
test "built-in levels contain exactly one P1 spawn and one P2 spawn" {
  for level in levels {
    let mut p1 = 0
    let mut p2 = 0
    for row in level {
      for code in row {
        if code == LEVEL_P1_SPAWN {
          p1 += 1
        }
        if code == LEVEL_P2_SPAWN {
          p2 += 1
        }
      }
    }
    assert_eq(p1, 1)
    assert_eq(p2, 1)
  }
}

///|
test "versus level strips enemy spawns while normal modes keep them" {
  current_level.val = 0
  start_round(SinglePlayer)
  assert_true(enemies.length() > 0)
  start_round(Versus)
  assert_eq(enemies.length(), 0)
  assert_true(players[0].active)
  assert_true(players[1].active)
}

///|
test "single-player accepts arrows and space bomb" {
  with_round(SinglePlayer, fn() raise {
    @inputs.pressed_keys.add(@inputs.ArrowRight)
    advance_input_frame()
    input_system(@ecs.require_current_world())
    assert_true(players[0].desired_direction is Some(Right))
    @inputs.pressed_keys.clear()
    advance_input_frame()

    let current = players[0]
    players[0] = { ..current, active_bombs: 0 }
    @inputs.pressed_keys.add(@inputs.Space)
    advance_input_frame()
    input_system(@ecs.require_current_world())
    assert_eq(bombs.length(), 1)
    assert_true(bombs[0].owner == P1)
    @inputs.pressed_keys.clear()
    advance_input_frame()
  })
}

///|
test "dual-player controls use WASD+G and IJKL+apostrophe" {
  with_round(Coop, fn() raise {
    @inputs.pressed_keys.add(@inputs.KeyD)
    @inputs.pressed_keys.add(@inputs.KeyL)
    advance_input_frame()
    input_system(@ecs.require_current_world())
    assert_true(players[0].desired_direction is Some(Right))
    assert_true(players[1].desired_direction is Some(Right))
    @inputs.pressed_keys.clear()
    advance_input_frame()

    @inputs.pressed_keys.add(@inputs.KeyG)
    advance_input_frame()
    input_system(@ecs.require_current_world())
    assert_eq(bombs.length(), 1)
    assert_true(bombs[0].owner == P1)
    @inputs.pressed_keys.clear()
    advance_input_frame()

    p2_bomb_test_override.val = true
    input_system(@ecs.require_current_world())
    assert_eq(bombs.length(), 2)
    assert_true(bombs[1].owner == P2)

    @inputs.pressed_keys.add(@inputs.Space)
    advance_input_frame()
    input_system(@ecs.require_current_world())
    assert_eq(bombs.length(), 2)
    @inputs.pressed_keys.clear()
    advance_input_frame()
  })
}

///|
test "bomb owner can leave just-placed bomb but other player cannot pass through" {
  with_round(Coop, fn() raise {
    players[0] = { ..players[0], center: cell_center(1, 1), active_bombs: 0 }
    players[1] = { ..players[1], center: cell_center(1, 2), active_bombs: 0 }
    place_bomb_for_player(0)
    assert_eq(bombs.length(), 1)
    assert_true(bombs[0].passable_for_owner)

    players[0] = {
      ..players[0],
      desired_direction: Some(Right),
      direction: Some(Right),
    }
    tick_players_motion(0.2)
    assert_true(bombs[0].passable_for_owner)

    players[1] = {
      ..players[1],
      desired_direction: Some(Up),
      direction: Some(Up),
    }
    tick_players_motion(0.2)
    let blocked_y = cell_center(bombs[0].cell_x, bombs[0].cell_y)[Y] +
      players[1].radius +
      BOMB_RADIUS
    assert_true(players[1].center[Y] >= blocked_y - 0.01)

    players[0] = {
      ..players[0],
      desired_direction: Some(Right),
      direction: Some(Right),
    }
    tick_players_motion(0.25)
    assert_true(!bombs[0].passable_for_owner)
  })
}

///|
test "co-op win needs enemies gone and at least one survivor" {
  with_round(Coop, fn() raise {
    enemies.clear()
    players[0] = { ..players[0], alive: false }
    players[1] = { ..players[1], alive: true }
    resolve_phase()
    assert_true(phase.val == RoundOver)
    assert_true(round_outcome.val is LevelClear)
  })
}

///|
test "co-op loss only happens when both players are dead" {
  with_round(Coop, fn() raise {
    players[0] = { ..players[0], alive: false }
    players[1] = { ..players[1], alive: true }
    resolve_phase()
    assert_true(phase.val == Playing)
    players[1] = { ..players[1], alive: false }
    resolve_phase()
    assert_true(phase.val == RoundOver)
    assert_true(round_outcome.val is Defeat)
  })
}

///|
test "versus outcomes resolve to P1 win, P2 win, or draw" {
  with_round(Versus, fn() raise {
    players[0] = { ..players[0], alive: true }
    players[1] = { ..players[1], alive: false }
    resolve_phase()
    assert_true(round_outcome.val is P1Win)

    start_round(Versus)
    players[0] = { ..players[0], alive: false }
    players[1] = { ..players[1], alive: true }
    resolve_phase()
    assert_true(round_outcome.val is P2Win)

    start_round(Versus)
    players[0] = { ..players[0], alive: false }
    players[1] = { ..players[1], alive: false }
    resolve_phase()
    assert_true(round_outcome.val is Draw)
  })
}

///|
test "single-player level clear advances to next level and versus restarts same arena" {
  current_level.val = 0
  start_round(SinglePlayer)
  enemies.clear()
  resolve_phase()
  assert_true(round_outcome.val is LevelClear)
  continue_after_round_over()
  assert_eq(current_level.val, 1)
  assert_true(current_mode.val == SinglePlayer)
  assert_true(phase.val == Playing)

  current_level.val = 2
  start_round(Versus)
  players[0] = { ..players[0], alive: false }
  players[1] = { ..players[1], alive: true }
  resolve_phase()
  continue_after_round_over()
  assert_eq(current_level.val, 2)
  assert_true(current_mode.val == Versus)
  assert_eq(enemies.length(), 0)
}

///|
test "flame hits every active player by center-in-cell semantics" {
  with_round(Coop, fn() raise {
    flames.clear()
    players[0] = { ..players[0], center: cell_center(4, 4), alive: true }
    players[1] = { ..players[1], center: cell_center(5, 4), alive: true }
    spawn_flame(4, 4)
    resolve_flame_hits()
    assert_true(!players[0].alive)
    assert_true(players[1].alive)
  })
}

///|
test "enemy contact kills any overlapping active player outside versus" {
  with_round(Coop, fn() raise {
    enemies.clear()
    let center = cell_center(5, 5)
    players[0] = { ..players[0], center, alive: true }
    players[1] = { ..players[1], center: cell_center(1, 1), alive: true }
    enemies.push({
      entity: @entity.Entity::new(),
      cell_x: 5,
      cell_y: 5,
      center,
      direction: Down,
      desired_direction: Down,
      speed: ENEMY_SPEED,
      radius: ENEMY_RADIUS,
      alive: true,
    })
    resolve_enemy_contact()
    assert_true(!players[0].alive)
    assert_true(players[1].alive)

    start_round(Versus)
    players[0] = { ..players[0], center, alive: true }
    enemies.push({
      entity: @entity.Entity::new(),
      cell_x: 5,
      cell_y: 5,
      center,
      direction: Down,
      desired_direction: Down,
      speed: ENEMY_SPEED,
      radius: ENEMY_RADIUS,
      alive: true,
    })
    resolve_enemy_contact()
    assert_true(players[0].alive)
  })
}

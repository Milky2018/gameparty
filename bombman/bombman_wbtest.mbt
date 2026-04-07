///|
fn reset_test_input_state() -> Unit {
  @inputs.pressed_keys.clear()
  reset_direction_input_state()
  stop_active_netplay()
  netplay_mode.val = Off
  reset_network_menu_state()
  menu_error_message.val = ""
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
  assert_eq(current_level.val, 0)
  press_menu_key(@inputs.ArrowRight)
  assert_eq(current_level.val, 0)
  press_menu_key(@inputs.KeyA)
  assert_eq(current_level.val, 0)
  press_menu_key(@inputs.ArrowLeft)
  assert_eq(current_level.val, 0)
  press_menu_key(@inputs.KeyS)
  assert_true(menu_selection.val == TwoPlayersA)
  press_menu_key(@inputs.KeyS)
  assert_true(menu_selection.val == TwoPlayersB)
  press_menu_key(@inputs.KeyS)
  assert_true(menu_selection.val == NetworkBattle)
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
test "network battle menu routes host/join setup and validates inputs" {
  prepare_menu()
  menu_selection.val = NetworkBattle
  press_menu_key(@inputs.Enter)
  assert_true(phase.val == MainMenu)
  assert_true(menu_screen.val == NetworkRoot)

  // Create room path
  press_menu_key(@inputs.Enter)
  assert_true(menu_screen.val == NetworkHostSetup)
  let selected_before = host_setup_level.val
  host_setup_focus.val = Level
  press_menu_key(@inputs.KeyD)
  assert_eq(host_setup_level.val, next_level_index(selected_before))
  press_menu_key(@inputs.KeyA)
  assert_eq(host_setup_level.val, selected_before)
  host_setup_level.val = 2
  host_setup_focus.val = Port
  host_setup_port.val = "0"
  press_menu_key(@inputs.Enter)
  assert_true(menu_screen.val == NetworkHostSetup)
  assert_true(menu_error_message.val.contains("1..65535"))
  host_setup_port.val = "39000"
  press_menu_key(@inputs.Enter)
  assert_true(menu_screen.val == NetworkLobby)
  assert_true(netplay_mode.val == Host)
  assert_eq(current_level.val, 2)
  assert_true(netplay_session.val is Some(_))
  assert_true(netplay_link.val is Some(_))

  // Cancel lobby and go to join path.
  press_menu_key(@inputs.Enter)
  assert_true(menu_screen.val == NetworkRoot)
  assert_true(netplay_mode.val == Off)
  press_menu_key(@inputs.KeyS)
  press_menu_key(@inputs.Enter)
  assert_true(menu_screen.val == NetworkJoinSetup)
  join_setup_focus.val = Host
  join_setup_host.val = ""
  press_menu_key(@inputs.Enter)
  assert_true(menu_screen.val == NetworkJoinSetup)
  assert_true(menu_error_message.val.contains("Host IP cannot be empty"))
  join_setup_host.val = "127.0.0.1"
  join_setup_port.val = "39000"
  press_menu_key(@inputs.Enter)
  assert_true(menu_screen.val == NetworkLobby)
  assert_true(netplay_mode.val == Client)
  assert_true(netplay_session.val is Some(_))
  assert_true(netplay_link.val is Some(_))
}

///|
test "escape returns from network submenu hierarchy to main menu" {
  prepare_menu()
  menu_selection.val = NetworkBattle
  press_menu_key(@inputs.Enter)
  assert_true(menu_screen.val == NetworkRoot)
  press_menu_key(@inputs.Enter)
  assert_true(menu_screen.val == NetworkHostSetup)
  press_menu_key(@inputs.Escape)
  assert_true(menu_screen.val == NetworkRoot)
  press_menu_key(@inputs.Escape)
  assert_true(menu_screen.val == MainRoot)
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
test "local round startup clears active netplay runtime" {
  reset_test_input_state()
  begin_network_host_lobby(Coop, 39000, 0)
  assert_true(netplay_mode.val == Host)
  assert_true(netplay_session.val is Some(_))
  start_local_round(Coop)
  assert_true(phase.val == Playing)
  assert_true(current_mode.val == Coop)
  assert_true(netplay_mode.val == Off)
  assert_true(netplay_session.val is None)
  assert_true(netplay_link.val is None)
}

///|
test "single-player simulation still advances with stale client mode and no session" {
  reset_test_input_state()
  netplay_mode.val = Client
  current_level.val = 0
  start_round(SinglePlayer)
  let before_x = players[0].center[X]
  players[0] = {
    ..players[0],
    desired_direction: Some(Right),
    direction: Some(Right),
  }
  simulation_system(@ecs.require_current_world())
  assert_true(players[0].center[X] > before_x + 0.1)
}

///|
test "client seed application updates menu state and selected round config" {
  reset_test_input_state()
  current_level.val = 0
  return_to_menu()
  assert_true(phase.val == MainMenu)
  let host_seed = encode_round_seed_for_netplay(2, Versus)
  apply_remote_round_seed(host_seed)
  assert_true(current_mode.val == Versus)
  assert_eq(current_level.val, 2)
  assert_true(phase.val == MainMenu)

  start_round(current_mode.val)
  assert_eq(enemies.length(), 0)
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
    tick_players_motion(1.0)
    assert_true(!bombs[0].passable_for_owner)
  })
}

///|
test "destroyed soft walls can drop items with configured chance" {
  with_round(SinglePlayer, fn() raise {
    bombs.clear()
    flames.clear()
    items.clear()
    forced_drop_rolls.push(0.0)
    forced_drop_kinds.push(PowerUp)
    players[0] = { ..players[0], active_bombs: 1 }
    set_tile(3, 1, SoftWall)
    bombs.push({
      entity: @entity.Entity::new(),
      cell_x: 2,
      cell_y: 1,
      timer: 0.0,
      radius: 1,
      owner: P1,
      passable_for_owner: false,
      anim: anim_playback_new(BombFuse, true),
    })
    resolve_bomb_explosions()
    assert_true(tile_at(3, 1) is SoftWall)
    assert_eq(soft_wall_breaks.length(), 1)
    assert_true(
      !flames.any(fn(flame) { flame.cell_x == 3 && flame.cell_y == 1 }),
    )
    assert_eq(items.length(), 0)
    tick_soft_wall_breaks(SOFT_WALL_BREAK_DURATION + 0.01)
    assert_true(tile_at(3, 1) is Empty)
    assert_eq(items.length(), 1)
    assert_eq(items[0].cell_x, 3)
    assert_eq(items[0].cell_y, 1)
    assert_true(items[0].kind is PowerUp)
  })
}

///|
test "players pick up items with caps applied" {
  with_round(SinglePlayer, fn() raise {
    items.clear()
    let base_speed = players[0].speed
    let base_bombs = players[0].max_bombs
    let base_radius = players[0].blast_radius
    let pickup_cell = cell_center(2, 1)
    players[0] = { ..players[0], center: pickup_cell }

    spawn_item(2, 1, Shoes)
    resolve_item_pickups()
    assert_eq(items.length(), 0)
    assert_eq(players[0].speed, base_speed + CELL_SIZE)

    spawn_item(2, 1, BombUp)
    resolve_item_pickups()
    assert_eq(items.length(), 0)
    assert_eq(players[0].max_bombs, base_bombs + 1)

    spawn_item(2, 1, PowerUp)
    resolve_item_pickups()
    assert_eq(items.length(), 0)
    assert_eq(players[0].blast_radius, base_radius + 1)

    players[0] = {
      ..players[0],
      speed: PLAYER_MAX_SPEED,
      max_bombs: PLAYER_MAX_BOMBS,
      blast_radius: PLAYER_MAX_BLAST_RADIUS,
    }
    spawn_item(2, 1, Shoes)
    spawn_item(3, 1, BombUp)
    spawn_item(4, 1, PowerUp)
    players[0] = { ..players[0], center: cell_center(2, 1) }
    resolve_item_pickups()
    players[0] = { ..players[0], center: cell_center(3, 1) }
    resolve_item_pickups()
    players[0] = { ..players[0], center: cell_center(4, 1) }
    resolve_item_pickups()
    assert_eq(players[0].speed, PLAYER_MAX_SPEED)
    assert_eq(players[0].max_bombs, PLAYER_MAX_BOMBS)
    assert_eq(players[0].blast_radius, PLAYER_MAX_BLAST_RADIUS)
  })
}

///|
test "drop candidates exclude fully maxed item kinds" {
  with_round(SinglePlayer, fn() raise {
    players[0] = {
      ..players[0],
      speed: PLAYER_MAX_SPEED,
      max_bombs: PLAYER_MAX_BOMBS,
      blast_radius: PLAYER_BLAST_RADIUS,
    }
    let candidates = available_drop_kinds()
    assert_eq(candidates.length(), 1)
    assert_true(candidates[0] is PowerUp)
  })
}

///|
test "drop rng advances between rolls after reseed" {
  with_round(SinglePlayer, fn() raise {
    let seed : UInt64 = 20260407
    reseed_drop_rng(seed)
    let roll1 = next_drop_roll()
    let roll2 = next_drop_roll()
    let roll3 = next_drop_roll()
    assert_true(roll1 != roll2 || roll2 != roll3 || roll1 != roll3)
  })
}

///|
test "level1 soft-wall drops can be zero in some seeded runs" {
  with_round(SinglePlayer, fn() raise {
    let level = levels[0]
    let soft_wall_cells : Array[(Int, Int)] = []
    for y in 0..<GRID_HEIGHT {
      for x in 0..<GRID_WIDTH {
        if level[y][x] == LEVEL_SOFT_WALL {
          soft_wall_cells.push((x, y))
        }
      }
    }
    assert_eq(soft_wall_cells.length(), 22)

    let mut zero_drop_runs = 0
    let mut non_zero_runs = 0
    for trial in 1..<513 {
      items.clear()
      reseed_drop_rng(trial.to_uint64())
      for cell in soft_wall_cells {
        let (x, y) = cell
        maybe_spawn_random_item(x, y, SOFT_WALL_ITEM_DROP_CHANCE)
      }
      if items.is_empty() {
        zero_drop_runs += 1
      } else {
        non_zero_runs += 1
      }
    }
    assert_true(zero_drop_runs > 0)
    assert_true(non_zero_runs > 0)
  })
}

///|
test "enemy deaths can drop items with configured chance" {
  with_round(SinglePlayer, fn() raise {
    flames.clear()
    items.clear()
    enemies.clear()
    forced_drop_rolls.push(0.0)
    forced_drop_kinds.push(BombUp)
    let center = cell_center(5, 5)
    enemies.push({
      entity: @entity.Entity::new(),
      cell_x: 5,
      cell_y: 5,
      center,
      direction: Down,
      desired_direction: Down,
      facing: Down,
      flip_x: false,
      speed: ENEMY_SPEED,
      radius: ENEMY_RADIUS,
      alive: true,
      skin: Blue,
      death_animation_done: false,
      anim: anim_playback_new(enemy_move_clip(Blue, Down), true),
    })
    spawn_flame(5, 5, Center)
    resolve_flame_hits()
    assert_eq(items.length(), 1)
    assert_eq(items[0].cell_x, 5)
    assert_eq(items[0].cell_y, 5)
    assert_true(items[0].kind is BombUp)
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
    spawn_flame(4, 4, Center)
    resolve_flame_hits()
    assert_true(!players[0].alive)
    assert_true(players[1].alive)
  })
}

///|
test "soft wall remains blocking until break animation completes" {
  with_round(SinglePlayer, fn() raise {
    soft_wall_breaks.clear()
    set_tile(4, 4, SoftWall)
    spawn_soft_wall_break(4, 4)
    assert_true(tile_is_solid(4, 4))
    tick_soft_wall_breaks(SOFT_WALL_BREAK_DURATION / 2.0)
    assert_true(tile_at(4, 4) is SoftWall)
    tick_soft_wall_breaks(SOFT_WALL_BREAK_DURATION)
    assert_true(tile_at(4, 4) is Empty)
  })
}

///|
test "flame damage window is shorter than visual window" {
  with_round(SinglePlayer, fn() raise {
    flames.clear()
    players[0] = { ..players[0], center: cell_center(6, 6), alive: true }
    spawn_flame(6, 6, Center)
    resolve_flame_hits()
    assert_true(!players[0].alive)

    players[0] = {
      ..players[0],
      alive: true,
      death_animation_done: false,
      anim: anim_playback_new(player_idle_clip(P1, Down), true),
      center: cell_center(6, 6),
    }
    tick_flames(FLAME_DAMAGE_DURATION + 0.01)
    assert_eq(flames.length(), 1)
    resolve_flame_hits()
    assert_true(players[0].alive)
    tick_flames(FLAME_VISUAL_DURATION)
    assert_eq(flames.length(), 0)
  })
}

///|
test "player movement updates animation clip without mirror flip" {
  with_round(SinglePlayer, fn() raise {
    let player = players[0]
    player.direction = Some(Right)
    player.desired_direction = Some(Right)
    tick_player_motion(0, 0.2)
    assert_true(player.anim.clip_id == player_move_clip(P1, Right))
    assert_true(!player.flip_x)

    player.direction = Some(Left)
    player.desired_direction = Some(Left)
    tick_player_motion(0, 0.2)
    assert_true(player.anim.clip_id == player_move_clip(P1, Left))
    assert_true(!player.flip_x)

    player.direction = None
    player.desired_direction = None
    tick_player_motion(0, 0.2)
    assert_true(player.anim.clip_id == player_idle_clip(P1, Left))
    assert_true(!player.flip_x)
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
      facing: Down,
      flip_x: false,
      speed: ENEMY_SPEED,
      radius: ENEMY_RADIUS,
      alive: true,
      skin: Blue,
      death_animation_done: false,
      anim: anim_playback_new(enemy_move_clip(Blue, Down), true),
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
      facing: Down,
      flip_x: false,
      speed: ENEMY_SPEED,
      radius: ENEMY_RADIUS,
      alive: true,
      skin: Blue,
      death_animation_done: false,
      anim: anim_playback_new(enemy_move_clip(Blue, Down), true),
    })
    resolve_enemy_contact()
    assert_true(players[0].alive)
  })
}

///|
test "enemy movement advances over simulation ticks" {
  with_round(SinglePlayer, fn() raise {
    assert_true(enemies.length() > 0)
    let enemy = enemies[0]
    let start = enemy.center
    for _ in 0..<20 {
      tick_enemies(1.0 / 60.0)
    }
    let moved_x = abs_double(enemy.center[X] - start[X]) > 0.001
    let moved_y = abs_double(enemy.center[Y] - start[Y]) > 0.001
    assert_true(moved_x || moved_y)
  })
}

///|
test "quoted rgb css values are normalized before color parsing" {
  assert_eq(
    normalize_css_color_string("\"rgb(18, 24, 30)\""),
    "rgb(18, 24, 30)",
  )
  assert_eq(normalize_css_color_string("'rgb(18, 24, 30)'"), "rgb(18, 24, 30)")
  match parse_css_rgb_components("\"rgb(18, 24, 30)\"") {
    Some((r, g, b, a)) => {
      assert_eq(r, 18U)
      assert_eq(g, 24U)
      assert_eq(b, 30U)
      assert_eq(a, 1.0)
    }
    None => fail("expected quoted rgb to parse")
  }
}

///|
test "plain rgb css values with spaces parse correctly" {
  match parse_css_rgb_components("rgb(86, 113, 140)") {
    Some((r, g, b, a)) => {
      assert_eq(r, 86U)
      assert_eq(g, 113U)
      assert_eq(b, 140U)
      assert_eq(a, 1.0)
    }
    None => fail("expected plain rgb with spaces to parse")
  }
}

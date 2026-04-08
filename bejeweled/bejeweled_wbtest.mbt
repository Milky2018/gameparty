///|
fn reset_logic_state_for_test() -> Unit {
  game_state.phase = Playing
  game_state.score = 0
  game_state.moves_left = MOVE_LIMIT
  game_state.time_left = GAME_TIME_LIMIT
  game_state.first_pick = None
  game_state.drag_origin = None
  game_state.drag_pointer_down = false
  game_state.drag_swapped = false
  game_state.pending_swap_a = None
  game_state.pending_swap_b = None
  game_state.pending_matches.clear()
  game_state.active_tweens.clear()
  game_state.cascade_depth = 0
  game_state.game_over_reason = ""
  set_input_ready_phase()
  for entity in gem_entities {
    if entity.is_alive() {
      entity.destroy()
    }
  }
  gem_entities.clear()
  gem_lookup.clear()
  board.clear()
  for _ in 0..<(BOARD_ROWS * BOARD_COLS) {
    board.push(None)
  }
}

///|
fn place_gem_for_test(row : Int, col : Int, kind : GemKind) -> Unit {
  board_set(row, col, Some(kind))
  let entity = @entity.Entity::new()
  gem_entities.push(entity)
  gem_lookup.set(Cell::{ row, col }, Gem::{ kind, row, col, entity })
}

///|
fn gem_lookup_count() -> Int {
  let mut count = 0
  for _, _ in gem_lookup {
    count += 1
  }
  count
}

///|
fn alive_gem_entity_count() -> Int {
  let mut count = 0
  for entity in gem_entities {
    if entity.is_alive() {
      count += 1
    }
  }
  count
}

///|
fn non_empty_board_count_for_test() -> Int {
  let mut count = 0
  for row in 0..<BOARD_ROWS {
    for col in 0..<BOARD_COLS {
      if board_get(row, col) is Some(_) {
        count += 1
      }
    }
  }
  count
}

///|
fn resolve_until_input_ready(step_limit : Int) -> Int {
  let mut steps = 0
  while game_state.resolution_phase != InputReady && steps < step_limit {
    complete_resolution_phase()
    steps += 1
  }
  steps
}

///|
test "find_matches detects horizontal and vertical runs" {
  reset_logic_state_for_test()
  board_set(0, 0, Some(Emerald))
  board_set(0, 1, Some(Emerald))
  board_set(0, 2, Some(Emerald))
  board_set(1, 4, Some(Sapphire))
  board_set(2, 4, Some(Sapphire))
  board_set(3, 4, Some(Sapphire))
  let matches = find_matches()
  inspect(matches.length(), content="6")
}

///|
test "swap validation rejects non-match and accepts match-making swap" {
  reset_logic_state_for_test()
  board_set(0, 0, Some(Emerald))
  board_set(0, 1, Some(Sapphire))
  swap_cells(Cell::{ row: 0, col: 0 }, Cell::{ row: 0, col: 1 })
  if find_matches().is_empty() {
    swap_cells(Cell::{ row: 0, col: 0 }, Cell::{ row: 0, col: 1 })
  }
  inspect(board_get(0, 0), content="Some(Emerald)")
  inspect(board_get(0, 1), content="Some(Sapphire)")
  board_set(1, 1, Some(Emerald))
  board_set(2, 1, Some(Emerald))
  swap_cells(Cell::{ row: 0, col: 0 }, Cell::{ row: 0, col: 1 })
  inspect(find_matches().is_empty(), content="false")
  inspect(board_get(0, 0), content="Some(Sapphire)")
  inspect(board_get(0, 1), content="Some(Emerald)")
}

///|
test "begin_fall_phase compresses columns downward" {
  reset_logic_state_for_test()
  place_gem_for_test(5, 3, Ruby)
  inspect(begin_fall_phase(), content="true")
  assert_true(game_state.resolution_phase is Fall)
  inspect(board_get(7, 3), content="Some(Ruby)")
  inspect(board_get(5, 3), content="None")
}

///|
test "fill_board_without_initial_matches creates a match-free board" {
  reset_logic_state_for_test()
  fill_board_without_initial_matches()
  inspect(find_matches().is_empty(), content="true")
}

///|
test "selected hint text reflects the picked gem" {
  reset_logic_state_for_test()
  board_set(0, 0, Some(Ruby))
  game_state.first_pick = Some(Cell::{ row: 0, col: 0 })
  inspect(
    selected_hint_text(),
    content="Selected Ruby at 1,1. Pick an adjacent gem.",
  )
}

///|
test "invalid swap plays forward then rollback and restores board" {
  reset_logic_state_for_test()
  place_gem_for_test(0, 0, Ruby)
  place_gem_for_test(0, 1, Emerald)
  let a = Cell::{ row: 0, col: 0 }
  let b = Cell::{ row: 0, col: 1 }
  begin_swap_forward_phase(a, b)
  assert_true(game_state.resolution_phase is SwapForward)
  complete_resolution_phase()
  assert_true(game_state.resolution_phase is SwapRollback)
  inspect(board_get(0, 0), content="Some(Emerald)")
  inspect(board_get(0, 1), content="Some(Ruby)")
  complete_resolution_phase()
  assert_true(game_state.resolution_phase is InputReady)
  inspect(board_get(0, 0), content="Some(Ruby)")
  inspect(board_get(0, 1), content="Some(Emerald)")
}

///|
test "valid swap resolves through clear fall refill and returns input ready" {
  reset_logic_state_for_test()
  place_gem_for_test(0, 0, Ruby)
  place_gem_for_test(0, 1, Emerald)
  place_gem_for_test(1, 1, Ruby)
  place_gem_for_test(2, 1, Ruby)
  let a = Cell::{ row: 0, col: 0 }
  let b = Cell::{ row: 0, col: 1 }
  begin_swap_forward_phase(a, b)
  complete_resolution_phase()
  assert_true(game_state.resolution_phase is Clear)
  ignore(resolve_until_input_ready(16))
  assert_true(game_state.resolution_phase is InputReady)
  inspect(game_state.moves_left, content="31")
  inspect(game_state.score >= 30, content="true")
  inspect(
    gem_lookup_count() == non_empty_board_count_for_test(),
    content="true",
  )
  inspect(
    alive_gem_entity_count() == non_empty_board_count_for_test(),
    content="true",
  )
}

///|
test "cascade check can trigger a second clear round" {
  reset_logic_state_for_test()
  place_gem_for_test(0, 0, Ruby)
  place_gem_for_test(1, 0, Ruby)
  place_gem_for_test(2, 0, Emerald)
  place_gem_for_test(3, 0, Emerald)
  place_gem_for_test(4, 0, Emerald)
  place_gem_for_test(5, 0, Ruby)
  place_gem_for_test(6, 0, Amber)
  place_gem_for_test(7, 0, Sapphire)
  begin_clear_phase([
    Cell::{ row: 2, col: 0 },
    Cell::{ row: 3, col: 0 },
    Cell::{ row: 4, col: 0 },
  ])
  assert_true(game_state.resolution_phase is Clear)
  complete_resolution_phase()
  assert_true(game_state.resolution_phase is Fall)
  complete_resolution_phase()
  assert_true(game_state.resolution_phase is Refill)
  complete_resolution_phase()
  assert_true(game_state.resolution_phase is CascadeCheck)
  complete_resolution_phase()
  assert_true(game_state.resolution_phase is Clear)
  inspect(game_state.cascade_depth >= 1, content="true")
}

///|
test "input is gated during animation phases" {
  reset_logic_state_for_test()
  inspect(can_accept_input(), content="true")
  game_state.resolution_phase = SwapForward
  inspect(can_accept_input(), content="false")
  game_state.resolution_phase = Clear
  inspect(can_accept_input(), content="false")
  game_state.resolution_phase = InputReady
  game_state.phase = GameOver
  inspect(can_accept_input(), content="false")
}

///|
test "steady visuals keep entity count aligned with non-empty cells" {
  reset_logic_state_for_test()
  place_gem_for_test(0, 0, Ruby)
  place_gem_for_test(2, 3, Emerald)
  place_gem_for_test(7, 7, Sapphire)
  inspect(non_empty_board_count_for_test(), content="3")
  inspect(gem_lookup_count(), content="3")
  inspect(alive_gem_entity_count(), content="3")
}

///|
test "drag swap triggers immediately when pointer crosses adjacent cell" {
  reset_logic_state_for_test()
  place_gem_for_test(0, 0, Ruby)
  place_gem_for_test(0, 1, Emerald)
  game_state.first_pick = Some(Cell::{ row: 0, col: 0 })
  game_state.drag_origin = Some(Cell::{ row: 0, col: 0 })
  game_state.drag_pointer_down = true
  game_state.drag_swapped = false
  inspect(try_drag_swap_to_cell(Some(Cell::{ row: 0, col: 1 })), content="true")
  assert_true(game_state.resolution_phase is SwapForward)
  inspect(game_state.first_pick, content="None")
  inspect(game_state.drag_swapped, content="true")
}

///|
test "drag swap only fires once per hold and ignores non-adjacent targets" {
  reset_logic_state_for_test()
  place_gem_for_test(0, 0, Ruby)
  place_gem_for_test(0, 1, Emerald)
  game_state.drag_origin = Some(Cell::{ row: 0, col: 0 })
  game_state.drag_pointer_down = true
  game_state.drag_swapped = false
  inspect(
    try_drag_swap_to_cell(Some(Cell::{ row: 0, col: 2 })),
    content="false",
  )
  inspect(game_state.resolution_phase is InputReady, content="true")
  inspect(try_drag_swap_to_cell(Some(Cell::{ row: 0, col: 1 })), content="true")
  inspect(
    try_drag_swap_to_cell(Some(Cell::{ row: 1, col: 1 })),
    content="false",
  )
}

///|
test "click flow keeps two-click behavior and adjacency rules" {
  reset_logic_state_for_test()
  place_gem_for_test(0, 0, Ruby)
  place_gem_for_test(0, 1, Emerald)
  place_gem_for_test(3, 3, Sapphire)
  place_gem_for_test(3, 4, Amber)
  inspect(handle_click_cell(Cell::{ row: 0, col: 0 }), content="false")
  inspect(game_state.first_pick, content="Some({row: 0, col: 0})")
  inspect(handle_click_cell(Cell::{ row: 3, col: 3 }), content="false")
  inspect(game_state.first_pick, content="Some({row: 3, col: 3})")
  inspect(handle_click_cell(Cell::{ row: 3, col: 4 }), content="true")
  assert_true(game_state.resolution_phase is SwapForward)
  inspect(game_state.first_pick, content="None")
}

///|
test "drag and click swaps are disabled outside input-ready phase" {
  reset_logic_state_for_test()
  place_gem_for_test(0, 0, Ruby)
  place_gem_for_test(0, 1, Emerald)
  game_state.drag_origin = Some(Cell::{ row: 0, col: 0 })
  game_state.drag_pointer_down = true
  game_state.drag_swapped = false
  game_state.resolution_phase = Clear
  inspect(
    try_drag_swap_to_cell(Some(Cell::{ row: 0, col: 1 })),
    content="false",
  )
  inspect(game_state.resolution_phase is Clear, content="true")
}

///|
test "selected frame visibility follows first_pick and input gate" {
  reset_logic_state_for_test()
  inspect(should_show_selected_frame(), content="false")
  game_state.first_pick = Some(Cell::{ row: 0, col: 0 })
  inspect(should_show_selected_frame(), content="true")
  game_state.resolution_phase = Fall
  inspect(should_show_selected_frame(), content="false")
  game_state.resolution_phase = InputReady
  game_state.phase = GameOver
  inspect(should_show_selected_frame(), content="false")
}

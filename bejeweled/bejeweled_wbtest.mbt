///|
test "find_matches detects horizontal and vertical runs" {
  board.clear()
  for _ in 0..<(BOARD_ROWS * BOARD_COLS) {
    board.push(None)
  }
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
  board.clear()
  for _ in 0..<(BOARD_ROWS * BOARD_COLS) {
    board.push(None)
  }
  board_set(0, 0, Some(Emerald))
  board_set(0, 1, Some(Sapphire))
  ignore(
    try_swap_and_find_match(Cell::{ row: 0, col: 0 }, Cell::{ row: 0, col: 1 }),
  )
  inspect(board_get(0, 0), content="Some(Emerald)")
  inspect(board_get(0, 1), content="Some(Sapphire)")
  board_set(1, 1, Some(Emerald))
  board_set(2, 1, Some(Emerald))
  inspect(
    try_swap_and_find_match(Cell::{ row: 0, col: 0 }, Cell::{ row: 0, col: 1 }),
    content="true",
  )
  inspect(board_get(0, 0), content="Some(Sapphire)")
  inspect(board_get(0, 1), content="Some(Emerald)")
}

///|
test "collapse_board fills empty spaces" {
  board.clear()
  for _ in 0..<(BOARD_ROWS * BOARD_COLS) {
    board.push(None)
  }
  board_set(7, 3, None)
  board_set(6, 3, None)
  board_set(5, 3, Some(Ruby))
  ignore(collapse_board())
  inspect(board_get(7, 3) is Some(_), content="true")
  inspect(board_get(6, 3) is Some(_), content="true")
}

///|
test "fill_board_without_initial_matches creates a match-free board" {
  board.clear()
  for _ in 0..<(BOARD_ROWS * BOARD_COLS) {
    board.push(None)
  }
  fill_board_without_initial_matches()
  inspect(find_matches().is_empty(), content="true")
}

///|
test "selected hint text reflects the picked gem" {
  board.clear()
  for _ in 0..<(BOARD_ROWS * BOARD_COLS) {
    board.push(None)
  }
  board_set(0, 0, Some(Ruby))
  game_state.first_pick = Some(Cell::{ row: 0, col: 0 })
  inspect(
    selected_hint_text(),
    content="Selected Ruby at 1,1. Pick an adjacent gem.",
  )
}

///|
fn board_get(row : Int, col : Int) -> GemKind? {
  if !in_bounds(row, col) {
    return None
  }
  board[board_index(row, col)]
}

///|
fn board_set(row : Int, col : Int, value : GemKind?) -> Unit {
  if in_bounds(row, col) {
    board[board_index(row, col)] = value
  }
}

///|
fn random_kind() -> GemKind {
  match rand.int(limit=GEM_COUNT) {
    0 => Ruby
    1 => Emerald
    2 => Sapphire
    3 => Amber
    4 => Amethyst
    _ => Pearl
  }
}

///|
fn fill_board_without_initial_matches() -> Unit {
  for row in 0..<BOARD_ROWS {
    for col in 0..<BOARD_COLS {
      let mut candidate = random_kind()
      while makes_match_at(row, col, candidate) {
        candidate = random_kind()
      }
      board_set(row, col, Some(candidate))
    }
  }
}

///|
fn makes_match_at(row : Int, col : Int, kind : GemKind) -> Bool {
  let left1 = if col >= 1 { board_get(row, col - 1) } else { None }
  let left2 = if col >= 2 { board_get(row, col - 2) } else { None }
  if left1 == Some(kind) && left2 == Some(kind) {
    return true
  }
  let up1 = if row >= 1 { board_get(row - 1, col) } else { None }
  let up2 = if row >= 2 { board_get(row - 2, col) } else { None }
  up1 == Some(kind) && up2 == Some(kind)
}

///|
fn find_matches() -> Array[Cell] {
  let matched : Map[Cell, Bool] = Map::new()
  for row in 0..<BOARD_ROWS {
    let mut run_kind : GemKind? = None
    let mut run_start = 0
    let mut run_len = 0
    for col in 0..<BOARD_COLS {
      let current = board_get(row, col)
      if current == run_kind && current is Some(_) {
        run_len += 1
      } else {
        if run_len >= 3 && run_kind is Some(_) {
          for k in run_start..<(run_start + run_len) {
            matched.set(Cell::{ row, col: k }, true)
          }
        }
        run_kind = current
        run_start = col
        run_len = if current is Some(_) { 1 } else { 0 }
      }
    }
    if run_len >= 3 && run_kind is Some(_) {
      for k in run_start..<(run_start + run_len) {
        matched.set(Cell::{ row, col: k }, true)
      }
    }
  }

  for col in 0..<BOARD_COLS {
    let mut run_kind : GemKind? = None
    let mut run_start = 0
    let mut run_len = 0
    for row in 0..<BOARD_ROWS {
      let current = board_get(row, col)
      if current == run_kind && current is Some(_) {
        run_len += 1
      } else {
        if run_len >= 3 && run_kind is Some(_) {
          for k in run_start..<(run_start + run_len) {
            matched.set(Cell::{ row: k, col }, true)
          }
        }
        run_kind = current
        run_start = row
        run_len = if current is Some(_) { 1 } else { 0 }
      }
    }
    if run_len >= 3 && run_kind is Some(_) {
      for k in run_start..<(run_start + run_len) {
        matched.set(Cell::{ row: k, col }, true)
      }
    }
  }

  let result : Array[Cell] = []
  for cell, _ in matched {
    result.push(cell)
  }
  result
}

///|
fn is_adjacent(a : Cell, b : Cell) -> Bool {
  let col_delta = if a.col >= b.col { a.col - b.col } else { b.col - a.col }
  let row_delta = if a.row >= b.row { a.row - b.row } else { b.row - a.row }
  (a.row == b.row && col_delta == 1) || (a.col == b.col && row_delta == 1)
}

///|
fn swap_cells(a : Cell, b : Cell) -> Unit {
  let left = board_get(a.row, a.col)
  let right = board_get(b.row, b.col)
  board_set(a.row, a.col, right)
  board_set(b.row, b.col, left)
}

///|
fn score_for_matches(count : Int) -> Int {
  if count <= 0 {
    0
  } else {
    count * 10
  }
}

///|
fn center_cell_of_group(group : Array[Cell]) -> Cell {
  let group_set : Map[Cell, Bool] = Map::new()
  for cell in group {
    group_set.set(cell, true)
  }
  let mut best = group[0]
  let mut best_total_distance = 0
  let mut best_degree = -1
  for i in 0..<group.length() {
    let cell = group[i]
    let mut total_distance = 0
    for other in group {
      let row_delta = if cell.row >= other.row {
        cell.row - other.row
      } else {
        other.row - cell.row
      }
      let col_delta = if cell.col >= other.col {
        cell.col - other.col
      } else {
        other.col - cell.col
      }
      total_distance += row_delta + col_delta
    }
    let mut degree = 0
    let neighbors : Array[Cell] = [
      Cell::{ row: cell.row - 1, col: cell.col },
      Cell::{ row: cell.row + 1, col: cell.col },
      Cell::{ row: cell.row, col: cell.col - 1 },
      Cell::{ row: cell.row, col: cell.col + 1 },
    ]
    for next in neighbors {
      if group_set.get(next) is Some(_) {
        degree += 1
      }
    }
    if i == 0 ||
      total_distance < best_total_distance ||
      (
        total_distance == best_total_distance &&
        (
          degree > best_degree ||
          (
            degree == best_degree &&
            (
              cell.row < best.row ||
              (cell.row == best.row && cell.col < best.col)
            )
          )
        )
      ) {
      best = cell
      best_total_distance = total_distance
      best_degree = degree
    }
  }
  best
}

///|
fn plan_special_spawns(
  matches : Array[Cell],
) -> (Array[Cell], Array[SpecialSpawn]) {
  let matched_set : Map[Cell, Bool] = Map::new()
  let clear_set : Map[Cell, Bool] = Map::new()
  let visited : Map[Cell, Bool] = Map::new()
  for cell in matches {
    matched_set.set(cell, true)
    clear_set.set(cell, true)
  }
  let spawns : Array[SpecialSpawn] = []
  for start in matches {
    if visited.get(start) is Some(_) {
      continue
    }
    let kind = match board_get(start.row, start.col) {
      Some(kind) => kind
      None => continue
    }
    let queue : Array[Cell] = [start]
    let group : Array[Cell] = []
    visited.set(start, true)
    let mut head = 0
    while head < queue.length() {
      let current = queue[head]
      head += 1
      group.push(current)
      let neighbors : Array[Cell] = [
        Cell::{ row: current.row - 1, col: current.col },
        Cell::{ row: current.row + 1, col: current.col },
        Cell::{ row: current.row, col: current.col - 1 },
        Cell::{ row: current.row, col: current.col + 1 },
      ]
      for next in neighbors {
        if !in_bounds(next.row, next.col) {
          continue
        }
        if matched_set.get(next) is None {
          continue
        }
        if visited.get(next) is Some(_) {
          continue
        }
        if board_get(next.row, next.col) == Some(kind) {
          visited.set(next, true)
          queue.push(next)
        }
      }
    }
    if group.length() >= 5 {
      let center_cell = center_cell_of_group(group)
      clear_set.remove(center_cell)
      spawns.push({ cell: center_cell, kind })
    }
  }
  let clear_cells : Array[Cell] = []
  for cell, _ in clear_set {
    clear_cells.push(cell)
  }
  (clear_cells, spawns)
}

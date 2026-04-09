///|
priv enum FlashEffect {
  ConvertToSapphire
  Blast3x3
  RefreshTimeFreeze
  BlastRow
  TripleRoundScore
  RefreshScoreBonus
}

///|
fn flash_effect_for_kind(kind : GemKind) -> FlashEffect {
  match kind {
    Sapphire => ConvertToSapphire
    Ruby => Blast3x3
    Emerald => RefreshTimeFreeze
    Amber => BlastRow
    Pearl => TripleRoundScore
    Amethyst => RefreshScoreBonus
  }
}

///|
fn add_clear_cell_if_filled(
  clear_set : Map[Cell, Bool],
  row : Int,
  col : Int,
) -> Unit {
  if !in_bounds(row, col) {
    return
  }
  if board_get(row, col) is Some(_) {
    clear_set.set(Cell::{ row, col }, true)
  }
}

///|
fn choose_sapphire_transform_kind(clear_set : Map[Cell, Bool]) -> GemKind? {
  let seen : Map[GemKind, Bool] = Map::new()
  let candidates : Array[GemKind] = []
  for row in 0..<BOARD_ROWS {
    for col in 0..<BOARD_COLS {
      let cell = Cell::{ row, col }
      if clear_set.get(cell) is Some(_) {
        continue
      }
      match board_get(row, col) {
        Some(kind) => {
          if kind == Sapphire || seen.get(kind) is Some(_) {
            continue
          }
          seen.set(kind, true)
          candidates.push(kind)
        }
        None => ()
      }
    }
  }
  if candidates.is_empty() {
    None
  } else {
    Some(candidates[rand.int(limit=candidates.length())])
  }
}

///|
fn convert_kind_to_sapphire(
  kind : GemKind,
  clear_set : Map[Cell, Bool],
) -> Unit {
  for row in 0..<BOARD_ROWS {
    for col in 0..<BOARD_COLS {
      let cell = Cell::{ row, col }
      if clear_set.get(cell) is Some(_) {
        continue
      }
      if board_get(row, col) == Some(kind) {
        board_set(row, col, Some(Sapphire))
        if gem_lookup.get(cell) is Some(gem) {
          gem_lookup.set(cell, { ..gem, kind: Sapphire })
        }
      }
    }
  }
}

///|
fn apply_single_flash_effect(
  effect : FlashEffect,
  cell : Cell,
  clear_set : Map[Cell, Bool],
  round_score_multiplier : Int,
) -> Int {
  match effect {
    ConvertToSapphire =>
      if choose_sapphire_transform_kind(clear_set) is Some(target_kind) {
        convert_kind_to_sapphire(target_kind, clear_set)
      }
    Blast3x3 =>
      for row in (cell.row - 1)..<(cell.row + 2) {
        for col in (cell.col - 1)..<(cell.col + 2) {
          add_clear_cell_if_filled(clear_set, row, col)
        }
      }
    RefreshTimeFreeze =>
      game_state.time_freeze_remaining = FLASH_EMERALD_FREEZE_SECONDS
    BlastRow =>
      for col in 0..<BOARD_COLS {
        add_clear_cell_if_filled(clear_set, cell.row, col)
      }
    TripleRoundScore =>
      if round_score_multiplier < FLASH_PEARL_SCORE_MULTIPLIER {
        return FLASH_PEARL_SCORE_MULTIPLIER
      }
    RefreshScoreBonus =>
      game_state.score_bonus_remaining = FLASH_AMETHYST_SCORE_SECONDS
  }
  round_score_multiplier
}

///|
fn apply_flash_effects(clear_set : Map[Cell, Bool]) -> Int {
  let processed_flash : Map[Cell, Bool] = Map::new()
  let mut round_score_multiplier = 1
  let mut loop_count = 0
  while loop_count < BOARD_ROWS * BOARD_COLS * 4 {
    loop_count += 1
    let mut next_flash : (Cell, GemKind)? = None
    for cell, _ in clear_set {
      if processed_flash.get(cell) is Some(_) {
        continue
      }
      if gem_lookup.get(cell) is Some(gem) {
        if gem.flash {
          next_flash = Some((cell, gem.kind))
          break
        }
      }
    }
    match next_flash {
      None => break
      Some((cell, kind)) => {
        processed_flash.set(cell, true)
        round_score_multiplier = apply_single_flash_effect(
          flash_effect_for_kind(kind),
          cell,
          clear_set,
          round_score_multiplier,
        )
      }
    }
  }
  round_score_multiplier
}

///|
fn effect_time_scale_for_tick(delta : Double) -> Double {
  let freeze_active = game_state.time_freeze_remaining > 0.0
  if game_state.time_freeze_remaining > 0.0 {
    game_state.time_freeze_remaining -= delta
    if game_state.time_freeze_remaining < 0.0 {
      game_state.time_freeze_remaining = 0.0
    }
  }
  if game_state.score_bonus_remaining > 0.0 {
    game_state.score_bonus_remaining -= delta
    if game_state.score_bonus_remaining < 0.0 {
      game_state.score_bonus_remaining = 0.0
    }
  }
  if freeze_active {
    FLASH_TIME_FREEZE_SCALE
  } else {
    1.0
  }
}

///|
fn effect_hud_suffix() -> String {
  let freeze_text = if game_state.time_freeze_remaining > 0.0 {
    let shown = @cmath.ceil(game_state.time_freeze_remaining).to_int()
    " FREEZE \{shown}s"
  } else {
    ""
  }
  let bonus_text = if game_state.score_bonus_remaining > 0.0 {
    let shown = @cmath.ceil(game_state.score_bonus_remaining).to_int()
    " X2 \{shown}s"
  } else {
    ""
  }
  "\{freeze_text}\{bonus_text}"
}

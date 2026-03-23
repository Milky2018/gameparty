///|
let bombman_font_registered : Ref[Bool] = { val: false }

///|
fn register_bombman_font_once() -> Unit {
  if bombman_font_registered.val {
    return
  }
  ignore(@asset.load_font(BOMBMAN_FONT_PATH, family=BOMBMAN_FONT_FAMILY))
  bombman_font_registered.val = true
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn ensure_tile_entities() -> Unit {
  let needed = GRID_WIDTH * GRID_HEIGHT
  while tile_entities.length() < needed {
    tile_entities.push(@entity.Entity::new())
  }
}

///|
fn hide_entity(entity : @entity.Entity) -> Unit {
  if @sprite.sprites().get(entity) is Some(sprite) {
    sprite.visible = false
  }
}

///|
fn set_text_entity(
  entity : @entity.Entity,
  text : String,
  position : @math.Vec2D,
  font : String,
  color : String,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  @sprite.sprites().set(
    entity,
    @sprite.Sprite::from_text(
      @sprite.Text::new(text, color~, font~, baseline=Top, align=Left),
      zindex,
    ),
  )
  @transform.positions().set(entity, position)
}

///|
fn set_text_entity_center(
  entity : @entity.Entity,
  text : String,
  position : @math.Vec2D,
  font : String,
  color : String,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  @sprite.sprites().set(
    entity,
    @sprite.Sprite::from_text(
      @sprite.Text::new(text, color~, font~, baseline=Top, align=Center),
      zindex,
    ),
  )
  @transform.positions().set(entity, position)
}

///|
fn set_rect_entity(
  entity : @entity.Entity,
  position : @math.Vec2D,
  size : @math.Vec2D,
  color : String,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  @sprite.sprites().set(
    entity,
    @sprite.Sprite::from_color_rect(@sprite.ColorRect::new(size, color), zindex),
  )
  @transform.positions().set(entity, position)
}

///|
fn set_circle_entity(
  entity : @entity.Entity,
  center : @math.Vec2D,
  radius : Double,
  color : String,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  @sprite.sprites().set(
    entity,
    @sprite.Sprite::from_color_circle(
      @sprite.ColorCircle::new(radius, color, stroke_color="rgba(0,0,0,0.18)"),
      zindex,
    ),
  )
  @transform.positions().set(entity, center_to_circle_position(center, radius))
}

///|
fn tile_at(x : Int, y : Int) -> TileKind {
  if !cell_in_bounds(x, y) {
    return HardWall
  }
  tiles[cell_index(x, y)]
}

///|
fn set_tile(x : Int, y : Int, tile : TileKind) -> Unit {
  if cell_in_bounds(x, y) {
    tiles[cell_index(x, y)] = tile
  }
}

///|
fn has_bomb_at(x : Int, y : Int) -> Bool {
  bombs.any(fn(bomb) { bomb.cell_x == x && bomb.cell_y == y })
}

///|
fn has_item_at(x : Int, y : Int) -> Bool {
  items.any(fn(item) { item.cell_x == x && item.cell_y == y })
}

///|
fn tile_is_solid(x : Int, y : Int) -> Bool {
  match tile_at(x, y) {
    Empty => false
    HardWall | SoftWall => true
  }
}

///|
fn reset_direction_input_state() -> Unit {
  for input_state in direction_input_state {
    input_state.sequence = 0
    input_state.up = 0
    input_state.down = 0
    input_state.left = 0
    input_state.right = 0
  }
  p2_bomb_test_override.val = false
  forced_drop_rolls.clear()
  forced_drop_kinds.clear()
}

///|
fn active_enemy_count() -> Int {
  enemies.fold(init=0, fn(acc, enemy) {
    if enemy.alive {
      acc + 1
    } else {
      acc
    }
  })
}

///|
fn enemy_can_enter_cell(
  from_x : Int,
  from_y : Int,
  direction : Direction,
) -> Bool {
  let (dx, dy) = direction_delta(direction)
  let next_x = from_x + dx
  let next_y = from_y + dy
  cell_in_bounds(next_x, next_y) &&
  tile_at(next_x, next_y) == Empty &&
  !has_bomb_at(next_x, next_y)
}

///|
fn tile_kind_for_level_code(code : Int) -> TileKind {
  match code {
    LEVEL_EMPTY | LEVEL_P1_SPAWN | LEVEL_P2_SPAWN | LEVEL_ENEMY_SPAWN => Empty
    LEVEL_HARD_WALL => HardWall
    LEVEL_SOFT_WALL => SoftWall
    _ => abort("Unknown bombman level tile code: \{code}")
  }
}

///|
fn clear_tile_grid() -> Unit {
  tiles.clear()
  for _ in 0..<(GRID_WIDTH * GRID_HEIGHT) {
    tiles.push(Empty)
  }
}

///|
fn reset_player_slot(
  index : Int,
  start_center : @math.Vec2D,
  active : Bool,
) -> Unit {
  let id = if index == 0 { P1 } else { P2 }
  players[index] = {
    id,
    entity: players[index].entity,
    active,
    center: start_center,
    direction: None,
    desired_direction: None,
    speed: PLAYER_SPEED,
    radius: PLAYER_RADIUS,
    alive: true,
    active_bombs: 0,
    max_bombs: PLAYER_START_BOMBS,
    blast_radius: PLAYER_BLAST_RADIUS,
  }
}

///|
fn clear_dynamic_entities() -> Unit {
  for bomb in bombs {
    hide_entity(bomb.entity)
  }
  for flame in flames {
    hide_entity(flame.entity)
  }
  for item in items {
    hide_entity(item.entity)
  }
  for enemy in enemies {
    hide_entity(enemy.entity)
  }
  for player in players {
    hide_entity(player.entity)
  }
  bombs.clear()
  flames.clear()
  items.clear()
  enemies.clear()
}

///|
fn deactivate_all_players() -> Unit {
  for index in 0..<players.length() {
    let current = players[index]
    players[index] = {
      ..current,
      active: false,
      alive: false,
      direction: None,
      desired_direction: None,
      active_bombs: 0,
    }
  }
}

///|
fn load_level(level_index : Int, mode : GameMode) -> Unit {
  if level_index < 0 || level_index >= levels.length() {
    abort("Bombman level index out of bounds: \{level_index}")
  }
  let level = levels[level_index]
  if level.length() != GRID_HEIGHT {
    abort(
      "Bombman level \{level_index + 1} has \{level.length()} rows; expected \{GRID_HEIGHT}",
    )
  }
  clear_tile_grid()
  enemies.clear()
  let mut p1_spawn : @math.Vec2D? = None
  let mut p2_spawn : @math.Vec2D? = None
  for y in 0..<GRID_HEIGHT {
    let row = level[y]
    if row.length() != GRID_WIDTH {
      abort(
        "Bombman level \{level_index + 1} row \{y} has \{row.length()} columns; expected \{GRID_WIDTH}",
      )
    }
    for x in 0..<GRID_WIDTH {
      let code = row[x]
      set_tile(x, y, tile_kind_for_level_code(code))
      match code {
        LEVEL_P1_SPAWN => {
          if p1_spawn is Some(_) {
            abort("Bombman level \{level_index + 1} has multiple P1 spawns")
          }
          p1_spawn = Some(cell_center(x, y))
        }
        LEVEL_P2_SPAWN => {
          if p2_spawn is Some(_) {
            abort("Bombman level \{level_index + 1} has multiple P2 spawns")
          }
          p2_spawn = Some(cell_center(x, y))
        }
        LEVEL_ENEMY_SPAWN =>
          if mode != Versus {
            enemies.push({
              entity: @entity.Entity::new(),
              cell_x: x,
              cell_y: y,
              center: cell_center(x, y),
              direction: default_enemy_direction(),
              desired_direction: default_enemy_direction(),
              speed: ENEMY_SPEED,
              radius: ENEMY_RADIUS,
              alive: true,
            })
          }
        _ => ()
      }
    }
  }
  match p1_spawn {
    Some(center) => reset_player_slot(0, center, true)
    None => abort("Bombman level \{level_index + 1} is missing a P1 spawn")
  }
  match p2_spawn {
    Some(center) => reset_player_slot(1, center, mode != SinglePlayer)
    None => abort("Bombman level \{level_index + 1} is missing a P2 spawn")
  }
  for enemy in enemies {
    if tile_at(enemy.cell_x, enemy.cell_y) != Empty {
      abort(
        "Bombman level \{level_index + 1} spawns an enemy on a solid tile at (\{enemy.cell_x}, \{enemy.cell_y})",
      )
    }
  }
}

///|
fn start_round(mode : GameMode) -> Unit {
  ensure_tile_entities()
  reset_direction_input_state()
  clear_dynamic_entities()
  current_mode.val = mode
  round_outcome.val = LevelClear
  load_level(current_level.val, mode)
  phase.val = Playing
}

///|
fn return_to_menu() -> Unit {
  reset_direction_input_state()
  clear_dynamic_entities()
  clear_tile_grid()
  deactivate_all_players()
  phase.val = MainMenu
  round_outcome.val = LevelClear
  menu_selection.val = match current_mode.val {
    SinglePlayer => OnePlayer
    Coop => TwoPlayersA
    Versus => TwoPlayersB
  }
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  register_bombman_font_once()
  ensure_entity_alive(background_entity)
  ensure_entity_alive(title_entity)
  ensure_entity_alive(hud_entity)
  ensure_entity_alive(status_entity)
  ensure_entity_alive(hint_entity)
  for entity in menu_entities {
    ensure_entity_alive(entity)
  }
  for player in players {
    ensure_entity_alive(player.entity)
  }
  ensure_tile_entities()
  clear_tile_grid()
  deactivate_all_players()
  phase.val = MainMenu
  exit_request_count.val = 0
  render_sync_system(@ecs.require_current_world())
}

///|
fn collect_explosion_cells(
  origin_x : Int,
  origin_y : Int,
  radius : Int,
) -> Array[(Int, Int)] {
  let cells : Array[(Int, Int)] = [(origin_x, origin_y)]
  for direction in [Up, Down, Left, Right] {
    let (dx, dy) = direction_delta(direction)
    for step in 1..<=radius {
      let x = origin_x + dx * step
      let y = origin_y + dy * step
      let tile = tile_at(x, y)
      if tile == HardWall {
        break
      }
      cells.push((x, y))
      if tile == SoftWall {
        break
      }
    }
  }
  cells
}

///|
fn spawn_flame(x : Int, y : Int) -> Unit {
  if flames.any(fn(flame) { flame.cell_x == x && flame.cell_y == y }) {
    return
  }
  flames.push({
    entity: @entity.Entity::new(),
    cell_x: x,
    cell_y: y,
    timer: FLAME_DURATION,
  })
}

///|
fn spawn_item(x : Int, y : Int, kind : ItemKind) -> Unit {
  if has_item_at(x, y) {
    return
  }
  items.push({ entity: @entity.Entity::new(), cell_x: x, cell_y: y, kind })
}

///|
fn next_drop_roll() -> Double {
  match forced_drop_rolls.pop() {
    Some(value) => value
    None => {
      let seed = drop_rng_state.val
      let next_seed = seed * 48271 % 2147483647
      drop_rng_state.val = if next_seed <= 0 { 1 } else { next_seed }
      drop_rng_state.val.to_double() / 2147483647.0
    }
  }
}

///|
fn next_drop_kind(candidates : Array[ItemKind]) -> ItemKind? {
  if candidates.is_empty() {
    return None
  }
  match forced_drop_kinds.pop() {
    Some(kind) =>
      if candidates.any(fn(candidate) { candidate == kind }) {
        Some(kind)
      } else {
        None
      }
    None => {
      let roll = next_drop_roll()
      let index = clamp_int(
        @cmath.floor(roll * candidates.length().to_double()).to_int(),
        0,
        candidates.length() - 1,
      )
      Some(candidates[index])
    }
  }
}

///|
fn maybe_spawn_random_item(x : Int, y : Int, chance : Double) -> Unit {
  if has_item_at(x, y) {
    return
  }
  let candidates = available_drop_kinds()
  if candidates.is_empty() {
    return
  }
  if next_drop_roll() >= chance {
    return
  }
  match next_drop_kind(candidates) {
    Some(kind) => spawn_item(x, y, kind)
    None => ()
  }
}

///|
fn explode_bomb_at(index : Int) -> Unit {
  let bomb = bombs[index]
  hide_entity(bomb.entity)
  ignore(bombs.remove(index))
  let owner_index = player_index(bomb.owner)
  let owner = players[owner_index]
  if owner.active_bombs > 0 {
    owner.active_bombs -= 1
  }
  let cells = collect_explosion_cells(bomb.cell_x, bomb.cell_y, bomb.radius)
  for cell in cells {
    let x = cell.0
    let y = cell.1
    if tile_at(x, y) == SoftWall {
      set_tile(x, y, Empty)
      maybe_spawn_random_item(x, y, SOFT_WALL_ITEM_DROP_CHANCE)
    }
    for chained in bombs {
      if chained.cell_x == x && chained.cell_y == y {
        chained.timer = 0.0
      }
    }
    spawn_flame(x, y)
  }
}

///|
fn place_bomb_for_player(index : Int) -> Unit {
  let player = players[index]
  if !player.active || !player.alive || player.active_bombs >= player.max_bombs {
    return
  }
  let (bomb_x, bomb_y) = world_to_cell(player.center)
  if tile_at(bomb_x, bomb_y) != Empty || has_bomb_at(bomb_x, bomb_y) {
    return
  }
  bombs.push({
    entity: @entity.Entity::new(),
    cell_x: bomb_x,
    cell_y: bomb_y,
    timer: BOMB_FUSE_TIME,
    radius: player.blast_radius,
    owner: player.id,
    passable_for_owner: true,
  })
  player.active_bombs += 1
}

///|
fn round_outcome_text() -> String {
  match round_outcome.val {
    LevelClear => "LEVEL CLEAR"
    Defeat => "DEFEAT"
    P1Win => "P1 WINS"
    P2Win => "P2 WINS"
    Draw => "DRAW"
  }
}

///|
fn phase_status_text() -> String {
  match phase.val {
    MainMenu => "LEVEL \{current_level_number()} / \{levels.length()}"
    Playing => {
      let base = "MODE: \{mode_label(current_mode.val)}   LEVEL: \{current_level_number()}/\{levels.length()}"
      let p1 = players[0]
      let mut suffix = if p1.active {
        "   P1 BOMBS: \{p1.max_bombs - p1.active_bombs}/\{p1.max_bombs}"
      } else {
        ""
      }
      let p2 = players[1]
      if p2.active {
        suffix = suffix +
          "   P2 BOMBS: \{p2.max_bombs - p2.active_bombs}/\{p2.max_bombs}"
      }
      if current_mode.val != Versus {
        suffix = suffix + "   ENEMIES: \{active_enemy_count()}"
      }
      base + suffix
    }
    RoundOver => round_outcome_text()
  }
}

///|
fn hint_text() -> String {
  match phase.val {
    MainMenu =>
      "W/S or Up/Down: Mode   A/D or Left/Right: Level   Enter/Space: Start   Esc: Exit"
    Playing =>
      match current_mode.val {
        SinglePlayer =>
          "Move: WASD / Arrows   Bomb: Space   R: Restart   Esc: Menu"
        Coop | Versus => "P1: WASD + G   P2: IJKL + '   R: Restart   Esc: Menu"
      }
    RoundOver =>
      match current_mode.val {
        Versus => "Enter/Space: Rematch   R: Restart   Esc: Menu"
        SinglePlayer | Coop => "Enter/Space: Continue   R: Restart   Esc: Menu"
      }
  }
}

///|
fn status_text() -> String {
  match phase.val {
    MainMenu => "2 Players A = co-op, 2 Players B = versus with no enemies."
    Playing =>
      match current_mode.val {
        SinglePlayer =>
          "Soft walls break. Hard walls block. Flames travel in a cross."
        Coop =>
          "Friendly fire is enabled. Clear all enemies with at least one player alive."
        Versus => "Friendly fire is enabled. Last survivor wins."
      }
    RoundOver =>
      match round_outcome.val {
        LevelClear =>
          if current_mode.val == Versus {
            "Press Enter or Space to restart the arena."
          } else {
            "Press Enter or Space to continue."
          }
        Defeat => "Both active players were eliminated."
        P1Win => "P1 survived the round."
        P2Win => "P2 survived the round."
        Draw => "Both players were eliminated in the same round."
      }
  }
}

///|
fn sync_tile_visuals() -> Unit {
  let size = floor_tile_size()
  for y in 0..<GRID_HEIGHT {
    for x in 0..<GRID_WIDTH {
      let entity = tile_entities[cell_index(x, y)]
      let color = match tile_at(x, y) {
        Empty => FLOOR_COLOR
        HardWall => HARD_WALL_COLOR
        SoftWall => SOFT_WALL_COLOR
      }
      set_rect_entity(entity, floor_tile_position(x, y), size, color, 20)
    }
  }
}

///|
fn hide_tile_visuals() -> Unit {
  for entity in tile_entities {
    hide_entity(entity)
  }
}

///|
fn sync_bomb_visuals() -> Unit {
  for bomb in bombs {
    set_circle_entity(
      bomb.entity,
      cell_center(bomb.cell_x, bomb.cell_y),
      BOMB_RADIUS,
      BOMB_COLOR,
      60,
    )
  }
}

///|
fn sync_flame_visuals() -> Unit {
  for flame in flames {
    let pos = cell_top_left(flame.cell_x, flame.cell_y) + @math.Vec2D(6.0, 6.0)
    set_rect_entity(
      flame.entity,
      pos,
      @math.Vec2D(CELL_SIZE - 12.0, CELL_SIZE - 12.0),
      FLAME_COLOR,
      70,
    )
  }
}

///|
fn sync_item_visuals() -> Unit {
  for item in items {
    let center = cell_center(item.cell_x, item.cell_y)
    set_text_entity_center(
      item.entity,
      item_label(item.kind),
      @math.Vec2D(center[X], center[Y] - 10.0),
      "18px \{BOMBMAN_FONT_FAMILY}",
      item_color(item.kind),
      63,
    )
  }
}

///|
fn sync_enemy_visuals() -> Unit {
  for index, enemy in enemies {
    if enemy.alive {
      let color = if index % 2 == 0 {
        "rgb(235, 78, 99)"
      } else {
        "rgb(198, 94, 255)"
      }
      set_circle_entity(enemy.entity, enemy.center, enemy.radius, color, 65)
    } else {
      hide_entity(enemy.entity)
    }
  }
}

///|
fn sync_player_visuals() -> Unit {
  for player in players {
    if player.active {
      set_circle_entity(
        player.entity,
        player.center,
        player.radius,
        player_color(player.id, player.alive),
        66,
      )
    } else {
      hide_entity(player.entity)
    }
  }
}

///|
fn hide_gameplay_visuals() -> Unit {
  hide_tile_visuals()
  for bomb in bombs {
    hide_entity(bomb.entity)
  }
  for flame in flames {
    hide_entity(flame.entity)
  }
  for item in items {
    hide_entity(item.entity)
  }
  for enemy in enemies {
    hide_entity(enemy.entity)
  }
  for player in players {
    hide_entity(player.entity)
  }
}

///|
fn hide_menu_visuals() -> Unit {
  for entity in menu_entities {
    hide_entity(entity)
  }
}

///|
fn sync_menu_visuals() -> Unit {
  let center_x = VIEWPORT_WIDTH / 2.0
  set_text_entity_center(
    title_entity,
    "MoonBit Bombman",
    @math.Vec2D(center_x, 26.0),
    "42px \{BOMBMAN_FONT_FAMILY}",
    HUD_TEXT_COLOR,
    200,
  )
  set_text_entity_center(
    hud_entity,
    phase_status_text(),
    @math.Vec2D(center_x, 104.0),
    "18px \{BOMBMAN_FONT_FAMILY}",
    MENU_SELECTED_COLOR,
    200,
  )
  let options = menu_options()
  for index in 0..<options.length() {
    let option = options[index]
    let prefix = if option == menu_selection.val { "> " } else { "  " }
    let color = if option == menu_selection.val {
      MENU_SELECTED_COLOR
    } else {
      MENU_NORMAL_COLOR
    }
    set_text_entity_center(
      menu_entities[index],
      prefix + menu_option_label(option),
      @math.Vec2D(center_x, 210.0 + index.to_double() * 38.0),
      "24px \{BOMBMAN_FONT_FAMILY}",
      color,
      200,
    )
  }
  set_text_entity_center(
    status_entity,
    status_text(),
    @math.Vec2D(center_x, VIEWPORT_HEIGHT - 60.0),
    "12px \{BOMBMAN_FONT_FAMILY}",
    HUD_MUTED_TEXT_COLOR,
    200,
  )
  set_text_entity_center(
    hint_entity,
    hint_text(),
    @math.Vec2D(center_x, VIEWPORT_HEIGHT - 32.0),
    "12px \{BOMBMAN_FONT_FAMILY}",
    HUD_MUTED_TEXT_COLOR,
    200,
  )
}

///|
fn sync_playing_hud_visuals() -> Unit {
  hide_menu_visuals()
  set_text_entity(
    title_entity,
    "BOMBMAN",
    @math.Vec2D(20.0, 18.0),
    "26px \{BOMBMAN_FONT_FAMILY}",
    HUD_TEXT_COLOR,
    200,
  )
  set_text_entity(
    hud_entity,
    phase_status_text(),
    @math.Vec2D(20.0, 48.0),
    "16px \{BOMBMAN_FONT_FAMILY}",
    HUD_TEXT_COLOR,
    200,
  )
  hide_entity(status_entity)
  hide_entity(hint_entity)
}

///|
pub fn render_sync_system(_world : @ecs.World) -> Unit {
  set_rect_entity(
    background_entity,
    @math.Vec2D::zero(),
    @math.Vec2D(VIEWPORT_WIDTH, VIEWPORT_HEIGHT),
    "rgb(18, 24, 30)",
    0,
  )
  match phase.val {
    MainMenu => {
      hide_gameplay_visuals()
      sync_menu_visuals()
    }
    Playing | RoundOver => {
      sync_tile_visuals()
      sync_bomb_visuals()
      sync_flame_visuals()
      sync_item_visuals()
      sync_enemy_visuals()
      sync_player_visuals()
      sync_playing_hud_visuals()
    }
  }
}

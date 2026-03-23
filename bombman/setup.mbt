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
fn tile_is_solid(x : Int, y : Int) -> Bool {
  match tile_at(x, y) {
    Empty => false
    HardWall | SoftWall => true
  }
}

///|
fn reset_direction_input_state() -> Unit {
  input_press_sequence.val = 0
  up_press_stamp.val = 0
  down_press_stamp.val = 0
  left_press_stamp.val = 0
  right_press_stamp.val = 0
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
fn reset_tiles() -> Unit {
  tiles.clear()
  let cell_count = GRID_WIDTH * GRID_HEIGHT
  for _ in 0..<cell_count {
    tiles.push(Empty)
  }
  for y in 0..<GRID_HEIGHT {
    for x in 0..<GRID_WIDTH {
      if x == 0 || x == GRID_WIDTH - 1 || y == 0 || y == GRID_HEIGHT - 1 {
        set_tile(x, y, HardWall)
      } else if x % 2 == 0 && y % 2 == 0 {
        set_tile(x, y, HardWall)
      }
    }
  }
  let soft_walls = [
    (3, 1),
    (5, 1),
    (7, 1),
    (9, 1),
    (1, 3),
    (3, 3),
    (5, 3),
    (7, 3),
    (9, 3),
    (11, 3),
    (3, 5),
    (5, 5),
    (7, 5),
    (9, 5),
    (11, 5),
    (1, 7),
    (3, 7),
    (5, 7),
    (7, 7),
    (9, 7),
    (5, 9),
    (7, 9),
    (9, 9),
    (11, 9),
  ]
  for pair in soft_walls {
    let x = pair.0
    let y = pair.1
    if tile_at(x, y) == Empty {
      set_tile(x, y, SoftWall)
    }
  }
  for pair in [(1, 1), (2, 1), (1, 2), (11, 1), (11, 2), (10, 1)] {
    let x = pair.0
    let y = pair.1
    set_tile(x, y, Empty)
  }
}

///|
fn reset_player() -> Unit {
  let start_center = cell_center(1, 1)
  player.val = {
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
fn reset_enemies() -> Unit {
  enemies.clear()
  let specs = [(11, 1, Left), (11, 9, Up), (9, 5, Down)]
  for spec in specs {
    let spawn_center = cell_center(spec.0, spec.1)
    enemies.push({
      entity: @entity.Entity::new(),
      cell_x: spec.0,
      cell_y: spec.1,
      center: spawn_center,
      direction: spec.2,
      desired_direction: spec.2,
      speed: ENEMY_SPEED,
      radius: ENEMY_RADIUS,
      alive: true,
    })
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
  for enemy in enemies {
    hide_entity(enemy.entity)
  }
  bombs.clear()
  flames.clear()
}

///|
fn reset_level() -> Unit {
  ensure_tile_entities()
  reset_direction_input_state()
  reset_tiles()
  reset_player()
  clear_dynamic_entities()
  reset_enemies()
  phase.val = Start
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  register_bombman_font_once()
  ensure_entity_alive(background_entity)
  ensure_entity_alive(player_entity)
  ensure_entity_alive(title_entity)
  ensure_entity_alive(hud_entity)
  ensure_entity_alive(status_entity)
  ensure_entity_alive(hint_entity)
  ensure_tile_entities()
  reset_level()
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
fn explode_bomb_at(index : Int) -> Unit {
  let bomb = bombs[index]
  hide_entity(bomb.entity)
  ignore(bombs.remove(index))
  player.val = { ..player.val, active_bombs: player.val.active_bombs - 1 }
  let cells = collect_explosion_cells(bomb.cell_x, bomb.cell_y, bomb.radius)
  for cell in cells {
    let x = cell.0
    let y = cell.1
    if tile_at(x, y) == SoftWall {
      set_tile(x, y, Empty)
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
fn place_bomb() -> Unit {
  if player.val.active_bombs >= player.val.max_bombs {
    return
  }
  let (bomb_x, bomb_y) = world_to_cell(player.val.center)
  if tile_at(bomb_x, bomb_y) != Empty || has_bomb_at(bomb_x, bomb_y) {
    return
  }
  bombs.push({
    entity: @entity.Entity::new(),
    cell_x: bomb_x,
    cell_y: bomb_y,
    timer: BOMB_FUSE_TIME,
    radius: player.val.blast_radius,
    passable_for_player: true,
  })
  player.val = { ..player.val, active_bombs: player.val.active_bombs + 1 }
}

///|
fn phase_status_text() -> String {
  match phase.val {
    Start => "Press Enter or Space to start"
    Playing => {
      let enemies_left = active_enemy_count()
      if player.val.alive {
        "Bombs: \{player.val.max_bombs - player.val.active_bombs}/\{player.val.max_bombs}   Enemies: \{enemies_left}"
      } else {
        "Boom. You were caught in the blast."
      }
    }
    Won => "Stage clear. Press Enter or R to restart"
    Lost => "You lost. Press Enter or R to restart"
  }
}

///|
fn hint_text() -> String {
  match phase.val {
    Start => "Move: WASD / Arrows   Bomb: Space   ESC: Exit"
    Playing => "Move: WASD / Arrows   Bomb: Space   R: Restart   ESC: Exit"
    Won => "Enter / R restart   ESC exit"
    Lost => "Enter / R restart   ESC exit"
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
  let color = if player.val.alive { PLAYER_COLOR } else { PLAYER_DEAD_COLOR }
  set_circle_entity(
    player_entity,
    player.val.center,
    player.val.radius,
    color,
    66,
  )
}

///|
fn sync_hud_visuals() -> Unit {
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
  set_text_entity(
    status_entity,
    "Soft walls break. Hard walls block. Flames travel in a cross.",
    @math.Vec2D(20.0, VIEWPORT_HEIGHT - 48.0),
    "12px \{BOMBMAN_FONT_FAMILY}",
    HUD_MUTED_TEXT_COLOR,
    200,
  )
  set_text_entity(
    hint_entity,
    hint_text(),
    @math.Vec2D(20.0, VIEWPORT_HEIGHT - 24.0),
    "12px \{BOMBMAN_FONT_FAMILY}",
    HUD_MUTED_TEXT_COLOR,
    200,
  )
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
  sync_tile_visuals()
  sync_bomb_visuals()
  sync_flame_visuals()
  sync_enemy_visuals()
  sync_player_visuals()
  sync_hud_visuals()
}

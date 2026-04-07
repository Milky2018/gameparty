///|
let bombman_font_registered : Ref[Bool] = { val: false }

///|
let circle_mesh_handles : Map[Int, @mesh2d.Mesh2dHandle] = Map::new()

///|
let circle_material_handles : Map[String, @material2d.ColorMaterialHandle] = Map::new()

///|
let text_content_cache : Map[@entity.Entity, String] = Map::new()

///|
let text_style_cache : Map[@entity.Entity, String] = Map::new()

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
fn entity_transform_2d(
  position : @math.Vec2D,
  zindex : Int,
) -> @transform.Transform {
  @transform.Transform::from_xyz(position[X], position[Y], zindex.to_double())
}

///|
fn show_entity(entity : @entity.Entity) -> Unit {
  @visibility.visibilities().set(entity, Visible)
}

///|
fn parse_color_component_int(part : StringView) -> Int? {
  let token = part.to_string().trim().to_string()
  if token == "" {
    return None
  }
  Some(@string.parse_int(token)) catch {
    _ => None
  }
}

///|
fn parse_color_alpha(part : StringView) -> Double? {
  let token = part.to_string().trim().to_string()
  if token == "" {
    return None
  }
  Some(@string.parse_double(token)) catch {
    _ => None
  }
}

///|
fn clamp_color_byte(value : Int) -> UInt {
  let clamped = if value < 0 { 0 } else if value > 255 { 255 } else { value }
  clamped.reinterpret_as_uint()
}

///|
fn clamp_color_alpha(value : Double) -> Double {
  clamp_double(value, 0.0, 1.0)
}

///|
fn normalize_css_color_string(color : String) -> String {
  let trimmed = color.trim().to_string()
  if trimmed.length() >= 2 &&
    trimmed.unsafe_get(0) == '\"' &&
    trimmed.unsafe_get(trimmed.length() - 1) == '\"' {
    return trimmed.unsafe_substring(start=1, end=trimmed.length() - 1)
  }
  if trimmed.length() >= 2 &&
    trimmed.unsafe_get(0) == '\'' &&
    trimmed.unsafe_get(trimmed.length() - 1) == '\'' {
    return trimmed.unsafe_substring(start=1, end=trimmed.length() - 1)
  }
  trimmed
}

///|
fn parse_css_rgb_components(color : String) -> (UInt, UInt, UInt, Double)? {
  let trimmed = normalize_css_color_string(color)
  let is_rgb = trimmed.has_prefix("rgb(") && trimmed.has_suffix(")")
  let is_rgba = trimmed.has_prefix("rgba(") && trimmed.has_suffix(")")
  if !is_rgb && !is_rgba {
    return None
  }
  let body = if is_rgba {
    trimmed.replace(old="rgba(", new="").replace(old=")", new="")
  } else {
    trimmed.replace(old="rgb(", new="").replace(old=")", new="")
  }
  let parts : Array[StringView] = []
  for part in body.split(",") {
    parts.push(part)
  }
  if (is_rgba && parts.length() != 4) || (is_rgb && parts.length() != 3) {
    return None
  }
  guard parse_color_component_int(parts[0]) is Some(r) else { return None }
  guard parse_color_component_int(parts[1]) is Some(g) else { return None }
  guard parse_color_component_int(parts[2]) is Some(b) else { return None }
  let alpha = if is_rgba {
    guard parse_color_alpha(parts[3]) is Some(a) else { return None }
    clamp_color_alpha(a)
  } else {
    1.0
  }
  Some((clamp_color_byte(r), clamp_color_byte(g), clamp_color_byte(b), alpha))
}

///|
fn sprite_color(color : String) -> @render.Color {
  let normalized = normalize_css_color_string(color)
  match parse_css_rgb_components(color) {
    Some((r, g, b, a)) => { r, g, b, a }
    None => @sprite.color_from_css(normalized)
  }
}

///|
fn circle_mesh_handle(radius : Double) -> @mesh2d.Mesh2dHandle {
  let key = @cmath.round(radius * 1000.0).to_int()
  circle_mesh_handles.get_or_init(key, fn() { @mesh2d.circle(radius) })
}

///|
fn circle_material_handle(color : String) -> @material2d.ColorMaterialHandle {
  circle_material_handles.get_or_init(color, fn() {
    @material2d.register_color_material(
      @material2d.ColorMaterial::from_color(sprite_color(color)),
    )
  })
}

///|
fn hide_entity(entity : @entity.Entity) -> Unit {
  @visibility.visibilities().set(entity, Hidden)
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
  show_entity(entity)
  let style_key = font + "|" + color + "|left-top"
  let style_changed = match text_style_cache.get(entity) {
    Some(existing) => existing != style_key
    None => true
  }
  if style_changed {
    @ui.text_fonts().set(entity, @ui.TextFont::from_css(font))
    @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
    @ui.text_layouts().set(
      entity,
      @ui.TextLayout::new(align=Left, baseline=Top),
    )
    @text2d.text2ds().set(entity, @text2d.Text2d::new())
    @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2D(-0.5, 0.5)))
    text_style_cache.set(entity, style_key)
  }
  let content_changed = match text_content_cache.get(entity) {
    Some(existing) => existing != text
    None => true
  }
  if content_changed {
    @ui.texts().set(entity, @ui.Text::new(text))
    text_content_cache.set(entity, text)
  }
  @transform.transforms().set(entity, entity_transform_2d(position, zindex))
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
  show_entity(entity)
  let style_key = font + "|" + color + "|center-top"
  let style_changed = match text_style_cache.get(entity) {
    Some(existing) => existing != style_key
    None => true
  }
  if style_changed {
    @ui.text_fonts().set(entity, @ui.TextFont::from_css(font))
    @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
    @ui.text_layouts().set(
      entity,
      @ui.TextLayout::new(align=Center, baseline=Top),
    )
    @text2d.text2ds().set(entity, @text2d.Text2d::new())
    @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2D(0.0, 0.5)))
    text_style_cache.set(entity, style_key)
  }
  let content_changed = match text_content_cache.get(entity) {
    Some(existing) => existing != text
    None => true
  }
  if content_changed {
    @ui.texts().set(entity, @ui.Text::new(text))
    text_content_cache.set(entity, text)
  }
  @transform.transforms().set(entity, entity_transform_2d(position, zindex))
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
  show_entity(entity)
  let sprite = @sprite.Sprite::from_color(sprite_color(color), size)
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, entity_transform_2d(position, zindex))
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
  show_entity(entity)
  @mesh2d.mesh2ds().set(entity, @mesh2d.Mesh2d::new(circle_mesh_handle(radius)))
  @material2d.mesh_material2ds().set(
    entity,
    @material2d.MeshMaterial2d::from_color_material(
      circle_material_handle(color),
    ),
  )
  @transform.transforms().set(entity, entity_transform_2d(center, zindex))
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
    let index = cell_index(x, y)
    if tiles[index] != tile {
      tiles[index] = tile
      tile_visuals_dirty.val = true
    }
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
fn reset_netplay_runtime() -> Unit {
  netplay_host_session.val = None
  netplay_client_session.val = None
  netplay_local_frame.val = 0
}

///|
fn netplay_loopback_exchange(
  host : @netplay.NetSession,
  client : @netplay.NetSession,
) -> (@netplay.NetSession, @netplay.NetSession) {
  let (host_after_drain, host_messages) = host.drain_outgoing()
  let mut next_client = client
  for message in host_messages {
    next_client = next_client.ingest_remote(message)
  }
  let (client_after_drain, client_messages) = next_client.drain_outgoing()
  let mut next_host = host_after_drain
  for message in client_messages {
    next_host = next_host.ingest_remote(message)
  }
  (next_host, client_after_drain)
}

///|
fn configure_netplay_for_round(mode : GameMode) -> Unit {
  reset_netplay_runtime()
  if mode == SinglePlayer || !netplay_local_loop_enabled.val {
    return
  }
  let config = @netplay.NetConfig::default()
  let mut host = @netplay.NetSession::new_host(
    local_peer_id="p1",
    remote_peer_id="p2",
    seed=current_level.val + 1,
    config~,
  )
  let mut client = @netplay.NetSession::new_client(
    local_peer_id="p2",
    remote_peer_id="p1",
    config~,
  )
  host = host.begin_handshake()
  client = client.begin_handshake()
  for _ in 0..<2 {
    let (next_host, next_client) = netplay_loopback_exchange(host, client)
    host = next_host
    client = next_client
  }
  host = host.set_local_ready()
  client = client.set_local_ready()
  for _ in 0..<4 {
    let (next_host, next_client) = netplay_loopback_exchange(host, client)
    host = next_host
    client = next_client
  }
  let (host_after_events, _) = host.drain_events()
  let (client_after_events, _) = client.drain_events()
  netplay_host_session.val = Some(host_after_events)
  netplay_client_session.val = Some(client_after_events)
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
  tile_visuals_dirty.val = true
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
    hide_entity(item.label_entity)
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
  configure_netplay_for_round(mode)
  tile_visuals_dirty.val = true
  phase.val = Playing
}

///|
fn return_to_menu() -> Unit {
  reset_direction_input_state()
  reset_netplay_runtime()
  clear_dynamic_entities()
  clear_tile_grid()
  deactivate_all_players()
  tile_visuals_dirty.val = true
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
  profile_enabled.val = env_flag_enabled(PROFILE_ENV)
  capture_enabled.val = env_flag_enabled(CAPTURE_ENV)
  netplay_local_loop_enabled.val = env_flag_enabled(NETPLAY_LOCAL_LOOP_ENV)
  reset_netplay_runtime()
  let started_at = @time.elapsed_raw()
  profile_started_at.val = started_at
  profile_last_report_at.val = started_at
  profile_frame_count.val = 0
  profile_sim_total.val = 0.0
  profile_render_total.val = 0.0
  profile_frame_dt_total.val = 0.0
  profile_motion_total.val = 0.0
  profile_bombs_total.val = 0.0
  profile_flames_total.val = 0.0
  profile_enemies_total.val = 0.0
  profile_hits_total.val = 0.0
  profile_phase_total.val = 0.0
  capture_started_at.val = started_at
  capture_taken.val = false
  capture_perf_started_at.val = started_at
  capture_perf_frame_count.val = 0
  capture_perf_frame_dt_total.val = 0.0
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
  if capture_enabled.val {
    start_round(SinglePlayer)
  }
  render_sync_system(@ecs.require_current_world())
  // Ignore startup/setup cost for runtime QA metrics and capture delay.
  let ready_at = @time.elapsed_raw()
  profile_started_at.val = ready_at
  profile_last_report_at.val = ready_at
  profile_frame_count.val = 0
  profile_sim_total.val = 0.0
  profile_render_total.val = 0.0
  profile_frame_dt_total.val = 0.0
  profile_motion_total.val = 0.0
  profile_bombs_total.val = 0.0
  profile_flames_total.val = 0.0
  profile_enemies_total.val = 0.0
  profile_hits_total.val = 0.0
  profile_phase_total.val = 0.0
  capture_started_at.val = ready_at
  capture_taken.val = false
  capture_perf_started_at.val = ready_at
  capture_perf_frame_count.val = 0
  capture_perf_frame_dt_total.val = 0.0
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
  items.push({
    entity: @entity.Entity::new(),
    label_entity: @entity.Entity::new(),
    cell_x: x,
    cell_y: y,
    kind,
  })
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
  if !tile_visuals_dirty.val {
    return
  }
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
  tile_visuals_dirty.val = false
}

///|
fn hide_tile_visuals() -> Unit {
  for entity in tile_entities {
    hide_entity(entity)
  }
  tile_visuals_dirty.val = true
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
    set_circle_entity(
      item.entity,
      center,
      ITEM_BUBBLE_RADIUS,
      ITEM_BUBBLE_COLOR,
      62,
    )
    set_text_entity_center(
      item.label_entity,
      item_label(item.kind),
      @math.Vec2D(center[X], center[Y] - 14.0),
      "26px \{BOMBMAN_FONT_FAMILY}",
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
    hide_entity(item.label_entity)
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
  let render_started_at = @time.elapsed_raw()
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
  if profile_enabled.val {
    profile_render_total.val += @time.elapsed_raw() - render_started_at
    profile_frame_count.val += 1
    profile_frame_dt_total.val += @time.frame_delta()
    emit_profile_report_if_needed(@time.elapsed_raw())
  }
  if capture_enabled.val && !capture_taken.val {
    capture_perf_frame_count.val += 1
    capture_perf_frame_dt_total.val += @time.frame_delta()
  }
}

///|
pub fn capture_after_render_system(_world : @ecs.World) -> Unit {
  if !capture_enabled.val || capture_taken.val {
    return
  }
  if @time.elapsed_raw() - capture_started_at.val < CAPTURE_DELAY_SECONDS {
    return
  }
  if profile_enabled.val {
    let elapsed = @time.elapsed_raw() - capture_perf_started_at.val
    let frames = capture_perf_frame_count.val
    let average_fps = if elapsed <= 0.0 || frames <= 0 {
      0.0
    } else {
      frames.to_double() / elapsed
    }
    let fps_from_frame_dt = if capture_perf_frame_dt_total.val <= 0.0 ||
      frames <= 0 {
      0.0
    } else {
      frames.to_double() / capture_perf_frame_dt_total.val
    }
    if frames > 0 {
      println(
        "[bombman][perf] raylib_fps=\{@raylib.get_fps()} avg_fps=\{average_fps} fps_frame_dt=\{fps_from_frame_dt} frames=\{frames} elapsed=\{elapsed}",
      )
    }
  }
  @raylib.take_screenshot(CAPTURE_PATH)
  println("[bombman][capture] path=\{CAPTURE_PATH}")
  capture_taken.val = true
  @system.exit()
}

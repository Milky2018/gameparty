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
let bombman_spritesheet_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
fn register_bombman_font_once() -> Unit {
  if bombman_font_registered.val {
    return
  }
  ignore(@asset.load_font(BOMBMAN_FONT_PATH, family=BOMBMAN_FONT_FAMILY))
  bombman_font_registered.val = true
}

///|
fn bombman_spritesheet() -> @asset.ImageHandle {
  match bombman_spritesheet_handle.val {
    Some(handle) => handle
    None => {
      let handle = @asset.load_image(BOMBMAN_SPRITES_PATH)
      bombman_spritesheet_handle.val = Some(handle)
      handle
    }
  }
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
fn atlas_tile_rect(col : Int, row : Int) -> @math.Rect {
  {
    position: @math.Vec2D(
      col.to_double() * BOMBMAN_SPRITE_TILE_SIZE,
      row.to_double() * BOMBMAN_SPRITE_TILE_SIZE,
    ),
    size: @math.Vec2D(BOMBMAN_SPRITE_TILE_SIZE, BOMBMAN_SPRITE_TILE_SIZE),
  }
}

///|
fn atlas_tile_index(col : Int, row : Int) -> Int {
  row * BOMBMAN_SPRITE_ATLAS_COLUMNS + col
}

///|
fn anim_clip_first_tile_index(clip_id : AnimClip) -> Int {
  let frame = anim_clip_frame(clip_id, 0)
  atlas_tile_index(frame.0, frame.1)
}

///|
fn anim_clip_name(clip_id : AnimClip) -> String {
  match clip_id {
    PlayerIdleDown => "player.idle.down"
    PlayerIdleUp => "player.idle.up"
    PlayerIdleLeft => "player.idle.left"
    PlayerIdleRight => "player.idle.right"
    PlayerMoveDown => "player.move.down"
    PlayerMoveUp => "player.move.up"
    PlayerMoveLeft => "player.move.left"
    PlayerMoveRight => "player.move.right"
    PlayerDeath => "player.death"
    EnemyBlueMoveRight => "enemy.blue.move.right"
    EnemyBlueMoveLeft => "enemy.blue.move.left"
    EnemyBlueDeath => "enemy.blue.death"
    EnemyPinkMoveRight => "enemy.pink.move.right"
    EnemyPinkMoveLeft => "enemy.pink.move.left"
    EnemyPinkDeath => "enemy.pink.death"
    EnemyPeachMoveRight => "enemy.peach.move.right"
    EnemyPeachMoveLeft => "enemy.peach.move.left"
    EnemyPeachDeath => "enemy.peach.death"
    BombFuse => "bomb.fuse"
    FlameCenterActive => "flame.center.active"
    FlameBodyHActive => "flame.body_h.active"
    FlameBodyVActive => "flame.body_v.active"
    FlameEndLeftActive => "flame.end_left.active"
    FlameEndRightActive => "flame.end_right.active"
    FlameEndUpActive => "flame.end_up.active"
    FlameEndDownActive => "flame.end_down.active"
    FlameCenterTail => "flame.center.tail"
    FlameBodyHTail => "flame.body_h.tail"
    FlameBodyVTail => "flame.body_v.tail"
    FlameEndLeftTail => "flame.end_left.tail"
    FlameEndRightTail => "flame.end_right.tail"
    FlameEndUpTail => "flame.end_up.tail"
    FlameEndDownTail => "flame.end_down.tail"
    SoftWallBreak => "soft_wall.break"
  }
}

///|
fn ensure_bombman_animation_assets_once() -> Unit {
  if bombman_atlas_layout.val is None {
    let layout = @sprite.TextureAtlasLayout::from_grid(
      @math.Vec2D(BOMBMAN_SPRITE_TILE_SIZE, BOMBMAN_SPRITE_TILE_SIZE),
      BOMBMAN_SPRITE_ATLAS_COLUMNS,
      BOMBMAN_SPRITE_ATLAS_ROWS,
    )
    bombman_atlas_layout.val = Some(
      @sprite.register_texture_atlas_layout(layout),
    )
  }
  if bombman_anim_graph.val is Some(_) {
    return
  }
  let clip_handles : Array[@animation.AnimationClipHandle] = []
  let frame_duration = anim_frame_duration()
  for clip_id in all_anim_clips {
    let frame_count = anim_clip_frame_count(clip_id)
    let keys : Array[@animation.ScalarKeyframe] = []
    for frame_index in 0..<frame_count {
      let frame = anim_clip_frame(clip_id, frame_index)
      keys.push({
        time: frame_index.to_double() * frame_duration,
        value: atlas_tile_index(frame.0, frame.1).to_double(),
        in_tangent: None,
        out_tangent: None,
      })
    }
    let clip = @animation.AnimationClip::new(anim_clip_name(clip_id))
    clip.add_curve_to_target(
      @animation.AnimationTargetId::new("self"),
      @animation.VariableCurve::scalar(
        @animation.texture_atlas_index_field(),
        keys,
        interpolation=@animation.ChannelInterpolation::Step,
      ),
    )
    clip.duration = frame_count.to_double() * frame_duration
    clip_handles.push(@animation.register_animation_clip_asset(clip))
  }
  let (graph, nodes) = @animation.AnimationGraph::from_clips(clip_handles)
  bombman_anim_graph.val = Some(
    @animation.register_animation_graph_asset(graph),
  )
  bombman_anim_nodes.clear()
  for node in nodes {
    bombman_anim_nodes.push(node)
  }
}

///|
fn animation_node_for_clip(
  clip_id : AnimClip,
) -> @animation.AnimationNodeIndex? {
  for index in 0..<all_anim_clips.length() {
    if all_anim_clips[index] == clip_id {
      if index >= 0 && index < bombman_anim_nodes.length() {
        return Some(bombman_anim_nodes[index])
      }
      return None
    }
  }
  None
}

///|
fn ensure_entity_animation_binding(entity : @entity.Entity) -> Unit {
  ensure_bombman_animation_assets_once()
  match bombman_anim_graph.val {
    Some(graph_handle) => {
      @animation.animation_graph_handles().set(entity, graph_handle)
      @animation.animation_target_ids().set(
        entity,
        @animation.AnimationTargetId::new("self"),
      )
      @animation.animated_bys().set(entity, @animation.AnimatedBy::new(entity))
      ignore(
        @animation.animation_players().get_or_init(entity, fn() {
          @animation.AnimationPlayer::new()
        }),
      )
      ignore(
        @animation.animation_transitions().get_or_init(entity, fn() {
          @animation.AnimationTransitions::new()
        }),
      )
    }
    None => ()
  }
}

///|
fn play_entity_animation(
  entity : @entity.Entity,
  clip_id : AnimClip,
  looping : Bool,
) -> Bool {
  ensure_entity_animation_binding(entity)
  guard animation_node_for_clip(clip_id) is Some(node) else { return false }
  guard @animation.animation_players().get(entity) is Some(player) else {
    return false
  }
  guard @animation.animation_transitions().get(entity) is Some(transitions) else {
    return false
  }
  ignore(
    transitions.play(
      player,
      node,
      0.0,
      repeat=if looping {
        @animation.RepeatAnimation::Forever
      } else {
        @animation.RepeatAnimation::Never
      },
    ),
  )
  true
}

///|
fn entity_animation_finished(
  entity : @entity.Entity,
  clip_id : AnimClip,
) -> Bool {
  guard animation_node_for_clip(clip_id) is Some(node) else { return true }
  guard @animation.animation_players().get(entity) is Some(player) else {
    return false
  }
  match player.animation(node) {
    Some(active_animation) => active_animation.is_finished()
    None => false
  }
}

///|
fn parse_font_size_px(font : String) -> Double {
  let trimmed = font.trim().to_string()
  let mut first_token = ""
  for token_view in trimmed.split(" ") {
    let token = token_view.to_string().trim().to_string()
    if token != "" {
      first_token = token
      break
    }
  }
  if first_token == "" {
    return 16.0
  }
  let number_text = first_token.replace(old="px", new="")
  @string.parse_double(number_text) catch {
    _ => 16.0
  }
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
fn sprite_color(color : String) -> @render.Color {
  @sprite.color_from_css(normalize_css_color_string(color))
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
    @ui.text_fonts().set(
      entity,
      @ui.TextFont::new(
        family=BOMBMAN_FONT_FAMILY,
        size=parse_font_size_px(font),
      ),
    )
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
    @ui.text_fonts().set(
      entity,
      @ui.TextFont::new(
        family=BOMBMAN_FONT_FAMILY,
        size=parse_font_size_px(font),
      ),
    )
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
fn set_atlas_entity_top_left(
  entity : @entity.Entity,
  position : @math.Vec2D,
  size : @math.Vec2D,
  col : Int,
  row : Int,
  zindex : Int,
  tint? : String? = None,
  flip_x? : Bool = false,
) -> Unit {
  ensure_entity_alive(entity)
  show_entity(entity)
  let sprite = @sprite.Sprite::from_image(
    bombman_spritesheet(),
    custom_size=Some(size),
  )
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  sprite.rect = Some(atlas_tile_rect(col, row))
  sprite.flip_x = flip_x
  match tint {
    Some(color) => sprite.color = sprite_color(color)
    None => ()
  }
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, entity_transform_2d(position, zindex))
}

///|
fn set_atlas_entity_center(
  entity : @entity.Entity,
  center : @math.Vec2D,
  size : @math.Vec2D,
  col : Int,
  row : Int,
  zindex : Int,
  tint? : String? = None,
  flip_x? : Bool = false,
) -> Unit {
  let top_left = center - @math.Vec2D(size[X] / 2.0, size[Y] / 2.0)
  set_atlas_entity_top_left(
    entity,
    top_left,
    size,
    col,
    row,
    zindex,
    tint~,
    flip_x~,
  )
}

///|
fn set_animated_atlas_entity_top_left(
  entity : @entity.Entity,
  position : @math.Vec2D,
  size : @math.Vec2D,
  clip_id : AnimClip,
  zindex : Int,
  tint? : String? = None,
  flip_x? : Bool = false,
) -> Unit {
  ensure_entity_alive(entity)
  show_entity(entity)
  ensure_entity_animation_binding(entity)
  guard bombman_atlas_layout.val is Some(layout) else { return }
  let image = bombman_spritesheet()
  let sprite = match @sprite.sprites().get(entity) {
    Some(existing) => existing
    None =>
      @sprite.Sprite::from_atlas_image(
        image,
        @sprite.TextureAtlas::new(
          layout,
          index=anim_clip_first_tile_index(clip_id),
        ),
      )
  }
  sprite.custom_size = Some(size)
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  sprite.flip_x = flip_x
  sprite.texture_atlas = match sprite.texture_atlas {
    Some(texture_atlas) => Some({ ..texture_atlas, layout, })
    None =>
      Some(
        @sprite.TextureAtlas::new(
          layout,
          index=anim_clip_first_tile_index(clip_id),
        ),
      )
  }
  match tint {
    Some(color) => sprite.color = sprite_color(color)
    None => sprite.color = sprite_color("rgb(255,255,255)")
  }
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, entity_transform_2d(position, zindex))
}

///|
fn set_animated_atlas_entity_center(
  entity : @entity.Entity,
  center : @math.Vec2D,
  size : @math.Vec2D,
  clip_id : AnimClip,
  zindex : Int,
  tint? : String? = None,
  flip_x? : Bool = false,
) -> Unit {
  let top_left = center - @math.Vec2D(size[X] / 2.0, size[Y] / 2.0)
  set_animated_atlas_entity_top_left(
    entity,
    top_left,
    size,
    clip_id,
    zindex,
    tint~,
    flip_x~,
  )
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
  match netplay_link.val {
    Some(link) => {
      ignore(link.close())
      netplay_link.val = None
    }
    None => ()
  }
  netplay_host_session.val = None
  netplay_client_session.val = None
  netplay_session.val = None
  netplay_last_remote_input.val = None
  netplay_last_remote_action_frame.val = -1
  netplay_round_seed_applied.val = -1
  netplay_local_frame.val = 0
}

///|
fn uint64_array_to_seed_bytes(values : Array[UInt64]) -> Bytes {
  Bytes::makei(32, fn(i) {
    let value_index = i / 8
    let byte_index = i % 8
    let value = values[value_index]
    match byte_index {
      0 => value.to_byte()
      1 => (value >> 8).to_byte()
      2 => (value >> 16).to_byte()
      3 => (value >> 24).to_byte()
      4 => (value >> 32).to_byte()
      5 => (value >> 40).to_byte()
      6 => (value >> 48).to_byte()
      7 => (value >> 56).to_byte()
      _ => b'\x00'
    }
  })
}

///|
fn reseed_drop_rng(seed : UInt64) -> Unit {
  let part1 = seed - 25
  let part2 = seed + 25
  let part3 = seed - 41
  let part4 = seed + 41
  drop_rng.val = @random.Rand::chacha8(
    seed=uint64_array_to_seed_bytes([part1, part2, part3, part4]),
  )
}

///|
fn reset_network_menu_state() -> Unit {
  menu_screen.val = MainRoot
  network_root_selection.val = CreateRoom
  host_setup_focus.val = Mode
  join_setup_focus.val = Host
  host_setup_mode.val = Coop
  host_setup_level.val = current_level.val
  host_setup_port.val = "39000"
  join_setup_host.val = "127.0.0.1"
  join_setup_port.val = "39000"
  lobby_local_ip.val = None
  lobby_mode_label.val = "A (CO-OP)"
  lobby_endpoint_label.val = ""
  lobby_status_label.val = ""
}

///|
fn stop_active_netplay() -> Unit {
  reset_netplay_runtime()
  netplay_mode.val = Off
}

///|
fn apply_remote_round_seed(seed : Int) -> Unit {
  if netplay_round_seed_applied.val == seed {
    return
  }
  match decode_round_seed_from_netplay(seed) {
    Some((remote_level, remote_mode)) => {
      let needs_reload = current_level.val != remote_level ||
        current_mode.val != remote_mode
      current_level.val = remote_level
      current_mode.val = remote_mode
      if phase.val == Playing && needs_reload {
        clear_dynamic_entities()
        load_level(remote_level, remote_mode)
        tile_visuals_dirty.val = true
      }
      netplay_round_seed_applied.val = seed
      reseed_drop_rng(seed.to_uint64())
    }
    None => ()
  }
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
fn parse_numeric_port(raw : String) -> Int? {
  if raw == "" {
    return None
  }
  for index in 0..<raw.length() {
    let code = raw.code_unit_at(index).to_int()
    if code < 48 || code > 57 {
      return None
    }
  }
  let parsed = Some(@string.parse_int(raw)) catch { _ => None }
  match parsed {
    Some(port) => if port >= 1 && port <= 65535 { Some(port) } else { None }
    None => None
  }
}

///|
fn open_network_menu_root() -> Unit {
  stop_active_netplay()
  menu_error_message.val = ""
  menu_screen.val = NetworkRoot
  network_root_selection.val = CreateRoom
  lobby_status_label.val = ""
}

///|
fn open_network_host_setup() -> Unit {
  menu_error_message.val = ""
  menu_screen.val = NetworkHostSetup
  host_setup_focus.val = Mode
  host_setup_mode.val = Coop
  host_setup_level.val = current_level.val
  host_setup_port.val = "39000"
}

///|
fn open_network_join_setup() -> Unit {
  menu_error_message.val = ""
  menu_screen.val = NetworkJoinSetup
  join_setup_focus.val = Host
  join_setup_host.val = "127.0.0.1"
  join_setup_port.val = "39000"
}

///|
fn cancel_network_lobby_to_root(error? : String = "") -> Unit {
  stop_active_netplay()
  menu_screen.val = NetworkRoot
  network_root_selection.val = CreateRoom
  lobby_status_label.val = ""
  if error == "" {
    menu_error_message.val = ""
  } else {
    menu_error_message.val = error
  }
}

///|
fn begin_network_host_lobby(
  mode : GameMode,
  port : Int,
  level_index : Int,
) -> Unit {
  stop_active_netplay()
  let normalized_level = clamp_int(level_index, 0, levels.length() - 1)
  current_level.val = normalized_level
  let round_seed = encode_round_seed_for_netplay(current_level.val, mode)
  let config = @netplay.NetConfig::default()
  let mut session = @netplay.NetSession::new_host(
    local_peer_id="p1",
    remote_peer_id="p2",
    seed=round_seed,
    config~,
  )
  session = session.begin_handshake()
  session = session.set_local_ready()
  netplay_mode.val = Host
  netplay_port.val = port
  netplay_session.val = Some(session)
  netplay_link.val = Some(@netplay.TcpLink::new_host(port))
  netplay_round_seed_applied.val = round_seed
  reseed_drop_rng(round_seed.to_uint64())
  current_mode.val = mode
  lobby_local_ip.val = @netplay.local_ipv4()
  lobby_mode_label.val = network_mode_short(mode)
  lobby_endpoint_label.val = "0.0.0.0:\{port}"
  lobby_status_label.val = "Waiting for another player..."
  menu_error_message.val = ""
  menu_screen.val = NetworkLobby
}

///|
fn begin_network_join_lobby(host : String, port : Int) -> Unit {
  stop_active_netplay()
  let config = @netplay.NetConfig::default()
  let mut session = @netplay.NetSession::new_client(
    local_peer_id="p2",
    remote_peer_id="p1",
    config~,
  )
  session = session.begin_handshake()
  session = session.set_local_ready()
  netplay_mode.val = Client
  netplay_remote_host.val = host
  netplay_remote_port.val = port
  netplay_session.val = Some(session)
  netplay_link.val = Some(
    @netplay.TcpLink::new_client(remote_host=host, remote_port=port),
  )
  lobby_local_ip.val = @netplay.local_ipv4()
  lobby_mode_label.val = "SYNCING FROM HOST"
  lobby_endpoint_label.val = "\{host}:\{port}"
  lobby_status_label.val = "Connecting and syncing..."
  menu_error_message.val = ""
  menu_screen.val = NetworkLobby
}

///|
fn start_local_round(mode : GameMode) -> Unit {
  stop_active_netplay()
  start_round(mode)
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
    facing: Down,
    flip_x: false,
    speed: PLAYER_SPEED,
    radius: PLAYER_RADIUS,
    alive: true,
    death_animation_done: false,
    anim: anim_playback_new(player_idle_clip(id, Down), true),
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
  for breaking in soft_wall_breaks {
    hide_entity(breaking.entity)
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
  soft_wall_breaks.clear()
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
            let spawn_order = enemies.length()
            let skin = enemy_skin_for_spawn(x, y, spawn_order)
            let direction = default_enemy_direction()
            let facing = Right
            enemies.push({
              entity: @entity.Entity::new(),
              cell_x: x,
              cell_y: y,
              center: cell_center(x, y),
              direction,
              desired_direction: direction,
              facing,
              flip_x: false,
              speed: ENEMY_SPEED,
              radius: ENEMY_RADIUS,
              alive: true,
              skin,
              death_animation_done: false,
              anim: anim_playback_new(enemy_move_clip(skin, facing), true),
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
  menu_error_message.val = ""
  current_mode.val = mode
  round_outcome.val = LevelClear
  load_level(current_level.val, mode)
  tile_visuals_dirty.val = true
  phase.val = Playing
}

///|
fn return_to_menu() -> Unit {
  reset_direction_input_state()
  stop_active_netplay()
  clear_dynamic_entities()
  clear_tile_grid()
  deactivate_all_players()
  menu_error_message.val = ""
  reset_network_menu_state()
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
  ensure_bombman_animation_assets_once()
  profile_enabled.val = env_flag_enabled(PROFILE_ENV)
  capture_enabled.val = env_flag_enabled(CAPTURE_ENV)
  stop_active_netplay()
  reset_network_menu_state()
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
  reseed_drop_rng(@env.now())
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
  menu_selection.val = OnePlayer
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
priv struct FlameSpawnPlan {
  cell_x : Int
  cell_y : Int
  kind : FlameKind
}

///|
fn add_or_replace_flame_spawn(
  spawns : Array[FlameSpawnPlan],
  cell_x : Int,
  cell_y : Int,
  kind : FlameKind,
) -> Unit {
  match
    spawns.search_by(fn(spawn) {
      spawn.cell_x == cell_x && spawn.cell_y == cell_y
    }) {
    Some(index) =>
      if spawns[index].kind != Center && kind == Center {
        spawns[index] = { ..spawns[index], kind, }
      }
    None => spawns.push({ cell_x, cell_y, kind })
  }
}

///|
fn collect_explosion_spawns(
  origin_x : Int,
  origin_y : Int,
  radius : Int,
) -> Array[FlameSpawnPlan] {
  let spawns : Array[FlameSpawnPlan] = [
    { cell_x: origin_x, cell_y: origin_y, kind: Center },
  ]
  for direction in [Up, Down, Left, Right] {
    let (dx, dy) = direction_delta(direction)
    let traversed : Array[(Int, Int)] = []
    for step in 1..<=radius {
      let x = origin_x + dx * step
      let y = origin_y + dy * step
      let tile = tile_at(x, y)
      if tile == HardWall {
        break
      }
      traversed.push((x, y))
      if tile == SoftWall {
        break
      }
    }
    for index in 0..<traversed.length() {
      let cell = traversed[index]
      let is_end = index == traversed.length() - 1
      let kind = if is_end {
        match direction {
          Left => EndLeft
          Right => EndRight
          Up => EndUp
          Down => EndDown
        }
      } else {
        match direction {
          Left | Right => BodyH
          Up | Down => BodyV
        }
      }
      add_or_replace_flame_spawn(spawns, cell.0, cell.1, kind)
    }
  }
  spawns
}

///|
fn has_soft_wall_break_at(x : Int, y : Int) -> Bool {
  soft_wall_breaks.any(fn(breaking) {
    breaking.cell_x == x && breaking.cell_y == y
  })
}

///|
fn spawn_soft_wall_break(x : Int, y : Int) -> Unit {
  if has_soft_wall_break_at(x, y) {
    return
  }
  soft_wall_breaks.push({
    entity: @entity.Entity::new(),
    cell_x: x,
    cell_y: y,
    timer: SOFT_WALL_BREAK_DURATION,
    anim: anim_playback_new(SoftWallBreak, false),
  })
}

///|
fn spawn_flame(x : Int, y : Int, kind : FlameKind) -> Unit {
  match flames.search_by(fn(flame) { flame.cell_x == x && flame.cell_y == y }) {
    Some(index) => {
      let flame = flames[index]
      flame.kind = kind
      flame.damage_timer = clamp_double(
        flame.damage_timer + FLAME_DAMAGE_DURATION,
        0.0,
        FLAME_DAMAGE_DURATION,
      )
      flame.visual_timer = clamp_double(
        flame.visual_timer + FLAME_VISUAL_DURATION,
        0.0,
        FLAME_VISUAL_DURATION,
      )
      flame.tail_phase = false
      flame.anim = anim_playback_new(flame_active_clip(kind), true)
    }
    None =>
      flames.push({
        entity: @entity.Entity::new(),
        cell_x: x,
        cell_y: y,
        kind,
        damage_timer: FLAME_DAMAGE_DURATION,
        visual_timer: FLAME_VISUAL_DURATION,
        tail_phase: false,
        anim: anim_playback_new(flame_active_clip(kind), true),
      })
  }
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
    None => drop_rng.val.double()
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
  let spawns = collect_explosion_spawns(bomb.cell_x, bomb.cell_y, bomb.radius)
  for spawn in spawns {
    let x = spawn.cell_x
    let y = spawn.cell_y
    if tile_at(x, y) == SoftWall {
      spawn_soft_wall_break(x, y)
      continue
    }
    for chained in bombs {
      if chained.cell_x == x && chained.cell_y == y {
        chained.timer = 0.0
      }
    }
    spawn_flame(x, y, spawn.kind)
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
    anim: anim_playback_new(BombFuse, true),
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
    MainMenu =>
      match menu_screen.val {
        MainRoot => "LEVEL \{current_level_number()} / \{levels.length()}"
        NetworkRoot => "NETWORK BATTLE"
        NetworkHostSetup => "CREATE ROOM"
        NetworkJoinSetup => "JOIN ROOM"
        NetworkLobby => "NETWORK LOBBY"
      }
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
      match menu_screen.val {
        MainRoot => "W/S or Up/Down: Mode   Enter/Space: Select   Esc: Exit"
        NetworkRoot =>
          "W/S or Up/Down: Option   Enter/Space: Select   Esc: Back"
        NetworkHostSetup =>
          "W/S: Field   A/D or Left/Right: Mode/Level   Digits: Port   Backspace: Delete   Enter: Create   Esc: Back"
        NetworkJoinSetup =>
          "W/S: Field   Type Host/Port   Backspace: Delete   Enter: Join   Esc: Back"
        NetworkLobby => "Waiting for handshake... Enter/Esc: Cancel"
      }
    Playing =>
      match current_mode.val {
        SinglePlayer =>
          "Move: WASD / Arrows   Bomb: Space   R: Restart   Esc: Menu"
        Coop | Versus =>
          match netplay_mode.val {
            Host =>
              "NET HOST   Local: P1 WASD+G   Remote: P2 IJKL+'   R: Restart   Esc: Menu"
            Client =>
              "NET CLIENT   Local: P2 IJKL+'   Remote: P1 WASD+G   R: Restart   Esc: Menu"
            Off | Loopback =>
              "P1: WASD + G   P2: IJKL + '   R: Restart   Esc: Menu"
          }
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
    MainMenu =>
      if menu_error_message.val != "" {
        menu_error_message.val
      } else {
        match menu_screen.val {
          MainRoot => "2 Players A = co-op, 2 Players B = versus."
          NetworkRoot => "Network battle supports Host(P1) + Client(P2)."
          NetworkHostSetup =>
            "Choose mode A/B, level, and port, then press Enter to create."
          NetworkJoinSetup =>
            "Enter host IP and port, then press Enter to join."
          NetworkLobby => {
            let lan = match lobby_local_ip.val {
              Some(ip) => ip
              None => "unavailable"
            }
            "MODE: \{lobby_mode_label.val}   LEVEL: \{current_level_number()}/\{levels.length()}   ROOM: \{lobby_endpoint_label.val}   LAN: \{lan}   LOOPBACK: 127.0.0.1   \{lobby_status_label.val}"
          }
        }
      }
    Playing =>
      match current_mode.val {
        SinglePlayer =>
          "Soft walls break. Hard walls block. Flames travel in a cross."
        Coop => {
          let net_suffix = if netplay_session.val is Some(_) &&
            (netplay_mode.val == Host || netplay_mode.val == Client) {
            match netplay_mode.val {
              Host => {
                let connected = match netplay_link.val {
                  Some(link) =>
                    if link.is_connected() {
                      "connected"
                    } else {
                      "waiting"
                    }
                  None => "waiting"
                }
                let running = match netplay_session.val {
                  Some(session) =>
                    if session.is_running() {
                      "running"
                    } else {
                      "syncing"
                    }
                  None => "syncing"
                }
                "   NET HOST \{connected}/\{running} port=\{netplay_port.val}"
              }
              Client => {
                let connected = match netplay_link.val {
                  Some(link) =>
                    if link.is_connected() {
                      "connected"
                    } else {
                      "waiting"
                    }
                  None => "waiting"
                }
                let running = match netplay_session.val {
                  Some(session) =>
                    if session.is_running() {
                      "running"
                    } else {
                      "syncing"
                    }
                  None => "syncing"
                }
                "   NET CLIENT \{connected}/\{running} to \{netplay_remote_host.val}:\{netplay_remote_port.val}"
              }
              Off => ""
              Loopback => ""
            }
          } else {
            ""
          }
          "Friendly fire is enabled. Clear all enemies with at least one player alive." +
          net_suffix
        }
        Versus => {
          let net_suffix = if netplay_session.val is Some(_) &&
            (netplay_mode.val == Host || netplay_mode.val == Client) {
            match netplay_mode.val {
              Host => "   NET HOST"
              Client => "   NET CLIENT"
              Off => ""
              Loopback => ""
            }
          } else {
            ""
          }
          "Friendly fire is enabled. Last survivor wins." + net_suffix
        }
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
      match tile_at(x, y) {
        Empty => {
          let color = if (x + y) % 2 == 0 {
            FLOOR_TILE_COLOR_A
          } else {
            FLOOR_TILE_COLOR_B
          }
          set_rect_entity(entity, floor_tile_position(x, y), size, color, 20)
        }
        HardWall =>
          set_atlas_entity_top_left(
            entity,
            floor_tile_position(x, y),
            size,
            SPRITE_HARD_WALL_COL,
            SPRITE_HARD_WALL_ROW,
            20,
          )
        SoftWall =>
          set_atlas_entity_top_left(
            entity,
            floor_tile_position(x, y),
            size,
            SPRITE_SOFT_WALL_COL,
            SPRITE_SOFT_WALL_ROW,
            20,
          )
      }
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
  let size = @math.Vec2D(BOMB_SPRITE_SIZE, BOMB_SPRITE_SIZE)
  for bomb in bombs {
    set_animated_atlas_entity_center(
      bomb.entity,
      cell_center(bomb.cell_x, bomb.cell_y),
      size,
      bomb.anim.clip_id,
      60,
    )
  }
}

///|
fn sync_flame_visuals() -> Unit {
  let size = @math.Vec2D(FLAME_SPRITE_SIZE, FLAME_SPRITE_SIZE)
  for flame in flames {
    set_animated_atlas_entity_center(
      flame.entity,
      cell_center(flame.cell_x, flame.cell_y),
      size,
      flame.anim.clip_id,
      70,
    )
  }
}

///|
fn sync_soft_wall_break_visuals() -> Unit {
  let size = floor_tile_size()
  for breaking in soft_wall_breaks {
    set_animated_atlas_entity_top_left(
      breaking.entity,
      floor_tile_position(breaking.cell_x, breaking.cell_y),
      size,
      breaking.anim.clip_id,
      45,
    )
  }
}

///|
fn sync_item_visuals() -> Unit {
  for item in items {
    let center = cell_center(item.cell_x, item.cell_y)
    let (icon_col, icon_row) = match item.kind {
      Shoes => (SPRITE_SHOES_COL, SPRITE_SHOES_ROW)
      BombUp => (SPRITE_BOMB_ITEM_COL, SPRITE_BOMB_ITEM_ROW)
      PowerUp => (SPRITE_POWER_ITEM_COL, SPRITE_POWER_ITEM_ROW)
    }
    set_circle_entity(
      item.entity,
      center,
      ITEM_BUBBLE_RADIUS,
      ITEM_BUBBLE_COLOR,
      62,
    )
    set_atlas_entity_center(
      item.label_entity,
      center,
      @math.Vec2D(ITEM_ICON_SIZE, ITEM_ICON_SIZE),
      icon_col,
      icon_row,
      63,
      tint=Some(item_color(item.kind)),
    )
  }
}

///|
fn sync_enemy_visuals() -> Unit {
  let size = @math.Vec2D(ENEMY_SPRITE_SIZE, ENEMY_SPRITE_SIZE)
  for enemy in enemies {
    if enemy.alive || !enemy.death_animation_done {
      set_animated_atlas_entity_center(
        enemy.entity,
        enemy.center,
        size,
        enemy.anim.clip_id,
        65,
        flip_x=enemy.flip_x,
      )
    } else {
      hide_entity(enemy.entity)
    }
  }
}

///|
fn sync_player_visuals() -> Unit {
  let size = @math.Vec2D(PLAYER_SPRITE_SIZE, PLAYER_SPRITE_SIZE)
  for player in players {
    if player.active {
      if player.alive || !player.death_animation_done {
        let tint = match player.id {
          P1 => None
          P2 => Some(player_color(player.id, player.alive))
        }
        set_animated_atlas_entity_center(
          player.entity,
          player.center,
          size,
          player.anim.clip_id,
          66,
          tint~,
          flip_x=player.flip_x,
        )
      } else {
        hide_entity(player.entity)
      }
    } else {
      hide_entity(player.entity)
    }
  }
}

///|
fn hide_gameplay_visuals() -> Unit {
  hide_tile_visuals()
  for breaking in soft_wall_breaks {
    hide_entity(breaking.entity)
  }
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
fn set_menu_entry(
  index : Int,
  text : String,
  y : Double,
  color : String,
) -> Unit {
  set_text_entity_center(
    menu_entities[index],
    text,
    @math.Vec2D(VIEWPORT_WIDTH / 2.0, y),
    "24px \{BOMBMAN_FONT_FAMILY}",
    color,
    200,
  )
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
  hide_menu_visuals()
  match menu_screen.val {
    MainRoot => {
      let options = menu_options()
      for index in 0..<options.length() {
        let option = options[index]
        let prefix = if option == menu_selection.val { "> " } else { "  " }
        let color = if option == menu_selection.val {
          MENU_SELECTED_COLOR
        } else {
          MENU_NORMAL_COLOR
        }
        set_menu_entry(
          index,
          prefix + menu_option_label(option),
          210.0 + index.to_double() * 38.0,
          color,
        )
      }
    }
    NetworkRoot => {
      let options : Array[NetworkRootOption] = [CreateRoom, JoinRoom, Back]
      for index in 0..<options.length() {
        let option = options[index]
        let prefix = if option == network_root_selection.val {
          "> "
        } else {
          "  "
        }
        let color = if option == network_root_selection.val {
          MENU_SELECTED_COLOR
        } else {
          MENU_NORMAL_COLOR
        }
        set_menu_entry(
          index,
          prefix + network_root_option_label(option),
          234.0 + index.to_double() * 42.0,
          color,
        )
      }
    }
    NetworkHostSetup => {
      let mode_prefix = if host_setup_focus.val == Mode { "> " } else { "  " }
      let level_prefix = if host_setup_focus.val == Level { "> " } else { "  " }
      let port_prefix = if host_setup_focus.val == Port { "> " } else { "  " }
      set_menu_entry(
        0,
        mode_prefix + "MODE: \{network_mode_short(host_setup_mode.val)}",
        220.0,
        if host_setup_focus.val == Mode {
          MENU_SELECTED_COLOR
        } else {
          MENU_NORMAL_COLOR
        },
      )
      set_menu_entry(
        1,
        level_prefix + "LEVEL: \{host_setup_level.val + 1} / \{levels.length()}",
        262.0,
        if host_setup_focus.val == Level {
          MENU_SELECTED_COLOR
        } else {
          MENU_NORMAL_COLOR
        },
      )
      set_menu_entry(
        2,
        port_prefix + "PORT: \{host_setup_port.val}",
        304.0,
        if host_setup_focus.val == Port {
          MENU_SELECTED_COLOR
        } else {
          MENU_NORMAL_COLOR
        },
      )
    }
    NetworkJoinSetup => {
      let host_prefix = if join_setup_focus.val == Host { "> " } else { "  " }
      let port_prefix = if join_setup_focus.val == Port { "> " } else { "  " }
      set_menu_entry(
        0,
        host_prefix + "HOST: \{join_setup_host.val}",
        220.0,
        if join_setup_focus.val == Host {
          MENU_SELECTED_COLOR
        } else {
          MENU_NORMAL_COLOR
        },
      )
      set_menu_entry(
        1,
        port_prefix + "PORT: \{join_setup_port.val}",
        262.0,
        if join_setup_focus.val == Port {
          MENU_SELECTED_COLOR
        } else {
          MENU_NORMAL_COLOR
        },
      )
      set_menu_entry(2, "ENTER: JOIN ROOM", 322.0, MENU_SELECTED_COLOR)
      set_menu_entry(3, "ESC: BACK", 364.0, MENU_NORMAL_COLOR)
    }
    NetworkLobby => {
      let lan = match lobby_local_ip.val {
        Some(ip) => ip
        None => "unavailable"
      }
      set_menu_entry(
        0,
        "MODE: \{lobby_mode_label.val}   LEVEL: \{current_level_number()}/\{levels.length()}",
        214.0,
        MENU_SELECTED_COLOR,
      )
      set_menu_entry(
        1,
        "ROOM: \{lobby_endpoint_label.val}",
        252.0,
        MENU_NORMAL_COLOR,
      )
      set_menu_entry(2, "LAN: \{lan}", 290.0, MENU_NORMAL_COLOR)
      set_menu_entry(3, "LOOPBACK: 127.0.0.1", 328.0, MENU_NORMAL_COLOR)
      set_menu_entry(4, "> CANCEL (ENTER/ESC)", 380.0, MENU_SELECTED_COLOR)
    }
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
      sync_soft_wall_break_visuals()
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

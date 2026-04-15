///|
const VIEWPORT_WIDTH : Double = 800.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const ZOOM : Double = 1.0

///|
const ARENA_COLS : Int = 15

///|
const ARENA_ROWS : Int = 13

///|
const TILE_SIZE : Double = 40.0

///|
const ARENA_ORIGIN_X : Double = 100.0

///|
const ARENA_ORIGIN_Y : Double = 120.0

///|
const HUD_BOTTOM_Y : Double = VIEWPORT_HEIGHT - 36.0

///|
const PLAYER_RADIUS : Double = 14.0

///|
const ENEMY_RADIUS : Double = 14.0

///|
const BULLET_RADIUS : Double = 4.0

///|
const PLAYER_SPEED : Double = 92.0

///|
const ENEMY_SPEED : Double = 48.0

///|
const BULLET_SPEED : Double = 240.0

///|
const PLAYER_SHOT_COOLDOWN : Double = 0.26

///|
const ENEMY_SHOT_COOLDOWN : Double = 2.2

///|
const ENEMY_THINK_INTERVAL : Double = 0.22

///|
const WALL_COLOR : String = "rgb(90, 112, 138)"

///|
const BRICK_COLOR : String = "rgb(180, 104, 64)"

///|
const FLOOR_COLOR : String = "rgb(38, 50, 62)"

///|
const PLAYER_COLOR : String = "rgb(74, 203, 255)"

///|
const PLAYER_BARREL_COLOR : String = "rgb(36, 145, 186)"

///|
const ENEMY_COLOR : String = "rgb(255, 92, 92)"

///|
const ENEMY_BARREL_COLOR : String = "rgb(182, 50, 50)"

///|
const BULLET_PLAYER_COLOR : String = "rgb(255, 232, 121)"

///|
const BULLET_ENEMY_COLOR : String = "rgb(255, 193, 96)"

///|
const HUD_TEXT_COLOR : String = "rgb(240, 244, 248)"

///|
const HUD_MUTED_COLOR : String = "rgb(171, 181, 189)"

///|
const TITLE_COLOR : String = "rgb(255, 225, 136)"

///|
const TANKBATTLE_FONT_FAMILY : String = "MGS1Codec"

///|
const TANKBATTLE_FONT_PATH : String = "assets/shared/fonts/mgs1codec.ttf"

///|
const DEBUG_ENV : String = "TANKBATTLE_CAPTURE"

///|
const DEBUG_CAPTURE_PATH : String = "tankbattle_capture.png"

///|
const DEBUG_CAPTURE_DELAY_SECONDS : Double = 2.0

///|
const PROFILE_ENV : String = "TANKBATTLE_PROFILE"

///|
const TANK_HALF_SIZE : Double = 14.0

///|
const BARREL_LENGTH : Double = 20.0

///|
const BARREL_THICKNESS : Double = 6.0

///|
const BOARD_Z : Int = 0

///|
const PLAYER_Z : Int = 50

///|
const ENEMY_Z : Int = 50

///|
const BULLET_Z : Int = 60

///|
const HUD_Z : Int = 200

///|
const TILE_Z_BASE : Int = 5

///|
const TILE_EMPTY : Int = 0

///|
const TILE_STEEL : Int = 1

///|
const TILE_BRICK : Int = 2

///|
priv enum TileKind {
  Floor
  Steel
  Brick
} derive(Eq)

///|
priv enum GamePhase {
  MainMenu
  Playing
  RoundOver
} derive(Eq)

///|
priv enum MenuOption {
  Start
  Exit
} derive(Eq)

///|
priv enum RoundOutcome {
  Victory
  Defeat
}

///|
priv enum Direction {
  Up
  Down
  Left
  Right
}

///|
priv enum BulletOwner {
  Player
  Enemy
}

///|
priv struct Rect {
  x : Double
  y : Double
  width : Double
  height : Double
}

///|
priv struct PlayerState {
  mut alive : Bool
  mut center : @math.Vec2
  mut direction : Direction
  mut turret_direction : Direction
  mut reload_timer : Double
}

///|
priv struct EnemyState {
  mut alive : Bool
  mut center : @math.Vec2
  mut direction : Direction
  mut turret_direction : Direction
  mut reload_timer : Double
  mut think_timer : Double
}

///|
priv struct BulletState {
  mut center : @math.Vec2
  direction : Direction
  speed : Double
  mut life_time : Double
  owner : BulletOwner
  entity : @entity.Entity
}

///|
priv struct LevelConfig {
  name : String
  tiles : Array[Array[Int]]
  player_spawn : @math.Vec2
  enemy_spawns : Array[@math.Vec2]
}

///|
priv struct ProceduralSounds {
  shoot : @host.Sound
  hit : @host.Sound
  boom : @host.Sound
  win : @host.Sound
  lose : @host.Sound
}

///|
let phase : Ref[GamePhase] = { val: MainMenu }

///|
let tankbattle_font_registered : Ref[Bool] = { val: false }

///|
let current_level : Ref[Int] = { val: 0 }

///|
let current_menu_option : Ref[MenuOption] = { val: Start }

///|
let round_outcome : Ref[RoundOutcome] = { val: Victory }

///|
let debug_fps_enabled : Ref[Bool] = { val: false }

///|
let debug_capture_enabled : Ref[Bool] = { val: false }

///|
let debug_capture_started_at : Ref[Double] = { val: 0.0 }

///|
let debug_capture_taken : Ref[Bool] = { val: false }

///|
let debug_capture_forced_start : Ref[Bool] = { val: false }

///|
let profile_enabled : Ref[Bool] = { val: false }

///|
let profile_started_at : Ref[Double] = { val: 0.0 }

///|
let profile_last_report_at : Ref[Double] = { val: 0.0 }

///|
let profile_frame_count : Ref[Int] = { val: 0 }

///|
let profile_input_total : Ref[Double] = { val: 0.0 }

///|
let profile_sim_total : Ref[Double] = { val: 0.0 }

///|
let profile_render_total : Ref[Double] = { val: 0.0 }

///|
let profile_slowest_frame : Ref[Double] = { val: 0.0 }

///|
let tiles : Array[TileKind] = []

///|
let tile_entities : Array[@entity.Entity] = []

///|
let bullet_entities : Array[@entity.Entity] = []

///|
let bullets : Array[BulletState] = []

///|
let player : PlayerState = {
  alive: false,
  center: @math.Vec2(0.0, 0.0),
  direction: Up,
  turret_direction: Up,
  reload_timer: 0.0,
}

///|
let enemies : Array[EnemyState] = [
  {
    alive: false,
    center: @math.Vec2(0.0, 0.0),
    direction: Down,
    turret_direction: Down,
    reload_timer: 0.0,
    think_timer: 0.0,
  },
  {
    alive: false,
    center: @math.Vec2(0.0, 0.0),
    direction: Down,
    turret_direction: Down,
    reload_timer: 0.0,
    think_timer: 0.0,
  },
  {
    alive: false,
    center: @math.Vec2(0.0, 0.0),
    direction: Down,
    turret_direction: Down,
    reload_timer: 0.0,
    think_timer: 0.0,
  },
  {
    alive: false,
    center: @math.Vec2(0.0, 0.0),
    direction: Down,
    turret_direction: Down,
    reload_timer: 0.0,
    think_timer: 0.0,
  },
]

///|
let enemy_body_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let enemy_barrel_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let player_body_entity : @entity.Entity = @entity.Entity::new()

///|
let player_barrel_entity : @entity.Entity = @entity.Entity::new()

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let status_entity : @entity.Entity = @entity.Entity::new()

///|
let hint_entity : @entity.Entity = @entity.Entity::new()

///|
let round_entity : @entity.Entity = @entity.Entity::new()

///|
let fps_entity : @entity.Entity = @entity.Entity::new()

///|
let menu_option_entities : Array[@entity.Entity] = [
  @entity.Entity::new(),
  @entity.Entity::new(),
]

///|
let last_title_text : Ref[String] = { val: "" }

///|
let last_status_text : Ref[String] = { val: "" }

///|
let last_round_text : Ref[String] = { val: "" }

///|
let last_hint_text : Ref[String] = { val: "" }

///|
let last_fps_text : Ref[String] = { val: "" }

///|
let last_menu_start_text : Ref[String] = { val: "" }

///|
let last_menu_exit_text : Ref[String] = { val: "" }

///|
let background_entity : @entity.Entity = @entity.Entity::new()

///|
let box_entity : @entity.Entity = @entity.Entity::new()

///|
let sound_bank : Ref[ProceduralSounds?] = { val: None }

///|
let levels : Array[LevelConfig] = []

///|
let key_stamp_up : Ref[Int] = { val: 0 }

///|
let key_stamp_down : Ref[Int] = { val: 0 }

///|
let key_stamp_left : Ref[Int] = { val: 0 }

///|
let key_stamp_right : Ref[Int] = { val: 0 }

///|
let key_stamp_counter : Ref[Int] = { val: 0 }

///|
fn vec2(x : Double, y : Double) -> @math.Vec2 {
  @math.Vec2(x, y)
}

///|
fn clamp_double(value : Double, min_ : Double, max_ : Double) -> Double {
  if value < min_ {
    min_
  } else if value > max_ {
    max_
  } else {
    value
  }
}

///|
fn clamp_int(value : Int, min_ : Int, max_ : Int) -> Int {
  if value < min_ {
    min_
  } else if value > max_ {
    max_
  } else {
    value
  }
}

///|
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
fn direction_vector(direction : Direction) -> @math.Vec2 {
  match direction {
    Up => vec2(0.0, -1.0)
    Down => vec2(0.0, 1.0)
    Left => vec2(-1.0, 0.0)
    Right => vec2(1.0, 0.0)
  }
}

///|
fn direction_to_angle(direction : Direction) -> Double {
  match direction {
    Up => -@cmath.PI * 0.5
    Down => @cmath.PI * 0.5
    Left => @cmath.PI
    Right => 0.0
  }
}

///|
fn opposite_direction(direction : Direction) -> Direction {
  match direction {
    Up => Down
    Down => Up
    Left => Right
    Right => Left
  }
}

///|
fn tile_index(x : Int, y : Int) -> Int {
  y * ARENA_COLS + x
}

///|
fn tile_in_bounds(x : Int, y : Int) -> Bool {
  x >= 0 && x < ARENA_COLS && y >= 0 && y < ARENA_ROWS
}

///|
fn world_to_grid(point : @math.Vec2) -> (Int, Int) {
  let x = ((point[X] - ARENA_ORIGIN_X) / TILE_SIZE).floor().to_int()
  let y = ((point[Y] - ARENA_ORIGIN_Y) / TILE_SIZE).floor().to_int()
  (x, y)
}

///|
fn grid_to_world_center(x : Int, y : Int) -> @math.Vec2 {
  vec2(
    ARENA_ORIGIN_X + (x.to_double() + 0.5) * TILE_SIZE,
    ARENA_ORIGIN_Y + (y.to_double() + 0.5) * TILE_SIZE,
  )
}

///|
fn tile_rect(x : Int, y : Int) -> Rect {
  {
    x: ARENA_ORIGIN_X + x.to_double() * TILE_SIZE,
    y: ARENA_ORIGIN_Y + y.to_double() * TILE_SIZE,
    width: TILE_SIZE,
    height: TILE_SIZE,
  }
}

///|
fn tile_kind_for(code : Int) -> TileKind {
  match code {
    TILE_STEEL => Steel
    TILE_BRICK => Brick
    _ => Floor
  }
}

///|
fn tile_is_solid(tile : TileKind) -> Bool {
  match tile {
    Floor => false
    Steel | Brick => true
  }
}

///|
fn tile_blocks_bullet(tile : TileKind) -> Bool {
  match tile {
    Floor => false
    Steel | Brick => true
  }
}

///|
fn tile_at(x : Int, y : Int) -> TileKind {
  if !tile_in_bounds(x, y) {
    return Steel
  }
  tiles[tile_index(x, y)]
}

///|
fn set_tile(x : Int, y : Int, tile : TileKind) -> Unit {
  if !tile_in_bounds(x, y) {
    return
  }
  tiles[tile_index(x, y)] = tile
}

///|
fn set_tile_code(x : Int, y : Int, code : Int) -> Unit {
  set_tile(x, y, tile_kind_for(code))
}

///|
fn clear_tiles() -> Unit {
  tiles.clear()
  for _ in 0..<(ARENA_COLS * ARENA_ROWS) {
    tiles.push(Floor)
  }
}

///|
fn clear_bullets() -> Unit {
  for bullet in bullets {
    bullet.entity.destroy()
  }
  bullets.clear()
  bullet_entities.clear()
}

///|
fn append_byte(buf : Array[Byte], value : Int) -> Unit {
  buf.push(value.to_byte())
}

///|
fn append_u16_le(buf : Array[Byte], value : Int) -> Unit {
  append_byte(buf, value % 256)
  append_byte(buf, value / 256)
}

///|
fn append_u32_le(buf : Array[Byte], value : Int) -> Unit {
  append_byte(buf, value % 256)
  append_byte(buf, value / 256 % 256)
  append_byte(buf, value / 65536 % 256)
  append_byte(buf, value / 16777216 % 256)
}

///|
fn append_fourcc(buf : Array[Byte], a : Int, b : Int, c : Int, d : Int) -> Unit {
  append_byte(buf, a)
  append_byte(buf, b)
  append_byte(buf, c)
  append_byte(buf, d)
}

///|
fn hide_enemy(index : Int) -> Unit {
  enemies[index].alive = false
}

///|
fn hide_all_enemies() -> Unit {
  for i in 0..<enemies.length() {
    hide_enemy(i)
  }
}

///|
fn reset_direction_stamps() -> Unit {
  key_stamp_up.val = 0
  key_stamp_down.val = 0
  key_stamp_left.val = 0
  key_stamp_right.val = 0
  key_stamp_counter.val = 0
}

///|
fn make_tone_wav_bytes(
  freq : Double,
  duration_sec : Double,
  volume : Double,
) -> Bytes {
  let sample_rate = 22050
  let channels = 1
  let bits_per_sample = 16
  let sample_count = (duration_sec * sample_rate.to_double()).to_int()
  let data_bytes = sample_count * 2
  let total_bytes = 44 + data_bytes
  let out : Array[Byte] = []

  append_fourcc(out, 82, 73, 70, 70)
  append_u32_le(out, total_bytes - 8)
  append_fourcc(out, 87, 65, 86, 69)
  append_fourcc(out, 102, 109, 116, 32)
  append_u32_le(out, 16)
  append_u16_le(out, 1)
  append_u16_le(out, channels)
  append_u32_le(out, sample_rate)
  append_u32_le(out, sample_rate * channels * bits_per_sample / 8)
  append_u16_le(out, channels * bits_per_sample / 8)
  append_u16_le(out, bits_per_sample)
  append_fourcc(out, 100, 97, 116, 97)
  append_u32_le(out, data_bytes)

  let pi2 = @cmath.PI * 2.0
  for i in 0..<sample_count {
    let t = i.to_double() / sample_rate.to_double()
    let env = if duration_sec <= 0.0 {
      1.0
    } else {
      let progress = i.to_double() / sample_count.to_double()
      let attack = if progress < 0.12 { progress / 0.12 } else { 1.0 }
      let release = if progress > 0.72 {
        1.0 - (progress - 0.72) / 0.28
      } else {
        1.0
      }
      clamp_double(attack * release, 0.0, 1.0)
    }
    let sample = @cmath.sin(pi2 * freq * t) * volume * env
    let clamped = clamp_double(sample, -1.0, 1.0)
    let int_sample = (clamped * 32767.0).to_int()
    let lo = int_sample & 0xFF
    let hi = (int_sample >> 8) & 0xFF
    append_byte(out, lo)
    append_byte(out, hi)
  }

  Bytes::from_array(out)
}

///|
fn load_tone_sound(
  freq : Double,
  duration_sec : Double,
  volume : Double,
) -> @host.Sound {
  let wav = make_tone_wav_bytes(freq, duration_sec, volume)
  @host.sound_from_wav_bytes(wav)
}

///|
fn init_sound_bank_once() -> Unit {
  if sound_bank.val is Some(_) {
    return
  }
  sound_bank.val = Some({
    shoot: load_tone_sound(950.0, 0.08, 0.55),
    hit: load_tone_sound(180.0, 0.11, 0.65),
    boom: load_tone_sound(90.0, 0.16, 0.7),
    win: load_tone_sound(660.0, 0.18, 0.6),
    lose: load_tone_sound(120.0, 0.22, 0.6),
  })
}

///|
fn play_sound(sound : @host.Sound) -> Unit {
  @host.play_sound(sound)
}

///|
fn play_shoot_sound() -> Unit {
  match sound_bank.val {
    Some(bank) => play_sound(bank.shoot)
    None => ()
  }
}

///|
fn play_hit_sound() -> Unit {
  match sound_bank.val {
    Some(bank) => play_sound(bank.hit)
    None => ()
  }
}

///|
fn play_boom_sound() -> Unit {
  match sound_bank.val {
    Some(bank) => play_sound(bank.boom)
    None => ()
  }
}

///|
fn play_win_sound() -> Unit {
  match sound_bank.val {
    Some(bank) => play_sound(bank.win)
    None => ()
  }
}

///|
fn play_lose_sound() -> Unit {
  match sound_bank.val {
    Some(bank) => play_sound(bank.lose)
    None => ()
  }
}

///|
fn entity_transform_2d(
  position : @math.Vec2,
  zindex : Int,
) -> @transform.Transform {
  {
    translation: @math.Vec3::new(position[X], position[Y], zindex.to_double()),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  }
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn show_entity(entity : @entity.Entity) -> Unit {
  @visibility.visibilities().set(entity, Visible)
}

///|
fn hide_entity(entity : @entity.Entity) -> Unit {
  @visibility.visibilities().set(entity, Hidden)
}

///|
fn register_tankbattle_font_once() -> Unit {
  if tankbattle_font_registered.val {
    return
  }
  ignore(@asset.load_font(TANKBATTLE_FONT_PATH, family=TANKBATTLE_FONT_FAMILY))
  tankbattle_font_registered.val = true
}

///|
fn set_rect_entity(
  entity : @entity.Entity,
  position : @math.Vec2,
  size : @math.Vec2,
  color : String,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_color(@sprite.color_from_css(color), size)
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  let top_left = vec2(position[X] - size[X] * 0.5, position[Y] - size[Y] * 0.5)
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, entity_transform_2d(top_left, zindex))
  show_entity(entity)
}

///|
fn set_text_entity_center(
  entity : @entity.Entity,
  text : String,
  position : @math.Vec2,
  color : String,
  size : Double,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  @ui.texts().set(entity, @ui.Text::new(text))
  @ui.text_fonts().set(
    entity,
    @ui.TextFont::new(family=TANKBATTLE_FONT_FAMILY, size~),
  )
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Center, baseline=Center, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(0.0, 0.0)))
  @transform.transforms().set(entity, entity_transform_2d(position, zindex))
  show_entity(entity)
}

///|
fn update_text_entity(entity : @entity.Entity, text : String) -> Unit {
  @ui.texts().set(entity, @ui.Text::new(text))
}

///|
fn update_text_entity_if_changed(
  entity : @entity.Entity,
  cache : Ref[String],
  text : String,
) -> Unit {
  if cache.val != text {
    cache.val = text
    update_text_entity(entity, text)
  }
}

///|
fn circle_overlaps_rect(
  center : @math.Vec2,
  radius : Double,
  rect : Rect,
) -> Bool {
  let nearest_x = clamp_double(center[X], rect.x, rect.x + rect.width)
  let nearest_y = clamp_double(center[Y], rect.y, rect.y + rect.height)
  let dx = center[X] - nearest_x
  let dy = center[Y] - nearest_y
  dx * dx + dy * dy <= radius * radius
}

///|
fn circle_overlaps_circle(
  a_center : @math.Vec2,
  a_radius : Double,
  b_center : @math.Vec2,
  b_radius : Double,
) -> Bool {
  let dx = a_center[X] - b_center[X]
  let dy = a_center[Y] - b_center[Y]
  dx * dx + dy * dy <= (a_radius + b_radius) * (a_radius + b_radius)
}

///|
fn row_open(x : Int, y : Int) -> Bool {
  x <= 2 || x >= ARENA_COLS - 3 || y <= 2 || y >= ARENA_ROWS - 3
}

///|
fn make_level(variant : Int) -> LevelConfig {
  let tiles_2d : Array[Array[Int]] = []
  for y in 0..<ARENA_ROWS {
    let row : Array[Int] = []
    for x in 0..<ARENA_COLS {
      let code = if x == 0 ||
        y == 0 ||
        x == ARENA_COLS - 1 ||
        y == ARENA_ROWS - 1 {
        TILE_STEEL
      } else if x % 4 == 0 && y % 4 == 0 {
        TILE_STEEL
      } else if row_open(x, y) {
        TILE_EMPTY
      } else if (x * 11 + y * 7 + variant * 5) % 6 <= 2 {
        TILE_BRICK
      } else {
        TILE_EMPTY
      }
      row.push(code)
    }
    tiles_2d.push(row)
  }

  let player_spawn = grid_to_world_center(1, ARENA_ROWS - 2)
  let enemy_spawns : Array[@math.Vec2] = [
    grid_to_world_center(ARENA_COLS - 2, 1),
    grid_to_world_center(ARENA_COLS - 2, ARENA_ROWS - 2),
    grid_to_world_center(ARENA_COLS / 2, 1),
    grid_to_world_center(ARENA_COLS / 2, ARENA_ROWS - 2),
  ]

  // Open the spawn zones and a few lanes so every level is immediately playable.
  let clear_cells : Array[(Int, Int)] = [
    (1, ARENA_ROWS - 2),
    (1, ARENA_ROWS - 3),
    (2, ARENA_ROWS - 2),
    (1, 1),
    (1, 2),
    (ARENA_COLS - 2, 1),
    (ARENA_COLS - 3, 1),
    (ARENA_COLS - 2, ARENA_ROWS - 2),
    (ARENA_COLS - 3, ARENA_ROWS - 2),
    (ARENA_COLS / 2, 1),
    (ARENA_COLS / 2, 2),
    (ARENA_COLS / 2, ARENA_ROWS - 2),
    (ARENA_COLS / 2, ARENA_ROWS - 3),
  ]
  for cell in clear_cells {
    let (x, y) = cell
    if tile_in_bounds(x, y) {
      tiles_2d[y][x] = TILE_EMPTY
    }
  }

  {
    name: "Arena " + (variant + 1).to_string(),
    tiles: tiles_2d,
    player_spawn,
    enemy_spawns,
  }
}

///|
fn init_levels_once() -> Unit {
  if levels.length() > 0 {
    return
  }
  levels.push(make_level(0))
  levels.push(make_level(1))
  levels.push(make_level(2))
}

///|
fn level_count() -> Int {
  levels.length()
}

///|
fn level_at(index : Int) -> LevelConfig {
  levels[clamp_int(index, 0, levels.length() - 1)]
}

///|
fn previous_level_index(index : Int) -> Int {
  if level_count() == 0 {
    0
  } else if index <= 0 {
    level_count() - 1
  } else {
    index - 1
  }
}

///|
fn next_level_index(index : Int) -> Int {
  if level_count() == 0 {
    0
  } else {
    (index + 1) % level_count()
  }
}

///|
fn previous_menu_option(option : MenuOption) -> MenuOption {
  match option {
    Start => Exit
    Exit => Start
  }
}

///|
fn next_menu_option(option : MenuOption) -> MenuOption {
  previous_menu_option(option)
}

///|
fn env_flag_enabled(name : String) -> Bool {
  match @env.get_env_var(name) {
    Some(raw) =>
      raw == "1" ||
      raw == "true" ||
      raw == "TRUE" ||
      raw == "yes" ||
      raw == "YES" ||
      raw == "on" ||
      raw == "ON"
    None => false
  }
}

///|
fn set_capture_from_env() -> Unit {
  debug_capture_enabled.val = env_flag_enabled(DEBUG_ENV)
  debug_capture_started_at.val = @time.elapsed()
  debug_capture_taken.val = false
  debug_capture_forced_start.val = false
}

///|
fn set_profile_from_env() -> Unit {
  profile_enabled.val = env_flag_enabled(PROFILE_ENV)
}

///|
fn set_menu_option(option : MenuOption) -> Unit {
  current_menu_option.val = option
}

///|
fn round_title() -> String {
  match round_outcome.val {
    Victory => "MISSION COMPLETE"
    Defeat => "TANK DESTROYED"
  }
}

///|
fn phase_label() -> String {
  match phase.val {
    MainMenu => "MAIN MENU"
    Playing => "PLAYING"
    RoundOver => "ROUND OVER"
  }
}

///|
fn tank_angle(direction : Direction) -> Double {
  direction_to_angle(direction)
}

///|
fn tank_barrel_position(
  center : @math.Vec2,
  direction : Direction,
) -> @math.Vec2 {
  let v = direction_vector(direction)
  vec2(center[X] + v[X] * 16.0, center[Y] + v[Y] * 16.0)
}

///|
fn spawn_bullet_entity(
  center : @math.Vec2,
  direction : Direction,
  owner : BulletOwner,
) -> Unit {
  let entity = @entity.Entity::new()
  bullet_entities.push(entity)
  bullets.push({
    center,
    direction,
    speed: BULLET_SPEED,
    life_time: 0.0,
    owner,
    entity,
  })
}

///|
fn tank_body_size() -> @math.Vec2 {
  vec2(TANK_HALF_SIZE * 2.0, TANK_HALF_SIZE * 2.0)
}

///|
fn tank_barrel_size() -> @math.Vec2 {
  vec2(BARREL_LENGTH, BARREL_THICKNESS)
}

///|
fn bullet_size() -> @math.Vec2 {
  vec2(8.0, 8.0)
}

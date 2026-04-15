///|
const VIEWPORT_WIDTH : Double = 1280.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const DEBUG_CAPTURE_ENV : String = "JACKAL_CAPTURE"

///|
const DEBUG_CAPTURE_PATH : String = "jackal_capture.png"

///|
const DEBUG_CAPTURE_DELAY_SECONDS : Double = 2.2

///|
const DEBUG_PROFILE_ENV : String = "JACKAL_PROFILE"

///|
const PROFILE_REPORT_SECONDS : Double = 1.0

///|
const WORLD_WIDTH : Double = 1280.0

///|
const WORLD_HEIGHT : Double = 720.0

///|
const PLAYER_RADIUS : Double = 15.5

///|
const PLAYER_SPEED : Double = 170.0

///|
const PLAYER_HP_MAX : Int = 3

///|
const PLAYER_LIVES_MAX : Int = 3

///|
const PLAYER_FIRE_COOLDOWN : Double = 0.18

///|
const PLAYER_RESPAWN_INVULN : Double = 1.2

///|
const BULLET_RADIUS : Double = 4.0

///|
const BULLET_SPEED : Double = 380.0

///|
const BULLET_TTL : Double = 2.0

///|
const ENEMY_RADIUS : Double = 14.0

///|
const SOLDIER_SPEED : Double = 80.0

///|
const SOLDIER_FIRE_COOLDOWN : Double = 1.2

///|
const TURRET_FIRE_COOLDOWN : Double = 1.0

///|
const ENEMY_HP : Int = 1

///|
const TURRET_HP : Int = 2

///|
const INITIAL_WAVE_COUNT : Int = 4

///|
const INITIAL_WAVE_READY_DELAY : Double = 1.8

///|
const HUD_Z : Int = 220

///|
const FLOOR_Z : Int = 0

///|
const OBJECT_Z : Int = 20

///|
const BULLET_Z : Int = 30

///|
const PLAYER_Z : Int = 40

///|
const ENEMY_Z : Int = 40

///|
const GOAL_Z : Int = 12

///|
const WORLD_MIN_X : Double = 0.0

///|
const WORLD_MIN_Y : Double = 0.0

///|
const WORLD_MAX_X : Double = 1280.0

///|
const WORLD_MAX_Y : Double = 720.0

///|
let player_spawn : @math.Vec2 = @math.Vec2(640.0, 620.0)

///|
let extraction_zone : @math.Rect = {
  position: @math.Vec2(542.0, 16.0),
  size: @math.Vec2(196.0, 92.0),
}

///|
priv enum GamePhase {
  Playing
  Won
  Lost
} derive(Eq)

///|
priv enum Facing {
  Up
  Down
  Left
  Right
}

///|
priv enum EnemyKind {
  Soldier
  Turret
} derive(Eq)

///|
priv enum BulletOwner {
  Player
  Enemy
}

///|
priv enum ObstacleKind {
  Rock
  Crate
} derive(Eq)

///|
priv struct PlayerState {
  entity : @entity.Entity
  mut pos : @math.Vec2
  mut facing : Facing
  mut hp : Int
  mut lives : Int
  mut fire_cd : Double
  mut invuln : Double
  mut alive : Bool
}

///|
priv struct EnemyState {
  entity : @entity.Entity
  kind : EnemyKind
  mut pos : @math.Vec2
  mut facing : Facing
  mut hp : Int
  mut fire_cd : Double
  mut alive : Bool
}

///|
priv struct BulletState {
  entity : @entity.Entity
  owner : BulletOwner
  mut pos : @math.Vec2
  vel : @math.Vec2
  mut ttl : Double
  mut alive : Bool
}

///|
priv struct ObstacleState {
  entity : @entity.Entity
  rect : @math.Rect
  kind : ObstacleKind
  mut hp : Int
  mut alive : Bool
}

///|
priv struct WaveState {
  mut index : Int
  mut spawn_left : Int
  mut spawn_timer : Double
  mut ready_timer : Double
  mut extraction_open : Bool
}

///|
priv struct GameState {
  mut phase : GamePhase
  mut score : Int
  mut best_streak : Int
  mut streak : Int
  mut debug_overlay : Bool
  mut capture_enabled : Bool
  mut capture_started_at : Double
  mut capture_taken : Bool
  mut profile_enabled : Bool
  mut profile_started_at : Double
  mut profile_last_report_at : Double
  mut profile_frame_count : Int
}

///|
let game_state : GameState = {
  phase: Playing,
  score: 0,
  best_streak: 0,
  streak: 0,
  debug_overlay: false,
  capture_enabled: false,
  capture_started_at: 0.0,
  capture_taken: false,
  profile_enabled: false,
  profile_started_at: 0.0,
  profile_last_report_at: 0.0,
  profile_frame_count: 0,
}

///|
let player_state : PlayerState = {
  entity: @entity.Entity::new(),
  pos: player_spawn,
  facing: Up,
  hp: PLAYER_HP_MAX,
  lives: PLAYER_LIVES_MAX,
  fire_cd: 0.0,
  invuln: 0.0,
  alive: true,
}

///|
let wave_state : WaveState = {
  index: 0,
  spawn_left: 0,
  spawn_timer: 0.0,
  ready_timer: 0.0,
  extraction_open: false,
}

///|
let enemy_states : Array[EnemyState] = []

///|
let bullet_states : Array[BulletState] = []

///|
let obstacle_states : Array[ObstacleState] = []

///|
let obstacle_rect_cache : Array[@math.Rect] = []

///|
let floor_entity : @entity.Entity = @entity.Entity::new()

///|
let extraction_entity : @entity.Entity = @entity.Entity::new()

///|
let title_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_entity : @entity.Entity = @entity.Entity::new()

///|
let message_entity : @entity.Entity = @entity.Entity::new()

///|
let debug_entity : @entity.Entity = @entity.Entity::new()

///|
let shoot_sound : Ref[@host.Sound?] = { val: None }

///|
let hit_sound : Ref[@host.Sound?] = { val: None }

///|
let boom_sound : Ref[@host.Sound?] = { val: None }

///|
let win_sound : Ref[@host.Sound?] = { val: None }

///|
let lose_sound : Ref[@host.Sound?] = { val: None }

///|
let decorative_entities : Array[@entity.Entity] = []

///|
let all_enemy_spawn_points : Array[@math.Vec2] = [
  @math.Vec2(120.0, 72.0),
  @math.Vec2(640.0, 72.0),
  @math.Vec2(1160.0, 72.0),
  @math.Vec2(80.0, 240.0),
  @math.Vec2(1200.0, 240.0),
]

///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
fn color_rgb(r : UInt, g : UInt, b : UInt) -> @render.Color {
  color_rgba(r, g, b, 1.0)
}

///|
fn rotation_z(angle : Double) -> @math.Quat {
  @math.Quat::from_axis_angle(@math.Vec3::z_axis(), angle)
}

///|
fn world_transform_2d(
  position : @math.Vec2,
  zindex : Int,
  rotation? : Double = 0.0,
) -> @transform.Transform {
  let transform = @transform.Transform::from_xyz(
    position[X],
    position[Y],
    zindex.to_double(),
  )
  if rotation == 0.0 {
    transform
  } else {
    transform.with_rotation(rotation_z(rotation))
  }
}

///|
fn center_of_rect(rect : @math.Rect) -> @math.Vec2 {
  @math.Vec2(
    rect.position[X] + rect.size[X] * 0.5,
    rect.position[Y] + rect.size[Y] * 0.5,
  )
}

///|
fn make_rect(x : Double, y : Double, w : Double, h : Double) -> @math.Rect {
  { position: @math.Vec2(x, y), size: @math.Vec2(w, h) }
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
fn vec_length(value : @math.Vec2) -> Double {
  value.dot(value).sqrt()
}

///|
fn vec_normalize(value : @math.Vec2) -> @math.Vec2 {
  let length = vec_length(value)
  if length <= 0.000001 {
    @math.Vec2::zero()
  } else {
    value.scalar_div(length)
  }
}

///|
fn moving_direction(angle : Facing) -> @math.Vec2 {
  match angle {
    Up => @math.Vec2(0.0, -1.0)
    Down => @math.Vec2(0.0, 1.0)
    Left => @math.Vec2(-1.0, 0.0)
    Right => @math.Vec2(1.0, 0.0)
  }
}

///|
fn facing_from_vector(vector : @math.Vec2) -> Facing {
  if vector[X].abs() > vector[Y].abs() {
    if vector[X] >= 0.0 {
      Right
    } else {
      Left
    }
  } else if vector[Y] >= 0.0 {
    Down
  } else {
    Up
  }
}

///|
fn facing_angle(facing : Facing) -> Double {
  match facing {
    Up => -@cmath.PI / 2.0
    Down => @cmath.PI / 2.0
    Left => @cmath.PI
    Right => 0.0
  }
}

///|
fn rect_intersects_circle(
  rect : @math.Rect,
  center : @math.Vec2,
  radius : Double,
) -> Bool {
  let closest_x = clamp_double(
    center[X],
    rect.position[X],
    rect.position[X] + rect.size[X],
  )
  let closest_y = clamp_double(
    center[Y],
    rect.position[Y],
    rect.position[Y] + rect.size[Y],
  )
  let dx = center[X] - closest_x
  let dy = center[Y] - closest_y
  dx * dx + dy * dy <= radius * radius
}

///|
fn circle_intersects_circle(
  a_center : @math.Vec2,
  a_radius : Double,
  b_center : @math.Vec2,
  b_radius : Double,
) -> Bool {
  let dx = a_center[X] - b_center[X]
  let dy = a_center[Y] - b_center[Y]
  let sum = a_radius + b_radius
  dx * dx + dy * dy <= sum * sum
}

///|
fn body_rect_for(center : @math.Vec2, radius : Double) -> @math.Rect {
  make_rect(center[X] - radius, center[Y] - radius, radius * 2.0, radius * 2.0)
}

///|
fn in_world(center : @math.Vec2, radius : Double) -> @math.Vec2 {
  @math.Vec2(
    clamp_double(center[X], WORLD_MIN_X + radius, WORLD_MAX_X - radius),
    clamp_double(center[Y], WORLD_MIN_Y + radius, WORLD_MAX_Y - radius),
  )
}

///|
fn is_capture_enabled() -> Bool {
  match @env.get_env_var(DEBUG_CAPTURE_ENV) {
    Some(raw) =>
      raw == "1" ||
      raw == "true" ||
      raw == "TRUE" ||
      raw == "yes" ||
      raw == "on"
    None => false
  }
}

///|
fn is_profile_enabled() -> Bool {
  match @env.get_env_var(DEBUG_PROFILE_ENV) {
    Some(raw) =>
      raw == "1" ||
      raw == "true" ||
      raw == "TRUE" ||
      raw == "yes" ||
      raw == "on"
    None => false
  }
}

///|
fn set_text_entity(
  entity : @entity.Entity,
  text : String,
  position : @math.Vec2,
  color : String,
  font : String,
  zindex : Int,
) -> Unit {
  @ui.texts().set(entity, @ui.Text::new(text))
  @ui.text_fonts().set(entity, @ui.TextFont::from_css(font))
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(-0.5, 0.5)))
  @transform.transforms().set(entity, world_transform_2d(position, zindex))
  @visibility.visibilities().set(entity, Visible)
}

///|
fn set_rect_entity(
  entity : @entity.Entity,
  center : @math.Vec2,
  size : @math.Vec2,
  color : @render.Color,
  zindex : Int,
  rotation? : Double = 0.0,
) -> Unit {
  let sprite = @sprite.Sprite::from_color(color, size)
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  let top_left = @math.Vec2(
    center[X] - size[X] * 0.5,
    center[Y] - size[Y] * 0.5,
  )
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    world_transform_2d(top_left, zindex, rotation~),
  )
  @visibility.visibilities().set(entity, Visible)
}

///|
fn destroy_and_clear(entity : @entity.Entity) -> Unit {
  if entity.is_alive() {
    entity.destroy()
  }
}

///|
fn clear_decorative_entities() -> Unit {
  for entity in decorative_entities {
    destroy_and_clear(entity)
  }
  decorative_entities.clear()
}

///|
fn clear_enemy_entities() -> Unit {
  for enemy in enemy_states {
    destroy_and_clear(enemy.entity)
  }
  enemy_states.clear()
}

///|
fn clear_bullet_entities() -> Unit {
  for bullet in bullet_states {
    destroy_and_clear(bullet.entity)
  }
  bullet_states.clear()
}

///|
fn clear_obstacle_entities() -> Unit {
  for obstacle in obstacle_states {
    destroy_and_clear(obstacle.entity)
  }
  obstacle_states.clear()
}

///|
fn load_player_spawn() -> Unit {
  player_state.pos = player_spawn
  player_state.facing = Up
  player_state.hp = PLAYER_HP_MAX
  player_state.fire_cd = 0.0
  player_state.invuln = PLAYER_RESPAWN_INVULN
  player_state.alive = true
}

///|
fn reset_game_state() -> Unit {
  game_state.phase = Playing
  game_state.score = 0
  game_state.best_streak = 0
  game_state.streak = 0
  game_state.profile_started_at = @time.elapsed()
  game_state.profile_last_report_at = game_state.profile_started_at
  game_state.profile_frame_count = 0
  wave_state.index = 0
  wave_state.spawn_left = 0
  wave_state.spawn_timer = 0.0
  wave_state.ready_timer = 0.0
  wave_state.extraction_open = false
  player_state.lives = PLAYER_LIVES_MAX
  load_player_spawn()
}

///|
fn base_obstacle_specs() -> Array[(ObstacleKind, @math.Rect)] {
  [
    (Rock, make_rect(192.0, 192.0, 80.0, 80.0)),
    (Rock, make_rect(1000.0, 192.0, 80.0, 80.0)),
    (Crate, make_rect(352.0, 240.0, 64.0, 64.0)),
    (Crate, make_rect(864.0, 240.0, 64.0, 64.0)),
    (Crate, make_rect(560.0, 328.0, 72.0, 56.0)),
    (Rock, make_rect(144.0, 432.0, 96.0, 52.0)),
    (Rock, make_rect(1040.0, 432.0, 96.0, 52.0)),
    (Crate, make_rect(320.0, 516.0, 64.0, 64.0)),
    (Crate, make_rect(896.0, 516.0, 64.0, 64.0)),
  ]
}

///|
fn add_score(value : Int) -> Unit {
  game_state.score += value
  game_state.streak += 1
  if game_state.streak > game_state.best_streak {
    game_state.best_streak = game_state.streak
  }
}

///|
fn wave_enemy_count(wave_index : Int) -> Int {
  5 + wave_index * 2
}

///|
fn wave_spawn_interval(wave_index : Int) -> Double {
  clamp_double(0.72 - wave_index.to_double() * 0.08, 0.34, 0.72)
}

///|
fn wave_total_count() -> Int {
  INITIAL_WAVE_COUNT
}

///|
fn can_fire_player() -> Bool {
  player_state.fire_cd <= 0.0 &&
  game_state.phase == Playing &&
  player_state.alive
}

///|
fn begin_next_wave() -> Unit {
  if wave_state.index >= wave_total_count() {
    wave_state.extraction_open = true
    wave_state.spawn_left = 0
    wave_state.ready_timer = 0.0
    return
  }
  wave_state.spawn_left = wave_enemy_count(wave_state.index)
  wave_state.spawn_timer = 0.2
  wave_state.ready_timer = 0.0
  wave_state.extraction_open = false
}

///|
fn active_enemies() -> Int {
  let mut count = 0
  for enemy in enemy_states {
    if enemy.alive {
      count += 1
    }
  }
  count
}

///|
fn maybe_finish_wave() -> Unit {
  if wave_state.spawn_left == 0 && active_enemies() == 0 {
    if wave_state.index < wave_total_count() {
      wave_state.ready_timer += @time.delta()
      if wave_state.ready_timer >= INITIAL_WAVE_READY_DELAY {
        wave_state.index += 1
        begin_next_wave()
      }
    } else {
      wave_state.extraction_open = true
    }
  }
}

///|
fn spawn_player_bullet(origin : @math.Vec2, direction : @math.Vec2) -> Unit {
  let bullet : BulletState = {
    entity: @entity.Entity::new(),
    owner: Player,
    pos: origin,
    vel: direction.scalar_mul(BULLET_SPEED),
    ttl: BULLET_TTL,
    alive: true,
  }
  bullet_states.push(bullet)
}

///|
fn spawn_enemy_bullet(origin : @math.Vec2, direction : @math.Vec2) -> Unit {
  let bullet : BulletState = {
    entity: @entity.Entity::new(),
    owner: Enemy,
    pos: origin,
    vel: direction.scalar_mul(BULLET_SPEED * 0.78),
    ttl: BULLET_TTL,
    alive: true,
  }
  bullet_states.push(bullet)
}

///|
fn spawn_enemy(kind : EnemyKind, pos : @math.Vec2) -> Unit {
  let enemy : EnemyState = {
    entity: @entity.Entity::new(),
    kind,
    pos,
    facing: Down,
    hp: if kind == Soldier {
      ENEMY_HP
    } else {
      TURRET_HP
    },
    fire_cd: 0.4,
    alive: true,
  }
  enemy_states.push(enemy)
}

///|
fn respawn_after_death() -> Unit {
  player_state.lives -= 1
  if player_state.lives <= 0 {
    player_state.alive = false
    game_state.phase = Lost
    return
  }
  player_state.pos = player_spawn
  player_state.hp = PLAYER_HP_MAX
  player_state.invuln = PLAYER_RESPAWN_INVULN
  player_state.fire_cd = 0.0
  player_state.alive = true
}

///|
fn damage_player(amount : Int) -> Unit {
  if player_state.invuln > 0.0 || game_state.phase != Playing {
    return
  }
  player_state.hp -= amount
  player_state.invuln = PLAYER_RESPAWN_INVULN
  if player_state.hp <= 0 {
    respawn_after_death()
  }
}

///|
fn damage_enemy(index : Int, amount : Int) -> Unit {
  let enemy = enemy_states[index]
  if !enemy.alive {
    return
  }
  enemy.hp -= amount
  if enemy.hp <= 0 {
    enemy.alive = false
    add_score(if enemy.kind == Soldier { 100 } else { 150 })
  }
  enemy_states[index] = enemy
}

///|
fn damage_obstacle(index : Int, amount : Int) -> Unit {
  let obstacle = obstacle_states[index]
  if !obstacle.alive || obstacle.kind == Rock {
    return
  }
  obstacle.hp -= amount
  if obstacle.hp <= 0 {
    obstacle.alive = false
    add_score(20)
  }
  obstacle_states[index] = obstacle
}

///|
fn extract_world_rect() -> @math.Rect {
  extraction_zone
}

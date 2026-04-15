///|
fn plant_index_at(x : Int, y : Int) -> Int? {
  for i in 0..<plants.length() {
    let plant = plants[i]
    if plant.alive && plant.cell_x == x && plant.cell_y == y {
      return Some(i)
    }
  }
  None
}

///|
fn zombie_index_at_lane_ahead(lane : Int, x : Double) -> Int? {
  let mut best_index : Int? = None
  let mut best_x = -1.0
  for i in 0..<zombies.length() {
    let zombie = zombies[i]
    if !zombie.alive || zombie.lane != lane || zombie.x < x {
      continue
    }
    if best_index is None || zombie.x < best_x {
      best_index = Some(i)
      best_x = zombie.x
    }
  }
  best_index
}

///|
fn alive_plant_count() -> Int {
  let mut count = 0
  for plant in plants {
    if plant.alive {
      count += 1
    }
  }
  count
}

///|
fn alive_zombie_count() -> Int {
  let mut count = 0
  for zombie in zombies {
    if zombie.alive {
      count += 1
    }
  }
  count
}

///|
fn alive_bullet_count() -> Int {
  let mut count = 0
  for bullet in bullets {
    if bullet.alive {
      count += 1
    }
  }
  count
}

///|
fn alive_sun_count() -> Int {
  let mut count = 0
  for sun in suns {
    if sun.alive {
      count += 1
    }
  }
  count
}

///|
fn playing_hint_text() -> String {
  "Click sun to collect. LMB shooter. RMB wall. R restart. Esc quit."
}

///|
fn result_banner_text() -> String {
  match phase.val {
    Won =>
      "YOU WIN\nSun \{sun_points.val}  Wave \{WAVE_COUNT}/\{WAVE_COUNT}\nPress R or Enter to restart"
    Lost => "YOU LOSE\nZombies reached the house\nPress R or Enter to retry"
    Playing => ""
  }
}

///|
fn phase_hint_text() -> String {
  match phase.val {
    Playing => playing_hint_text()
    Won => "Wave clear. Press R / Enter to play again."
    Lost => "House lost. Press R / Enter to try again."
  }
}

///|
fn spawn_plant(kind : PlantKind, cell_x : Int, cell_y : Int) -> Bool {
  if !cell_in_bounds(cell_x, cell_y) {
    return false
  }
  if plant_index_at(cell_x, cell_y) is Some(_) {
    return false
  }
  if sun_points.val < plant_cost(kind) {
    return false
  }

  sun_points.val -= plant_cost(kind)
  let center = cell_center(cell_x, cell_y)
  let entity = @entity.Entity::new()
  let size = match kind {
    Shooter => @math.Vec2(58.0, 58.0)
    Wall => @math.Vec2(64.0, 64.0)
  }
  @sprite.sprites().set(
    entity,
    {
      let sprite = @sprite.Sprite::from_color(
        match kind {
          Shooter => rgba(73U, 184U, 92U, 1.0)
          Wall => rgba(148U, 104U, 60U, 1.0)
        },
        size,
      )
      sprite.anchor = @sprite.Anchor(@math.Vec2(0.0, 0.0))
      sprite
    },
  )
  @transform.transforms().set(
    entity,
    world_transform(
      @math.Vec2(center[X] - size[X] * 0.5, center[Y] - size[Y] * 0.5),
      PLANT_Z,
    ),
  )
  set_entity_visibility(entity, true)
  plants.push({
    kind,
    cell_x,
    cell_y,
    hp: plant_hp_for(kind),
    attack_timer: 0.0,
    entity,
    alive: true,
  })
  play_fx(Place)
  true
}

///|
fn spawn_bullet(x : Double, y : Double) -> Unit {
  let entity = spawn_circle_entity(
    @math.Vec2(x, y),
    10.0,
    rgba(136U, 247U, 107U, 1.0),
    BULLET_Z,
  )
  bullets.push({
    x,
    y,
    speed: BULLET_SPEED,
    damage: BULLET_DAMAGE,
    entity,
    alive: true,
  })
}

///|
fn spawn_sun_token(x : Double, y : Double) -> Unit {
  let entity = spawn_circle_entity(
    @math.Vec2(x, y),
    11.0,
    rgba(251U, 219U, 90U, 1.0),
    SUN_Z,
  )
  suns.push({ x, y, vy: SUN_FALL_SPEED, life_time: 0.0, entity, alive: true })
}

///|
fn spawn_zombie(lane : Int, kind_index : Int) -> Unit {
  let row = clamp_int(lane, 0, GRID_ROWS - 1)
  let center = cell_center(GRID_COLS - 1, row)
  let entity = @entity.Entity::new()
  set_rect_entity(
    entity,
    @math.Vec2(center[X] - 31.0, center[Y] - 31.0),
    @math.Vec2(62.0, 62.0),
    rgba(131U, 186U, 110U, 1.0),
    ZOMBIE_Z,
  )
  zombies.push({
    x: BOARD_RIGHT + 42.0,
    y: center[Y],
    lane: row,
    hp: wave_plan_hp(kind_index),
    speed: wave_plan_speed(kind_index),
    chew_timer: 0.0,
    entity,
    alive: true,
  })
}

///|
fn spawn_wave_zombie_if_needed() -> Unit {
  if phase.val != Playing || current_wave_complete() {
    return
  }
  let plan_index = wave_state.val.wave_index
  let wave_count = wave_plan_count(plan_index)
  if wave_state.val.spawned_in_wave >= wave_count {
    return
  }
  let spawn_interval = wave_plan_interval(plan_index)
  wave_state.val.spawn_timer += @time.delta()
  if wave_state.val.spawn_timer < spawn_interval {
    return
  }
  wave_state.val.spawn_timer -= spawn_interval
  wave_state.val.spawned_in_wave += 1
  spawn_zombie(rng.int(limit=GRID_ROWS), plan_index)
}

///|
fn nearest_zombie_in_row(row : Int, x : Double) -> Int? {
  zombie_index_at_lane_ahead(row, x)
}

///|
fn fire_shooters(delta : Double) -> Unit {
  for i in 0..<plants.length() {
    let plant = plants[i]
    if !plant.alive || plant.kind != Shooter {
      continue
    }
    let next = plant.attack_timer + delta
    plants[i] = { ..plant, attack_timer: next }
    let center = cell_center(plant.cell_x, plant.cell_y)
    if next < SHOOTER_FIRE_INTERVAL {
      continue
    }
    match nearest_zombie_in_row(plant.cell_y, center[X]) {
      Some(zombie_index) => {
        let zombie = zombies[zombie_index]
        if zombie.alive {
          spawn_bullet(center[X] + 30.0, center[Y])
          plants[i] = { ..plants[i], attack_timer: 0.0 }
          play_fx(Shoot)
        }
      }
      None => ()
    }
  }
}

///|
fn advance_bullets(delta : Double) -> Unit {
  for i in 0..<bullets.length() {
    let bullet = bullets[i]
    if !bullet.alive {
      continue
    }
    let next_x = bullet.x + bullet.speed * delta
    bullets[i] = { ..bullet, x: next_x }
    if next_x > BOARD_RIGHT + 60.0 {
      bullets[i] = { ..bullet, alive: false }
      bullets[i].entity.destroy()
      continue
    }
    for j in 0..<zombies.length() {
      let zombie = zombies[j]
      if !zombie.alive || bullet.y < BOARD_TOP || bullet.y > BOARD_BOTTOM {
        continue
      }
      if projectile_hits_zombie(next_x, zombie.x) &&
        abs_double(bullet.y - zombie.y) <= 34.0 {
        bullets[i] = { ..bullet, alive: false }
        bullets[i].entity.destroy()
        let next_hp = zombie.hp - bullet.damage
        zombies[j] = { ..zombie, hp: next_hp }
        play_fx(Hit)
        if next_hp <= 0 {
          zombies[j] = { ..zombie, alive: false }
          zombies[j].entity.destroy()
          sun_points.val += ZOMBIE_REWARD_SUN
          spawn_sun_token(zombie.x, zombie.y - 12.0)
          play_fx(Kill)
        }
        break
      }
    }
  }
}

///|
fn zombie_blocking_plant_index(zombie : ZombieState) -> Int? {
  let mut best_index : Int? = None
  let mut best_x = -1.0
  for i in 0..<plants.length() {
    let plant = plants[i]
    if !plant.alive || plant.cell_y != zombie.lane {
      continue
    }
    let center = cell_center(plant.cell_x, plant.cell_y)
    if center[X] > zombie.x {
      continue
    }
    if best_index is None || center[X] > best_x {
      best_index = Some(i)
      best_x = center[X]
    }
  }
  best_index
}

///|
fn advance_zombies(delta : Double) -> Unit {
  for i in 0..<zombies.length() {
    let zombie = zombies[i]
    if !zombie.alive {
      continue
    }
    match zombie_blocking_plant_index(zombie) {
      Some(plant_index) => {
        let plant = plants[plant_index]
        let plant_center = cell_center(plant.cell_x, plant.cell_y)
        if abs_double(zombie.x - plant_center[X]) <= 40.0 {
          let chew_next = zombie.chew_timer + delta
          let updated = if chew_next >= ZOMBIE_CHEW_INTERVAL {
            let next_hp = plant.hp - 1
            plants[plant_index] = { ..plant, hp: next_hp }
            play_fx(Hit)
            if next_hp <= 0 {
              plants[plant_index] = { ..plant, alive: false }
              plants[plant_index].entity.destroy()
            }
            { ..zombie, chew_timer: 0.0, x: plant_center[X] + 34.0 }
          } else {
            { ..zombie, chew_timer: chew_next, x: plant_center[X] + 34.0 }
          }
          zombies[i] = updated
        } else {
          zombies[i] = {
            ..zombie,
            x: zombie.x - zombie.speed * delta,
            chew_timer: 0.0,
          }
        }
      }
      None =>
        zombies[i] = {
          ..zombie,
          x: zombie.x - zombie.speed * delta,
          chew_timer: 0.0,
        }
    }
    if zombies[i].alive && zombie_reaches_house(zombies[i].x) {
      phase.val = Lost
      play_fx(Lose)
    }
  }
}

///|
fn advance_suns(delta : Double) -> Unit {
  for i in 0..<suns.length() {
    let sun = suns[i]
    if !sun.alive {
      continue
    }
    let next_y = sun.y + sun.vy * delta
    let next_time = sun.life_time + delta
    suns[i] = { ..sun, y: next_y, life_time: next_time }
    if next_time >= SUN_LIFETIME || next_y > BOARD_BOTTOM + 32.0 {
      suns[i] = { ..sun, alive: false }
      suns[i].entity.destroy()
    }
  }
}

///|
fn spawn_sun_timer(delta : Double) -> Unit {
  sun_spawn_timer.val += delta
  if sun_spawn_timer.val < SUN_SPAWN_INTERVAL || phase.val != Playing {
    return
  }
  sun_spawn_timer.val -= SUN_SPAWN_INTERVAL
  let x = BOARD_LEFT + rng.double() * GRID_COLS.to_double() * CELL_SIZE
  let y = BOARD_TOP - 30.0
  spawn_sun_token(x, y)
}

///|
fn collect_sun_under_mouse() -> Bool {
  if !@inputs.just_pressed_mouse.left_button {
    return false
  }
  let mouse = @inputs.mouse.pos
  for i in 0..<suns.length() {
    let sun = suns[i]
    if !sun.alive {
      continue
    }
    if point_in_rect(mouse, sun.x - 18.0, sun.y - 18.0, 36.0, 36.0) {
      sun_points.val += SUN_VALUE
      suns[i] = { ..sun, alive: false }
      suns[i].entity.destroy()
      play_fx(Sun)
      return true
    }
  }
  false
}

///|
fn maybe_report_profile() -> Unit {
  if !profile_enabled.val {
    return
  }
  let now = @time.elapsed()
  if now - profile_last_report_at.val < PVZ_PROFILE_REPORT_SECONDS {
    return
  }
  let frame_count = if profile_frame_count.val <= 0 {
    1
  } else {
    profile_frame_count.val
  }
  let frames = frame_count.to_double()
  let window = now - profile_last_report_at.val
  let fps = if window <= 0.0 { 0.0 } else { frames / window }
  let input_ms = profile_input_total.val / frames * 1000.0
  let sim_ms = profile_sim_total.val / frames * 1000.0
  let render_ms = profile_render_total.val / frames * 1000.0
  let slowest_frame_ms = profile_slowest_frame.val * 1000.0
  let min_fps = if slowest_frame_ms <= 0.0 {
    0.0
  } else {
    1000.0 / slowest_frame_ms
  }
  println(
    "[plantvszombies][profile] elapsed=\{now - profile_started_at.val}s frames=\{profile_frame_count.val} fps_avg=\{fps} fps_min=\{min_fps} input_avg_ms=\{input_ms} sim_avg_ms=\{sim_ms} render_avg_ms=\{render_ms} slowest_frame_ms=\{slowest_frame_ms} plants=\{alive_plant_count()} zombies=\{alive_zombie_count()} bullets=\{alive_bullet_count()} suns=\{alive_sun_count()} sun=\{sun_points.val} wave=\{clamp_int(wave_state.val.wave_index + 1, 1, WAVE_COUNT)}",
  )
  profile_last_report_at.val = now
  profile_frame_count.val = 0
  profile_input_total.val = 0.0
  profile_render_total.val = 0.0
  profile_sim_total.val = 0.0
  profile_slowest_frame.val = 0.0
}

///|
fn board_cell_from_mouse() -> (Int, Int)? {
  let mouse = @inputs.mouse.pos
  if mouse[X] < BOARD_LEFT ||
    mouse[X] >= BOARD_RIGHT ||
    mouse[Y] < BOARD_TOP ||
    mouse[Y] >= BOARD_BOTTOM {
    return None
  }
  Some(world_to_cell(mouse))
}

///|
fn place_plant_from_mouse(kind : PlantKind) -> Unit {
  match board_cell_from_mouse() {
    Some((x, y)) => {
      let occupied = plant_index_at(x, y) is Some(_)
      if can_place_plant(kind, sun_points.val, occupied) {
        if spawn_plant(kind, x, y) {
          return
        }
      }
    }
    None => ()
  }
}

///|
fn handle_input_for_playing() -> Unit {
  if @inputs.is_just_pressed(Escape) {
    @system.exit()
    return
  }
  if @inputs.is_just_pressed(KeyR) {
    reset_game_state()
    return
  }
  if phase.val != Playing {
    if @inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space) {
      reset_game_state()
    }
    return
  }
  if @host.is_key_pressed("F3") {
    show_fps.val = !show_fps.val
  }
  if collect_sun_under_mouse() {
    return
  }
  if @inputs.just_pressed_mouse.left_button {
    place_plant_from_mouse(Shooter)
  } else if @inputs.just_pressed_mouse.right_button {
    place_plant_from_mouse(Wall)
  }
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  handle_input_for_playing()
  if profile_enabled.val {
    profile_input_total.val += @time.elapsed() - started_at
  }
}

///|
fn finalize_wave_state() -> Unit {
  if phase.val != Playing {
    return
  }
  if wave_state.val.wave_index >= WAVE_COUNT {
    if zombies.length() == 0 {
      phase.val = Won
      play_fx(Win)
    }
    return
  }
  if wave_state.val.spawned_in_wave >=
    wave_plan_count(wave_state.val.wave_index) &&
    zombies.length() == 0 {
    wave_state.val.wave_index += 1
    wave_state.val.spawned_in_wave = 0
    wave_state.val.spawn_timer = 0.0
  }
}

///|
pub fn simulation_system(_world : @ecs.World) -> Unit {
  let delta = @time.delta()
  if phase.val != Playing {
    return
  }
  let started_at = @time.elapsed()
  spawn_sun_timer(delta)
  spawn_wave_zombie_if_needed()
  fire_shooters(delta)
  advance_bullets(delta)
  advance_zombies(delta)
  advance_suns(delta)
  finalize_wave_state()
  if profile_enabled.val {
    profile_sim_total.val += @time.elapsed() - started_at
  }
}

///|
fn sync_plant_entities() -> Unit {
  for plant in plants {
    if !plant.alive {
      continue
    }
    ensure_entity_alive(plant.entity)
    let center = cell_center(plant.cell_x, plant.cell_y)
    let size = match plant.kind {
      Shooter => @math.Vec2(58.0, 58.0)
      Wall => @math.Vec2(64.0, 64.0)
    }
    @transform.transforms().set(
      plant.entity,
      world_transform(
        @math.Vec2(center[X] - size[X] * 0.5, center[Y] - size[Y] * 0.5),
        PLANT_Z,
      ),
    )
    set_entity_visibility(plant.entity, true)
  }
}

///|
fn sync_zombie_entities() -> Unit {
  for zombie in zombies {
    if !zombie.alive {
      continue
    }
    ensure_entity_alive(zombie.entity)
    @transform.transforms().set(
      zombie.entity,
      world_transform(@math.Vec2(zombie.x - 31.0, zombie.y - 31.0), ZOMBIE_Z),
    )
    set_entity_visibility(zombie.entity, true)
  }
}

///|
fn sync_bullet_entities() -> Unit {
  for bullet in bullets {
    if !bullet.alive {
      continue
    }
    ensure_entity_alive(bullet.entity)
    @transform.transforms().set(
      bullet.entity,
      world_transform(@math.Vec2(bullet.x - 10.0, bullet.y - 10.0), BULLET_Z),
    )
    set_entity_visibility(bullet.entity, true)
  }
}

///|
fn sync_sun_entities() -> Unit {
  for sun in suns {
    if !sun.alive {
      continue
    }
    ensure_entity_alive(sun.entity)
    @transform.transforms().set(
      sun.entity,
      world_transform(@math.Vec2(sun.x - 11.0, sun.y - 11.0), SUN_Z),
    )
    set_entity_visibility(sun.entity, true)
  }
}

///|
fn sync_overlays() -> Unit {
  let hud_text = "Sun \{sun_points.val}  Wave \{clamp_int(wave_state.val.wave_index + 1, 1, WAVE_COUNT)}/\{WAVE_COUNT}  Plants \{alive_plant_count()}  Zombies \{alive_zombie_count()}"
  if hud_text_cache.val != hud_text {
    @ui.texts().set(hud_entity, @ui.Text::new(hud_text))
    hud_text_cache.val = hud_text
  }

  let hint_text = phase_hint_text()
  if hint_text_cache.val != hint_text {
    @ui.texts().set(hint_entity, @ui.Text::new(hint_text))
    hint_text_cache.val = hint_text
  }

  let result_text = result_banner_text()
  if result_text_cache.val != result_text {
    @ui.texts().set(result_entity, @ui.Text::new(result_text))
    result_text_cache.val = result_text
  }
  set_entity_visibility(result_entity, phase.val != Playing)
  if phase.val == Won {
    @ui.text_colors().set(
      result_entity,
      @ui.TextColor::from_css(RESULT_WIN_COLOR),
    )
  } else if phase.val == Lost {
    @ui.text_colors().set(
      result_entity,
      @ui.TextColor::from_css(RESULT_LOSE_COLOR),
    )
  }
  if show_fps.val {
    let fps_text = "FPS \{(1.0 / clamp_double(@time.delta(), 0.0001, 1.0)).to_int()}"
    if fps_text_cache.val != fps_text {
      @ui.texts().set(fps_entity, @ui.Text::new(fps_text))
      fps_text_cache.val = fps_text
    }
    set_entity_visibility(fps_entity, true)
  } else {
    set_entity_visibility(fps_entity, false)
  }
}

///|
pub fn render_sync_system(_world : @ecs.World) -> Unit {
  let started_at = @time.elapsed()
  sync_plant_entities()
  sync_zombie_entities()
  sync_bullet_entities()
  sync_sun_entities()
  sync_overlays()
  if profile_enabled.val {
    profile_render_total.val += @time.elapsed() - started_at
    profile_frame_count.val = profile_frame_count.val + 1
    let frame_dt = @time.frame_delta()
    if frame_dt > profile_slowest_frame.val {
      profile_slowest_frame.val = frame_dt
    }
    maybe_report_profile()
  }
}

///|
pub fn capture_after_render_system(_world : @ecs.World) -> Unit {
  if !capture_enabled.val || capture_taken.val {
    return
  }
  if @time.elapsed() - capture_started_at.val < PVZ_CAPTURE_DELAY_SECONDS {
    return
  }
  @host.take_screenshot(PVZ_CAPTURE_PATH)
  println("[plantvszombies][capture] path=\{PVZ_CAPTURE_PATH}")
  capture_taken.val = true
  @system.exit()
}

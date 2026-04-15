///|
let best_score : Ref[Int] = { val: 0 }

///|
fn normal_gravity() -> @math.Vec3 {
  @math.Vec3::new(0.0, -14.0, 4.0)
}

///|
fn round2(value : Double) -> Double {
  @cmath.round(value * 100.0) / 100.0
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
fn board_rotation() -> @math.Quat {
  @math.Quat::from_axis_angle(@math.Vec3::x_axis(), BOARD_TILT_RADIANS)
}

///|
fn run_phase_name(phase : RunPhase) -> String {
  match phase {
    Playing => "Playing"
    ChestPick => "ChestPick"
    Finished => "Finished"
  }
}

///|
fn apply_difficulty_tier(tier : Int) -> Unit {
  board_state.difficulty_tier = tier
  board_state.pusher_speed = PUSHER_BASE_SPEED * (1.0 + tier.to_double() * 0.1)
  board_state.stroke_length = PUSHER_BASE_STROKE_LENGTH *
    (1.0 + tier.to_double() * 0.06)
  board_state.lane_jitter = PUSHER_BASE_LANE_JITTER *
    (1.0 + tier.to_double() * 0.08)
}

///|
fn coin_world_position(entity : @entity.Entity) -> @math.Vec3? {
  match @physics3d.rigid_body_translation(entity) {
    Some(value) => Some(value)
    None =>
      match @transform.transforms().get(entity) {
        Some(transform) => Some(transform.translation)
        None => None
      }
  }
}

///|
fn coin_speed_squared(entity : @entity.Entity) -> Double {
  match @physics3d.rigid_body_linear_velocity(entity) {
    Some(value) => value.length_squared()
    None => 0.0
  }
}

///|
fn update_coin_visual_transform(entity : @entity.Entity) -> Unit {
  let translation = @physics3d.rigid_body_translation(entity)
  let rotation = @physics3d.rigid_body_rotation(entity)
  match (translation, rotation) {
    (Some(pos), Some(rot)) =>
      @transform.transforms().set(
        entity,
        world_transform(pos, rot, @math.Vec3::one()),
      )
    (Some(pos), None) =>
      @transform.transforms().set(
        entity,
        world_transform(pos, @math.Quat::identity(), @math.Vec3::one()),
      )
    _ => ()
  }
}

///|
fn next_spawn_x_from_mouse() -> Double {
  screen_x_to_spawn_x(@inputs.mouse.pos[X])
}

///|
fn set_phase(new_phase : RunPhase) -> Unit {
  if run_state.phase == new_phase {
    return
  }
  run_state.phase = new_phase
  if new_phase == ChestPick {
    @physics3d.set_gravity(@math.Vec3::zero())
  } else {
    @physics3d.set_gravity(normal_gravity())
  }
}

///|
fn weighted_pick_upgrade(candidates : Array[UpgradeId]) -> UpgradeId? {
  if candidates.is_empty() {
    return None
  }
  let mut total = 0.0
  for candidate in candidates {
    total += upgrade_weight(candidate)
  }
  if total <= 0.0 {
    return Some(candidates[0])
  }
  let mut cursor = rand.double() * total
  for candidate in candidates {
    cursor -= upgrade_weight(candidate)
    if cursor <= 0.0 {
      return Some(candidate)
    }
  }
  Some(candidates[candidates.length() - 1])
}

///|
fn filtered_candidates_after_pick(
  candidates : Array[UpgradeId],
  picked : UpgradeId,
) -> Array[UpgradeId] {
  let result : Array[UpgradeId] = []
  for candidate in candidates {
    if candidate == picked {
      continue
    }
    if upgrades_conflict(candidate, picked) {
      continue
    }
    result.push(candidate)
  }
  result
}

///|
fn roll_chest_options() -> Array[UpgradeId] {
  let options : Array[UpgradeId] = []
  let mut candidates = eligible_upgrades()
  while options.length() < 3 && !candidates.is_empty() {
    match weighted_pick_upgrade(candidates) {
      Some(picked) => {
        options.push(picked)
        candidates = filtered_candidates_after_pick(candidates, picked)
      }
      None => break
    }
  }
  options
}

///|
fn ensure_chest_pending(elapsed : Double) -> Unit {
  if run_state.phase != Playing || chest_state.pending {
    return
  }
  let options = roll_chest_options()
  if options.is_empty() {
    return
  }
  chest_state.pending = true
  chest_state.options = options
  chest_state.last_chest_time = elapsed
  set_phase(ChestPick)
}

///|
fn apply_upgrade(id : UpgradeId) -> Unit {
  let current = upgrade_stacks(id)
  upgrade_state.owned.set(id, current + 1)
  upgrade_state.picked_order.push(id)
  match id {
    MaxCharge => {
      economy_state.coin_charge_max += 2
      economy_state.coin_charge = clamp_int(
        economy_state.coin_charge + 2,
        0,
        economy_state.coin_charge_max,
      )
    }
    RegenBoost => economy_state.regen_rate *= 1.25
    ScoreBoost => run_state.score_multiplier += 0.2
    ComboWindowBoost => run_state.combo_window += 0.22
    CooldownCut =>
      economy_state.drop_cooldown = clamp_double(
        economy_state.drop_cooldown * 0.88,
        0.06,
        INITIAL_DROP_COOLDOWN,
      )
    SplitCoin | MagnetPulse | LuckyBounce | HeavyCoin => ()
  }
}

///|
fn finish_chest_pick(selected_index : Int) -> Unit {
  if !chest_state.pending {
    return
  }
  if selected_index < 0 || selected_index >= chest_state.options.length() {
    return
  }
  let selected = chest_state.options[selected_index]
  apply_upgrade(selected)
  chest_state.pending = false
  chest_state.options.clear()
  play_audio(SFX_CHEST_PICK_PATH, volume=0.8)
  set_phase(Playing)
}

///|
fn restart_run() -> Unit {
  reset_runtime_scene()
  set_phase(Playing)
}

///|
fn coin_density(heavy : Bool) -> Double {
  if heavy {
    2.35
  } else {
    1.0
  }
}

///|
fn coin_linear_damping(heavy : Bool) -> Double {
  if heavy {
    1.1
  } else {
    0.45
  }
}

///|
fn coin_spawn_velocity(heavy : Bool) -> @math.Vec3 {
  if heavy {
    @math.Vec3::new(0.0, -1.1, 0.9)
  } else {
    @math.Vec3::new(0.0, -1.0, 1.5)
  }
}

///|
fn spawn_coin_entity(
  x : Double,
  y : Double,
  z : Double,
  velocity : @math.Vec3,
  heavy : Bool,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  @transform.transforms().set(
    entity,
    world_transform(
      @math.Vec3::new(x, y, z),
      @math.Quat::identity(),
      @math.Vec3::one(),
    ),
  )
  @render3d.mesh3d_renderers().set(entity, {
    mesh: coin_mesh_handle.val.unwrap(),
    material: coin_material_handle.val.unwrap(),
    visible: true,
    cast_shadows: false,
    receive_shadows: false,
  })
  @physics3d.rigid_bodies().set(entity, @physics3d.Dynamic)
  @physics3d.colliders().set(entity, @physics3d.Collider::ball(COIN_RADIUS))
  @physics3d.collider_mass_properties().set(
    entity,
    @physics3d.ColliderMassProperties::density(coin_density(heavy)),
  )
  @physics3d.frictions().set(
    entity,
    @physics3d.Friction::new(if heavy { 0.95 } else { 0.82 }),
  )
  @physics3d.restitutions().set(entity, @physics3d.Restitution::new(0.08))
  @physics3d.dampings().set(entity, {
    linear_damping: coin_linear_damping(heavy),
    angular_damping: 0.8,
  })
  @physics3d.set_rigid_body_linear_velocity(entity, velocity)
  coin_entities.set(entity, {
    split_done: false,
    lucky_checked: false,
    life_time: 0.0,
    heavy,
  })
  entity
}

///|
fn spawn_drop_coin() -> Unit {
  let heavy = has_upgrade(HeavyCoin)
  let spawn_y = COIN_SPAWN_Y
  ignore(
    spawn_coin_entity(
      economy_state.spawn_x,
      spawn_y,
      COIN_SPAWN_Z,
      coin_spawn_velocity(heavy),
      heavy,
    ),
  )
  economy_state.coin_charge -= 1
  economy_state.drop_cooldown_timer = economy_state.drop_cooldown
  play_audio(SFX_COIN_DROP_PATH, volume=0.55)
}

///|
pub fn seed_board_coin_field() -> Unit {
  let min_z = -board_half_length() + 2.6
  let max_z = 3.2
  for _ in 0..<INITIAL_BOARD_COINS {
    let z = min_z + rand.double() * (max_z - min_z)
    let x = lane_min_x() + rand.double() * (lane_max_x() - lane_min_x())
    let y = board_surface_y(z) + COIN_HEIGHT * 0.7 + rand.double() * 0.72
    let vx = (rand.double() - 0.5) * 0.3
    let vz = rand.double() * 0.2
    ignore(spawn_coin_entity(x, y, z, @math.Vec3::new(vx, 0.0, vz), false))
  }
}

///|
fn destroy_coin_entity(entity : @entity.Entity) -> Unit {
  coin_entities.remove(entity)
  entity.destroy()
}

///|
fn add_score_event(slot_multiplier : Double, elapsed : Double) -> Unit {
  if elapsed - run_state.last_score_time <= run_state.combo_window {
    run_state.combo_count += 1
  } else {
    run_state.combo_count = 1
  }
  run_state.last_score_time = elapsed
  if run_state.combo_count > run_state.best_combo {
    run_state.best_combo = run_state.combo_count
  }
  let total_multiplier = slot_multiplier *
    run_state.score_multiplier *
    combo_multiplier(run_state.combo_count)
  let gained_raw = @cmath.round(SCORE_BASE.to_double() * total_multiplier).to_int()
  let gained = if gained_raw <= 0 { 1 } else { gained_raw }
  run_state.score += gained
  score_events_in_frame.val += 1
  if run_state.score > best_score.val {
    best_score.val = run_state.score
  }
}

///|
fn try_trigger_chest_from_score(elapsed : Double) -> Unit {
  if run_state.phase != Playing || chest_state.pending {
    return
  }
  let since_last = elapsed - chest_state.last_chest_time
  if chest_should_trigger(rand.double(), since_last) {
    ensure_chest_pending(elapsed)
  }
}

///|
fn mouse_pick_chest_option() -> Int? {
  if !@inputs.just_pressed_mouse.left_button {
    return None
  }
  let mouse = @inputs.mouse.pos
  for i in 0..<chest_option_rects.length() {
    let (left, top, width, height) = chest_option_rects[i]
    if mouse[X] >= left &&
      mouse[X] <= left + width &&
      mouse[Y] >= top &&
      mouse[Y] <= top + height {
      return Some(i)
    }
  }
  None
}

///|
fn keyboard_pick_chest_option() -> Int? {
  if @host.is_key_pressed("Digit1") {
    return Some(0)
  }
  if @host.is_key_pressed("Digit2") {
    return Some(1)
  }
  if @host.is_key_pressed("Digit3") {
    return Some(2)
  }
  None
}

///|
fn update_chest_visibility(visible : Bool) -> Unit {
  set_entity_visibility(chest_title_entity, visible)
  for entity in chest_option_panel_entities {
    set_entity_visibility(entity, visible)
  }
  for entity in chest_option_text_entities {
    set_entity_visibility(entity, visible)
  }
}

///|
fn set_hud_texts(main : String, sub : String, hint : String) -> Unit {
  if hud_main_text_cache.val != main {
    hud_main_text_cache.val = main
    @ui.texts().set(hud_main_entity, @ui.Text::new(main))
  }
  if hud_sub_text_cache.val != sub {
    hud_sub_text_cache.val = sub
    @ui.texts().set(hud_sub_entity, @ui.Text::new(sub))
  }
  if hud_hint_text_cache.val != hint {
    hud_hint_text_cache.val = hint
    @ui.texts().set(hud_hint_entity, @ui.Text::new(hint))
  }
}

///|
fn update_summary_visibility(visible : Bool) -> Unit {
  set_entity_visibility(summary_title_entity, visible)
  set_entity_visibility(summary_body_entity, visible)
}

///|
fn summaries_text() -> (String, String) {
  let upgrade_list = if upgrade_state.picked_order.is_empty() {
    "none"
  } else {
    upgrade_state.picked_order.map(upgrade_display_name).join(", ")
  }
  let title = "RUN FINISHED"
  let body = "Score: \{run_state.score}\nBest Score: \{best_score.val}\nBest Combo: \{run_state.best_combo}\nUpgrades: \{upgrade_list}\nPress Enter/Space to restart"
  (title, body)
}

///|
pub fn input_system(_world : @ecs.World) -> Unit {
  if @inputs.is_just_pressed(Escape) {
    @system.exit()
    return
  }
  if @inputs.is_just_pressed(KeyR) {
    restart_run()
    return
  }
  if run_state.phase == Finished &&
    (@inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space)) {
    restart_run()
    return
  }

  economy_state.spawn_x = next_spawn_x_from_mouse()

  if run_state.phase == ChestPick {
    let mut picked : Int? = None
    match keyboard_pick_chest_option() {
      Some(index) => picked = Some(index)
      None => ()
    }
    if picked is None {
      picked = mouse_pick_chest_option()
    }
    match picked {
      Some(index) => finish_chest_pick(index)
      None => ()
    }
    return
  }

  if run_state.phase != Playing {
    return
  }
}

///|
pub fn coin_spawn_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  let delta = @time.delta()
  economy_state.drop_cooldown_timer = clamp_double(
    economy_state.drop_cooldown_timer - delta,
    0.0,
    999.0,
  )
  let (next_charge, next_accum) = regen_charge_step(
    economy_state.coin_charge,
    economy_state.coin_charge_max,
    economy_state.regen_accum,
    economy_state.regen_rate,
    delta,
  )
  economy_state.coin_charge = next_charge
  economy_state.regen_accum = next_accum
  if @inputs.just_pressed_mouse.left_button &&
    economy_state.coin_charge > 0 &&
    economy_state.drop_cooldown_timer <= 0.0 {
    spawn_drop_coin()
  }
}

///|
pub fn run_timer_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  run_state.time_left = clamp_double(
    run_state.time_left - @time.delta(),
    0.0,
    RUN_DURATION_SECONDS,
  )
  if run_state.time_left <= 0.0 {
    set_phase(Finished)
  }
}

///|
pub fn difficulty_ramp_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  let tier = difficulty_tier_for_elapsed(run_elapsed_seconds())
  if tier != board_state.difficulty_tier {
    apply_difficulty_tier(tier)
  }
}

///|
pub fn physics_sync_system(_world : @ecs.World) -> Unit {
  if run_state.phase == ChestPick {
    for entity, _ in coin_entities {
      @physics3d.set_rigid_body_linear_velocity(entity, @math.Vec3::zero())
      @physics3d.set_rigid_body_angular_velocity(entity, @math.Vec3::zero())
      update_coin_visual_transform(entity)
    }
    @physics3d.set_rigid_body_linear_velocity(pusher_entity, @math.Vec3::zero())
    return
  }
  for entity, _ in coin_entities {
    update_coin_visual_transform(entity)
  }
}

///|
pub fn pusher_motion_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing {
    return
  }
  board_state.pusher_phase += @time.delta() * board_state.pusher_speed
  let phase = board_state.pusher_phase
  let offset_z = @cmath.sin(phase) * board_state.stroke_length
  let offset_x = @cmath.sin(phase * 0.7) * board_state.lane_jitter
  let z = PUSHER_CENTER_Z + offset_z
  let x = clamp_double(offset_x, lane_min_x(), lane_max_x())
  let y = board_surface_y(z) + PUSHER_HEIGHT * 0.5
  let translation = @math.Vec3::new(x, y, z)
  @physics3d.set_rigid_body_translation(pusher_entity, translation)
  @physics3d.set_rigid_body_rotation(pusher_entity, board_rotation())
  @transform.transforms().set(
    pusher_entity,
    world_transform(translation, board_rotation(), @math.Vec3::one()),
  )
}

///|
fn spawn_split_coin(parent_pos : @math.Vec3, parent_heavy : Bool) -> Unit {
  if coin_entities.length() >= COIN_LIMIT {
    return
  }
  let side = if rand.boolean() { 1.0 } else { -1.0 }
  let offset_x = side * (COIN_RADIUS * 0.9)
  let velocity = @math.Vec3::new(side * 1.2, -0.3, 1.35)
  ignore(
    spawn_coin_entity(
      clamp_double(parent_pos.x + offset_x, lane_min_x(), lane_max_x()),
      parent_pos.y + 0.2,
      parent_pos.z,
      velocity,
      parent_heavy,
    ),
  )
}

///|
pub fn split_coin_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing || !has_upgrade(SplitCoin) {
    return
  }
  let entities = coin_entities.keys()
  for entity in entities {
    match coin_entities.get(entity) {
      Some(coin) => {
        if coin.split_done {
          continue
        }
        match coin_world_position(entity) {
          Some(pos) =>
            if pos.z >= SPLIT_TRIGGER_Z {
              coin.split_done = true
              coin_entities.set(entity, coin)
              spawn_split_coin(pos, coin.heavy)
            }
          None => ()
        }
      }
      None => ()
    }
  }
}

///|
pub fn magnet_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing || !has_upgrade(MagnetPulse) {
    return
  }
  upgrade_state.magnet_timer += @time.delta()
  if upgrade_state.magnet_timer < MAGNET_PULSE_PERIOD {
    return
  }
  upgrade_state.magnet_timer -= MAGNET_PULSE_PERIOD
  for entity, _ in coin_entities {
    match coin_world_position(entity) {
      Some(pos) =>
        if pos.z >= MAGNET_ZONE_Z {
          let target_x = lane_center(
            if pos.x < lane_center(1) {
              if pos.x < lane_center(0) {
                0
              } else {
                1
              }
            } else if pos.x < lane_center(2) {
              1
            } else {
              2
            },
          )
          let current_vel = match
            @physics3d.rigid_body_linear_velocity(entity) {
            Some(value) => value
            None => @math.Vec3::zero()
          }
          let next_vel = @math.Vec3::new(
            current_vel.x + (target_x - pos.x) * MAGNET_LANE_PULL,
            current_vel.y * 0.96,
            current_vel.z + MAGNET_FORWARD_BOOST,
          )
          @physics3d.set_rigid_body_linear_velocity(entity, next_vel)
        }
      None => ()
    }
  }
}

///|
pub fn lucky_bounce_system(_world : @ecs.World) -> Unit {
  if run_state.phase != Playing || !has_upgrade(LuckyBounce) {
    return
  }
  let elapsed = run_elapsed_seconds()
  let entities = coin_entities.keys()
  for entity in entities {
    let coin = match coin_entities.get(entity) {
      Some(value) => value
      None => continue
    }
    if coin.lucky_checked {
      continue
    }
    match coin_world_position(entity) {
      Some(pos) => {
        let near_x = abs_double(abs_double(pos.x) - BUMPER_X_OFFSET) <= 0.65
        let near_z = abs_double(pos.z - BUMPER_Z) <= 1.0
        if near_x &&
          near_z &&
          coin_speed_squared(entity) >= LUCKY_CHECK_SPEED * LUCKY_CHECK_SPEED {
          coin.lucky_checked = true
          coin_entities.set(entity, coin)
          if rand.double() < LUCKY_BONUS_CHANCE {
            run_state.score += LUCKY_BONUS_SCORE
            if run_state.score > best_score.val {
              best_score.val = run_state.score
            }
            score_events_in_frame.val += 1
            try_trigger_chest_from_score(elapsed)
          }
        }
      }
      None => ()
    }
  }
}

///|
pub fn collector_system(_world : @ecs.World) -> Unit {
  score_events_in_frame.val = 0
  let elapsed = run_elapsed_seconds()
  let to_remove : Array[@entity.Entity] = []
  let entities = coin_entities.keys()
  for entity in entities {
    match coin_entities.get(entity) {
      Some(coin) => {
        coin.life_time += @time.delta()
        coin_entities.set(entity, coin)
      }
      None => ()
    }
    match coin_world_position(entity) {
      Some(pos) => {
        if pos.y <= COIN_DESPAWN_Y || pos.z >= COIN_DESPAWN_Z {
          to_remove.push(entity)
          continue
        }
        if pos.z >= COLLECTOR_Z && pos.y <= COLLECTOR_Y_MAX {
          let slot = slot_multiplier_for_x(pos.x)
          add_score_event(slot, elapsed)
          to_remove.push(entity)
          continue
        }
      }
      None => to_remove.push(entity)
    }
  }

  for entity in to_remove {
    destroy_coin_entity(entity)
  }

  for _ in 0..<score_events_in_frame.val {
    try_trigger_chest_from_score(elapsed)
    if chest_state.pending {
      break
    }
  }
}

///|
fn coin_cleanup_priority(entity : @entity.Entity, coin : Coin) -> Double {
  let pos = match coin_world_position(entity) {
    Some(value) => value
    None => @math.Vec3::zero()
  }
  let slow_bonus = if coin_speed_squared(entity) <= 0.7 * 0.7 {
    1000.0
  } else {
    0.0
  }
  slow_bonus + abs_double(pos.z - COIN_SPAWN_Z) * 4.0 + coin.life_time
}

///|
fn trim_coin_overflow() -> Unit {
  while coin_entities.length() > COIN_LIMIT {
    let mut best_entity : @entity.Entity? = None
    let mut best_priority = -1.0
    for entity, coin in coin_entities {
      let priority = coin_cleanup_priority(entity, coin)
      if best_entity is None || priority > best_priority {
        best_entity = Some(entity)
        best_priority = priority
      }
    }
    match best_entity {
      Some(entity) => destroy_coin_entity(entity)
      None => break
    }
  }
}

///|
pub fn cleanup_system(_world : @ecs.World) -> Unit {
  trim_coin_overflow()
}

///|
pub fn chest_ui_system(_world : @ecs.World) -> Unit {
  let chest_visible = run_state.phase == ChestPick && chest_state.pending
  update_chest_visibility(chest_visible)
  if chest_visible {
    @ui.texts().set(chest_title_entity, @ui.Text::new("CHEST: PICK ONE"))
    for i in 0..<chest_option_text_entities.length() {
      let text = if i < chest_state.options.length() {
        let id = chest_state.options[i]
        "\{i + 1}. \{upgrade_display_name(id)}\n\{upgrade_description(id)}"
      } else {
        ""
      }
      @ui.texts().set(chest_option_text_entities[i], @ui.Text::new(text))
    }
  }
}

///|
pub fn hud_system(_world : @ecs.World) -> Unit {
  let minutes = @cmath.floor(run_state.time_left / 60.0).to_int()
  let seconds = @cmath.floor(run_state.time_left - minutes.to_double() * 60.0).to_int()
  let seconds_text = if seconds < 10 {
    "0" + seconds.to_string()
  } else {
    seconds.to_string()
  }
  let main = "COIN PUSHER 3D  TIME \{minutes}:\{seconds_text}  SCORE \{run_state.score}"
  let sub = "Charge \{economy_state.coin_charge}/\{economy_state.coin_charge_max}  CD \{round2(economy_state.drop_cooldown)}s  Tier \{board_state.difficulty_tier + 1}  Combo x\{round2(combo_multiplier(run_state.combo_count))}"

  let hint = match run_state.phase {
    Playing => "Mouse X: aim lane  LMB: drop coin  R: restart  Esc: exit"
    ChestPick => "CHEST OPEN: press 1/2/3 or click one card to choose"
    Finished =>
      "Run over. Press Enter/Space to restart, R to reroll now, Esc to exit"
  }
  set_hud_texts(main, sub, hint)

  if run_state.phase == Finished {
    update_summary_visibility(true)
    let (title, body) = summaries_text()
    if summary_title_text_cache.val != title {
      summary_title_text_cache.val = title
      @ui.texts().set(summary_title_entity, @ui.Text::new(title))
    }
    if summary_body_text_cache.val != body {
      summary_body_text_cache.val = body
      @ui.texts().set(summary_body_entity, @ui.Text::new(body))
    }
  } else {
    update_summary_visibility(false)
  }
}

///|
fn maybe_report_profile() -> Unit {
  if !profile_enabled.val {
    return
  }
  let now = @time.elapsed()
  if profile_frame_count.val == 0 {
    profile_started_at.val = now
    profile_last_report_at.val = now
  }
  profile_frame_count.val += 1
  profile_delta_accum.val += @time.frame_delta()
  let window_s = now - profile_last_report_at.val
  if window_s < PROFILE_REPORT_SECONDS {
    return
  }
  let frame_count = profile_frame_count.val
  let fps_window = if window_s <= 0.0 {
    0.0
  } else {
    frame_count.to_double() / window_s
  }
  let fps_avg = fps_window
  let fps_frame_dt = if profile_delta_accum.val <= 0.0 {
    0.0
  } else {
    frame_count.to_double() / profile_delta_accum.val
  }
  let avg_ms = if fps_frame_dt <= 0.0 { 0.0 } else { 1000.0 / fps_frame_dt }
  let sample_s = now - profile_started_at.val
  println(
    "[coinpusher3d][profile] fps_avg=\{fps_avg} fps_window=\{fps_window} fps_frame_dt=\{fps_frame_dt} avg_ms=\{avg_ms} window_s=\{window_s} sample_s=\{sample_s} phase=\{run_phase_name(run_state.phase)} score=\{run_state.score} coins=\{coin_entities.length()} charge=\{economy_state.coin_charge}/\{economy_state.coin_charge_max} tier=\{board_state.difficulty_tier + 1} pusher=\{round2(board_state.pusher_phase)}",
  )
  profile_frame_count.val = 0
  profile_delta_accum.val = 0.0
  profile_last_report_at.val = now
}

///|
pub fn capture_after_render_system(_world : @ecs.World) -> Unit {
  maybe_report_profile()
  if !debug_capture_enabled.val || debug_capture_taken.val {
    return
  }
  if @time.elapsed() - debug_capture_started_at.val <
    DEBUG_CAPTURE_DELAY_SECONDS {
    return
  }
  @host.take_screenshot(DEBUG_CAPTURE_PATH)
  println("[coinpusher3d][capture] path=\{DEBUG_CAPTURE_PATH}")
  debug_capture_taken.val = true
  @system.exit()
}

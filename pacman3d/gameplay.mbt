///|
let mouse_locked_last_frame : Ref[Bool] = { val: false }

///|
const DEBUG_CAPTURE_ENV : String = "PACMAN3D_CAPTURE"

///|
const DEBUG_PROFILE_ENV : String = "PACMAN3D_PROFILE"

///|
const DEBUG_CAPTURE_PATH : String = "pacman3d_capture.png"

///|
const DEBUG_CAPTURE_DELAY_SECONDS : Double = 4.0

///|
const PROFILE_REPORT_SECONDS : Double = 1.0

///|
const WORLD_CULL_DISTANCE_DEFAULT : Double = 14.0

///|
const WORLD_CULL_DISTANCE_PERF : Double = 8.0

///|
let debug_bootstrapped : Ref[Bool] = { val: false }

///|
let debug_capture_enabled : Ref[Bool] = { val: false }

///|
let debug_capture_started_at : Ref[Double] = { val: 0.0 }

///|
let debug_capture_taken : Ref[Bool] = { val: false }

///|
let debug_profile_enabled : Ref[Bool] = { val: false }

///|
let debug_profile_started_at : Ref[Double] = { val: 0.0 }

///|
let debug_profile_last_report_at : Ref[Double] = { val: 0.0 }

///|
let debug_profile_frame_count : Ref[Int] = { val: 0 }

///|
let debug_profile_delta_accum : Ref[Double] = { val: 0.0 }

///|
let debug_perf_mode : Ref[Bool] = { val: false }

///|
fn env_flag_enabled(name : String) -> Bool {
  match @env.get_env_var(name) {
    Some(raw) =>
      match raw {
        "1" | "true" | "TRUE" | "yes" | "YES" | "on" | "ON" => true
        _ => false
      }
    None => false
  }
}

///|
fn ensure_debug_runtime_state() -> Unit {
  if debug_bootstrapped.val {
    return
  }
  let started_at = @time.elapsed()
  debug_capture_enabled.val = env_flag_enabled(DEBUG_CAPTURE_ENV)
  debug_capture_started_at.val = started_at
  debug_capture_taken.val = false
  debug_profile_enabled.val = env_flag_enabled(DEBUG_PROFILE_ENV)
  debug_profile_started_at.val = started_at
  debug_profile_last_report_at.val = started_at
  debug_profile_frame_count.val = 0
  debug_profile_delta_accum.val = 0.0
  debug_perf_mode.val = debug_capture_enabled.val || debug_profile_enabled.val
  debug_bootstrapped.val = true
}

///|
fn maybe_report_profile() -> Unit {
  if !debug_profile_enabled.val {
    return
  }
  let now = @time.elapsed()
  debug_profile_frame_count.val += 1
  let window_s = now - debug_profile_last_report_at.val
  if window_s < PROFILE_REPORT_SECONDS {
    return
  }
  let frame_count = debug_profile_frame_count.val.to_double()
  let sample_s = now - debug_profile_started_at.val
  if sample_s < 1.5 {
    debug_profile_last_report_at.val = now
    debug_profile_frame_count.val = 0
    return
  }
  let fps_avg = if window_s <= 0.0001 { 0.0 } else { frame_count / window_s }
  let fps_window = fps_avg
  let fps_frame_dt = if window_s <= 0.0001 {
    0.0
  } else {
    frame_count / window_s
  }
  let fps = fps_avg.to_int()
  let avg_ms = if frame_count <= 0.0 {
    0.0
  } else {
    window_s * 1000.0 / frame_count
  }
  println(
    "[pacman3d][profile] fps_avg=\{fps_avg} fps_window=\{fps_window} fps_frame_dt=\{fps_frame_dt} fps=\{fps} avg_ms=\{avg_ms} window_s=\{window_s} sample_s=\{sample_s} level=\{current_level.val + 1} dots=\{collected_dots_count()}/\{dots.length()} ghosts=\{ghosts.length()}",
  )
  debug_profile_last_report_at.val = now
  debug_profile_frame_count.val = 0
  debug_profile_delta_accum.val = 0.0
}

///|
fn squared(value : Double) -> Double {
  value * value
}

///|
fn update_world_visibility() -> Unit {
  let cull_distance = if debug_perf_mode.val {
    WORLD_CULL_DISTANCE_PERF
  } else {
    WORLD_CULL_DISTANCE_DEFAULT
  }
  let cull_distance_sq = squared(cull_distance)
  let px = player_state.x
  let pz = player_state.z
  let is_visible = fn(x : Double, z : Double) -> Bool {
    squared(x - px) + squared(z - pz) <= cull_distance_sq
  }

  for entity in floor_entities {
    if @transform.transforms().get(entity) is Some(transform) {
      set_entity_visibility(
        entity,
        is_visible(transform.translation.x, transform.translation.z),
      )
    }
  }
  for entity in ceiling_entities {
    if debug_perf_mode.val {
      set_entity_visibility(entity, false)
    } else if @transform.transforms().get(entity) is Some(transform) {
      set_entity_visibility(
        entity,
        is_visible(transform.translation.x, transform.translation.z),
      )
    }
  }
  for entity in wall_entities {
    if @transform.transforms().get(entity) is Some(transform) {
      set_entity_visibility(
        entity,
        is_visible(transform.translation.x, transform.translation.z),
      )
    }
  }
  for dot in dots {
    if !dot.collected {
      set_entity_visibility(dot.entity, is_visible(dot.x, dot.z))
    }
  }
  for ghost in ghosts {
    let visible = is_visible(ghost.x, ghost.z)
    set_entity_visibility(ghost.entity, visible)
    set_entity_visibility(ghost.left_eye_entity, visible)
    set_entity_visibility(ghost.right_eye_entity, visible)
  }
}

///|
fn play_audio(
  path : String,
  volume? : Double = 1.0,
  loop_? : Bool = false,
) -> Unit {
  let source = @asset.load_audio(resolve_pacman_asset_path(path))
  if loop_ {
    ignore(
      @audio.spawn_audio(
        source,
        settings=@audio.PlaybackSettings::looped().with_volume(volume),
      ),
    )
  } else {
    @audio.play_one_shot(source, volume~)
  }
}

///|
fn dir_step(direction : Direction, speed : Double) -> (Double, Double) {
  match direction {
    Up => (0.0, -speed)
    Down => (0.0, speed)
    Left => (-speed, 0.0)
    Right => (speed, 0.0)
  }
}

///|
fn can_player_move_to(x : Double, z : Double) -> Bool {
  let r = PLAYER_RADIUS
  let corners : Array[(Double, Double)] = [
    (x - r, z - r),
    (x + r, z - r),
    (x - r, z + r),
    (x + r, z + r),
  ]
  for point in corners {
    if is_wall_world(point.0, point.1) {
      return false
    }
  }
  true
}

///|
fn can_ghost_move_to(x : Double, z : Double) -> Bool {
  let r = GHOST_RADIUS
  let corners : Array[(Double, Double)] = [
    (x - r, z - r),
    (x + r, z - r),
    (x - r, z + r),
    (x + r, z + r),
  ]
  for point in corners {
    if is_wall_world(point.0, point.1) {
      return false
    }
  }
  true
}

///|
fn collected_dots_count() -> Int {
  let mut count = 0
  for dot in dots {
    if dot.collected {
      count += 1
    }
  }
  count
}

///|
fn half_dots_collected() -> Bool {
  let total = dots.length()
  if total == 0 {
    return false
  }
  collected_dots_count() >= total / 2
}

///|
fn all_dots_collected() -> Bool {
  for dot in dots {
    if !dot.collected {
      return false
    }
  }
  true
}

///|
fn check_dot_collection() -> Unit {
  if lighting_debug.scene_enabled {
    return
  }
  for i in 0..<dots.length() {
    if dots[i].collected {
      continue
    }
    let dx = dots[i].x - player_state.x
    let dz = dots[i].z - player_state.z
    if squared(dx) + squared(dz) <= squared(DOT_PICKUP_RADIUS) {
      dots[i].collected = true
      @render3d.point_lights3d().remove(dots[i].entity)
      dots[i].entity.destroy()
      dots[i].minimap_entity.destroy()
      play_audio("assets/pacman3d/coin.wav")
      if all_dots_collected() {
        next_level()
        reset_level_entities()
      }
      return
    }
  }
}

///|
fn check_ghost_collision() -> Bool {
  if lighting_debug.scene_enabled {
    return false
  }
  let min_distance = PLAYER_RADIUS + GHOST_RADIUS
  let min_distance_sq = squared(min_distance)
  for ghost in ghosts {
    let dx = ghost.x - player_state.x
    let dz = ghost.z - player_state.z
    if squared(dx) + squared(dz) <= min_distance_sq {
      return true
    }
  }
  false
}

///|
pub fn player_input_system(_world : @ecs.World) -> Unit {
  let delta = @time.delta()
  if @inputs.is_just_pressed(KeyF) {
    lighting_debug.enabled = !lighting_debug.enabled
  }
  if @inputs.is_just_pressed(KeyG) {
    lighting_debug.light_mode = next_debug_light_mode(lighting_debug.light_mode)
  }
  if @inputs.is_just_pressed(KeyH) {
    lighting_debug.freeze_ghosts = !lighting_debug.freeze_ghosts
  }
  if @inputs.is_just_pressed(KeyJ) {
    lighting_debug.bobbing_enabled = !lighting_debug.bobbing_enabled
  }
  if @inputs.is_just_pressed(KeyK) {
    lighting_debug.scene_enabled = !lighting_debug.scene_enabled
    if lighting_debug.scene_enabled {
      apply_sandbox_debug_defaults()
    }
    reset_lighting_debug_tracking()
    reset_level_entities()
    mouse_locked_last_frame.val = @system.is_mouse_locked()
    return
  }
  if @inputs.is_just_pressed(KeyL) {
    lighting_debug.show_ghost_spot_rays = !lighting_debug.show_ghost_spot_rays
  }
  if @inputs.is_just_pressed(KeyM) {
    lighting_debug.material_mode = next_debug_material_mode(
      lighting_debug.material_mode,
    )
    if lighting_debug.scene_enabled {
      reset_level_entities()
      mouse_locked_last_frame.val = @system.is_mouse_locked()
      return
    }
  }
  if @inputs.is_just_pressed(KeyO) {
    lighting_debug.center_ghost_spot_origin = !lighting_debug.center_ghost_spot_origin
  }
  if @inputs.is_just_pressed(Tab) {
    cycle_tracked_ghost()
  }

  if @inputs.is_just_pressed(Escape) {
    if !mouse_locked_last_frame.val {
      request_exit()
    }
    mouse_locked_last_frame.val = @system.is_mouse_locked()
    return
  }

  if lighting_debug.scene_enabled {
    sync_camera_transform()
    update_world_visibility()
    mouse_locked_last_frame.val = @system.is_mouse_locked()
    return
  }

  if @inputs.just_pressed_mouse.left_button {
    @system.lock_mouse()
  }

  let mut move_x = 0.0
  let mut move_z = 0.0
  let forward_x = @cmath.cos(player_state.yaw)
  let forward_z = @cmath.sin(player_state.yaw)
  let right_x = @cmath.cos(player_state.yaw + @cmath.PI / 2.0)
  let right_z = @cmath.sin(player_state.yaw + @cmath.PI / 2.0)

  if @inputs.is_pressed(KeyW) {
    move_x += forward_x
    move_z += forward_z
  }
  if @inputs.is_pressed(KeyS) {
    move_x -= forward_x
    move_z -= forward_z
  }
  if @inputs.is_pressed(KeyA) {
    move_x -= right_x
    move_z -= right_z
  }
  if @inputs.is_pressed(KeyD) {
    move_x += right_x
    move_z += right_z
  }

  if move_x != 0.0 || move_z != 0.0 {
    let frame_step = PLAYER_SPEED * delta
    let target_x = player_state.x + move_x * frame_step
    let target_z = player_state.z + move_z * frame_step
    if can_player_move_to(target_x, player_state.z) {
      player_state.x = target_x
    }
    if can_player_move_to(player_state.x, target_z) {
      player_state.z = target_z
    }
  }

  if @system.is_mouse_locked() {
    player_state.yaw = @math.normalize_angle(
      player_state.yaw +
      @inputs.mouse_movement.movement[X] * PLAYER_TURN_SENSITIVITY,
    )
  }

  check_dot_collection()
  if check_ghost_collision() {
    play_audio("assets/pacman3d/hurt.wav")
    reset_level_entities()
  }
  sync_camera_transform()
  update_world_visibility()
  mouse_locked_last_frame.val = @system.is_mouse_locked()
}

///|
pub fn ghost_update_system(_world : @ecs.World) -> Unit {
  let delta = @time.delta()
  if lighting_debug.freeze_ghosts {
    return
  }
  for i in 0..<ghosts.length() {
    let ghost = ghosts[i]
    let speed = ghost_speed(ghost.ghost_type) * delta
    let (dx, dz) = dir_step(ghost.direction, speed)
    let target_x = ghost.x + dx
    let target_z = ghost.z + dz
    if can_ghost_move_to(target_x, target_z) {
      ghost.x = target_x
      ghost.z = target_z
    } else {
      ghost.direction = random_direction()
    }
    ghosts[i] = ghost
    sync_ghost_visuals(ghost)
  }
}

///|
pub fn minimap_system(_world : @ecs.World) -> Unit {
  if debug_perf_mode.val {
    set_entity_visibility(minimap_player_entity, false)
    for entity in minimap_tile_entities {
      set_entity_visibility(entity, false)
    }
    for dot in dots {
      set_entity_visibility(dot.minimap_entity, false)
    }
    for ghost in ghosts {
      set_entity_visibility(ghost.minimap_entity, false)
    }
    return
  }

  @transform.transforms().set(
    minimap_player_entity,
    transform_2d(
      minimap_pos_for_world(player_state.x, player_state.z, MINIMAP_MARKER_SIZE),
      1,
    ),
  )

  let show_ghosts = half_dots_collected()
  for ghost in ghosts {
    @transform.transforms().set(
      ghost.minimap_entity,
      transform_2d(
        minimap_pos_for_world(ghost.x, ghost.z, MINIMAP_MARKER_SIZE),
        1,
      ),
    )
    set_entity_visibility(ghost.minimap_entity, show_ghosts)
  }
}

///|
fn set_hud_text(
  entity : @entity.Entity,
  cache : Ref[String],
  content : String,
  position : @math.Vec2,
  font : String,
  color : String,
) -> Unit {
  ensure_entity_alive(entity)
  if cache.val == content {
    return
  }
  cache.val = content
  @ui.texts().set(entity, @ui.Text::new(content))
  @ui.text_fonts().set(entity, @ui.TextFont::from_css(font))
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(-0.5, 0.5)))
  @transform.transforms().set(entity, transform_2d(position, 200))
  set_entity_visibility(entity, true)
}

///|
fn hud_level_text() -> String {
  "Level: \{current_level.val + 1}"
}

///|
fn hud_completion_title() -> String {
  if completed_all_levels.val {
    "CONGRATULATIONS!"
  } else {
    ""
  }
}

///|
fn hud_completion_body() -> String {
  if completed_all_levels.val {
    "You completed all levels!"
  } else {
    ""
  }
}

///|
pub fn hud_system(_world : @ecs.World) -> Unit {
  set_hud_text(
    hud_title_ui,
    hud_title_text_cache,
    hud_level_text(),
    @math.Vec2(VIEWPORT_WIDTH - 140.0, 40.0),
    "36px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "white",
  )
  set_hud_text(
    hud_line1_ui,
    hud_line1_text_cache,
    hud_completion_title(),
    @math.Vec2(VIEWPORT_WIDTH / 2.0 - 170.0, 30.0),
    "32px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "rgb(0,255,0)",
  )
  set_hud_text(
    hud_line2_ui,
    hud_line2_text_cache,
    hud_completion_body(),
    @math.Vec2(VIEWPORT_WIDTH / 2.0 - 120.0, 70.0),
    "20px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "rgb(0,255,0)",
  )
  set_hud_text(
    hud_line3_ui,
    hud_line3_text_cache,
    "",
    @math.Vec2(0.0, 0.0),
    "18px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "white",
  )
  if lighting_debug.enabled {
    set_hud_text(
      hud_debug_ui,
      hud_debug_text_cache,
      debug_status_text() + "\n" + debug_help_text(),
      @math.Vec2(8.0, 8.0),
      "14px \{PACMAN_UPSTREAM_FONT_FAMILY}",
      "rgb(180,255,180)",
    )
  } else {
    set_hud_text(
      hud_debug_ui,
      hud_debug_text_cache,
      "",
      @math.Vec2(0.0, 0.0),
      "14px \{PACMAN_UPSTREAM_FONT_FAMILY}",
      "white",
    )
  }
}

///|
pub fn debug_runtime_system(_world : @ecs.World) -> Unit {
  ensure_debug_runtime_state()
  maybe_report_profile()
}

///|
pub fn capture_after_render_system(_world : @ecs.World) -> Unit {
  ensure_debug_runtime_state()
  if !debug_capture_enabled.val || debug_capture_taken.val {
    return
  }
  if @time.elapsed() - debug_capture_started_at.val <
    DEBUG_CAPTURE_DELAY_SECONDS {
    return
  }
  @raylib.take_screenshot(DEBUG_CAPTURE_PATH)
  println("[pacman3d][capture] path=\{DEBUG_CAPTURE_PATH}")
  debug_capture_taken.val = true
  request_exit()
}

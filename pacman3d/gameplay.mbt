///|
fn squared(value : Double) -> Double {
  value * value
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
  for i in 0..<dots.length() {
    if dots[i].collected {
      continue
    }
    let dx = dots[i].x - player_state.x
    let dz = dots[i].z - player_state.z
    if squared(dx) + squared(dz) <= squared(DOT_PICKUP_RADIUS) {
      dots[i].collected = true
      @render3d.point_lights3d.remove(dots[i].entity)
      dots[i].entity.destroy()
      dots[i].minimap_entity.destroy()
      play_audio("pacman3d/assets/coin.wav")
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
pub fn player_input_system(delta : Double) -> Unit {
  if @inputs.is_just_pressed(Escape) {
    request_exit()
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
    play_audio("pacman3d/assets/hurt.wav")
    reset_level_entities()
  }
  sync_camera_transform()
}

///|
pub fn ghost_update_system(delta : Double) -> Unit {
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
pub fn minimap_system(_delta : Double) -> Unit {
  @transform.positions.set(
    minimap_player_entity,
    minimap_pos_for_world(player_state.x, player_state.z, MINIMAP_MARKER_SIZE),
  )

  let show_ghosts = half_dots_collected()
  for ghost in ghosts {
    @transform.positions.set(
      ghost.minimap_entity,
      minimap_pos_for_world(ghost.x, ghost.z, MINIMAP_MARKER_SIZE),
    )
    if @sprite.sprites.get(ghost.minimap_entity) is Some(sprite) {
      sprite.visible = show_ghosts
    }
  }
}

///|
fn set_hud_text(
  entity : @entity.Entity,
  content : String,
  position : @math.Vec2D,
  font : String,
  color : String,
) -> Unit {
  let text = @sprite.Text::new(content, color~, font~, baseline=Top, align=Left)
  @sprite.sprites.set(entity, @sprite.Sprite::from_text(text, 200))
  @transform.positions.set(entity, position)
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
pub fn hud_system(_delta : Double) -> Unit {
  set_hud_text(
    hud_title_ui,
    hud_level_text(),
    @math.Vec2D(VIEWPORT_WIDTH - 140.0, 40.0),
    "36px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "white",
  )
  set_hud_text(
    hud_line1_ui,
    hud_completion_title(),
    @math.Vec2D(VIEWPORT_WIDTH / 2.0 - 170.0, 30.0),
    "32px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "rgb(0,255,0)",
  )
  set_hud_text(
    hud_line2_ui,
    hud_completion_body(),
    @math.Vec2D(VIEWPORT_WIDTH / 2.0 - 120.0, 70.0),
    "20px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "rgb(0,255,0)",
  )
  set_hud_text(
    hud_line3_ui,
    "",
    @math.Vec2D(0.0, 0.0),
    "18px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "white",
  )
}

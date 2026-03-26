///|
fn handle_world_shortcuts() -> Unit {
  if @inputs.is_just_pressed(KeyQ) {
    reset_runtime_world(@level.WorldType::Infinite, @env.now())
  }
  if @inputs.is_just_pressed(KeyZ) {
    reset_runtime_world(@level.WorldType::Finite, @env.now())
  }
  if @inputs.is_just_pressed(KeyX) {
    reset_runtime_world(@level.WorldType::Flat, @env.now())
  }
  if @inputs.is_just_pressed(KeyC) {
    reset_runtime_world(@level.WorldType::PreClassic, @env.now())
  }
  if @inputs.is_just_pressed(KeyR) {
    let seed = match world_session.val {
      Some(session) => session.seed
      None => @env.now()
    }
    let world_type = match world_session.val {
      Some(session) => session.world_type
      None => @level.WorldType::Infinite
    }
    reset_runtime_world(world_type, seed)
  }
}

///|
fn handle_mouse_lock_and_exit() -> Unit {
  if @inputs.just_pressed_mouse.left_button && !inventory_state.val.open {
    @system.lock_mouse()
  }
  if @inputs.is_just_pressed(Escape) {
    if inventory_state.val.open {
      inventory_state.val = { ..inventory_state.val, open: false }
      return
    }
    if @system.is_mouse_locked() {
      return
    }
    @system.exit()
  }
}

///|
fn cycle_hotbar(step : Int) -> Unit {
  player_controller.val = {
    ..player_controller.val,
    selected_hotbar_index: wrap_hotbar_index(
      player_controller.val.selected_hotbar_index + step,
    ),
  }
}

///|
fn handle_hotbar_inputs() -> Unit {
  let wheel_y = @inputs.mouse_wheel.delta[Y]
  if inventory_state.val.open {
    if wheel_y > 0.0 {
      inventory_state.val = {
        ..inventory_state.val,
        scroll_row: (inventory_state.val.scroll_row - 1).clamp(
          min=0,
          max=max_inventory_scroll_row(),
        ),
      }
    } else if wheel_y < 0.0 {
      inventory_state.val = {
        ..inventory_state.val,
        scroll_row: (inventory_state.val.scroll_row + 1).clamp(
          min=0,
          max=max_inventory_scroll_row(),
        ),
      }
    }
    return
  }
  if @inputs.is_just_pressed(Tab) {
    cycle_hotbar(if @inputs.is_pressed(ShiftLeft) { -1 } else { 1 })
  }
  if wheel_y > 0.0 {
    cycle_hotbar(-1)
  } else if wheel_y < 0.0 {
    cycle_hotbar(1)
  }
}

///|
fn handle_inventory_toggle() -> Unit {
  if @inputs.is_just_pressed(KeyE) {
    let next_open = !inventory_state.val.open
    inventory_state.val = {
      ..inventory_state.val,
      open: next_open,
      cursor: if next_open {
        @math.Vec2D(VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0)
      } else {
        inventory_state.val.cursor
      },
    }
  }
}

///|
fn update_inventory_cursor() -> Unit {
  if !inventory_state.val.open {
    return
  }
  let movement = @inputs.mouse_movement.movement
  inventory_state.val = {
    ..inventory_state.val,
    cursor: @math.Vec2D(
      inventory_state.val.cursor[X] + movement[X],
      inventory_state.val.cursor[Y] + movement[Y],
    ),
  }
  clamp_inventory_cursor()
}

///|
fn handle_inventory_clicks() -> Unit {
  if !inventory_state.val.open || !@inputs.just_pressed_mouse.left_button {
    return
  }
  let cursor = screen_cursor_position()
  for slot_index in 0..<INVENTORY_VISIBLE_SLOTS {
    let rect = inventory_slot_screen_rect(slot_index)
    if point_in_rect(cursor, rect) {
      let catalog_index = visible_inventory_index(slot_index)
      if catalog_index >= 0 &&
        catalog_index < inventory_state.val.catalog.length() {
        let hotbar_index = wrap_hotbar_index(
          player_controller.val.selected_hotbar_index,
        )
        inventory_state.val.hotbar[hotbar_index] = { catalog_index, }
      }
      return
    }
  }
}

///|
fn handle_player_look() -> Unit {
  if inventory_state.val.open || !@system.is_mouse_locked() {
    return
  }
  let movement = @inputs.mouse_movement.movement
  player_controller.val = {
    ..player_controller.val,
    yaw: player_controller.val.yaw + movement[X] * PLAYER_LOOK_SENSITIVITY,
    pitch: (player_controller.val.pitch - movement[Y] * PLAYER_LOOK_SENSITIVITY).clamp(
      min=-MAX_PITCH,
      max=MAX_PITCH,
    ),
  }
}

///|
fn handle_interactions() -> Unit {
  if inventory_state.val.open || !@system.is_mouse_locked() {
    return
  }
  if @inputs.just_pressed_mouse.middle_button {
    sample_hit_to_hotbar()
  }
  guard current_catalog_entry() is Some(entry) else { return }
  if @inputs.just_pressed_mouse.left_button {
    match selection_state.val.hit {
      Some(hit) =>
        apply_use_action(
          @item.use_item(entry.name, category_name(entry.category), [
            hit.wx,
            hit.wy,
            hit.wz,
          ]),
        )
      None => ()
    }
  }
  if @inputs.just_pressed_mouse.right_button {
    match selection_state.val.hit {
      Some(hit) =>
        apply_use_on_action(
          @item.use_item_on(
            entry.name,
            category_name(entry.category),
            [hit.wx, hit.wy, hit.wz],
            [hit.place_wx, hit.place_wy, hit.place_wz],
            (
              Float::from_double(hit.point.x),
              Float::from_double(hit.point.y),
              Float::from_double(hit.point.z),
            ),
          ),
        )
      None => ()
    }
  }
}

///|
fn refresh_world_material_bindings_if_needed() -> Unit {
  if world_material_rebind_frames_left.val <= 0 {
    return
  }
  refresh_world_material_bindings()
  world_material_rebind_frames_left.val -= 1
}

///|
pub fn update_system(_world : @ecs.World) -> Unit {
  if DEBUG_FRAME_LOG_LIMIT > 0 &&
    debug_update_counter.val < DEBUG_FRAME_LOG_LIMIT {
    let position = player_controller.val.position
    let wx = position.x.floor().to_int()
    let wy = position.y.floor().to_int()
    let wz = position.z.floor().to_int()
    let below = get_block_long_id(wx, wy - 1, wz)
    let feet = get_block_long_id(wx, wy, wz)
    println(
      "[mooncraft][frame \{debug_update_counter.val}] pos=\{position} vel=\{player_controller.val.velocity} on_ground=\{player_controller.val.on_ground} below=\{below} feet=\{feet}",
    )
    debug_update_counter.val += 1
  }
  handle_world_shortcuts()
  handle_mouse_lock_and_exit()
  handle_hotbar_inputs()
  handle_inventory_toggle()
  update_inventory_cursor()
  handle_inventory_clicks()
  handle_player_look()
  handle_interactions()
  refresh_world_material_bindings_if_needed()
  if !inventory_state.val.open {
    resolve_player_motion(@time.delta())
  }
  stream_chunks_step()
  update_selection_state()
  sync_camera_transform()
  sync_selection_visuals()
  sync_hud()
  sync_hotbar()
  sync_inventory()
}

///|
pub fn capture_after_render_system(_world : @ecs.World) -> Unit {
  if !DEBUG_CAPTURE_ENABLED ||
    debug_capture_taken.val ||
    @time.elapsed() - debug_started_at.val < DEBUG_CAPTURE_DELAY {
    return
  }
  let frame = @render3d.get_extracted_frame3d()
  let camera_text = match frame.camera {
    Some(camera) =>
      "camera_pos=\{camera.position} camera_target=\{camera.target} items=\{frame.items.length()}"
    None => "camera_pos=<none> items=\{frame.items.length()}"
  }
  let first_item_text = match frame.items.get(0) {
    Some(item) =>
      "first_item_translation=\{item.transform.translation} scale=\{item.transform.scale}"
    None => "first_item_translation=<none>"
  }
  println("[mooncraft][capture] \{camera_text}")
  println("[mooncraft][capture] \{first_item_text}")
  @raylib.take_screenshot(DEBUG_CAPTURE_PATH)
  println("[mooncraft][capture] path=\{DEBUG_CAPTURE_PATH}")
  debug_capture_taken.val = true
  @system.exit()
}

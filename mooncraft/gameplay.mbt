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
        @math.Vec2(VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0)
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
    cursor: @math.Vec2(
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
      "[mooncraft][frame \{debug_update_counter.val}] pos=\{debug_vec3_string(position)} vel=\{debug_vec3_string(player_controller.val.velocity)} on_ground=\{player_controller.val.on_ground} below=\{below} feet=\{feet}",
    )
    debug_update_counter.val += 1
  }
  if capture_enabled.val {
    refresh_world_material_bindings_if_needed()
    if !debug_capture_ready_started.val {
      stream_chunks_step()
      update_selection_state()
      sync_camera_transform()
      sync_selection_visuals()
      sync_hud()
      sync_hotbar()
      sync_inventory()
      let has_visible_chunk_mesh = match player_chunk_mesh_counts() {
        Some((normal_count, leaf_count, translucent_count)) =>
          normal_count + leaf_count + translucent_count > 0
        None => false
      }
      if player_chunk_column_loaded() &&
        has_visible_chunk_mesh &&
        startup_reach_hit() is Some(_) {
        debug_capture_ready_started.val = true
        debug_capture_ready_at.val = @time.elapsed_raw()
        // Start capture perf sampling on the next frame to avoid
        // counting the readiness-transition frame, which can be spike-heavy.
        debug_capture_ready_frames.val = 0
        debug_capture_ready_delta.val = 0.0
      }
      // Keep the sampled capture scene static for stable perf evidence.
      // Skip an initial warmup window after readiness to avoid startup spikes.
    } else if @time.elapsed_raw() - debug_capture_ready_at.val >=
      DEBUG_CAPTURE_WARMUP {
      debug_capture_ready_frames.val += 1
      debug_capture_ready_delta.val += @time.frame_delta()
    }
    profile_frame_counter.val += 1
    return
  }
  let shortcuts_started_at = profile_phase_begin("frame.shortcuts")
  handle_world_shortcuts()
  profile_phase_end("frame.shortcuts", shortcuts_started_at)

  let input_started_at = profile_phase_begin("frame.input")
  handle_mouse_lock_and_exit()
  handle_hotbar_inputs()
  handle_inventory_toggle()
  update_inventory_cursor()
  handle_inventory_clicks()
  profile_phase_end("frame.input", input_started_at)

  let interaction_started_at = profile_phase_begin("frame.interaction")
  handle_player_look()
  handle_interactions()
  profile_phase_end("frame.interaction", interaction_started_at)

  let material_started_at = profile_phase_begin("frame.material_rebind")
  refresh_world_material_bindings_if_needed()
  profile_phase_end("frame.material_rebind", material_started_at)

  let motion_started_at = profile_phase_begin("frame.motion")
  // Keep capture-mode perf stable by freezing player motion before auto-exit.
  if !capture_enabled.val && !inventory_state.val.open {
    resolve_player_motion(@time.delta())
  }
  profile_phase_end("frame.motion", motion_started_at)

  let stream_started_at = profile_phase_begin("frame.chunk_stream")
  // Keep streaming active until the playable capture gate is reached.
  if !capture_enabled.val || !debug_capture_ready_started.val {
    stream_chunks_step()
  }
  profile_phase_end("frame.chunk_stream", stream_started_at)

  let demo_started_at = profile_phase_begin("frame.demo_spawn")
  maybe_spawn_demo_entities()
  profile_phase_end("frame.demo_spawn", demo_started_at)

  let selection_started_at = profile_phase_begin("frame.selection")
  update_selection_state()
  profile_phase_end("frame.selection", selection_started_at)

  let sync_started_at = profile_phase_begin("frame.sync")
  sync_camera_transform()
  sync_selection_visuals()
  sync_hud()
  sync_hotbar()
  sync_inventory()
  profile_phase_end("frame.sync", sync_started_at)
  profile_frame_counter.val += 1
}

///|
pub fn capture_after_render_system(_world : @ecs.World) -> Unit {
  if !capture_enabled.val || debug_capture_taken.val {
    return
  }
  if !debug_capture_ready_started.val {
    return
  }
  let ready_elapsed = @time.elapsed_raw() - debug_capture_ready_at.val
  if ready_elapsed < DEBUG_CAPTURE_WARMUP + DEBUG_CAPTURE_DELAY {
    return
  }
  let ready_frames = debug_capture_ready_frames.val
  let average_fps = if ready_elapsed <= 0.0 {
    0.0
  } else {
    ready_frames.to_double() / ready_elapsed
  }
  let ready_delta = debug_capture_ready_delta.val
  let fps_frame_dt = if ready_delta <= 0.0 {
    0.0
  } else {
    ready_frames.to_double() / ready_delta
  }
  println(
    "[mooncraft][perf] avg_fps=\{average_fps} fps_frame_dt=\{fps_frame_dt} frames=\{ready_frames} elapsed=\{ready_elapsed} delta=\{ready_delta}",
  )
  let frame = @render3d.get_extracted_frame3d()
  let (loaded_chunks, total_chunks) = chunk_runtime_stats()
  let mesh_counts_text = match player_chunk_mesh_counts() {
    Some((normal_count, leaf_count, translucent_count)) =>
      "mesh_counts=(\{normal_count},\{leaf_count},\{translucent_count})"
    None => "mesh_counts=<none>"
  }
  let camera_text = match frame.camera {
    Some(camera) =>
      "camera_pos=\{debug_vec3_string(camera.position)} camera_target=\{debug_vec3_string(camera.target)} items=\{frame.items.length()}"
    None => "camera_pos=<none> items=\{frame.items.length()}"
  }
  let first_item_text = match frame.items.get(0) {
    Some(item) =>
      "first_item_translation=\{debug_vec3_string(item.transform.translation)} scale=\{debug_vec3_string(item.transform.scale)}"
    None => "first_item_translation=<none>"
  }
  println("[mooncraft][capture] \{camera_text}")
  println("[mooncraft][capture] \{first_item_text}")
  let wx = player_controller.val.position.x.floor().to_int()
  let wy = player_controller.val.position.y.floor().to_int()
  let wz = player_controller.val.position.z.floor().to_int()
  let cx = @util.floor_div(wx, @level.CHUNK_X_SIZE)
  let cy = @util.floor_div(wy, @level.CHUNK_Y_SIZE)
  let cz = @util.floor_div(wz, @level.CHUNK_Z_SIZE)
  let center_chunk_text = match ensure_chunk_record(cx, cy, cz) {
    Some(record) => {
      let transform_text = match record.opaque_entity {
        Some(entity) =>
          match @transform.transforms().get(entity) {
            Some(transform) =>
              "opaque_transform=\{debug_vec3_string(transform.translation)}"
            None => "opaque_transform=<none>"
          }
        None => "opaque_transform=<missing>"
      }
      "center_chunk=(\{cx},\{cy},\{cz}) loaded=\{record.loaded} opaque_entity=\{record.opaque_entity is Some(_)} cutout_entity=\{record.cutout_entity is Some(_)} translucent_entity=\{record.translucent_entity is Some(_)} \{transform_text}"
    }
    None => "center_chunk=(\{cx},\{cy},\{cz}) record=<none>"
  }
  println("[mooncraft][capture] \{center_chunk_text}")
  println(
    "[mooncraft][capture] loaded_chunks=\{loaded_chunks}/\{total_chunks} \{mesh_counts_text}",
  )
  @host.take_screenshot(DEBUG_CAPTURE_PATH)
  println("[mooncraft][capture] path=\{DEBUG_CAPTURE_PATH}")
  debug_capture_taken.val = true
  @system.exit()
}

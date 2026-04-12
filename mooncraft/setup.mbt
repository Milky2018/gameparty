///|
fn initialize_inventory_once() -> Unit {
  if inventory_state.val.catalog.length() > 0 {
    return
  }
  let catalog = build_creative_catalog()
  inventory_state.val = {
    ..inventory_state.val,
    catalog,
    hotbar: default_hotbar_slots(catalog),
  }
}

///|
fn initialize_camera_and_lighting() -> Unit {
  ensure_entity_alive(camera_entity)
  ensure_entity_alive(light_entity)
  @transform.transforms().set(camera_entity, {
    translation: @math.Vec3::new(0.0, 80.0, 0.0),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  @camera3d.cameras3d().set(camera_entity, {
    ..@camera3d.Camera3DComponent::default(),
    clear_color: color_rgba(132U, 194U, 255U, 1.0),
    fov_y: 72.0,
    near: 0.01,
    far: if capture_enabled.val {
      96.0
    } else {
      512.0
    },
  })
  @transform.transforms().set(light_entity, {
    translation: @math.Vec3::new(0.0, 24.0, 0.0),
    rotation: @math.Quat::from_axis_angle(@math.Vec3::x_axis(), -0.88) *
    @math.Quat::from_axis_angle(@math.Vec3::y_axis(), -0.55),
    scale: @math.Vec3::one(),
  })
  @render3d.directional_lights3d().set(light_entity, {
    ..@render3d.default_directional_light3d(),
    color: color_rgba(255U, 249U, 238U, 1.0),
    intensity: 1.25,
    shadows: false,
  })
  @render3d.set_ambient_light3d(
    Some({ color: color_rgba(140U, 164U, 196U, 1.0), intensity: 0.18 }),
  )
}

///|
fn prime_initial_chunks() -> Unit {
  // Aggressively prewarm nearby chunks so the first visible frame does not
  // show large terrain holes around the spawn column.
  let prewarm_steps = if capture_enabled.val {
    STARTUP_CHUNK_PREWARM_STEPS * 2
  } else {
    STARTUP_CHUNK_PREWARM_STEPS
  }
  for _ in 0..<prewarm_steps {
    stream_chunks_step_with_budget(
      STARTUP_CHUNK_GENERATE_BUDGET,
      STARTUP_CHUNK_REBUILD_BUDGET,
      STARTUP_CHUNK_UNLOAD_BUDGET,
    )
    if capture_enabled.val {
      let has_visible_chunk_mesh = match player_chunk_mesh_counts() {
        Some((normal_count, leaf_count, translucent_count)) =>
          normal_count + leaf_count + translucent_count > 0
        None => false
      }
      if player_chunk_column_loaded() && has_visible_chunk_mesh {
        break
      }
    } else if player_chunk_column_loaded() && chunk_stream_idle() {
      break
    }
  }
}

///|
fn reset_runtime_world(world_type : @level.WorldType, seed : UInt64) -> Unit {
  let reset_started_at = profile_phase_begin("startup.reset_runtime_world")
  debug_update_counter.val = 0
  debug_capture_taken.val = false
  debug_capture_ready_started.val = false
  debug_capture_ready_at.val = 0.0
  debug_capture_ready_frames.val = 0
  debug_capture_ready_delta.val = 0.0
  debug_first_mesh_logged.val = false
  profile_frame_counter.val = 0
  demo_spawn_pending.val = demo_entities_enabled.val
  demo_spawn_delay_frames.val = if demo_entities_enabled.val {
    DEMO_SPAWN_DELAY_FRAMES
  } else {
    0
  }
  world_material_rebind_frames_left.val = 0
  let preserved_hotbar = inventory_state.val.hotbar.copy()
  let preserved_selection = wrap_hotbar_index(
    player_controller.val.selected_hotbar_index,
  )
  let clear_started_at = profile_phase_begin("startup.clear_demo_and_chunks")
  clear_demo_entities()
  reset_chunk_runtime()
  profile_phase_end("startup.clear_demo_and_chunks", clear_started_at)

  let session_started_at = profile_phase_begin("startup.create_world_session")
  world_session.val = Some(create_world_session(seed, world_type))
  profile_phase_end("startup.create_world_session", session_started_at)

  let state_started_at = profile_phase_begin("startup.reset_player_and_ui")
  let spawned_position = spawn_player_position()
  let initial_position = if capture_enabled.val &&
    world_type is @level.WorldType::Flat {
    // Keep capture-mode camera inside the single loaded chunk so terrain is
    // visible even with the reduced capture streaming radius.
    @math.Vec3::new(
      CHUNK_WORLD_SIZE_X.to_double() * 0.5 + 0.5,
      spawned_position.y,
      CHUNK_WORLD_SIZE_Z.to_double() * 0.5 + 0.5,
    )
  } else {
    spawned_position
  }
  selection_state.val = {
    hit: None,
    preview_long_id: None,
    preview_valid: false,
  }
  player_controller.val = {
    position: initial_position,
    velocity: @math.Vec3::zero(),
    yaw: DEFAULT_PLAYER_YAW,
    pitch: DEFAULT_PLAYER_PITCH,
    on_ground: true,
    selected_hotbar_index: preserved_selection,
  }
  inventory_state.val = {
    ..inventory_state.val,
    open: false,
    cursor: @math.Vec2D(VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0),
    scroll_row: 0,
    hotbar: if preserved_hotbar.length() == HOTBAR_SIZE {
      preserved_hotbar
    } else {
      default_hotbar_slots(inventory_state.val.catalog)
    },
  }
  profile_phase_end("startup.reset_player_and_ui", state_started_at)

  let prewarm_started_at = profile_phase_begin("startup.prime_chunks")
  prime_initial_chunks()
  profile_phase_end("startup.prime_chunks", prewarm_started_at)

  let view_started_at = profile_phase_begin("startup.choose_initial_view")
  let (initial_yaw, initial_pitch) = choose_initial_view_angles()
  let capture_yaw = if capture_enabled.val &&
    world_type is @level.WorldType::Flat {
    @cmath.PI * 0.25
  } else {
    initial_yaw
  }
  let capture_pitch = if capture_enabled.val &&
    world_type is @level.WorldType::Flat {
    -0.8
  } else {
    initial_pitch
  }
  player_controller.val = {
    ..player_controller.val,
    yaw: capture_yaw,
    pitch: capture_pitch,
  }
  profile_phase_end("startup.choose_initial_view", view_started_at)

  if DEBUG_VERBOSE_STARTUP {
    let hit_text = match startup_reach_hit() {
      Some(hit) => {
        let block_text = match @block.lookup_by_long_id(hit.long_id) {
          Some(block) => "\{block.name}#\{hit.long_id}"
          None => "unknown#\{hit.long_id}"
        }
        "hit=(\{hit.wx}, \{hit.wy}, \{hit.wz}) place=(\{hit.place_wx}, \{hit.place_wy}, \{hit.place_wz}) block=\{block_text}"
      }
      None => "hit=<none>"
    }
    println(
      "[mooncraft][startup] seed=\{seed} world=\{world_type_name(world_type)} player=\{player_controller.val.position} on_ground=\{player_controller.val.on_ground} yaw=\{player_controller.val.yaw} pitch=\{player_controller.val.pitch} column_ready=\{player_chunk_column_loaded()} \{hit_text}",
    )
    match player_chunk_mesh_counts() {
      Some((normal_count, leaf_count, translucent_count)) =>
        println(
          "[mooncraft][chunk] normal=\{normal_count} leaf=\{leaf_count} translucent=\{translucent_count} debug_unlit=\{DEBUG_FORCE_WORLD_UNLIT}",
        )
      None => println("[mooncraft][chunk] unavailable")
    }
    match world_session.val {
      Some(session) => {
        let sample : Array[String] = []
        let max = if session.texture_names.length() < 32 {
          session.texture_names.length()
        } else {
          32
        }
        for i in 0..<max {
          sample.push("\{i}:\{session.texture_names[i]}")
        }
        let sample_text = sample.join(", ")
        println("[mooncraft][textures] \{sample_text}")
      }
      None => ()
    }
  }
  let sync_started_at = profile_phase_begin("startup.initial_sync")
  sync_camera_transform()
  sync_selection_visuals()
  sync_hud()
  sync_hotbar()
  sync_inventory()
  profile_phase_end("startup.initial_sync", sync_started_at)
  // Start capture/profile wall-time after startup so QA runs reflect steady-state gameplay.
  debug_started_at.val = @time.elapsed_raw()
  profile_phase_end("startup.reset_runtime_world", reset_started_at)
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  profile_enabled.val = env_flag_enabled(DEBUG_PROFILE_ENV)
  capture_enabled.val = env_flag_enabled(DEBUG_CAPTURE_ENV)
  demo_entities_enabled.val = if capture_enabled.val {
    env_flag_enabled(DEBUG_DEMO_ENTITIES_ENV)
  } else {
    true
  }
  register_mooncraft_font_once()
  let system_started_at = profile_phase_begin("startup.system")
  @ui.set_ui_scale_mode(@ui.UiScaleMode::Viewport)
  let materials_started_at = profile_phase_begin("startup.register_materials")
  register_world_materials_once()
  profile_phase_end("startup.register_materials", materials_started_at)

  let inventory_started_at = profile_phase_begin("startup.inventory")
  initialize_inventory_once()
  profile_phase_end("startup.inventory", inventory_started_at)

  let camera_started_at = profile_phase_begin("startup.camera_and_lighting")
  initialize_camera_and_lighting()
  profile_phase_end("startup.camera_and_lighting", camera_started_at)

  let seed = @env.now()
  let startup_world = if capture_enabled.val {
    @level.WorldType::Flat
  } else {
    @level.WorldType::Infinite
  }
  reset_runtime_world(startup_world, seed)
  profile_phase_end("startup.system", system_started_at)
}

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
    far: 512.0,
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
  prime_player_chunk_neighborhood(1)
  for _ in 0..<12 {
    stream_chunks_step()
    if player_chunk_neighborhood_loaded(1) {
      return
    }
  }
}

///|
fn reset_runtime_world(world_type : @level.WorldType, seed : UInt64) -> Unit {
  debug_update_counter.val = 0
  debug_started_at.val = @time.elapsed()
  debug_capture_taken.val = false
  debug_first_mesh_logged.val = false
  // Work around backend sync order (materials submitted before images):
  // rebind textured world materials for a few early frames.
  world_material_rebind_frames_left.val = 60
  let preserved_hotbar = inventory_state.val.hotbar.copy()
  let preserved_selection = wrap_hotbar_index(
    player_controller.val.selected_hotbar_index,
  )
  clear_demo_entities()
  reset_chunk_runtime()
  world_session.val = Some(create_world_session(seed, world_type))
  selection_state.val = {
    hit: None,
    preview_long_id: None,
    preview_valid: false,
  }
  player_controller.val = {
    position: spawn_player_position(),
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
  prime_initial_chunks()
  let (initial_yaw, initial_pitch) = choose_initial_view_angles()
  player_controller.val = {
    ..player_controller.val,
    yaw: initial_yaw,
    pitch: initial_pitch,
  }
  if DEBUG_VERBOSE_STARTUP {
    let hit_text = match startup_reach_hit() {
      Some(hit) =>
        "hit=(\{hit.wx}, \{hit.wy}, \{hit.wz}) place=(\{hit.place_wx}, \{hit.place_wy}, \{hit.place_wz})"
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
  spawn_demo_entities()
  sync_camera_transform()
  sync_selection_visuals()
  sync_hud()
  sync_hotbar()
  sync_inventory()
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  @ui.set_ui_scale_mode(@ui.UiScaleMode::Viewport)
  register_world_materials_once()
  load_demo_scene_handles_once()
  initialize_inventory_once()
  initialize_camera_and_lighting()
  let seed = @env.now()
  let startup_world = @level.WorldType::Infinite
  reset_runtime_world(startup_world, seed)
}

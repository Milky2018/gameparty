///|
test "icon_texture_to_asset_path flattens slashes" {
  inspect(
    icon_texture_to_asset_path("classic/oak_log"),
    content="mooncraft/assets/textures/classic__oak_log.png",
  )
}

///|
test "wrap_hotbar_index wraps negative and positive indexes" {
  inspect(wrap_hotbar_index(-1), content="8")
  inspect(wrap_hotbar_index(9), content="0")
  inspect(wrap_hotbar_index(10), content="1")
}

///|
test "default_hotbar_slots fills nine entries" {
  let catalog = build_creative_catalog()
  inspect(default_hotbar_slots(catalog).length(), content="9")
}

///|
test "build_registry_and_texture_names returns matching texture metadata" {
  let (registry, texture_names, texture_name_to_index, texture_colors) = build_registry_and_texture_names()
  ignore(registry)
  inspect(texture_names.length() > 0, content="true")
  inspect(texture_names.length() == 81, content="true")
  inspect(texture_names.length() <= ATLAS_COLUMNS * ATLAS_ROWS, content="true")
  inspect(texture_names[23] == "grass_carried", content="true")
  inspect(texture_names[40] == "sand", content="true")
  inspect(texture_names[52] == "glass", content="true")
  inspect(texture_names[68] == "oak_leaves", content="true")
  inspect(texture_names[72] == "torch", content="true")
  inspect(
    texture_name_to_index.contains(@block.fallback_texture),
    content="true",
  )
  inspect(texture_colors.length() == texture_names.length(), content="true")
}

///|
test "create_world_session keeps requested world type" {
  let session = create_world_session(7UL, @level.WorldType::Flat)
  inspect(world_type_name(session.world_type), content="Flat")
}

///|
test "create_world_session finds a safe spawn column" {
  let session = create_world_session(1774433487UL, @level.WorldType::Infinite)
  inspect(session.spawn_surface_y >= @level.SEA_LEVEL - 6, content="true")
  inspect(session.spawn_surface_y <= @level.SEA_LEVEL + 28, content="true")
  inspect(
    @level.find_spawn_column(session.world).2 == session.spawn_surface_y,
    content="true",
  )
}

///|
fn spawn_chunk_mesh_count(kind : @level.WorldType) -> Int {
  let session = create_world_session(17UL, kind)
  let hint_y = @util.floor_div(session.spawn_surface_y, @level.CHUNK_Y_SIZE)
  let hint_x = @util.floor_div(session.spawn_wx, @level.CHUNK_X_SIZE)
  let hint_z = @util.floor_div(session.spawn_wz, @level.CHUNK_Z_SIZE)
  let chunk = session.world.generate_chunk(hint_x, hint_y, hint_z)
  let light = Bytes::make(
    @level.CHUNK_X_SIZE * @level.CHUNK_Y_SIZE * @level.CHUNK_Z_SIZE,
    b'\x0f',
  )
  let mesh = @block.build_chunk_mesh_split(
    session.registry,
    chunk.tile_map.copy(),
    light,
    @level.CHUNK_X_SIZE,
  )
  mesh.normal.count + mesh.leaf.count + mesh.translucent.count
}

///|
fn spawn_chunk_layer_max(kind : @level.WorldType, seed : UInt64) -> Int {
  let session = create_world_session(seed, kind)
  let hint_y = @util.floor_div(session.spawn_surface_y, @level.CHUNK_Y_SIZE)
  let hint_x = @util.floor_div(session.spawn_wx, @level.CHUNK_X_SIZE)
  let hint_z = @util.floor_div(session.spawn_wz, @level.CHUNK_Z_SIZE)
  let chunk = session.world.generate_chunk(hint_x, hint_y, hint_z)
  let light = Bytes::make(
    @level.CHUNK_X_SIZE * @level.CHUNK_Y_SIZE * @level.CHUNK_Z_SIZE,
    b'\x0f',
  )
  let mesh = @block.build_chunk_mesh_split(
    session.registry,
    chunk.tile_map.copy(),
    light,
    @level.CHUNK_X_SIZE,
  )
  let mut max_layer = 0
  let scan = fn(layers : Array[Float]) {
    for value in layers {
      let layer = value.round().to_int()
      if layer > max_layer {
        max_layer = layer
      }
    }
  }
  scan(mesh.normal.layers)
  scan(mesh.leaf.layers)
  scan(mesh.translucent.layers)
  max_layer
}

///|
test "surface height hint lands on non-empty spawn chunk for every world type" {
  inspect(
    spawn_chunk_mesh_count(@level.WorldType::Infinite) > 0,
    content="true",
  )
  inspect(spawn_chunk_mesh_count(@level.WorldType::Finite) > 0, content="true")
  inspect(spawn_chunk_mesh_count(@level.WorldType::Flat) > 0, content="true")
  inspect(
    spawn_chunk_mesh_count(@level.WorldType::PreClassic) > 0,
    content="true",
  )
}

///|
test "spawn chunk texture layers stay within atlas capacity" {
  let max_layer = spawn_chunk_layer_max(
    @level.WorldType::Infinite,
    1774494186000UL,
  )
  inspect(max_layer <= 80, content="true")
}

///|
test "world chunk material uses nearest non-mipmap sampler" {
  let atlas_image = @render3d.register_image_asset({ path: ATLAS_PATH })
  let material = world_chunk_material(
    atlas_image,
    @render3d.AlphaMode3D::Opaque,
  )
  guard material.base_color_texture is Some(binding) else {
    inspect(false, content="true")
    return
  }
  inspect(binding.texcoord_set == 0, content="true")
  inspect(
    binding.sampler.min_filter is @render3d.TextureFilter3D::Nearest,
    content="true",
  )
  inspect(
    binding.sampler.mag_filter is @render3d.TextureFilter3D::Nearest,
    content="true",
  )
  inspect(binding.sampler.mipmap_filter is None, content="true")
  inspect(material.unlit, content="false")
}

///|
test "set_block_long_id marks self and neighbor chunks dirty at boundaries" {
  reset_chunk_runtime()
  world_session.val = Some(create_world_session(11UL, @level.WorldType::Flat))
  let session = world_session.val.unwrap()
  let chunk_y = session.chunk_min_y
  let world_y = chunk_y * @level.CHUNK_Y_SIZE
  ignore(ensure_chunk_record(0, chunk_y, 0))
  ignore(ensure_chunk_record(1, chunk_y, 0))
  set_block_long_id(
    @level.CHUNK_X_SIZE - 1,
    world_y,
    0,
    @block.name_to_long_id("stone"),
  )
  let self_key = @level.chunk_key_by_chunk_xyz(0, chunk_y, 0)
  let neighbor_key = @level.chunk_key_by_chunk_xyz(1, chunk_y, 0)
  inspect(chunk_store.val.get(self_key).unwrap().dirty, content="true")
  inspect(chunk_store.val.get(neighbor_key).unwrap().dirty, content="true")
}

///|
test "spawn_player_position returns a supported non-overlapping position" {
  reset_chunk_runtime()
  world_session.val = Some(create_world_session(13UL, @level.WorldType::Flat))
  let position = spawn_player_position()
  inspect(!player_overlaps_world_at(position), content="true")
  inspect(player_supported_at(position), content="true")
}

///|
test "camera rotation forward matches look direction" {
  player_controller.val = { ..player_controller.val, yaw: 0.37, pitch: -0.41 }
  let look = look_direction()
  let forward = camera_rotation().rotate_vec3(@math.Vec3::new(0.0, 0.0, -1.0))
  inspect((look - forward).length() < 0.000001, content="true")
}

///|
test "prime initial chunks performs minimal startup prewarm" {
  initialize_inventory_once()
  register_world_materials_once()
  load_demo_scene_handles_once()
  reset_chunk_runtime()
  world_session.val = Some(create_world_session(7UL, @level.WorldType::Finite))
  player_controller.val = {
    position: spawn_player_position(),
    velocity: @math.Vec3::zero(),
    yaw: 0.0,
    pitch: -0.22,
    on_ground: false,
    selected_hotbar_index: 0,
  }
  prime_initial_chunks()
  let (loaded, total) = chunk_runtime_stats()
  inspect(loaded > 0, content="true")
  inspect(total > 0, content="true")
}

///|
fn startup_view_hits_ground(
  world_type : @level.WorldType,
  seed : UInt64,
) -> Bool {
  initialize_inventory_once()
  register_world_materials_once()
  load_demo_scene_handles_once()
  reset_chunk_runtime()
  reset_runtime_world(world_type, seed)
  raycast_blocks(player_eye_position(), look_direction(), PLAYER_REACH)
  is Some(_)
}

///|
test "default finite startup view can see ground" {
  inspect(
    startup_view_hits_ground(@level.WorldType::Finite, 5UL),
    content="true",
  )
}

///|
test "default infinite startup view can see ground for representative seeds" {
  inspect(
    startup_view_hits_ground(@level.WorldType::Infinite, 5UL),
    content="true",
  )
  inspect(
    startup_view_hits_ground(@level.WorldType::Infinite, 1774433487UL),
    content="true",
  )
  inspect(
    startup_view_hits_ground(@level.WorldType::Infinite, 23UL),
    content="true",
  )
  inspect(
    startup_view_hits_ground(@level.WorldType::Infinite, 67UL),
    content="true",
  )
}

///|
test "face_from_transition maps stepped cell transitions to hit faces" {
  inspect(
    face_from_transition(0, 0, 0, 1, 0, 0) is Some(@shape.FaceName::NegX),
    content="true",
  )
  inspect(
    face_from_transition(0, 0, 0, 0, 1, 0) is Some(@shape.FaceName::NegY),
    content="true",
  )
  inspect(
    face_from_transition(0, 0, 0, 0, 0, -1) is Some(@shape.FaceName::PosZ),
    content="true",
  )
}

///|
test "sample_hit_to_hotbar swaps current slot to the selected block family" {
  let catalog = build_creative_catalog()
  inventory_state.val = {
    ..inventory_state.val,
    catalog,
    hotbar: default_hotbar_slots(catalog),
  }
  player_controller.val = { ..player_controller.val, selected_hotbar_index: 0 }
  selection_state.val = {
    hit: Some({
      wx: 0,
      wy: 0,
      wz: 0,
      place_wx: 0,
      place_wy: 1,
      place_wz: 0,
      face: @shape.FaceName::PosY,
      long_id: @block.name_to_long_id("glass"),
      point: @math.Vec3::zero(),
      distance: 1.0,
    }),
    preview_long_id: None,
    preview_valid: false,
  }
  sample_hit_to_hotbar()
  let entry = current_catalog_entry().unwrap()
  inspect(entry.name, content="glass")
}

///|
test "player settles onto terrain after startup" {
  initialize_inventory_once()
  register_world_materials_once()
  load_demo_scene_handles_once()
  reset_chunk_runtime()
  reset_runtime_world(@level.WorldType::Infinite, 1774433487UL)
  inspect(player_controller.val.on_ground, content="true")
}

///|
test "reset runtime world keeps startup view within player reach after settling" {
  initialize_inventory_once()
  register_world_materials_once()
  load_demo_scene_handles_once()
  reset_chunk_runtime()
  reset_runtime_world(@level.WorldType::Infinite, 1774433487UL)
  inspect(startup_reach_hit() is Some(_), content="true")
}

///|
test "player remains supported for two seconds after startup" {
  initialize_inventory_once()
  register_world_materials_once()
  load_demo_scene_handles_once()
  reset_chunk_runtime()
  reset_runtime_world(@level.WorldType::Infinite, 1774433487UL)
  let start_y = player_controller.val.position.y
  for _ in 0..<120 {
    resolve_player_motion(1.0 / 60.0)
  }
  inspect(player_controller.val.position.y >= start_y - 0.1, content="true")
  inspect(player_controller.val.on_ground, content="true")
}

///|
test "large frame delta does not tunnel player through ground" {
  initialize_inventory_once()
  register_world_materials_once()
  load_demo_scene_handles_once()
  reset_chunk_runtime()
  reset_runtime_world(@level.WorldType::Infinite, 1774433487UL)
  let start_y = player_controller.val.position.y
  resolve_player_motion(0.5)
  inspect(player_controller.val.position.y >= start_y - 0.1, content="true")
  inspect(player_controller.val.on_ground, content="true")
}

///|
fn startup_view_hits_ground_with_reach(
  world_type : @level.WorldType,
  seed : UInt64,
  reach : Double,
) -> Bool {
  initialize_inventory_once()
  register_world_materials_once()
  load_demo_scene_handles_once()
  reset_chunk_runtime()
  reset_runtime_world(world_type, seed)
  raycast_blocks(player_eye_position(), look_direction(), reach) is Some(_)
}

///|
test "default infinite startup view can see nearby ground within player reach" {
  inspect(
    startup_view_hits_ground_with_reach(
      @level.WorldType::Infinite,
      1774433487UL,
      PLAYER_REACH,
    ),
    content="true",
  )
}

///|
test "safe spawn works across multiple infinite seeds" {
  let seeds : Array[UInt64] = [
    1UL, 2UL, 3UL, 5UL, 23UL, 67UL, 97UL, 521UL, 4096UL, 65535UL, 20260325UL, 1774433487UL,
    1774494186000UL,
  ]
  for seed in seeds {
    inspect(
      startup_view_hits_ground_with_reach(
        @level.WorldType::Infinite,
        seed,
        PLAYER_REACH,
      ),
      content="true",
    )
  }
}

///|
test "runtime screenshot seed remains supported for one second after startup" {
  initialize_inventory_once()
  register_world_materials_once()
  load_demo_scene_handles_once()
  reset_chunk_runtime()
  reset_runtime_world(@level.WorldType::Infinite, 1774494186000UL)
  let start_y = player_controller.val.position.y
  for _ in 0..<60 {
    resolve_player_motion(1.0 / 60.0)
  }
  inspect(player_controller.val.position.y >= start_y - 0.1, content="true")
  inspect(player_controller.val.on_ground, content="true")
}

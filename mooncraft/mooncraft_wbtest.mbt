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
  let (registry, texture_names, texture_name_to_index) = build_registry_and_texture_names()
  ignore(registry)
  inspect(texture_names.length() > 0, content="true")
  inspect(
    texture_name_to_index.contains(@block.fallback_texture),
    content="true",
  )
}

///|
test "create_world_session keeps requested world type" {
  let session = create_world_session(7UL, @level.WorldType::Flat)
  inspect(world_type_name(session.world_type), content="Flat")
}

///|
fn spawn_chunk_mesh_count(kind : @level.WorldType) -> Int {
  let session = create_world_session(17UL, kind)
  let hint_y = @util.floor_div(
    @level.surface_height(session.world, SPAWN_BLOCK_X, SPAWN_BLOCK_Z),
    @level.CHUNK_Y_SIZE,
  )
  let chunk = session.world.generate_chunk(0, hint_y, 0)
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
test "spawn_player_position finds a non-colliding spawn" {
  reset_chunk_runtime()
  world_session.val = Some(create_world_session(13UL, @level.WorldType::Flat))
  let position = spawn_player_position()
  inspect(player_collides_at(position), content="false")
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

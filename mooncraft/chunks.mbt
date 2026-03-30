///|
fn fullbright_chunk_light(size : Int) -> Bytes {
  Bytes::make(size * size * size, b'\x0f')
}

///|
fn padded_fullbright_chunk_light(size : Int) -> Bytes {
  let padded = size + 2
  Bytes::make(padded * padded * padded, b'\x0f')
}

///|
fn create_world_session(
  seed : UInt64,
  world_type : @level.WorldType,
) -> WorldSession {
  let world = @level.World::new(seed~, world_type~)
  let (registry, texture_names, texture_name_to_index, texture_colors) = build_registry_and_texture_names()
  // Avoid expensive full-ring spawn probing on startup: use a fast surface
  // sample near origin, then let runtime safe-spawn validation adjust locally.
  let spawn_wx = 0
  let spawn_wz = 0
  let spawn_surface_y = @level.surface_height(world, spawn_wx, spawn_wz)
  let hint_y = @util.floor_div(spawn_surface_y, @level.CHUNK_Y_SIZE)
  {
    seed,
    world_type,
    spawn_wx,
    spawn_wz,
    spawn_surface_y,
    chunk_radius: CHUNK_RADIUS_XZ,
    chunk_min_y: hint_y - 2,
    chunk_max_y: hint_y + 2,
    world,
    registry,
    texture_names,
    texture_name_to_index,
    texture_colors,
  }
}

///|
fn queue_push_unique(queue : Array[String], key : String) -> Unit {
  if !queue.contains(key) {
    queue.push(key)
  }
}

///|
fn release_chunk_mesh(mesh : @render3d.MeshHandle?) -> Unit {
  match mesh {
    Some(handle) => @render3d.release_mesh_asset(handle)
    None => ()
  }
}

///|
fn release_chunk_entity(entity : @entity.Entity?) -> Unit {
  match entity {
    Some(node) => node.destroy()
    None => ()
  }
}

///|
fn reset_chunk_runtime() -> Unit {
  for _, record in chunk_store.val {
    release_chunk_mesh(record.opaque_mesh)
    release_chunk_mesh(record.cutout_mesh)
    release_chunk_mesh(record.translucent_mesh)
    release_chunk_entity(record.opaque_entity)
    release_chunk_entity(record.cutout_entity)
    release_chunk_entity(record.translucent_entity)
  }
  chunk_store.val = Map::new()
  chunk_stream_queue.val = empty_queue()
}

///|
fn ensure_chunk_record(
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> ChunkRecord? {
  let key = @level.chunk_key_by_chunk_xyz(chunk_x, chunk_y, chunk_z)
  match chunk_store.val.get(key) {
    Some(record) => Some(record)
    None =>
      match world_session.val {
        None => None
        Some(session) =>
          if chunk_y < session.chunk_min_y || chunk_y > session.chunk_max_y {
            None
          } else {
            let chunk = session.world.generate_chunk(chunk_x, chunk_y, chunk_z)
            let record : ChunkRecord = {
              chunk_x,
              chunk_y,
              chunk_z,
              data: chunk.tile_map.copy(),
              light: fullbright_chunk_light(@level.CHUNK_X_SIZE),
              dirty: true,
              loaded: false,
              opaque_entity: None,
              cutout_entity: None,
              translucent_entity: None,
              opaque_mesh: None,
              cutout_mesh: None,
              translucent_mesh: None,
            }
            chunk_store.val.set(key, record)
            Some(record)
          }
      }
  }
}

///|
fn ensure_chunk_record_by_key(chunk_key : String) -> ChunkRecord? {
  let (chunk_x, chunk_y, chunk_z) = @level.chunk_xyz_by_chunk_key(chunk_key)
  ensure_chunk_record(chunk_x, chunk_y, chunk_z)
}

///|
fn get_block_long_id(wx : Int, wy : Int, wz : Int) -> UInt {
  guard world_session.val is Some(session) else { return @block.AIR_LONG_ID }
  let chunk_y = @util.floor_div(wy, @level.CHUNK_Y_SIZE)
  if chunk_y < session.chunk_min_y || chunk_y > session.chunk_max_y {
    return @block.AIR_LONG_ID
  }
  let chunk_x = @util.floor_div(wx, @level.CHUNK_X_SIZE)
  let chunk_z = @util.floor_div(wz, @level.CHUNK_Z_SIZE)
  guard ensure_chunk_record(chunk_x, chunk_y, chunk_z) is Some(record) else {
    return @block.AIR_LONG_ID
  }
  let (rx, ry, rz) = @level.get_relative_block_xyz(wx, wy, wz)
  record.data[@level.get_linear_block_index(rx, ry, rz)]
}

///|
fn mark_chunk_dirty(chunk_key : String) -> Unit {
  match chunk_store.val.get(chunk_key) {
    Some(record) => {
      record.dirty = true
      queue_push_unique(chunk_stream_queue.val.to_rebuild, chunk_key)
    }
    None => ()
  }
}

///|
fn set_block_long_id(wx : Int, wy : Int, wz : Int, long_id : UInt) -> Unit {
  let chunk_x = @util.floor_div(wx, @level.CHUNK_X_SIZE)
  let chunk_y = @util.floor_div(wy, @level.CHUNK_Y_SIZE)
  let chunk_z = @util.floor_div(wz, @level.CHUNK_Z_SIZE)
  guard ensure_chunk_record(chunk_x, chunk_y, chunk_z) is Some(record) else {
    return
  }
  let (rx, ry, rz) = @level.get_relative_block_xyz(wx, wy, wz)
  let block_index = @level.get_linear_block_index(rx, ry, rz)
  record.data[block_index] = long_id
  let chunk_key = @level.chunk_key_by_chunk_xyz(chunk_x, chunk_y, chunk_z)
  mark_chunk_dirty(chunk_key)
  if rx == 0 {
    mark_chunk_dirty(
      @level.chunk_key_by_chunk_xyz(chunk_x - 1, chunk_y, chunk_z),
    )
  }
  if rx == @level.CHUNK_X_SIZE - 1 {
    mark_chunk_dirty(
      @level.chunk_key_by_chunk_xyz(chunk_x + 1, chunk_y, chunk_z),
    )
  }
  if ry == 0 {
    mark_chunk_dirty(
      @level.chunk_key_by_chunk_xyz(chunk_x, chunk_y - 1, chunk_z),
    )
  }
  if ry == @level.CHUNK_Y_SIZE - 1 {
    mark_chunk_dirty(
      @level.chunk_key_by_chunk_xyz(chunk_x, chunk_y + 1, chunk_z),
    )
  }
  if rz == 0 {
    mark_chunk_dirty(
      @level.chunk_key_by_chunk_xyz(chunk_x, chunk_y, chunk_z - 1),
    )
  }
  if rz == @level.CHUNK_Z_SIZE - 1 {
    mark_chunk_dirty(
      @level.chunk_key_by_chunk_xyz(chunk_x, chunk_y, chunk_z + 1),
    )
  }
}

///|
fn build_chunk_data_padded(
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> Array[UInt] {
  let size = @level.CHUNK_X_SIZE
  let padded = size + 2
  let data = Array::make(padded * padded * padded, @block.AIR_LONG_ID)
  let index_of = fn(px : Int, py : Int, pz : Int) -> Int {
    (py * padded + pz) * padded + px
  }
  for px in 0..<padded {
    for py in 0..<padded {
      for pz in 0..<padded {
        let wx = chunk_x * size + px - 1
        let wy = chunk_y * size + py - 1
        let wz = chunk_z * size + pz - 1
        data[index_of(px, py, pz)] = get_block_long_id(wx, wy, wz)
      }
    }
  }
  data
}

///|
fn build_chunk_light_padded(
  _chunk_x : Int,
  _chunk_y : Int,
  _chunk_z : Int,
) -> Bytes {
  padded_fullbright_chunk_light(@level.CHUNK_X_SIZE)
}

///|
fn update_chunk_layer(
  entity_ref : @entity.Entity?,
  mesh_ref : @render3d.MeshHandle?,
  material_handle : @render3d.MaterialHandle,
  mesh_data : @block.MeshData,
  origin : @math.Vec3,
) -> (@entity.Entity?, @render3d.MeshHandle?) {
  if mesh_data.count == 0 {
    release_chunk_mesh(mesh_ref)
    release_chunk_entity(entity_ref)
    return (None, None)
  }
  let mesh_handle = @render3d.register_mesh_asset(
    mesh_asset_from_mesh_data(mesh_data),
  )
  let entity = match entity_ref {
    Some(existing) => {
      ensure_entity_alive(existing)
      existing
    }
    None => @entity.Entity::new()
  }
  @transform.transforms().set(entity, {
    translation: origin + chunk_mesh_center_offset(),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  @render3d.mesh3d_renderers().set(entity, {
    mesh: mesh_handle,
    material: material_handle,
    visible: true,
    cast_shadows: false,
    receive_shadows: false,
  })
  @visibility.visibilities().set(entity, Visible)
  release_chunk_mesh(mesh_ref)
  (Some(entity), Some(mesh_handle))
}

///|
fn rebuild_chunk_record(record : ChunkRecord) -> Unit {
  guard world_session.val is Some(session) else { return }
  guard opaque_material_handle.val is Some(opaque_material) else { return }
  guard cutout_material_handle.val is Some(cutout_material) else { return }
  guard translucent_material_handle.val is Some(translucent_material) else {
    return
  }
  let world_opaque_material = match
    (DEBUG_FORCE_WORLD_UNLIT, debug_marker_material_handle.val) {
    (true, Some(handle)) => handle
    _ => opaque_material
  }
  let world_cutout_material = match
    (DEBUG_FORCE_WORLD_UNLIT, debug_marker_material_handle.val) {
    (true, Some(handle)) => handle
    _ => cutout_material
  }
  let world_trans_material = match
    (DEBUG_FORCE_WORLD_UNLIT, debug_marker_material_handle.val) {
    (true, Some(handle)) => handle
    _ => translucent_material
  }
  let origin = chunk_world_origin(
    record.chunk_x,
    record.chunk_y,
    record.chunk_z,
  )
  let mesh = @block.build_chunk_mesh_split(
    session.registry,
    build_chunk_data_padded(record.chunk_x, record.chunk_y, record.chunk_z),
    build_chunk_light_padded(record.chunk_x, record.chunk_y, record.chunk_z),
    @level.CHUNK_X_SIZE,
  )
  let (opaque_entity, opaque_mesh) = update_chunk_layer(
    record.opaque_entity,
    record.opaque_mesh,
    world_opaque_material,
    mesh.normal,
    origin,
  )
  let (cutout_entity, cutout_mesh) = update_chunk_layer(
    record.cutout_entity,
    record.cutout_mesh,
    world_cutout_material,
    mesh.leaf,
    origin,
  )
  let (trans_entity, trans_mesh) = update_chunk_layer(
    record.translucent_entity,
    record.translucent_mesh,
    world_trans_material,
    mesh.translucent,
    origin,
  )
  record.opaque_entity = opaque_entity
  record.cutout_entity = cutout_entity
  record.translucent_entity = trans_entity
  record.opaque_mesh = opaque_mesh
  record.cutout_mesh = cutout_mesh
  record.translucent_mesh = trans_mesh
  record.loaded = true
  record.dirty = false
}

///|
fn queue_chunks_around_player() -> Unit {
  guard world_session.val is Some(session) else { return }
  let center_wx = player_controller.val.position.x.floor().to_int()
  let center_wz = player_controller.val.position.z.floor().to_int()
  let center_chunk_x = @util.floor_div(center_wx, @level.CHUNK_X_SIZE)
  let center_chunk_z = @util.floor_div(center_wz, @level.CHUNK_Z_SIZE)
  let desired = @level.collect_render_chunk_keys(
    center_chunk_x,
    center_chunk_z,
    session.chunk_radius,
    session.chunk_min_y,
    session.chunk_max_y,
  )
  let desired_map : Map[String, Bool] = Map::new()
  for idx in 0..<desired.length() {
    let key = desired[desired.length() - 1 - idx]
    desired_map.set(key, true)
    match chunk_store.val.get(key) {
      Some(record) =>
        if record.dirty || !record.loaded {
          queue_push_unique(chunk_stream_queue.val.to_rebuild, key)
        }
      None => queue_push_unique(chunk_stream_queue.val.to_generate, key)
    }
  }
  for key, _ in chunk_store.val {
    if !desired_map.contains(key) {
      queue_push_unique(chunk_stream_queue.val.to_unload, key)
    }
  }
}

///|
fn player_chunk_column_loaded() -> Bool {
  guard world_session.val is Some(session) else { return false }
  let center_wx = player_controller.val.position.x.floor().to_int()
  let center_wz = player_controller.val.position.z.floor().to_int()
  let center_chunk_x = @util.floor_div(center_wx, @level.CHUNK_X_SIZE)
  let center_chunk_z = @util.floor_div(center_wz, @level.CHUNK_Z_SIZE)
  for chunk_y in session.chunk_min_y..<=session.chunk_max_y {
    let key = @level.chunk_key_by_chunk_xyz(
      center_chunk_x, chunk_y, center_chunk_z,
    )
    guard chunk_store.val.get(key) is Some(record) else { return false }
    if !record.loaded {
      return false
    }
  }
  true
}

///|
fn chunk_runtime_stats() -> (Int, Int) {
  let mut loaded = 0
  let total = chunk_store.val.length()
  for _, record in chunk_store.val {
    if record.loaded {
      loaded += 1
    }
  }
  (loaded, total)
}

///|
fn player_chunk_mesh_counts() -> (Int, Int, Int)? {
  guard world_session.val is Some(session) else { return None }
  let center_wx = player_controller.val.position.x.floor().to_int()
  let center_wy = player_controller.val.position.y.floor().to_int()
  let center_wz = player_controller.val.position.z.floor().to_int()
  let center_chunk_x = @util.floor_div(center_wx, @level.CHUNK_X_SIZE)
  let center_chunk_y = @util.floor_div(center_wy, @level.CHUNK_Y_SIZE)
  let center_chunk_z = @util.floor_div(center_wz, @level.CHUNK_Z_SIZE)
  guard ensure_chunk_record(center_chunk_x, center_chunk_y, center_chunk_z)
    is Some(record) else {
    return None
  }
  let mesh = @block.build_chunk_mesh_split(
    session.registry,
    build_chunk_data_padded(record.chunk_x, record.chunk_y, record.chunk_z),
    build_chunk_light_padded(record.chunk_x, record.chunk_y, record.chunk_z),
    @level.CHUNK_X_SIZE,
  )
  Some((mesh.normal.count, mesh.leaf.count, mesh.translucent.count))
}

///|
fn process_generate_queue() -> Unit {
  let mut budget = CHUNK_GENERATE_BUDGET
  while budget > 0 && chunk_stream_queue.val.to_generate.length() > 0 {
    guard chunk_stream_queue.val.to_generate.pop() is Some(key) else { break }
    budget -= 1
    match ensure_chunk_record_by_key(key) {
      Some(record) =>
        if record.dirty || !record.loaded {
          queue_push_unique(chunk_stream_queue.val.to_rebuild, key)
        }
      None => ()
    }
  }
}

///|
fn process_rebuild_queue() -> Unit {
  let mut budget = CHUNK_REBUILD_BUDGET
  while budget > 0 && chunk_stream_queue.val.to_rebuild.length() > 0 {
    guard chunk_stream_queue.val.to_rebuild.pop() is Some(key) else { break }
    budget -= 1
    match chunk_store.val.get(key) {
      Some(record) =>
        if record.dirty || !record.loaded {
          rebuild_chunk_record(record)
        }
      None =>
        match ensure_chunk_record_by_key(key) {
          Some(record) => rebuild_chunk_record(record)
          None => ()
        }
    }
  }
}

///|
fn unload_chunk_record(record : ChunkRecord) -> Unit {
  release_chunk_mesh(record.opaque_mesh)
  release_chunk_mesh(record.cutout_mesh)
  release_chunk_mesh(record.translucent_mesh)
  release_chunk_entity(record.opaque_entity)
  release_chunk_entity(record.cutout_entity)
  release_chunk_entity(record.translucent_entity)
  record.opaque_entity = None
  record.cutout_entity = None
  record.translucent_entity = None
  record.opaque_mesh = None
  record.cutout_mesh = None
  record.translucent_mesh = None
  record.loaded = false
}

///|
fn process_unload_queue() -> Unit {
  let mut budget = CHUNK_UNLOAD_BUDGET
  while budget > 0 && chunk_stream_queue.val.to_unload.length() > 0 {
    guard chunk_stream_queue.val.to_unload.pop() is Some(key) else { break }
    budget -= 1
    match chunk_store.val.get(key) {
      Some(record) => {
        unload_chunk_record(record)
        chunk_store.val.remove(key)
      }
      None => ()
    }
  }
}

///|
fn stream_chunks_step() -> Unit {
  queue_chunks_around_player()
  process_generate_queue()
  process_rebuild_queue()
  process_unload_queue()
}

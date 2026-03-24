///|
fn vec3(x : Double, y : Double, z : Double) -> @math.Vec3 {
  @math.Vec3::new(x, y, z)
}

///|
fn player_aabb_min(position : @math.Vec3) -> @math.Vec3 {
  vec3(position.x - PLAYER_RADIUS, position.y, position.z - PLAYER_RADIUS)
}

///|
fn player_aabb_max(position : @math.Vec3) -> @math.Vec3 {
  vec3(
    position.x + PLAYER_RADIUS,
    position.y + PLAYER_HEIGHT,
    position.z + PLAYER_RADIUS,
  )
}

///|
fn player_eye_position() -> @math.Vec3 {
  vec3(
    player_controller.val.position.x,
    player_controller.val.position.y + PLAYER_EYE_HEIGHT,
    player_controller.val.position.z,
  )
}

///|
fn camera_rotation() -> @math.Quat {
  @math.Quat::from_axis_angle(@math.Vec3::y_axis(), player_controller.val.yaw) *
  @math.Quat::from_axis_angle(@math.Vec3::x_axis(), player_controller.val.pitch)
}

///|
fn look_direction() -> @math.Vec3 {
  let yaw = player_controller.val.yaw
  let pitch = player_controller.val.pitch
  vec3(
    @cmath.cos(yaw) * @cmath.cos(pitch),
    @cmath.sin(pitch),
    @cmath.sin(yaw) * @cmath.cos(pitch),
  ).normalize()
}

///|
fn forward_xz() -> (Double, Double) {
  let yaw = player_controller.val.yaw
  (@cmath.cos(yaw), @cmath.sin(yaw))
}

///|
fn right_xz() -> (Double, Double) {
  let (fx, fz) = forward_xz()
  (-fz, fx)
}

///|
fn block_center(wx : Int, wy : Int, wz : Int) -> @math.Vec3 {
  vec3(wx.to_double() + 0.5, wy.to_double() + 0.5, wz.to_double() + 0.5)
}

///|
fn world_to_block_cell(point : @math.Vec3) -> (Int, Int, Int) {
  (point.x.floor().to_int(), point.y.floor().to_int(), point.z.floor().to_int())
}

///|
fn aabb_intersects(
  a_min : @math.Vec3,
  a_max : @math.Vec3,
  b_min : @math.Vec3,
  b_max : @math.Vec3,
) -> Bool {
  a_min.x < b_max.x &&
  a_max.x > b_min.x &&
  a_min.y < b_max.y &&
  a_max.y > b_min.y &&
  a_min.z < b_max.z &&
  a_max.z > b_min.z
}

///|
fn axis_overlap(
  min_a : Double,
  max_a : Double,
  min_b : Double,
  max_b : Double,
) -> Bool {
  min_a < max_b && max_a > min_b
}

///|
fn collect_block_boxes_at(
  wx : Int,
  wy : Int,
  wz : Int,
) -> Array[(@math.Vec3, @math.Vec3)] {
  let boxes : Array[(@math.Vec3, @math.Vec3)] = []
  let long_id = get_block_long_id(wx, wy, wz)
  if long_id == @block.AIR_LONG_ID {
    return boxes
  }
  match @block.get_shape_desc(long_id) {
    Some(source) =>
      for box in source.boxes {
        let min = vec3(
          wx.to_double() + box.min[0].to_double(),
          wy.to_double() + box.min[1].to_double(),
          wz.to_double() + box.min[2].to_double(),
        )
        let max = vec3(
          wx.to_double() + box.max[0].to_double(),
          wy.to_double() + box.max[1].to_double(),
          wz.to_double() + box.max[2].to_double(),
        )
        boxes.push((min, max))
      }
    None => ()
  }
  boxes
}

///|
fn player_collides_at(position : @math.Vec3) -> Bool {
  let min = player_aabb_min(position)
  let max = player_aabb_max(position)
  let min_x = min.x.floor().to_int() - 1
  let max_x = max.x.floor().to_int() + 1
  let min_y = min.y.floor().to_int() - 1
  let max_y = max.y.floor().to_int() + 1
  let min_z = min.z.floor().to_int() - 1
  let max_z = max.z.floor().to_int() + 1
  for wx in min_x..<=max_x {
    for wy in min_y..<=max_y {
      for wz in min_z..<=max_z {
        for pair in collect_block_boxes_at(wx, wy, wz) {
          let (block_min, block_max) = pair
          if aabb_intersects(min, max, block_min, block_max) {
            return true
          }
        }
      }
    }
  }
  false
}

///|
fn position_with_axis(
  position : @math.Vec3,
  axis : Int,
  value : Double,
) -> @math.Vec3 {
  match axis {
    0 => vec3(value, position.y, position.z)
    1 => vec3(position.x, value, position.z)
    _ => vec3(position.x, position.y, value)
  }
}

///|
fn move_player_axis(
  position : @math.Vec3,
  axis : Int,
  delta : Double,
) -> (Double, Bool) {
  if delta == 0.0 {
    return (
      match axis {
        0 => position.x
        1 => position.y
        _ => position.z
      },
      false,
    )
  }
  let mut result = match axis {
    0 => position.x + delta
    1 => position.y + delta
    _ => position.z + delta
  }
  let mut collided = false
  let player_min_other = player_aabb_min(position)
  let player_max_other = player_aabb_max(position)
  let candidate = position_with_axis(position, axis, result)
  let candidate_min = player_aabb_min(candidate)
  let candidate_max = player_aabb_max(candidate)
  let min_x = candidate_min.x.floor().to_int() - 1
  let max_x = candidate_max.x.floor().to_int() + 1
  let min_y = candidate_min.y.floor().to_int() - 1
  let max_y = candidate_max.y.floor().to_int() + 1
  let min_z = candidate_min.z.floor().to_int() - 1
  let max_z = candidate_max.z.floor().to_int() + 1
  for wx in min_x..<=max_x {
    for wy in min_y..<=max_y {
      for wz in min_z..<=max_z {
        for pair in collect_block_boxes_at(wx, wy, wz) {
          let (block_min, block_max) = pair
          let overlap = match axis {
            0 =>
              axis_overlap(
                player_min_other.y,
                player_max_other.y,
                block_min.y,
                block_max.y,
              ) &&
              axis_overlap(
                player_min_other.z,
                player_max_other.z,
                block_min.z,
                block_max.z,
              )
            1 =>
              axis_overlap(
                player_min_other.x,
                player_max_other.x,
                block_min.x,
                block_max.x,
              ) &&
              axis_overlap(
                player_min_other.z,
                player_max_other.z,
                block_min.z,
                block_max.z,
              )
            _ =>
              axis_overlap(
                player_min_other.x,
                player_max_other.x,
                block_min.x,
                block_max.x,
              ) &&
              axis_overlap(
                player_min_other.y,
                player_max_other.y,
                block_min.y,
                block_max.y,
              )
          }
          if !overlap {
            continue
          }
          if delta > 0.0 {
            let limit = match axis {
              0 => block_min.x - PLAYER_RADIUS
              1 => block_min.y - PLAYER_HEIGHT
              _ => block_min.z - PLAYER_RADIUS
            }
            let player_max_axis = match axis {
              0 => result + PLAYER_RADIUS
              1 => result + PLAYER_HEIGHT
              _ => result + PLAYER_RADIUS
            }
            let block_min_axis = match axis {
              0 => block_min.x
              1 => block_min.y
              _ => block_min.z
            }
            if player_max_axis > block_min_axis && result > limit {
              result = limit
              collided = true
            }
          } else {
            let limit = match axis {
              0 => block_max.x + PLAYER_RADIUS
              1 => block_max.y
              _ => block_max.z + PLAYER_RADIUS
            }
            let player_min_axis = match axis {
              0 => result - PLAYER_RADIUS
              1 => result
              _ => result - PLAYER_RADIUS
            }
            let block_max_axis = match axis {
              0 => block_max.x
              1 => block_max.y
              _ => block_max.z
            }
            if player_min_axis < block_max_axis && result < limit {
              result = limit
              collided = true
            }
          }
        }
      }
    }
  }
  (result, collided)
}

///|
fn resolve_player_motion(delta : Double) -> Unit {
  let mut move_x = 0.0
  let mut move_z = 0.0
  if @inputs.is_pressed(KeyW) {
    move_z += 1.0
  }
  if @inputs.is_pressed(KeyS) {
    move_z -= 1.0
  }
  if @inputs.is_pressed(KeyA) {
    move_x -= 1.0
  }
  if @inputs.is_pressed(KeyD) {
    move_x += 1.0
  }
  let move_len = if move_x == 0.0 && move_z == 0.0 {
    0.0
  } else if move_x != 0.0 && move_z != 0.0 {
    1.41421356237
  } else {
    1.0
  }
  let (dir_x, dir_z) = if move_len == 0.0 {
    (0.0, 0.0)
  } else {
    (move_x / move_len, move_z / move_len)
  }
  let (forward_x, forward_z) = forward_xz()
  let (right_x, right_z) = right_xz()
  let speed = PLAYER_MOVE_SPEED *
    (if @inputs.is_pressed(ShiftLeft) { PLAYER_SLOW_MULTIPLIER } else { 1.0 })
  let velocity_x = (right_x * dir_x + forward_x * dir_z) * speed
  let velocity_z = (right_z * dir_x + forward_z * dir_z) * speed
  let controller = player_controller.val
  controller.velocity = vec3(velocity_x, controller.velocity.y, velocity_z)
  if controller.on_ground && @inputs.is_just_pressed(Space) {
    controller.velocity = vec3(
      controller.velocity.x,
      PLAYER_JUMP_SPEED,
      controller.velocity.z,
    )
    controller.on_ground = false
  }
  let mut position = controller.position
  let (next_x, _) = move_player_axis(position, 0, controller.velocity.x * delta)
  position = vec3(next_x, position.y, position.z)
  let (next_z, _) = move_player_axis(position, 2, controller.velocity.z * delta)
  position = vec3(position.x, position.y, next_z)
  let next_vel_y = (controller.velocity.y - PLAYER_GRAVITY * delta).max(
    -PLAYER_MAX_FALL_SPEED,
  )
  controller.velocity = vec3(
    controller.velocity.x,
    next_vel_y,
    controller.velocity.z,
  )
  let candidate_y = position.y + controller.velocity.y * delta
  let (next_y, collided_y) = move_player_axis(
    position,
    1,
    controller.velocity.y * delta,
  )
  let hit_ground = controller.velocity.y <= 0.0 &&
    collided_y &&
    next_y > candidate_y
  position = vec3(position.x, next_y, position.z)
  controller.on_ground = hit_ground
  if collided_y {
    controller.velocity = vec3(
      controller.velocity.x,
      0.0,
      controller.velocity.z,
    )
  }
  controller.position = position
  player_controller.val = controller
}

///|
fn spawn_player_position() -> @math.Vec3 {
  guard world_session.val is Some(session) else {
    return vec3(
      SPAWN_BLOCK_X.to_double() + 0.5,
      32.0,
      SPAWN_BLOCK_Z.to_double() + 0.5,
    )
  }
  let base_x = SPAWN_BLOCK_X.to_double() + 0.5
  let base_z = SPAWN_BLOCK_Z.to_double() + 0.5
  let surface_y = @level.surface_height(
    session.world,
    SPAWN_BLOCK_X,
    SPAWN_BLOCK_Z,
  )
  let mut position = vec3(
    base_x,
    surface_y.to_double() + SPAWN_SURFACE_OFFSET.to_double(),
    base_z,
  )
  while player_collides_at(position) {
    position = vec3(position.x, position.y + 1.0, position.z)
  }
  let step = 0.2
  while !player_collides_at(vec3(position.x, position.y - step, position.z)) {
    position = vec3(position.x, position.y - step, position.z)
    if position.y < surface_y.to_double() - 8.0 {
      break
    }
  }
  position
}

///|
fn face_from_transition(
  prev_wx : Int,
  prev_wy : Int,
  prev_wz : Int,
  wx : Int,
  wy : Int,
  wz : Int,
) -> @shape.FaceName? {
  let dx = wx - prev_wx
  let dy = wy - prev_wy
  let dz = wz - prev_wz
  if dx == 1 {
    Some(@shape.FaceName::NegX)
  } else if dx == -1 {
    Some(@shape.FaceName::PosX)
  } else if dy == 1 {
    Some(@shape.FaceName::NegY)
  } else if dy == -1 {
    Some(@shape.FaceName::PosY)
  } else if dz == 1 {
    Some(@shape.FaceName::NegZ)
  } else if dz == -1 {
    Some(@shape.FaceName::PosZ)
  } else {
    None
  }
}

///|
fn raycast_blocks(
  origin : @math.Vec3,
  direction : @math.Vec3,
  reach : Double,
) -> BlockHit? {
  let step = 0.05
  let mut last_point = origin
  let (start_wx, start_wy, start_wz) = world_to_block_cell(origin)
  let mut prev_wx = start_wx
  let mut prev_wy = start_wy
  let mut prev_wz = start_wz
  let mut distance = 0.0
  while distance <= reach {
    let point = vec3(
      origin.x + direction.x * distance,
      origin.y + direction.y * distance,
      origin.z + direction.z * distance,
    )
    let (wx, wy, wz) = world_to_block_cell(point)
    if wx != prev_wx || wy != prev_wy || wz != prev_wz {
      let long_id = get_block_long_id(wx, wy, wz)
      if long_id != @block.AIR_LONG_ID {
        match @block.lookup_by_long_id(long_id) {
          Some(block) if @block.Block::is_selectable(block) => {
            guard face_from_transition(prev_wx, prev_wy, prev_wz, wx, wy, wz)
              is Some(face) else {
              return None
            }
            return Some({
              wx,
              wy,
              wz,
              place_wx: prev_wx,
              place_wy: prev_wy,
              place_wz: prev_wz,
              face,
              long_id,
              point,
              distance,
            })
          }
          _ => ()
        }
      }
      prev_wx = wx
      prev_wy = wy
      prev_wz = wz
    }
    last_point = point
    distance += step
  }
  ignore(last_point)
  None
}

///|
fn can_place_block_local(long_id : UInt, wx : Int, wy : Int, wz : Int) -> Bool {
  match @block.get_shape_desc(long_id) {
    Some(source) => {
      if source.boxes.length() == 0 {
        return true
      }
      let player_min = player_aabb_min(player_controller.val.position)
      let player_max = player_aabb_max(player_controller.val.position)
      for box in source.boxes {
        let block_min = vec3(
          wx.to_double() + box.min[0].to_double(),
          wy.to_double() + box.min[1].to_double(),
          wz.to_double() + box.min[2].to_double(),
        )
        let block_max = vec3(
          wx.to_double() + box.max[0].to_double(),
          wy.to_double() + box.max[1].to_double(),
          wz.to_double() + box.max[2].to_double(),
        )
        if aabb_intersects(player_min, player_max, block_min, block_max) {
          return false
        }
      }
      true
    }
    None => true
  }
}

///|
fn replacement_long_id(neo : @item.UniqueNamePredicate) -> UInt? {
  for block in @block.blocks {
    if neo(block.name) {
      return Some(block.long_id())
    }
  }
  None
}

///|
fn apply_use_action(action : @item.UseAction) -> Unit {
  match action {
    @item.UseAction::None => ()
    @item.UseAction::BreakBlock(wx~, wy~, wz~) =>
      set_block_long_id(wx, wy, wz, @block.AIR_LONG_ID)
    @item.UseAction::Batch(actions) =>
      for nested in actions {
        apply_use_action(nested)
      }
  }
}

///|
fn apply_use_on_action(action : @item.UseOnAction) -> Unit {
  match action {
    @item.UseOnAction::None => ()
    @item.UseOnAction::ReplaceBlock(
      wx~,
      wy~,
      wz~,
      expected~,
      neo~,
      require_above_air~
    ) => {
      guard @block.lookup_by_long_id(get_block_long_id(wx, wy, wz))
        is Some(current) else {
        return
      }
      if !expected(current.name) {
        return
      }
      if require_above_air &&
        get_block_long_id(wx, wy + 1, wz) != @block.AIR_LONG_ID {
        return
      }
      match replacement_long_id(neo) {
        Some(long_id) => set_block_long_id(wx, wy, wz, long_id)
        None => ()
      }
    }
    @item.UseOnAction::PlaceBlock(
      target_wx~,
      target_wy~,
      target_wz~,
      place_wx~,
      place_wy~,
      place_wz~,
      name~,
      require_air~
    ) => {
      if require_air &&
        get_block_long_id(place_wx, place_wy, place_wz) != @block.AIR_LONG_ID {
        return
      }
      guard @block.lookup_by_name(name) is Some(block) else { return }
      let block_state = @block.compute_placement_state(
        block.long_id(),
        [target_wx, target_wy, target_wz],
        [place_wx, place_wy, place_wz],
        player_pos=[
          player_controller.val.position.x,
          player_controller.val.position.y,
          player_controller.val.position.z,
        ],
      )
      let long_id = block.long_id(state=block_state)
      if can_place_block_local(long_id, place_wx, place_wy, place_wz) {
        set_block_long_id(place_wx, place_wy, place_wz, long_id)
      }
    }
    @item.UseOnAction::Batch(actions) =>
      for nested in actions {
        apply_use_on_action(nested)
      }
  }
}

///|
fn sample_hit_to_hotbar() -> Unit {
  guard selection_state.val.hit is Some(hit) else { return }
  guard @block.lookup_by_long_id(hit.long_id) is Some(target_block) else {
    return
  }
  for index, entry in inventory_state.val.catalog {
    guard entry.block_long_id is Some(entry_long_id) else { continue }
    guard @block.lookup_by_long_id(entry_long_id) is Some(entry_block) else {
      continue
    }
    if entry_block.id == target_block.id {
      inventory_state.val.hotbar[player_controller.val.selected_hotbar_index] = {
        catalog_index: index,
      }
      return
    }
  }
}

///|
fn update_selection_state() -> Unit {
  let origin = player_eye_position()
  let direction = look_direction()
  selection_state.val = {
    hit: None,
    preview_long_id: None,
    preview_valid: false,
  }
  match raycast_blocks(origin, direction, PLAYER_REACH) {
    Some(hit) => {
      let next = selection_state.val
      next.hit = Some(hit)
      match current_catalog_entry() {
        Some(entry) if entry.category is @item.Block => {
          guard entry.block_long_id is Some(base_long_id) else {
            selection_state.val = next
            return
          }
          guard @block.lookup_by_name(entry.name) is Some(block) else {
            selection_state.val = next
            return
          }
          let placed_state = @block.compute_placement_state(
            base_long_id,
            [hit.wx, hit.wy, hit.wz],
            [hit.place_wx, hit.place_wy, hit.place_wz],
            player_pos=[
              player_controller.val.position.x,
              player_controller.val.position.y,
              player_controller.val.position.z,
            ],
          )
          let long_id = block.long_id(state=placed_state)
          next.preview_long_id = Some(long_id)
          next.preview_valid = can_place_block_local(
              long_id,
              hit.place_wx,
              hit.place_wy,
              hit.place_wz,
            ) &&
            get_block_long_id(hit.place_wx, hit.place_wy, hit.place_wz) ==
            @block.AIR_LONG_ID
        }
        _ => ()
      }
      selection_state.val = next
    }
    None => ()
  }
}

///|
fn sync_camera_transform() -> Unit {
  ensure_entity_alive(camera_entity)
  @transform.transforms().set(camera_entity, {
    translation: player_eye_position(),
    rotation: camera_rotation(),
    scale: @math.Vec3::one(),
  })
}

///|
fn sync_selection_visuals() -> Unit {
  guard cube_mesh_handle.val is Some(cube_mesh) else { return }
  guard selection_material_handle.val is Some(selection_material) else {
    return
  }
  guard preview_material_handle.val is Some(preview_material) else { return }
  ensure_entity_alive(selection_entity)
  ensure_entity_alive(preview_entity)
  match selection_state.val.hit {
    Some(hit) => {
      @transform.transforms().set(selection_entity, {
        translation: block_center(hit.wx, hit.wy, hit.wz),
        rotation: @math.Quat::identity(),
        scale: vec3(SELECTION_BOX_SIZE, SELECTION_BOX_SIZE, SELECTION_BOX_SIZE),
      })
      @render3d.mesh3d_renderers().set(selection_entity, {
        mesh: cube_mesh,
        material: selection_material,
        visible: true,
        cast_shadows: false,
        receive_shadows: false,
      })
      @visibility.visibilities().set(selection_entity, Visible)
    }
    None => @visibility.visibilities().set(selection_entity, Hidden)
  }
  if selection_state.val.preview_valid && selection_state.val.hit is Some(hit) {
    @transform.transforms().set(preview_entity, {
      translation: block_center(hit.place_wx, hit.place_wy, hit.place_wz),
      rotation: @math.Quat::identity(),
      scale: vec3(PREVIEW_BOX_SIZE, PREVIEW_BOX_SIZE, PREVIEW_BOX_SIZE),
    })
    @render3d.mesh3d_renderers().set(preview_entity, {
      mesh: cube_mesh,
      material: preview_material,
      visible: true,
      cast_shadows: false,
      receive_shadows: false,
    })
    @visibility.visibilities().set(preview_entity, Visible)
  } else {
    @visibility.visibilities().set(preview_entity, Hidden)
  }
}

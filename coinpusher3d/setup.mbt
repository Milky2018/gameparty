///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn set_entity_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn transform_2d(position : @math.Vec2, zindex : Int) -> @transform.Transform {
  {
    translation: @math.Vec3::new(position[X], position[Y], zindex.to_double()),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  }
}

///|
fn set_text_entity(
  entity : @entity.Entity,
  content : String,
  position : @math.Vec2,
  color : String,
  font? : String = "28px \{HUD_FONT_FAMILY}",
  zindex? : Int = UI_ZINDEX,
) -> Unit {
  ensure_entity_alive(entity)
  @ui.texts().set(entity, @ui.Text::new(content))
  @ui.text_fonts().set(entity, @ui.TextFont::from_css(font))
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(-0.5, 0.5)))
  @transform.transforms().set(entity, transform_2d(position, zindex))
  set_entity_visibility(entity, true)
}

///|
fn set_panel_color_entity(
  entity : @entity.Entity,
  color : @render.Color,
  size : @math.Vec2,
  center : @math.Vec2,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_color(color, size)
  sprite.anchor = @sprite.Anchor(@math.Vec2(0.0, 0.0))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_2d(center, zindex))
  set_entity_visibility(entity, true)
}

///|
fn world_transform(
  translation : @math.Vec3,
  rotation : @math.Quat,
  scale : @math.Vec3,
) -> @transform.Transform {
  { translation, rotation, scale }
}

///|
fn look_rotation(from : @math.Vec3, to : @math.Vec3) -> @math.Quat {
  let forward = (to - from).normalize()
  let mut right = forward.cross(@math.Vec3::y_axis())
  if right.length_squared() < 0.000001 {
    right = @math.Vec3::x_axis()
  }
  right = right.normalize()
  let up = right.cross(forward).normalize()
  @math.Quat::from_basis(
    right,
    up,
    @math.Vec3::new(-forward.x, -forward.y, -forward.z),
  )
}

///|
fn assign_static_body(
  entity : @entity.Entity,
  size : @math.Vec3,
  friction : Double,
  restitution : Double,
) -> Unit {
  @physics3d.rigid_bodies().set(entity, @physics3d.Fixed)
  @physics3d.colliders().set(
    entity,
    @physics3d.Collider::cuboid(size.scalar_mul(0.5)),
  )
  @physics3d.frictions().set(entity, @physics3d.Friction::new(friction))
  @physics3d.restitutions().set(
    entity,
    @physics3d.Restitution::new(restitution),
  )
}

///|
fn register_render_assets_once() -> Unit {
  if table_mesh_handle.val is Some(_) {
    return
  }

  register_font_once()

  table_mesh_handle.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(
        @math.Vec3::new(BOARD_WIDTH, BOARD_THICKNESS, BOARD_LENGTH),
      ),
    ),
  )
  pusher_mesh_handle.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(
        @math.Vec3::new(PUSHER_WIDTH, PUSHER_HEIGHT, PUSHER_DEPTH),
      ),
    ),
  )
  bumper_mesh_handle.val = Some(
    @render3d.register_mesh_asset(@render3d.cube_mesh(bumper_size)),
  )
  coin_mesh_handle.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cylinder_mesh(COIN_RADIUS, COIN_RADIUS, COIN_HEIGHT, slices=24),
    ),
  )

  table_material_handle.val = Some(
    material_from_texture(
      TABLE_TOP_PATH,
      color_rgba(255U, 255U, 255U, 1.0),
      roughness=1.0,
      metallic=0.0,
    ),
  )
  rail_material_handle.val = Some(
    material_from_texture(
      TABLE_SIDE_PATH,
      color_rgba(255U, 255U, 255U, 1.0),
      roughness=1.0,
      metallic=0.0,
    ),
  )
  collector_material_handle.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(95U, 170U, 110U, 0.95),
      roughness: 1.0,
      metallic: 0.0,
      alpha_mode: Blend,
    }),
  )
  pusher_material_handle.val = Some(
    material_from_texture(
      PUSHER_PATH,
      color_rgba(255U, 255U, 255U, 1.0),
      roughness=1.0,
      metallic=0.0,
    ),
  )
  bumper_material_handle.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(246U, 159U, 67U, 1.0),
      roughness: 1.0,
      metallic: 0.0,
    }),
  )
  coin_material_handle.val = Some(
    material_from_texture(
      COIN_PATH,
      color_rgba(255U, 255U, 255U, 1.0),
      roughness=1.0,
      metallic=0.0,
      emissive=color_rgba(30U, 20U, 6U, 1.0),
    ),
  )
  cabinet_material_handle.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(33U, 43U, 58U, 1.0),
      roughness: 1.0,
      metallic: 0.0,
    }),
  )
  glass_material_handle.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(148U, 198U, 238U, 0.18),
      roughness: 1.0,
      metallic: 0.0,
      alpha_mode: Blend,
    }),
  )
}

///|
fn spawn_mesh_entity(
  mesh : @render3d.MeshHandle,
  material : @render3d.MaterialHandle,
  translation : @math.Vec3,
  rotation? : @math.Quat = @math.Quat::identity(),
  scale? : @math.Vec3 = @math.Vec3::one(),
  cast_shadows? : Bool = false,
  receive_shadows? : Bool = true,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  @transform.transforms().set(
    entity,
    world_transform(translation, rotation, scale),
  )
  @render3d.mesh3d_renderers().set(entity, {
    mesh,
    material,
    visible: true,
    cast_shadows,
    receive_shadows,
  })
  set_entity_visibility(entity, true)
  entity
}

///|
fn clear_coin_entities() -> Unit {
  for entity, _ in coin_entities {
    entity.destroy()
  }
  coin_entities.clear()
}

///|
fn clear_static_entities() -> Unit {
  for entity in static_entities {
    entity.destroy()
  }
  static_entities.clear()
  collector_entities.clear()
}

///|
fn setup_camera_and_lighting() -> Unit {
  ensure_entity_alive(camera_entity)
  ensure_entity_alive(light_entity)

  @camera3d.cameras3d().set(camera_entity, {
    ..@camera3d.Camera3DComponent::default(),
    fov_y: CAMERA_FOV_Y,
    near: CAMERA_NEAR,
    far: CAMERA_FAR,
    clear_color: color_rgba(18U, 36U, 58U, 1.0),
    order: CAMERA_ORDER,
    enabled: true,
  })
  @transform.transforms().set(
    camera_entity,
    world_transform(
      camera_position,
      look_rotation(camera_position, camera_target),
      @math.Vec3::one(),
    ),
  )

  @render3d.directional_lights3d().set(light_entity, {
    ..@render3d.default_directional_light3d(),
    direction: @math.Vec3::new(-0.24, -1.0, -0.31),
    color: color_rgba(255U, 247U, 230U, 1.0),
    intensity: 0.7,
    shadows: false,
  })
  @render3d.set_ambient_light3d(
    Some({ color: color_rgba(164U, 195U, 232U, 1.0), intensity: 0.35 }),
  )
}

///|
fn setup_hud_entities() -> Unit {
  let panel_size = @math.Vec2(VIEWPORT_WIDTH, 96.0)
  let panel_center = @math.Vec2(VIEWPORT_WIDTH * 0.5, VIEWPORT_HEIGHT - 48.0)
  set_panel_color_entity(
    hud_bg_entity,
    color_rgba(8U, 12U, 22U, 0.82),
    panel_size,
    panel_center,
    UI_ZINDEX,
  )

  set_text_entity(
    hud_main_entity,
    "",
    @math.Vec2(26.0, 22.0),
    "rgb(245,247,251)",
    font="32px \{HUD_FONT_FAMILY}",
    zindex=UI_ZINDEX + 2,
  )
  set_text_entity(
    hud_sub_entity,
    "",
    @math.Vec2(26.0, 62.0),
    "rgb(202,215,230)",
    font="24px \{HUD_FONT_FAMILY}",
    zindex=UI_ZINDEX + 2,
  )
  set_text_entity(
    hud_hint_entity,
    "",
    @math.Vec2(26.0, VIEWPORT_HEIGHT - 40.0),
    "rgb(215,224,236)",
    font="22px \{HUD_FONT_FAMILY}",
    zindex=UI_ZINDEX + 2,
  )

  set_text_entity(
    chest_title_entity,
    "",
    @math.Vec2(310.0, 160.0),
    "rgb(255,244,204)",
    font="42px \{HUD_FONT_FAMILY}",
    zindex=UI_ZINDEX + 6,
  )

  chest_option_rects.clear()
  let panel_w = 320.0
  let panel_h = 180.0
  let center_y = 380.0
  for i in 0..<3 {
    let x = VIEWPORT_WIDTH * 0.5 + (i - 1).to_double() * 360.0
    let y = center_y
    chest_option_rects.push(
      (x - panel_w * 0.5, y - panel_h * 0.5, panel_w, panel_h),
    )
    set_panel_color_entity(
      chest_option_panel_entities[i],
      color_rgba(20U, 36U, 58U, 0.9),
      @math.Vec2(panel_w, panel_h),
      @math.Vec2(x, y),
      UI_ZINDEX + 5,
    )
    set_text_entity(
      chest_option_text_entities[i],
      "",
      @math.Vec2(x - panel_w * 0.5 + 20.0, y - panel_h * 0.5 + 24.0),
      "rgb(243,245,248)",
      font="24px \{HUD_FONT_FAMILY}",
      zindex=UI_ZINDEX + 7,
    )
  }

  set_text_entity(
    summary_title_entity,
    "",
    @math.Vec2(320.0, 180.0),
    "rgb(251,236,191)",
    font="56px \{HUD_FONT_FAMILY}",
    zindex=UI_ZINDEX + 8,
  )
  set_text_entity(
    summary_body_entity,
    "",
    @math.Vec2(320.0, 260.0),
    "rgb(227,236,246)",
    font="32px \{HUD_FONT_FAMILY}",
    zindex=UI_ZINDEX + 8,
  )

  set_entity_visibility(chest_title_entity, false)
  for entity in chest_option_panel_entities {
    set_entity_visibility(entity, false)
  }
  for entity in chest_option_text_entities {
    set_entity_visibility(entity, false)
  }
  set_entity_visibility(summary_title_entity, false)
  set_entity_visibility(summary_body_entity, false)
}

///|
fn spawn_board_scene() -> Unit {
  clear_static_entities()

  let board_rotation = @math.Quat::from_axis_angle(
    @math.Vec3::x_axis(),
    BOARD_TILT_RADIANS,
  )

  ensure_entity_alive(table_entity)
  @transform.transforms().set(
    table_entity,
    world_transform(
      @math.Vec3::new(0.0, BOARD_CENTER_Y, 0.0),
      board_rotation,
      @math.Vec3::one(),
    ),
  )
  @render3d.mesh3d_renderers().set(table_entity, {
    mesh: table_mesh_handle.val.unwrap(),
    material: table_material_handle.val.unwrap(),
    visible: true,
    cast_shadows: true,
    receive_shadows: true,
  })
  assign_static_body(
    table_entity,
    @math.Vec3::new(BOARD_WIDTH, BOARD_THICKNESS, BOARD_LENGTH),
    0.9,
    0.08,
  )
  static_entities.push(table_entity)

  let cabinet_body = spawn_mesh_entity(
    table_mesh_handle.val.unwrap(),
    cabinet_material_handle.val.unwrap(),
    @math.Vec3::new(0.0, BOARD_CENTER_Y - 1.25, 0.0),
    scale=@math.Vec3::new(1.22, 4.2, 1.14),
    cast_shadows=true,
    receive_shadows=true,
  )
  static_entities.push(cabinet_body)

  let canopy = spawn_mesh_entity(
    table_mesh_handle.val.unwrap(),
    cabinet_material_handle.val.unwrap(),
    @math.Vec3::new(
      0.0,
      board_surface_y(-board_half_length() + 0.2) + 2.3,
      -6.9,
    ),
    scale=@math.Vec3::new(1.08, 0.55, 0.3),
    cast_shadows=true,
    receive_shadows=true,
  )
  static_entities.push(canopy)

  let rail_depth = BOARD_LENGTH - RAIL_DEPTH_PADDING
  let rail_y = board_surface_y(0.0) + RAIL_HEIGHT * 0.5
  let left_rail = spawn_mesh_entity(
    table_mesh_handle.val.unwrap(),
    rail_material_handle.val.unwrap(),
    @math.Vec3::new(-board_half_width() - RAIL_WIDTH * 0.45, rail_y, 0.0),
    rotation=board_rotation,
    scale=@math.Vec3::new(
      RAIL_WIDTH / BOARD_WIDTH,
      RAIL_HEIGHT / BOARD_THICKNESS,
      rail_depth / BOARD_LENGTH,
    ),
  )
  assign_static_body(
    left_rail,
    @math.Vec3::new(RAIL_WIDTH, RAIL_HEIGHT, rail_depth),
    0.8,
    0.08,
  )
  static_entities.push(left_rail)

  let right_rail = spawn_mesh_entity(
    table_mesh_handle.val.unwrap(),
    rail_material_handle.val.unwrap(),
    @math.Vec3::new(board_half_width() + RAIL_WIDTH * 0.45, rail_y, 0.0),
    rotation=board_rotation,
    scale=@math.Vec3::new(
      RAIL_WIDTH / BOARD_WIDTH,
      RAIL_HEIGHT / BOARD_THICKNESS,
      rail_depth / BOARD_LENGTH,
    ),
  )
  assign_static_body(
    right_rail,
    @math.Vec3::new(RAIL_WIDTH, RAIL_HEIGHT, rail_depth),
    0.8,
    0.08,
  )
  static_entities.push(right_rail)

  let glass_height = 1.45
  let glass_y = rail_y + glass_height * 0.5 + 0.22
  let left_glass = spawn_mesh_entity(
    table_mesh_handle.val.unwrap(),
    glass_material_handle.val.unwrap(),
    @math.Vec3::new(-board_half_width() - RAIL_WIDTH * 0.1, glass_y, 0.3),
    rotation=board_rotation,
    scale=@math.Vec3::new(
      0.028,
      glass_height / BOARD_THICKNESS,
      rail_depth / BOARD_LENGTH,
    ),
    cast_shadows=false,
    receive_shadows=true,
  )
  static_entities.push(left_glass)

  let right_glass = spawn_mesh_entity(
    table_mesh_handle.val.unwrap(),
    glass_material_handle.val.unwrap(),
    @math.Vec3::new(board_half_width() + RAIL_WIDTH * 0.1, glass_y, 0.3),
    rotation=board_rotation,
    scale=@math.Vec3::new(
      0.028,
      glass_height / BOARD_THICKNESS,
      rail_depth / BOARD_LENGTH,
    ),
    cast_shadows=false,
    receive_shadows=true,
  )
  static_entities.push(right_glass)

  let back_stop = spawn_mesh_entity(
    table_mesh_handle.val.unwrap(),
    rail_material_handle.val.unwrap(),
    @math.Vec3::new(
      0.0,
      board_surface_y(-board_half_length() + BACK_STOP_THICKNESS) +
      RAIL_HEIGHT * 0.5,
      -board_half_length() + BACK_STOP_THICKNESS,
    ),
    rotation=board_rotation,
    scale=@math.Vec3::new(
      1.0,
      RAIL_HEIGHT / BOARD_THICKNESS,
      BACK_STOP_THICKNESS / BOARD_LENGTH,
    ),
  )
  assign_static_body(
    back_stop,
    @math.Vec3::new(BOARD_WIDTH, RAIL_HEIGHT, BACK_STOP_THICKNESS),
    0.85,
    0.08,
  )
  static_entities.push(back_stop)

  let front_trim = spawn_mesh_entity(
    table_mesh_handle.val.unwrap(),
    cabinet_material_handle.val.unwrap(),
    @math.Vec3::new(
      0.0,
      board_surface_y(COLLECTOR_Z + 0.65) + 0.38,
      COLLECTOR_Z + 0.72,
    ),
    rotation=board_rotation,
    scale=@math.Vec3::new(1.06, 0.36, 0.12),
    cast_shadows=true,
    receive_shadows=true,
  )
  static_entities.push(front_trim)

  let tray_visual = spawn_mesh_entity(
    table_mesh_handle.val.unwrap(),
    cabinet_material_handle.val.unwrap(),
    @math.Vec3::new(
      0.0,
      board_surface_y(COLLECTOR_Z + 1.1) - 0.78,
      COLLECTOR_Z + 1.42,
    ),
    rotation=board_rotation,
    scale=@math.Vec3::new(1.06, 0.22, 0.52),
    cast_shadows=true,
    receive_shadows=true,
  )
  static_entities.push(tray_visual)

  for i in 0..<2 {
    let x = lane_min_x() + lane_width() * (i + 1).to_double()
    let front_separator = spawn_mesh_entity(
      table_mesh_handle.val.unwrap(),
      rail_material_handle.val.unwrap(),
      @math.Vec3::new(
        x,
        board_surface_y(COLLECTOR_Z + 0.72) - 0.16,
        COLLECTOR_Z + 1.02,
      ),
      rotation=board_rotation,
      scale=@math.Vec3::new(0.028, 0.56, 0.2),
      cast_shadows=true,
      receive_shadows=true,
    )
    static_entities.push(front_separator)
  }

  let separator_size = @math.Vec3::new(0.32, 0.95, 1.4)
  for i in 0..<2 {
    let x = lane_min_x() + lane_width() * (i + 1).to_double()
    let separator = spawn_mesh_entity(
      bumper_mesh_handle.val.unwrap(),
      rail_material_handle.val.unwrap(),
      @math.Vec3::new(
        x,
        board_surface_y(COLLECTOR_Z) + separator_size.y * 0.5,
        COLLECTOR_Z,
      ),
      rotation=board_rotation,
      scale=@math.Vec3::new(
        separator_size.x / bumper_size.x,
        separator_size.y / bumper_size.y,
        separator_size.z / bumper_size.z,
      ),
    )
    assign_static_body(separator, separator_size, 0.8, 0.06)
    static_entities.push(separator)
  }

  collector_entities.clear()
  for i in 0..<3 {
    let center_x = lane_center(i)
    let lane_entity = spawn_mesh_entity(
      bumper_mesh_handle.val.unwrap(),
      collector_material_handle.val.unwrap(),
      @math.Vec3::new(
        center_x,
        board_surface_y(COLLECTOR_Z) - 0.12,
        COLLECTOR_Z + 0.25,
      ),
      rotation=board_rotation,
      scale=@math.Vec3::new(
        lane_width() * 0.85 / bumper_size.x,
        0.18 / bumper_size.y,
        0.8 / bumper_size.z,
      ),
      cast_shadows=false,
      receive_shadows=true,
    )
    collector_entities.push(lane_entity)
  }

  let bumper_y = board_surface_y(BUMPER_Z) + bumper_size.y * 0.5
  for side in [-1.0, 1.0] {
    let x = BUMPER_X_OFFSET * side
    let bumper_entity = spawn_mesh_entity(
      bumper_mesh_handle.val.unwrap(),
      bumper_material_handle.val.unwrap(),
      @math.Vec3::new(x, bumper_y, BUMPER_Z),
      rotation=board_rotation,
      scale=@math.Vec3::one(),
    )
    assign_static_body(bumper_entity, bumper_size, 0.82, 0.3)
    static_entities.push(bumper_entity)
  }

  ensure_entity_alive(pusher_entity)
  let pusher_start_z = PUSHER_CENTER_Z
  let pusher_y = board_surface_y(pusher_start_z) + PUSHER_HEIGHT * 0.5
  @transform.transforms().set(
    pusher_entity,
    world_transform(
      @math.Vec3::new(0.0, pusher_y, pusher_start_z),
      board_rotation,
      @math.Vec3::one(),
    ),
  )
  @render3d.mesh3d_renderers().set(pusher_entity, {
    mesh: pusher_mesh_handle.val.unwrap(),
    material: pusher_material_handle.val.unwrap(),
    visible: true,
    cast_shadows: true,
    receive_shadows: true,
  })
  @physics3d.rigid_bodies().set(
    pusher_entity,
    @physics3d.KinematicPositionBased,
  )
  @physics3d.colliders().set(
    pusher_entity,
    @physics3d.Collider::cuboid(
      @math.Vec3::new(
        PUSHER_WIDTH * 0.5,
        PUSHER_HEIGHT * 0.5,
        PUSHER_DEPTH * 0.5,
      ),
    ),
  )
  @physics3d.frictions().set(pusher_entity, @physics3d.Friction::new(0.9))
  @physics3d.restitutions().set(
    pusher_entity,
    @physics3d.Restitution::new(0.08),
  )
  static_entities.push(pusher_entity)
}

///|
fn reset_runtime_scene() -> Unit {
  clear_coin_entities()
  spawn_board_scene()
  let seed = rand.int()
  reset_run_state(seed)
  seed_board_coin_field()
  @physics3d.set_gravity(@math.Vec3::new(0.0, -14.0, 4.0))
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  register_render_assets_once()
  setup_camera_and_lighting()
  setup_hud_entities()
  ensure_music_started()
  reset_runtime_scene()
}

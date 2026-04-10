///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
const PACMAN_UPSTREAM_FONT_FAMILY : String = "ThaleahFat"

///|
const PACMAN_UPSTREAM_FONT_PATH : String = "assets/shared/fonts/ThaleahFat.ttf"

///|
const CEILING_TILE_TEXTURE_PATH : String = "assets/pacman3d/ceiling_tile.png"

///|
const CEILING_TILE_ALBEDO_TEXTURE_PATH : String = "assets/pacman3d/ceiling_tile_albedo.png"

///|
const WALL_TILE_TEXTURE_PATH : String = "assets/pacman3d/wall_tile.png"

///|
const WALL_TILE_ALBEDO_TEXTURE_PATH : String = "assets/pacman3d/wall_tile_albedo.png"

///|
const FLOOR_TILE_TEXTURE_PATH : String = "assets/pacman3d/floor_tile.png"

///|
const FLOOR_TILE_ALBEDO_TEXTURE_PATH : String = "assets/pacman3d/floor_tile_albedo.png"

///|
let pacman_upstream_font_registered : Ref[Bool] = { val: false }

///|
fn register_pacman_upstream_font_once() -> Unit {
  if pacman_upstream_font_registered.val {
    return
  }
  ignore(
    @asset.load_font(
      PACMAN_UPSTREAM_FONT_PATH,
      family=PACMAN_UPSTREAM_FONT_FAMILY,
    ),
  )
  pacman_upstream_font_registered.val = true
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn transform_2d(position : @math.Vec2D, zindex : Int) -> @transform.Transform {
  {
    translation: @math.Vec3::new(position[X], position[Y], zindex.to_double()),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  }
}

///|
fn set_entity_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn setup_text_entity(
  entity : @entity.Entity,
  content : String,
  position : @math.Vec2D,
  color : String,
) -> Unit {
  ensure_entity_alive(entity)
  @ui.texts().set(entity, @ui.Text::new(content))
  @ui.text_fonts().set(
    entity,
    @ui.TextFont::from_css("18px \{PACMAN_UPSTREAM_FONT_FAMILY}"),
  )
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2D(-0.5, 0.5)))
  @transform.transforms().set(entity, transform_2d(position, 200))
  set_entity_visibility(entity, true)
}

///|
fn setup_color_rect_entity(
  entity : @entity.Entity,
  size : @math.Vec2D,
  position : @math.Vec2D,
  color : String,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_color(@sprite.color_from_css(color), size)
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_2d(position, zindex))
  set_entity_visibility(entity, true)
}

///|
fn spawn_color_rect_entity(
  size : @math.Vec2D,
  position : @math.Vec2D,
  color : String,
  zindex : Int,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  setup_color_rect_entity(entity, size, position, color, zindex)
  entity
}

///|
fn register_render_assets_once() -> Unit {
  if wall_mesh.val is Some(_) {
    return
  }
  wall_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(
        @math.Vec3::new(TILE_WORLD_SIZE, WALL_HEIGHT, TILE_WORLD_SIZE),
      ),
    ),
  )
  floor_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(
        @math.Vec3::new(TILE_WORLD_SIZE, FLOOR_THICKNESS, TILE_WORLD_SIZE),
      ),
    ),
  )
  dot_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(
        @math.Vec3::new(DOT_RADIUS * 1.8, DOT_RADIUS * 1.8, DOT_RADIUS * 1.8),
      ),
    ),
  )
  ghost_body_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cylinder_mesh(
        GHOST_BODY_RADIUS,
        GHOST_BODY_RADIUS,
        GHOST_BODY_HEIGHT,
      ),
    ),
  )
  ghost_eye_mesh.val = Some(
    @render3d.register_mesh_asset(@render3d.sphere_mesh(GHOST_EYE_RADIUS)),
  )
  ghost_spot_ray_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(
        @math.Vec3::new(
          GHOST_SPOT_DEBUG_RAY_THICKNESS,
          GHOST_SPOT_DEBUG_RAY_THICKNESS,
          GHOST_SPOT_DEBUG_RAY_LENGTH,
        ),
      ),
    ),
  )

  let ceiling_texture_path = resolve_pacman_asset_path(
    CEILING_TILE_TEXTURE_PATH,
  )
  let ceiling_texture_albedo_path = resolve_pacman_asset_path(
    CEILING_TILE_ALBEDO_TEXTURE_PATH,
  )
  let wall_texture_path = resolve_pacman_asset_path(WALL_TILE_TEXTURE_PATH)
  let wall_texture_albedo_path = resolve_pacman_asset_path(
    WALL_TILE_ALBEDO_TEXTURE_PATH,
  )
  let floor_texture_path = resolve_pacman_asset_path(FLOOR_TILE_TEXTURE_PATH)
  let floor_texture_albedo_path = resolve_pacman_asset_path(
    FLOOR_TILE_ALBEDO_TEXTURE_PATH,
  )

  let ceiling_texture = @render3d.register_image_asset({
    path: ceiling_texture_path,
  })
  let ceiling_texture_albedo = @render3d.register_image_asset({
    path: ceiling_texture_albedo_path,
  })
  let wall_texture = @render3d.register_image_asset({ path: wall_texture_path })
  let wall_texture_albedo = @render3d.register_image_asset({
    path: wall_texture_albedo_path,
  })
  let floor_texture = @render3d.register_image_asset({
    path: floor_texture_path,
  })
  let floor_texture_albedo = @render3d.register_image_asset({
    path: floor_texture_albedo_path,
  })

  let wall_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    base_color_texture: Some(@render3d.texture_binding3d(wall_texture)),
    roughness: 1.0,
    metallic: 0.0,
  }
  wall_material.val = Some(
    @render3d.register_material_asset(wall_material_asset),
  )
  let wall_material_neutral_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  wall_material_neutral.val = Some(
    @render3d.register_material_asset(wall_material_neutral_asset),
  )
  let wall_material_textured_flat_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    base_color_texture: Some(@render3d.texture_binding3d(wall_texture_albedo)),
    roughness: 1.0,
    metallic: 0.0,
    unlit: true,
  }
  wall_material_textured_flat.val = Some(
    @render3d.register_material_asset(wall_material_textured_flat_asset),
  )
  let wall_material_brdf_only_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  wall_material_brdf_only.val = Some(
    @render3d.register_material_asset(wall_material_brdf_only_asset),
  )

  let floor_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    base_color_texture: Some(@render3d.texture_binding3d(floor_texture)),
    roughness: 1.0,
  }
  floor_material.val = Some(
    @render3d.register_material_asset(floor_material_asset),
  )
  let floor_material_neutral_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  floor_material_neutral.val = Some(
    @render3d.register_material_asset(floor_material_neutral_asset),
  )
  let floor_material_textured_flat_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    base_color_texture: Some(@render3d.texture_binding3d(floor_texture_albedo)),
    roughness: 1.0,
    metallic: 0.0,
    unlit: true,
  }
  floor_material_textured_flat.val = Some(
    @render3d.register_material_asset(floor_material_textured_flat_asset),
  )
  let floor_material_brdf_only_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  floor_material_brdf_only.val = Some(
    @render3d.register_material_asset(floor_material_brdf_only_asset),
  )

  let ceiling_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    base_color_texture: Some(@render3d.texture_binding3d(ceiling_texture)),
    roughness: 1.0,
  }
  ceiling_material.val = Some(
    @render3d.register_material_asset(ceiling_material_asset),
  )
  let ceiling_material_neutral_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  ceiling_material_neutral.val = Some(
    @render3d.register_material_asset(ceiling_material_neutral_asset),
  )
  let ceiling_material_textured_flat_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    base_color_texture: Some(
      @render3d.texture_binding3d(ceiling_texture_albedo),
    ),
    roughness: 1.0,
    metallic: 0.0,
    unlit: true,
  }
  ceiling_material_textured_flat.val = Some(
    @render3d.register_material_asset(ceiling_material_textured_flat_asset),
  )
  let ceiling_material_brdf_only_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  ceiling_material_brdf_only.val = Some(
    @render3d.register_material_asset(ceiling_material_brdf_only_asset),
  )

  let dot_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(245U, 227U, 92U, 1.0),
    emissive_color: color_rgba(168U, 146U, 56U, 1.0),
    roughness: 1.0,
  }
  dot_material.val = Some(@render3d.register_material_asset(dot_material_asset))
  let dot_material_neutral_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  dot_material_neutral.val = Some(
    @render3d.register_material_asset(dot_material_neutral_asset),
  )
  let dot_material_no_emissive_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(245U, 227U, 92U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  dot_material_no_emissive.val = Some(
    @render3d.register_material_asset(dot_material_no_emissive_asset),
  )

  let fast_ghost_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(220U, 42U, 42U, 1.0),
    emissive_color: color_rgba(84U, 16U, 16U, 1.0),
    roughness: 1.0,
  }
  ghost_material_fast.val = Some(
    @render3d.register_material_asset(fast_ghost_material_asset),
  )
  let fast_ghost_material_neutral_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  ghost_material_fast_neutral.val = Some(
    @render3d.register_material_asset(fast_ghost_material_neutral_asset),
  )
  let fast_ghost_material_no_emissive_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(220U, 42U, 42U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  ghost_material_fast_no_emissive.val = Some(
    @render3d.register_material_asset(fast_ghost_material_no_emissive_asset),
  )

  let normal_ghost_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(246U, 146U, 46U, 1.0),
    emissive_color: color_rgba(96U, 48U, 16U, 1.0),
    roughness: 1.0,
  }
  ghost_material_normal.val = Some(
    @render3d.register_material_asset(normal_ghost_material_asset),
  )
  let normal_ghost_material_neutral_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  ghost_material_normal_neutral.val = Some(
    @render3d.register_material_asset(normal_ghost_material_neutral_asset),
  )
  let normal_ghost_material_no_emissive_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(246U, 146U, 46U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  ghost_material_normal_no_emissive.val = Some(
    @render3d.register_material_asset(normal_ghost_material_no_emissive_asset),
  )

  let slow_ghost_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(42U, 108U, 214U, 1.0),
    emissive_color: color_rgba(18U, 40U, 84U, 1.0),
    roughness: 1.0,
  }
  ghost_material_slow.val = Some(
    @render3d.register_material_asset(slow_ghost_material_asset),
  )
  let slow_ghost_material_neutral_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  ghost_material_slow_neutral.val = Some(
    @render3d.register_material_asset(slow_ghost_material_neutral_asset),
  )
  let slow_ghost_material_no_emissive_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(42U, 108U, 214U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  ghost_material_slow_no_emissive.val = Some(
    @render3d.register_material_asset(slow_ghost_material_no_emissive_asset),
  )

  let ghost_eye_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    emissive_color: color_rgba(40U, 40U, 40U, 1.0),
    roughness: 1.0,
  }
  ghost_eye_material.val = Some(
    @render3d.register_material_asset(ghost_eye_material_asset),
  )
  let ghost_eye_material_neutral_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  ghost_eye_material_neutral.val = Some(
    @render3d.register_material_asset(ghost_eye_material_neutral_asset),
  )
  let ghost_eye_material_no_emissive_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(255U, 255U, 255U, 1.0),
    roughness: 1.0,
    metallic: 0.0,
  }
  ghost_eye_material_no_emissive.val = Some(
    @render3d.register_material_asset(ghost_eye_material_no_emissive_asset),
  )

  let fast_ghost_spot_ray_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(220U, 42U, 42U, 1.0),
    unlit: true,
  }
  ghost_spot_ray_material_fast.val = Some(
    @render3d.register_material_asset(fast_ghost_spot_ray_material_asset),
  )

  let normal_ghost_spot_ray_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(246U, 146U, 46U, 1.0),
    unlit: true,
  }
  ghost_spot_ray_material_normal.val = Some(
    @render3d.register_material_asset(normal_ghost_spot_ray_material_asset),
  )

  let slow_ghost_spot_ray_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(42U, 108U, 214U, 1.0),
    unlit: true,
  }
  ghost_spot_ray_material_slow.val = Some(
    @render3d.register_material_asset(slow_ghost_spot_ray_material_asset),
  )
}

///|
fn spawn_mesh_entity(
  mesh : @render3d.MeshHandle,
  material : @render3d.MaterialHandle,
  translation : @math.Vec3,
  cast_shadows? : Bool = false,
  receive_shadows? : Bool = true,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  @render3d.mesh3d_renderers().set(entity, {
    mesh,
    material,
    visible: true,
    cast_shadows,
    receive_shadows,
  })
  @transform.transforms().set(entity, {
    translation,
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  entity
}

///|
fn ghost_material_for_type(ghost_type : GhostType) -> @render3d.MaterialHandle {
  match lighting_debug.material_mode {
    Neutral | WorldTextureFlat | WorldBrdfOnly | WorldActorsNeutral =>
      match ghost_type {
        Fast => ghost_material_fast_neutral.val.unwrap()
        Normal => ghost_material_normal_neutral.val.unwrap()
        Slow => ghost_material_slow_neutral.val.unwrap()
      }
    WorldActorsColor =>
      match ghost_type {
        Fast => ghost_material_fast_no_emissive.val.unwrap()
        Normal => ghost_material_normal_no_emissive.val.unwrap()
        Slow => ghost_material_slow_no_emissive.val.unwrap()
      }
    Scene =>
      match ghost_type {
        Fast => ghost_material_fast.val.unwrap()
        Normal => ghost_material_normal.val.unwrap()
        Slow => ghost_material_slow.val.unwrap()
      }
  }
}

///|
fn active_wall_material() -> @render3d.MaterialHandle {
  match lighting_debug.material_mode {
    Neutral => wall_material_neutral.val.unwrap()
    WorldTextureFlat => wall_material_textured_flat.val.unwrap()
    WorldBrdfOnly => wall_material_brdf_only.val.unwrap()
    _ => wall_material.val.unwrap()
  }
}

///|
fn active_floor_material() -> @render3d.MaterialHandle {
  match lighting_debug.material_mode {
    Neutral => floor_material_neutral.val.unwrap()
    WorldTextureFlat => floor_material_textured_flat.val.unwrap()
    WorldBrdfOnly => floor_material_brdf_only.val.unwrap()
    _ => floor_material.val.unwrap()
  }
}

///|
fn active_ceiling_material() -> @render3d.MaterialHandle {
  match lighting_debug.material_mode {
    Neutral => ceiling_material_neutral.val.unwrap()
    WorldTextureFlat => ceiling_material_textured_flat.val.unwrap()
    WorldBrdfOnly => ceiling_material_brdf_only.val.unwrap()
    _ => ceiling_material.val.unwrap()
  }
}

///|
fn active_dot_material() -> @render3d.MaterialHandle {
  match lighting_debug.material_mode {
    Neutral | WorldTextureFlat | WorldBrdfOnly | WorldActorsNeutral =>
      dot_material_neutral.val.unwrap()
    WorldActorsColor => dot_material_no_emissive.val.unwrap()
    Scene => dot_material.val.unwrap()
  }
}

///|
fn active_ghost_eye_material() -> @render3d.MaterialHandle {
  match lighting_debug.material_mode {
    Neutral | WorldTextureFlat | WorldBrdfOnly | WorldActorsNeutral =>
      ghost_eye_material_neutral.val.unwrap()
    WorldActorsColor => ghost_eye_material_no_emissive.val.unwrap()
    Scene => ghost_eye_material.val.unwrap()
  }
}

///|
fn ghost_light_color_for_type(ghost_type : GhostType) -> @render.Color {
  match ghost_type {
    Fast => color_rgba(220U, 42U, 42U, 1.0)
    Normal => color_rgba(246U, 146U, 46U, 1.0)
    Slow => color_rgba(42U, 108U, 214U, 1.0)
  }
}

///|
fn ghost_spot_ray_material_for_type(
  ghost_type : GhostType,
) -> @render3d.MaterialHandle {
  match ghost_type {
    Fast => ghost_spot_ray_material_fast.val.unwrap()
    Normal => ghost_spot_ray_material_normal.val.unwrap()
    Slow => ghost_spot_ray_material_slow.val.unwrap()
  }
}

///|
fn ghost_rotation(direction : Direction) -> @math.Quat {
  let yaw = match direction {
    Up => 0.0
    Down => @cmath.PI
    Left => @cmath.PI / 2.0
    Right => -@cmath.PI / 2.0
  }
  @math.Quat::from_axis_angle(@math.Vec3::new(0.0, 1.0, 0.0), yaw)
}

///|
fn ghost_forward_vector_from_rotation(
  rotation : @math.Quat,
) -> (Double, Double) {
  let forward = rotation.rotate_vec3(@math.Vec3::new(0.0, 0.0, -1.0))
  (forward.x, forward.z)
}

///|
fn ghost_local_spot_direction() -> @math.Vec3 {
  @math.Vec3::new(0.0, -GHOST_SPOT_LIGHT_DOWNWARD, -1.0).normalize()
}

///|
fn ghost_spot_forward_offset() -> Double {
  if lighting_debug.center_ghost_spot_origin {
    0.0
  } else {
    GHOST_SPOT_LIGHT_FORWARD_OFFSET
  }
}

///|
fn quat_from_forward_direction(direction : @math.Vec3) -> @math.Quat {
  let source = @math.Vec3::new(0.0, 0.0, -1.0)
  let target = direction.normalize()
  if target.length_squared() <= 0.000000001 {
    return @math.Quat::identity()
  }
  let dot = source.dot(target)
  let clamped_dot = if dot > 1.0 {
    1.0
  } else if dot < -1.0 {
    -1.0
  } else {
    dot
  }
  if clamped_dot >= 0.999999 {
    return @math.Quat::identity()
  }
  if clamped_dot <= -0.999999 {
    return @math.Quat::from_axis_angle(
      @math.Vec3::new(0.0, 1.0, 0.0),
      @cmath.PI,
    )
  }
  let axis = source.cross(target).normalize()
  let angle = @cmath.acos(clamped_dot)
  @math.Quat::from_axis_angle(axis, angle)
}

///|
fn ghost_bob_phase_for_spawn(
  x : Double,
  z : Double,
  ghost_type : GhostType,
) -> Double {
  let type_offset = match ghost_type {
    Fast => 0.0
    Normal => @cmath.PI / 3.0
    Slow => @cmath.PI * 2.0 / 3.0
  }
  x * 0.37 + z * 0.61 + type_offset
}

///|
fn sandbox_ghost_direction_for_spawn(spawn_index : Int) -> Direction {
  if spawn_index % 2 == 0 {
    Up
  } else {
    Down
  }
}

///|
fn sync_ghost_visuals(ghost : Ghost) -> Unit {
  let bob_offset = if lighting_debug.bobbing_enabled {
    @cmath.sin(
      @time.elapsed() *
      ghost_speed(ghost.ghost_type) *
      GHOST_BOB_FREQUENCY_PER_SPEED +
      ghost.bob_phase,
    ) *
    GHOST_BOB_AMPLITUDE
  } else {
    0.0
  }
  let ghost_y = MAP_GHOST_Y + bob_offset
  let rotation = ghost_rotation(ghost.direction)
  let (forward_x, forward_z) = ghost_forward_vector_from_rotation(rotation)
  @transform.transforms().set(ghost.entity, {
    translation: @math.Vec3::new(ghost.x, ghost_y, ghost.z),
    rotation,
    scale: @math.Vec3::one(),
  })

  let side_x = -forward_z
  let side_z = forward_x
  let eye_base = @math.Vec3::new(
    ghost.x + forward_x * GHOST_EYE_FORWARD_OFFSET,
    ghost_y + GHOST_EYE_HEIGHT_OFFSET,
    ghost.z + forward_z * GHOST_EYE_FORWARD_OFFSET,
  )
  let local_spot_direction = ghost_local_spot_direction()
  let spot_forward_offset = ghost_spot_forward_offset()
  let light_translation = @math.Vec3::new(
    ghost.x + forward_x * spot_forward_offset,
    ghost_y + GHOST_SPOT_LIGHT_HEIGHT_OFFSET,
    ghost.z + forward_z * spot_forward_offset,
  )
  let world_spot_direction = rotation
    .rotate_vec3(local_spot_direction)
    .normalize()
  @transform.transforms().set(ghost.light_entity, {
    translation: light_translation,
    rotation,
    scale: @math.Vec3::one(),
  })
  if debug_mode_allows_ghost_point_light() {
    @render3d.point_lights3d().set(ghost.light_entity, {
      ..@render3d.default_point_light3d(),
      color: ghost_light_color_for_type(ghost.ghost_type),
      intensity: GHOST_POINT_LIGHT_INTENSITY,
      range: GHOST_POINT_LIGHT_RANGE,
    })
  } else {
    @render3d.point_lights3d().remove(ghost.light_entity)
  }
  if debug_mode_allows_ghost_spot_light() {
    @render3d.spot_lights3d().set(ghost.light_entity, {
      ..@render3d.default_spot_light3d(),
      direction: local_spot_direction,
      color: ghost_light_color_for_type(ghost.ghost_type),
      intensity: GHOST_SPOT_LIGHT_INTENSITY,
      range: GHOST_SPOT_LIGHT_RANGE,
      inner_angle: GHOST_SPOT_LIGHT_INNER_ANGLE,
      outer_angle: GHOST_SPOT_LIGHT_OUTER_ANGLE,
    })
  } else {
    @render3d.spot_lights3d().remove(ghost.light_entity)
  }
  @render3d.mesh3d_renderers().set(ghost.spot_ray_entity, {
    mesh: ghost_spot_ray_mesh.val.unwrap(),
    material: ghost_spot_ray_material_for_type(ghost.ghost_type),
    visible: lighting_debug.show_ghost_spot_rays,
    cast_shadows: false,
    receive_shadows: false,
  })
  @transform.transforms().set(ghost.spot_ray_entity, {
    translation: light_translation +
    world_spot_direction.scalar_mul(GHOST_SPOT_DEBUG_RAY_LENGTH * 0.5),
    rotation: quat_from_forward_direction(world_spot_direction),
    scale: @math.Vec3::one(),
  })
  @transform.transforms().set(ghost.left_eye_entity, {
    translation: @math.Vec3::new(
      eye_base.x + side_x * GHOST_EYE_SIDE_OFFSET,
      eye_base.y,
      eye_base.z + side_z * GHOST_EYE_SIDE_OFFSET,
    ),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  @transform.transforms().set(ghost.right_eye_entity, {
    translation: @math.Vec3::new(
      eye_base.x - side_x * GHOST_EYE_SIDE_OFFSET,
      eye_base.y,
      eye_base.z - side_z * GHOST_EYE_SIDE_OFFSET,
    ),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
}

///|
fn random_direction() -> Direction {
  let n0 = rand.int() % 4
  let n = if n0 < 0 { n0 + 4 } else { n0 }
  match n {
    0 => Up
    1 => Down
    2 => Left
    _ => Right
  }
}

///|
fn clear_level_entities() -> Unit {
  for entity in floor_entities {
    entity.destroy()
  }
  floor_entities.clear()

  for entity in ceiling_entities {
    entity.destroy()
  }
  ceiling_entities.clear()

  for entity in wall_entities {
    entity.destroy()
  }
  wall_entities.clear()

  for entity in minimap_tile_entities {
    entity.destroy()
  }
  minimap_tile_entities.clear()

  for dot in dots {
    @render3d.point_lights3d().remove(dot.entity)
    dot.entity.destroy()
    dot.minimap_entity.destroy()
  }
  dots.clear()

  for ghost in ghosts {
    @render3d.point_lights3d().remove(ghost.light_entity)
    @render3d.spot_lights3d().remove(ghost.light_entity)
    ghost.entity.destroy()
    ghost.light_entity.destroy()
    ghost.spot_ray_entity.destroy()
    ghost.left_eye_entity.destroy()
    ghost.right_eye_entity.destroy()
    ghost.minimap_entity.destroy()
  }
  ghosts.clear()
}

///|
fn sync_camera_transform() -> Unit {
  ensure_entity_alive(camera_entity)
  ensure_entity_alive(player_light_entity)
  let yaw = -(player_state.yaw + @cmath.PI / 2.0)
  @transform.transforms().set(camera_entity, {
    translation: @math.Vec3::new(player_state.x, PLAYER_HEIGHT, player_state.z),
    rotation: @math.Quat::from_axis_angle(@math.Vec3::new(0.0, 1.0, 0.0), yaw),
    scale: @math.Vec3::one(),
  })
  let forward_x = @cmath.cos(player_state.yaw)
  let forward_z = @cmath.sin(player_state.yaw)
  @transform.transforms().set(player_light_entity, {
    translation: @math.Vec3::new(
      player_state.x + forward_x * 0.45,
      PLAYER_HEIGHT + 0.2,
      player_state.z + forward_z * 0.45,
    ),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  @render3d.point_lights3d().set(player_light_entity, {
    ..@render3d.default_point_light3d(),
    color: color_rgba(255U, 240U, 214U, 1.0),
    intensity: if debug_mode_allows_player_light() {
      PLAYER_LIGHT_INTENSITY
    } else {
      0.0
    },
    range: PLAYER_LIGHT_RANGE,
  })
}

///|
fn reset_level_entities() -> Unit {
  register_render_assets_once()
  clear_level_entities()

  let map = get_map()
  let mut found_spawn = false
  for tile_y in 0..<map_height(map) {
    for tile_x in 0..<map_width(map) {
      let tile = map[tile_y][tile_x]
      let world_x = world_x_for_tile(tile_x)
      let world_z = world_z_for_tile(tile_y)
      let minimap_tile_position = minimap_pos_for_tile(tile_x, tile_y)

      let tile_color = if tile == 1 {
        "rgb(139,69,19)"
      } else {
        "rgb(51,51,51)"
      }
      let minimap_tile_entity = spawn_color_rect_entity(
        @math.Vec2D(MINIMAP_CELL_SIZE, MINIMAP_CELL_SIZE),
        minimap_tile_position,
        tile_color,
        160,
      )
      minimap_tile_entities.push(minimap_tile_entity)

      if tile != 1 {
        let floor_entity = spawn_mesh_entity(
          floor_mesh.val.unwrap(),
          active_floor_material(),
          @math.Vec3::new(world_x, MAP_FLOOR_Y, world_z),
        )
        floor_entities.push(floor_entity)

        let ceiling_entity = spawn_mesh_entity(
          floor_mesh.val.unwrap(),
          active_ceiling_material(),
          @math.Vec3::new(world_x, MAP_CEILING_Y, world_z),
        )
        ceiling_entities.push(ceiling_entity)
      }

      if tile == 1 {
        let wall_entity = spawn_mesh_entity(
          wall_mesh.val.unwrap(),
          active_wall_material(),
          @math.Vec3::new(world_x, WALL_HALF_HEIGHT_Y, world_z),
        )
        wall_entities.push(wall_entity)
      } else if tile == 2 {
        player_state.x = world_x
        player_state.z = world_z
        player_state.yaw = 0.0
        found_spawn = true
      } else if !lighting_debug.scene_enabled {
        let dot_entity = spawn_mesh_entity(
          dot_mesh.val.unwrap(),
          active_dot_material(),
          @math.Vec3::new(world_x, MAP_DOT_Y, world_z),
        )
        if debug_mode_allows_dot_light() {
          @render3d.point_lights3d().set(dot_entity, {
            ..@render3d.default_point_light3d(),
            color: color_rgba(245U, 227U, 92U, 1.0),
            intensity: DOT_LIGHT_INTENSITY,
            range: DOT_LIGHT_RANGE,
          })
        }
        let minimap_dot_entity = spawn_color_rect_entity(
          @math.Vec2D(MINIMAP_DOT_SIZE, MINIMAP_DOT_SIZE),
          minimap_pos_for_world(world_x, world_z, MINIMAP_DOT_SIZE),
          "rgb(252,224,80)",
          170,
        )
        dots.push({
          entity: dot_entity,
          minimap_entity: minimap_dot_entity,
          x: world_x,
          z: world_z,
          collected: false,
        })
      }

      if tile == 3 || tile == 4 || tile == 5 {
        let ghost_type = ghost_type_from_tile(tile)
        let ghost_entity = spawn_mesh_entity(
          ghost_body_mesh.val.unwrap(),
          ghost_material_for_type(ghost_type),
          @math.Vec3::new(world_x, MAP_GHOST_Y, world_z),
        )
        let ghost_light_entity = @entity.Entity::new()
        let ghost_spot_ray_entity = spawn_mesh_entity(
          ghost_spot_ray_mesh.val.unwrap(),
          ghost_spot_ray_material_for_type(ghost_type),
          @math.Vec3::new(world_x, MAP_GHOST_Y, world_z),
          cast_shadows=false,
          receive_shadows=false,
        )
        let left_eye_entity = spawn_mesh_entity(
          ghost_eye_mesh.val.unwrap(),
          active_ghost_eye_material(),
          @math.Vec3::new(world_x, MAP_GHOST_Y, world_z),
        )
        let right_eye_entity = spawn_mesh_entity(
          ghost_eye_mesh.val.unwrap(),
          active_ghost_eye_material(),
          @math.Vec3::new(world_x, MAP_GHOST_Y, world_z),
        )
        let ghost_minimap_color = match ghost_type {
          Fast => "rgb(255,0,0)"
          Normal => "rgb(255,165,0)"
          Slow => "rgb(0,128,255)"
        }
        let ghost_minimap_entity = spawn_color_rect_entity(
          @math.Vec2D(MINIMAP_MARKER_SIZE, MINIMAP_MARKER_SIZE),
          minimap_pos_for_world(world_x, world_z, MINIMAP_MARKER_SIZE),
          ghost_minimap_color,
          180,
        )
        let ghost_direction = if lighting_debug.scene_enabled {
          sandbox_ghost_direction_for_spawn(ghosts.length())
        } else {
          random_direction()
        }
        let ghost = {
          entity: ghost_entity,
          light_entity: ghost_light_entity,
          spot_ray_entity: ghost_spot_ray_entity,
          left_eye_entity,
          right_eye_entity,
          minimap_entity: ghost_minimap_entity,
          x: world_x,
          z: world_z,
          direction: ghost_direction,
          bob_phase: ghost_bob_phase_for_spawn(world_x, world_z, ghost_type),
          ghost_type,
        }
        sync_ghost_visuals(ghost)
        ghosts.push(ghost)
      }
    }
  }

  if !found_spawn {
    player_state.x = world_x_for_tile(1)
    player_state.z = world_z_for_tile(1)
    player_state.yaw = 0.0
  }
  setup_color_rect_entity(
    minimap_player_entity,
    @math.Vec2D(MINIMAP_MARKER_SIZE, MINIMAP_MARKER_SIZE),
    minimap_pos_for_world(player_state.x, player_state.z, MINIMAP_MARKER_SIZE),
    "rgb(0,255,0)",
    190,
  )
  sync_camera_transform()
}

///|
fn reset_run() -> Unit {
  current_level.val = 0
  completed_all_levels.val = false
  reset_lighting_debug_tracking()
  reset_level_entities()
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  register_pacman_upstream_font_once()
  ensure_entity_alive(camera_entity)
  ensure_entity_alive(light_entity)
  ensure_entity_alive(player_light_entity)
  ensure_entity_alive(hud_title_ui)
  ensure_entity_alive(hud_line1_ui)
  ensure_entity_alive(hud_line2_ui)
  ensure_entity_alive(hud_line3_ui)
  ensure_entity_alive(hud_debug_ui)
  ensure_entity_alive(minimap_player_entity)

  @camera3d.cameras3d().set(camera_entity, {
    ..@camera3d.Camera3DComponent::default(),
    fov_y: 60.0,
    near: 0.01,
    far: 300.0,
    clear_color: color_rgba(
      WORLD_CLEAR_COLOR_R,
      WORLD_CLEAR_COLOR_G,
      WORLD_CLEAR_COLOR_B,
      1.0,
    ),
    order: 10,
    enabled: true,
  })
  @render3d.directional_lights3d().set(light_entity, {
    ..@render3d.default_directional_light3d(),
    direction: @math.Vec3::new(-0.45, -1.0, -0.3),
    color: color_rgba(255U, 250U, 245U, 1.0),
    intensity: DIRECTIONAL_LIGHT_INTENSITY,
    shadows: false,
  })
  @render3d.point_lights3d().set(player_light_entity, {
    ..@render3d.default_point_light3d(),
    color: color_rgba(255U, 240U, 214U, 1.0),
    intensity: PLAYER_LIGHT_INTENSITY,
    range: PLAYER_LIGHT_RANGE,
  })
  @render3d.set_ambient_light3d(
    Some({
      color: color_rgba(190U, 205U, 240U, 1.0),
      intensity: AMBIENT_LIGHT_INTENSITY,
    }),
  )

  setup_text_entity(
    hud_title_ui,
    "",
    @math.Vec2D(VIEWPORT_WIDTH - 140.0, 40.0),
    "white",
  )
  setup_text_entity(
    hud_line1_ui,
    "",
    @math.Vec2D(VIEWPORT_WIDTH / 2.0 - 170.0, 30.0),
    "rgb(0,255,0)",
  )
  setup_text_entity(
    hud_line2_ui,
    "",
    @math.Vec2D(VIEWPORT_WIDTH / 2.0 - 120.0, 70.0),
    "rgb(0,255,0)",
  )
  setup_text_entity(hud_line3_ui, "", @math.Vec2D(0.0, 0.0), "white")
  setup_text_entity(hud_debug_ui, "", @math.Vec2D(8.0, 8.0), "rgb(180,255,180)")

  @system.lock_mouse()
  mouse_locked_last_frame.val = @system.is_mouse_locked()
  reset_run()
}

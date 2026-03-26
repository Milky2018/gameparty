///|
const VIEWPORT_WIDTH : Double = 960.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const FLOOR_SIZE : Double = 8.0

///|
const FLOOR_THICKNESS : Double = 0.2

///|
const CUBE_SIZE : Double = 1.0

///|
const SPHERE_RADIUS : Double = 0.55

///|
const ATLAS_PATH : String = "mooncraft/assets/generated/block_item_atlas.png"

///|
const ATLAS_COLUMNS : Int = 8

///|
const ATLAS_ROWS : Int = 11

///|
let camera_entity : @entity.Entity = @entity.Entity::new()

///|
let light_entity : @entity.Entity = @entity.Entity::new()

///|
let floor_entity : @entity.Entity = @entity.Entity::new()

///|
let cube_entity : @entity.Entity = @entity.Entity::new()

///|
let sphere_entity : @entity.Entity = @entity.Entity::new()

///|
let atlas_cube_entity : @entity.Entity = @entity.Entity::new()

///|
let label_entity : @entity.Entity = @entity.Entity::new()

///|
let chunk_entity : @entity.Entity = @entity.Entity::new()

///|
let floor_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let cube_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let sphere_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let floor_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let cube_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let sphere_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let atlas_image : Ref[@render3d.ImageHandle?] = { val: None }

///|
let atlas_cube_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let chunk_mesh : Ref[@render3d.MeshHandle?] = { val: None }

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
fn transform_2d(position : @math.Vec2D, zindex : Int) -> @transform.Transform {
  {
    translation: @math.Vec3::new(position[X], position[Y], zindex.to_double()),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  }
}

///|
fn atlas_uv(u : Float, v : Float, atlas_index : Int) -> @math.Vec2D {
  let col = atlas_index % ATLAS_COLUMNS
  let row = atlas_index / ATLAS_COLUMNS
  @math.Vec2D(
    (col.to_double() + u.to_double()) / ATLAS_COLUMNS.to_double(),
    (row.to_double() + v.to_double()) / ATLAS_ROWS.to_double(),
  )
}

///|
fn mesh_asset_from_mesh_data(mesh : @block.MeshData) -> @render3d.MeshAsset {
  let vertex_count = mesh.positions.length() / 3
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2D] = []
  let normals : Array[@math.Vec3] = []
  let colors : Array[@render.Color] = []
  for i in 0..<vertex_count {
    let pidx = i * 3
    let cidx = i * 4
    let atlas_index = mesh.layers[i].round().to_int()
    positions.push(
      @math.Vec3::new(
        mesh.positions[pidx].to_double(),
        mesh.positions[pidx + 1].to_double(),
        mesh.positions[pidx + 2].to_double(),
      ),
    )
    let uv = atlas_uv(mesh.uvs[i * 2], mesh.uvs[i * 2 + 1], atlas_index)
    uvs.push(uv)
    normals.push(
      @math.Vec3::new(
        mesh.normals[pidx].to_double(),
        mesh.normals[pidx + 1].to_double(),
        mesh.normals[pidx + 2].to_double(),
      ),
    )
    colors.push({
      r: (mesh.colors[cidx].to_double() * 255.0)
      .round()
      .to_int()
      .clamp(min=0, max=255)
      .reinterpret_as_uint(),
      g: (mesh.colors[cidx + 1].to_double() * 255.0)
      .round()
      .to_int()
      .clamp(min=0, max=255)
      .reinterpret_as_uint(),
      b: (mesh.colors[cidx + 2].to_double() * 255.0)
      .round()
      .to_int()
      .clamp(min=0, max=255)
      .reinterpret_as_uint(),
      a: mesh.colors[cidx + 3].to_double(),
    })
  }
  let preview = if vertex_count < 8 { vertex_count } else { 8 }
  for i in 0..<preview {
    let raw_u = mesh.uvs[i * 2]
    let raw_v = mesh.uvs[i * 2 + 1]
    let layer = mesh.layers[i].round().to_int()
    let mapped = uvs[i]
    println(
      "[min3dprobe][mapped-vtx \{i}] raw_uv=(\{raw_u},\{raw_v}) layer=\{layer} atlas_uv=\{mapped}",
    )
  }
  @render3d.triangle_mesh(
    positions,
    uvs=Some(uvs),
    normals=Some(normals),
  )
}

///|
fn look_rotation(eye : @math.Vec3, target : @math.Vec3) -> @math.Quat {
  let forward = (target - eye).normalize()
  let right = forward.cross(@math.Vec3::y_axis()).normalize()
  let up = right.cross(forward).normalize()
  @math.Quat::from_basis(
    right,
    up,
    @math.Vec3::new(-forward.x, -forward.y, -forward.z),
  )
}

///|
fn register_assets_once() -> Unit {
  if floor_mesh.val is Some(_) {
    return
  }
  floor_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(
        @math.Vec3::new(FLOOR_SIZE, FLOOR_THICKNESS, FLOOR_SIZE),
      ),
    ),
  )
  cube_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(@math.Vec3::new(CUBE_SIZE, CUBE_SIZE, CUBE_SIZE)),
    ),
  )
  sphere_mesh.val = Some(
    @render3d.register_mesh_asset(@render3d.sphere_mesh(SPHERE_RADIUS)),
  )
  floor_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(190U, 190U, 196U, 1.0),
      roughness: 0.95,
    }),
  )
  cube_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(234U, 120U, 70U, 1.0),
      roughness: 0.65,
    }),
  )
  sphere_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(74U, 168U, 255U, 1.0),
      emissive_color: color_rgba(18U, 44U, 92U, 1.0),
      roughness: 0.25,
    }),
  )
  atlas_image.val = Some(@render3d.register_image_asset({ path: ATLAS_PATH }))
  atlas_cube_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(255U, 255U, 255U, 1.0),
      base_color_texture: Some(
        @render3d.texture_binding3d(atlas_image.val.unwrap(), sampler={
          wrap_u: @render3d.TextureWrap3D::ClampToEdge,
          wrap_v: @render3d.TextureWrap3D::ClampToEdge,
          min_filter: @render3d.TextureFilter3D::Nearest,
          mag_filter: @render3d.TextureFilter3D::Nearest,
          mipmap_filter: None,
        }),
      ),
      roughness: 0.8,
    }),
  )
  let texture_names = @block.collect_texture_names()
  let texture_indices = Array::makei(texture_names.length(), fn(i) { i })
  let registry = @block.BlockRegistry::create(texture_names, texture_indices)
  let world = @level.World::new(seed=1UL, world_type=@level.WorldType::Flat)
  let chunk = world.generate_chunk(0, 0, 0)
  let light = Bytes::make(
    @level.CHUNK_X_SIZE * @level.CHUNK_Y_SIZE * @level.CHUNK_Z_SIZE,
    b'\x0f',
  )
  let split = @block.build_chunk_mesh_split(
    registry,
    chunk.tile_map,
    light,
    @level.CHUNK_X_SIZE,
  )
  let mut layer_min = 1 << 30
  let mut layer_max = -(1 << 30)
  let layer_counts : Map[Int, Int] = Map::new()
  for layer in split.normal.layers {
    let value = layer.round().to_int()
    if value < layer_min {
      layer_min = value
    }
    if value > layer_max {
      layer_max = value
    }
    layer_counts.set(value, layer_counts.get(value).unwrap_or(0) + 1)
  }
  println(
    "[min3dprobe][chunk] vertices=\{split.normal.count} layers=\{split.normal.layers.length()} layer_min=\{layer_min} layer_max=\{layer_max}",
  )
  let sample_vertices = if split.normal.count < 6 {
    split.normal.count
  } else {
    6
  }
  for i in 0..<sample_vertices {
    let pidx = i * 3
    let uidx = i * 2
    let layer = split.normal.layers[i]
    println(
      "[min3dprobe][chunk-vtx \{i}] pos=(\{split.normal.positions[pidx]},\{split.normal.positions[pidx + 1]},\{split.normal.positions[pidx + 2]}) uv=(\{split.normal.uvs[uidx]},\{split.normal.uvs[uidx + 1]}) layer=\{layer}",
    )
  }
  let layer_summary : Array[String] = []
  for layer in layer_min..<=layer_max {
    match layer_counts.get(layer) {
      Some(count) => layer_summary.push("\{layer}:\{count}")
      None => ()
    }
  }
  let layer_summary_text = layer_summary.join(" ")
  println("[min3dprobe][chunk-layers] \{layer_summary_text}")
  chunk_mesh.val = Some(
    @render3d.register_mesh_asset(mesh_asset_from_mesh_data(split.normal)),
  )
}

///|
fn setup_camera_and_lighting() -> Unit {
  let eye = @math.Vec3::new(4.0, 3.2, 5.4)
  let target = @math.Vec3::new(0.4, 0.9, 0.0)
  @transform.transforms().set(camera_entity, {
    translation: eye,
    rotation: look_rotation(eye, target),
    scale: @math.Vec3::one(),
  })
  @camera3d.cameras3d().set(camera_entity, {
    ..@camera3d.Camera3DComponent::default(),
    fov_y: 60.0,
    near: 0.01,
    far: 100.0,
    clear_color: color_rgba(40U, 60U, 82U, 1.0),
    order: 10,
    enabled: true,
  })
  @transform.transforms().set(light_entity, {
    translation: @math.Vec3::new(0.0, 6.0, 0.0),
    rotation: @math.Quat::from_axis_angle(@math.Vec3::x_axis(), -0.85) *
    @math.Quat::from_axis_angle(@math.Vec3::y_axis(), -0.65),
    scale: @math.Vec3::one(),
  })
  @render3d.directional_lights3d().set(light_entity, {
    ..@render3d.default_directional_light3d(),
    color: color_rgba(255U, 248U, 238U, 1.0),
    intensity: 24.0,
  })
  @render3d.set_ambient_light3d(
    Some({ color: color_rgba(176U, 188U, 212U, 1.0), intensity: 0.55 }),
  )
}

///|
fn setup_scene() -> Unit {
  @transform.transforms().set(floor_entity, {
    translation: @math.Vec3::new(0.0, -FLOOR_THICKNESS / 2.0, 0.0),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  @render3d.mesh3d_renderers().set(floor_entity, {
    visible: true,
    mesh: floor_mesh.val.unwrap(),
    material: floor_material.val.unwrap(),
    cast_shadows: true,
    receive_shadows: true,
  })

  @transform.transforms().set(cube_entity, {
    translation: @math.Vec3::new(0.0, CUBE_SIZE / 2.0, 0.0),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  @render3d.mesh3d_renderers().set(cube_entity, {
    visible: true,
    mesh: cube_mesh.val.unwrap(),
    material: cube_material.val.unwrap(),
    cast_shadows: true,
    receive_shadows: true,
  })

  @transform.transforms().set(sphere_entity, {
    translation: @math.Vec3::new(1.85, SPHERE_RADIUS, -1.35),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  @render3d.mesh3d_renderers().set(sphere_entity, {
    visible: true,
    mesh: sphere_mesh.val.unwrap(),
    material: sphere_material.val.unwrap(),
    cast_shadows: true,
    receive_shadows: true,
  })

  @transform.transforms().set(atlas_cube_entity, {
    translation: @math.Vec3::new(-1.85, CUBE_SIZE / 2.0, -1.0),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  @render3d.mesh3d_renderers().set(atlas_cube_entity, {
    visible: true,
    mesh: cube_mesh.val.unwrap(),
    material: atlas_cube_material.val.unwrap(),
    cast_shadows: true,
    receive_shadows: true,
  })

  @transform.transforms().set(chunk_entity, {
    translation: @math.Vec3::new(-3.2, 0.0, -5.4),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::new(0.14, 0.14, 0.14),
  })
  @render3d.mesh3d_renderers().set(chunk_entity, {
    visible: true,
    mesh: chunk_mesh.val.unwrap(),
    material: atlas_cube_material.val.unwrap(),
    cast_shadows: true,
    receive_shadows: true,
  })
}

///|
fn setup_label() -> Unit {
  @ui.texts().set(
    label_entity,
    @ui.Text::new(
      "Minimal 3D probe: gray floor, orange cube, blue sphere, textured cube, flat chunk. Esc exits.",
    ),
  )
  @ui.text_fonts().set(label_entity, @ui.TextFont::from_css("18px Arial"))
  @ui.text_colors().set(label_entity, @ui.TextColor::from_css("white"))
  @ui.text_layouts().set(
    label_entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(label_entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(
    label_entity,
    @sprite.Anchor(@math.Vec2D(-0.5, 0.5)),
  )
  @transform.transforms().set(
    label_entity,
    transform_2d(@math.Vec2D(14.0, 14.0), 400),
  )
  @visibility.visibilities().set(label_entity, Visible)
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  ensure_entity_alive(camera_entity)
  ensure_entity_alive(light_entity)
  ensure_entity_alive(floor_entity)
  ensure_entity_alive(cube_entity)
  ensure_entity_alive(sphere_entity)
  ensure_entity_alive(atlas_cube_entity)
  ensure_entity_alive(chunk_entity)
  ensure_entity_alive(label_entity)
  register_assets_once()
  setup_camera_and_lighting()
  setup_scene()
  setup_label()
}

///|
fn update_system(_world : @ecs.World) -> Unit {
  if @inputs.is_just_pressed(Escape) {
    @system.exit()
    return
  }
  let delta = @time.delta()
  if delta <= 0.0 {
    return
  }
  let transform = @transform.transforms()
    .get(cube_entity)
    .unwrap_or(@transform.Transform::identity())
  let rotation = @math.Quat::from_axis_angle(@math.Vec3::y_axis(), delta * 0.9)
  @transform.transforms().set(cube_entity, {
    ..transform,
    rotation: rotation * transform.rotation,
  })
}

///|
pub fn run() -> Unit {
  let app = @app.App::new()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(1.0)
    .with_fps(FPS)
    .add_plugin(@plugins.default_3d_plugin)
    .add_system(Startup, startup_system)
    .add_system(Update, update_system)
  app.run()
}

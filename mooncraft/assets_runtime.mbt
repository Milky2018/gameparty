///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
fn atlas_uv(u : Float, v : Float, atlas_index : Int) -> @math.Vec2 {
  let col = atlas_index % ATLAS_COLUMNS
  let row = atlas_index / ATLAS_COLUMNS
  let cols_f = ATLAS_COLUMNS.to_double()
  let rows_f = ATLAS_ROWS.to_double()
  let tile_min_u = col.to_double() / cols_f
  let tile_max_u = (col + 1).to_double() / cols_f
  let tile_min_v = row.to_double() / rows_f
  let tile_max_v = (row + 1).to_double() / rows_f
  let atlas_px_w = (ATLAS_COLUMNS * 16).to_double()
  let atlas_px_h = (ATLAS_ROWS * 16).to_double()
  let inset_u = 0.5 / atlas_px_w
  let inset_v = 0.5 / atlas_px_h
  let mapped_u = (col.to_double() + u.to_double().clamp(min=0.0, max=1.0)) /
    cols_f
  let mapped_v = (row.to_double() + v.to_double().clamp(min=0.0, max=1.0)) /
    rows_f
  @math.Vec2(
    mapped_u.clamp(min=tile_min_u + inset_u, max=tile_max_u - inset_u),
    mapped_v.clamp(min=tile_min_v + inset_v, max=tile_max_v - inset_v),
  )
}

///|
let debug_first_mesh_logged : Ref[Bool] = { val: false }

///|
fn mesh_asset_from_mesh_data(mesh : @block.MeshData) -> @render3d.MeshAsset {
  let vertex_count = mesh.positions.length() / 3
  let positions : Array[@math.Vec3] = []
  let uvs : Array[@math.Vec2] = []
  let normals : Array[@math.Vec3] = []
  let colors : Array[@render.Color] = []
  let mut atlas_min = 1 << 30
  let mut atlas_max = -(1 << 30)
  let center_offset = chunk_mesh_center_offset()
  let mut u_min = 1_000_000_000.0
  let mut u_max = -1_000_000_000.0
  let mut v_min = 1_000_000_000.0
  let mut v_max = -1_000_000_000.0
  for i in 0..<vertex_count {
    let pidx = i * 3
    let atlas_index = mesh.layers[i].round().to_int()
    if atlas_index < atlas_min {
      atlas_min = atlas_index
    }
    if atlas_index > atlas_max {
      atlas_max = atlas_index
    }
    positions.push(
      @math.Vec3::new(
        mesh.positions[pidx].to_double() - center_offset.x,
        mesh.positions[pidx + 1].to_double() - center_offset.y,
        mesh.positions[pidx + 2].to_double() - center_offset.z,
      ),
    )
    let uv = atlas_uv(mesh.uvs[i * 2], mesh.uvs[i * 2 + 1], atlas_index)
    if uv[X] < u_min {
      u_min = uv[X]
    }
    if uv[X] > u_max {
      u_max = uv[X]
    }
    if uv[Y] < v_min {
      v_min = uv[Y]
    }
    if uv[Y] > v_max {
      v_max = uv[Y]
    }
    uvs.push(uv)
    normals.push(
      @math.Vec3::new(
        mesh.normals[pidx].to_double(),
        mesh.normals[pidx + 1].to_double(),
        mesh.normals[pidx + 2].to_double(),
      ),
    )
    let cidx = i * 4
    let to_channel = fn(v : Float) -> UInt {
      (v.to_double().clamp(min=0.0, max=1.0) * 255.0).round().to_uint()
    }
    colors.push({
      r: to_channel(mesh.colors[cidx]),
      g: to_channel(mesh.colors[cidx + 1]),
      b: to_channel(mesh.colors[cidx + 2]),
      a: mesh.colors[cidx + 3].to_double().clamp(min=0.0, max=1.0),
    })
  }
  if DEBUG_VERBOSE_STARTUP && !debug_first_mesh_logged.val {
    let preview = if vertex_count < 8 { vertex_count } else { 8 }
    for i in 0..<preview {
      let uv = uvs[i]
      let layer = mesh.layers[i].round().to_int()
      println(
        "[mooncraft][mesh-vtx \{i}] layer=\{layer} uv=\{debug_vec2_string(uv)} raw_uv=(\{mesh.uvs[i * 2]},\{mesh.uvs[i * 2 + 1]})",
      )
    }
    println(
      "[mooncraft][mesh] vertices=\{vertex_count} layers=[\{atlas_min},\{atlas_max}] uv_u=[\{u_min},\{u_max}] uv_v=[\{v_min},\{v_max}]",
    )
    debug_first_mesh_logged.val = true
  }
  @render3d.triangle_mesh(
    positions,
    uvs=Some(uvs),
    normals=Some(normals),
    colors=Some(colors),
  )
}

///|
fn block_primary_texture(block : @block.Block) -> String {
  match block.faces.pos_y {
    Some(texture) => texture
    None =>
      match block.faces.pos_x {
        Some(texture) => texture
        None => @block.fallback_texture
      }
  }
}

///|
fn build_registry_and_texture_names() -> (
  @block.BlockRegistry,
  Array[String],
  Map[String, Int],
  Array[@render.Color],
) {
  let texture_names = @block.collect_texture_names()
  let texture_indices = Array::makei(texture_names.length(), fn(i) { i })
  let registry = @block.BlockRegistry::create(texture_names, texture_indices)
  let texture_name_to_index : Map[String, Int] = Map::new()
  for index, texture_name in texture_names {
    texture_name_to_index.set(texture_name, index)
  }
  let texture_colors = Array::makei(texture_names.length(), fn(_) {
    color_rgba(255U, 255U, 255U, 1.0)
  })
  (registry, texture_names, texture_name_to_index, texture_colors)
}

///|
fn world_chunk_material(
  atlas_image : @render3d.ImageHandle,
  alpha_mode : @render3d.AlphaMode3D,
) -> @render3d.StandardMaterial3D {
  let base_color = color_rgba(255U, 255U, 255U, 1.0)
  {
    ..@render3d.default_standard_material3d(),
    base_color,
    base_color_texture: Some(
      @render3d.texture_binding3d(atlas_image, sampler={
        wrap_u: @render3d.TextureWrap3D::ClampToEdge,
        wrap_v: @render3d.TextureWrap3D::ClampToEdge,
        min_filter: @render3d.TextureFilter3D::Nearest,
        mag_filter: @render3d.TextureFilter3D::Nearest,
        mipmap_filter: None,
      }),
    ),
    alpha_mode,
    alpha_cutoff: if alpha_mode is @render3d.AlphaMode3D::Mask {
      0.5
    } else {
      0.0
    },
    unlit: false,
    double_sided: true,
    roughness: 1.0,
    metallic: 0.0,
  }
}

///|
fn register_world_materials_once() -> Unit {
  if atlas_image_handle.val is None {
    let atlas_path = resolve_mooncraft_asset_path(ATLAS_PATH)
    atlas_image_handle.val = Some(
      @render3d.register_image_asset({ path: atlas_path }),
    )
  }
  if gui_window_image_handle.val is None {
    gui_window_image_handle.val = Some(@asset.load_image(GUI_WINDOW_PATH))
  }
  if cube_mesh_handle.val is None {
    cube_mesh_handle.val = Some(
      @render3d.register_mesh_asset(@render3d.cube_mesh(@math.Vec3::one())),
    )
  }
  guard atlas_image_handle.val is Some(atlas_image) else { return }
  if opaque_material_handle.val is None {
    opaque_material_handle.val = Some(
      @render3d.register_material_asset(
        world_chunk_material(atlas_image, @render3d.AlphaMode3D::Opaque),
      ),
    )
  }
  if cutout_material_handle.val is None {
    cutout_material_handle.val = Some(
      @render3d.register_material_asset(
        world_chunk_material(atlas_image, @render3d.AlphaMode3D::Mask),
      ),
    )
  }
  if translucent_material_handle.val is None {
    translucent_material_handle.val = Some(
      @render3d.register_material_asset(
        world_chunk_material(atlas_image, @render3d.AlphaMode3D::Blend),
      ),
    )
  }
  if selection_material_handle.val is None {
    selection_material_handle.val = Some(
      @render3d.register_material_asset({
        ..@render3d.default_standard_material3d(),
        base_color: color_rgba(255U, 255U, 255U, 0.18),
        alpha_mode: @render3d.AlphaMode3D::Blend,
        unlit: true,
        double_sided: true,
      }),
    )
  }
  if preview_material_handle.val is None {
    preview_material_handle.val = Some(
      @render3d.register_material_asset({
        ..@render3d.default_standard_material3d(),
        base_color: color_rgba(114U, 216U, 132U, 0.28),
        alpha_mode: @render3d.AlphaMode3D::Blend,
        unlit: true,
        double_sided: true,
      }),
    )
  }
  if debug_marker_material_handle.val is None {
    debug_marker_material_handle.val = Some(
      @render3d.register_material_asset({
        ..@render3d.default_standard_material3d(),
        base_color: color_rgba(255U, 132U, 42U, 1.0),
        emissive_color: color_rgba(255U, 96U, 32U, 1.0),
        unlit: true,
        double_sided: true,
      }),
    )
  }
}

///|
fn refresh_world_material_bindings() -> Unit {
  guard atlas_image_handle.val is Some(atlas_image) else { return }
  if opaque_material_handle.val is Some(handle) {
    @render3d.update_material_asset(
      handle,
      world_chunk_material(atlas_image, @render3d.AlphaMode3D::Opaque),
    )
  }
  if cutout_material_handle.val is Some(handle) {
    @render3d.update_material_asset(
      handle,
      world_chunk_material(atlas_image, @render3d.AlphaMode3D::Mask),
    )
  }
  if translucent_material_handle.val is Some(handle) {
    @render3d.update_material_asset(
      handle,
      world_chunk_material(atlas_image, @render3d.AlphaMode3D::Blend),
    )
  }
}

///|
fn build_creative_catalog() -> Array[CatalogEntry] {
  let catalog : Array[CatalogEntry] = []
  for block in @block.blocks {
    if !(block.category is @item.Block) {
      continue
    }
    let icon_texture = block_primary_texture(block)
    catalog.push({
      name: block.name,
      category: @item.Block,
      icon_texture,
      icon_path: icon_texture_to_asset_path(icon_texture),
      icon_handle: @asset.load_image(icon_texture_to_asset_path(icon_texture)),
      block_long_id: Some(block.long_id()),
    })
  }
  for item in @item.items {
    let icon_path = icon_texture_to_asset_path(item.texture)
    catalog.push({
      name: item.name,
      category: item.category,
      icon_texture: item.texture,
      icon_path,
      icon_handle: @asset.load_image(icon_path),
      block_long_id: None,
    })
  }
  catalog
}

///|
fn catalog_index_by_name(catalog : Array[CatalogEntry], name : String) -> Int? {
  for index, entry in catalog {
    if entry.name == name {
      return Some(index)
    }
  }
  None
}

///|
fn default_hotbar_slots(catalog : Array[CatalogEntry]) -> Array[HotbarSlot] {
  let preferred = [
    "stone", "grass", "dirt", "cobblestone", "sand", "glass", "torch", "water_bucket",
    "iron_shovel",
  ]
  let hotbar : Array[HotbarSlot] = []
  for name in preferred {
    match catalog_index_by_name(catalog, name) {
      Some(index) => hotbar.push({ catalog_index: index })
      None => ()
    }
  }
  let mut fallback_index = 0
  while hotbar.length() < HOTBAR_SIZE && fallback_index < catalog.length() {
    hotbar.push({ catalog_index: fallback_index })
    fallback_index += 1
  }
  while hotbar.length() < HOTBAR_SIZE {
    hotbar.push({ catalog_index: 0 })
  }
  hotbar
}

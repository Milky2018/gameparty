///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
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
    uvs.push(atlas_uv(mesh.uvs[i * 2], mesh.uvs[i * 2 + 1], atlas_index))
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
) {
  let texture_names = @block.collect_texture_names()
  let texture_indices = Array::makei(texture_names.length(), fn(i) { i })
  let registry = @block.BlockRegistry::create(texture_names, texture_indices)
  let texture_name_to_index : Map[String, Int] = Map::new()
  for index, texture_name in texture_names {
    texture_name_to_index.set(texture_name, index)
  }
  (registry, texture_names, texture_name_to_index)
}

///|
fn register_world_materials_once() -> Unit {
  if atlas_image_handle.val is None {
    atlas_image_handle.val = Some(
      @render3d.register_image_asset({ path: ATLAS_PATH }),
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
      @render3d.register_material_asset({
        ..@render3d.default_standard_material3d(),
        base_color: color_rgba(255U, 255U, 255U, 1.0),
        base_color_texture: Some(@render3d.texture_binding3d(atlas_image)),
        alpha_mode: @render3d.AlphaMode3D::Opaque,
        roughness: 1.0,
        metallic: 0.0,
      }),
    )
  }
  if cutout_material_handle.val is None {
    cutout_material_handle.val = Some(
      @render3d.register_material_asset({
        ..@render3d.default_standard_material3d(),
        base_color: color_rgba(255U, 255U, 255U, 1.0),
        base_color_texture: Some(@render3d.texture_binding3d(atlas_image)),
        alpha_mode: @render3d.AlphaMode3D::Mask,
        alpha_cutoff: 0.5,
        double_sided: true,
        roughness: 1.0,
        metallic: 0.0,
      }),
    )
  }
  if translucent_material_handle.val is None {
    translucent_material_handle.val = Some(
      @render3d.register_material_asset({
        ..@render3d.default_standard_material3d(),
        base_color: color_rgba(255U, 255U, 255U, 1.0),
        base_color_texture: Some(@render3d.texture_binding3d(atlas_image)),
        alpha_mode: @render3d.AlphaMode3D::Blend,
        double_sided: true,
        roughness: 1.0,
        metallic: 0.0,
      }),
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

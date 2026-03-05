///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
const PACMAN_UPSTREAM_FONT_FAMILY : String = "Arial"

///|
let pacman_upstream_font_registered : Ref[Bool] = { val: false }

///|
let pacman_upstream_font_candidate_paths : Array[String] = [
  "/System/Library/Fonts/Supplemental/Arial.ttf", "/Library/Fonts/Arial.ttf", "C:/Windows/Fonts/arial.ttf",
  "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/liberation/LiberationSans-Regular.ttf",
]

///|
fn register_pacman_upstream_font_once() -> Unit {
  if pacman_upstream_font_registered.val {
    return
  }
  for path in pacman_upstream_font_candidate_paths {
    if @asset.read_bytes(path) is Some(_) {
      ignore(@asset.load_font(path, family=PACMAN_UPSTREAM_FONT_FAMILY))
      pacman_upstream_font_registered.val = true
      return
    }
  }
  pacman_upstream_font_registered.val = true
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn setup_text_entity(
  entity : @entity.Entity,
  content : String,
  position : @math.Vec2D,
  color : String,
) -> Unit {
  ensure_entity_alive(entity)
  let text = @sprite.Text::new(
    content,
    color~,
    font="18px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    baseline=Top,
    align=Left,
  )
  @sprite.sprites.set(entity, @sprite.Sprite::from_text(text, 200))
  @transform.positions.set(entity, position)
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
  let sprite = @sprite.Sprite::from_color_rect(
    @sprite.ColorRect::new(size, color),
    zindex,
  )
  @sprite.sprites.set(entity, sprite)
  @transform.positions.set(entity, position)
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
    @render3d.register_mesh_asset(@render3d.sphere_mesh(DOT_RADIUS)),
  )
  ghost_mesh.val = Some(
    @render3d.register_mesh_asset(@render3d.sphere_mesh(GHOST_RADIUS)),
  )

  let wall_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(73U, 111U, 223U, 1.0),
    roughness: 0.85,
    metallic: 0.05,
  }
  wall_material.val = Some(
    @render3d.register_material_asset(wall_material_asset),
  )

  let floor_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(18U, 24U, 36U, 1.0),
    roughness: 0.98,
  }
  floor_material.val = Some(
    @render3d.register_material_asset(floor_material_asset),
  )

  let dot_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(245U, 227U, 92U, 1.0),
    emissive_color: color_rgba(168U, 146U, 56U, 1.0),
    roughness: 0.3,
  }
  dot_material.val = Some(@render3d.register_material_asset(dot_material_asset))

  let fast_ghost_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(220U, 42U, 42U, 1.0),
    emissive_color: color_rgba(84U, 16U, 16U, 1.0),
    roughness: 0.35,
  }
  ghost_material_fast.val = Some(
    @render3d.register_material_asset(fast_ghost_material_asset),
  )

  let normal_ghost_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(246U, 146U, 46U, 1.0),
    emissive_color: color_rgba(96U, 48U, 16U, 1.0),
    roughness: 0.35,
  }
  ghost_material_normal.val = Some(
    @render3d.register_material_asset(normal_ghost_material_asset),
  )

  let slow_ghost_material_asset = {
    ..@render3d.default_standard_material3d(),
    base_color: color_rgba(42U, 108U, 214U, 1.0),
    emissive_color: color_rgba(18U, 40U, 84U, 1.0),
    roughness: 0.35,
  }
  ghost_material_slow.val = Some(
    @render3d.register_material_asset(slow_ghost_material_asset),
  )
}

///|
fn spawn_mesh_entity(
  mesh : @render3d.MeshHandle,
  material : @render3d.MaterialHandle,
  translation : @math.Vec3,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  @render3d.mesh3d_renderers.set(entity, { mesh, material, visible: true })
  @transform3d.transforms3d.set(entity, {
    translation,
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  entity
}

///|
fn ghost_material_for_type(ghost_type : GhostType) -> @render3d.MaterialHandle {
  match ghost_type {
    Fast => ghost_material_fast.val.unwrap()
    Normal => ghost_material_normal.val.unwrap()
    Slow => ghost_material_slow.val.unwrap()
  }
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

  for entity in wall_entities {
    entity.destroy()
  }
  wall_entities.clear()

  for entity in minimap_tile_entities {
    entity.destroy()
  }
  minimap_tile_entities.clear()

  for dot in dots {
    dot.entity.destroy()
    dot.minimap_entity.destroy()
  }
  dots.clear()

  for ghost in ghosts {
    ghost.entity.destroy()
    ghost.minimap_entity.destroy()
  }
  ghosts.clear()
}

///|
fn sync_camera_transform() -> Unit {
  ensure_entity_alive(camera_entity)
  ensure_entity_alive(player_light_entity)
  let yaw = -(player_state.yaw + @cmath.PI / 2.0)
  @transform3d.transforms3d.set(camera_entity, {
    translation: @math.Vec3::new(player_state.x, PLAYER_HEIGHT, player_state.z),
    rotation: @math.Quat::from_axis_angle(@math.Vec3::new(0.0, 1.0, 0.0), yaw),
    scale: @math.Vec3::one(),
  })
  let forward_x = @cmath.cos(player_state.yaw)
  let forward_z = @cmath.sin(player_state.yaw)
  @transform3d.transforms3d.set(player_light_entity, {
    translation: @math.Vec3::new(
      player_state.x + forward_x * 0.45,
      PLAYER_HEIGHT + 0.2,
      player_state.z + forward_z * 0.45,
    ),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
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
          floor_material.val.unwrap(),
          @math.Vec3::new(world_x, MAP_FLOOR_Y, world_z),
        )
        floor_entities.push(floor_entity)
      }

      if tile == 1 {
        let wall_entity = spawn_mesh_entity(
          wall_mesh.val.unwrap(),
          wall_material.val.unwrap(),
          @math.Vec3::new(world_x, WALL_HALF_HEIGHT_Y, world_z),
        )
        wall_entities.push(wall_entity)
      } else if tile == 2 {
        player_state.x = world_x
        player_state.z = world_z
        player_state.yaw = 0.0
        found_spawn = true
      } else {
        let dot_entity = spawn_mesh_entity(
          dot_mesh.val.unwrap(),
          dot_material.val.unwrap(),
          @math.Vec3::new(world_x, MAP_DOT_Y, world_z),
        )
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
          ghost_mesh.val.unwrap(),
          ghost_material_for_type(ghost_type),
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
        ghosts.push({
          entity: ghost_entity,
          minimap_entity: ghost_minimap_entity,
          x: world_x,
          z: world_z,
          direction: random_direction(),
          ghost_type,
        })
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
  reset_level_entities()
}

///|
fn startup_system(_delta : Double) -> Unit {
  register_pacman_upstream_font_once()
  install_embedded_assets()
  ensure_entity_alive(camera_entity)
  ensure_entity_alive(light_entity)
  ensure_entity_alive(player_light_entity)
  ensure_entity_alive(hud_title_ui)
  ensure_entity_alive(hud_line1_ui)
  ensure_entity_alive(hud_line2_ui)
  ensure_entity_alive(hud_line3_ui)
  ensure_entity_alive(minimap_player_entity)

  @camera3d.cameras3d.set(camera_entity, {
    ..@camera3d.Camera3DComponent::default(),
    fov_y: 60.0,
    near: 0.01,
    far: 300.0,
    clear_color: color_rgba(7U, 8U, 12U, 1.0),
    order: 10,
    enabled: true,
  })
  @render3d.directional_lights3d.set(light_entity, {
    direction: @math.Vec3::new(-0.45, -1.0, -0.3),
    color: color_rgba(255U, 250U, 245U, 1.0),
    intensity: 0.55,
    shadows: false,
  })
  @render3d.point_lights3d.set(player_light_entity, {
    color: color_rgba(255U, 240U, 214U, 1.0),
    intensity: 2.8,
    range: 9.5,
  })
  @render3d.set_ambient_light3d(
    Some({ color: color_rgba(190U, 205U, 240U, 1.0), intensity: 0.18 }),
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

  @system.lock_mouse()
  reset_run()
}

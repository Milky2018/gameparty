///|
fn rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
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
fn world_transform(
  center : @math.Vec2D,
  z : Double,
  scale? : @math.Vec2D = @math.Vec2D(1.0, 1.0),
) -> @transform.Transform {
  {
    translation: @math.Vec3::new(center[X], center[Y], z),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::new(scale[X], scale[Y], 1.0),
  }
}

///|
fn set_rect_entity(
  entity : @entity.Entity,
  center : @math.Vec2D,
  size : @math.Vec2D,
  color : @render.Color,
  z : Double,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_color(color, size)
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  let top_left = @math.Vec2D(
    center[X] - size[X] * 0.5,
    center[Y] - size[Y] * 0.5,
  )
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, world_transform(top_left, z))
  set_entity_visibility(entity, true)
}

///|
fn set_text_entity(
  entity : @entity.Entity,
  text : String,
  position : @math.Vec2D,
  color : String,
  size? : Double = 24.0,
  z? : Double = HUD_Z,
) -> Unit {
  ensure_entity_alive(entity)
  @ui.texts().set(entity, @ui.Text::new(text))
  @ui.text_fonts().set(entity, @ui.TextFont::new(family="monospace", size~))
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=NoWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2D(-0.5, 0.5)))
  @transform.transforms().set(entity, world_transform(position, z))
  set_entity_visibility(entity, true)
}

///|
fn circle_handle(radius : Double) -> @mesh2d.Mesh2dHandle {
  if radius == 10.0 {
    if sun_mesh_handle.val is Some(value) {
      return value
    }
    let mesh = @mesh2d.circle(radius)
    sun_mesh_handle.val = Some(mesh)
    mesh
  } else {
    if bullet_mesh_handle.val is Some(value) {
      return value
    }
    let mesh = @mesh2d.circle(radius)
    bullet_mesh_handle.val = Some(mesh)
    mesh
  }
}

///|
fn circle_material(color : @render.Color) -> @material2d.ColorMaterialHandle {
  if color == rgba(251U, 219U, 90U, 1.0) {
    if sun_material_handle.val is Some(value) {
      return value
    }
    let handle = @material2d.register_color_material(
      @material2d.ColorMaterial::from_color(color),
    )
    sun_material_handle.val = Some(handle)
    handle
  } else {
    if bullet_material_handle.val is Some(value) {
      return value
    }
    let handle = @material2d.register_color_material(
      @material2d.ColorMaterial::from_color(color),
    )
    bullet_material_handle.val = Some(handle)
    handle
  }
}

///|
fn spawn_circle_entity(
  center : @math.Vec2D,
  radius : Double,
  color : @render.Color,
  z : Double,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  @transform.transforms().set(entity, world_transform(center, z))
  @mesh2d.mesh2ds().set(entity, @mesh2d.Mesh2d::new(circle_handle(radius)))
  @material2d.mesh_material2ds().set(
    entity,
    @material2d.MeshMaterial2d::from_color_material(circle_material(color)),
  )
  set_entity_visibility(entity, true)
  entity
}

///|
fn clear_dynamic_entities() -> Unit {
  for plant in plants {
    plant.entity.destroy()
  }
  for zombie in zombies {
    zombie.entity.destroy()
  }
  for bullet in bullets {
    bullet.entity.destroy()
  }
  for sun in suns {
    sun.entity.destroy()
  }
  plants.clear()
  zombies.clear()
  bullets.clear()
  suns.clear()
}

///|
fn clear_static_entities() -> Unit {
  for entity in board_cells {
    entity.destroy()
  }
  for entity in board_grid_lines {
    entity.destroy()
  }
  for entity in house_entities {
    entity.destroy()
  }
  for entity in plant_overlay_entities {
    entity.destroy()
  }
  board_cells.clear()
  board_grid_lines.clear()
  house_entities.clear()
  plant_overlay_entities.clear()
}

///|
fn spawn_board_cell(x : Int, y : Int) -> Unit {
  let center = cell_center(x, y)
  let entity = @entity.Entity::new()
  let color = if (x + y) % 2 == 0 {
    rgba(64U, 138U, 68U, 1.0)
  } else {
    rgba(56U, 120U, 60U, 1.0)
  }
  set_rect_entity(
    entity,
    center,
    @math.Vec2D(CELL_SIZE, CELL_SIZE),
    color,
    BOARD_Z,
  )
  board_cells.push(entity)
}

///|
fn spawn_board_grid_line(center : @math.Vec2D, size : @math.Vec2D) -> Unit {
  let entity = @entity.Entity::new()
  set_rect_entity(
    entity,
    center,
    size,
    rgba(35U, 74U, 38U, 0.58),
    BOARD_Z + 1.0,
  )
  board_grid_lines.push(entity)
}

///|
fn spawn_house() -> Unit {
  let body = @entity.Entity::new()
  set_rect_entity(
    body,
    @math.Vec2D(HOUSE_X, BOARD_TOP + 72.0),
    @math.Vec2D(92.0, 230.0),
    rgba(136U, 77U, 63U, 1.0),
    BOARD_Z + 2.0,
  )
  house_entities.push(body)
  let roof = @entity.Entity::new()
  set_rect_entity(
    roof,
    @math.Vec2D(HOUSE_X - 8.0, BOARD_TOP + 20.0),
    @math.Vec2D(112.0, 48.0),
    rgba(169U, 93U, 78U, 1.0),
    BOARD_Z + 3.0,
  )
  house_entities.push(roof)
}

///|
fn spawn_overlay_bars() -> Unit {
  let bar_left = @entity.Entity::new()
  set_rect_entity(
    bar_left,
    @math.Vec2D(BOARD_LEFT - 20.0, BOARD_TOP - 18.0),
    @math.Vec2D(BOARD_RIGHT - BOARD_LEFT + 40.0, 18.0),
    rgba(31U, 55U, 35U, 1.0),
    BOARD_Z + 4.0,
  )
  plant_overlay_entities.push(bar_left)
}

///|
fn spawn_base_scene() -> Unit {
  clear_static_entities()

  for y in 0..<GRID_ROWS {
    for x in 0..<GRID_COLS {
      spawn_board_cell(x, y)
    }
  }

  for x in 0..<=GRID_COLS {
    let center_x = BOARD_LEFT + x.to_double() * CELL_SIZE
    spawn_board_grid_line(
      @math.Vec2D(center_x, BOARD_TOP + GRID_ROWS.to_double() * CELL_SIZE * 0.5),
      @math.Vec2D(4.0, GRID_ROWS.to_double() * CELL_SIZE),
    )
  }

  for y in 0..<=GRID_ROWS {
    spawn_board_grid_line(
      @math.Vec2D(
        BOARD_LEFT + GRID_COLS.to_double() * CELL_SIZE * 0.5,
        BOARD_TOP + y.to_double() * CELL_SIZE,
      ),
      @math.Vec2D(GRID_COLS.to_double() * CELL_SIZE, 4.0),
    )
  }

  spawn_house()
  spawn_overlay_bars()
}

///|
fn reset_game_state() -> Unit {
  clear_dynamic_entities()
  phase.val = Playing
  sun_points.val = START_SUN
  sun_spawn_timer.val = 0.0
  wave_state.val = { wave_index: 0, spawned_in_wave: 0, spawn_timer: 0.0 }
  hud_text_cache.val = ""
  hint_text_cache.val = ""
  result_text_cache.val = ""
  fps_text_cache.val = ""
}

///|
fn startup_texts() -> Unit {
  set_text_entity(
    title_entity,
    "PLANT VS ZOMBIES",
    @math.Vec2D(BOARD_LEFT, 20.0),
    TITLE_COLOR,
    size=30.0,
    z=HUD_Z,
  )
  set_text_entity(
    hud_entity,
    "",
    @math.Vec2D(BOARD_LEFT, 64.0),
    HUD_COLOR,
    size=18.0,
    z=HUD_Z,
  )
  set_text_entity(
    hint_entity,
    "",
    @math.Vec2D(BOARD_LEFT, 92.0),
    HUD_MUTED_COLOR,
    size=14.0,
    z=HUD_Z,
  )
  set_text_entity(
    result_entity,
    "",
    @math.Vec2D(VIEWPORT_WIDTH * 0.5 - 160.0, 250.0),
    RESULT_WIN_COLOR,
    size=44.0,
    z=OVERLAY_Z,
  )
  set_text_entity(
    fps_entity,
    "",
    @math.Vec2D(VIEWPORT_WIDTH - 130.0, 20.0),
    HUD_COLOR,
    size=20.0,
    z=HUD_Z,
  )
}

///|
fn setup_capture_state() -> Unit {
  capture_enabled.val = reloadable_capture_enabled()
  capture_started_at.val = @time.elapsed()
  capture_taken.val = false
}

///|
fn setup_profile_state() -> Unit {
  profile_enabled.val = env_flag_enabled(PVZ_PROFILE_ENV)
  profile_started_at.val = @time.elapsed()
  profile_last_report_at.val = profile_started_at.val
  profile_frame_count.val = 0
  profile_input_total.val = 0.0
  profile_render_total.val = 0.0
  profile_sim_total.val = 0.0
  profile_slowest_frame.val = 0.0
}

///|
fn setup_camera() -> Unit {
  ()
}

///|
pub fn startup_system(_world : @ecs.World) -> Unit {
  init_sound_bank()
  setup_capture_state()
  setup_profile_state()
  setup_camera()
  spawn_base_scene()
  startup_texts()
  reset_game_state()
  if profile_enabled.val {
    profile_started_at.val = @time.elapsed()
    profile_last_report_at.val = profile_started_at.val
    profile_frame_count.val = 0
    profile_input_total.val = 0.0
    profile_render_total.val = 0.0
    profile_sim_total.val = 0.0
    profile_slowest_frame.val = 0.0
  }
}

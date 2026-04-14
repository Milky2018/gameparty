///|
const VIEWPORT_WIDTH : Double = 960.0

///|
const VIEWPORT_HEIGHT : Double = 720.0

///|
const FPS : UInt = 60

///|
const FLOOR_SIZE : Double = 18.0

///|
const FLOOR_THICKNESS : Double = 0.12

///|
const PILLAR_SIZE : Double = 0.7

///|
const PILLAR_HEIGHT : Double = 2.2

///|
const PILLAR_OFFSET : Double = 3.0

///|
const LIGHT_HEIGHT : Double = 4.2

///|
const LIGHT_DOWNWARD : Double = 0.55

///|
const LIGHT_FORWARD : Double = 1.0

///|
const LIGHT_FORWARD_OFFSET : Double = 0.32

///|
const LIGHT_SPOT_RANGE : Double = 15.4

///|
const LIGHT_SPOT_INNER_ANGLE : Double = 0.45

///|
const LIGHT_SPOT_OUTER_ANGLE : Double = 2.52

///|
const CAPTURE_INTERVAL : Double = 0.45

///|
const STAGE_SELECTION_FILE : String = "spotrepro_stage.txt"

///|
const PI : Double = 3.141592653589793

///|
priv struct Stage {
  name : String
  yaw : Double
  forward : @math.Vec3
  shadows : Bool
}

///|
let stages : Array[Stage] = [
  {
    name: "north_noshadow",
    yaw: 0.0,
    forward: @math.Vec3::new(0.0, 0.0, -1.0),
    shadows: false,
  },
  {
    name: "south_noshadow",
    yaw: PI,
    forward: @math.Vec3::new(0.0, 0.0, 1.0),
    shadows: false,
  },
  {
    name: "west_noshadow",
    yaw: PI / 2.0,
    forward: @math.Vec3::new(-1.0, 0.0, 0.0),
    shadows: false,
  },
  {
    name: "east_noshadow",
    yaw: -PI / 2.0,
    forward: @math.Vec3::new(1.0, 0.0, 0.0),
    shadows: false,
  },
  {
    name: "north_shadow",
    yaw: 0.0,
    forward: @math.Vec3::new(0.0, 0.0, -1.0),
    shadows: true,
  },
  {
    name: "south_shadow",
    yaw: PI,
    forward: @math.Vec3::new(0.0, 0.0, 1.0),
    shadows: true,
  },
  {
    name: "west_shadow",
    yaw: PI / 2.0,
    forward: @math.Vec3::new(-1.0, 0.0, 0.0),
    shadows: true,
  },
  {
    name: "east_shadow",
    yaw: -PI / 2.0,
    forward: @math.Vec3::new(1.0, 0.0, 0.0),
    shadows: true,
  },
]

///|
let camera_entity : @entity.Entity = @entity.Entity::new()

///|
let light_entity : @entity.Entity = @entity.Entity::new()

///|
let label_entity : @entity.Entity = @entity.Entity::new()

///|
let floor_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let pillar_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let marker_mesh : Ref[@render3d.MeshHandle?] = { val: None }

///|
let floor_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let pillar_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let marker_material : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let scene_entities : Array[@entity.Entity] = []

///|
let selected_stage : Ref[Stage?] = { val: None }

///|
let stage_started_at : Ref[Double] = { val: 0.0 }

///|
let screenshot_taken : Ref[Bool] = { val: false }

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
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
  pillar_mesh.val = Some(
    @render3d.register_mesh_asset(
      @render3d.cube_mesh(
        @math.Vec3::new(PILLAR_SIZE, PILLAR_HEIGHT, PILLAR_SIZE),
      ),
    ),
  )
  marker_mesh.val = Some(
    @render3d.register_mesh_asset(@render3d.sphere_mesh(0.18)),
  )

  floor_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(212U, 212U, 218U, 1.0),
      roughness: 0.95,
    }),
  )
  pillar_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(160U, 160U, 168U, 1.0),
      roughness: 0.82,
    }),
  )
  marker_material.val = Some(
    @render3d.register_material_asset({
      ..@render3d.default_standard_material3d(),
      base_color: color_rgba(70U, 120U, 255U, 1.0),
      emissive_color: color_rgba(18U, 30U, 80U, 1.0),
      roughness: 0.25,
    }),
  )
}

///|
fn spawn_mesh(
  mesh : @render3d.MeshHandle,
  material : @render3d.MaterialHandle,
  translation : @math.Vec3,
) -> @entity.Entity {
  let entity = @entity.Entity::new()
  @transform.transforms().set(entity, {
    translation,
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  })
  @render3d.mesh3d_renderers().set(entity, {
    visible: true,
    mesh,
    material,
    cast_shadows: true,
    receive_shadows: true,
  })
  scene_entities.push(entity)
  entity
}

///|
fn setup_scene_geometry() -> Unit {
  let floor = floor_mesh.val.unwrap()
  let pillar = pillar_mesh.val.unwrap()
  let floor_mat = floor_material.val.unwrap()
  let pillar_mat = pillar_material.val.unwrap()
  let marker_mat = marker_material.val.unwrap()
  let marker = marker_mesh.val.unwrap()

  ignore(
    spawn_mesh(
      floor,
      floor_mat,
      @math.Vec3::new(0.0, -FLOOR_THICKNESS / 2.0, 0.0),
    ),
  )

  for
    position in [
      @math.Vec3::new(-PILLAR_OFFSET, PILLAR_HEIGHT / 2.0, 0.0),
      @math.Vec3::new(PILLAR_OFFSET, PILLAR_HEIGHT / 2.0, 0.0),
      @math.Vec3::new(0.0, PILLAR_HEIGHT / 2.0, -PILLAR_OFFSET),
      @math.Vec3::new(0.0, PILLAR_HEIGHT / 2.0, PILLAR_OFFSET),
    ] {
    ignore(spawn_mesh(pillar, pillar_mat, position))
  }

  ignore(
    spawn_mesh(marker, marker_mat, @math.Vec3::new(0.0, LIGHT_HEIGHT, 0.0)),
  )
}

///|
fn stage_for_name(name : String) -> Stage {
  for stage in stages {
    if stage.name == name {
      return stage
    }
  }
  stages[0]
}

///|
fn load_selected_stage() -> Stage {
  let name = @raylib.load_file_text(STAGE_SELECTION_FILE).trim().to_string()
  if name == "" {
    return stages[0]
  }
  stage_for_name(name)
}

///|
fn update_stage_visuals() -> Unit {
  let stage = selected_stage.val.unwrap()
  @transform.transforms().set(light_entity, {
    translation: @math.Vec3::new(
      stage.forward.x * LIGHT_FORWARD_OFFSET,
      LIGHT_HEIGHT,
      stage.forward.z * LIGHT_FORWARD_OFFSET,
    ),
    rotation: @math.Quat::from_axis_angle(
      @math.Vec3::new(0.0, 1.0, 0.0),
      stage.yaw,
    ),
    scale: @math.Vec3::one(),
  })
  @render3d.point_lights3d().remove(light_entity)
  @render3d.spot_lights3d().set(light_entity, {
    ..@render3d.default_spot_light3d(),
    direction: @math.Vec3::new(0.0, -LIGHT_DOWNWARD, -LIGHT_FORWARD).normalize(),
    color: color_rgba(48U, 96U, 255U, 1.0),
    intensity: 3.0,
    range: LIGHT_SPOT_RANGE,
    shadows: stage.shadows,
    inner_angle: LIGHT_SPOT_INNER_ANGLE,
    outer_angle: LIGHT_SPOT_OUTER_ANGLE,
  })
  @ui.texts().set(label_entity, @ui.Text::new("spot repro: \{stage.name}"))
  @ui.text_fonts().set(label_entity, @ui.TextFont::from_css("20px Arial"))
  @ui.text_colors().set(label_entity, @ui.TextColor::from_css("white"))
  @ui.text_layouts().set(
    label_entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(label_entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(
    label_entity,
    @sprite.Anchor(@math.Vec2(-0.5, 0.5)),
  )
  @transform.transforms().set(
    label_entity,
    transform_2d(@math.Vec2(12.0, 12.0), 400),
  )
  @visibility.visibilities().set(label_entity, Visible)
}

///|
fn capture_file_name(stage : Stage) -> String {
  "spotrepro_\{stage.name}.png"
}

///|
fn setup_camera() -> Unit {
  @camera3d.cameras3d().set(camera_entity, {
    ..@camera3d.Camera3DComponent::default(),
    projection: Orthographic,
    orthographic_size: Some(@math.Vec2(16.0, 16.0)),
    near: 0.01,
    far: 100.0,
    clear_color: color_rgba(5U, 6U, 10U, 1.0),
    order: 10,
    enabled: true,
  })
  @transform.transforms().set(camera_entity, {
    translation: @math.Vec3::new(0.0, 18.0, 0.0),
    rotation: @math.Quat::from_axis_angle(
      @math.Vec3::new(1.0, 0.0, 0.0),
      -1.5707963267948966,
    ),
    scale: @math.Vec3::one(),
  })
}

///|
fn startup_system(_world : @ecs.World) -> Unit {
  ensure_entity_alive(camera_entity)
  ensure_entity_alive(light_entity)
  ensure_entity_alive(label_entity)
  register_assets_once()
  setup_camera()
  setup_scene_geometry()
  @render3d.set_ambient_light3d(
    Some({ color: color_rgba(255U, 255U, 255U, 1.0), intensity: 0.01 }),
  )
  selected_stage.val = Some(load_selected_stage())
  stage_started_at.val = @time.elapsed()
  screenshot_taken.val = false
  update_stage_visuals()
}

///|
fn runtime_system(_world : @ecs.World) -> Unit {
  if screenshot_taken.val {
    return
  }
  if @time.elapsed() - stage_started_at.val >= CAPTURE_INTERVAL {
    let stage = selected_stage.val.unwrap()
    @raylib.take_screenshot(capture_file_name(stage))
    screenshot_taken.val = true
    @system.exit()
  }
}

///|
pub fn run() -> Unit {
  let app = @app.App::new()
    .with_viewport_width(VIEWPORT_WIDTH)
    .with_viewport_height(VIEWPORT_HEIGHT)
    .with_zoom(1.0)
    .with_fps(FPS)
    .with_image_smooth(true)
    .add_plugin(@plugins.default_3d_plugin)
    .add_system(Startup, startup_system)
    .add_system(Update, runtime_system)
  app.run()
}

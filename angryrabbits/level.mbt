///|
const DEFAULT_LEVEL_PATH : String = "angryrabbits/assets/levels/level_01.ldtk"

///|
priv struct DecorRectDef {
  position : @math.Vec2D
  size : @math.Vec2D
  color : String
  zindex : Int
}

///|
priv struct DecorCircleDef {
  center : @math.Vec2D
  radius : Double
  color : String
  zindex : Int
}

///|
priv struct BlockDef {
  center : @math.Vec2D
  size : @math.Vec2D
  color : String
}

///|
priv struct TargetDef {
  center : @math.Vec2D
  radius : Double
  color : String
}

///|
priv struct LevelDef {
  slingshot_anchor : @math.Vec2D
  rabbit_spawn : @math.Vec2D
  max_shots : Int
  background_rect : DecorRectDef
  ground_rect : DecorRectDef
  hill_circle : DecorCircleDef
  blocks : Array[BlockDef]
  targets : Array[TargetDef]
}

///|
fn default_level_def() -> LevelDef {
  {
    slingshot_anchor: @math.Vec2D(142.0, GROUND_Y - 88.0),
    rabbit_spawn: @math.Vec2D(142.0, GROUND_Y - 88.0),
    max_shots: MAX_SHOTS,
    background_rect: {
      position: @math.Vec2D::zero(),
      size: @math.Vec2D(VIEWPORT_WIDTH, VIEWPORT_HEIGHT),
      color: SKY_COLOR,
      zindex: 0,
    },
    ground_rect: {
      position: @math.Vec2D(0.0, GROUND_Y),
      size: @math.Vec2D(VIEWPORT_WIDTH, GROUND_HEIGHT),
      color: GROUND_COLOR,
      zindex: 2,
    },
    hill_circle: {
      center: @math.Vec2D(620.0, GROUND_Y),
      radius: 120.0,
      color: "rgb(154, 211, 132)",
      zindex: 1,
    },
    blocks: [
      {
        center: @math.Vec2D(486.0, GROUND_Y - 42.0),
        size: @math.Vec2D(28.0, 84.0),
        color: "rgb(191,132,78)",
      },
      {
        center: @math.Vec2D(544.0, GROUND_Y - 42.0),
        size: @math.Vec2D(28.0, 84.0),
        color: "rgb(169,115,67)",
      },
      {
        center: @math.Vec2D(604.0, GROUND_Y - 34.0),
        size: @math.Vec2D(32.0, 68.0),
        color: "rgb(208,148,88)",
      },
      {
        center: @math.Vec2D(646.0, GROUND_Y - 30.0),
        size: @math.Vec2D(22.0, 60.0),
        color: "rgb(160,107,65)",
      },
      {
        center: @math.Vec2D(570.0, GROUND_Y - 10.0),
        size: @math.Vec2D(132.0, 20.0),
        color: "rgb(221,171,108)",
      },
    ],
    targets: [
      {
        center: @math.Vec2D(446.0, GROUND_Y - TARGET_RADIUS - 4.0),
        radius: TARGET_RADIUS,
        color: "rgb(112, 209, 115)",
      },
      {
        center: @math.Vec2D(571.0, GROUND_Y - TARGET_RADIUS - 4.0),
        radius: TARGET_RADIUS,
        color: "rgb(112, 209, 115)",
      },
      {
        center: @math.Vec2D(632.0, GROUND_Y - TARGET_RADIUS - 4.0),
        radius: TARGET_RADIUS,
        color: "rgb(112, 209, 115)",
      },
    ],
  }
}

///|
fn load_current_level() -> LevelDef {
  load_level_from_path(current_level_path.val)
}

///|
fn load_level_from_path(path : String) -> LevelDef {
  let project = @ldtk.load_ldtk_project(path)
  if project.indexed_levels().is_empty() {
    return default_level_def()
  }
  level_def_from_ldtk_project(project)
}

///|
fn level_def_from_ldtk_project(project : @ldtk.LdtkProject) -> LevelDef {
  guard first_ldtk_level(project) is Some(level) else {
    return default_level_def()
  }
  let fallback = default_level_def()
  let slingshot_anchor : Ref[@math.Vec2D] = { val: fallback.slingshot_anchor }
  let rabbit_spawn : Ref[@math.Vec2D] = { val: fallback.rabbit_spawn }
  let background_rect : Ref[DecorRectDef] = { val: fallback.background_rect }
  let ground_rect : Ref[DecorRectDef] = { val: fallback.ground_rect }
  let hill_circle : Ref[DecorCircleDef] = { val: fallback.hill_circle }
  let max_shots : Ref[Int] = {
    val: level.field_int("max_shots").unwrap_or(fallback.max_shots),
  }
  let blocks : Array[BlockDef] = []
  let targets : Array[TargetDef] = []
  with_scoped_ldtk_entity_registrations_for_level(level.iid, fn() {
    @ldtk.add_ldtk_entity_registration("SlingshotAnchor", fn(event) {
      if event.layer.visible {
        slingshot_anchor.val = ldtk_entity_anchor(event.instance)
      }
    })
    @ldtk.add_ldtk_entity_registration("RabbitSpawn", fn(event) {
      if event.layer.visible {
        rabbit_spawn.val = ldtk_entity_anchor(event.instance)
      }
    })
    @ldtk.add_ldtk_entity_registration("BackgroundRect", fn(event) {
      if event.layer.visible {
        background_rect.val = decor_rect_def_from_ldtk_entity(
          event.instance,
          background_rect.val,
        )
      }
    })
    @ldtk.add_ldtk_entity_registration("GroundRect", fn(event) {
      if event.layer.visible {
        ground_rect.val = decor_rect_def_from_ldtk_entity(
          event.instance,
          ground_rect.val,
        )
      }
    })
    @ldtk.add_ldtk_entity_registration("HillCircle", fn(event) {
      if event.layer.visible {
        hill_circle.val = decor_circle_def_from_ldtk_entity(
          event.instance,
          hill_circle.val,
        )
      }
    })
    @ldtk.add_ldtk_entity_registration("Block", fn(event) {
      if event.layer.visible {
        blocks.push(block_def_from_ldtk_entity(event.instance))
      }
    })
    @ldtk.add_ldtk_entity_registration("Target", fn(event) {
      if event.layer.visible {
        targets.push(target_def_from_ldtk_entity(event.instance))
      }
    })
    let world_entity = @ldtk.spawn_ldtk_world(project)
    @ldtk.despawn_ldtk_tree(world_entity)
  })

  {
    slingshot_anchor: slingshot_anchor.val,
    rabbit_spawn: rabbit_spawn.val,
    max_shots: max_shots.val,
    background_rect: background_rect.val,
    ground_rect: ground_rect.val,
    hill_circle: hill_circle.val,
    blocks: if blocks.is_empty() {
      fallback.blocks
    } else {
      blocks
    },
    targets: if targets.is_empty() {
      fallback.targets
    } else {
      targets
    },
  }
}

///|
fn first_ldtk_level(project : @ldtk.LdtkProject) -> @ldtk.LdtkLevel? {
  let levels = project.indexed_levels()
  if levels.is_empty() {
    None
  } else {
    Some(levels[0].level)
  }
}

///|
fn with_scoped_ldtk_entity_registrations_for_level(
  level_iid : String,
  action : () -> Unit,
) -> Unit {
  let previous = @ldtk.ldtk_entity_typed_registrations.to_array()
  let previous_level_selection = @ldtk.ldtk_level_selection.val
  @ldtk.clear_ldtk_entity_registrations()
  @ldtk.set_ldtk_level_selection(@ldtk.ldtk_level_selection_iid(level_iid))
  action()
  @ldtk.clear_ldtk_entity_registrations()
  for entry in previous {
    @ldtk.ldtk_entity_typed_registrations.set(entry.0, entry.1)
  }
  @ldtk.set_ldtk_level_selection(previous_level_selection)
}

///|
fn ldtk_entity_anchor(entity : @ldtk.LdtkEntityInstance) -> @math.Vec2D {
  entity.px
}

///|
fn ldtk_entity_size(entity : @ldtk.LdtkEntityInstance) -> @math.Vec2D {
  @math.Vec2D(entity.width.to_double(), entity.height.to_double())
}

///|
fn ldtk_entity_center(entity : @ldtk.LdtkEntityInstance) -> @math.Vec2D {
  let size = ldtk_entity_size(entity)
  entity.px + @math.Vec2D(size[X] / 2.0, size[Y] / 2.0)
}

///|
fn ldtk_entity_string_field(
  entity : @ldtk.LdtkEntityInstance,
  field : String,
  fallback : String,
) -> String {
  match entity.field_string(field) {
    Some(value) => value
    None => entity.field_color(field).unwrap_or(fallback)
  }
}

///|
fn ldtk_entity_int_field(
  entity : @ldtk.LdtkEntityInstance,
  field : String,
  fallback : Int,
) -> Int {
  match entity.field_int(field) {
    Some(value) => value
    None =>
      entity.field_number(field).map_or(fallback, fn(value) { value.to_int() })
  }
}

///|
fn ldtk_entity_number_field(
  entity : @ldtk.LdtkEntityInstance,
  field : String,
  fallback : Double,
) -> Double {
  match entity.field_number(field) {
    Some(value) => value
    None =>
      entity.field_int(field).map_or(fallback, fn(value) { value.to_double() })
  }
}

///|
fn decor_rect_def_from_ldtk_entity(
  entity : @ldtk.LdtkEntityInstance,
  fallback : DecorRectDef,
) -> DecorRectDef {
  {
    position: entity.px,
    size: if entity.width > 0 && entity.height > 0 {
      ldtk_entity_size(entity)
    } else {
      fallback.size
    },
    color: ldtk_entity_string_field(entity, "color", fallback.color),
    zindex: ldtk_entity_int_field(entity, "zindex", fallback.zindex),
  }
}

///|
fn decor_circle_def_from_ldtk_entity(
  entity : @ldtk.LdtkEntityInstance,
  fallback : DecorCircleDef,
) -> DecorCircleDef {
  let radius = if entity.width > 0 && entity.height > 0 {
    let size = ldtk_entity_size(entity)
    let width_radius = size[X] / 2.0
    let height_radius = size[Y] / 2.0
    if width_radius < height_radius {
      width_radius
    } else {
      height_radius
    }
  } else {
    ldtk_entity_number_field(entity, "radius", fallback.radius)
  }
  {
    center: ldtk_entity_center(entity),
    radius,
    color: ldtk_entity_string_field(entity, "color", fallback.color),
    zindex: ldtk_entity_int_field(entity, "zindex", fallback.zindex),
  }
}

///|
fn block_def_from_ldtk_entity(entity : @ldtk.LdtkEntityInstance) -> BlockDef {
  {
    center: ldtk_entity_center(entity),
    size: ldtk_entity_size(entity),
    color: ldtk_entity_string_field(entity, "color", "rgb(191,132,78)"),
  }
}

///|
fn target_def_from_ldtk_entity(entity : @ldtk.LdtkEntityInstance) -> TargetDef {
  let size = ldtk_entity_size(entity)
  let radius = if entity.width > 0 && entity.height > 0 {
    let width_radius = size[X] / 2.0
    let height_radius = size[Y] / 2.0
    if width_radius < height_radius {
      width_radius
    } else {
      height_radius
    }
  } else {
    ldtk_entity_number_field(entity, "radius", TARGET_RADIUS)
  }
  {
    center: ldtk_entity_center(entity),
    radius,
    color: ldtk_entity_string_field(entity, "color", "rgb(112, 209, 115)"),
  }
}

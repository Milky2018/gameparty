///|
const DEFAULT_LEVEL_PATH : String = "angryrabbits/assets/levels/level_01.tmj"

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
  let map = @tiled.load_tiled_map(path)
  if map.layers.length() == 0 {
    return default_level_def()
  }
  level_def_from_tiled_map(map)
}

///|
fn level_def_from_tiled_map(map : @tiled.TiledMap) -> LevelDef {
  let fallback = default_level_def()
  let mut slingshot = fallback.slingshot_anchor
  let mut rabbit_spawn = fallback.rabbit_spawn
  let mut background_rect = fallback.background_rect
  let mut ground_rect = fallback.ground_rect
  let mut hill_circle = fallback.hill_circle
  let blocks : Array[BlockDef] = []
  let targets : Array[TargetDef] = []

  for layer in map.layers {
    match layer.kind {
      ObjectLayer(object_layer) =>
        for object in object_layer.objects {
          if !object.visible {
            continue
          }
          match object.object_type {
            "slingshot_anchor" => slingshot = tiled_object_anchor(object)
            "rabbit_spawn" => rabbit_spawn = tiled_object_anchor(object)
            "background_rect" =>
              background_rect = decor_rect_def_from_tiled_object(
                object, background_rect,
              )
            "ground_rect" =>
              ground_rect = decor_rect_def_from_tiled_object(
                object, ground_rect,
              )
            "hill_circle" =>
              hill_circle = decor_circle_def_from_tiled_object(
                object, hill_circle,
              )
            "block" => blocks.push(block_def_from_tiled_object(object))
            "target" => targets.push(target_def_from_tiled_object(object))
            _ => ()
          }
        }
      _ => ()
    }
  }

  {
    slingshot_anchor: slingshot,
    rabbit_spawn,
    max_shots: tiled_property_int(map.property("max_shots"), fallback.max_shots),
    background_rect,
    ground_rect,
    hill_circle,
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
fn tiled_object_anchor(object : @tiled.TiledObject) -> @math.Vec2D {
  if object.point {
    return @math.Vec2D(object.x, object.y)
  }
  @math.Vec2D(object.x + object.width / 2.0, object.y + object.height / 2.0)
}

///|
fn tiled_object_center(object : @tiled.TiledObject) -> @math.Vec2D {
  @math.Vec2D(object.x + object.width / 2.0, object.y + object.height / 2.0)
}

///|
fn tiled_property_string(
  property : @tiled.TiledPropertyValue?,
  fallback : String,
) -> String {
  match property {
    Some(String(value)) => value
    Some(Color(value)) => value
    Some(File(value)) => value
    _ => fallback
  }
}

///|
fn tiled_property_double(
  property : @tiled.TiledPropertyValue?,
  fallback : Double,
) -> Double {
  match property {
    Some(Float(value)) => value
    Some(Int(value)) => value.to_double()
    _ => fallback
  }
}

///|
fn tiled_property_int(
  property : @tiled.TiledPropertyValue?,
  fallback : Int,
) -> Int {
  match property {
    Some(Int(value)) => value
    Some(Float(value)) => value.to_int()
    _ => fallback
  }
}

///|
fn decor_rect_def_from_tiled_object(
  object : @tiled.TiledObject,
  fallback : DecorRectDef,
) -> DecorRectDef {
  {
    position: @math.Vec2D(object.x, object.y),
    size: if object.width > 0.0 && object.height > 0.0 {
      @math.Vec2D(object.width, object.height)
    } else {
      fallback.size
    },
    color: tiled_property_string(object.property("color"), fallback.color),
    zindex: tiled_property_int(object.property("zindex"), fallback.zindex),
  }
}

///|
fn decor_circle_def_from_tiled_object(
  object : @tiled.TiledObject,
  fallback : DecorCircleDef,
) -> DecorCircleDef {
  let radius = if object.width > 0.0 && object.height > 0.0 {
    let width_radius = object.width / 2.0
    let height_radius = object.height / 2.0
    if width_radius < height_radius {
      width_radius
    } else {
      height_radius
    }
  } else {
    tiled_property_double(object.property("radius"), fallback.radius)
  }
  {
    center: if object.point {
      tiled_object_anchor(object)
    } else {
      tiled_object_center(object)
    },
    radius,
    color: tiled_property_string(object.property("color"), fallback.color),
    zindex: tiled_property_int(object.property("zindex"), fallback.zindex),
  }
}

///|
fn block_def_from_tiled_object(object : @tiled.TiledObject) -> BlockDef {
  {
    center: tiled_object_center(object),
    size: @math.Vec2D(object.width, object.height),
    color: tiled_property_string(object.property("color"), "rgb(191,132,78)"),
  }
}

///|
fn target_def_from_tiled_object(object : @tiled.TiledObject) -> TargetDef {
  let radius = if object.width > 0.0 && object.height > 0.0 {
    let width_radius = object.width / 2.0
    let height_radius = object.height / 2.0
    if width_radius < height_radius {
      width_radius
    } else {
      height_radius
    }
  } else {
    tiled_property_double(object.property("radius"), TARGET_RADIUS)
  }
  {
    center: if object.point {
      tiled_object_anchor(object)
    } else {
      tiled_object_center(object)
    },
    radius,
    color: tiled_property_string(object.property("color"), "rgb(112, 209, 115)"),
  }
}

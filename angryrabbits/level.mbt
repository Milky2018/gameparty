///|
const DEFAULT_LEVEL_PATH : String = "assets/angryrabbits/levels/level_01.ldtk"

///|
const LDTK_ENTITIES_LAYER : String = "Entities"

///|
const LDTK_DECOR_LAYER : String = "Decor"

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
}

///|
priv struct TargetDef {
  center : @math.Vec2D
  radius : Double
}

///|
priv struct LevelDef {
  slingshot_anchor : @math.Vec2D
  slingshot_front_stick : @math.Vec2D
  slingshot_back_stick : @math.Vec2D
  rabbit_spawn : @math.Vec2D
  max_shots : Int
  background_rect : DecorRectDef
  ground_rect : DecorRectDef
  hill_circle : DecorCircleDef
  blocks : Array[BlockDef]
  targets : Array[TargetDef]
}

///|
priv enum LoadResult[T] {
  Ok(T)
  Err(String)
}

///|
fn[T] load_level_error(path : String, detail : String) -> LoadResult[T] {
  Err("Angry Rabbits level load failed for '\{path}': \{detail}")
}

///|
fn load_current_level() -> LoadResult[LevelDef] {
  load_level_from_path(current_level_path.val)
}

///|
fn load_level_from_path(path : String) -> LoadResult[LevelDef] {
  match load_ldtk_project_from_utf8_asset(path) {
    Ok(project) =>
      if project.indexed_levels().is_empty() {
        load_level_error(
          path, "no LDtk levels were loaded. Check that the file exists at runtime and that the working directory matches the project root.",
        )
      } else {
        level_def_from_ldtk_project(project, path)
      }
    Err(message) => Err(message)
  }
}

///|
fn level_def_from_ldtk_project(
  project : @ldtk.LdtkProject,
  path : String,
) -> LoadResult[LevelDef] {
  guard first_ldtk_level(project) is Some(level) else {
    return load_level_error(path, "the project has no selectable level.")
  }
  if !has_visible_entities_layer(level) {
    return load_level_error(
      path,
      "level '\{level.identifier}' has no visible 'Entities' layer.",
    )
  }
  let slingshot_anchor : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }
  let has_slingshot_anchor : Ref[Bool] = { val: false }
  let slingshot_front_stick : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }
  let has_slingshot_front_stick : Ref[Bool] = { val: false }
  let slingshot_back_stick : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }
  let has_slingshot_back_stick : Ref[Bool] = { val: false }
  let rabbit_spawn : Ref[@math.Vec2D] = { val: @math.Vec2D::zero() }
  let has_rabbit_spawn : Ref[Bool] = { val: false }
  let background_rect : Ref[DecorRectDef] = {
    val: {
      position: @math.Vec2D::zero(),
      size: @math.Vec2D::zero(),
      color: "",
      zindex: 0,
    },
  }
  let has_background_rect : Ref[Bool] = { val: false }
  let ground_rect : Ref[DecorRectDef] = {
    val: {
      position: @math.Vec2D::zero(),
      size: @math.Vec2D::zero(),
      color: "",
      zindex: 0,
    },
  }
  let has_ground_rect : Ref[Bool] = { val: false }
  let hill_circle : Ref[DecorCircleDef] = {
    val: { center: @math.Vec2D::zero(), radius: 0.0, color: "", zindex: 0 },
  }
  let has_hill_circle : Ref[Bool] = { val: false }
  let load_failure : Ref[String?] = { val: None }
  guard level.field_int("max_shots") is Some(max_shots) else {
    return load_level_error(
      path,
      "level '\{level.identifier}' is missing required level field max_shots.",
    )
  }
  let blocks : Array[BlockDef] = []
  let targets : Array[TargetDef] = []
  with_scoped_ldtk_entity_registrations_for_level(level.iid, fn() {
    @ldtk.add_ldtk_entity_registration_for_layer(
      LDTK_ENTITIES_LAYER,
      "SlingshotAnchor",
      fn(event) {
        if event.layer.visible {
          slingshot_anchor.val = ldtk_entity_anchor(event.instance)
          has_slingshot_anchor.val = true
        }
      },
    )
    @ldtk.add_ldtk_entity_registration_for_layer(
      LDTK_ENTITIES_LAYER,
      "SlingshotFrontStick",
      fn(event) {
        if event.layer.visible {
          slingshot_front_stick.val = ldtk_entity_anchor(event.instance)
          has_slingshot_front_stick.val = true
        }
      },
    )
    @ldtk.add_ldtk_entity_registration_for_layer(
      LDTK_ENTITIES_LAYER,
      "SlingshotBackStick",
      fn(event) {
        if event.layer.visible {
          slingshot_back_stick.val = ldtk_entity_anchor(event.instance)
          has_slingshot_back_stick.val = true
        }
      },
    )
    @ldtk.add_ldtk_entity_registration_for_layer(
      LDTK_ENTITIES_LAYER,
      "RabbitSpawn",
      fn(event) {
        if event.layer.visible {
          rabbit_spawn.val = ldtk_entity_anchor(event.instance)
          has_rabbit_spawn.val = true
        }
      },
    )
    @ldtk.add_ldtk_entity_registration_for_layer(
      LDTK_DECOR_LAYER,
      "BackgroundRect",
      fn(event) {
        if event.layer.visible {
          match decor_rect_def_from_ldtk_entity(event.instance, path) {
            Ok(rect) => {
              background_rect.val = rect
              has_background_rect.val = true
            }
            Err(message) =>
              if load_failure.val is None {
                load_failure.val = Some(message)
              }
          }
        }
      },
    )
    @ldtk.add_ldtk_entity_registration_for_layer(
      LDTK_DECOR_LAYER,
      "GroundRect",
      fn(event) {
        if event.layer.visible {
          match decor_rect_def_from_ldtk_entity(event.instance, path) {
            Ok(rect) => {
              ground_rect.val = rect
              has_ground_rect.val = true
            }
            Err(message) =>
              if load_failure.val is None {
                load_failure.val = Some(message)
              }
          }
        }
      },
    )
    @ldtk.add_ldtk_entity_registration_for_layer(
      LDTK_DECOR_LAYER,
      "HillCircle",
      fn(event) {
        if event.layer.visible {
          match decor_circle_def_from_ldtk_entity(event.instance, path) {
            Ok(circle) => {
              hill_circle.val = circle
              has_hill_circle.val = true
            }
            Err(message) =>
              if load_failure.val is None {
                load_failure.val = Some(message)
              }
          }
        }
      },
    )
    @ldtk.add_ldtk_entity_registration_for_layer(LDTK_ENTITIES_LAYER, "Block", fn(
      event,
    ) {
      if event.layer.visible {
        match block_def_from_ldtk_entity(event.instance, path) {
          Ok(block) => blocks.push(block)
          Err(message) =>
            if load_failure.val is None {
              load_failure.val = Some(message)
            }
        }
      }
    })
    @ldtk.add_ldtk_entity_registration_for_layer(
      LDTK_ENTITIES_LAYER,
      "Target",
      fn(event) {
        if event.layer.visible {
          match target_def_from_ldtk_entity(event.instance, path) {
            Ok(target) => targets.push(target)
            Err(message) =>
              if load_failure.val is None {
                load_failure.val = Some(message)
              }
          }
        }
      },
    )
    let world_entity = @ldtk.spawn_ldtk_world(project)
    @ldtk.despawn_ldtk_tree(world_entity)
  })
  guard load_failure.val is None else { return Err(load_failure.val.unwrap()) }
  let missing : Array[String] = []
  if !has_slingshot_anchor.val {
    missing.push("SlingshotAnchor")
  }
  if !has_slingshot_front_stick.val {
    missing.push("SlingshotFrontStick")
  }
  if !has_slingshot_back_stick.val {
    missing.push("SlingshotBackStick")
  }
  if !has_rabbit_spawn.val {
    missing.push("RabbitSpawn")
  }
  if !has_background_rect.val {
    missing.push("BackgroundRect")
  }
  if !has_ground_rect.val {
    missing.push("GroundRect")
  }
  if !has_hill_circle.val {
    missing.push("HillCircle")
  }
  if !missing.is_empty() {
    return load_level_error(
      path,
      "level '\{level.identifier}' is missing required entities \{missing}.",
    )
  }

  Ok({
    slingshot_anchor: slingshot_anchor.val,
    slingshot_front_stick: slingshot_front_stick.val,
    slingshot_back_stick: slingshot_back_stick.val,
    rabbit_spawn: rabbit_spawn.val,
    max_shots,
    background_rect: background_rect.val,
    ground_rect: ground_rect.val,
    hill_circle: hill_circle.val,
    blocks,
    targets,
  })
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
fn has_visible_entities_layer(level : @ldtk.LdtkLevel) -> Bool {
  for layer in level.layer_instances {
    if layer.identifier == LDTK_ENTITIES_LAYER && layer.visible {
      return true
    }
  }
  false
}

///|
fn load_ldtk_project_from_utf8_asset(
  path : String,
) -> LoadResult[@ldtk.LdtkProject] {
  guard @asset.read_bytes(path) is Some(bytes) else {
    return load_level_error(path, "asset bytes could not be read.")
  }
  let source = @utf8.decode(bytes, ignore_bom=true) catch {
    _ => return load_level_error(path, "file is not valid UTF-8 text.")
  }
  let root_json = @json.parse(source.view()) catch {
    err => return load_level_error(path, "JSON parse error \{err}.")
  }
  let project = @ldtk.LdtkProject::from_ldtk_json(root_json)
  if project.external_levels {
    return load_level_error(
      path, "LDtk external levels are not supported by the local UTF-8 fallback loader. Disable LDtk external levels for this project.",
    )
  }
  Ok(project)
}

///|
fn with_scoped_ldtk_entity_registrations_for_level(
  level_iid : String,
  action : () -> Unit,
) -> Unit {
  let previous = @ldtk.ldtk_entity_typed_registrations().to_array()
  let previous_level_selection = @ldtk.ldtk_level_selection.val
  @ldtk.clear_ldtk_entity_registrations()
  @ldtk.set_ldtk_level_selection(@ldtk.ldtk_level_selection_iid(level_iid))
  action()
  @ldtk.clear_ldtk_entity_registrations()
  for entry in previous {
    @ldtk.ldtk_entity_typed_registrations().set(entry.0, entry.1)
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
fn[T] load_level_entity_error(
  path : String,
  entity : @ldtk.LdtkEntityInstance,
  detail : String,
) -> LoadResult[T] {
  load_level_error(
    path,
    "entity '\{entity.identifier}' (\{entity.iid}) \{detail}",
  )
}

///|
fn required_ldtk_entity_size(
  entity : @ldtk.LdtkEntityInstance,
  path : String,
) -> LoadResult[@math.Vec2D] {
  if entity.width <= 0 || entity.height <= 0 {
    load_level_entity_error(
      path, entity, "must have positive width and height.",
    )
  } else {
    Ok(ldtk_entity_size(entity))
  }
}

///|
fn required_ldtk_entity_string_field(
  entity : @ldtk.LdtkEntityInstance,
  path : String,
  field : String,
) -> LoadResult[String] {
  match entity.field_string(field) {
    Some(value) => Ok(value)
    None =>
      load_level_entity_error(
        path,
        entity,
        "is missing required String field '\{field}'.",
      )
  }
}

///|
fn required_ldtk_entity_int_field(
  entity : @ldtk.LdtkEntityInstance,
  path : String,
  field : String,
) -> LoadResult[Int] {
  match entity.field_int(field) {
    Some(value) => Ok(value)
    None =>
      load_level_entity_error(
        path,
        entity,
        "is missing required Int field '\{field}'.",
      )
  }
}

///|
fn decor_rect_def_from_ldtk_entity(
  entity : @ldtk.LdtkEntityInstance,
  path : String,
) -> LoadResult[DecorRectDef] {
  match required_ldtk_entity_size(entity, path) {
    Err(message) => Err(message)
    Ok(size) =>
      match required_ldtk_entity_string_field(entity, path, "color") {
        Err(message) => Err(message)
        Ok(color) =>
          match required_ldtk_entity_int_field(entity, path, "zindex") {
            Err(message) => Err(message)
            Ok(zindex) => Ok({ position: entity.px, size, color, zindex })
          }
      }
  }
}

///|
fn decor_circle_def_from_ldtk_entity(
  entity : @ldtk.LdtkEntityInstance,
  path : String,
) -> LoadResult[DecorCircleDef] {
  match required_ldtk_entity_size(entity, path) {
    Err(message) => Err(message)
    Ok(size) =>
      match required_ldtk_entity_string_field(entity, path, "color") {
        Err(message) => Err(message)
        Ok(color) =>
          match required_ldtk_entity_int_field(entity, path, "zindex") {
            Err(message) => Err(message)
            Ok(zindex) => {
              let width_radius = size[X] / 2.0
              let height_radius = size[Y] / 2.0
              let radius = if width_radius < height_radius {
                width_radius
              } else {
                height_radius
              }
              Ok({ center: ldtk_entity_center(entity), radius, color, zindex })
            }
          }
      }
  }
}

///|
fn block_def_from_ldtk_entity(
  entity : @ldtk.LdtkEntityInstance,
  path : String,
) -> LoadResult[BlockDef] {
  match required_ldtk_entity_size(entity, path) {
    Err(message) => Err(message)
    Ok(size) => Ok({ center: ldtk_entity_center(entity), size })
  }
}

///|
fn target_def_from_ldtk_entity(
  entity : @ldtk.LdtkEntityInstance,
  path : String,
) -> LoadResult[TargetDef] {
  match required_ldtk_entity_size(entity, path) {
    Err(message) => Err(message)
    Ok(size) => {
      let width_radius = size[X] / 2.0
      let height_radius = size[Y] / 2.0
      let radius = if width_radius < height_radius {
        width_radius
      } else {
        height_radius
      }
      Ok({ center: ldtk_entity_center(entity), radius })
    }
  }
}

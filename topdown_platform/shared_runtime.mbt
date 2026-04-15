///|
pub(all) struct WorldTileVisualPlan {
  center : @math.Vec2
  floor_image : ImageVisualDef
  prop_image : ImageVisualDef?
}

///|
pub(all) struct WorldMapLayout {
  tile_size : Double
  rows : Int
  cols : Int
  world_width : Double
  world_height : Double
  player_spawn : @math.Vec2
  actor_spawns : Array[ActorSpawnPoint]
  blocking_rects : Array[@math.Rect]
  tiles : Array[WorldTileVisualPlan]
}

///|
pub fn resolve_asset_path(path : String, prefixes : Array[String]) -> String {
  for prefix in prefixes {
    let candidate = "\{prefix}\{path}"
    if @asset.read_bytes(candidate) is Some(_) {
      return candidate
    }
  }
  path
}

///|
pub fn load_cached_image(
  path : String,
  prefixes : Array[String],
  cache : Map[String, @asset.ImageHandle],
) -> @asset.ImageHandle {
  let key = resolve_asset_path(path, prefixes)
  match cache.get(key) {
    Some(handle) => handle
    None => {
      let handle = @asset.load_image(key)
      cache.set(key, handle)
      handle
    }
  }
}

///|
pub fn apply_text_entity(
  entity : @entity.Entity,
  text : String,
  x : Double,
  y : Double,
  z : Double,
  color_css : String,
  size : Int,
  font_family : String,
) -> Unit {
  @ui.texts().set(entity, @ui.Text::new(text))
  @ui.text_fonts().set(
    entity,
    @ui.TextFont::from_css("\{size}px \{font_family}"),
  )
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color_css))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(-0.5, 0.5)))
  @transform.transforms().set(entity, transform_xy(x, y, z))
  set_entity_visible(entity, true)
}

///|
pub fn apply_world_background(
  entity : @entity.Entity,
  width : Double,
  height : Double,
  color : @render.Color,
) -> Unit {
  let sprite = @sprite.Sprite::from_color(color, @math.Vec2(width, height))
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_xy(0.0, 0.0, 0.0))
  set_entity_visible(entity, true)
}

///|
pub fn apply_image_sprite_entity(
  entity : @entity.Entity,
  visual : ImageVisualDef,
  center : @math.Vec2,
  base_size : Double,
  z : Double,
  prefixes : Array[String],
  cache : Map[String, @asset.ImageHandle],
) -> Unit {
  let size = base_size * visual.scale
  let sprite = @sprite.Sprite::from_image(
    load_cached_image(visual.path, prefixes, cache),
    custom_size=Some(@math.Vec2(size, size)),
  )
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    transform_xy(
      center[X] - size * 0.5,
      center[Y] - size * 0.5 + visual.y_offset,
      z,
    ),
  )
  set_entity_visible(entity, true)
}

///|
pub fn build_world_map_layout(
  map : MapDef,
  wall_padding : Double,
) -> WorldMapLayout {
  let rows = map.rows.length()
  let cols = map.rows[0].length()
  let tile_size = map.tile_size
  let world_width = cols.to_double() * tile_size
  let world_height = rows.to_double() * tile_size
  let mut player_spawn = @math.Vec2(tile_size * 0.5, tile_size * 0.5)
  let actor_spawns : Array[ActorSpawnPoint] = []
  let blocking_rects : Array[@math.Rect] = []
  let tiles : Array[WorldTileVisualPlan] = []

  for row = 0; row < rows; row = row + 1 {
    let line = map.rows[row]
    for col = 0; col < cols; col = col + 1 {
      let code = line.unsafe_get(col).unsafe_to_char()
      let rule = map.legend.get(code).unwrap()
      let center = @math.Vec2(
        (col.to_double() + 0.5) * tile_size,
        (row.to_double() + 0.5) * tile_size,
      )
      let floor_image = match rule.floor_image {
        Some(visual) => visual
        None => map.default_floor_image
      }
      tiles.push({ center, floor_image, prop_image: rule.prop_image })
      if rule.blocks || rule.kind == Wall {
        blocking_rects.push({
          position: @math.Vec2(
            col.to_double() * tile_size + wall_padding,
            row.to_double() * tile_size + wall_padding,
          ),
          size: @math.Vec2(
            tile_size - wall_padding * 2.0,
            tile_size - wall_padding * 2.0,
          ),
        })
      }
      match rule.kind {
        PlayerSpawn => player_spawn = center
        ActorSpawn =>
          actor_spawns.push({ position: center, tag: rule.actor_spawn_tag })
        _ => ()
      }
    }
  }

  {
    tile_size,
    rows,
    cols,
    world_width,
    world_height,
    player_spawn,
    actor_spawns,
    blocking_rects,
    tiles,
  }
}

///|
pub fn sprite_anim_for_facing(
  sprites : DirectionalSprites,
  facing : Facing,
) -> SpriteAnimDef {
  match facing {
    Up => sprites.up
    Down => sprites.down
    Left => sprites.left
    Right => sprites.right
  }
}

///|
pub fn actor_frame_index(
  moving : Bool,
  anim_elapsed : Double,
  anim : SpriteAnimDef,
) -> Int {
  if !moving || anim.frame_count <= 1 {
    0
  } else {
    let count = anim.frame_count.max(1)
    (anim_elapsed * anim.fps).to_int() % count
  }
}

///|
pub fn anim_frame_rect(anim : SpriteAnimDef, frame_index : Int) -> @math.Rect {
  let columns = anim.columns.max(1)
  let col = frame_index % columns
  let row = frame_index / columns
  {
    position: @math.Vec2(
      col.to_double() * anim.frame_width,
      row.to_double() * anim.frame_height,
    ),
    size: @math.Vec2(anim.frame_width, anim.frame_height),
  }
}

///|
pub fn move_circle_with_collision(
  center : @math.Vec2,
  radius : Double,
  delta : @math.Vec2,
  blocking_rects : Array[@math.Rect],
  world_width : Double,
  world_height : Double,
) -> @math.Vec2 {
  let mut next = center

  let trial_x = @math.Vec2(next[X] + delta[X], next[Y])
  let mut blocked_x = false
  for rect in blocking_rects {
    if rect_intersects_circle(rect, trial_x, radius) {
      blocked_x = true
      break
    }
  }
  if !blocked_x {
    next = @math.Vec2(trial_x[X], next[Y])
  }

  let trial_y = @math.Vec2(next[X], next[Y] + delta[Y])
  let mut blocked_y = false
  for rect in blocking_rects {
    if rect_intersects_circle(rect, trial_y, radius) {
      blocked_y = true
      break
    }
  }
  if !blocked_y {
    next = @math.Vec2(next[X], trial_y[Y])
  }

  @math.Vec2(
    clamp_double(next[X], radius, world_width - radius),
    clamp_double(next[Y], radius, world_height - radius),
  )
}

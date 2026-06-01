///|
fn transform_xy(x : Double, y : Double, z : Double) -> @transform.Transform {
  @transform.Transform::from_xyz(x, y, z)
}

///|
fn top_left_anchor() -> @sprite.Anchor {
  @sprite.Anchor(@math.Vec2(-0.5, 0.5))
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn set_entity_visible(entity : @entity.Entity, visible : Bool) -> Unit {
  ensure_entity_alive(entity)
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn hide_entity(entity : @entity.Entity) -> Unit {
  set_entity_visible(entity, false)
}

///|
fn panel_entity(
  entity : @entity.Entity,
  color : String,
  center : @math.Vec2,
  size : @math.Vec2,
  z : Double,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_color(@sprite.color_from_css(color), size)
  sprite.anchor = top_left_anchor()
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    transform_xy(center[X] - size[X] * 0.5, center[Y] - size[Y] * 0.5, z),
  )
  set_entity_visible(entity, true)
}

///|
fn set_text_entity_center(
  entity : @entity.Entity,
  text : String,
  center : @math.Vec2,
  width : Double,
  height : Double,
  size_px : Int,
  color : String,
  z : Double,
) -> Unit {
  ensure_entity_alive(entity)
  @ui.texts().set(entity, @ui.Text::Text(text))
  @ui.text_fonts().set(
    entity,
    @ui.TextFont::TextFont(family=FONT_FAMILY, size=size_px.to_double()),
  )
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::TextLayout(align=Center, baseline=Center, wrap=NoWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::Text2d())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(0.0, 0.0)))
  @text2d.text_bounds().set(
    entity,
    @text2d.TextBounds::TextBounds(width, height),
  )
  @transform.transforms().set(entity, transform_xy(center[X], center[Y], z))
  set_entity_visible(entity, true)
}

///|
fn update_text_if_changed(
  entity : @entity.Entity,
  cache : Ref[String],
  text : String,
) -> Unit {
  if cache.val == text {
    return
  }
  @ui.texts().set(entity, @ui.Text::Text(text))
  cache.val = text
}

///|
fn set_sprite_entity(
  entity : @entity.Entity,
  image : @asset.ImageHandle,
  center : @math.Vec2,
  size : @math.Vec2,
  z : Double,
  rect? : @math.Rect? = None,
  tint_css? : String? = None,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_image(image, custom_size=Some(size))
  sprite.anchor = top_left_anchor()
  sprite.rect = rect
  match tint_css {
    Some(color) => sprite.color = @sprite.color_from_css(color)
    None => ()
  }
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    transform_xy(center[X] - size[X] * 0.5, center[Y] - size[Y] * 0.5, z),
  )
  set_entity_visible(entity, true)
}

///|
fn atlas_rect(
  cell_width : Double,
  cell_height : Double,
  columns : Int,
  index : Int,
) -> @math.Rect {
  let col = index % columns
  let row = index / columns
  {
    position: @math.Vec2(
      col.to_double() * cell_width,
      row.to_double() * cell_height,
    ),
    size: @math.Vec2(cell_width, cell_height),
  }
}

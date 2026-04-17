///|
fn color_rgba(r : UInt, g : UInt, b : UInt, a : Double) -> @render.Color {
  { r, g, b, a }
}

///|
fn set_entity_visible(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn transform_xy(x : Double, y : Double, z : Double) -> @transform.Transform {
  @transform.Transform::from_xyz(x, y, z)
}

///|
fn centered_text_entity(
  entity : @entity.Entity,
  content : String,
  center_x : Double,
  center_y : Double,
  width : Double,
  height : Double,
  size_px : Int,
  color_css : String,
  z : Double,
) -> Unit {
  @ui.texts().set(entity, @ui.Text::new(content))
  @ui.text_fonts().set(
    entity,
    @ui.TextFont::new(family="monospace", size=size_px.to_double()),
  )
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color_css))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Center, baseline=Center, wrap=NoWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(0.0, 0.0)))
  @text2d.text_bounds().set(entity, @text2d.TextBounds::new(width, height))
  @transform.transforms().set(entity, transform_xy(center_x, center_y, z))
  set_entity_visible(entity, true)
}

///|
fn panel_entity(
  entity : @entity.Entity,
  color : @render.Color,
  center_x : Double,
  center_y : Double,
  width : Double,
  height : Double,
  z : Double,
) -> Unit {
  let sprite = @sprite.Sprite::from_color(color, @math.Vec2(width, height))
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(
    entity,
    transform_xy(center_x - width * 0.5, center_y - height * 0.5, z),
  )
  set_entity_visible(entity, true)
}

///|
fn point_in_rect(x : Double, y : Double, rect : ButtonRect) -> Bool {
  x >= rect.left &&
  x <= rect.left + rect.width &&
  y >= rect.top &&
  y <= rect.top + rect.height
}

///|
fn rects_overlap(a : ButtonRect, b : ButtonRect) -> Bool {
  a.left < b.left + b.width &&
  a.left + a.width > b.left &&
  a.top < b.top + b.height &&
  a.top + a.height > b.top
}

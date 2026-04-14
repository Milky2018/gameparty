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
fn text_entity(
  entity : @entity.Entity,
  content : String,
  x : Double,
  y : Double,
  size_px : Int,
  color_css : String,
  z : Double,
) -> Unit {
  @ui.texts().set(entity, @ui.Text::new(content))
  @ui.text_fonts().set(
    entity,
    @ui.TextFont::from_css("\{size_px}px \{BEJEWELED_FONT_FAMILY}"),
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
fn set_centered_text_block(
  entity : @entity.Entity,
  width : Double,
  height : Double,
) -> Unit {
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2(0.0, 0.0)))
  @text2d.text_bounds().set(entity, @text2d.TextBounds::new(width, height))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Center, baseline=Center, wrap=WordWrap),
  )
}

///|
fn status_box_center_x(slot : Int) -> Double {
  let timer_center_x = VIEWPORT_WIDTH -
    STATUS_BOX_MARGIN_RIGHT -
    STATUS_BOX_WIDTH * 0.5
  timer_center_x - slot.to_double() * (STATUS_BOX_WIDTH + STATUS_BOX_GAP)
}

///|
fn panel_entity(
  entity : @entity.Entity,
  color : @render.Color,
  x : Double,
  y : Double,
  w : Double,
  h : Double,
  z : Double,
) -> Unit {
  let sprite = @sprite.Sprite::from_color(color, @math.Vec2(w, h))
  sprite.anchor = @sprite.Anchor(@math.Vec2(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_xy(x - w * 0.5, y - h * 0.5, z))
  set_entity_visible(entity, true)
}

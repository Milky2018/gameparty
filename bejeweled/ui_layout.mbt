///|
fn setup_flash_legend_icon(
  entity : @entity.Entity,
  aura_entity : @entity.Entity,
  kind : GemKind,
  center_x : Double,
  center_y : Double,
) -> Unit {
  let center = @math.Vec2D(center_x, center_y)
  let size_value = CELL_SIZE * 0.72
  let size = @math.Vec2D(size_value, size_value)
  let top_left = @math.Vec2D(
    center[X] - size[X] * 0.5,
    center[Y] - size[Y] * 0.5,
  )
  let gem_sprite = @sprite.Sprite::from_image(
    gem_image(kind),
    custom_size=Some(size),
  )
  gem_sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(entity, gem_sprite)
  @transform.transforms().set(
    entity,
    transform_xy(top_left[X], top_left[Y], 112.0),
  )
  set_entity_visible(entity, true)

  let aura_virtual_size_value = size_value * FLASH_AURA_SCALE
  let aura_clip_size_value = CELL_SIZE - BOARD_GAP * FLASH_AURA_CLIP_GAP_FACTOR
  let aura_size = @math.Vec2D(aura_clip_size_value, aura_clip_size_value)
  let aura_top_left = @math.Vec2D(
    center[X] - aura_size[X] * 0.5,
    center[Y] - aura_size[Y] * 0.5,
  )
  let clip_ratio_unclamped = aura_clip_size_value / aura_virtual_size_value
  let clip_ratio = if clip_ratio_unclamped >= 1.0 {
    1.0
  } else if clip_ratio_unclamped <= 0.01 {
    0.01
  } else {
    clip_ratio_unclamped
  }
  let source_size = gem_image_size(kind)
  let source_clip_size = @math.Vec2D(
    source_size[X] * clip_ratio,
    source_size[Y] * clip_ratio,
  )
  let source_clip_pos = @math.Vec2D(
    (source_size[X] - source_clip_size[X]) * 0.5,
    (source_size[Y] - source_clip_size[Y]) * 0.5,
  )
  let aura_sprite = @sprite.Sprite::from_image(
    gem_image(kind),
    custom_size=Some(aura_size),
  )
  aura_sprite.rect = Some({ position: source_clip_pos, size: source_clip_size })
  let aura_alpha = if FLASH_AURA_ALPHA <= 0.0 {
    0.0
  } else if FLASH_AURA_ALPHA >= 1.0 {
    1.0
  } else {
    FLASH_AURA_ALPHA
  }
  aura_sprite.color = { ..gem_aura_color(kind), a: aura_alpha }
  aura_sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(aura_entity, aura_sprite)
  @transform.transforms().set(
    aura_entity,
    transform_xy(aura_top_left[X], aura_top_left[Y], 111.0),
  )
  set_entity_visible(aura_entity, true)
}

///|
fn setup_flash_gem_legend() -> Unit {
  let panel_width = 430.0
  let panel_height = 438.0
  let panel_left = VIEWPORT_WIDTH - STATUS_BOX_MARGIN_RIGHT - panel_width
  let panel_top = STATUS_BOX_TOP + STATUS_BOX_HEIGHT + 16.0
  panel_entity(
    flash_legend_panel_entity,
    color_rgba(58U, 64U, 74U, 0.94),
    panel_left + panel_width * 0.5,
    panel_top + panel_height * 0.5,
    panel_width,
    panel_height,
    102.0,
  )
  text_entity(
    flash_legend_title_entity,
    "FLASH GEMS",
    panel_left + 22.0,
    panel_top + 18.0,
    34,
    "rgb(236,244,255)",
    113.0,
  )
  let kinds : Array[GemKind] = [Sapphire, Ruby, Emerald, Amber, Pearl, Amethyst]
  let descriptions : Array[String] = [
    "Sapphire: convert one color", "Ruby: blast nearby 3x3", "Emerald: freeze timer 5s",
    "Amber: clear one row", "Pearl: x3 this clear", "Amethyst: x2 score for 10s",
  ]
  let icon_x = panel_left + 34.0
  let text_x = panel_left + 72.0
  let row_start_y = panel_top + 82.0
  let row_gap = 58.0
  for i = 0; i < kinds.length(); i = i + 1 {
    let row_y = row_start_y + i.to_double() * row_gap
    setup_flash_legend_icon(
      flash_legend_icon_entities[i],
      flash_legend_aura_entities[i],
      kinds[i],
      icon_x,
      row_y + 16.0,
    )
    text_entity(
      flash_legend_text_entities[i],
      descriptions[i],
      text_x,
      row_y + 2.0,
      22,
      "rgb(220,232,246)",
      113.0,
    )
  }
}

///|
fn setup_static_text() -> Unit {
  text_entity(
    title_glow_outer_entity, "MOONBIT EATS YOU", 18.0, 10.0, 108, "rgba(132,72,255,0.34)",
    98.0,
  )
  text_entity(
    title_glow_inner_entity, "MOONBIT EATS YOU", 26.0, 18.0, 92, "rgba(176,112,255,0.52)",
    99.0,
  )
  text_entity(
    title_entity, "MOONBIT EATS YOU", 32.0, 24.0, 80, "rgb(198,135,255)", 100.0,
  )
  let status_center_y = STATUS_BOX_TOP + STATUS_BOX_HEIGHT * 0.5
  let score_center_x = status_box_center_x(1)
  let timer_center_x = status_box_center_x(0)
  panel_entity(
    score_panel_entity,
    color_rgba(58U, 64U, 74U, 0.94),
    score_center_x,
    status_center_y,
    STATUS_BOX_WIDTH,
    STATUS_BOX_HEIGHT,
    102.0,
  )
  panel_entity(
    timer_panel_entity,
    color_rgba(58U, 64U, 74U, 0.94),
    timer_center_x,
    status_center_y,
    STATUS_BOX_WIDTH,
    STATUS_BOX_HEIGHT,
    102.0,
  )
  panel_entity(
    score_fx_entity,
    color_rgba(255U, 64U, 64U, 0.5),
    score_center_x,
    status_center_y,
    STATUS_BOX_WIDTH,
    STATUS_BOX_HEIGHT,
    105.0,
  )
  panel_entity(
    timer_fx_entity,
    color_rgba(255U, 255U, 255U, 0.5),
    timer_center_x,
    status_center_y,
    STATUS_BOX_WIDTH,
    STATUS_BOX_HEIGHT,
    105.0,
  )
  set_entity_visible(score_fx_entity, false)
  set_entity_visible(timer_fx_entity, false)
  text_entity(
    score_text_entity, "", score_center_x, status_center_y, 24, "rgb(236,244,255)",
    106.0,
  )
  set_centered_text_block(
    score_text_entity,
    STATUS_BOX_WIDTH * 0.9,
    STATUS_BOX_HEIGHT * 0.9,
  )
  text_entity(
    timer_text_entity, "", timer_center_x, status_center_y, 24, "rgb(236,244,255)",
    106.0,
  )
  set_centered_text_block(
    timer_text_entity,
    STATUS_BOX_WIDTH * 0.9,
    STATUS_BOX_HEIGHT * 0.9,
  )
  text_entity(
    overlay_text_entity,
    "",
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5 - 18.0,
    44,
    "rgb(255,255,255)",
    400.0,
  )
  @text2d.text_anchors().set(
    overlay_text_entity,
    @sprite.Anchor(@math.Vec2D(0.0, 0.0)),
  )
  @text2d.text_bounds().set(
    overlay_text_entity,
    @text2d.TextBounds::new(VIEWPORT_WIDTH * 0.8, VIEWPORT_HEIGHT * 0.5),
  )
  @ui.text_layouts().set(
    overlay_text_entity,
    @ui.TextLayout::new(align=Center, baseline=Center, wrap=WordWrap),
  )
  panel_entity(
    overlay_entity,
    color_rgba(0U, 0U, 0U, 0.58),
    VIEWPORT_WIDTH * 0.5,
    VIEWPORT_HEIGHT * 0.5,
    VIEWPORT_WIDTH,
    VIEWPORT_HEIGHT,
    390.0,
  )
  set_entity_visible(overlay_entity, false)
  set_entity_visible(overlay_text_entity, false)
}

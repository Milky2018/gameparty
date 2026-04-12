///|

///|
let mooncraft_font_registered : Ref[Bool] = { val: false }

///|
fn register_mooncraft_font_once() -> Unit {
  if mooncraft_font_registered.val {
    return
  }
  ignore(@asset.load_font(MOONCRAFT_FONT_PATH, family=MOONCRAFT_FONT_FAMILY))
  mooncraft_font_registered.val = true
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn transform_2d(position : @math.Vec2D, zindex : Int) -> @transform.Transform {
  {
    translation: @math.Vec3::new(position[X], position[Y], zindex.to_double()),
    rotation: @math.Quat::identity(),
    scale: @math.Vec3::one(),
  }
}

///|
fn set_visibility(entity : @entity.Entity, visible : Bool) -> Unit {
  @visibility.visibilities().set(entity, if visible { Visible } else { Hidden })
}

///|
fn setup_text_entity(
  entity : @entity.Entity,
  content : String,
  position : @math.Vec2D,
  color : String,
  font_size : Int,
) -> Unit {
  ensure_entity_alive(entity)
  @ui.texts().set(entity, @ui.Text::new(content))
  @ui.text_fonts().set(
    entity,
    @ui.TextFont::from_css("\{font_size}px \{MOONCRAFT_FONT_FAMILY}"),
  )
  @ui.text_colors().set(entity, @ui.TextColor::from_css(color))
  @ui.text_layouts().set(
    entity,
    @ui.TextLayout::new(align=Left, baseline=Top, wrap=WordWrap),
  )
  @text2d.text2ds().set(entity, @text2d.Text2d::new())
  @text2d.text_anchors().set(entity, @sprite.Anchor(@math.Vec2D(-0.5, 0.5)))
  @transform.transforms().set(entity, transform_2d(position, 200))
  set_visibility(entity, true)
}

///|
fn setup_color_rect_entity(
  entity : @entity.Entity,
  size : @math.Vec2D,
  position : @math.Vec2D,
  color : String,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_color(@sprite.color_from_css(color), size)
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_2d(position, zindex))
  set_visibility(entity, true)
}

///|
fn setup_image_entity(
  entity : @entity.Entity,
  image : @asset.ImageHandle,
  size : @math.Vec2D,
  position : @math.Vec2D,
  zindex : Int,
  color? : @render.Color = @sprite.color_from_css("white"),
) -> Unit {
  ensure_entity_alive(entity)
  let sprite = @sprite.Sprite::from_image(image, custom_size=Some(size))
  sprite.anchor = @sprite.Anchor(@math.Vec2D(-0.5, 0.5))
  sprite.color = color
  @sprite.sprites().set(entity, sprite)
  @transform.transforms().set(entity, transform_2d(position, zindex))
  set_visibility(entity, true)
}

///|
fn hide_entity(entity : @entity.Entity) -> Unit {
  if entity.is_alive() {
    set_visibility(entity, false)
  }
}

///|
fn hud_title_text() -> String {
  "Mooncraft"
}

///|
fn selected_entry_label() -> String {
  match current_catalog_entry() {
    Some(entry) => "Selected: \{entry.name} (\{category_name(entry.category)})"
    None => "Selected: none"
  }
}

///|
fn hud_info_text() -> String {
  let position = player_controller.val.position
  let chunk_x = @util.floor_div(position.x.floor().to_int(), CHUNK_WORLD_SIZE_X)
  let chunk_y = @util.floor_div(position.y.floor().to_int(), CHUNK_WORLD_SIZE_Y)
  let chunk_z = @util.floor_div(position.z.floor().to_int(), CHUNK_WORLD_SIZE_Z)
  let block_x = position.x.floor().to_int()
  let block_y = position.y.floor().to_int()
  let block_z = position.z.floor().to_int()
  let world_name = match world_session.val {
    Some(session) => world_type_name(session.world_type)
    None => "Unknown"
  }
  let spawn_text = match world_session.val {
    Some(session) =>
      "Seed: \{session.seed}  Spawn: (\{session.spawn_wx}, \{session.spawn_surface_y}, \{session.spawn_wz})"
    None => "Seed: unknown  Spawn: unknown"
  }
  let hit_text = match selection_state.val.hit {
    Some(hit) =>
      "Hit: (\{hit.wx}, \{hit.wy}, \{hit.wz}) -> place (\{hit.place_wx}, \{hit.place_wy}, \{hit.place_wz})"
    None => "Hit: none"
  }
  let (loaded_chunks, total_chunks) = chunk_runtime_stats()
  let reach_text = if startup_reach_hit() is Some(_) {
    "Reach hit: yes"
  } else {
    "Reach hit: no"
  }
  let controller = player_controller.val
  "Type: \{world_name}  Block: (\{block_x}, \{block_y}, \{block_z})  Chunk: (\{chunk_x}, \{chunk_y}, \{chunk_z})\n\{spawn_text}\nPlayer: (\{position.x.to_int()}, \{position.y.to_int()}, \{position.z.to_int()})  Ground: \{controller.on_ground}  Yaw/Pitch: (\{controller.yaw.to_int()}, \{controller.pitch})\nChunks: \{loaded_chunks}/\{total_chunks}  Column ready: \{player_chunk_column_loaded()}  \{reach_text}\n\{selected_entry_label()}\n\{hit_text}"
}

///|
fn hud_hint_text() -> String {
  if inventory_state.val.open {
    "E close inventory  Wheel scroll list  Left click assign to hotbar  Tab / Wheel choose hotbar"
  } else {
    "Left click lock mouse  WASD move  Space jump  Shift slow  Left break  Right place  Middle sample  E inventory  Tab/Wheel hotbar  Q/Z/X/C world  R regenerate  Esc release/exit"
  }
}

///|
fn inventory_title_text() -> String {
  "Creative Inventory"
}

///|
fn inventory_hint_text() -> String {
  "Move the virtual cursor with the mouse and left click an item to assign it to the selected hotbar slot."
}

///|
fn screen_cursor_position() -> @math.Vec2D {
  if @system.is_mouse_locked() {
    inventory_state.val.cursor
  } else {
    @inputs.mouse.pos
  }
}

///|
fn hotbar_base_position() -> @math.Vec2D {
  let width = HOTBAR_SIZE.to_double() * HOTBAR_SLOT_SIZE
  @math.Vec2D(
    VIEWPORT_WIDTH / 2.0 - width / 2.0,
    VIEWPORT_HEIGHT - HOTBAR_SLOT_SIZE - 18.0,
  )
}

///|
fn inventory_grid_origin() -> @math.Vec2D {
  @math.Vec2D(
    VIEWPORT_WIDTH / 2.0 - INVENTORY_PANEL_WIDTH / 2.0 + 52.0,
    VIEWPORT_HEIGHT / 2.0 - INVENTORY_PANEL_HEIGHT / 2.0 + 82.0,
  )
}

///|
fn inventory_slot_screen_rect(slot_index : Int) -> @math.Rect {
  let column = slot_index % INVENTORY_COLUMNS
  let row = slot_index / INVENTORY_COLUMNS
  let origin = inventory_grid_origin()
  let x = origin[X] + column.to_double() * INVENTORY_SLOT_SIZE
  let y = origin[Y] + row.to_double() * INVENTORY_SLOT_SIZE
  {
    position: @math.Vec2D(x, y),
    size: @math.Vec2D(INVENTORY_SLOT_SIZE - 8.0, INVENTORY_SLOT_SIZE - 8.0),
  }
}

///|
fn point_in_rect(point : @math.Vec2D, rect : @math.Rect) -> Bool {
  point[X] >= rect.position[X] &&
  point[X] <= rect.position[X] + rect.size[X] &&
  point[Y] >= rect.position[Y] &&
  point[Y] <= rect.position[Y] + rect.size[Y]
}

///|
fn max_inventory_scroll_row() -> Int {
  let total_rows = (
      inventory_state.val.catalog.length() + INVENTORY_COLUMNS - 1
    ) /
    INVENTORY_COLUMNS
  let extra = total_rows - INVENTORY_ROWS
  if extra > 0 {
    extra
  } else {
    0
  }
}

///|
fn clamp_inventory_cursor() -> Unit {
  let cursor = inventory_state.val.cursor
  inventory_state.val = {
    ..inventory_state.val,
    cursor: @math.Vec2D(
      cursor[X].clamp(min=0.0, max=VIEWPORT_WIDTH),
      cursor[Y].clamp(min=0.0, max=VIEWPORT_HEIGHT),
    ),
  }
}

///|
fn visible_inventory_index(slot_index : Int) -> Int {
  inventory_state.val.scroll_row * INVENTORY_COLUMNS + slot_index
}

///|
fn sync_hud_text(
  entity : @entity.Entity,
  cache : Ref[String],
  text : String,
  position : @math.Vec2D,
  color : String,
  font_size : Int,
) -> Unit {
  if cache.val != text || !entity.is_alive() {
    setup_text_entity(entity, text, position, color, font_size)
    cache.val = text
  } else {
    ensure_entity_alive(entity)
    @transform.transforms().set(entity, transform_2d(position, 200))
    set_visibility(entity, true)
  }
}

///|
fn sync_hud() -> Unit {
  sync_hud_text(
    hud_title_entity,
    last_hud_title_text,
    hud_title_text(),
    @math.Vec2D(20.0, 20.0),
    "white",
    30,
  )
  sync_hud_text(
    hud_info_entity,
    last_hud_info_text,
    hud_info_text(),
    @math.Vec2D(20.0, 62.0),
    "rgb(220,230,240)",
    15,
  )
  sync_hud_text(
    hud_hint_entity,
    last_hud_hint_text,
    hud_hint_text(),
    @math.Vec2D(20.0, VIEWPORT_HEIGHT - 44.0),
    "rgb(180,200,220)",
    14,
  )
}

///|
fn sync_hotbar() -> Unit {
  let base = hotbar_base_position()
  let selected = wrap_hotbar_index(player_controller.val.selected_hotbar_index)
  for index in 0..<HOTBAR_SIZE {
    let x = base[X] + index.to_double() * HOTBAR_SLOT_SIZE
    let position = @math.Vec2D(x, base[Y])
    let slot_color = if index == selected {
      "rgba(244, 211, 94, 0.92)"
    } else {
      "rgba(32, 36, 44, 0.86)"
    }
    setup_color_rect_entity(
      hotbar_slot_entities[index],
      @math.Vec2D(HOTBAR_SLOT_SIZE - 6.0, HOTBAR_SLOT_SIZE - 6.0),
      position,
      slot_color,
      UI_DEPTH.to_int(),
    )
    match inventory_state.val.hotbar.get(index) {
      Some(slot) =>
        match inventory_state.val.catalog.get(slot.catalog_index) {
          Some(entry) =>
            setup_image_entity(
              hotbar_icon_entities[index],
              entry.icon_handle,
              @math.Vec2D(HOTBAR_ICON_SIZE, HOTBAR_ICON_SIZE),
              @math.Vec2D(position[X] + 6.0, position[Y] + 6.0),
              UI_DEPTH.to_int() + 1,
            )
          None => hide_entity(hotbar_icon_entities[index])
        }
      None => hide_entity(hotbar_icon_entities[index])
    }
  }
}

///|
fn sync_inventory() -> Unit {
  if !inventory_state.val.open {
    hide_entity(inventory_panel_entity)
    hide_entity(inventory_title_entity)
    hide_entity(inventory_hint_entity)
    hide_entity(inventory_cursor_entity)
    for entity in inventory_slot_entities {
      hide_entity(entity)
    }
    for entity in inventory_icon_entities {
      hide_entity(entity)
    }
    return
  }
  match gui_window_image_handle.val {
    Some(window_image) =>
      setup_image_entity(
        inventory_panel_entity,
        window_image,
        @math.Vec2D(INVENTORY_PANEL_WIDTH, INVENTORY_PANEL_HEIGHT),
        @math.Vec2D(
          VIEWPORT_WIDTH / 2.0 - INVENTORY_PANEL_WIDTH / 2.0,
          VIEWPORT_HEIGHT / 2.0 - INVENTORY_PANEL_HEIGHT / 2.0,
        ),
        UI_DEPTH.to_int() - 2,
      )
    None =>
      setup_color_rect_entity(
        inventory_panel_entity,
        @math.Vec2D(INVENTORY_PANEL_WIDTH, INVENTORY_PANEL_HEIGHT),
        @math.Vec2D(
          VIEWPORT_WIDTH / 2.0 - INVENTORY_PANEL_WIDTH / 2.0,
          VIEWPORT_HEIGHT / 2.0 - INVENTORY_PANEL_HEIGHT / 2.0,
        ),
        "rgba(18,24,32,0.92)",
        UI_DEPTH.to_int() - 2,
      )
  }
  sync_hud_text(
    inventory_title_entity,
    last_inventory_title_text,
    inventory_title_text(),
    @math.Vec2D(
      VIEWPORT_WIDTH / 2.0 - INVENTORY_PANEL_WIDTH / 2.0 + 24.0,
      VIEWPORT_HEIGHT / 2.0 - INVENTORY_PANEL_HEIGHT / 2.0 + 18.0,
    ),
    "white",
    22,
  )
  sync_hud_text(
    inventory_hint_entity,
    last_inventory_hint_text,
    inventory_hint_text(),
    @math.Vec2D(
      VIEWPORT_WIDTH / 2.0 - INVENTORY_PANEL_WIDTH / 2.0 + 24.0,
      VIEWPORT_HEIGHT / 2.0 + INVENTORY_PANEL_HEIGHT / 2.0 - 44.0,
    ),
    "rgb(210,220,232)",
    14,
  )
  for slot_index in 0..<INVENTORY_VISIBLE_SLOTS {
    let rect = inventory_slot_screen_rect(slot_index)
    let catalog_index = visible_inventory_index(slot_index)
    let slot_color = if catalog_index < inventory_state.val.catalog.length() {
      "rgba(39,52,68,0.85)"
    } else {
      "rgba(28,36,44,0.45)"
    }
    setup_color_rect_entity(
      inventory_slot_entities[slot_index],
      rect.size,
      rect.position,
      slot_color,
      UI_DEPTH.to_int(),
    )
    match inventory_state.val.catalog.get(catalog_index) {
      Some(entry) =>
        setup_image_entity(
          inventory_icon_entities[slot_index],
          entry.icon_handle,
          @math.Vec2D(INVENTORY_ICON_SIZE, INVENTORY_ICON_SIZE),
          @math.Vec2D(rect.position[X] + 2.0, rect.position[Y] + 2.0),
          UI_DEPTH.to_int() + 1,
        )
      None => hide_entity(inventory_icon_entities[slot_index])
    }
  }
  setup_color_rect_entity(
    inventory_cursor_entity,
    @math.Vec2D(INVENTORY_CURSOR_SIZE, INVENTORY_CURSOR_SIZE),
    inventory_state.val.cursor,
    "rgba(255, 236, 120, 0.95)",
    UI_DEPTH.to_int() + 5,
  )
}

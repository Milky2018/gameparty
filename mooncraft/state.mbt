///|
pub const VIEWPORT_WIDTH : Double = 1280.0

///|
pub const VIEWPORT_HEIGHT : Double = 720.0

///|
pub const FPS : UInt = 60

///|
const ATLAS_COLUMNS : Int = 8

///|
const ATLAS_ROWS : Int = 11

///|
const ATLAS_PATH : String = "mooncraft/assets/generated/block_item_atlas.png"

///|
const GUI_WINDOW_PATH : String = "mooncraft/assets/gui/window.png"

///|
let mooncraft_asset_path_prefixes : Array[String] = [
  "", "../", "../../", "../../../",
]

///|
const CHUNK_RADIUS_XZ : Int = 2

///|
const CHUNK_GENERATE_BUDGET : Int = 16

///|
const CHUNK_REBUILD_BUDGET : Int = 10

///|
const CHUNK_UNLOAD_BUDGET : Int = 24

///|
const PLAYER_HEIGHT : Double = 1.8

///|
const PLAYER_RADIUS : Double = 0.32

///|
const PLAYER_EYE_HEIGHT : Double = 1.62

///|
const PLAYER_MOVE_SPEED : Double = 5.2

///|
const PLAYER_SLOW_MULTIPLIER : Double = 0.45

///|
const PLAYER_LOOK_SENSITIVITY : Double = 0.0024

///|
const PLAYER_REACH : Double = 6.0

///|
const PLAYER_JUMP_SPEED : Double = 6.8

///|
const PLAYER_GRAVITY : Double = 20.0

///|
const PLAYER_MAX_FALL_SPEED : Double = 28.0

///|
const MAX_PITCH : Double = 1.45

///|
const DEFAULT_PLAYER_YAW : Double = -@cmath.PI * 0.75

///|
const DEFAULT_PLAYER_PITCH : Double = -0.35

///|
const HOTBAR_SIZE : Int = 9

///|
const HOTBAR_SLOT_SIZE : Double = 52.0

///|
const INVENTORY_COLUMNS : Int = 8

///|
const INVENTORY_ROWS : Int = 8

///|
const INVENTORY_VISIBLE_SLOTS : Int = INVENTORY_COLUMNS * INVENTORY_ROWS

///|
const INVENTORY_SLOT_SIZE : Double = 52.0

///|
const INVENTORY_CURSOR_SIZE : Double = 14.0

///|
const UI_DEPTH : Double = 300.0

///|
const HOTBAR_ICON_SIZE : Double = 40.0

///|
const INVENTORY_ICON_SIZE : Double = 40.0

///|
const INVENTORY_PANEL_WIDTH : Double = 640.0

///|
const INVENTORY_PANEL_HEIGHT : Double = 420.0

///|
const SELECTION_BOX_SIZE : Double = 1.01

///|
const PREVIEW_BOX_SIZE : Double = 1.01

///|
const CHUNK_WORLD_SIZE_X : Int = @level.CHUNK_X_SIZE

///|
const CHUNK_WORLD_SIZE_Y : Int = @level.CHUNK_Y_SIZE

///|
const CHUNK_WORLD_SIZE_Z : Int = @level.CHUNK_Z_SIZE

///|
const SPAWN_BLOCK_X : Int = CHUNK_WORLD_SIZE_X / 2

///|
const SPAWN_BLOCK_Z : Int = CHUNK_WORLD_SIZE_Z / 2

///|
const SPAWN_SURFACE_OFFSET : Int = 3

///|
const DEMO_ANIMATION_BLEND_DURATION : Double = 0.15

///|
const DEBUG_FORCE_WORLD_UNLIT : Bool = false

///|
const DEBUG_CAPTURE_ENABLED : Bool = false

///|
const DEBUG_CAPTURE_DELAY : Double = 1.0

///|
const DEBUG_CAPTURE_PATH : String = "/tmp/mooncraft_capture.png"

///|
const DEBUG_FRAME_LOG_LIMIT : Int = 0

///|
const DEBUG_SHOW_MARKER : Bool = false

///|
const DEBUG_VERBOSE_STARTUP : Bool = false

///|
pub(all) struct WorldSession {
  seed : UInt64
  world_type : @level.WorldType
  spawn_wx : Int
  spawn_wz : Int
  spawn_surface_y : Int
  chunk_radius : Int
  chunk_min_y : Int
  chunk_max_y : Int
  world : @level.World
  registry : @block.BlockRegistry
  texture_names : Array[String]
  texture_name_to_index : Map[String, Int]
  texture_colors : Array[@render.Color]
}

///|
pub(all) struct ChunkRecord {
  chunk_x : Int
  chunk_y : Int
  chunk_z : Int
  mut data : Array[UInt]
  light : Bytes
  mut dirty : Bool
  mut loaded : Bool
  mut opaque_entity : @entity.Entity?
  mut cutout_entity : @entity.Entity?
  mut translucent_entity : @entity.Entity?
  mut opaque_mesh : @render3d.MeshHandle?
  mut cutout_mesh : @render3d.MeshHandle?
  mut translucent_mesh : @render3d.MeshHandle?
}

///|
pub(all) struct ChunkStreamQueue {
  mut to_generate : Array[String]
  mut to_rebuild : Array[String]
  mut to_unload : Array[String]
}

///|
pub(all) struct PlayerController {
  mut position : @math.Vec3
  mut velocity : @math.Vec3
  mut yaw : Double
  mut pitch : Double
  mut on_ground : Bool
  mut selected_hotbar_index : Int
}

///|
pub(all) struct CatalogEntry {
  name : String
  category : @item.Category
  icon_texture : String
  icon_path : String
  icon_handle : @asset.ImageHandle
  block_long_id : UInt?
}

///|
pub(all) struct HotbarSlot {
  mut catalog_index : Int
}

///|
pub(all) struct InventoryState {
  mut open : Bool
  mut cursor : @math.Vec2D
  mut scroll_row : Int
  catalog : Array[CatalogEntry]
  mut hotbar : Array[HotbarSlot]
}

///|
pub(all) struct BlockHit {
  wx : Int
  wy : Int
  wz : Int
  place_wx : Int
  place_wy : Int
  place_wz : Int
  face : @shape.FaceName
  long_id : UInt
  point : @math.Vec3
  distance : Double
}

///|
pub(all) struct SelectionState {
  mut hit : BlockHit?
  mut preview_long_id : UInt?
  mut preview_valid : Bool
}

///|
pub(all) struct DemoEntityState {
  mut roots : Array[@entity.Entity]
  mut rabbit_scene : @render3d.SceneHandle?
  mut snowman_scene : @render3d.SceneHandle?
  mut zombie_scene : @render3d.SceneHandle?
}

///|
let world_session : Ref[WorldSession?] = { val: None }

///|
let chunk_store : Ref[Map[String, ChunkRecord]] = { val: Map::new() }

///|
let chunk_stream_queue : Ref[ChunkStreamQueue] = { val: empty_queue() }

///|
let player_controller : Ref[PlayerController] = {
  val: {
    position: @math.Vec3::new(0.5, 80.0, 0.5),
    velocity: @math.Vec3::zero(),
    yaw: 0.0,
    pitch: DEFAULT_PLAYER_PITCH,
    on_ground: false,
    selected_hotbar_index: 0,
  },
}

///|
let inventory_state : Ref[InventoryState] = {
  val: {
    open: false,
    cursor: @math.Vec2D(VIEWPORT_WIDTH / 2.0, VIEWPORT_HEIGHT / 2.0),
    scroll_row: 0,
    catalog: [],
    hotbar: [],
  },
}

///|
let selection_state : Ref[SelectionState] = {
  val: { hit: None, preview_long_id: None, preview_valid: false },
}

///|
let demo_entity_state : Ref[DemoEntityState] = {
  val: {
    roots: [],
    rabbit_scene: None,
    snowman_scene: None,
    zombie_scene: None,
  },
}

///|
let atlas_image_handle : Ref[@render3d.ImageHandle?] = { val: None }

///|
let gui_window_image_handle : Ref[@asset.ImageHandle?] = { val: None }

///|
let opaque_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let cutout_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let translucent_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let selection_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let preview_material_handle : Ref[@render3d.MaterialHandle?] = { val: None }

///|
let debug_marker_material_handle : Ref[@render3d.MaterialHandle?] = {
  val: None,
}

///|
let cube_mesh_handle : Ref[@render3d.MeshHandle?] = { val: None }

///|
let camera_entity : @entity.Entity = @entity.Entity::new()

///|
let light_entity : @entity.Entity = @entity.Entity::new()

///|
let selection_entity : @entity.Entity = @entity.Entity::new()

///|
let preview_entity : @entity.Entity = @entity.Entity::new()

///|
let debug_marker_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_title_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_info_entity : @entity.Entity = @entity.Entity::new()

///|
let hud_hint_entity : @entity.Entity = @entity.Entity::new()

///|
let hotbar_slot_entities : Array[@entity.Entity] = Array::makei(HOTBAR_SIZE, fn(
  _,
) {
  @entity.Entity::new()
})

///|
let hotbar_icon_entities : Array[@entity.Entity] = Array::makei(HOTBAR_SIZE, fn(
  _,
) {
  @entity.Entity::new()
})

///|
let inventory_panel_entity : @entity.Entity = @entity.Entity::new()

///|
let inventory_title_entity : @entity.Entity = @entity.Entity::new()

///|
let inventory_hint_entity : @entity.Entity = @entity.Entity::new()

///|
let inventory_cursor_entity : @entity.Entity = @entity.Entity::new()

///|
let inventory_slot_entities : Array[@entity.Entity] = Array::makei(
  INVENTORY_VISIBLE_SLOTS,
  fn(_) { @entity.Entity::new() },
)

///|
let inventory_icon_entities : Array[@entity.Entity] = Array::makei(
  INVENTORY_VISIBLE_SLOTS,
  fn(_) { @entity.Entity::new() },
)

///|
let last_hud_title_text : Ref[String] = { val: "" }

///|
let last_hud_info_text : Ref[String] = { val: "" }

///|
let last_hud_hint_text : Ref[String] = { val: "" }

///|
let last_inventory_title_text : Ref[String] = { val: "" }

///|
let last_inventory_hint_text : Ref[String] = { val: "" }

///|
let debug_update_counter : Ref[Int] = { val: 0 }

///|
let debug_started_at : Ref[Double] = { val: 0.0 }

///|
let debug_capture_taken : Ref[Bool] = { val: false }

///|
let world_material_rebind_frames_left : Ref[Int] = { val: 0 }

///|
fn world_type_name(world_type : @level.WorldType) -> String {
  @level.world_type_name(world_type)
}

///|
fn category_name(category : @item.Category) -> String {
  match category {
    @item.Category::Block => "block"
    @item.Category::Item => "item"
    @item.Category::None => "none"
  }
}

///|
fn resolve_mooncraft_asset_path(path : String) -> String {
  for prefix in mooncraft_asset_path_prefixes {
    let candidate = "\{prefix}\{path}"
    if @asset.read_bytes(candidate) is Some(_) {
      return candidate
    }
  }
  path
}

///|
fn empty_queue() -> ChunkStreamQueue {
  { to_generate: [], to_rebuild: [], to_unload: [] }
}

///|
fn chunk_world_origin(
  chunk_x : Int,
  chunk_y : Int,
  chunk_z : Int,
) -> @math.Vec3 {
  @math.Vec3::new(
    (chunk_x * CHUNK_WORLD_SIZE_X).to_double(),
    (chunk_y * CHUNK_WORLD_SIZE_Y).to_double(),
    (chunk_z * CHUNK_WORLD_SIZE_Z).to_double(),
  )
}

///|
fn chunk_mesh_center_offset() -> @math.Vec3 {
  @math.Vec3::new(
    CHUNK_WORLD_SIZE_X.to_double() * 0.5,
    CHUNK_WORLD_SIZE_Y.to_double() * 0.5,
    CHUNK_WORLD_SIZE_Z.to_double() * 0.5,
  )
}

///|
fn wrap_hotbar_index(index : Int) -> Int {
  let size = HOTBAR_SIZE
  if size <= 0 {
    0
  } else {
    let value = index % size
    if value < 0 {
      value + size
    } else {
      value
    }
  }
}

///|
fn current_hotbar_slot() -> HotbarSlot? {
  let hotbar = inventory_state.val.hotbar
  if hotbar.length() == 0 {
    None
  } else {
    hotbar.get(wrap_hotbar_index(player_controller.val.selected_hotbar_index))
  }
}

///|
fn current_catalog_entry() -> CatalogEntry? {
  guard current_hotbar_slot() is Some(slot) else { return None }
  inventory_state.val.catalog.get(slot.catalog_index)
}

///|
fn icon_texture_to_asset_path(texture_name : String) -> String {
  let builder = StringBuilder::new()
  builder.write_string("mooncraft/assets/textures/")
  let mut first = true
  for part in texture_name.split("/") {
    if !first {
      builder.write_string("__")
    }
    builder.write_string(part.to_string())
    first = false
  }
  builder.write_string(".png")
  builder.to_string()
}

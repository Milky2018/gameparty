///|
const APP_VIEWPORT_WIDTH : Double = 640.0

///|
const APP_VIEWPORT_HEIGHT : Double = 480.0

///|
const APP_ZOOM : Double = 2.0

///|
const APP_FPS : UInt = 60

///|
const PACMAN_UPSTREAM_FONT_FAMILY : String = "Arial"

///|
let pacman_upstream_font_registered : Ref[Bool] = { val: false }

///|
let pacman_upstream_font_candidate_paths : Array[String] = [
  "/System/Library/Fonts/Supplemental/Arial.ttf", "/Library/Fonts/Arial.ttf", "C:/Windows/Fonts/arial.ttf",
  "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", "/usr/share/fonts/liberation/LiberationSans-Regular.ttf",
]

///|
fn register_pacman_upstream_font_once() -> Unit {
  if pacman_upstream_font_registered.val {
    return
  }
  for path in pacman_upstream_font_candidate_paths {
    if @asset.read_bytes(path) is Some(_) {
      ignore(@asset.load_font(path, family=PACMAN_UPSTREAM_FONT_FAMILY))
      pacman_upstream_font_registered.val = true
      return
    }
  }
  pacman_upstream_font_registered.val = true
}

///|
priv enum MenuChoice {
  LaunchThetawave
  LaunchPacman3d
  Exit
}

///|
priv enum ActiveGame {
  Menu
  Thetawave
  Pacman3d
}

///|
let active_game : Ref[ActiveGame] = { val: Menu }

///|
let previous_game : Ref[ActiveGame] = { val: Menu }

///|
let menu_selected_index : Ref[Int] = { val: 0 }

///|
let menu_title_entity : @entity.Entity = @entity.Entity::new()

///|
let menu_hint_entity : @entity.Entity = @entity.Entity::new()

///|
let menu_item1_entity : @entity.Entity = @entity.Entity::new()

///|
let menu_item2_entity : @entity.Entity = @entity.Entity::new()

///|
let menu_item3_entity : @entity.Entity = @entity.Entity::new()

///|
fn is_same_game(lhs : ActiveGame, rhs : ActiveGame) -> Bool {
  match (lhs, rhs) {
    (Menu, Menu) => true
    (Thetawave, Thetawave) => true
    (Pacman3d, Pacman3d) => true
    _ => false
  }
}

///|
fn menu_item_count() -> Int {
  3
}

///|
fn menu_label(index : Int) -> String {
  match index {
    0 => "Thetawave"
    1 => "Pacman 3D"
    _ => "Exit"
  }
}

///|
fn menu_choice_from_index(index : Int) -> MenuChoice {
  match index {
    0 => LaunchThetawave
    1 => LaunchPacman3d
    _ => Exit
  }
}

///|
fn menu_item_entity(index : Int) -> @entity.Entity {
  match index {
    0 => menu_item1_entity
    1 => menu_item2_entity
    _ => menu_item3_entity
  }
}

///|
fn menu_entities() -> Array[@entity.Entity] {
  [
    menu_title_entity, menu_hint_entity, menu_item1_entity, menu_item2_entity, menu_item3_entity,
  ]
}

///|
fn wrap_menu_index(index : Int) -> Int {
  let count = menu_item_count()
  let mut wrapped = index % count
  if wrapped < 0 {
    wrapped += count
  }
  wrapped
}

///|
fn ensure_entity_alive(entity : @entity.Entity) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
}

///|
fn set_center_text_entity(
  entity : @entity.Entity,
  text : String,
  position : @math.Vec2D,
  font : String,
  color : String,
  zindex : Int,
) -> Unit {
  ensure_entity_alive(entity)
  let style = @sprite.Text::new(text, color~, font~, baseline=Top, align=Center)
  @sprite.sprites.set(entity, @sprite.Sprite::from_text(style, zindex))
  @transform.positions.set(entity, position)
}

///|
fn menu_item_text(index : Int, selected_index : Int) -> String {
  let prefix = if index == selected_index { "> " } else { "  " }
  "\{prefix}\{menu_label(index)}"
}

///|
fn menu_item_color(index : Int, selected_index : Int) -> String {
  if index == selected_index {
    "rgb(255,224,120)"
  } else {
    "rgb(210,210,210)"
  }
}

///|
fn refresh_menu_visuals() -> Unit {
  let center_x = APP_VIEWPORT_WIDTH / 2.0
  set_center_text_entity(
    menu_title_entity,
    "GAME PARTY",
    @math.Vec2D(center_x, 70.0),
    "56px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "white",
    300,
  )
  set_center_text_entity(
    menu_hint_entity,
    "W/S or Arrow Keys Select   Enter/Space Confirm   ESC Exit",
    @math.Vec2D(center_x, APP_VIEWPORT_HEIGHT - 36.0),
    "18px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "rgb(170,170,170)",
    300,
  )

  let selected = menu_selected_index.val
  for index in 0..<menu_item_count() {
    let item_y = 192.0 + index.to_double() * 52.0
    set_center_text_entity(
      menu_item_entity(index),
      menu_item_text(index, selected),
      @math.Vec2D(center_x, item_y),
      "36px \{PACMAN_UPSTREAM_FONT_FAMILY}",
      menu_item_color(index, selected),
      300,
    )
  }
}

///|
fn set_menu_visible(visible : Bool) -> Unit {
  for entity in menu_entities() {
    if @sprite.sprites.get(entity) is Some(sprite) {
      sprite.visible = visible
    }
  }
}

///|
fn hide_existing_scene_visuals() -> Unit {
  for _, sprite in @sprite.sprites {
    sprite.visible = false
  }
  for _, renderer in @render3d.mesh3d_renderers {
    renderer.visible = false
  }
  for _, camera in @camera3d.cameras3d {
    camera.enabled = false
  }
}

///|
fn enter_menu_mode() -> Unit {
  hide_existing_scene_visuals()
  menu_selected_index.val = 0
  set_menu_visible(true)
  refresh_menu_visuals()
}

///|
fn enter_thetawave_mode() -> Unit {
  hide_existing_scene_visuals()
  @thetawave.enter_from_host()
}

///|
fn enter_pacman3d_mode() -> Unit {
  hide_existing_scene_visuals()
  @pacman3d.enter_from_host()
}

///|
fn game_mode_transition_system(_delta : Double) -> Unit {
  if is_same_game(active_game.val, previous_game.val) {
    return
  }
  match active_game.val {
    Menu => enter_menu_mode()
    Thetawave => enter_thetawave_mode()
    Pacman3d => enter_pacman3d_mode()
  }
  previous_game.val = active_game.val
}

///|
fn move_menu_selection(step : Int) -> Unit {
  menu_selected_index.val = wrap_menu_index(menu_selected_index.val + step)
  refresh_menu_visuals()
}

///|
fn confirm_menu_selection() -> Unit {
  match menu_choice_from_index(menu_selected_index.val) {
    LaunchThetawave => active_game.val = Thetawave
    LaunchPacman3d => active_game.val = Pacman3d
    Exit => @system.exit()
  }
}

///|
fn menu_input_system(_delta : Double) -> Unit {
  if @inputs.is_just_pressed(ArrowUp) || @inputs.is_just_pressed(KeyW) {
    move_menu_selection(-1)
  }
  if @inputs.is_just_pressed(ArrowDown) || @inputs.is_just_pressed(KeyS) {
    move_menu_selection(1)
  }
  if @inputs.is_just_pressed(Enter) || @inputs.is_just_pressed(Space) {
    confirm_menu_selection()
  }
  if @inputs.is_just_pressed(Escape) {
    @system.exit()
  }
}

///|
fn menu_startup_system(_delta : Double) -> Unit {
  register_pacman_upstream_font_once()
  for entity in menu_entities() {
    ensure_entity_alive(entity)
  }
  @thetawave.set_exit_handler(fn() { active_game.val = Menu })
  @pacman3d.set_exit_handler(fn() { active_game.val = Menu })
  active_game.val = Menu
  previous_game.val = Menu
  enter_menu_mode()
}

///|
fn run_if_menu() -> Bool {
  match active_game.val {
    Menu => true
    _ => false
  }
}

///|
fn run_if_thetawave() -> Bool {
  match active_game.val {
    Thetawave => true
    _ => false
  }
}

///|
fn run_if_pacman3d() -> Bool {
  match active_game.val {
    Pacman3d => true
    _ => false
  }
}

///|
pub fn run() -> Unit {
  let app = @system.App::new()
    .with_viewport_width(APP_VIEWPORT_WIDTH)
    .with_viewport_height(APP_VIEWPORT_HEIGHT)
    .with_zoom(APP_ZOOM)
    .with_fps(APP_FPS)
    .with_image_smooth(true)
    .add_plugin(@plugins.default_plugin)
    .add_system(@transform3d.transform3d_propagate_system, schedule=PostUpdate)
    .add_system(@camera3d.camera3d_extract_system, schedule=RenderExtract)
    .add_system(@render3d.render3d_extract_system, schedule=RenderExtract)
    .add_system(
      @render3d_pipeline.render3d_prepare_system,
      schedule=RenderPrepare,
    )
    .add_system(menu_startup_system, schedule=Startup)
    .add_system(game_mode_transition_system)
    .add_system(menu_input_system, run_if=run_if_menu)
  let app = @thetawave.add_runtime_systems(app, run_if_thetawave)
  let app = @pacman3d.add_runtime_systems(app, run_if_pacman3d)
  app.run()
}

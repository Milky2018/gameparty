///|
const MENU_VIEWPORT_WIDTH : Double = 960.0

///|
const MENU_VIEWPORT_HEIGHT : Double = 540.0

///|
const MENU_FPS : UInt = 60

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
let menu_choice : Ref[MenuChoice?] = { val: None }

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
  let center_x = MENU_VIEWPORT_WIDTH / 2.0
  set_center_text_entity(
    menu_title_entity,
    "GAME PARTY",
    @math.Vec2D(center_x, 92.0),
    "64px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "white",
    300,
  )
  set_center_text_entity(
    menu_hint_entity,
    "W/S or Arrow Keys Select   Enter/Space Confirm   ESC Exit",
    @math.Vec2D(center_x, 450.0),
    "20px \{PACMAN_UPSTREAM_FONT_FAMILY}",
    "rgb(170,170,170)",
    300,
  )

  let selected = menu_selected_index.val
  for index in 0..<menu_item_count() {
    let item_y = 220.0 + index.to_double() * 56.0
    set_center_text_entity(
      menu_item_entity(index),
      menu_item_text(index, selected),
      @math.Vec2D(center_x, item_y),
      "40px \{PACMAN_UPSTREAM_FONT_FAMILY}",
      menu_item_color(index, selected),
      300,
    )
  }
}

///|
fn menu_startup_system(_delta : Double) -> Unit {
  register_pacman_upstream_font_once()
  ensure_entity_alive(menu_title_entity)
  ensure_entity_alive(menu_hint_entity)
  ensure_entity_alive(menu_item1_entity)
  ensure_entity_alive(menu_item2_entity)
  ensure_entity_alive(menu_item3_entity)
  refresh_menu_visuals()
}

///|
fn move_menu_selection(step : Int) -> Unit {
  menu_selected_index.val = wrap_menu_index(menu_selected_index.val + step)
  refresh_menu_visuals()
}

///|
fn confirm_menu_selection() -> Unit {
  menu_choice.val = Some(menu_choice_from_index(menu_selected_index.val))
  @system.exit()
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
    menu_choice.val = Some(Exit)
    @system.exit()
  }
}

///|
fn run_menu_once() -> MenuChoice {
  menu_selected_index.val = 0
  menu_choice.val = None

  @system.App::new()
  .with_viewport_width(MENU_VIEWPORT_WIDTH)
  .with_viewport_height(MENU_VIEWPORT_HEIGHT)
  .with_zoom(1.0)
  .with_fps(MENU_FPS)
  .with_image_smooth(true)
  .add_plugin(@plugins.default_plugin)
  .add_system(menu_startup_system, schedule=Startup)
  .add_system(menu_input_system)
  .run()

  menu_choice.val.unwrap_or(Exit)
}

///|
pub fn run_thetawave() -> Unit {
  @thetawave.run()
}

///|
pub fn run_pacman3d() -> Unit {
  @pacman3d.run()
}

///|
pub fn run() -> Unit {
  let mut running = true
  while running {
    match run_menu_once() {
      LaunchThetawave => run_thetawave()
      LaunchPacman3d => run_pacman3d()
      Exit => running = false
    }
  }
}

///|
fn startup_system(_delta : Double) -> Unit {
  if !ui_initialized.val {
    install_embedded_assets()
    preload_assets()
    initialize_scene()
    initialize_ui()
    ui_initialized.val = true
  }
  enter_main_menu()
}

///|
let game_background_textures : Array[String] = [
  "thetawave/assets/texture/backgrounds/background_1.png", "thetawave/assets/texture/backgrounds/background_2.png",
  "thetawave/assets/texture/backgrounds/background_3.png", "thetawave/assets/texture/backgrounds/background_4.png",
  "thetawave/assets/texture/backgrounds/background_5.png", "thetawave/assets/texture/backgrounds/background_6.png",
  "thetawave/assets/texture/backgrounds/background_7.png", "thetawave/assets/texture/backgrounds/background_8.png",
  "thetawave/assets/texture/backgrounds/background_9.png", "thetawave/assets/texture/backgrounds/background_10.png",
  "thetawave/assets/texture/backgrounds/background_11.png", "thetawave/assets/texture/backgrounds/background_12.png",
]

///|
fn preload_assets() -> Unit {
  @backend.preload_img(MENU_BG_TEXTURE)
  @backend.preload_img(CHARACTER_SELECT_BG_TEXTURE)
  @backend.preload_img(GAME_BG_TEXTURE)
  @backend.preload_img(GAME_OVER_BG_TEXTURE)
  @backend.preload_img(VICTORY_BG_TEXTURE)
  @backend.preload_img(THETAWAVE_LOGO_TEXTURE)
  @backend.preload_img(MENU_BUTTON_SPRITESHEET_TEXTURE)
  @backend.preload_img(CAPTAIN_TEXTURE)
  @backend.preload_img(JUGGERNAUT_TEXTURE)
  @backend.preload_img(CAPTAIN_DESCRIPTION_TEXTURE)
  @backend.preload_img(JUGGERNAUT_DESCRIPTION_TEXTURE)
  @backend.preload_img(RESTART_GAME_PROMPT_TEXTURE)
  @backend.preload_img(PAWN_TEXTURE)
  @backend.preload_img(DRONE_TEXTURE)
  @backend.preload_img(TUTORIAL_DRONE_TEXTURE)
  @backend.preload_img(SHELLY_TEXTURE)
  @backend.preload_img(STRAFER_TEXTURE)
  @backend.preload_img(MISSILE_LAUNCHER_TEXTURE)
  @backend.preload_img(MISSILE_TEXTURE)
  @backend.preload_img(MONEY_ASTEROID_TEXTURE)
  @backend.preload_img(HAULER_TEXTURE)
  @backend.preload_img(CRUSTLING_TEXTURE)
  @backend.preload_img(FERRITHARAX_TEXTURE)
  @backend.preload_img(MECHA_FERRITHARAX_TEXTURE)
  @backend.preload_img(MECHA_SAUCETRON_TEXTURE)
  @backend.preload_img(PLAYER_BULLET_TEXTURE)
  @backend.preload_img(PLAYER_BLAST_TEXTURE)
  @backend.preload_img(ENEMY_BULLET_TEXTURE)
  @backend.preload_img(ENEMY_BLAST_TEXTURE)
  @backend.preload_img(CONSUMABLE_MONEY_TEXTURE)
  @backend.preload_img(CONSUMABLE_MONEY3_TEXTURE)
  @backend.preload_img(CONSUMABLE_HEALTH_TEXTURE)
  @backend.preload_img(CONSUMABLE_ARMOR_TEXTURE)
  @backend.preload_img(CONSUMABLE_GAIN_PROJECTILES_TEXTURE)
  @backend.preload_img(ITEM_ENHANCED_PLATING_TEXTURE)
  @backend.preload_img(HEALTH_BAR_LABEL_TEXTURE)
  @backend.preload_img(DEFENSE_BAR_LABEL_TEXTURE)
  @backend.preload_img(WARNING_GRADIENT_TEXTURE)
  @backend.preload_img(DEFENSE_GRADIENT_TEXTURE)
  @backend.preload_img(ABILITY_SQUARE_LEFT_TEXTURE)
  @backend.preload_img(BLAST_ABILITY_TEXTURE)
  @backend.preload_img(BULLET_ABILITY_TEXTURE)
  @backend.preload_img(MEGABLAST_ABILITY_TEXTURE)
  @backend.preload_img(CHARGE_ABILITY_TEXTURE)
  for texture in game_background_textures {
    @backend.preload_img(texture)
  }
  @backend.load_font(FONT_LUNCHDS_ALIAS, FONT_LUNCHDS_PATH)
  @backend.load_font(FONT_SPACE_MADNESS_ALIAS, FONT_SPACE_MADNESS_PATH)
  @backend.load_font(FONT_WIBLETOWN_ALIAS, FONT_WIBLETOWN_PATH)
  @backend.preload_audio(MUSIC_GAME_LOOP)
  @backend.preload_audio(SFX_PLAYER_FIRE)
  @backend.preload_audio(SFX_ENEMY_FIRE)
  @backend.preload_audio(SFX_PLAYER_HIT)
  @backend.preload_audio(SFX_DEFENSE_DAMAGE)
  @backend.preload_audio(SFX_DEFENSE_HEAL)
  @backend.preload_audio(SFX_MEGABLAST)
  @backend.preload_audio(SFX_CONSUMABLE_PICKUP)
  @backend.preload_audio(SFX_MENU_INPUT_SUCCESS)
}

///|
fn initialize_scene() -> Unit {
  let entity = game_state.background
  if !entity.is_alive() {
    entity.respawn()
  }
  set_background(Menu)
}

///|
fn set_background(kind : BackgroundKind) -> Unit {
  if game_state.background_kind == kind &&
    @sprite.sprites.get(game_state.background) is Some(_) {
    return
  }
  game_state.background_kind = kind
  let sprite = if kind is Game {
    background_sprite_by_texture(random_game_background_texture())
  } else {
    background_sprite(kind)
  }
  @sprite.sprites.set(game_state.background, sprite)
  @transform.positions.set(game_state.background, @math.Vec2D(0.0, 0.0))
}

///|
fn random_game_background_texture() -> String {
  let len = game_background_textures.length()
  if len <= 0 {
    return GAME_BG_TEXTURE
  }
  let idx = (game_state.rand.double() * len.to_double()).to_int()
  let idx = clamp_int(idx, 0, len - 1)
  game_background_textures[idx]
}

///|
fn initialize_ui() -> Unit {
  setup_text_entity(
    game_state.score_ui,
    game_state.score_text,
    @math.Vec2D(8.0, 8.0),
  )
  setup_text_entity(
    game_state.hull_ui,
    game_state.hull_text,
    @math.Vec2D(8.0, 28.0),
  )
  setup_text_entity(
    game_state.shield_ui,
    game_state.shield_text,
    @math.Vec2D(8.0, 48.0),
  )
  setup_text_entity(
    game_state.defense_ui,
    game_state.defense_text,
    @math.Vec2D(8.0, 68.0),
  )
  setup_text_entity(
    game_state.stage_ui,
    game_state.stage_text,
    @math.Vec2D(8.0, 88.0),
  )
  setup_text_entity(
    game_state.timer_ui,
    game_state.timer_text,
    @math.Vec2D(VIEWPORT_WIDTH - 150.0, 8.0),
  )
  setup_text_entity(
    game_state.banner_ui,
    game_state.banner_text,
    @math.Vec2D(40.0, VIEWPORT_HEIGHT - 20.0),
  )
  setup_picture_entity(
    game_state.menu_logo_ui,
    menu_logo_sprite(),
    @math.Vec2D(58.0, 16.0),
  )
  setup_picture_entity(
    game_state.menu_button_start_ui,
    menu_button_background_sprite(false),
    @math.Vec2D(160.0, 176.0),
  )
  setup_button_entity(game_state.menu_button_start_ui, @math.Vec2D(160.0, 22.0))
  setup_picture_entity(
    game_state.menu_button_options_ui,
    menu_button_background_sprite(false),
    @math.Vec2D(160.0, 198.0),
  )
  setup_button_entity(
    game_state.menu_button_options_ui,
    @math.Vec2D(160.0, 22.0),
  )
  setup_picture_entity(
    game_state.menu_button_compendium_ui,
    menu_button_background_sprite(false),
    @math.Vec2D(160.0, 220.0),
  )
  setup_button_entity(
    game_state.menu_button_compendium_ui,
    @math.Vec2D(160.0, 22.0),
  )
  setup_picture_entity(
    game_state.menu_button_exit_ui,
    menu_button_background_sprite(false),
    @math.Vec2D(160.0, 242.0),
  )
  setup_button_entity(game_state.menu_button_exit_ui, @math.Vec2D(160.0, 22.0))
  setup_picture_entity(
    game_state.character_portrait_ui,
    character_portrait_sprite(Captain),
    @math.Vec2D(240.0, 118.0),
  )
  setup_picture_entity(
    game_state.character_description_ui,
    character_description_sprite(Captain),
    @math.Vec2D(240.0, 242.0),
  )
  setup_picture_entity(
    game_state.phase_prompt_ui,
    restart_prompt_sprite(),
    @math.Vec2D(240.0, 244.0),
  )
  setup_picture_entity(
    game_state.warning_gradient_ui,
    border_gradient_sprite(WARNING_GRADIENT_TEXTURE, 0.0),
    @math.Vec2D(0.0, VIEWPORT_HEIGHT),
  )
  setup_picture_entity(
    game_state.defense_gradient_ui,
    border_gradient_sprite(DEFENSE_GRADIENT_TEXTURE, 0.0),
    @math.Vec2D(0.0, VIEWPORT_HEIGHT),
  )
  setup_picture_entity(
    game_state.hud_health_label_ui,
    hud_health_label_sprite(),
    @math.Vec2D(16.0, 160.0),
  )
  setup_picture_entity(
    game_state.hud_health_bar_bg_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(
        @math.Vec2D(12.0, 120.0),
        "rgba(128, 16, 24, 0.18)",
      ),
      91,
    ),
    @math.Vec2D(30.0, 98.0),
  )
  setup_picture_entity(
    game_state.hud_health_bar_fill_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(
        @math.Vec2D(10.0, 116.0),
        "rgba(220, 20, 60, 0.85)",
      ),
      92,
    ),
    @math.Vec2D(31.0, 100.0),
  )
  setup_picture_entity(
    game_state.hud_shield_bar_bg_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(12.0, 120.0), "rgba(0, 96, 128, 0.18)"),
      91,
    ),
    @math.Vec2D(46.0, 98.0),
  )
  setup_picture_entity(
    game_state.hud_shield_bar_fill_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(
        @math.Vec2D(10.0, 116.0),
        "rgba(0, 255, 255, 0.75)",
      ),
      92,
    ),
    @math.Vec2D(47.0, 100.0),
  )
  setup_picture_entity(
    game_state.hud_defense_label_ui,
    hud_defense_label_sprite(),
    @math.Vec2D(240.0, 300.0),
  )
  setup_picture_entity(
    game_state.hud_defense_bar_bg_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(120.0, 8.0), "rgba(18, 24, 78, 0.55)"),
      93,
    ),
    @math.Vec2D(180.0, 295.0),
  )
  setup_picture_entity(
    game_state.hud_defense_bar_fill_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(120.0, 8.0), "rgba(40, 110, 255, 0.9)"),
      94,
    ),
    @math.Vec2D(180.0, 295.0),
  )
  setup_picture_entity(
    game_state.hud_slot1_bg_ui,
    hud_ability_slot_sprite(),
    @math.Vec2D(34.0, 248.0),
  )
  setup_picture_entity(
    game_state.hud_slot1_icon_ui,
    hud_ability_icon_sprite(Captain, 1),
    @math.Vec2D(34.0, 248.0),
  )
  setup_picture_entity(
    game_state.hud_slot1_fill_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(64.0, 0.0), "rgba(0, 0, 0, 0.55)"),
      95,
    ),
    @math.Vec2D(2.0, 280.0),
  )
  setup_picture_entity(
    game_state.hud_slot2_bg_ui,
    hud_ability_slot_sprite(),
    @math.Vec2D(34.0, 176.0),
  )
  setup_picture_entity(
    game_state.hud_slot2_icon_ui,
    hud_ability_icon_sprite(Captain, 2),
    @math.Vec2D(34.0, 176.0),
  )
  setup_picture_entity(
    game_state.hud_slot2_fill_ui,
    @sprite.Sprite::from_color_rect(
      @sprite.ColorRect::new(@math.Vec2D(64.0, 0.0), "rgba(0, 0, 0, 0.55)"),
      95,
    ),
    @math.Vec2D(2.0, 208.0),
  )
  if @sprite.sprites.get(game_state.character_portrait_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.character_description_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.phase_prompt_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.warning_gradient_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.defense_gradient_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_health_label_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_health_bar_bg_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_health_bar_fill_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_shield_bar_bg_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_shield_bar_fill_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_defense_label_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_defense_bar_bg_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_defense_bar_fill_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_slot1_bg_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_slot1_icon_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_slot1_fill_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_slot2_bg_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_slot2_icon_ui) is Some(sprite) {
    sprite.visible = false
  }
  if @sprite.sprites.get(game_state.hud_slot2_fill_ui) is Some(sprite) {
    sprite.visible = false
  }
}

///|
fn setup_text_entity(
  entity : @entity.Entity,
  text : @sprite.Text,
  position : @math.Vec2D,
) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
  @sprite.sprites.set(entity, @sprite.Sprite::from_text(text, 100))
  @transform.positions.set(entity, position)
  @ui.uis.set(entity, @ui.Ui::new())
}

///|
fn setup_picture_entity(
  entity : @entity.Entity,
  sprite : @sprite.Sprite,
  position : @math.Vec2D,
) -> Unit {
  if !entity.is_alive() {
    entity.respawn()
  }
  @sprite.sprites.set(entity, sprite)
  @transform.positions.set(entity, position)
  @ui.uis.set(entity, @ui.Ui::new())
}

///|
fn setup_button_entity(entity : @entity.Entity, hit_size : @math.Vec2D) -> Unit {
  @ui.buttons.set(entity, @ui.Button::new(hit_size~))
  @ui.interactions.set(entity, @ui.None)
}

///|
fn enter_main_menu() -> Unit {
  clear_dynamic_entities()
  game_state.screen = MainMenu
  game_state.phase = Playing
  game_state.main_menu_selected = 0
  set_background(Menu)
  if !game_state.music_started {
    @audio.play_audio(MUSIC_GAME_LOOP, volume=0.35, loop_=true)
    game_state.music_started = true
  }
}

///|
fn enter_character_selection() -> Unit {
  clear_dynamic_entities()
  game_state.screen = CharacterSelection
  game_state.phase = Playing
  set_background(CharacterSelection)
}

///|
fn start_game_with_selected_character() -> Unit {
  game_state.screen = InGame
  set_background(Game)
  reset_run()
}

///|
fn reset_run() -> Unit {
  clear_dynamic_entities()
  reset_game_state_data()
  apply_character(game_state.selected_character)
  spawn_player()
  enter_stage()
}

///|
fn clear_dynamic_entities() -> Unit {
  let enemies_to_clear = []
  for enemy_entity, _ in enemies {
    enemies_to_clear.push(enemy_entity)
  }
  for enemy_entity in enemies_to_clear {
    despawn_enemy(enemy_entity)
  }

  let bullets_to_clear = []
  for bullet_entity, _ in bullets {
    bullets_to_clear.push(bullet_entity)
  }
  for bullet_entity in bullets_to_clear {
    despawn_bullet(bullet_entity)
  }

  let consumables_to_clear = []
  for consumable_entity, _ in consumables {
    consumables_to_clear.push(consumable_entity)
  }
  for consumable_entity in consumables_to_clear {
    despawn_consumable(consumable_entity)
  }

  let items_to_clear = []
  for item_entity, _ in items {
    items_to_clear.push(item_entity)
  }
  for item_entity in items_to_clear {
    despawn_item(item_entity)
  }
}

///|
fn reset_game_state_data() -> Unit {
  game_state.phase = Playing
  game_state.score = 0
  game_state.shots_fired = 0
  game_state.shots_hit = 0
  game_state.enemies_destroyed = 0
  game_state.money = 0
  game_state.armor = 0
  game_state.defense = 100
  game_state.elapsed = 0.0
  game_state.stage_index = 0
  game_state.stage_elapsed = 0.0
  game_state.stage_spawn_timer = 0.0
  game_state.stage_label = ""
  game_state.boss_spawned = false
  game_state.plating_count = 0
  game_state.allow_move = true
  game_state.allow_main_attack = true
  game_state.allow_special = true
  game_state.tutorial_lesson = 0
  game_state.tutorial_up_progress = 0.0
  game_state.tutorial_down_progress = 0.0
  game_state.tutorial_left_progress = 0.0
  game_state.tutorial_right_progress = 0.0
  game_state.tutorial_up_left_progress = 0.0
  game_state.tutorial_up_right_progress = 0.0
  game_state.tutorial_down_left_progress = 0.0
  game_state.tutorial_down_right_progress = 0.0
  game_state.tutorial_slot1_destroy = 0
  game_state.tutorial_slot1_protect = 0
  game_state.tutorial_slot2_destroy = 0
  game_state.tutorial_spawn_timer = 0.0
  game_state.center_intro_text = ""
  game_state.center_intro_timer = 0.0
  game_state.warning_gradient_timer = 0.0
  game_state.defense_gradient_timer = 0.0
  game_state.shoot_cooldown = 0.0
  game_state.special_cooldown = 0.0
  game_state.player_invulnerable = 0.0
  game_state.charge_time_left = 0.0
  game_state.charge_velocity = @math.Vec2D(0.0, 0.0)
}

///|
fn apply_character(character : CharacterType) -> Unit {
  let config = character_config(character)
  game_state.max_hull = config.max_hull
  game_state.hull = config.max_hull
  game_state.max_shield = config.max_shield
  game_state.shield = config.max_shield
  game_state.shield_recharge_rate = config.shield_recharge_rate
  game_state.shield_recharge_delay = 0.0
  game_state.shield_recharge_progress = 0.0
  game_state.attraction_distance = config.attraction_distance
  game_state.attraction_acceleration = config.attraction_acceleration
  game_state.base_cooldown_multiplier = config.base_cooldown_multiplier
  game_state.cooldown_multiplier = config.base_cooldown_multiplier
  game_state.player_speed = config.speed
  game_state.shoot_interval = config.shoot_interval
  game_state.special_cooldown_base = config.special_cooldown
  game_state.projectile_kind = config.projectile_kind
  game_state.projectile_speed = config.projectile_speed
  game_state.projectile_damage = config.projectile_damage
  game_state.projectile_ttl = config.projectile_ttl
  game_state.special_ability = config.special_ability
  game_state.projectile_count = if character is Juggernaut { 3 } else { 1 }
  refresh_cooldown_multiplier()
}

///|
fn spawn_player() -> Unit {
  let entity = game_state.player
  if !entity.is_alive() {
    entity.respawn()
  }
  @sprite.sprites.set(entity, player_sprite(game_state.selected_character))
  @transform.positions.set(entity, initial_player_position())
}

///|
fn spawn_enemy(kind : EnemyKind, spawn_pos : @math.Vec2D) -> Unit {
  let enemy_entity = @entity.Entity::new()
  let archetype = enemy_archetype(kind)
  let hp_bonus = if kind is Missile ||
    kind is MoneyAsteroid ||
    kind is TutorialDrone ||
    kind is Hauler ||
    kind is Ferritharax ||
    kind is MechaFerritharax ||
    kind is MechaSaucetron {
    0
  } else {
    (game_state.elapsed / 45.0).to_int() * 3
  }
  let speed_bonus = game_state.stage_index.to_double() * 4.0
  let speed_x = if archetype.speed_x <= 0.0 {
    0.0
  } else {
    archetype.speed_x + speed_bonus
  }
  let speed_y = if kind is Missile {
    archetype.speed_y + game_state.stage_index.to_double() * 8.0
  } else if kind is Ferritharax ||
    kind is MechaFerritharax ||
    kind is MechaSaucetron {
    archetype.speed_y
  } else {
    archetype.speed_y + speed_bonus
  }
  @sprite.sprites.set(enemy_entity, enemy_sprite(kind))
  @transform.positions.set(enemy_entity, spawn_pos)
  enemies.set(enemy_entity, {
    kind,
    hp: archetype.hp + hp_bonus,
    speed_x,
    speed_y,
    collision_damage: archetype.collision_damage,
    escape_defense_delta: archetype.escape_defense_delta,
    movement: archetype.movement,
    horizontal_dir: archetype.horizontal_dir,
    shooter: archetype.shooter,
    shoot_interval: archetype.shoot_interval,
    shoot_cooldown: archetype.initial_shoot_delay,
  })
}

///|
fn spawn_player_burst() -> Unit {
  guard @transform.positions.get(game_state.player) is Some(player_position)
  let projectile_count = @cmp.maximum(1, game_state.projectile_count)
  let base = @math.Vec2D(
    player_position.0[X],
    player_position.0[Y] - PLAYER_HALF_SIZE - 2.0,
  )
  match game_state.projectile_kind {
    Blast => {
      let spread = 1.5708
      for i in 0..<projectile_count {
        let t = if projectile_count <= 1 {
          0.5
        } else {
          i.to_double() / (projectile_count - 1).to_double()
        }
        let angle = -1.5708 + (t - 0.5) * spread
        let velocity = @math.Vec2D(
          @cmath.cos(angle) * game_state.projectile_speed,
          @cmath.sin(angle) * game_state.projectile_speed,
        )
        spawn_player_projectile(
          base + @math.Vec2D((t - 0.5) * 8.0, 0.0),
          velocity,
          game_state.projectile_damage,
          Blast,
          game_state.projectile_ttl,
        )
      }
    }
    Bullet =>
      for i in 0..<projectile_count {
        let offset = (i.to_double() - (projectile_count - 1).to_double() / 2.0) *
          1.5
        let angle = -1.5708 + (game_state.rand.double() - 0.5) * 0.1884
        let speed = game_state.projectile_speed *
          (0.75 + game_state.rand.double() * 0.5)
        let velocity = @math.Vec2D(
          @cmath.cos(angle) * speed,
          @cmath.sin(angle) * speed,
        )
        spawn_player_projectile(
          base + @math.Vec2D(offset, 0.0),
          velocity,
          game_state.projectile_damage,
          Bullet,
          game_state.projectile_ttl,
        )
      }
  }
  @audio.play_audio(SFX_PLAYER_FIRE, volume=0.18)
}

///|
fn spawn_player_projectile(
  start_pos : @math.Vec2D,
  velocity : @math.Vec2D,
  damage : Int,
  kind : ProjectileKind,
  ttl : Double,
) -> Unit {
  game_state.shots_fired += 1
  spawn_projectile(start_pos, velocity, damage, kind, Ally, ttl)
}

///|
fn spawn_enemy_projectile(
  start_pos : @math.Vec2D,
  velocity : @math.Vec2D,
  damage : Int,
  kind : ProjectileKind,
  ttl : Double,
) -> Unit {
  spawn_projectile(start_pos, velocity, damage, kind, Enemy, ttl)
}

///|
fn spawn_projectile(
  start_pos : @math.Vec2D,
  velocity : @math.Vec2D,
  damage : Int,
  kind : ProjectileKind,
  faction : BulletFaction,
  ttl : Double,
) -> Unit {
  let bullet_entity = @entity.Entity::new()
  @sprite.sprites.set(bullet_entity, projectile_sprite(kind, faction))
  @transform.positions.set(bullet_entity, start_pos)
  let radius = if kind is Blast { 5.0 } else { 4.0 }
  bullets.set(bullet_entity, { ttl, velocity, damage, faction, radius })
}

///|
fn spawn_consumable(kind : ConsumableKind, position : @math.Vec2D) -> Unit {
  let entity = @entity.Entity::new()
  @sprite.sprites.set(entity, consumable_sprite(kind))
  @transform.positions.set(entity, position)
  consumables.set(entity, { kind, speed: 105.0 })
}

///|
fn spawn_item(kind : ItemKind, position : @math.Vec2D) -> Unit {
  let entity = @entity.Entity::new()
  @sprite.sprites.set(entity, item_sprite(kind))
  @transform.positions.set(entity, position)
  items.set(entity, { kind, speed: 105.0 })
}

///|
fn despawn_enemy(enemy_entity : @entity.Entity) -> Unit {
  enemies.remove(enemy_entity)
  @sprite.sprites.remove(enemy_entity)
  @transform.positions.remove(enemy_entity)
  if enemy_entity.is_alive() {
    enemy_entity.destroy()
  }
}

///|
fn despawn_bullet(bullet_entity : @entity.Entity) -> Unit {
  bullets.remove(bullet_entity)
  @sprite.sprites.remove(bullet_entity)
  @transform.positions.remove(bullet_entity)
  if bullet_entity.is_alive() {
    bullet_entity.destroy()
  }
}

///|
fn despawn_consumable(entity : @entity.Entity) -> Unit {
  consumables.remove(entity)
  @sprite.sprites.remove(entity)
  @transform.positions.remove(entity)
  if entity.is_alive() {
    entity.destroy()
  }
}

///|
fn despawn_item(entity : @entity.Entity) -> Unit {
  items.remove(entity)
  @sprite.sprites.remove(entity)
  @transform.positions.remove(entity)
  if entity.is_alive() {
    entity.destroy()
  }
}

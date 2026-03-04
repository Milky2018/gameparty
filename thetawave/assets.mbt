///|
const MENU_BG_TEXTURE : String = "thetawave/assets/texture/main_menu_background_54.png"

///|
const CHARACTER_SELECT_BG_TEXTURE : String = "thetawave/assets/texture/character_selection_54.png"

///|
const GAME_BG_TEXTURE : String = "thetawave/assets/texture/main_menu_background_54.png"

///|
const CAPTAIN_TEXTURE : String = "thetawave/assets/texture/captain_character.png"

///|
const JUGGERNAUT_TEXTURE : String = "thetawave/assets/texture/captain_character_outline.png"

///|
const PAWN_TEXTURE : String = "thetawave/assets/texture/pawn_spritesheet.png"

///|
const DRONE_TEXTURE : String = "thetawave/assets/texture/drone_spritesheet.png"

///|
const SHELLY_TEXTURE : String = "thetawave/assets/texture/shelly_spritesheet.png"

///|
const STRAFER_TEXTURE : String = "thetawave/assets/texture/strafer_spritesheet.png"

///|
const MISSILE_LAUNCHER_TEXTURE : String = "thetawave/assets/texture/missile_launcher_spritesheet.png"

///|
const MISSILE_TEXTURE : String = "thetawave/assets/texture/missile_spritesheet.png"

///|
const MONEY_ASTEROID_TEXTURE : String = "thetawave/assets/texture/money_asteroid_spritesheet.png"

///|
const HAULER_TEXTURE : String = "thetawave/assets/texture/hauler_front.png"

///|
const FERRITHARAX_TEXTURE : String = "thetawave/assets/texture/hauler_middle.png"

///|
const MECHA_FERRITHARAX_TEXTURE : String = "thetawave/assets/texture/hauler_back.png"

///|
const MECHA_SAUCETRON_TEXTURE : String = "thetawave/assets/texture/hauler_front.png"

///|
const PLAYER_BULLET_TEXTURE : String = "thetawave/assets/texture/ally_bullet.png"

///|
const PLAYER_BLAST_TEXTURE : String = "thetawave/assets/texture/ally_blast.png"

///|
const ENEMY_BULLET_TEXTURE : String = "thetawave/assets/texture/enemy_bullet.png"

///|
const ENEMY_BLAST_TEXTURE : String = "thetawave/assets/texture/enemy_blast.png"

///|
const CONSUMABLE_MONEY_TEXTURE : String = "thetawave/assets/texture/money1_spritesheet.png"

///|
const CONSUMABLE_MONEY3_TEXTURE : String = "thetawave/assets/texture/money5_spritesheet.png"

///|
const CONSUMABLE_HEALTH_TEXTURE : String = "thetawave/assets/texture/health_wrench_spritesheet.png"

///|
const CONSUMABLE_ARMOR_TEXTURE : String = "thetawave/assets/texture/armor_spritesheet.png"

///|
const CONSUMABLE_GAIN_PROJECTILES_TEXTURE : String = "thetawave/assets/texture/power_glow.png"

///|
const ITEM_ENHANCED_PLATING_TEXTURE : String = "thetawave/assets/texture/power_label.png"

///|
const SFX_PLAYER_FIRE : String = "thetawave/assets/sounds/player_fire_blast.wav"

///|
const SFX_ENEMY_FIRE : String = "thetawave/assets/sounds/enemy_fire_blast.wav"

///|
const SFX_DEFENSE_HEAL : String = "thetawave/assets/sounds/defense_heal.wav"

///|
const SFX_DEFENSE_DAMAGE : String = "thetawave/assets/sounds/defense_damage.wav"

///|
const SFX_PLAYER_HIT : String = "thetawave/assets/sounds/player_hit.wav"

///|
const SFX_MEGABLAST : String = "thetawave/assets/sounds/megablast_ability.wav"

///|
const SFX_CONSUMABLE_PICKUP : String = "thetawave/assets/sounds/consumable_pickup.wav"

///|
const MUSIC_GAME_LOOP : String = "thetawave/assets/sounds/deflector_soundtrack.mp3"

///|
fn player_sprite(character : CharacterType) -> @sprite.Sprite {
  let texture = match character {
    Captain => CAPTAIN_TEXTURE
    Juggernaut => JUGGERNAUT_TEXTURE
  }
  @sprite.Sprite::from_picture(
    @sprite.Picture::new(@math.Vec2D(32.0, 32.0), texture),
    20,
    offset=@math.Vec2D(-16.0, -16.0),
  )
}

///|
fn enemy_sprite(kind : EnemyKind) -> @sprite.Sprite {
  match kind {
    Pawn =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(20.0, 20.0), PAWN_TEXTURE),
        10,
        offset=@math.Vec2D(-10.0, -10.0),
      )
    Drone =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(20.0, 20.0), DRONE_TEXTURE),
        10,
        offset=@math.Vec2D(-10.0, -10.0),
      )
    Shelly =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(24.0, 25.0), SHELLY_TEXTURE),
        10,
        offset=@math.Vec2D(-12.0, -12.5),
      )
    StraferRight =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(26.0, 14.0), STRAFER_TEXTURE),
        10,
        offset=@math.Vec2D(-13.0, -7.0),
      )
    StraferLeft =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(26.0, 14.0), STRAFER_TEXTURE),
        10,
        offset=@math.Vec2D(-13.0, -7.0),
      )
    MissileLauncher =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(23.0, 28.0), MISSILE_LAUNCHER_TEXTURE),
        10,
        offset=@math.Vec2D(-11.5, -14.0),
      )
    Missile =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(11.0, 20.0), MISSILE_TEXTURE),
        11,
        offset=@math.Vec2D(-5.5, -10.0),
      )
    MoneyAsteroid =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(21.0, 21.0), MONEY_ASTEROID_TEXTURE),
        9,
        offset=@math.Vec2D(-10.5, -10.5),
      )
    CrustlingRight =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(24.0, 25.0), SHELLY_TEXTURE),
        10,
        offset=@math.Vec2D(-12.0, -12.5),
      )
    CrustlingLeft =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(24.0, 25.0), SHELLY_TEXTURE),
        10,
        offset=@math.Vec2D(-12.0, -12.5),
      )
    Ferritharax =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(18.0, 26.0), FERRITHARAX_TEXTURE),
        12,
        offset=@math.Vec2D(-9.0, -13.0),
      )
    MechaFerritharax =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(18.0, 24.0), MECHA_FERRITHARAX_TEXTURE),
        12,
        offset=@math.Vec2D(-9.0, -12.0),
      )
    MechaSaucetron =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(18.0, 15.0), MECHA_SAUCETRON_TEXTURE),
        12,
        offset=@math.Vec2D(-9.0, -7.5),
      )
    Hauler =>
      @sprite.Sprite::from_picture(
        @sprite.Picture::new(@math.Vec2D(18.0, 15.0), HAULER_TEXTURE),
        11,
        offset=@math.Vec2D(-9.0, -7.5),
      )
  }
}

///|
fn projectile_sprite(
  kind : ProjectileKind,
  faction : BulletFaction,
) -> @sprite.Sprite {
  let texture = match faction {
    Ally =>
      match kind {
        Blast => PLAYER_BLAST_TEXTURE
        Bullet => PLAYER_BULLET_TEXTURE
      }
    Enemy =>
      match kind {
        Blast => ENEMY_BLAST_TEXTURE
        Bullet => ENEMY_BULLET_TEXTURE
      }
  }
  let size = match kind {
    Blast => @math.Vec2D(10.0, 10.0)
    Bullet => @math.Vec2D(8.0, 12.0)
  }
  @sprite.Sprite::from_picture(
    @sprite.Picture::new(size, texture),
    30,
    offset=@math.Vec2D(-size[X] / 2.0, -size[Y] / 2.0),
  )
}

///|
fn consumable_sprite(kind : ConsumableKind) -> @sprite.Sprite {
  let (texture, size) = match kind {
    Money1 => (CONSUMABLE_MONEY_TEXTURE, @math.Vec2D(12.0, 12.0))
    Money3 => (CONSUMABLE_MONEY3_TEXTURE, @math.Vec2D(14.0, 14.0))
    HealthWrench => (CONSUMABLE_HEALTH_TEXTURE, @math.Vec2D(16.0, 16.0))
    Armor => (CONSUMABLE_ARMOR_TEXTURE, @math.Vec2D(16.0, 16.0))
    GainProjectiles =>
      (CONSUMABLE_GAIN_PROJECTILES_TEXTURE, @math.Vec2D(14.0, 14.0))
  }
  @sprite.Sprite::from_picture(
    @sprite.Picture::new(size, texture),
    18,
    offset=@math.Vec2D(-size[X] / 2.0, -size[Y] / 2.0),
  )
}

///|
fn item_sprite(kind : ItemKind) -> @sprite.Sprite {
  let (texture, size) = match kind {
    EnhancedPlating => (ITEM_ENHANCED_PLATING_TEXTURE, @math.Vec2D(24.0, 10.0))
  }
  @sprite.Sprite::from_picture(
    @sprite.Picture::new(size, texture),
    19,
    offset=@math.Vec2D(-size[X] / 2.0, -size[Y] / 2.0),
  )
}

///|
fn background_sprite(kind : BackgroundKind) -> @sprite.Sprite {
  let texture = match kind {
    Menu => MENU_BG_TEXTURE
    CharacterSelection => CHARACTER_SELECT_BG_TEXTURE
    Game => GAME_BG_TEXTURE
  }
  @sprite.Sprite::from_picture(
    @sprite.Picture::new(@math.Vec2D(VIEWPORT_WIDTH, VIEWPORT_HEIGHT), texture),
    -100,
  )
}

///|
let asset_path_prefixes : Array[String] = [
  "", "/Users/zhengyu/Documents/projects/gameparty/",
]

///|
fn resolved_asset_path(path : String) -> String {
  for prefix in asset_path_prefixes {
    let candidate = "\{prefix}\{path}"
    if @asset.read_bytes(candidate) is Some(_) {
      return candidate
    }
  }
  path
}

///|
fn register_font_once() -> Unit {
  if coinpusher_font_registered.val {
    return
  }
  ignore(
    @asset.load_font(resolved_asset_path(HUD_FONT_PATH), family=HUD_FONT_FAMILY),
  )
  coinpusher_font_registered.val = true
}

///|
fn load_audio(path : String) -> @asset.AudioHandle {
  @asset.load_audio(resolved_asset_path(path))
}

///|
fn play_audio(
  path : String,
  volume? : Double = 1.0,
  loop_? : Bool = false,
) -> Unit {
  let source = load_audio(path)
  if loop_ {
    ignore(
      @audio.spawn_audio(
        source,
        settings=@audio.PlaybackSettings::looped().with_volume(volume),
      ),
    )
  } else {
    @audio.play_one_shot(source, volume~)
  }
}

///|
fn ensure_music_started() -> Unit {
  if music_started.val {
    return
  }
  play_audio(MUSIC_RUN_LOOP_PATH, volume=0.25, loop_=true)
  music_started.val = true
}

///|
fn material_from_texture(
  texture_path : String,
  base_color : @render.Color,
  roughness? : Double = 1.0,
  metallic? : Double = 0.0,
  emissive? : @render.Color = { r: 0U, g: 0U, b: 0U, a: 1.0 },
) -> @render3d.MaterialHandle {
  let image = @render3d.register_image_asset({
    path: resolved_asset_path(texture_path),
  })
  @render3d.register_material_asset({
    ..@render3d.default_standard_material3d(),
    base_color,
    base_color_texture: Some(@render3d.texture_binding3d(image)),
    roughness,
    metallic,
    emissive_color: emissive,
  })
}

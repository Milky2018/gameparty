///|
fn play_audio(
  path : String,
  volume? : Double = 1.0,
  loop_? : Bool = false,
) -> Unit {
  let source = @asset.load_audio(path)
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

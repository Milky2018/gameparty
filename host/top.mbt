///|
pub(all) struct Sound(Int)

///|
pub fn prepare_run(_hidden_window : Bool) -> Unit {
  ()
}

///|
pub fn take_screenshot(_path : String) -> Unit {
  ()
}

///|
pub fn exit_fullscreen_if_needed() -> Unit {
  ()
}

///|
pub fn is_key_pressed(_key : String) -> Bool {
  false
}

///|
pub fn drain_text_input_codepoints() -> Array[Int] {
  []
}

///|
pub fn sound_from_wav_bytes(_wav_bytes : Bytes) -> Sound {
  Sound(0)
}

///|
pub fn play_sound(_sound : Sound) -> Unit {
  ()
}

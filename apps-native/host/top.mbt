///|
pub(all) struct Sound {
  raw : @raylib.Sound
}

///|
fn native_key(key : String) -> Int {
  match key {
    "F2" => @raylib.KeyF2
    "F3" => @raylib.KeyF3
    "Digit1" => @raylib.KeyOne
    "Digit2" => @raylib.KeyTwo
    "Digit3" => @raylib.KeyThree
    "Backspace" => @raylib.KeyBackspace
    "Apostrophe" => @raylib.KeyApostrophe
    _ => @raylib.KeyNull
  }
}

///|
pub fn prepare_run(hidden_window : Bool) -> Unit {
  if hidden_window {
    @raylib.set_config_flags(@raylib.FlagWindowHidden)
  }
  @raylib.set_trace_log_level(@raylib.LogError)
}

///|
pub fn take_screenshot(path : String) -> Unit {
  @raylib.take_screenshot(path)
}

///|
pub fn exit_fullscreen_if_needed() -> Unit {
  if @raylib.is_window_fullscreen() {
    @raylib.clear_window_state(@raylib.FlagFullscreenMode)
  }
}

///|
pub fn is_key_pressed(key : String) -> Bool {
  @raylib.is_key_pressed(native_key(key))
}

///|
pub fn drain_text_input_codepoints() -> Array[Int] {
  let codes : Array[Int] = []
  let mut code = @raylib.get_char_pressed()
  while code > 0 {
    codes.push(code)
    code = @raylib.get_char_pressed()
  }
  codes
}

///|
pub fn sound_from_wav_bytes(wav_bytes : Bytes) -> Sound {
  let wave = @raylib.Wave::load_from_memory(
    ".wav",
    wav_bytes,
    wav_bytes.length(),
  )
  let sound = wave.load_sound()
  wave.unload()
  { raw: sound }
}

///|
pub fn play_sound(sound : Sound) -> Unit {
  sound.raw.play()
}

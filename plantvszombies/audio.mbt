///|
fn append_u8(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(value.to_byte())
}

///|
fn append_u16_le(bytes : Array[Byte], value : Int) -> Unit {
  append_u8(bytes, value & 0xFF)
  append_u8(bytes, (value >> 8) & 0xFF)
}

///|
fn append_i16_le(bytes : Array[Byte], value : Int) -> Unit {
  let signed = if value < 0 { value + 0x10000 } else { value }
  append_u16_le(bytes, signed)
}

///|
fn append_u32_le(bytes : Array[Byte], value : Int) -> Unit {
  append_u8(bytes, value & 0xFF)
  append_u8(bytes, (value >> 8) & 0xFF)
  append_u8(bytes, (value >> 16) & 0xFF)
  append_u8(bytes, (value >> 24) & 0xFF)
}

///|
fn wav_header(sample_count : Int, sample_rate : Int) -> Array[Byte] {
  let bytes : Array[Byte] = []
  let data_size = sample_count * 2
  let byte_rate = sample_rate * 2
  let block_align = 2
  append_u8(bytes, 'R'.to_int())
  append_u8(bytes, 'I'.to_int())
  append_u8(bytes, 'F'.to_int())
  append_u8(bytes, 'F'.to_int())
  append_u32_le(bytes, 36 + data_size)
  append_u8(bytes, 'W'.to_int())
  append_u8(bytes, 'A'.to_int())
  append_u8(bytes, 'V'.to_int())
  append_u8(bytes, 'E'.to_int())
  append_u8(bytes, 'f'.to_int())
  append_u8(bytes, 'm'.to_int())
  append_u8(bytes, 't'.to_int())
  append_u8(bytes, ' '.to_int())
  append_u32_le(bytes, 16)
  append_u16_le(bytes, 1)
  append_u16_le(bytes, 1)
  append_u32_le(bytes, sample_rate)
  append_u32_le(bytes, byte_rate)
  append_u16_le(bytes, block_align)
  append_u16_le(bytes, 16)
  append_u8(bytes, 'd'.to_int())
  append_u8(bytes, 'a'.to_int())
  append_u8(bytes, 't'.to_int())
  append_u8(bytes, 'a'.to_int())
  append_u32_le(bytes, data_size)
  bytes
}

///|
fn make_tone_bytes(
  freqs : Array[Double],
  duration : Double,
  sample_rate : Int,
) -> Bytes {
  let sample_count = (duration * sample_rate.to_double()).to_int()
  let bytes = wav_header(sample_count, sample_rate)
  let mut i = 0
  while i < sample_count {
    let t = i.to_double() / sample_rate.to_double()
    let attack = clamp_double(t / 0.015, 0.0, 1.0)
    let release = clamp_double((duration - t) / 0.04, 0.0, 1.0)
    let env = attack * release
    let mut mix = 0.0
    for freq in freqs {
      mix += @cmath.sin(2.0 * @cmath.PI * freq * t)
    }
    if !freqs.is_empty() {
      mix /= freqs.length().to_double()
    }
    let sample = env * 12000.0 * mix
    let clamped = clamp_int(sample.round().to_int(), -30000, 30000)
    append_i16_le(bytes, clamped)
    i += 1
  }
  Bytes::from_array(bytes)
}

///|
fn make_tone_sound(freqs : Array[Double], duration : Double) -> @raylib.Sound {
  let sample_rate = 22050
  let bytes = make_tone_bytes(freqs, duration, sample_rate)
  let wave = @raylib.Wave::load_from_memory(".wav", bytes, bytes.length())
  let sound = wave.load_sound()
  wave.unload()
  sound
}

///|
fn init_sound_bank() -> Unit {
  if place_sound.val is Some(_) {
    return
  }
  place_sound.val = Some(make_tone_sound([740.0], 0.08))
  shoot_sound.val = Some(make_tone_sound([420.0], 0.10))
  hit_sound.val = Some(make_tone_sound([220.0], 0.09))
  kill_sound.val = Some(make_tone_sound([160.0, 240.0], 0.13))
  sun_sound.val = Some(make_tone_sound([980.0], 0.07))
  win_sound.val = Some(make_tone_sound([523.25, 659.25, 783.99], 0.18))
  lose_sound.val = Some(make_tone_sound([180.0, 140.0], 0.20))
}

///|
fn play_sound(sound : @raylib.Sound?) -> Unit {
  match sound {
    Some(value) => value.play()
    None => ()
  }
}

///|
fn play_fx(kind : SoundKind) -> Unit {
  match kind {
    Place => play_sound(place_sound.val)
    Shoot => play_sound(shoot_sound.val)
    Hit => play_sound(hit_sound.val)
    Kill => play_sound(kill_sound.val)
    Sun => play_sound(sun_sound.val)
    Win => play_sound(win_sound.val)
    Lose => play_sound(lose_sound.val)
  }
}

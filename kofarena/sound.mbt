///|
fn push_byte(buf : Array[Byte], value : Int) -> Unit {
  buf.push(value.to_byte())
}

///|
fn push_u16_le(buf : Array[Byte], value : Int) -> Unit {
  push_byte(buf, value & 0xFF)
  push_byte(buf, (value >> 8) & 0xFF)
}

///|
fn push_u32_le(buf : Array[Byte], value : Int) -> Unit {
  push_byte(buf, value & 0xFF)
  push_byte(buf, (value >> 8) & 0xFF)
  push_byte(buf, (value >> 16) & 0xFF)
  push_byte(buf, (value >> 24) & 0xFF)
}

///|
fn push_ascii_fourcc(
  buf : Array[Byte],
  a : Int,
  b : Int,
  c : Int,
  d : Int,
) -> Unit {
  push_byte(buf, a)
  push_byte(buf, b)
  push_byte(buf, c)
  push_byte(buf, d)
}

///|
fn clamp_double(value : Double, min_ : Double, max_ : Double) -> Double {
  if value < min_ {
    min_
  } else if value > max_ {
    max_
  } else {
    value
  }
}

///|
fn tone_bytes(tone : AudioTone) -> Bytes {
  let sample_count = @cmath.round(tone.duration * AUDIO_SAMPLE_RATE.to_double()).to_int()
  let data_size = sample_count * 2
  let byte_rate = AUDIO_SAMPLE_RATE * 2
  let block_align = 2
  let buf : Array[Byte] = []

  push_ascii_fourcc(buf, 82, 73, 70, 70)
  push_u32_le(buf, 36 + data_size)
  push_ascii_fourcc(buf, 87, 65, 86, 69)
  push_ascii_fourcc(buf, 102, 109, 116, 32)
  push_u32_le(buf, 16)
  push_u16_le(buf, 1)
  push_u16_le(buf, 1)
  push_u32_le(buf, AUDIO_SAMPLE_RATE)
  push_u32_le(buf, byte_rate)
  push_u16_le(buf, block_align)
  push_u16_le(buf, 8)
  push_ascii_fourcc(buf, 100, 97, 116, 97)
  push_u32_le(buf, data_size)

  let tau = 6.283185307179586
  for i in 0..<sample_count {
    let t = i.to_double() / AUDIO_SAMPLE_RATE.to_double()
    let progress = i.to_double() / sample_count.to_double()
    let attack = if progress < 0.12 { progress / 0.12 } else { 1.0 }
    let release = if progress > 0.72 {
      1.0 - (progress - 0.72) / 0.28
    } else {
      1.0
    }
    let env = clamp_double(attack * release, 0.0, 1.0)
    let wave = @cmath.sin(tau * tone.freq * t)
    let sample = clamp_double(wave * tone.amplitude * env, -1.0, 1.0)
    let pcm = (sample * 32767.0).to_int()
    let normalized = if pcm < 0 { 65536 + pcm } else { pcm }
    push_u16_le(buf, normalized)
  }

  Bytes::from_array(buf)
}

///|
fn load_tone_sound(tone : AudioTone) -> @raylib.Sound {
  let bytes = tone_bytes(tone)
  let wave = @raylib.Wave::load_from_memory("wav", bytes, bytes.length())
  let sound = wave.load_sound()
  wave.unload()
  sound
}

///|
fn register_sounds_once() -> Unit {
  if sound_set.punch is Some(_) {
    return
  }
  if capture_enabled.val {
    return
  }
  sound_set.punch = Some(
    load_tone_sound({
      freq: 196.0,
      duration: AUDIO_DURATION_PUNCH,
      amplitude: 0.45,
    }),
  )
  sound_set.hit = Some(
    load_tone_sound({
      freq: 124.0,
      duration: AUDIO_DURATION_HIT,
      amplitude: 0.55,
    }),
  )
  sound_set.ko = Some(
    load_tone_sound({ freq: 82.0, duration: AUDIO_DURATION_KO, amplitude: 0.65 }),
  )
}

///|
fn play_sound(sound : @raylib.Sound?) -> Unit {
  match sound {
    Some(value) => value.play()
    None => ()
  }
}

///|
fn play_punch_sound() -> Unit {
  play_sound(sound_set.punch)
}

///|
fn play_hit_sound() -> Unit {
  play_sound(sound_set.hit)
}

///|
fn play_ko_sound() -> Unit {
  play_sound(sound_set.ko)
}

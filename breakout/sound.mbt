///|
let sound_serve : Ref[@host.Sound?] = { val: None }

///|
let sound_paddle : Ref[@host.Sound?] = { val: None }

///|
let sound_wall : Ref[@host.Sound?] = { val: None }

///|
let sound_brick : Ref[@host.Sound?] = { val: None }

///|
let sound_life_lost : Ref[@host.Sound?] = { val: None }

///|
let sound_pickup : Ref[@host.Sound?] = { val: None }

///|
let sound_laser : Ref[@host.Sound?] = { val: None }

///|
let sound_win : Ref[@host.Sound?] = { val: None }

///|
let sound_game_over : Ref[@host.Sound?] = { val: None }

///|
fn push_u16_le(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push((value & 0xFF).to_byte())
  bytes.push(((value >> 8) & 0xFF).to_byte())
}

///|
fn push_u8(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(value.to_byte())
}

///|
fn push_u32_le(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push((value & 0xFF).to_byte())
  bytes.push(((value >> 8) & 0xFF).to_byte())
  bytes.push(((value >> 16) & 0xFF).to_byte())
  bytes.push(((value >> 24) & 0xFF).to_byte())
}

///|
fn push_i16_le(bytes : Array[Byte], value : Int) -> Unit {
  let normalized = if value < 0 { value + 65536 } else { value }
  push_u16_le(bytes, normalized)
}

///|
fn synth_dual_tone_wav_bytes(
  freq_a_hz : Double,
  freq_b_hz : Double,
  seconds : Double,
  volume : Double,
) -> Bytes {
  let sample_rate = 22050
  let sample_count = (seconds * sample_rate.to_double()).to_int()
  let data_size = sample_count * 2
  let riff_size = 36 + data_size
  let bytes : Array[Byte] = []
  push_u8(bytes, 82)
  push_u8(bytes, 73)
  push_u8(bytes, 70)
  push_u8(bytes, 70)
  push_u32_le(bytes, riff_size)
  push_u8(bytes, 87)
  push_u8(bytes, 65)
  push_u8(bytes, 86)
  push_u8(bytes, 69)
  push_u8(bytes, 102)
  push_u8(bytes, 109)
  push_u8(bytes, 116)
  push_u8(bytes, 32)
  push_u32_le(bytes, 16)
  push_u16_le(bytes, 1)
  push_u16_le(bytes, 1)
  push_u32_le(bytes, sample_rate)
  push_u32_le(bytes, sample_rate * 2)
  push_u16_le(bytes, 2)
  push_u16_le(bytes, 16)
  push_u8(bytes, 100)
  push_u8(bytes, 97)
  push_u8(bytes, 116)
  push_u8(bytes, 97)
  push_u32_le(bytes, data_size)

  let amplitude = 32767.0 * volume
  for i in 0..<sample_count {
    let time = i.to_double() / sample_rate.to_double()
    let env = if time < 0.01 {
      time / 0.01
    } else if time > seconds - 0.05 {
      let tail = (seconds - time) / 0.05
      if tail > 0.0 {
        tail
      } else {
        0.0
      }
    } else {
      1.0
    }
    let wave_a = @cmath.sin(2.0 * 3.141592653589793 * freq_a_hz * time)
    let wave_b = @cmath.sin(2.0 * 3.141592653589793 * freq_b_hz * time * 0.5)
    let sample = (wave_a * 0.75 + wave_b * 0.25) * amplitude * env
    push_i16_le(bytes, sample.to_int())
  }
  Bytes::from_array(bytes)
}

///|
fn make_tone(
  freq_a_hz : Double,
  freq_b_hz : Double,
  seconds : Double,
  volume : Double,
) -> @host.Sound {
  @host.sound_from_wav_bytes(
    synth_dual_tone_wav_bytes(freq_a_hz, freq_b_hz, seconds, volume),
  )
}

///|
fn ensure_sounds_loaded() -> Unit {
  if sound_serve.val is Some(_) {
    return
  }
  sound_serve.val = Some(make_tone(560.0, 280.0, 0.06, 0.22))
  sound_paddle.val = Some(make_tone(720.0, 360.0, 0.04, 0.24))
  sound_wall.val = Some(make_tone(420.0, 210.0, 0.04, 0.16))
  sound_brick.val = Some(make_tone(860.0, 430.0, 0.05, 0.22))
  sound_life_lost.val = Some(make_tone(170.0, 96.0, 0.22, 0.34))
  sound_pickup.val = Some(make_tone(1040.0, 520.0, 0.10, 0.22))
  sound_laser.val = Some(make_tone(1280.0, 640.0, 0.05, 0.18))
  sound_win.val = Some(make_tone(920.0, 460.0, 0.16, 0.24))
  sound_game_over.val = Some(make_tone(150.0, 88.0, 0.28, 0.30))
}

///|
fn play_sound_ref(sound : Ref[@host.Sound?]) -> Unit {
  match sound.val {
    Some(value) => @host.play_sound(value)
    None => ()
  }
}

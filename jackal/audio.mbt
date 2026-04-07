///|
fn push_u8(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push(value.to_byte())
}

///|
fn push_u16_le(bytes : Array[Byte], value : Int) -> Unit {
  push_u8(bytes, value & 0xFF)
  push_u8(bytes, (value >> 8) & 0xFF)
}

///|
fn push_u32_le(bytes : Array[Byte], value : Int) -> Unit {
  push_u8(bytes, value & 0xFF)
  push_u8(bytes, (value >> 8) & 0xFF)
  push_u8(bytes, (value >> 16) & 0xFF)
  push_u8(bytes, (value >> 24) & 0xFF)
}

///|
fn push_fourcc(bytes : Array[Byte], a : Int, b : Int, c : Int, d : Int) -> Unit {
  push_u8(bytes, a)
  push_u8(bytes, b)
  push_u8(bytes, c)
  push_u8(bytes, d)
}

///|
fn wav_bytes(freq : Double, duration : Double, volume : Double) -> Bytes {
  let sample_rate = 22050
  let sample_count = (duration * sample_rate.to_double()).to_int()
  let data_bytes = sample_count * 2
  let bytes : Array[Byte] = []
  push_fourcc(bytes, 82, 73, 70, 70)
  push_u32_le(bytes, 36 + data_bytes)
  push_fourcc(bytes, 87, 65, 86, 69)
  push_fourcc(bytes, 102, 109, 116, 32)
  push_u32_le(bytes, 16)
  push_u16_le(bytes, 1)
  push_u16_le(bytes, 1)
  push_u32_le(bytes, sample_rate)
  push_u32_le(bytes, sample_rate * 2)
  push_u16_le(bytes, 2)
  push_u16_le(bytes, 16)
  push_fourcc(bytes, 100, 97, 116, 97)
  push_u32_le(bytes, data_bytes)

  let pi2 = 2.0 * @cmath.PI
  for i in 0..<sample_count {
    let t = i.to_double() / sample_rate.to_double()
    let attack = if t < 0.01 { t / 0.01 } else { 1.0 }
    let release = if t > duration - 0.06 {
      clamp_double((duration - t) / 0.06, 0.0, 1.0)
    } else {
      1.0
    }
    let env = attack * release * (1.0 - t / duration * 0.15)
    let raw = @cmath.sin(pi2 * freq * t) * volume * env
    let sample = clamp_double(raw, -1.0, 1.0)
    let pcm = (sample * 32767.0).to_int()
    let normalized = if pcm < 0 { 65536 + pcm } else { pcm }
    push_u16_le(bytes, normalized)
  }
  Bytes::from_array(bytes)
}

///|
fn make_tone_sound(
  freq : Double,
  duration : Double,
  amplitude : Double,
) -> @raylib.Sound {
  let wave = @raylib.Wave::load_from_memory(
    "wav",
    wav_bytes(freq, duration, amplitude),
    0,
  )
  let sound = wave.load_sound()
  wave.unload()
  sound
}

///|
fn push_u16_le(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push((value & 0xFF).to_byte())
  bytes.push(((value >> 8) & 0xFF).to_byte())
}

///|
fn push_u32_le(bytes : Array[Byte], value : Int) -> Unit {
  bytes.push((value & 0xFF).to_byte())
  bytes.push(((value >> 8) & 0xFF).to_byte())
  bytes.push(((value >> 16) & 0xFF).to_byte())
  bytes.push(((value >> 24) & 0xFF).to_byte())
}

///|
fn push_ascii(bytes : Array[Byte], values : Array[Int]) -> Unit {
  for value in values {
    bytes.push(value.to_byte())
  }
}

///|
fn wav_from_tone(
  freq_hz : Double,
  seconds : Double,
  volume : Double,
  sample_rate? : Int = 22050,
) -> Bytes {
  let sample_count = (seconds * sample_rate.to_double()).to_int()
  let data_bytes = sample_count * 2
  let out : Array[Byte] = []
  push_ascii(out, [82, 73, 70, 70])
  push_u32_le(out, 36 + data_bytes)
  push_ascii(out, [87, 65, 86, 69])
  push_ascii(out, [102, 109, 116, 32])
  push_u32_le(out, 16)
  push_u16_le(out, 1)
  push_u16_le(out, 1)
  push_u32_le(out, sample_rate)
  push_u32_le(out, sample_rate * 2)
  push_u16_le(out, 2)
  push_u16_le(out, 16)
  push_ascii(out, [100, 97, 116, 97])
  push_u32_le(out, data_bytes)
  let sample_rate_f = sample_rate.to_double()
  for i in 0..<sample_count {
    let t = i.to_double() / sample_rate_f
    let attack = if t < 0.01 { t / 0.01 } else { 1.0 }
    let release = if t > seconds - 0.06 {
      clamp_double((seconds - t) / 0.06, 0.0, 1.0)
    } else {
      1.0
    }
    let env = attack * release * (1.0 - t / seconds * 0.15)
    let raw = @cmath.sin(2.0 * @cmath.PI * freq_hz * t) * volume * env
    let sample = clamp_double(raw, -1.0, 1.0)
    let pcm = (sample * 32767.0).to_int()
    let normalized = if pcm < 0 { 65536 + pcm } else { pcm }
    push_u16_le(out, normalized)
  }
  Bytes::from_array(out)
}

///|
fn sound_from_tone(
  freq_hz : Double,
  seconds : Double,
  volume : Double,
) -> @raylib.Sound {
  let wav_bytes = wav_from_tone(freq_hz, seconds, volume)
  let wav = @raylib.Wave::load_from_memory(
    ".wav",
    wav_bytes,
    wav_bytes.length(),
  )
  let sound = wav.load_sound()
  wav.unload()
  sound
}

///|
fn create_audio_bank() -> AudioBank {
  {
    jump: sound_from_tone(760.0, 0.11, 0.62),
    stomp: sound_from_tone(220.0, 0.14, 0.76),
    hit: sound_from_tone(146.0, 0.18, 0.74),
    goal: sound_from_tone(988.0, 0.22, 0.72),
    collect: sound_from_tone(1240.0, 0.09, 0.66),
    shoot: sound_from_tone(540.0, 0.1, 0.62),
  }
}

///|
fn play_sound(sound : @raylib.Sound) -> Unit {
  sound.play()
}

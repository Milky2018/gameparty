///|
pub enum NetRole {
  Host
  Client
}

///|
pub enum SyncPolicy {
  HostAuthoritative
}

///|
pub struct NetConfig {
  input_delay_frames : Int
  checksum_interval_frames : Int
  policy : SyncPolicy
}

///|
pub fn NetConfig::default() -> NetConfig {
  {
    input_delay_frames: 2,
    checksum_interval_frames: 30,
    policy: HostAuthoritative,
  }
}

///|
pub struct PlayerInput {
  frame_id : Int
  axis_x : Int
  axis_y : Int
  action_mask : Int
}

///|
pub fn PlayerInput::new(
  frame_id~ : Int,
  axis_x~ : Int,
  axis_y~ : Int,
  action_mask~ : Int,
) -> PlayerInput {
  { frame_id, axis_x, axis_y, action_mask }
}

///|
pub enum NetMessage {
  Hello(String, NetRole)
  Ready(String)
  Start(Int, Int, Int)
  Input(PlayerInput)
  Checksum(Int, Int)
  ResyncRequest(Int)
  Snapshot(Int, String)
  Ping(Int)
  Pong(Int)
}

///|
pub enum NetEvent {
  RemoteReady(String)
  RoundStarted(Int, Int, Int)
  RemoteInput(PlayerInput)
  ResyncNeeded(Int, Int, Int)
  RemoteResyncRequest(Int)
  RemoteSnapshot(Int, String)
  LatencyProbe(Int)
}

///|
pub struct NetSession {
  role : NetRole
  local_peer_id : String
  remote_peer_id : String
  config : NetConfig
  mut seed : Int
  mut local_ready : Bool
  mut remote_ready : Bool
  mut running : Bool
  mut next_local_frame : Int
  mut last_checksum_frame : Int
  mut last_checksum_value : Int
  mut outgoing : Array[NetMessage]
  mut events : Array[NetEvent]
  mut remote_inputs : Array[PlayerInput]
}

///|
pub fn NetSession::new_host(
  local_peer_id~ : String,
  remote_peer_id~ : String,
  seed? : Int = 1,
  config? : NetConfig = NetConfig::default(),
) -> NetSession {
  {
    role: Host,
    local_peer_id,
    remote_peer_id,
    config,
    seed,
    local_ready: false,
    remote_ready: false,
    running: false,
    next_local_frame: 0,
    last_checksum_frame: -1,
    last_checksum_value: 0,
    outgoing: [],
    events: [],
    remote_inputs: [],
  }
}

///|
pub fn NetSession::new_client(
  local_peer_id~ : String,
  remote_peer_id~ : String,
  config? : NetConfig = NetConfig::default(),
) -> NetSession {
  {
    role: Client,
    local_peer_id,
    remote_peer_id,
    config,
    seed: 0,
    local_ready: false,
    remote_ready: false,
    running: false,
    next_local_frame: 0,
    last_checksum_frame: -1,
    last_checksum_value: 0,
    outgoing: [],
    events: [],
    remote_inputs: [],
  }
}

///|
fn normalize_axis(value : Int) -> Int {
  if value < 0 {
    -1
  } else if value > 0 {
    1
  } else {
    0
  }
}

///|
pub fn NetSession::begin_handshake(self : NetSession) -> NetSession {
  let next = self
  next.outgoing.push(Hello(next.local_peer_id, next.role))
  next
}

///|
fn maybe_start_round(session : NetSession) -> NetSession {
  let next = session
  if next.running {
    return next
  }
  if !next.local_ready || !next.remote_ready {
    return next
  }
  if next.role is Host {
    let start_frame = next.next_local_frame + next.config.input_delay_frames
    next.running = true
    next.next_local_frame = start_frame
    next.outgoing.push(
      Start(next.seed, start_frame, next.config.input_delay_frames),
    )
    next.events.push(
      RoundStarted(next.seed, start_frame, next.config.input_delay_frames),
    )
  }
  next
}

///|
pub fn NetSession::set_local_ready(self : NetSession) -> NetSession {
  let next = self
  next.local_ready = true
  next.outgoing.push(Ready(next.local_peer_id))
  maybe_start_round(next)
}

///|
pub fn NetSession::submit_local_input(
  self : NetSession,
  input : PlayerInput,
) -> NetSession {
  let next = self
  next.outgoing.push(
    Input(PlayerInput::{
      frame_id: input.frame_id,
      axis_x: normalize_axis(input.axis_x),
      axis_y: normalize_axis(input.axis_y),
      action_mask: input.action_mask,
    }),
  )
  next
}

///|
pub fn NetSession::report_local_checksum(
  self : NetSession,
  frame_id : Int,
  checksum : Int,
) -> NetSession {
  let next = self
  next.last_checksum_frame = frame_id
  next.last_checksum_value = checksum
  let interval = if next.config.checksum_interval_frames <= 0 {
    1
  } else {
    next.config.checksum_interval_frames
  }
  if frame_id % interval == 0 {
    next.outgoing.push(Checksum(frame_id, checksum))
  }
  next
}

///|
pub fn NetSession::tick(self : NetSession) -> NetSession {
  let next = self
  next.next_local_frame += 1
  next
}

///|
pub fn NetSession::ingest_remote(
  self : NetSession,
  message : NetMessage,
) -> NetSession {
  let next = self
  match message {
    Hello(peer_id, _) =>
      if peer_id == next.remote_peer_id && next.local_ready {
        next.outgoing.push(Ready(next.local_peer_id))
      }
    Ready(peer_id) => {
      if peer_id == next.remote_peer_id {
        next.remote_ready = true
        next.events.push(RemoteReady(peer_id))
      }
      return maybe_start_round(next)
    }
    Start(seed, start_frame, input_delay_frames) => {
      next.seed = seed
      next.running = true
      next.next_local_frame = start_frame
      next.events.push(RoundStarted(seed, start_frame, input_delay_frames))
    }
    Input(input) => {
      next.remote_inputs.push(input)
      next.events.push(RemoteInput(input))
    }
    Checksum(frame_id, remote_checksum) =>
      if next.last_checksum_frame == frame_id &&
        next.last_checksum_value != remote_checksum {
        next.events.push(
          ResyncNeeded(frame_id, next.last_checksum_value, remote_checksum),
        )
        if next.role is Host {
          next.outgoing.push(Snapshot(frame_id, "host_snapshot_pending"))
        } else {
          next.outgoing.push(ResyncRequest(frame_id))
        }
      }
    ResyncRequest(frame_id) => {
      next.events.push(RemoteResyncRequest(frame_id))
      if next.role is Host {
        next.outgoing.push(Snapshot(frame_id, "host_snapshot_pending"))
      }
    }
    Snapshot(frame_id, payload) =>
      next.events.push(RemoteSnapshot(frame_id, payload))
    Ping(sent_tick) => {
      next.outgoing.push(Pong(sent_tick))
      next.events.push(LatencyProbe(sent_tick))
    }
    Pong(sent_tick) => next.events.push(LatencyProbe(sent_tick))
  }
  next
}

///|
pub fn NetSession::enqueue_ping(
  self : NetSession,
  sent_tick : Int,
) -> NetSession {
  let next = self
  next.outgoing.push(Ping(sent_tick))
  next
}

///|
pub fn NetSession::drain_outgoing(
  self : NetSession,
) -> (NetSession, Array[NetMessage]) {
  let next = self
  let buffered = next.outgoing
  next.outgoing = []
  (next, buffered)
}

///|
pub fn NetSession::drain_events(
  self : NetSession,
) -> (NetSession, Array[NetEvent]) {
  let next = self
  let buffered = next.events
  next.events = []
  (next, buffered)
}

///|
pub fn NetSession::drain_remote_inputs(
  self : NetSession,
) -> (NetSession, Array[PlayerInput]) {
  let next = self
  let buffered = next.remote_inputs
  next.remote_inputs = []
  (next, buffered)
}

///|
pub fn NetSession::is_running(self : NetSession) -> Bool {
  self.running
}

///|
pub fn NetSession::current_frame(self : NetSession) -> Int {
  self.next_local_frame
}

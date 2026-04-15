///|
pub(all) struct Session {
  raw : @netplay.NetSession
}

///|
pub(all) struct Link {
  raw : @netplay.TcpLink
}

///|
fn default_config() -> @netplay.NetConfig {
  @netplay.NetConfig::default()
}

///|
fn player_input_tuple(input : @netplay.PlayerInput) -> (Int, Int, Int, Int) {
  (input.frame_id, input.axis_x, input.axis_y, input.action_mask)
}

///|
pub fn is_available() -> Bool {
  true
}

///|
pub fn local_ipv4() -> String? {
  @netplay.local_ipv4()
}

///|
pub fn new_host_session(round_seed : Int) -> Session {
  let config = default_config()
  let mut session = @netplay.NetSession::new_host(
    local_peer_id="p1",
    remote_peer_id="p2",
    seed=round_seed,
    config~,
  )
  session = session.begin_handshake()
  session = session.set_local_ready()
  { raw: session }
}

///|
pub fn new_client_session() -> Session {
  let config = default_config()
  let mut session = @netplay.NetSession::new_client(
    local_peer_id="p2",
    remote_peer_id="p1",
    config~,
  )
  session = session.begin_handshake()
  session = session.set_local_ready()
  { raw: session }
}

///|
pub fn new_host_link(port : Int) -> Link {
  { raw: @netplay.TcpLink::new_host(port) }
}

///|
pub fn new_client_link(host : String, port : Int) -> Link {
  { raw: @netplay.TcpLink::new_client(remote_host=host, remote_port=port) }
}

///|
pub fn close_link(link : Link) -> Link {
  { raw: link.raw.close() }
}

///|
pub fn link_is_connected(link : Link) -> Bool {
  link.raw.is_connected()
}

///|
pub fn loopback_exchange(
  host : Session,
  client : Session,
) -> (Session, Session) {
  let (host_after_drain, host_messages) = host.raw.drain_outgoing()
  let mut next_client = client.raw
  for message in host_messages {
    next_client = next_client.ingest_remote(message)
  }
  let (client_after_drain, client_messages) = next_client.drain_outgoing()
  let mut next_host = host_after_drain
  for message in client_messages {
    next_host = next_host.ingest_remote(message)
  }
  ({ raw: next_host }, { raw: client_after_drain })
}

///|
pub fn transport_flush(session : Session, link : Link) -> (Session, Link) {
  if !link.raw.is_connected() {
    return (session, link)
  }
  let (next_session, outgoing) = session.raw.drain_outgoing()
  let mut session_after_send = next_session
  let mut next_link = link.raw
  let mut keep_index = -1
  for index in 0..<outgoing.length() {
    let message = outgoing[index]
    let (updated, _) = next_link.send_line(@netplay.encode_message(message))
    next_link = updated
    if !next_link.is_connected() {
      keep_index = index
      break
    }
  }
  if keep_index >= 0 {
    for index in keep_index..<outgoing.length() {
      session_after_send = session_after_send.enqueue_outgoing(outgoing[index])
    }
  }
  ({ raw: session_after_send }, { raw: next_link })
}

///|
pub fn transport_poll(
  session : Session,
  link : Link,
) -> (Session, Link, Array[String]) {
  let (next_link, lines, events) = link.raw.poll()
  let mut next_session = session.raw
  for line in lines {
    match @netplay.decode_message(line) {
      Some(message) => next_session = next_session.ingest_remote(message)
      None => ()
    }
  }
  let errors : Array[String] = []
  for event in events {
    match event {
      Connected => ()
      Error(message) => errors.push(message)
    }
  }
  ({ raw: next_session }, { raw: next_link }, errors)
}

///|
pub fn session_is_running(session : Session) -> Bool {
  session.raw.is_running()
}

///|
pub fn session_current_frame(session : Session) -> Int {
  session.raw.current_frame()
}

///|
pub fn session_tick(session : Session) -> Session {
  { raw: session.raw.tick() }
}

///|
pub fn session_submit_local_input(
  session : Session,
  frame_id : Int,
  axis_x : Int,
  axis_y : Int,
  action_mask : Int,
) -> Session {
  let input = @netplay.PlayerInput::new(
    frame_id~,
    axis_x~,
    axis_y~,
    action_mask~,
  )
  { raw: session.raw.submit_local_input(input) }
}

///|
pub fn session_drain_remote_inputs(
  session : Session,
) -> (Session, Array[(Int, Int, Int, Int)]) {
  let (next_session, remote_inputs) = session.raw.drain_remote_inputs()
  let tuples : Array[(Int, Int, Int, Int)] = []
  for input in remote_inputs {
    tuples.push(player_input_tuple(input))
  }
  ({ raw: next_session }, tuples)
}

///|
pub fn session_drain_round_started_seed(session : Session) -> (Session, Int?) {
  let (next_session, events) = session.raw.drain_events()
  let mut seed : Int? = None
  for event in events {
    match event {
      RoundStarted(round_seed, _, _) => seed = Some(round_seed)
      _ => ()
    }
  }
  ({ raw: next_session }, seed)
}

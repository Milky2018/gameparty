///|
fn exchange(host : NetSession, client : NetSession) -> (NetSession, NetSession) {
  let (host_after_drain, host_messages) = host.drain_outgoing()
  let mut next_client = client
  for message in host_messages {
    next_client = next_client.ingest_remote(message)
  }
  let (client_after_drain, client_messages) = next_client.drain_outgoing()
  let mut next_host = host_after_drain
  for message in client_messages {
    next_host = next_host.ingest_remote(message)
  }
  (next_host, client_after_drain)
}

///|
fn handshake_and_start(
  host : NetSession,
  client : NetSession,
) -> (NetSession, NetSession) {
  let mut h = host.begin_handshake()
  let mut c = client.begin_handshake()
  let (h1, c1) = exchange(h, c)
  h = h1.set_local_ready()
  c = c1.set_local_ready()
  for _ in 0..<4 {
    let (nh, nc) = exchange(h, c)
    h = nh
    c = nc
  }
  (h, c)
}

///|
test "host and client handshake can enter running state" {
  let config = NetConfig::{ ..NetConfig::default(), input_delay_frames: 3 }
  let host0 = NetSession::new_host(
    local_peer_id="host",
    remote_peer_id="client",
    seed=20260407,
    config~,
  )
  let client0 = NetSession::new_client(
    local_peer_id="client",
    remote_peer_id="host",
    config~,
  )
  let (host, client) = handshake_and_start(host0, client0)
  assert_true(host.is_running())
  assert_true(client.is_running())
  assert_eq(client.current_frame(), 3)

  let (_, client_events) = client.drain_events()
  let mut saw_started = false
  for event in client_events {
    if event is RoundStarted(20260407, 3, 3) {
      saw_started = true
    }
  }
  assert_true(saw_started)
}

///|
test "checksum mismatch triggers resync flow" {
  let config = NetConfig::{
    ..NetConfig::default(),
    checksum_interval_frames: 1,
  }
  let host0 = NetSession::new_host(
    local_peer_id="host",
    remote_peer_id="client",
    seed=1,
    config~,
  )
  let client0 = NetSession::new_client(
    local_peer_id="client",
    remote_peer_id="host",
    config~,
  )
  let (host1, client1) = handshake_and_start(host0, client0)

  let host2 = host1.report_local_checksum(10, 111)
  let client2 = client1.report_local_checksum(10, 222)
  let (host3, _) = exchange(host2, client2)

  let (host4, host_events) = host3.drain_events()
  let mut saw_mismatch = false
  for event in host_events {
    if event is ResyncNeeded(10, 111, 222) {
      saw_mismatch = true
    }
  }
  assert_true(saw_mismatch)

  let (_, host_outgoing) = host4.drain_outgoing()
  let mut saw_snapshot = false
  for message in host_outgoing {
    if message is Snapshot(10, "host_snapshot_pending") {
      saw_snapshot = true
    }
  }
  assert_true(saw_snapshot)
}

///|
test "local input is normalized before send" {
  let session0 = NetSession::new_client(local_peer_id="p2", remote_peer_id="p1")
  let session1 = session0.submit_local_input(PlayerInput::{
    frame_id: 12,
    axis_x: 8,
    axis_y: -9,
    action_mask: 5,
  })

  let (_, outgoing) = session1.drain_outgoing()
  assert_eq(outgoing.length(), 1)
  match outgoing[0] {
    Input(input) => {
      assert_eq(input.frame_id, 12)
      assert_eq(input.axis_x, 1)
      assert_eq(input.axis_y, -1)
      assert_eq(input.action_mask, 5)
    }
    _ => panic()
  }
}

///|
fn pump_tcp_links(
  host : TcpLink,
  client : TcpLink,
  steps : Int,
) -> (TcpLink, TcpLink, Array[String], Array[String]) {
  let mut next_host = host
  let mut next_client = client
  let host_lines_all : Array[String] = []
  let client_lines_all : Array[String] = []
  for _ in 0..<steps {
    let (host_after_poll, host_lines, _) = next_host.poll()
    next_host = host_after_poll
    for line in host_lines {
      host_lines_all.push(line)
    }
    let (client_after_poll, client_lines, _) = next_client.poll()
    next_client = client_after_poll
    for line in client_lines {
      client_lines_all.push(line)
    }
  }
  (next_host, next_client, host_lines_all, client_lines_all)
}

///|
test "wire codec keeps net messages round-trippable" {
  let original = Snapshot(42, "state|line\nnext")
  let encoded = encode_message(original)
  match decode_message(encoded) {
    Some(Snapshot(frame_id, payload)) => {
      assert_eq(frame_id, 42)
      assert_eq(payload, "state|line\nnext")
    }
    _ => panic()
  }
}

///|
test "tcp link can connect and exchange encoded net messages" {
  let test_port = 45123
  let mut host = TcpLink::new_host(test_port)
  let mut client = TcpLink::new_client(
    remote_host="127.0.0.1",
    remote_port=test_port,
  )
  let (host_after_connect, client_after_connect, _, _) = pump_tcp_links(
    host, client, 300,
  )
  host = host_after_connect
  client = client_after_connect
  assert_true(host.is_connected())
  assert_true(client.is_connected())

  let payload = Input(
    PlayerInput::new(frame_id=7, axis_x=-1, axis_y=0, action_mask=1),
  )
  let (client_after_send, sent) = client.send_line(encode_message(payload))
  client = client_after_send
  assert_true(sent)

  let (host_after_recv, client_after_recv, host_lines, _) = pump_tcp_links(
    host, client, 300,
  )
  host = host_after_recv
  client = client_after_recv
  assert_true(host_lines.length() > 0)
  match decode_message(host_lines[0]) {
    Some(Input(input)) => {
      assert_eq(input.frame_id, 7)
      assert_eq(input.axis_x, -1)
      assert_eq(input.axis_y, 0)
      assert_eq(input.action_mask, 1)
    }
    _ => panic()
  }

  ignore(host.close())
  ignore(client.close())
}

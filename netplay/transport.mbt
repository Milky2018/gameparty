///|
pub enum TcpLinkEvent {
  Connected
  Error(String)
}

///|
pub struct TcpLink {
  role : NetRole
  listen_port : Int
  remote_host : String
  remote_port : Int
  mut listener_fd : Int
  mut socket_fd : Int
  mut connected : Bool
  mut recv_buffer : String
  mut last_error : String?
}

///|
fn ascii_bytes(text : String, null_terminated : Bool) -> Bytes {
  let bytes : Array[Byte] = []
  for index in 0..<text.length() {
    bytes.push(text.code_unit_at(index).to_int().to_byte())
  }
  if null_terminated {
    bytes.push((0).to_byte())
  }
  Bytes::from_array(bytes)
}

///|
fn ascii_string(bytes : Bytes) -> String {
  let chars : Array[Char] = []
  for index in 0..<bytes.length() {
    let value = bytes[index].to_int()
    if value == 0 {
      break
    }
    chars.push(Int::unsafe_to_char(value))
  }
  String::from_array(chars)
}

///|
pub fn local_ipv4() -> String? {
  let detected = ascii_string(tcp_local_ipv4_ffi()).trim().to_string()
  if detected == "" {
    None
  } else {
    Some(detected)
  }
}

///|
fn parse_int_safe(raw : String) -> Int? {
  Some(@string.parse_int(raw)) catch {
    _ => None
  }
}

///|
fn wire_escape(raw : String) -> String {
  raw
  .replace(old="%", new="%25")
  .replace(old="|", new="%7C")
  .replace(old="\n", new="%0A")
}

///|
fn wire_unescape(raw : String) -> String {
  raw
  .replace(old="%0A", new="\n")
  .replace(old="%7C", new="|")
  .replace(old="%25", new="%")
}

///|
fn role_code(role : NetRole) -> String {
  match role {
    Host => "H"
    Client => "C"
  }
}

///|
fn parse_role(raw : String) -> NetRole? {
  match raw {
    "H" => Some(Host)
    "C" => Some(Client)
    _ => None
  }
}

///|
fn split_wire_line(line : String) -> Array[String] {
  let parts : Array[String] = []
  for part in line.split("|") {
    parts.push(part.to_string())
  }
  parts
}

///|
pub fn encode_message(message : NetMessage) -> String {
  match message {
    Hello(peer, role) => "HELLO|\{wire_escape(peer)}|\{role_code(role)}"
    Ready(peer) => "READY|\{wire_escape(peer)}"
    Start(seed, start_frame, input_delay) =>
      "START|\{seed}|\{start_frame}|\{input_delay}"
    Input(input) =>
      "INPUT|\{input.frame_id}|\{input.axis_x}|\{input.axis_y}|\{input.action_mask}"
    Checksum(frame_id, value) => "CHECK|\{frame_id}|\{value}"
    ResyncRequest(frame_id) => "RSQ|\{frame_id}"
    Snapshot(frame_id, payload) => "SNAP|\{frame_id}|\{wire_escape(payload)}"
    Ping(tick) => "PING|\{tick}"
    Pong(tick) => "PONG|\{tick}"
  }
}

///|
pub fn decode_message(line : String) -> NetMessage? {
  let parts = split_wire_line(line.trim().to_string())
  if parts.is_empty() {
    return None
  }
  match parts[0] {
    "HELLO" =>
      if parts.length() == 3 {
        match parse_role(parts[2]) {
          Some(role) => Some(Hello(wire_unescape(parts[1]), role))
          None => None
        }
      } else {
        None
      }
    "READY" =>
      if parts.length() == 2 {
        Some(Ready(wire_unescape(parts[1])))
      } else {
        None
      }
    "START" =>
      if parts.length() == 4 {
        guard parse_int_safe(parts[1]) is Some(seed) else { return None }
        guard parse_int_safe(parts[2]) is Some(start_frame) else { return None }
        guard parse_int_safe(parts[3]) is Some(input_delay) else { return None }
        Some(Start(seed, start_frame, input_delay))
      } else {
        None
      }
    "INPUT" =>
      if parts.length() == 5 {
        guard parse_int_safe(parts[1]) is Some(frame_id) else { return None }
        guard parse_int_safe(parts[2]) is Some(axis_x) else { return None }
        guard parse_int_safe(parts[3]) is Some(axis_y) else { return None }
        guard parse_int_safe(parts[4]) is Some(action_mask) else { return None }
        Some(Input(PlayerInput::new(frame_id~, axis_x~, axis_y~, action_mask~)))
      } else {
        None
      }
    "CHECK" =>
      if parts.length() == 3 {
        guard parse_int_safe(parts[1]) is Some(frame_id) else { return None }
        guard parse_int_safe(parts[2]) is Some(value) else { return None }
        Some(Checksum(frame_id, value))
      } else {
        None
      }
    "RSQ" =>
      if parts.length() == 2 {
        guard parse_int_safe(parts[1]) is Some(frame_id) else { return None }
        Some(ResyncRequest(frame_id))
      } else {
        None
      }
    "SNAP" =>
      if parts.length() == 3 {
        guard parse_int_safe(parts[1]) is Some(frame_id) else { return None }
        Some(Snapshot(frame_id, wire_unescape(parts[2])))
      } else {
        None
      }
    "PING" =>
      if parts.length() == 2 {
        guard parse_int_safe(parts[1]) is Some(tick) else { return None }
        Some(Ping(tick))
      } else {
        None
      }
    "PONG" =>
      if parts.length() == 2 {
        guard parse_int_safe(parts[1]) is Some(tick) else { return None }
        Some(Pong(tick))
      } else {
        None
      }
    _ => None
  }
}

///|
pub fn TcpLink::new_host(listen_port : Int) -> TcpLink {
  let listener_fd = tcp_listen_ffi(listen_port)
  {
    role: Host,
    listen_port,
    remote_host: "",
    remote_port: 0,
    listener_fd,
    socket_fd: -1,
    connected: false,
    recv_buffer: "",
    last_error: if listener_fd < 0 {
      Some("listen_failed")
    } else {
      None
    },
  }
}

///|
pub fn TcpLink::new_client(
  remote_host~ : String,
  remote_port~ : Int,
) -> TcpLink {
  let host_bytes = ascii_bytes(remote_host, true)
  let socket_fd = tcp_connect_ffi(host_bytes, remote_port)
  {
    role: Client,
    listen_port: 0,
    remote_host,
    remote_port,
    listener_fd: -1,
    socket_fd,
    connected: socket_fd >= 0,
    recv_buffer: "",
    last_error: if socket_fd < 0 {
      Some("connect_failed")
    } else {
      None
    },
  }
}

///|
pub fn TcpLink::is_connected(self : TcpLink) -> Bool {
  self.connected && self.socket_fd >= 0
}

///|
fn absorb_incoming_lines(link : TcpLink) -> (TcpLink, Array[String]) {
  let next = link
  let lines : Array[String] = []
  if !next.is_connected() {
    return (next, lines)
  }
  let mut chunk = tcp_recv_ffi(next.socket_fd, 4096)
  while chunk.length() > 0 {
    next.recv_buffer = next.recv_buffer + ascii_string(chunk)
    chunk = tcp_recv_ffi(next.socket_fd, 4096)
  }
  let parts : Array[String] = []
  for segment in next.recv_buffer.split("\n") {
    parts.push(segment.to_string())
  }
  if parts.is_empty() {
    return (next, lines)
  }
  let has_newline = next.recv_buffer.has_suffix("\n")
  if has_newline {
    next.recv_buffer = ""
    for part in parts {
      if part != "" {
        lines.push(part)
      }
    }
  } else {
    let last_index = parts.length() - 1
    next.recv_buffer = parts[last_index]
    for index in 0..<last_index {
      let part = parts[index]
      if part != "" {
        lines.push(part)
      }
    }
  }
  (next, lines)
}

///|
pub fn TcpLink::poll(
  self : TcpLink,
) -> (TcpLink, Array[String], Array[TcpLinkEvent]) {
  let next = self
  let events : Array[TcpLinkEvent] = []
  if next.socket_fd < 0 {
    match next.role {
      Host =>
        if next.listener_fd >= 0 {
          let accepted = tcp_accept_ffi(next.listener_fd)
          if accepted >= 0 {
            next.socket_fd = accepted
            next.connected = true
            next.last_error = None
            events.push(Connected)
          }
        } else if next.last_error is None {
          next.last_error = Some("listener_unavailable")
          events.push(Error("listener_unavailable"))
        }
      Client => {
        let host_bytes = ascii_bytes(next.remote_host, true)
        let connected = tcp_connect_ffi(host_bytes, next.remote_port)
        if connected >= 0 {
          next.socket_fd = connected
          next.connected = true
          next.last_error = None
          events.push(Connected)
        }
      }
    }
  }
  let (after_recv, lines) = absorb_incoming_lines(next)
  (after_recv, lines, events)
}

///|
pub fn TcpLink::send_line(self : TcpLink, line : String) -> (TcpLink, Bool) {
  let next = self
  if !next.is_connected() {
    return (next, false)
  }
  let payload = ascii_bytes(line + "\n", false)
  let sent = tcp_send_ffi(next.socket_fd, payload)
  if sent == payload.length() {
    (next, true)
  } else if sent == -2 {
    (next, false)
  } else {
    if next.socket_fd >= 0 {
      tcp_close_ffi(next.socket_fd)
    }
    next.socket_fd = -1
    next.connected = false
    next.last_error = Some("send_failed")
    (next, false)
  }
}

///|
pub fn TcpLink::close(self : TcpLink) -> TcpLink {
  let next = self
  if next.socket_fd >= 0 {
    tcp_close_ffi(next.socket_fd)
  }
  if next.listener_fd >= 0 {
    tcp_close_ffi(next.listener_fd)
  }
  next.socket_fd = -1
  next.listener_fd = -1
  next.connected = false
  next.recv_buffer = ""
  next
}

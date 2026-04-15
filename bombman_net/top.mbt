///|
pub(all) struct Session(Int)

///|
pub(all) struct Link(Int)

///|
pub fn is_available() -> Bool {
  false
}

///|
pub fn local_ipv4() -> String? {
  None
}

///|
pub fn new_host_session(_round_seed : Int) -> Session {
  Session(0)
}

///|
pub fn new_client_session() -> Session {
  Session(0)
}

///|
pub fn new_host_link(_port : Int) -> Link {
  Link(0)
}

///|
pub fn new_client_link(_host : String, _port : Int) -> Link {
  Link(0)
}

///|
pub fn close_link(link : Link) -> Link {
  link
}

///|
pub fn link_is_connected(_link : Link) -> Bool {
  false
}

///|
pub fn loopback_exchange(
  host : Session,
  client : Session,
) -> (Session, Session) {
  (host, client)
}

///|
pub fn transport_flush(session : Session, link : Link) -> (Session, Link) {
  (session, link)
}

///|
pub fn transport_poll(
  session : Session,
  link : Link,
) -> (Session, Link, Array[String]) {
  (session, link, [])
}

///|
pub fn session_is_running(_session : Session) -> Bool {
  false
}

///|
pub fn session_current_frame(_session : Session) -> Int {
  0
}

///|
pub fn session_tick(session : Session) -> Session {
  session
}

///|
pub fn session_submit_local_input(
  session : Session,
  _frame_id : Int,
  _axis_x : Int,
  _axis_y : Int,
  _action_mask : Int,
) -> Session {
  session
}

///|
pub fn session_drain_remote_inputs(
  session : Session,
) -> (Session, Array[(Int, Int, Int, Int)]) {
  (session, [])
}

///|
pub fn session_drain_round_started_seed(session : Session) -> (Session, Int?) {
  (session, None)
}

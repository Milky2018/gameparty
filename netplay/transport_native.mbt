///|
#cfg(target="native")
extern "C" fn tcp_listen_ffi(port : Int) -> Int = "netplay_tcp_listen"

///|
#cfg(target="native")
extern "C" fn tcp_accept_ffi(listener_fd : Int) -> Int = "netplay_tcp_accept"

///|
#cfg(target="native")
#borrow(host)
extern "C" fn tcp_connect_ffi(host : Bytes, port : Int) -> Int = "netplay_tcp_connect"

///|
#cfg(target="native")
extern "C" fn tcp_close_ffi(fd : Int) -> Unit = "netplay_tcp_close"

///|
#cfg(target="native")
#borrow(payload)
extern "C" fn tcp_send_ffi(fd : Int, payload : Bytes) -> Int = "netplay_tcp_send"

///|
#cfg(target="native")
extern "C" fn tcp_recv_ffi(fd : Int, max_bytes : Int) -> Bytes = "netplay_tcp_recv"

///|
#cfg(not(target="native"))
fn tcp_listen_ffi(_port : Int) -> Int {
  -1
}

///|
#cfg(not(target="native"))
fn tcp_accept_ffi(_listener_fd : Int) -> Int {
  -1
}

///|
#cfg(not(target="native"))
fn tcp_connect_ffi(_host : Bytes, _port : Int) -> Int {
  -1
}

///|
#cfg(not(target="native"))
fn tcp_close_ffi(_fd : Int) -> Unit {
  ()
}

///|
#cfg(not(target="native"))
fn tcp_send_ffi(_fd : Int, _payload : Bytes) -> Int {
  -1
}

///|
#cfg(not(target="native"))
fn tcp_recv_ffi(_fd : Int, _max_bytes : Int) -> Bytes {
  b""
}

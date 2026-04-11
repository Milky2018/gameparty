#include <stdint.h>
#include "moonbit.h"

// Web builds do not support the native TCP transport used by bombman netplay.
// Keep these symbols available but make them inert so the wasm runtime remains stable.

MOONBIT_FFI_EXPORT int32_t netplay_tcp_listen(int32_t _port) {
  return -1;
}

MOONBIT_FFI_EXPORT int32_t netplay_tcp_accept(int32_t _listener_fd) {
  return -1;
}

MOONBIT_FFI_EXPORT int32_t netplay_tcp_connect(moonbit_bytes_t _host, int32_t _port) {
  return -1;
}

MOONBIT_FFI_EXPORT void netplay_tcp_close(int32_t _fd) {}

MOONBIT_FFI_EXPORT int32_t netplay_tcp_send(int32_t _fd, moonbit_bytes_t _payload) {
  return -1;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t netplay_tcp_recv(int32_t _fd, int32_t _max_bytes) {
  return moonbit_make_bytes(0, 0);
}

MOONBIT_FFI_EXPORT moonbit_bytes_t netplay_tcp_local_ipv4() {
  return moonbit_make_bytes(0, 0);
}

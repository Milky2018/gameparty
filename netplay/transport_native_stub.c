#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "moonbit.h"

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#pragma comment(lib, "ws2_32.lib")
typedef SOCKET net_fd_t;
static int net_winsock_ready = 0;
static void net_init_once() {
  if (net_winsock_ready) {
    return;
  }
  WSADATA wsa_data;
  if (WSAStartup(MAKEWORD(2, 2), &wsa_data) == 0) {
    net_winsock_ready = 1;
  }
}
static int net_set_nonblocking(net_fd_t fd) {
  u_long mode = 1;
  return ioctlsocket(fd, FIONBIO, &mode);
}
static int net_would_block() {
  int err = WSAGetLastError();
  return err == WSAEWOULDBLOCK;
}
static void net_close_fd(net_fd_t fd) {
  closesocket(fd);
}
#define NET_INVALID_FD INVALID_SOCKET
#else
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>
typedef int net_fd_t;
static void net_init_once() {}
static int net_set_nonblocking(net_fd_t fd) {
  int flags = fcntl(fd, F_GETFL, 0);
  if (flags < 0) {
    return -1;
  }
  return fcntl(fd, F_SETFL, flags | O_NONBLOCK);
}
static int net_would_block() {
  return errno == EWOULDBLOCK || errno == EAGAIN;
}
static void net_close_fd(net_fd_t fd) {
  close(fd);
}
#define NET_INVALID_FD (-1)
#endif

static void net_disable_sigpipe(net_fd_t fd) {
#if defined(SO_NOSIGPIPE)
  int yes = 1;
  setsockopt(fd, SOL_SOCKET, SO_NOSIGPIPE, (const char *)&yes, sizeof(yes));
#else
  (void)fd;
#endif
}

static int32_t net_fd_to_i32(net_fd_t fd) {
#ifdef _WIN32
  return (int32_t)fd;
#else
  return fd;
#endif
}

static net_fd_t net_i32_to_fd(int32_t fd) {
#ifdef _WIN32
  return (net_fd_t)fd;
#else
  return fd;
#endif
}

MOONBIT_FFI_EXPORT int32_t netplay_tcp_listen(int32_t port) {
  net_init_once();
  net_fd_t fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd == NET_INVALID_FD) {
    return -1;
  }
  int yes = 1;
  setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (const char *)&yes, sizeof(yes));

  struct sockaddr_in addr;
  memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_port = htons((uint16_t)port);
  addr.sin_addr.s_addr = htonl(INADDR_ANY);
  if (bind(fd, (struct sockaddr *)&addr, sizeof(addr)) != 0) {
    net_close_fd(fd);
    return -1;
  }
  if (listen(fd, 1) != 0) {
    net_close_fd(fd);
    return -1;
  }
  if (net_set_nonblocking(fd) != 0) {
    net_close_fd(fd);
    return -1;
  }
  net_disable_sigpipe(fd);
  return net_fd_to_i32(fd);
}

MOONBIT_FFI_EXPORT int32_t netplay_tcp_accept(int32_t listener_fd) {
  net_fd_t listener = net_i32_to_fd(listener_fd);
  struct sockaddr_in addr;
  socklen_t len = sizeof(addr);
  net_fd_t accepted = accept(listener, (struct sockaddr *)&addr, &len);
  if (accepted == NET_INVALID_FD) {
    return -1;
  }
  if (net_set_nonblocking(accepted) != 0) {
    net_close_fd(accepted);
    return -1;
  }
  net_disable_sigpipe(accepted);
  return net_fd_to_i32(accepted);
}

MOONBIT_FFI_EXPORT int32_t netplay_tcp_connect(moonbit_bytes_t host, int32_t port) {
  net_init_once();
  if (host == NULL) {
    return -1;
  }
  net_fd_t fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd == NET_INVALID_FD) {
    return -1;
  }
  if (net_set_nonblocking(fd) != 0) {
    net_close_fd(fd);
    return -1;
  }
  net_disable_sigpipe(fd);

  struct addrinfo hints;
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_INET;
  hints.ai_socktype = SOCK_STREAM;

  char port_buf[16];
  snprintf(port_buf, sizeof(port_buf), "%d", (int)port);
  struct addrinfo *result = NULL;
  if (getaddrinfo((const char *)host, port_buf, &hints, &result) != 0) {
    net_close_fd(fd);
    return -1;
  }

  int connected = -1;
  for (struct addrinfo *it = result; it != NULL; it = it->ai_next) {
    int rc = connect(fd, it->ai_addr, (socklen_t)it->ai_addrlen);
    if (rc == 0) {
      connected = 0;
      break;
    }
#ifdef _WIN32
    int err = WSAGetLastError();
    if (err == WSAEINPROGRESS || err == WSAEWOULDBLOCK || err == WSAEALREADY) {
      connected = 0;
      break;
    }
#else
    if (errno == EINPROGRESS || errno == EALREADY) {
      connected = 0;
      break;
    }
#endif
  }
  freeaddrinfo(result);
  if (connected != 0) {
    net_close_fd(fd);
    return -1;
  }
  return net_fd_to_i32(fd);
}

MOONBIT_FFI_EXPORT void netplay_tcp_close(int32_t fd) {
  if (fd < 0) {
    return;
  }
  net_close_fd(net_i32_to_fd(fd));
}

MOONBIT_FFI_EXPORT int32_t netplay_tcp_send(int32_t fd, moonbit_bytes_t payload) {
  if (fd < 0 || payload == NULL) {
    return -1;
  }
  int32_t len = (int32_t)Moonbit_array_length(payload);
  if (len <= 0) {
    return 0;
  }
#ifdef MSG_NOSIGNAL
  int flags = MSG_NOSIGNAL;
#else
  int flags = 0;
#endif
  int32_t sent = (int32_t)send(
    net_i32_to_fd(fd),
    (const char *)payload,
    len,
    flags
  );
  if (sent < 0 && net_would_block()) {
    return -2;
  }
  return sent;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t netplay_tcp_recv(int32_t fd, int32_t max_bytes) {
  if (fd < 0 || max_bytes <= 0) {
    return moonbit_make_bytes(0, 0);
  }
  char *buffer = (char *)malloc((size_t)max_bytes);
  if (buffer == NULL) {
    return moonbit_make_bytes(0, 0);
  }
  int32_t received = (int32_t)recv(net_i32_to_fd(fd), buffer, (size_t)max_bytes, 0);
  if (received <= 0) {
    free(buffer);
    return moonbit_make_bytes(0, 0);
  }
  moonbit_bytes_t result = moonbit_make_bytes(received, 0);
  memcpy(result, buffer, (size_t)received);
  free(buffer);
  return result;
}

MOONBIT_FFI_EXPORT moonbit_bytes_t netplay_tcp_local_ipv4() {
  net_init_once();

  char host_name[256];
  if (gethostname(host_name, sizeof(host_name)) != 0) {
    return moonbit_make_bytes(0, 0);
  }
  host_name[sizeof(host_name) - 1] = '\0';

  struct addrinfo hints;
  memset(&hints, 0, sizeof(hints));
  hints.ai_family = AF_INET;
  hints.ai_socktype = SOCK_STREAM;

  struct addrinfo *result = NULL;
  if (getaddrinfo(host_name, NULL, &hints, &result) != 0) {
    return moonbit_make_bytes(0, 0);
  }

  char selected[INET_ADDRSTRLEN];
  char fallback[INET_ADDRSTRLEN];
  selected[0] = '\0';
  fallback[0] = '\0';

  for (struct addrinfo *it = result; it != NULL; it = it->ai_next) {
    if (it->ai_addr == NULL || it->ai_family != AF_INET) {
      continue;
    }
    struct sockaddr_in *addr = (struct sockaddr_in *)it->ai_addr;
    char ip[INET_ADDRSTRLEN];
    if (inet_ntop(AF_INET, &(addr->sin_addr), ip, sizeof(ip)) == NULL) {
      continue;
    }
    if (fallback[0] == '\0') {
      strncpy(fallback, ip, sizeof(fallback) - 1);
      fallback[sizeof(fallback) - 1] = '\0';
    }
    if (strncmp(ip, "127.", 4) != 0) {
      strncpy(selected, ip, sizeof(selected) - 1);
      selected[sizeof(selected) - 1] = '\0';
      break;
    }
  }

  freeaddrinfo(result);

  const char *ip = selected[0] != '\0' ? selected : fallback;
  if (ip[0] == '\0') {
    return moonbit_make_bytes(0, 0);
  }
  int32_t len = (int32_t)strlen(ip);
  moonbit_bytes_t output = moonbit_make_bytes(len, 0);
  memcpy(output, ip, (size_t)len);
  return output;
}

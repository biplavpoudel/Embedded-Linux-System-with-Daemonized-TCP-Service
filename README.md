# Embedded Linux System with Daemonized TCP Service

This project implements a **custom embedded Linux system image** with a **daemonized TCP socket service**, built and validated using **Buildroot** and **QEMU (AArch64)**.

The goal of the project was not just to write a socket program, but to integrate a network service **properly into an embedded Linux environment**: cross-compilation, init scripts, signal handling, reproducible builds, and system-level validation.

## Architecture

                       Host machine
                        (Ubuntu, sh)
    ┌───────────────────────────────────────────────┐
    │                                               │
    │  netcat / sockettest.sh / full-test.sh        │
    │        │                                      │
    │        ├── TCP :9000  ─────────────────────┐  │
    │        │                                   │  │
    │        └── SSH/SCP :10022 ───────────────┐ │  │
    │                                          │ │  │
    └──────────────────────────────────────────┼─┼──┘
                                               │ │
                                 QEMU port fwd │ │
                                               │ │
                ┌──────────────────────────────▼─▼──────────────────────────────────┐
                │                  QEMU (AArch64)                                   │
                │            Buildroot Linux system image                           │
                │                                                                   │
                │  init (BusyBox)                                                   │
                │    └── /etc/init.d/S99aesdsocket                                  │
                │          └── start-stop-daemon                                    │
                │                └── /usr/bin/aesdsocket -d                         │
                │                       │                                           │
                │                       ├─ listens on TCP :9000                     │
                │                       ├─ syslog                                   │
                │                       └─ file state: /var/tmp/aesdsocketdata      │
                │                                                                   │
                │                                                                   │
                │  dropbear (SSH server) listens on :22                             │
                └───────────────────────────────────────────────────────────────────┘


## Overview

The system consists of three tightly integrated parts:

1. **A TCP socket server (`aesdsocket`) written in C**
2. **Service lifecycle management** (daemon mode + init integration)
3. **A reproducible embedded Linux image** built using Buildroot and executed on QEMU

The socket service listens on port **9000**, accepts newline-delimited input, appends data to a file on disk, and returns the aggregated contents to the client. The service runs as a daemon, starts automatically at boot, and shuts down cleanly when the system halts.


## Repository Structure

This project is split across two repositories by design.


### 1. Application Code (`assignments-3-and-later`)

[This repository](https://github.com/cu-ecen-aeld/assignments-3-and-later-biplavpoudel) contains the **socket implementation and service logic**.

**Key paths:**
- [`server/aesdsocket.c`](https://github.com/cu-ecen-aeld/assignments-3-and-later-biplavpoudel/blob/main/server/aesdsocket.c)
  TCP socket server implementation (POSIX sockets, syslog, signals, daemon mode)

- [`server/Makefile`](https://github.com/cu-ecen-aeld/assignments-3-and-later-biplavpoudel/blob/main/server/Makefile) 
  Supports both native compilation and cross-compilation using `CC`

- [`server/aesdsocket-start-stop`](https://github.com/cu-ecen-aeld/assignments-3-and-later-biplavpoudel/blob/main/server/aesdsocket-start-stop.sh)              init-compatible start/stop script using `start-stop-daemon`

To understand **how the socket service works**, we start here.


### 2. System Integration (`Buildroot`)

This repository is responsible for **turning the application into a bootable embedded Linux system**.

**Key components:**
- Buildroot is added as a **git submodule** [(2024.02.x)]((https://gitlab.com/buildroot.org/buildroot/))
- Custom [**external tree**](base_external/package/aesd-assignments/aesd-assignments.mk) defines the `aesd-assignments` package
- Cross-compilation and installation of `aesdsocket` into `/usr/bin`
- Init script is installed to `/etc/init.d/S99aesdsocket`
- Reproducible build scripts:
  - [`build.sh`](build.sh)
  - [`clean.sh`](clean.sh)
  - [`save-config.sh`](save-config.sh)

This is where the application is compiled into a binary and run as a **system service**.


## Socket Service Behavior

The `aesdsocket` service implements the following behavior:

- Opens a TCP stream socket bound to **port 9000**
- Logs client connections and disconnections using **syslog**
- Receives data until a newline character is encountered
- Appends completed packets to `/var/tmp/aesdsocketdata`
- Sends the **entire contents of the file** back to the client after each packet is written
- Continues accepting connections until interrupted
- On `SIGINT` or `SIGTERM`:
  - Server stops accepting new connections,
  - Closes listening sockets
  - Deletes `/var/tmp/aesdsocketdata`
  - Logs `Caught signal, exiting`
  - Terminates

A `-d` flag enables **daemon mode**, which forks the process after a successful bind and detaches it from the terminal.

The server uses a **fork-per-connection** model, allowing multiple clients to be handled concurrently. Access to `/var/tmp/aesdsocketdata` is synchronized using `flock()` to prevent file corruption across concurrent processes.


## Service Lifecycle Management

The socket service is integrated into the system using a traditional embedded Linux init workflow:

- Managed via `start-stop-daemon`
- PID tracked using a pidfile `/tmp/aesdsocket.pid`
- Installed as `/etc/init.d/S99aesdsocket`

This ensures:
- Automatic startup when the system boots
- Graceful shutdown during halt or restart


## Embedded Linux Image

The Linux image is built using **Buildroot** targeting **AArch64 QEMU**.

**Image features:**
- Custom defconfig derived from `qemu_aarch64_virt_defconfig`
- Dropbear SSH enabled for remote access
- Port forwarding configured:
  - Host **9000** → Guest **9000** (socket service)
  - Host **10022** → Guest **22** (SSH)

The system can be built and launched with:

```bash
./build.sh
./runqemu.sh
```
No manual interaction is required after the build completes.

## Validation and Testing

The project was validated using both automated and manual testing approaches:

- **Automated scripts**
  - `sockettest.sh`
  - `full-test.sh`

- **Manual testing**
  - Interaction testing using `netcat`
  - Remote access and file transfer verification using SSH and SCP

- **Build validation**
  - Clean rebuilds tested using `make distclean`

A clean shutdown followed by a restart guarantees that no stale data persists from previous runs.

---
## Additional Links
1. [Beej's Guide to Network Programming](https://beej.us/guide/bgnet/html/), which is an excellent resource for socket server/client.
2. Man pages for [accept](https://man7.org/linux/man-pages/man2/accept.2.html), [bind](https://man7.org/linux/man-pages/man2/bind.2.html), [socket](https://man7.org/linux/man-pages/man7/socket.7.html) and [start-stop-daemon](https://man7.org/linux/man-pages/man8/start-stop-daemon.8.html).
3. [Busybox Mirror](https://github.com/mirror/busybox.git), the original git [url](git://busybox.net/busybox.git) sometimes doesn't work!
4. For enabling **ccache** in Buildroot, follow this [documentation](https://buildroot.org/downloads/manual/manual.html#ccache).
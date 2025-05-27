# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

**Linux:**
```bash
make                    # Build the td-usb executable
make clean             # Remove build artifacts
```

**Windows:**
- Open `td-usb.sln` in Visual Studio
- Requires `Setupapi.lib` and `Hid.lib` libraries

**Dependencies:**
- Linux: `libusb-dev`, GCC, make
- macOS: Xcode Command Line Tools, Homebrew, `libusb-compat`
- Windows: Visual Studio, Windows SDK/Driver Kit

## Architecture Overview

TD-USB is a CLI tool for controlling 30+ USB device models from Tokyo Devices. The codebase uses a modular device driver architecture.

### Core Components

- `td-usb.c` - Main entry point and command dispatcher
- `td-usb.h` - Core definitions and data structures  
- `tddevice.c` - Common device communication protocols (TDDEV1/TDDEV2)
- `device_types.c` - Device registry and factory functions

### Device Support Structure

Each device in `devices/` implements a standard `td_device_t` interface with:
- USB VID/PID identification
- Function pointers for: `get`, `set`, `listen`, `save`, `destroy`, `init`
- Protocol-specific communication handling

### Platform Abstraction

- `linux/` - libusb-based HID implementation
- `windows/` - Windows HID API implementation  
- `tdhid.h` - Platform-agnostic HID interface

### Adding New Device Support

1. Create `devices/newdevice.c` implementing `td_device_t` structure
2. Add function pointer declaration in `device_types.c`
3. Add model name mapping in `import_device_type()`
4. Update README.md device table

### Communication Protocols

- **TDDEV1:** Simple command-based protocol
- **TDDEV2:** Register-based protocol with ACK/NACK handling
- Standard operations: GET/SET registers, SAVE to flash, DESTROY firmware

### Testing

Test devices using the built executable:
```bash
./td-usb model_name get                    # Read from device
./td-usb model_name set PARAM=value       # Write to device  
./td-usb model_name listen --loop         # Monitor events
```
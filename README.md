
[Japanese(Nihongo)](README_ja.md)

# TD-USB

CLI(Command Line Interface) for USB-based products of Tokyo Devices, Inc.


## Target platform

- Microsoft Windows 7 or later (64bit)
- Linux
- macOS


## Product models

|Model number|Name|`model_name` string|
|-------|-----|---------------|
|IWT120-USB|[Generic USB LED/Buzzer Module](https://en.tokyodevices.com/items/201)|`iwt120`|
|IWT1320-USB|[General Purpose USB Slider Input Device with integrated LED and Buzzer](https://en.tokyodevices.com/items/271)|`iwt1320`|
|IWS660-CS|[Generic USB Illuminance Meter](https://en.tokyodevices.com/items/228)|`iws660`|
|IWS73X-CS|[Generic USB CO2 Meter](https://en.tokyodevices.com/items/205)|`iws73x`|
|IWT303-1C|[USB SPDT Relay Controller 1CH](https://en.tokyodevices.com/items/148)|`iwt303`|
|IWT303-3C|[USB SPDT Relay Controller 3CH](https://en.tokyodevices.com/items/149)|`iwt303`|
|IWT313-USB|[USB SPDT Relay Controller 8CH](https://en.tokyodevices.com/items/149)|`iwt313`|
|TDFA30608|[8CH USB Digital Input Module with Optical Isolation](https://en.tokyodevices.com/items/284)|`tdfa30608`|
|TDFA30604|4CH USB Digital Input Module with Optical Isolation|`tdfa30604`|
|TDFA50507|[7CH USB Digital Output Module with Optical Isolation and Current Sink](https://en.tokyodevices.com/items/308)|`tdfa50507`|
|TDFA50607|[USB Digital Output Board, 7 Channels, 5/12/24V Output, Current Source Output, Bus-powered](https://en.tokyodevices.com/items/345)|`tdfa50607`|
|TDFA60220|[USB AD Converter For 4-20mA Analog Current Signal with Galvanic Isolation](https://en.tokyodevices.com/items/311)|`tdfa60220`|
|TDFA60250|[USB AD Converter For 0-5V/1-5V Analog Signal with Galvanic Isolation](https://en.tokyodevices.com/items/314)|`tdfa60250`|
|TDFA6032A|[USB Analog Output, 0-20mA/4-20mA Current Signal, Galvanic Isolation](https://en.tokyodevices.com/items/315)|`tdfa6032`|
|TDFA60350|[USB to 0-5V/1-5V, Analog Signal Output, Galvanic Isolation, Bus-Powered](https://en.tokyodevices.com/items/323)|`tdfa60350`|
|TDPC0201|["Reset Master" - a USB Watchdog](https://en.tokyodevices.com/items/288)|`tdpc0201`|
|TDPC0205|["Clock Dongle" - a USB Real-Time Clock for Current Time Sync., Battery Backup](https://en.tokyodevices.com/items/319)|`tdpc0205`|
|TDSN0700-UA|[USB General Purpose UV Sensor, UVA 295-490nm, Bus-Powered](https://en.tokyodevices.com/items/321)|`tdsn0700`|
|TDSN0700-UB|[USB General Purpose UV Sensor, UVB 240-320nm, Bus-Powered](https://en.tokyodevices.com/items/322)|`tdsn0700`|
|TDSN5200|[General-purpose, USB ToF Laser Distance Meter, Up to 6m, Bus-Powered](https://en.tokyodevices.com/items/326)|`tdsn5200`|
|TDSN604A8|[Genral-purpose Precision USB Current Sensor 20 Bit 0.8A Galvanic Isolation Bus-Powered](https://en.tokyodevices.com/items/332)|`tdsn604xx`|
|TDSN60408|[Genral-purpose Precision USB Current Sensor 20 Bit 8A Galvanic Isolation Bus-Powered](https://en.tokyodevices.com/items/331)|`tdsn604xx`|
|TDSN60420|[Genral-purpose Precision USB Current Sensor 20 Bit 20A Galvanic Isolation Bus-Powered](https://en.tokyodevices.com/items/330)|`tdsn604xx`|
|TDSN7200|[General-Purpose High-Precision USB Temperature, Humidity, and Pressure Sensor, -40 to 125��C, 0 to 100%RH, 260 to 1,260hPa, Bus Powered](https://en.tokyodevices.com/items/327)|`tdsn7200`|
|TDSN7360|[General-purpose high-precision USB accelerometer, 3-axis, low-noise, �}2.5g, 440Hz, bus-powered](https://en.tokyodevices.com/items/335)|`tdsn7360`|
|TDSN7400|[General purpose USB thermocouple temperature sensor K type -40 to 1200�� galvanic isolation Bus-Powered](https://en.tokyodevices.com/items/333)|`tdsn7400`|
|TDSN7502|[General purpose, Load cell to USB interface, Weight/Pressure sensor, 24-bit, Bus-power](https://en.tokyodevices.com/items/344)|`tdsn7502`|
|TDFA1104|[General purpose USB 7 segment LED display, 4 digits, 0.8 inch height, red](https://en.tokyodevices.com/items/350)|`tdfa1104`|

## Build instructions

Windows users are recommended to download and run the pre-built executable from
 [the Release page]((https://github.com/tokyodevices/td-usb/releases)).
For Linux users or Windows users who prefer to build it themselves, please follow the steps below to compile.

### Dependency

#### On Windows

- Microsoft Visual Studio is required to build.
- `Setupapi.lib` and `Hid.lib` must be available on library path. 
If you do not have these library, try to search Windows Driver Kit or Windows SDK. 

#### On Linux

- Git, GCC compiler and build toolkit
- TD-USB is depend on `libusb-dev` package. You should install it before compile.  
   ex.) `apt install libusb-dev` for Ubuntu/Debian.

#### On macOS

- Xcode Command Line Tools: `xcode-select --install`
- Homebrew: Install from https://brew.sh/
- libusb-compat package: `brew install libusb-compat`

### Compile

#### On Windows

Open `td-usb.sln` by Microsoft Visual Studio and build the project.
Note that you may add library and include path for `Setupapi.lib` and `Hid.lib`.
Please exclude the source code contained in the `/linux` folder from the build.

#### On Linux

Clone this repository to working directory. 


    % git clone https://github.com/tokyodevices/td-usb


Run make.


    % cd td-usb
    % make

#### On macOS

Clone this repository and install dependencies:


    % git clone https://github.com/tokyodevices/td-usb
    % brew install libusb-compat


Run make.


    % cd td-usb
    % make


Run `td-usb` with no-option shows version information.


    % ./td-usb
    td-usb version 0.2.6
    Copyright (C) 2020-2022 Tokyo Devices, Inc. (tokyodevices.jp)
    Usage: td-usb model_name[:serial] operation [options]
    Visit https://github.com/tokyodevices/td-usb/ for details


**Setting device permission on macOS**

On macOS, USB HID device access requires administrator privileges. You have several options:

1. **Use the helper script (recommended):**
   ```
   % ./run-td-usb.sh iws660 get
   ```

2. **Run with sudo:**
   ```
   % sudo ./td-usb iws660 get
   ```

3. **For development apps:** Use the provided `macos/entitlements.plist` with Xcode signing.

**Setting device permission on Linux**

USB devices that are connected to Linux platform firstly be under control of `udev` system.
Thus in most case it can only be accessed by root user. 

To add permission for normal user, `udev` needs some snippet. 
For Ubuntu or Debian, try to create `/etc/udev/rules.d/99-usb-tokyodevices.rules` which includes following line:

    SUBSYSTEM=="usb", ATTR{idVendor}=="16c0", ATTR{idProduct}=="05df", MODE="0666"

Note that `16c0` and `05df` should be replaced to VID/PID of the device which you need to use. 


## Usage

Available operation and option differ depending on the product model.


### Specifying product model

    td-usb (model_name) (operation) [options]

- `model_name` is fixed string that specifies product model. ex) `tdfa30608`


### Reading a value from the device

    td-usb (model_name) get [--format=(format)] [--loop=(interval)] [options]

- With `--loop` it will be repeated by `interval` milli-seconds.
- `[options]` is defiend by the product model.

### Writing a value to the device

    td-usb (model_name) set [(name)=(value)] [--loop]

 `(name)=(value)` pair is defiend by the product model.

With `--loop` option, TD-USB read repeatedly `(name)=(value)` pair from the standard input repeatedly.

     td-usb model_name[:serial] set --loop


### Listening to an event from the device

    td-usb (model_name) listen [--loop] [options]

- The process waits for an event and, when it is received, prints the event parameters to standard out.
- With `--loop` option the process will repeat continuously, otherwise terminate.
- `[options]` is defiend by the product model.


### Save current value of device registers

    td-usb (model_name) save

- The values will be loaded on next power-on sequence.


### Remove all firmware to switch DFU mode

    td-usb (model_name) destroy

- After this operation the device will be unavailable until new firmware is written.



## Exit code and error definition

|Exit Code|Name                        |Description                                 |
|---------|----------------------------|--------------------------------------------|
|0        |NO_ERROR                    |The process terminated successfully.|
|2        |UNKNOWN_DEVICE              |`model_name` is invalid.  |
|3        |UNKNOWN_OPERATION           |`operation` is invalid.    |
|4        |OPERATION_NOT_SUPPORTED     |Specified `operation` is not supproted for the device. |
|6        |INVALID_OPTION              |Invalid option format. |
|11       |DEVICE_OPEN_ERROR           |Failed to open the device. |
|12       |DEVICE_IO_ERROR             |Failed to communicate to the device. |
|13       |INVALID_FORMAT              |Specified `--format` is not available for the device. |
|14       |INVALID_RANGE			   |The given value is out of range. |


## Lunar Integration (macOS)

IWS660-CS illuminance sensor can be integrated with [Lunar](https://lunar.fyi/) app to automatically adjust monitor brightness based on ambient light.

### Architecture

```
IWS660-CS (USB) → bridge daemon (root) → ~/.td-usb/lux → lunarsensor agent (user) → Lunar
```

Detailed implementation document (Japanese): [docs/lunar-integration-macos-ja.md](docs/lunar-integration-macos-ja.md)

### Prerequisites

- macOS
- Lunar Pro (for Sensor Mode)
- Python 3.11, 3.12, or 3.13 (3.14+ is not recommended due to pydantic v1 compatibility risk)
- IWS660-CS sensor connected
- Homebrew (`brew install libusb-compat`)

### File Structure

```
scripts/
├── iws660-bridge.sh             # Reads sensor → writes ~/.td-usb/lux
├── start-lunarsensor-agent.sh   # Starts local lunarsensor API
├── install-launchd-services.sh  # Installs/reloads daemon+agent services
├── check-launchd-services.sh    # Verifies services and API after reboot/login
├── setup-lunar-integration.sh   # Installs lunarsensor + dependencies
├── start-lunar-integration.sh   # Manual fallback (single terminal)
└── configure-sudoers.sh         # Legacy fallback (sudoers mode)

launchd/
├── com.tokyodevices.iws660-bridge.plist # Root LaunchDaemon (USB read)
└── com.tokyodevices.iws660-lunar.plist  # User LaunchAgent (API)
```

### Quick Start

1. **Build td-usb:**
   ```bash
   make
   ```

2. **Setup lunarsensor:**
   ```bash
   ./scripts/setup-lunar-integration.sh
   ```

3. **Install launchd services (recommended):**
   ```bash
   ./scripts/install-launchd-services.sh
   ```
   - One-time administrator authentication is required during installation.
   - The installer rewrites plist paths for the current user/workspace before loading services.
   - Repository plist files are templates (`__HOME__`, `__PROJECT_DIR__`, `__USER__`) and do not contain personal paths.

4. **Verify service status/API:**
   ```bash
   ./scripts/check-launchd-services.sh
   ```

5. **Enable Sensor Mode in Lunar app**
   - Open Lunar settings
   - Enable "Sensor Mode"
   - Verify lux value is displayed

### Auto-start / Reboot Behavior

- `com.tokyodevices.iws660-bridge` (LaunchDaemon) starts as root after boot
- `com.tokyodevices.iws660-lunar` (LaunchAgent) starts at user login
- Runtime operation requires no `sudo` password prompts

### Management Commands

```bash
# Recommended status check
./scripts/check-launchd-services.sh

# Stop user agent
sudo launchctl bootout gui/$(id -u)/com.tokyodevices.iws660-lunar

# Start user agent
sudo launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.tokyodevices.iws660-lunar.plist
sudo launchctl kickstart -k gui/$(id -u)/com.tokyodevices.iws660-lunar

# Stop bridge daemon
sudo launchctl bootout system/com.tokyodevices.iws660-bridge

# Start bridge daemon
sudo launchctl bootstrap system /Library/LaunchDaemons/com.tokyodevices.iws660-bridge.plist

# View logs
tail -f ~/Library/Logs/td-usb/bridge-daemon.log
tail -f ~/Library/Logs/td-usb/lunarsensor-agent.log
tail -f ~/.td-usb/bridge.log
```

### Manual Operation

For temporary debugging without launchd:

```bash
./scripts/start-lunar-integration.sh
```

### Troubleshooting

**Device not detected:**
```bash
# Check USB connection
system_profiler SPUSBDataType | grep -A5 "16c0"

# Reinstall libusb
brew reinstall libusb-compat

# Test device directly
sudo ./td-usb iws660 get --format=simple
```

**LaunchDaemon install fails:**
```bash
# Validate plist syntax
plutil -p launchd/com.tokyodevices.iws660-bridge.plist
plutil -p launchd/com.tokyodevices.iws660-lunar.plist

# Retry install/reload
./scripts/install-launchd-services.sh
```

**Lunar not connecting to sensor:**
```bash
# Check Lunar settings
defaults read fyi.lunar.Lunar sensorHostname  # Should be: localhost
defaults read fyi.lunar.Lunar sensorPort      # Should be: 8000

# Reset Lunar sensor settings if needed
defaults write fyi.lunar.Lunar sensorHostname "localhost"
defaults write fyi.lunar.Lunar sensorPort 8000

# Test API endpoint
curl http://127.0.0.1:8000/sensor/ambient_light
```

**Service not starting after reboot/login:**
```bash
# Quick check
./scripts/check-launchd-services.sh

# Bridge daemon status (root)
sudo launchctl print system/com.tokyodevices.iws660-bridge | grep -E "state|last exit code|runs"

# Lunar agent status (user)
sudo launchctl print gui/$(id -u)/com.tokyodevices.iws660-lunar | grep -E "state|last exit code|runs"

# Reinstall/reload both services
./scripts/install-launchd-services.sh
```

### How It Works

1. Root LaunchDaemon runs `iws660-bridge.sh` and reads IWS660-CS every 2 seconds
2. Bridge writes lux values to `~/.td-usb/lux` (mode 600, owner=user)
3. User LaunchAgent runs `start-lunarsensor-agent.sh`
4. lunarsensor reads `~/.td-usb/lux` and serves `http://127.0.0.1:8000/sensor/ambient_light`
5. Lunar polls local API and adjusts monitor brightness

### Security Notes

- No runtime `sudo` call in normal operation (daemon handles USB access)
- Privileged boundary is explicit: root daemon (USB read) vs user agent (HTTP API)
- The lux file is stored under `~/.td-usb/lux` (private directory, `0700`)
- The bridge daemon rejects symlink paths for `~/.td-usb`, `lux`, and `bridge.log` to avoid unsafe root writes/chown
- The sensor API is bound to `127.0.0.1` to avoid exposing sensor data on LAN
- Legacy fallback remains available: `./scripts/configure-sudoers.sh` + `./scripts/start-lunar-integration.sh`


## License

TD-USB is released under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).

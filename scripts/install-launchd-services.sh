#!/bin/bash
# Install and (re)load launchd services for passwordless runtime operation.
# One-time admin authentication is required during installation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
USER_NAME="$(id -un)"
USER_UID="$(id -u)"
USER_HOME="$HOME"

AGENT_LABEL="com.tokyodevices.iws660-lunar"
DAEMON_LABEL="com.tokyodevices.iws660-bridge"
AGENT_SRC="$PROJECT_DIR/launchd/${AGENT_LABEL}.plist"
DAEMON_SRC="$PROJECT_DIR/launchd/${DAEMON_LABEL}.plist"
AGENT_DST="$USER_HOME/Library/LaunchAgents/${AGENT_LABEL}.plist"
DAEMON_DST="/Library/LaunchDaemons/${DAEMON_LABEL}.plist"
ROOT_HELPER_DIR="/usr/local/libexec/td-usb"
ROOT_TD_USB_BIN="$ROOT_HELPER_DIR/td-usb-root"
ROOT_BRIDGE_SCRIPT="$ROOT_HELPER_DIR/iws660-bridge-root.sh"
LOG_DIR="$USER_HOME/Library/Logs/td-usb"
LUX_DIR="$USER_HOME/.td-usb"
TMP_AGENT="$(mktemp "${TMPDIR:-/tmp}/td-usb-agent.XXXXXX.plist")"
TMP_DAEMON="$(mktemp "${TMPDIR:-/tmp}/td-usb-daemon.XXXXXX.plist")"
TMP_AGENT_BOOTSTRAP_ERR="$(mktemp "${TMPDIR:-/tmp}/td-usb-agent-bootstrap.XXXXXX.log")"
TMP_DAEMON_BOOTSTRAP_ERR="$(mktemp "${TMPDIR:-/tmp}/td-usb-daemon-bootstrap.XXXXXX.log")"
PLISTBUDDY="/usr/libexec/PlistBuddy"

cleanup() {
    rm -f "$TMP_AGENT" "$TMP_DAEMON" "$TMP_AGENT_BOOTSTRAP_ERR" "$TMP_DAEMON_BOOTSTRAP_ERR"
}
trap cleanup EXIT

wait_until_unloaded() {
    local target="$1"
    local attempts=30

    while sudo launchctl print "$target" >/dev/null 2>&1; do
        sleep 0.2
        attempts=$((attempts - 1))
        if [ "$attempts" -le 0 ]; then
            return 1
        fi
    done

    return 0
}

bootstrap_with_retry() {
    local domain="$1"
    local plist="$2"
    local err_file="$3"
    local attempts=3
    local i=1

    while [ "$i" -le "$attempts" ]; do
        if sudo launchctl bootstrap "$domain" "$plist" 2>"$err_file"; then
            return 0
        fi
        sleep 1
        i=$((i + 1))
    done

    return 1
}

echo "=== Install launchd services (bridge daemon + lunar agent) ==="
echo "User: $USER_NAME ($USER_UID)"
echo ""

if [ ! -x "$PROJECT_DIR/td-usb" ]; then
    echo "Error: td-usb binary not found: $PROJECT_DIR/td-usb" >&2
    echo "Run: make" >&2
    exit 1
fi

if [ ! -f "$AGENT_SRC" ] || [ ! -f "$DAEMON_SRC" ]; then
    echo "Error: launchd plist files are missing." >&2
    exit 1
fi

if [ ! -x "$PLISTBUDDY" ]; then
    echo "Error: PlistBuddy not found: $PLISTBUDDY" >&2
    exit 1
fi

if [ ! -x "$PROJECT_DIR/scripts/iws660-bridge.sh" ] || [ ! -x "$PROJECT_DIR/scripts/start-lunarsensor-agent.sh" ]; then
    echo "Error: required scripts are not executable." >&2
    exit 1
fi

mkdir -p "$USER_HOME/Library/LaunchAgents" "$LOG_DIR" "$LUX_DIR"
chmod 700 "$LUX_DIR" 2>/dev/null || true

cp "$AGENT_SRC" "$TMP_AGENT"
cp "$DAEMON_SRC" "$TMP_DAEMON"

"$PLISTBUDDY" -c "Set :ProgramArguments:0 $PROJECT_DIR/scripts/start-lunarsensor-agent.sh" "$TMP_AGENT"
"$PLISTBUDDY" -c "Set :WorkingDirectory $PROJECT_DIR" "$TMP_AGENT"
"$PLISTBUDDY" -c "Set :StandardOutPath $LOG_DIR/lunarsensor-agent.log" "$TMP_AGENT"
"$PLISTBUDDY" -c "Set :StandardErrorPath $LOG_DIR/lunarsensor-agent-error.log" "$TMP_AGENT"
"$PLISTBUDDY" -c "Set :EnvironmentVariables:LUNAR_LUX_FILE $LUX_DIR/lux" "$TMP_AGENT"

"$PLISTBUDDY" -c "Delete :ProgramArguments" "$TMP_DAEMON" >/dev/null 2>&1 || true
"$PLISTBUDDY" -c "Add :ProgramArguments array" "$TMP_DAEMON"
"$PLISTBUDDY" -c "Add :ProgramArguments:0 string /bin/bash" "$TMP_DAEMON"
"$PLISTBUDDY" -c "Add :ProgramArguments:1 string $ROOT_BRIDGE_SCRIPT" "$TMP_DAEMON"
"$PLISTBUDDY" -c "Set :WorkingDirectory $ROOT_HELPER_DIR" "$TMP_DAEMON"
"$PLISTBUDDY" -c "Set :StandardOutPath $LOG_DIR/bridge-daemon.log" "$TMP_DAEMON"
"$PLISTBUDDY" -c "Set :StandardErrorPath $LOG_DIR/bridge-daemon-error.log" "$TMP_DAEMON"
"$PLISTBUDDY" -c "Set :EnvironmentVariables:PATH /usr/sbin:/sbin:/usr/bin:/bin" "$TMP_DAEMON"
"$PLISTBUDDY" -c "Set :EnvironmentVariables:TD_USB_BIN $ROOT_TD_USB_BIN" "$TMP_DAEMON"
"$PLISTBUDDY" -c "Set :EnvironmentVariables:PROJECT_DIR $PROJECT_DIR" "$TMP_DAEMON"
"$PLISTBUDDY" -c "Set :EnvironmentVariables:LUNAR_LUX_FILE $LUX_DIR/lux" "$TMP_DAEMON"
"$PLISTBUDDY" -c "Set :EnvironmentVariables:LUNAR_LUX_OWNER $USER_NAME" "$TMP_DAEMON"
"$PLISTBUDDY" -c "Set :EnvironmentVariables:LUNAR_BRIDGE_LOG_FILE $LUX_DIR/bridge.log" "$TMP_DAEMON"

plutil -lint "$TMP_AGENT" >/dev/null
plutil -lint "$TMP_DAEMON" >/dev/null

install -m 644 "$TMP_AGENT" "$AGENT_DST"

echo "Requesting administrator privileges (one-time)..."
sudo -v

sudo install -d -o root -g wheel -m 755 "$ROOT_HELPER_DIR"
sudo install -o root -g wheel -m 755 "$PROJECT_DIR/td-usb" "$ROOT_TD_USB_BIN"
sudo install -o root -g wheel -m 755 "$PROJECT_DIR/scripts/iws660-bridge.sh" "$ROOT_BRIDGE_SCRIPT"
sudo install -d -o root -g wheel -m 755 /Library/LaunchDaemons
sudo install -o root -g wheel -m 644 "$TMP_DAEMON" "$DAEMON_DST"

sudo launchctl bootout "gui/$USER_UID/$AGENT_LABEL" >/dev/null 2>&1 || true
sudo launchctl bootout "system/$DAEMON_LABEL" >/dev/null 2>&1 || true
wait_until_unloaded "system/$DAEMON_LABEL" || true
wait_until_unloaded "gui/$USER_UID/$AGENT_LABEL" || true

if ! bootstrap_with_retry "system" "$DAEMON_DST" "$TMP_DAEMON_BOOTSTRAP_ERR"; then
    echo "Error: failed to bootstrap system daemon." >&2
    cat "$TMP_DAEMON_BOOTSTRAP_ERR" >&2
    exit 1
fi

if ! sudo launchctl bootstrap "gui/$USER_UID" "$AGENT_DST" 2>"$TMP_AGENT_BOOTSTRAP_ERR"; then
    if ! sudo launchctl asuser "$USER_UID" launchctl bootstrap "gui/$USER_UID" "$AGENT_DST" 2>>"$TMP_AGENT_BOOTSTRAP_ERR"; then
        echo "Error: failed to bootstrap user agent." >&2
        cat "$TMP_AGENT_BOOTSTRAP_ERR" >&2
        echo "Hint: run this command from a logged-in macOS user terminal." >&2
        exit 1
    fi
fi
sudo launchctl kickstart -k "gui/$USER_UID/$AGENT_LABEL" >/dev/null 2>&1 || true

sleep 2

echo ""
echo "=== Service status ==="
launchctl list | grep -E "com.tokyodevices.iws660-(bridge|lunar)" || true

echo ""
echo "[system/$DAEMON_LABEL]"
DAEMON_STATUS="$(launchctl print "system/$DAEMON_LABEL" 2>/dev/null || true)"
printf "%s\n" "$DAEMON_STATUS" | grep -E "state =|last exit code =|program =|path =|runs =" || true

echo ""
echo "[gui/$USER_UID/$AGENT_LABEL]"
sudo launchctl print "gui/$USER_UID/$AGENT_LABEL" 2>/dev/null | grep -E "state =|last exit code =|program =|path =|runs =" || true

DAEMON_LAST_EXIT="$(printf "%s\n" "$DAEMON_STATUS" | awk -F'= ' '/last exit code =/{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}')"
if [ -n "$DAEMON_LAST_EXIT" ] && [ "$DAEMON_LAST_EXIT" != "0" ] && [ "$DAEMON_LAST_EXIT" != "(never exited)" ]; then
    echo ""
    echo "=== Daemon error log (tail) ==="
    sudo tail -n 40 "$LOG_DIR/bridge-daemon-error.log" 2>/dev/null || true
    echo ""
    echo "=== Daemon output log (tail) ==="
    sudo tail -n 40 "$LOG_DIR/bridge-daemon.log" 2>/dev/null || true
    echo ""
    echo "=== Bridge debug log ==="
    if [ -f "$LUX_DIR/bridge.log" ]; then
        tail -n 40 "$LUX_DIR/bridge.log" || true
    else
        echo "missing: $LUX_DIR/bridge.log"
    fi
fi

echo ""
echo "Checking API endpoint..."
if curl -s http://127.0.0.1:8000/sensor/ambient_light >/dev/null 2>&1; then
    echo "OK: http://127.0.0.1:8000/sensor/ambient_light"
else
    echo "Warning: API did not respond yet. Check logs:"
    echo "  $LOG_DIR/bridge-daemon.log"
    echo "  $LOG_DIR/lunarsensor-agent.log"
fi

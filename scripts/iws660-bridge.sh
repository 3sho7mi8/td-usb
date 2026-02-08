#!/bin/bash
# IWS660-CS to lux file bridge for Lunar integration
# Reads lux values from the sensor and writes to a local file

set -euo pipefail
export PATH="/usr/sbin:/sbin:/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin${PATH:+:$PATH}"

resolve_project_dir() {
    local script_path="$0"
    local script_dir="${script_path%/*}"

    if [ "$script_dir" = "$script_path" ]; then
        script_dir="."
    fi

    (cd "$script_dir/.." && pwd)
}

PROJECT_DIR="${PROJECT_DIR:-}"
if [ -z "$PROJECT_DIR" ]; then
    PROJECT_DIR="$(resolve_project_dir)"
fi

TD_USB_BIN="${TD_USB_BIN:-$PROJECT_DIR/td-usb}"
SUDO_TD_USB_BIN="${SUDO_TD_USB_BIN:-/usr/local/libexec/td-usb/td-usb-root}"
LUX_FILE="${LUNAR_LUX_FILE:-$HOME/.td-usb/lux}"
LUX_OWNER="${LUNAR_LUX_OWNER:-}"
LUX_DIR="${LUX_FILE%/*}"
if [ "$LUX_DIR" = "$LUX_FILE" ]; then
    LUX_DIR="."
fi
DEBUG_LOG_FILE="${LUNAR_BRIDGE_LOG_FILE:-$LUX_DIR/bridge.log}"
DEBUG_LOG_DIR="${DEBUG_LOG_FILE%/*}"
if [ "$DEBUG_LOG_DIR" = "$DEBUG_LOG_FILE" ]; then
    DEBUG_LOG_DIR="."
fi
INTERVAL="${LUX_INTERVAL_SECONDS:-2}"  # seconds

CHMOD_BIN="/bin/chmod"
CHOWN_BIN="/usr/sbin/chown"
ID_BIN="/usr/bin/id"
MKDIR_BIN="/bin/mkdir"
MV_BIN="/bin/mv"

is_root() {
    [ "$("$ID_BIN" -u)" -eq 0 ]
}

fatal() {
    echo "[$(date '+%H:%M:%S')] $*" >&2
    exit 1
}

assert_not_symlink() {
    local target="$1"
    local description="$2"
    if [ -L "$target" ]; then
        fatal "$description must not be a symlink: $target"
    fi
}

append_debug_log() {
    local line="$1"

    if [ -e "$DEBUG_LOG_DIR" ]; then
        assert_not_symlink "$DEBUG_LOG_DIR" "Bridge log directory"
    fi
    if [ -e "$DEBUG_LOG_FILE" ]; then
        assert_not_symlink "$DEBUG_LOG_FILE" "Bridge log file"
    fi

    {
        "$MKDIR_BIN" -p "$DEBUG_LOG_DIR"
        printf "%s\n" "$line" >> "$DEBUG_LOG_FILE"
        "$CHMOD_BIN" 600 "$DEBUG_LOG_FILE"
        if is_root && [ -n "$LUX_OWNER" ]; then
            "$CHOWN_BIN" "$LUX_OWNER" "$DEBUG_LOG_FILE"
        fi
    } 2>/dev/null || true
}

log() {
    local line="[$(date '+%H:%M:%S')] $*"
    echo "$line"
    append_debug_log "$line"
}

log_error() {
    local line="[$(date '+%H:%M:%S')] $*"
    echo "$line" >&2
    append_debug_log "$line"
}

cleanup() {
    log "Bridge stopped"
    exit 0
}
trap cleanup INT TERM

preflight_checks() {
    if [ ! -x "$TD_USB_BIN" ]; then
        log_error "td-usb not found or not executable: $TD_USB_BIN"
        exit 1
    fi

    if [ -e "$LUX_DIR" ]; then
        assert_not_symlink "$LUX_DIR" "Lux directory"
    fi
    "$MKDIR_BIN" -p "$LUX_DIR"
    assert_not_symlink "$LUX_DIR" "Lux directory"
    "$CHMOD_BIN" 700 "$LUX_DIR" 2>/dev/null || true

    if [ -e "$DEBUG_LOG_DIR" ]; then
        assert_not_symlink "$DEBUG_LOG_DIR" "Bridge log directory"
    fi
    if [ -e "$DEBUG_LOG_FILE" ]; then
        assert_not_symlink "$DEBUG_LOG_FILE" "Bridge log file"
    fi

    if is_root && [ -n "$LUX_OWNER" ]; then
        if ! "$ID_BIN" "$LUX_OWNER" >/dev/null 2>&1; then
            log_error "LUNAR_LUX_OWNER does not exist: $LUX_OWNER"
            exit 1
        fi
        "$CHOWN_BIN" "$LUX_OWNER" "$LUX_DIR"
    fi

    if ! is_root; then
        if [ ! -x "$SUDO_TD_USB_BIN" ]; then
            log_error "Privileged helper is missing or not executable: $SUDO_TD_USB_BIN"
            log_error "Run: ./scripts/configure-sudoers.sh"
            exit 1
        fi

        local check_output=""
        local check_exit=0

        set +e
        check_output="$(sudo -n "$SUDO_TD_USB_BIN" 2>&1)"
        check_exit=$?
        set -e

        if [ "$check_exit" -eq 1 ] && printf "%s" "$check_output" | grep -Eq "password is required|a terminal is required"; then
            log_error "Passwordless sudo permission is missing for:"
            log_error "  $SUDO_TD_USB_BIN iws660 get --format=simple"
            log_error "Run: ./scripts/configure-sudoers.sh"
            exit 1
        fi
    fi
}

apply_lux_permissions() {
    local target="$1"
    assert_not_symlink "$target" "Lux file"
    "$CHMOD_BIN" 600 "$target"
    if is_root && [ -n "$LUX_OWNER" ]; then
        "$CHOWN_BIN" "$LUX_OWNER" "$target"
    fi
}

read_lux() {
    local output=""
    local exit_code=0

    set +e
    if is_root; then
        output="$("$TD_USB_BIN" iws660 get --format=simple 2>&1)"
        exit_code=$?
    else
        output="$(sudo -n "$SUDO_TD_USB_BIN" iws660 get --format=simple 2>&1)"
        exit_code=$?
    fi
    set -e

    if [ "$exit_code" -ne 0 ]; then
        log_error "td-usb read failed (exit=$exit_code): $output"
        return 1
    fi

    printf "%s" "$output"
}

write_lux_atomically() {
    local value="$1"
    local tmp_file="$LUX_FILE.tmp.$$"

    printf "%s\n" "$value" > "$tmp_file"
    apply_lux_permissions "$tmp_file"
    if [ -e "$LUX_FILE" ]; then
        assert_not_symlink "$LUX_FILE" "Lux file"
    fi
    "$MV_BIN" -f "$tmp_file" "$LUX_FILE"
    apply_lux_permissions "$LUX_FILE"
}

preflight_checks

log "Starting IWS660-CS to Lunar bridge..."
log "Output: $LUX_FILE"
log "Interval: ${INTERVAL}s"

while true; do
    if lux_raw="$(read_lux)"; then
        lux="$(printf "%s" "$lux_raw" | tr -d '\r\n')"

        # Validate lux value is a number
        if [[ "$lux" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
            write_lux_atomically "$lux"
            log "Lux: $lux"
        else
            log_error "Read error or invalid value: $lux_raw"
        fi
    fi

    sleep "$INTERVAL"
done

#!/bin/bash
# User-level lunarsensor launcher for Lunar Sensor Mode.
# Intended to be executed by launchd LaunchAgent.

set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LUNARSENSOR_DIR="$HOME/.lunarsensor"
VENV_PYTHON="$LUNARSENSOR_DIR/venv/bin/python"
VENV_UVICORN="$LUNARSENSOR_DIR/venv/bin/uvicorn"
CUSTOM_LUNARSENSOR="$PROJECT_DIR/scripts/lunarsensor-iws660.py"
TARGET_LUNARSENSOR="$LUNARSENSOR_DIR/lunarsensor.py"
LUX_FILE="${LUNAR_LUX_FILE:-$HOME/.td-usb/lux}"
LUX_DIR="$(dirname "$LUX_FILE")"

if [ ! -d "$LUNARSENSOR_DIR" ]; then
    echo "Error: lunarsensor directory not found: $LUNARSENSOR_DIR" >&2
    echo "Run: ./scripts/setup-lunar-integration.sh" >&2
    exit 1
fi

if [ ! -x "$VENV_PYTHON" ] || [ ! -x "$VENV_UVICORN" ]; then
    echo "Error: lunarsensor virtual environment is missing or broken." >&2
    echo "Run: ./scripts/setup-lunar-integration.sh" >&2
    exit 1
fi

if [ -f "$CUSTOM_LUNARSENSOR" ] && [ "$CUSTOM_LUNARSENSOR" -nt "$TARGET_LUNARSENSOR" ]; then
    cp "$CUSTOM_LUNARSENSOR" "$TARGET_LUNARSENSOR"
fi

mkdir -p "$LUX_DIR"
chmod 700 "$LUX_DIR" 2>/dev/null || true

if [ ! -f "$LUX_FILE" ]; then
    echo "Warning: lux file not found yet: $LUX_FILE" >&2
fi

export LUNAR_LUX_FILE="$LUX_FILE"
cd "$LUNARSENSOR_DIR"
exec "$VENV_UVICORN" lunarsensor:app --host 127.0.0.1 --port 8000

#!/bin/bash
# Integrated startup script for IWS660-CS + Lunar
# Starts both the bridge and lunarsensor

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LUNARSENSOR_DIR="$HOME/.lunarsensor"
VENV_PYTHON="$LUNARSENSOR_DIR/venv/bin/python"
LOG_DIR="$HOME/Library/Logs/td-usb"

# Create log directory
mkdir -p "$LOG_DIR"

# Cleanup function
cleanup() {
    echo ""
    echo "[$(date '+%H:%M:%S')] Shutting down..."

    # Kill child processes
    if [ -n "$BRIDGE_PID" ] && kill -0 "$BRIDGE_PID" 2>/dev/null; then
        kill "$BRIDGE_PID" 2>/dev/null
        echo "[$(date '+%H:%M:%S')] Bridge stopped (PID: $BRIDGE_PID)"
    fi

    if [ -n "$LUNARSENSOR_PID" ] && kill -0 "$LUNARSENSOR_PID" 2>/dev/null; then
        kill "$LUNARSENSOR_PID" 2>/dev/null
        echo "[$(date '+%H:%M:%S')] lunarsensor stopped (PID: $LUNARSENSOR_PID)"
    fi

    # Clean up lux file
    rm -f /tmp/lux

    echo "[$(date '+%H:%M:%S')] Cleanup complete"
    exit 0
}
trap cleanup INT TERM EXIT

# Parse options
FIX_VENV=false
for arg in "$@"; do
    case "$arg" in
        --fix-venv)
            FIX_VENV=true
            ;;
    esac
done

# Check prerequisites
if [ ! -d "$LUNARSENSOR_DIR" ]; then
    echo "Error: lunarsensor not installed."
    echo "Run: ./scripts/setup-lunar-integration.sh"
    exit 1
fi

if [ ! -f "$VENV_PYTHON" ]; then
    echo "Error: Python venv not found at $VENV_PYTHON"
    echo "Run: ./scripts/setup-lunar-integration.sh"
    exit 1
fi

# Verify venv Python is actually executable (detect broken symlinks)
if ! "$VENV_PYTHON" --version &>/dev/null; then
    LINKED_PYTHON="$(readlink "$VENV_PYTHON" 2>/dev/null || echo "unknown")"
    RECORDED_VERSION=""
    if [ -f "$LUNARSENSOR_DIR/.python-version" ]; then
        RECORDED_VERSION="$(cat "$LUNARSENSOR_DIR/.python-version")"
    fi

    echo "Error: Python venv is broken."
    echo "  Symlink: $VENV_PYTHON -> $LINKED_PYTHON"
    echo "  The Python version used to create the venv is no longer installed."
    if [ -n "$RECORDED_VERSION" ]; then
        echo "  Originally created with: $RECORDED_VERSION"
    fi
    echo ""
    echo "This typically happens when Homebrew updates Python to a newer version"
    echo "and removes the old one."
    echo ""

    if [ "$FIX_VENV" = true ]; then
        echo "Rebuilding venv (--fix-venv)..."
        if ! "$SCRIPT_DIR/setup-lunar-integration.sh"; then
            echo "Error: venv rebuild failed."
            exit 1
        fi

        # Verify rebuild succeeded
        if ! "$VENV_PYTHON" --version &>/dev/null; then
            echo "Error: venv rebuild completed but Python is still not executable."
            exit 1
        fi
        echo ""
        echo "Venv rebuilt successfully. Continuing startup..."
    else
        echo "To fix automatically, run:"
        echo "  $0 --fix-venv"
        echo ""
        echo "Or manually rebuild:"
        echo "  ./scripts/setup-lunar-integration.sh"
        exit 1
    fi
fi

if [ ! -f "$PROJECT_DIR/td-usb" ]; then
    echo "Error: td-usb not built."
    echo "Run: make"
    exit 1
fi

echo "=== IWS660-CS + Lunar Integration ==="
echo ""
echo "Logs: $LOG_DIR"
echo "Lux file: /tmp/lux"
echo ""
echo "Press Ctrl+C to stop"
echo ""

# Start bridge in background
echo "[$(date '+%H:%M:%S')] Starting IWS660-CS bridge..."
"$SCRIPT_DIR/iws660-bridge.sh" > "$LOG_DIR/bridge.log" 2>&1 &
BRIDGE_PID=$!
echo "[$(date '+%H:%M:%S')] Bridge started (PID: $BRIDGE_PID)"

# Wait for first lux value
sleep 3
if [ -f /tmp/lux ]; then
    echo "[$(date '+%H:%M:%S')] Initial lux value: $(cat /tmp/lux)"
else
    echo "[$(date '+%H:%M:%S')] Warning: No lux value yet (check device connection)"
fi

# Start lunarsensor with uvicorn
echo "[$(date '+%H:%M:%S')] Starting lunarsensor..."
cd "$LUNARSENSOR_DIR"
"$LUNARSENSOR_DIR/venv/bin/uvicorn" lunarsensor:app --host 0.0.0.0 --port 8000 > "$LOG_DIR/lunarsensor.log" 2>&1 &
LUNARSENSOR_PID=$!
echo "[$(date '+%H:%M:%S')] lunarsensor started (PID: $LUNARSENSOR_PID)"

# Wait a moment for server to start
sleep 2

# Test API
if curl -s http://localhost:8000/sensor/ambient_light > /dev/null 2>&1; then
    echo "[$(date '+%H:%M:%S')] API available at http://localhost:8000/sensor/ambient_light"
else
    echo "[$(date '+%H:%M:%S')] Warning: API not responding yet"
fi

echo ""
echo "[$(date '+%H:%M:%S')] Integration running. Enable Sensor Mode in Lunar."
echo ""

# Monitor processes
while true; do
    if ! kill -0 "$BRIDGE_PID" 2>/dev/null; then
        echo "[$(date '+%H:%M:%S')] Bridge process died. Check $LOG_DIR/bridge.log"
        break
    fi
    if ! kill -0 "$LUNARSENSOR_PID" 2>/dev/null; then
        echo "[$(date '+%H:%M:%S')] lunarsensor process died. Check $LOG_DIR/lunarsensor.log"
        break
    fi
    sleep 10
done

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

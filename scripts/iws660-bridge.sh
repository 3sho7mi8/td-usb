#!/bin/bash
# IWS660-CS to /tmp/lux bridge for Lunar integration
# Reads lux values from the sensor and writes to /tmp/lux

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LUX_FILE="/tmp/lux"
INTERVAL=2  # seconds

# Handle termination signals
cleanup() {
    echo "[$(date '+%H:%M:%S')] Bridge stopped"
    exit 0
}
trap cleanup INT TERM

echo "[$(date '+%H:%M:%S')] Starting IWS660-CS to Lunar bridge..."
echo "[$(date '+%H:%M:%S')] Output: $LUX_FILE"
echo "[$(date '+%H:%M:%S')] Interval: ${INTERVAL}s"

while true; do
    # Read lux value from sensor
    lux=$(sudo "$SCRIPT_DIR/td-usb" iws660 get --format=simple 2>/dev/null)

    # Validate lux value is a number
    if [[ "$lux" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        echo "$lux" > "$LUX_FILE"
        echo "[$(date '+%H:%M:%S')] Lux: $lux"
    else
        echo "[$(date '+%H:%M:%S')] Read error or invalid value: $lux" >&2
    fi

    sleep $INTERVAL
done

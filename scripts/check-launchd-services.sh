#!/bin/bash
# Verify launchd services and sensor API after login/reboot.

set -euo pipefail

USER_UID="$(id -u)"
LUX_FILE="${LUNAR_LUX_FILE:-$HOME/.td-usb/lux}"
AGENT_LABEL="com.tokyodevices.iws660-lunar"
DAEMON_LABEL="com.tokyodevices.iws660-bridge"

echo "=== launchd entries ==="
if launchctl print "gui/$USER_UID/$AGENT_LABEL" >/dev/null 2>&1; then
    echo "$AGENT_LABEL: loaded (gui/$USER_UID)"
else
    echo "$AGENT_LABEL: not loaded"
fi

if launchctl print "system/$DAEMON_LABEL" >/dev/null 2>&1; then
    echo "$DAEMON_LABEL: loaded (system)"
else
    echo "$DAEMON_LABEL: not loaded"
fi

echo ""
echo "=== agent detail ==="
launchctl print "gui/$USER_UID/$AGENT_LABEL" 2>/dev/null | grep -E "state =|last exit code =|runs =" || true

echo ""
echo "=== daemon detail ==="
launchctl print "system/$DAEMON_LABEL" 2>/dev/null | grep -E "state =|last exit code =|runs =" || true

echo ""
echo "=== lux file ==="
if [ -f "$LUX_FILE" ]; then
    ls -l "$LUX_FILE"
    echo "value: $(cat "$LUX_FILE")"
else
    echo "missing: $LUX_FILE"
fi

echo ""
echo "=== API ==="
curl -s http://127.0.0.1:8000/sensor/ambient_light || true
echo ""

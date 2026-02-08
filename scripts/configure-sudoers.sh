#!/bin/bash
# Configure sudoers for non-interactive IWS660-CS reading.
# Restricts NOPASSWD to the exact command used by iws660-bridge.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TD_USB_BIN="$PROJECT_DIR/td-usb"
ROOT_HELPER_DIR="/usr/local/libexec/td-usb"
ROOT_TD_USB_BIN="$ROOT_HELPER_DIR/td-usb-root"
RULE_FILE="/etc/sudoers.d/td-usb"
TMP_RULE="$(mktemp "${TMPDIR:-/tmp}/td-usb-sudoers.XXXXXX")"
USER_NAME="$(id -un)"
GROUP_NAME="wheel"

cleanup() {
    rm -f "$TMP_RULE"
}
trap cleanup EXIT

if [ ! -x "$TD_USB_BIN" ]; then
    echo "Error: td-usb not found or not executable: $TD_USB_BIN" >&2
    echo "Run: make" >&2
    exit 1
fi

if ! dscl . -read "/Groups/$GROUP_NAME" >/dev/null 2>&1; then
    GROUP_NAME="root"
fi

cat > "$TMP_RULE" <<EOF
$USER_NAME ALL=(root) NOPASSWD: $ROOT_TD_USB_BIN iws660 get --format=simple
EOF

chmod 440 "$TMP_RULE"

echo "Installing sudoers rule to $RULE_FILE"
echo "Installing privileged helper binary to $ROOT_TD_USB_BIN"
echo "Rule:"
cat "$TMP_RULE"
echo ""

sudo install -d -o root -g "$GROUP_NAME" -m 755 "$ROOT_HELPER_DIR"
sudo install -o root -g "$GROUP_NAME" -m 755 "$TD_USB_BIN" "$ROOT_TD_USB_BIN"
sudo install -o root -g "$GROUP_NAME" -m 440 "$TMP_RULE" "$RULE_FILE"
sudo visudo -cf "$RULE_FILE" >/dev/null

echo "sudoers configured successfully."
echo "Verifying non-interactive sudo access..."

if sudo -n "$ROOT_TD_USB_BIN" iws660 get --format=simple >/dev/null 2>&1; then
    echo "Verification OK: sudo -n command succeeded."
else
    echo "Warning: sudoers rule installed, but sensor read failed." >&2
    echo "Check USB connection and run: sudo -n $ROOT_TD_USB_BIN iws660 get --format=simple" >&2
fi

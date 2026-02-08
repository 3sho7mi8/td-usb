#!/bin/bash
# Setup script for Lunar integration with IWS660-CS
# Installs lunarsensor and configures Lunar app

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LUNARSENSOR_DIR="$HOME/.lunarsensor"
VENV_DIR="$LUNARSENSOR_DIR/venv"
USE_SUDOERS=false

for arg in "$@"; do
    case "$arg" in
        --sudoers|--with-sudoers)
            USE_SUDOERS=true
            ;;
        --skip-sudoers)
            USE_SUDOERS=false
            ;;
    esac
done

echo "=== IWS660-CS Lunar Integration Setup ==="
echo ""

if [ "$USE_SUDOERS" = true ]; then
    echo "Configuring sudoers for non-interactive sensor reads..."
    "$SCRIPT_DIR/configure-sudoers.sh"
    echo ""
else
    echo "Skipping sudoers configuration (LaunchDaemon mode recommended)."
    echo "To enable old sudoers mode, use: $0 --sudoers"
    echo ""
fi

# Find suitable Python version
# Priority: 3.13 > 3.12 > 3.11 > python3
# Note: 3.14+ is excluded by default due to pydantic v1 compatibility risk
PYTHON_BIN=""
for py in python3.13 python3.12 python3.11 python3; do
    if command -v "$py" &> /dev/null; then
        PYTHON_BIN="$py"
        break
    fi
done

if [ -z "$PYTHON_BIN" ]; then
    echo "Error: Python 3 is required but not installed."
    echo "Install with: brew install python@3.13"
    exit 1
fi

PYTHON_VERSION="$("$PYTHON_BIN" --version 2>&1)"
echo "Using Python: $PYTHON_BIN ($PYTHON_VERSION)"

# Clone or update lunarsensor
if [ -d "$LUNARSENSOR_DIR" ]; then
    echo "lunarsensor already exists at $LUNARSENSOR_DIR"
    echo "Updating..."
    cd "$LUNARSENSOR_DIR"
    git pull origin master 2>/dev/null || echo "Could not update (offline or no changes)"
else
    echo "Cloning lunarsensor repository..."
    git clone https://github.com/alin23/lunarsensor.git "$LUNARSENSOR_DIR"
fi

# Create virtual environment if not exists (or recreate if Python version mismatch)
if [ -d "$VENV_DIR" ]; then
    echo ""
    echo "Removing existing venv to ensure correct Python version..."
    rm -rf "$VENV_DIR"
fi

echo ""
echo "Creating Python virtual environment..."
"$PYTHON_BIN" -m venv "$VENV_DIR"

# Record Python version for future diagnostics
echo "$PYTHON_VERSION" > "$LUNARSENSOR_DIR/.python-version"
echo "Recorded Python version to $LUNARSENSOR_DIR/.python-version"

# Install dependencies using venv pip directly (no activate needed)
echo ""
echo "Installing Python dependencies in venv..."
"$VENV_DIR/bin/pip" install --upgrade pip --quiet
"$VENV_DIR/bin/pip" install "aiohttp>=3.9.0" "fastapi>=0.92.0" "sse-starlette>=1.2.1" "uvicorn>=0.20.0" "pydantic>=1.10.10,<2.0" --quiet

# Install customized lunarsensor.py with Lunar v6.9.6 sensor endpoint support
CUSTOM_LUNARSENSOR="$SCRIPT_DIR/lunarsensor-iws660.py"
if [ -f "$CUSTOM_LUNARSENSOR" ]; then
    echo ""
    echo "Installing customized lunarsensor.py (Lunar v6.9.6 compatible)..."
    cp "$CUSTOM_LUNARSENSOR" "$LUNARSENSOR_DIR/lunarsensor.py"
else
    echo ""
    echo "Warning: Custom lunarsensor not found at $CUSTOM_LUNARSENSOR"
    echo "Using upstream lunarsensor.py (may produce 404s with Lunar v6.9.6+)"
fi

# Configure Lunar to use local sensor
echo ""
echo "Configuring Lunar app..."
defaults write fyi.lunar.Lunar sensorHostname "localhost"
defaults write fyi.lunar.Lunar sensorPort 8000

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Install launchd services: ./scripts/install-launchd-services.sh"
echo "2. Verify status: ./scripts/check-launchd-services.sh"
echo "3. Enable Sensor Mode in Lunar app"
echo ""
echo "Manual fallback: ./scripts/start-lunar-integration.sh"

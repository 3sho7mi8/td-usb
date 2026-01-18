#!/bin/bash
# Setup script for Lunar integration with IWS660-CS
# Installs lunarsensor and configures Lunar app

set -e

LUNARSENSOR_DIR="$HOME/.lunarsensor"
VENV_DIR="$LUNARSENSOR_DIR/venv"

echo "=== IWS660-CS Lunar Integration Setup ==="
echo ""

# Find suitable Python version (3.12 preferred for compatibility)
PYTHON_BIN=""
for py in python3.12 python3.11 python3.13 python3; do
    if command -v "$py" &> /dev/null; then
        PYTHON_BIN="$py"
        break
    fi
done

if [ -z "$PYTHON_BIN" ]; then
    echo "Error: Python 3 is required but not installed."
    echo "Install with: brew install python@3.12"
    exit 1
fi

echo "Using Python: $PYTHON_BIN ($($PYTHON_BIN --version))"

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

# Activate venv and install dependencies
echo ""
echo "Installing Python dependencies in venv..."
cd "$LUNARSENSOR_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip --quiet

# Install with updated versions (original requirements.txt has outdated aiohttp)
pip install "aiohttp>=3.9.0" "fastapi>=0.92.0" "sse-starlette>=1.2.1" "uvicorn>=0.20.0" "pydantic>=1.10.10,<2.0" --quiet

deactivate

# Configure Lunar to use local sensor
echo ""
echo "Configuring Lunar app..."
defaults write fyi.lunar.Lunar sensorHostname "localhost"
defaults write fyi.lunar.Lunar sensorPort 8000

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Start the bridge: ./scripts/iws660-bridge.sh"
echo "2. Start lunarsensor: cd ~/.lunarsensor && ./venv/bin/uvicorn lunarsensor:app --port 8000"
echo "3. Enable Sensor Mode in Lunar app"
echo ""
echo "Or use the integrated script: ./scripts/start-lunar-integration.sh"

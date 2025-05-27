#!/bin/bash
# Helper script to run td-usb with proper permissions on macOS

if [ "$#" -eq 0 ]; then
    echo "TD-USB Helper Script for macOS"
    echo "Usage: $0 <device> <command> [options...]"
    echo "Example: $0 iws660 get"
    echo "Example: $0 iws660 get --format=json"
    exit 1
fi

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Requesting administrator privileges for USB device access..."
    sudo "$0" "$@"
    exit $?
fi

# Run td-usb with all arguments
exec "$(dirname "$0")/td-usb" "$@"
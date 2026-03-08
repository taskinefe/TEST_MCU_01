#!/bin/bash

# Simple OpenLane Runner - Works from current directory
# Just run this from your project root directory

echo "=========================================="
echo "OpenLane GDS Generation - Simple Version"
echo "=========================================="
echo "Current directory: $(pwd)"
echo ""

# Check if we're in the right place
if [ ! -f "openlane/user_project_wrapper/config.json" ]; then
    echo "ERROR: openlane/user_project_wrapper/config.json not found!"
    echo ""
    echo "Please run this script from the project root directory containing:"
    echo "  - openlane/user_project_wrapper/config.json"
    echo "  - verilog/rtl/"
    echo ""
    echo "Usage:"
    echo "  cd /path/to/your/caravel_project"
    echo "  ./run_openlane_simple.sh"
    exit 1
fi

echo "✅ Found config file: openlane/user_project_wrapper/config.json"
echo ""

# Try to find openlane
OPENLANE_CMD=""

if command -v openlane &> /dev/null; then
    OPENLANE_CMD="openlane"
elif [ -x "/home/openhands/.nix-profile/bin/openlane" ]; then
    OPENLANE_CMD="/home/openhands/.nix-profile/bin/openlane"
elif [ -x "$HOME/.nix-profile/bin/openlane" ]; then
    OPENLANE_CMD="$HOME/.nix-profile/bin/openlane"
elif [ -x "/usr/local/bin/openlane" ]; then
    OPENLANE_CMD="/usr/local/bin/openlane"
fi

if [ -n "$OPENLANE_CMD" ]; then
    echo "✅ Found OpenLane: $OPENLANE_CMD"
    echo ""
    echo "=========================================="
    echo "Starting OpenLane Flow..."
    echo "=========================================="
    echo "This will take 3-7 hours. Please be patient!"
    echo ""
    
    "$OPENLANE_CMD" openlane/user_project_wrapper/config.json --ef-save-views-to .
    
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "✅ SUCCESS!"
        echo "=========================================="
        if [ -f "gds/user_project_wrapper.gds" ]; then
            echo "GDS file generated:"
            ls -lh gds/user_project_wrapper.gds
        fi
    else
        echo ""
        echo "=========================================="
        echo "❌ OpenLane failed with exit code: $EXIT_CODE"
        echo "=========================================="
        echo "Check logs in: openlane/user_project_wrapper/runs/"
    fi
else
    echo "❌ OpenLane not found!"
    echo ""
    echo "Please install OpenLane first or use Docker:"
    echo "  docker run --rm -v \$(pwd):/work -w /work efabless/openlane:latest openlane/user_project_wrapper/config.json"
fi

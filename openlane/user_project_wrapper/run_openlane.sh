#!/bin/bash

# OpenLane GDS Generation Script for Motor Control Project
# This script automatically runs OpenLane to generate your GDS file

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Determine project root (go up to find the directory with openlane/ folder)
if [ -d "$SCRIPT_DIR/openlane/user_project_wrapper" ]; then
    # Running from project root
    PROJECT_DIR="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/user_project_wrapper" ]; then
    # Running from openlane/ directory
    PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
elif [ -f "$SCRIPT_DIR/config.json" ]; then
    # Running from openlane/user_project_wrapper/ directory
    PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
else
    # Try current directory
    PROJECT_DIR="$(pwd)"
fi

CONFIG_FILE="$PROJECT_DIR/openlane/user_project_wrapper/config.json"

echo "=========================================="
echo "OpenLane GDS Generation Script"
echo "=========================================="
echo "Script location: $SCRIPT_DIR"
echo "Project root:    $PROJECT_DIR"
echo "Config file:     $CONFIG_FILE"
echo ""

# Navigate to project directory
cd "$PROJECT_DIR" || {
    echo "ERROR: Cannot change to project directory: $PROJECT_DIR"
    echo "Current directory: $(pwd)"
    exit 1
}

# Check if config exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Config file not found: $CONFIG_FILE"
    exit 1
fi

echo "Checking OpenLane installation..."
echo ""

# Method 1: Try openlane command
if command -v openlane &> /dev/null; then
    echo "✅ Found 'openlane' command"
    echo "Running: openlane $CONFIG_FILE --ef-save-views-to ."
    echo ""
    openlane "$CONFIG_FILE" --ef-save-views-to .
    
# Method 2: Try /openlane/flow.tcl
elif [ -f "/openlane/flow.tcl" ]; then
    echo "✅ Found /openlane/flow.tcl"
    echo "Running: /openlane/flow.tcl -design openlane/user_project_wrapper"
    echo ""
    cd "$PROJECT_DIR"
    /openlane/flow.tcl -design openlane/user_project_wrapper
    
# Method 3: Try Docker
else
    echo "⚠️  OpenLane not found locally, trying Docker..."
    
    # Check if Docker is available
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker not found either!"
        echo "Please install OpenLane or Docker first."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker ps &> /dev/null; then
        echo "Starting Docker daemon..."
        sudo dockerd > /tmp/docker.log 2>&1 &
        sleep 5
        
        # Check again
        if ! docker ps &> /dev/null; then
            echo "ERROR: Could not start Docker"
            echo "Check /tmp/docker.log for details"
            exit 1
        fi
    fi
    
    echo "✅ Docker is running"
    echo "Pulling OpenLane Docker image (this may take a while)..."
    docker pull efabless/openlane:latest
    
    echo ""
    echo "Running OpenLane in Docker container..."
    echo "Working directory: $PROJECT_DIR"
    
    # Run OpenLane directly (image has openlane as entrypoint)
    docker run --rm \
      -v "$PROJECT_DIR":/work \
      -w /work \
      efabless/openlane:latest \
      openlane/user_project_wrapper/config.json --ef-save-views-to /work
fi

echo ""
echo "=========================================="
echo "Checking Results..."
echo "=========================================="

# Check if GDS was generated
if [ -f "$PROJECT_DIR/gds/user_project_wrapper.gds" ]; then
    echo "✅ SUCCESS! GDS file generated:"
    ls -lh "$PROJECT_DIR/gds/user_project_wrapper.gds"
    
    echo ""
    echo "Checking DRC violations..."
    DRC_FILE=$(find "$PROJECT_DIR/openlane/user_project_wrapper/runs" -name "magic.drc" -type f | sort -r | head -1)
    if [ -f "$DRC_FILE" ]; then
        echo "DRC Report: $DRC_FILE"
        cat "$DRC_FILE" | tail -10
    fi
    
    echo ""
    echo "Checking LVS status..."
    LVS_FILE=$(find "$PROJECT_DIR/openlane/user_project_wrapper/runs" -name "lvs.rpt" -type f | sort -r | head -1)
    if [ -f "$LVS_FILE" ]; then
        echo "LVS Report: $LVS_FILE"
        grep -i "pass\|fail\|error" "$LVS_FILE" || echo "Check file manually"
    fi
    
    echo ""
    echo "=========================================="
    echo "✅ GDS GENERATION COMPLETE!"
    echo "=========================================="
    echo "Output file: gds/user_project_wrapper.gds"
    echo ""
    echo "To view in 3D:"
    echo "  klayout gds/user_project_wrapper.gds"
    echo "  (Press Shift+F4 for 3D view)"
    echo ""
    
else
    echo "❌ ERROR: GDS file not generated!"
    echo ""
    echo "Check logs in:"
    echo "  openlane/user_project_wrapper/runs/*/logs/"
    echo ""
    echo "Latest log files:"
    find "$PROJECT_DIR/openlane/user_project_wrapper/runs" -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -5 | cut -d' ' -f2
    exit 1
fi

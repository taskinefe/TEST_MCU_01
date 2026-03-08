# Run OpenLane to Generate GDS - Exact Commands

## Quick Start - Copy & Paste These Commands

### Step 1: Navigate to Your Project

```bash
cd /workspace/caravel_multi_peripheral
```

---

### Step 2: Run OpenLane (MAIN COMMAND)

```bash
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

**That's it!** Wait 3-7 hours for completion.

---

## Alternative: If OpenLane Command Not Found

### Check if OpenLane is Available

```bash
# Try direct path
/openlane/flow.tcl -design openlane/user_project_wrapper

# Or check Docker
docker --version
```

---

## Method A: Direct OpenLane (If Installed)

### Run Directly

```bash
cd /workspace/caravel_multi_peripheral

# Main command
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

**Expected output:**
```
OpenLane Container (...)
OpenLane 2.x.x

[STEP 1] Running Synthesis
[STEP 2] Running Floorplan
[STEP 3] Running Placement
[STEP 4] Running CTS
[STEP 5] Running Routing  ← Takes 1-3 hours
[STEP 6] Running DRC & LVS
[STEP 7] Generating GDS

Flow complete!
```

---

## Method B: Using Docker (Most Common)

### Step 1: Start Docker (If Needed)

```bash
# Check if Docker is running
docker ps

# If error, start Docker daemon
sudo dockerd > /tmp/docker.log 2>&1 &
sleep 5

# Verify Docker works
docker ps
```

---

### Step 2: Run OpenLane with Docker

```bash
cd /workspace/caravel_multi_peripheral

# Run OpenLane Docker container
docker run --rm -it \
  -v $(pwd):/workspace \
  -v $PDK_ROOT:$PDK_ROOT \
  -e PDK_ROOT=$PDK_ROOT \
  efabless/openlane:latest \
  openlane /workspace/openlane/user_project_wrapper/config.json
```

**If PDK_ROOT is not set:**

```bash
# Set PDK_ROOT first
export PDK_ROOT=$HOME/.volare/sky130A

# Or typical location
export PDK_ROOT=/usr/share/pdk/sky130A

# Then run Docker command above
```

---

### Simplified Docker Command

```bash
cd /workspace/caravel_multi_peripheral

# All-in-one command
docker run --rm -it \
  -v $(pwd):/workspace \
  efabless/openlane:latest \
  /bin/bash -c "cd /workspace && openlane openlane/user_project_wrapper/config.json --ef-save-views-to ."
```

---

## Method C: Interactive Mode (For Debugging)

### Start Interactive OpenLane

```bash
cd /workspace/caravel_multi_peripheral

# Start interactive mode
openlane -it openlane/user_project_wrapper/config.json
```

**Inside OpenLane shell, run these commands one by one:**

```tcl
# Prepare design
prep -design user_project_wrapper -overwrite

# Run each stage
run_synthesis
run_floorplan
run_placement
run_cts
run_routing
run_magic_spice_export
run_magic_drc
run_lvs
run_magic

# Save outputs
save_final_views

# Generate summary
generate_final_summary_report

# Exit
exit
```

---

## After Running: Verify Success

### Check if GDS Was Created

```bash
# Check GDS file exists
ls -lh gds/user_project_wrapper.gds

# Should show something like:
# -rw-r--r-- 1 user user 127M Jan 15 10:23 user_project_wrapper.gds
```

---

### Check Reports

```bash
# Check DRC (should be 0 violations)
cat openlane/user_project_wrapper/runs/*/reports/magic/magic.drc

# Check LVS (should say PASS)
grep -i "pass\|fail" openlane/user_project_wrapper/runs/*/reports/lvs/lvs.rpt

# View summary
cat openlane/user_project_wrapper/runs/*/reports/final_summary_report.csv
```

---

## Common Issues & Quick Fixes

### Issue 1: "openlane: command not found"

**Fix:**

```bash
# Use full path
/openlane/flow.tcl -design openlane/user_project_wrapper

# Or use Docker method (see Method B above)
```

---

### Issue 2: "PDK_ROOT not defined"

**Fix:**

```bash
# Find PDK location
find $HOME -name "sky130A" 2>/dev/null | grep -v ".git"

# Set PDK_ROOT (use your actual path)
export PDK_ROOT=$HOME/.volare/sky130A

# Verify
ls $PDK_ROOT/libs.tech/openlane

# Make permanent
echo 'export PDK_ROOT=$HOME/.volare/sky130A' >> ~/.bashrc
```

---

### Issue 3: Docker Not Running

**Fix:**

```bash
# Check Docker status
docker ps

# If error, start Docker
sudo dockerd > /tmp/docker.log 2>&1 &
sleep 5

# Verify
docker ps
```

---

## Complete Workflow - Copy All These Commands

```bash
#!/bin/bash
# Complete OpenLane run script

# Navigate to project
cd /workspace/caravel_multi_peripheral

# Clean previous runs (optional)
# rm -rf openlane/user_project_wrapper/runs/*

# Method 1: Try direct OpenLane
if command -v openlane &> /dev/null; then
    echo "Running OpenLane directly..."
    openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
    
elif [ -f "/openlane/flow.tcl" ]; then
    echo "Running OpenLane via flow.tcl..."
    /openlane/flow.tcl -design openlane/user_project_wrapper
    
else
    echo "Running OpenLane via Docker..."
    
    # Check Docker
    if ! docker ps &> /dev/null; then
        echo "Starting Docker..."
        sudo dockerd > /tmp/docker.log 2>&1 &
        sleep 5
    fi
    
    # Run OpenLane in Docker
    docker run --rm -it \
      -v $(pwd):/workspace \
      efabless/openlane:latest \
      /bin/bash -c "cd /workspace && openlane openlane/user_project_wrapper/config.json --ef-save-views-to ."
fi

# Check result
if [ -f "gds/user_project_wrapper.gds" ]; then
    echo "SUCCESS! GDS generated:"
    ls -lh gds/user_project_wrapper.gds
    
    # Check DRC
    echo ""
    echo "DRC Report:"
    cat openlane/user_project_wrapper/runs/*/reports/magic/magic.drc | tail -5
    
else
    echo "ERROR: GDS not generated!"
    echo "Check logs in: openlane/user_project_wrapper/runs/*/logs/"
fi
```

**Save this as `run_openlane.sh` and run:**

```bash
chmod +x run_openlane.sh
./run_openlane.sh
```

---

## Monitor Progress While Running

### Check Current Stage

```bash
# See what's happening
tail -f openlane/user_project_wrapper/runs/*/logs/*/*.log

# Or check latest log
ls -lt openlane/user_project_wrapper/runs/*/logs/*/*.log | head -1
```

---

### Check if Still Running

```bash
# Check process
ps aux | grep openlane

# Check CPU usage
top | grep -E "openlane|yosys|openroad|magic"
```

---

## Expected Timeline

```
Stage               Time        What to Expect
─────────────────────────────────────────────────
Synthesis           30-60 min   CPU: 100% on 1 core
Floorplan           10-20 min   Macro placement
Placement           30-60 min   Cell placement
CTS                 15-30 min   Clock tree
Routing             60-180 min  ← LONGEST (be patient!)
DRC/LVS             20-40 min   Verification
GDS Gen             5-10 min    Final file

TOTAL               3-7 hours   ☕ Take breaks!
```

---

## Final Output Location

```
✅ Main GDS:  gds/user_project_wrapper.gds
✅ Reports:   openlane/user_project_wrapper/runs/*/reports/
✅ Logs:      openlane/user_project_wrapper/runs/*/logs/
```

---

## View Your GDS

```bash
# Install KLayout if needed
sudo apt install klayout

# View GDS
klayout gds/user_project_wrapper.gds

# Enable 3D view: Press Shift+F4
```

---

## Success Criteria

**Your GDS is good if:**

- ✅ File exists: `gds/user_project_wrapper.gds`
- ✅ File size: 50-200 MB
- ✅ DRC violations: 0
- ✅ LVS status: PASS
- ✅ Opens in KLayout without errors

---

## Summary - Just Run This!

### Absolute Simplest Method

```bash
cd /workspace/caravel_multi_peripheral
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

**Wait 3-7 hours.**

**Done!** GDS at `gds/user_project_wrapper.gds`

---

**Your motor control chip layout ready for fabrication!** 🎉

# Practical OpenLane Usage Guide - Generate GDS for Your Motor Control Project

## What is OpenLane?

**OpenLane** is an automated RTL-to-GDS flow that takes your Verilog code and produces a manufacturable chip layout.

- **Input:** Verilog RTL files + Configuration
- **Output:** GDS file (chip layout)
- **Process:** Fully automated physical design flow
- **Time:** 3-7 hours for complete flow

---

## Before You Start

### Check Prerequisites

```bash
# 1. Verify OpenLane is installed
which openlane
# Or try:
ls /openlane/flow.tcl

# 2. Check PDK (Process Design Kit) is available
echo $PDK_ROOT
# Should show path like: /home/user/.volare/sky130A

# 3. Verify you're in the project directory
cd /workspace/caravel_multi_peripheral
pwd

# 4. Check your config file exists
ls openlane/user_project_wrapper/config.json
```

**If any of these fail, see Troubleshooting section at the end.**

---

## Method 1: Simple One-Command Approach (Recommended)

### The Easiest Way

```bash
# Navigate to your project
cd /workspace/caravel_multi_peripheral

# Run OpenLane (one command!)
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

**That's it!** This single command:
1. Reads your configuration
2. Synthesizes your RTL
3. Places and routes the design
4. Generates the GDS file
5. Saves all outputs to your project directory

**Expected time:** 3-7 hours

---

### What Happens

**Terminal output will look like:**

```
OpenLane Container (...)
OpenLane 2.x.x

[STEP 1] Running Synthesis
[INFO]: Current directory: openlane/user_project_wrapper
[INFO]: Preparation complete
[INFO]: Running synthesis...
[STEP 2] Running Floorplan
[INFO]: Running floorplan...
[STEP 3] Running Placement
[INFO]: Running global placement...
[INFO]: Running detailed placement...
[STEP 4] Running CTS
[INFO]: Running clock tree synthesis...
[STEP 5] Running Routing
[INFO]: Running global routing...
[INFO]: Running detailed routing...
[STEP 6] Running DRC & LVS
[INFO]: Running Magic DRC...
[INFO]: Running LVS...
[STEP 7] Generating Final Views
[INFO]: Generating GDS...
[INFO]: Copying to output directory...

Flow complete!
```

---

### Monitor Progress

**While running, you can check progress:**

```bash
# In another terminal, check current stage
tail -20 openlane/user_project_wrapper/runs/*/logs/*/*.log

# Or watch live
tail -f openlane/user_project_wrapper/runs/*/logs/synthesis/1-synthesis.log

# Check if OpenLane is still running
ps aux | grep openlane
```

---

## Method 2: Using OpenLane Docker Container

### If OpenLane is Installed via Docker

```bash
# Navigate to project
cd /workspace/caravel_multi_peripheral

# Run OpenLane Docker container
docker run -it \
  -v $(pwd):/workspace \
  -v $PDK_ROOT:$PDK_ROOT \
  -e PDK_ROOT=$PDK_ROOT \
  efabless/openlane:latest

# Inside container:
cd /workspace
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

---

## Method 3: Interactive Mode (For Debugging)

### Step-by-Step Control

**Start OpenLane in interactive mode:**

```bash
cd /workspace/caravel_multi_peripheral

# Launch interactive OpenLane
openlane -it openlane/user_project_wrapper/config.json
```

**Inside OpenLane shell:**

```tcl
# OpenLane Shell (Tcl commands)

# Step 1: Prepare design
prep -design user_project_wrapper -overwrite

# Step 2: Run synthesis
run_synthesis

# Step 3: Run floorplan
run_floorplan

# Step 4: Run placement
run_placement

# Step 5: Run CTS (Clock Tree Synthesis)
run_cts

# Step 6: Run routing
run_routing

# Step 7: SPICE extraction (for LVS)
run_magic_spice_export

# Step 8: Run DRC checks
run_magic_drc

# Step 9: Run LVS
run_lvs

# Step 10: Generate final GDS
run_magic

# Step 11: Save all views
save_final_views

# Step 12: Generate summary report
generate_final_summary_report

# Exit
exit
```

**Advantages:**
- Run one step at a time
- Inspect results after each stage
- Modify parameters on the fly
- Resume from any checkpoint

---

## Understanding config.json

### Your OpenLane Configuration File

**Location:** `openlane/user_project_wrapper/config.json`

**Basic structure:**

```json
{
  "DESIGN_NAME": "user_project_wrapper",
  "VERILOG_FILES": [
    "dir::../../verilog/rtl/defines.v",
    "dir::../../verilog/rtl/user_project.v",
    "dir::../../verilog/rtl/user_project_wrapper.v"
  ],
  "CLOCK_PORT": "wb_clk_i",
  "CLOCK_PERIOD": 25,
  "FP_PDN_MULTILAYER": false,
  "DIE_AREA": "0 0 2920 3520",
  "FP_SIZING": "absolute",
  "PL_TARGET_DENSITY": 0.7,
  "MACROS": {
    // Your macros defined here
  }
}
```

**Key parameters:**

| Parameter | Meaning | Example |
|-----------|---------|---------|
| `DESIGN_NAME` | Top module name | `user_project_wrapper` |
| `VERILOG_FILES` | RTL source files | List of .v files |
| `CLOCK_PORT` | Main clock signal | `wb_clk_i` |
| `CLOCK_PERIOD` | Clock period (ns) | `25` (40 MHz) |
| `DIE_AREA` | Chip size (µm) | `0 0 2920 3520` |
| `PL_TARGET_DENSITY` | Core utilization | `0.7` (70%) |

---

## Output Files Explained

### After Successful Run

```
📁 Your Project
├── gds/
│   └── user_project_wrapper.gds ⭐ FINAL GDS FILE!
│
├── lef/
│   └── user_project_wrapper.lef   (Abstract layout)
│
├── lib/
│   └── user_project_wrapper.lib   (Timing library)
│
├── verilog/gl/
│   └── user_project_wrapper.v     (Gate-level netlist)
│
├── spef/multicorner/
│   ├── user_project_wrapper.min.spef
│   ├── user_project_wrapper.nom.spef
│   └── user_project_wrapper.max.spef
│
└── openlane/user_project_wrapper/runs/
    └── RUN_<timestamp>/
        ├── config.json             (Used configuration)
        ├── reports/
        │   ├── synthesis/
        │   │   └── 1-synthesis.stat.rpt
        │   ├── floorplan/
        │   ├── placement/
        │   ├── routing/
        │   │   └── routing.drc
        │   ├── magic/
        │   │   └── magic.drc ⭐ Check this!
        │   ├── lvs/
        │   │   └── lvs.rpt ⭐ Check this!
        │   └── final_summary_report.csv ⭐ Overview
        │
        ├── logs/
        │   ├── synthesis/
        │   ├── floorplan/
        │   ├── placement/
        │   ├── cts/
        │   └── routing/
        │
        └── final/
            └── gds/
                └── user_project_wrapper.gds
```

---

## Step-by-Step: Your First Run

### Complete Walkthrough

**Step 1: Open Terminal**

```bash
# Open a terminal window
```

**Step 2: Navigate to Project**

```bash
cd /workspace/caravel_multi_peripheral

# Verify you're in the right place
ls openlane/user_project_wrapper/config.json
# Should show: openlane/user_project_wrapper/config.json
```

**Step 3: Check Environment**

```bash
# Check OpenLane
which openlane || ls /openlane/flow.tcl

# Check PDK
echo $PDK_ROOT
# Should show path to sky130A

# If PDK_ROOT is empty, set it:
export PDK_ROOT=$HOME/.volare/sky130A
# Or wherever your PDK is installed
```

**Step 4: Clean Previous Runs (Optional)**

```bash
# Remove old runs to start fresh
rm -rf openlane/user_project_wrapper/runs/*

# Remove old GDS
rm -f gds/user_project_wrapper.gds*
```

**Step 5: Run OpenLane**

```bash
# THE MAIN COMMAND!
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

**Press Enter and wait!**

**Step 6: Wait (3-7 hours)**

☕ **Get coffee**  
📖 **Read documentation**  
🏃 **Take a break**

**Step 7: Check Completion**

```bash
# Look for success message in terminal:
# [SUCCESS]: Flow complete!

# Or check if GDS exists:
ls -lh gds/user_project_wrapper.gds
```

**Step 8: Verify Results**

```bash
# Check DRC (should be clean)
cat openlane/user_project_wrapper/runs/*/reports/magic/magic.drc
# Look for: "COUNT: 0" (no violations)

# Check LVS (should pass)
grep -i "pass\|fail" openlane/user_project_wrapper/runs/*/reports/lvs/lvs.rpt
# Should say: "PASS"

# View summary
cat openlane/user_project_wrapper/runs/*/reports/final_summary_report.csv
```

**Step 9: View Your GDS**

```bash
klayout gds/user_project_wrapper.gds

# In KLayout, press Shift+F4 for 3D view
```

**Done!** 🎉

---

## Common OpenLane Commands

### Useful Commands

```bash
# Basic run
openlane <path-to-config.json>

# Run with custom output directory
openlane <config.json> --ef-save-views-to <output-dir>

# Interactive mode
openlane -it <config.json>

# Specify tag/version
openlane -tag <run-name> <config.json>

# Overwrite previous run
openlane -overwrite <config.json>

# Resume from checkpoint
openlane -resume <config.json>

# Clean run directory
openlane -clean <config.json>
```

---

## Checking Progress During Run

### Monitor Live

**Option 1: Check Current Stage**

```bash
# Find current log file
ls -lt openlane/user_project_wrapper/runs/*/logs/*/*.log | head -1

# View it
tail -50 <path-to-latest-log>
```

**Option 2: Watch Log Live**

```bash
# Find synthesis log
tail -f openlane/user_project_wrapper/runs/*/logs/synthesis/1-synthesis.log

# When synthesis completes, check placement
tail -f openlane/user_project_wrapper/runs/*/logs/placement/*.log

# Then routing (longest step)
tail -f openlane/user_project_wrapper/runs/*/logs/routing/*.log
```

**Option 3: Check Process**

```bash
# See if OpenLane is running
ps aux | grep openlane

# Check CPU usage
top | grep openlane
```

---

## Understanding the Stages

### What Each Stage Does

**1. Synthesis (30-60 min)**
```
Input:  Your Verilog RTL
Tool:   Yosys
Output: Gate-level netlist
What:   Converts RTL to standard cells
```

**2. Floorplan (10-20 min)**
```
Input:  Netlist + Macros
Tool:   OpenROAD
Output: Initial placement
What:   Defines chip area, places macros, creates power grid
```

**3. Placement (30-60 min)**
```
Input:  Netlist + Floorplan
Tool:   OpenROAD (Global + Detailed)
Output: Cell locations
What:   Places all standard cells optimally
```

**4. Clock Tree Synthesis (15-30 min)**
```
Input:  Placed design + Clock spec
Tool:   TritonCTS
Output: Clock distribution network
What:   Builds balanced clock tree to minimize skew
```

**5. Routing (60-180 min) ⏰ LONGEST**
```
Input:  Placed design
Tool:   FastRoute + TritonRoute
Output: All connections routed
What:   Creates metal connections between all cells
```

**6. Verification (20-40 min)**
```
Tools:  Magic (DRC), Netgen (LVS)
Output: Violation reports
What:   Checks design rules and schematic matching
```

**7. GDS Generation (5-10 min)**
```
Tool:   Magic
Output: user_project_wrapper.gds
What:   Final layout file for fabrication
```

---

## Troubleshooting

### Problem: "openlane: command not found"

**Solution:**

```bash
# Option 1: Check if OpenLane installed
ls /openlane/flow.tcl

# If exists, run with full path:
/openlane/flow.tcl -design openlane/user_project_wrapper

# Option 2: Add to PATH
export PATH="/openlane:$PATH"
echo 'export PATH="/openlane:$PATH"' >> ~/.bashrc

# Option 3: Use Docker
docker run -it -v $(pwd):/workspace efabless/openlane:latest
```

---

### Problem: "PDK_ROOT not set"

**Error message:**
```
[ERROR]: PDK_ROOT is not defined
```

**Solution:**

```bash
# Find your PDK installation
find $HOME -name "sky130A" 2>/dev/null

# Typical locations:
# - $HOME/.volare/sky130A
# - /usr/share/pdk/sky130A
# - /foss/pdks/sky130A

# Set PDK_ROOT (replace path with your actual path)
export PDK_ROOT=$HOME/.volare/sky130A

# Make permanent
echo 'export PDK_ROOT=$HOME/.volare/sky130A' >> ~/.bashrc
source ~/.bashrc

# Verify
echo $PDK_ROOT
ls $PDK_ROOT/libs.tech/openlane
```

---

### Problem: Synthesis Fails

**Error:**
```
[ERROR]: Synthesis failed
[ERROR]: Check logs at: ...
```

**Debug steps:**

```bash
# 1. Check synthesis log
cat openlane/user_project_wrapper/runs/*/logs/synthesis/1-synthesis.log | tail -100

# 2. Common issues:
# - Missing Verilog files
# - Syntax errors in RTL
# - Undefined modules
# - Missing includes

# 3. Verify all RTL files exist
cat openlane/user_project_wrapper/config.json | grep "VERILOG_FILES" -A 20

# 4. Check each file
ls -l verilog/rtl/*.v

# 5. Fix RTL errors and re-run
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

---

### Problem: DRC Violations

**After run completes:**
```
[WARNING]: DRC violations found: X
```

**Check violations:**

```bash
# View DRC report
cat openlane/user_project_wrapper/runs/*/reports/magic/magic.drc

# Common violations:
# - Metal spacing too small
# - Via size incorrect  
# - Power grid issues

# Solutions:
# 1. Reduce density
# 2. Increase die area
# 3. Adjust routing layers
```

**Fix in config.json:**

```json
{
  "PL_TARGET_DENSITY": 0.6,  // Reduce from 0.7
  "DIE_AREA": "0 0 3000 3600"  // Increase if needed
}
```

**Re-run:**

```bash
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

---

### Problem: Routing Fails

**Error:**
```
[ERROR]: Routing could not complete
```

**Solutions:**

**1. Reduce core utilization:**

```json
{
  "PL_TARGET_DENSITY": 0.5  // Lower = more space for routing
}
```

**2. Increase die area:**

```json
{
  "DIE_AREA": "0 0 3200 3800"  // Make chip bigger
}
```

**3. Allow more routing iterations:**

```json
{
  "ROUTING_CORES": 8,  // Use more CPU cores
  "GLB_RT_MAXLAYER": 6,  // Use more metal layers
  "RT_MAX_LAYER": "met5"
}
```

---

### Problem: Out of Memory

**Error:**
```
[ERROR]: Killed (OOM)
```

**Solutions:**

1. **Use machine with more RAM** (16 GB minimum, 32 GB recommended)

2. **Reduce design complexity:**
   - Remove non-essential features
   - Reduce SRAM size
   - Simplify routing

3. **Close other applications**

4. **Enable swap:**
   ```bash
   sudo swapon --show
   sudo dd if=/dev/zero of=/swapfile bs=1G count=8
   sudo chmod 600 /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

---

## Performance Optimization

### Speed Up OpenLane

**1. Use all CPU cores:**

```json
{
  "ROUTING_CORES": 8,  // Match your CPU core count
  "RUN_HEURISTIC_DIODE_INSERTION": false
}
```

**2. Skip redundant checks:**

```json
{
  "RUN_KLAYOUT": false,  // Use Magic only
  "RUN_KLAYOUT_XOR": false,
  "RUN_KLAYOUT_DRC": false
}
```

**3. Reduce optimization iterations:**

```json
{
  "PL_RESIZER_DESIGN_OPTIMIZATIONS": 0,
  "PL_RESIZER_TIMING_OPTIMIZATIONS": 0,
  "GLB_RESIZER_TIMING_OPTIMIZATIONS": 0
}
```

**Warning:** This may reduce quality! Only use for quick testing.

---

## Advanced: Custom Scripts

### Automate Multiple Runs

**Create `run_all.sh`:**

```bash
#!/bin/bash

# Run all macros, then wrapper

PROJECT_ROOT="/workspace/caravel_multi_peripheral"
cd $PROJECT_ROOT

# Array of all macros (if you have any)
MACROS=(
    # Add your macro names here
    # "motor_pwm_wb"
    # "foc_transforms_wb"
)

# Run each macro
for macro in "${MACROS[@]}"; do
    echo "Running OpenLane for $macro..."
    openlane openlane/$macro/config.json --ef-save-views-to $PROJECT_ROOT
    
    if [ $? -ne 0 ]; then
        echo "ERROR: $macro failed!"
        exit 1
    fi
done

# Run user_project_wrapper (main)
echo "Running OpenLane for user_project_wrapper..."
openlane openlane/user_project_wrapper/config.json --ef-save-views-to $PROJECT_ROOT

if [ $? -eq 0 ]; then
    echo "SUCCESS! GDS generated."
    ls -lh gds/user_project_wrapper.gds
else
    echo "ERROR: user_project_wrapper failed!"
    exit 1
fi
```

**Run:**

```bash
chmod +x run_all.sh
./run_all.sh
```

---

## Quick Reference

### Essential Commands

```bash
# Generate GDS (main command)
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .

# Interactive mode
openlane -it openlane/user_project_wrapper/config.json

# Clean and re-run
rm -rf openlane/user_project_wrapper/runs/*
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .

# Check if running
ps aux | grep openlane

# View latest log
ls -lt openlane/user_project_wrapper/runs/*/logs/*/*.log | head -1

# Check DRC
cat openlane/user_project_wrapper/runs/*/reports/magic/magic.drc

# Check LVS
cat openlane/user_project_wrapper/runs/*/reports/lvs/lvs.rpt

# View GDS
klayout gds/user_project_wrapper.gds
```

---

## Summary

### How to Use OpenLane

**Simplest Method:**

```bash
cd /workspace/caravel_multi_peripheral
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

**Wait:** 3-7 hours  
**Output:** `gds/user_project_wrapper.gds`

### What You Need

1. ✅ OpenLane installed
2. ✅ PDK (SKY130) installed
3. ✅ Config file (`config.json`)
4. ✅ RTL files (`.v` files)
5. ✅ 3-7 hours of patience

### What You Get

1. ✅ GDS file (chip layout)
2. ✅ LEF file (abstract)
3. ✅ LIB file (timing)
4. ✅ Gate-level netlist
5. ✅ Complete reports

---

**Your chip is ready for fabrication!** 🎉

**Created:** 2026-03-07  
**Status:** Complete OpenLane usage guide

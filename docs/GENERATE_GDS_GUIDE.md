# Complete Guide: Generate GDS File for Your Motor Control Project

## What is a GDS File?

**GDS (Graphic Database System)** is the final layout file format used for chip fabrication.

- **Contains:** Complete physical layout of your chip
- **Includes:** All metal layers, vias, transistors, placement
- **Used for:** Manufacturing (tape-out), visualization, verification
- **Format:** Binary file (`.gds` or `.gds.gz`)

---

## Overview: Two-Stage Process

Your motor control project requires **TWO OpenLane runs**:

1. **Stage 1:** Generate GDS for each macro (user_project components)
2. **Stage 2:** Generate final GDS for user_project_wrapper (complete chip)

---

## Prerequisites

### Check Your Environment

```bash
# Verify OpenLane is available
which openlane
# Should show: /openlane/flow.tcl or similar

# Check PDK
echo $PDK_ROOT
# Should show: /path/to/pdk/sky130A

# Verify you're in project directory
cd /workspace/caravel_multi_peripheral
pwd
```

---

## Stage 1: Generate Macro GDS Files (If Needed)

### What Are Macros?

**Macros** are pre-designed blocks that you instantiate in your top-level design.

**Your project may have macros like:**
- Motor PWM module
- FOC transforms
- ADC wrapper
- Overcurrent protection

**Check if you have macros:**

```bash
ls openlane/
# Look for directories like:
# - motor_pwm_wb
# - foc_transforms_wb
# - overcurrent_protection_wb
# etc.
```

---

### Run OpenLane for Each Macro

**For each macro directory in `openlane/`:**

```bash
# General syntax
openlane openlane/<macro_name>/config.json --ef-save-views-to <project_root>

# Example: If you have motor_pwm_wb macro
openlane openlane/motor_pwm_wb/config.json --ef-save-views-to /workspace/caravel_multi_peripheral
```

**Wait time:** 30 minutes - 2 hours per macro (depending on size)

**Output files:**
```
gds/<macro_name>.gds
lef/<macro_name>.lef
lib/<macro_name>.lib
verilog/gl/<macro_name>.v
```

---

### Script to Run All Macros

**Create `run_macros.sh`:**

```bash
#!/bin/bash

# Run OpenLane for all macros in the project

PROJECT_ROOT="/workspace/caravel_multi_peripheral"
OPENLANE_DIR="$PROJECT_ROOT/openlane"

# Find all macro directories (exclude user_project_wrapper)
for macro_dir in "$OPENLANE_DIR"/*; do
    if [ -d "$macro_dir" ] && [ "$(basename $macro_dir)" != "user_project_wrapper" ]; then
        macro_name=$(basename "$macro_dir")
        
        echo "=================================="
        echo "Running OpenLane for: $macro_name"
        echo "=================================="
        
        # Check if config.json exists
        if [ -f "$macro_dir/config.json" ]; then
            openlane "$macro_dir/config.json" --ef-save-views-to "$PROJECT_ROOT"
            
            if [ $? -eq 0 ]; then
                echo "✅ SUCCESS: $macro_name"
            else
                echo "❌ FAILED: $macro_name"
                exit 1
            fi
        else
            echo "⚠️  No config.json found for $macro_name"
        fi
        
        echo ""
    fi
done

echo "=================================="
echo "All macros completed!"
echo "=================================="
```

**Run the script:**

```bash
chmod +x run_macros.sh
./run_macros.sh
```

**Note:** This may take several hours if you have many macros!

---

## Stage 2: Generate user_project_wrapper GDS

### This is the Main Step!

**The user_project_wrapper contains your entire motor control system.**

### Run OpenLane

```bash
cd /workspace/caravel_multi_peripheral

# Run OpenLane for user_project_wrapper
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

**Wait time:** 1-4 hours (depending on design complexity)

---

### What Happens During OpenLane Run

**OpenLane performs these steps:**

1. **Synthesis** (30 min)
   - Converts RTL to gate-level netlist
   - Technology mapping

2. **Floorplanning** (10 min)
   - Places macros
   - Defines chip area
   - Creates power grid

3. **Placement** (45 min)
   - Places standard cells
   - Optimizes placement

4. **CTS (Clock Tree Synthesis)** (20 min)
   - Builds clock distribution network
   - Minimizes clock skew

5. **Routing** (1-2 hours)
   - Routes all signals
   - Connects cells and macros

6. **Verification** (30 min)
   - DRC (Design Rule Check)
   - LVS (Layout vs Schematic)
   - Antenna check

7. **GDS Generation** (10 min)
   - Final layout file
   - **YOUR GDS FILE!** 🎉

---

### Monitor Progress

**OpenLane shows progress in terminal:**

```
[INFO]: Running Synthesis...
[INFO]: Synthesis complete
[INFO]: Running Floorplan...
[INFO]: Floorplan complete
[INFO]: Running Placement...
[INFO]: Placement complete
[INFO]: Running CTS...
[INFO]: CTS complete
[INFO]: Running Routing...
[INFO]: Routing complete
[INFO]: Running Magic DRC...
[INFO]: DRC complete
[INFO]: Running LVS...
[INFO]: LVS complete
[INFO]: Generating final GDS...
[SUCCESS]: Flow complete!
```

**Estimated total time:** 1-4 hours

---

### Output Files

**After successful run, you'll have:**

```
gds/
  ├── user_project_wrapper.gds        ← YOUR FINAL GDS! ⭐
  └── user_project_wrapper.gds.gz     ← Compressed version

lef/
  └── user_project_wrapper.lef        ← Layout abstract

lib/
  └── user_project_wrapper.lib        ← Timing library

verilog/
  └── gl/
      └── user_project_wrapper.v      ← Gate-level netlist

spef/
  └── multicorner/
      ├── user_project_wrapper.min.spef
      ├── user_project_wrapper.nom.spef
      └── user_project_wrapper.max.spef

openlane/user_project_wrapper/runs/
  └── RUN_<timestamp>/
      ├── reports/                    ← All reports
      ├── logs/                       ← Detailed logs
      └── final/
          └── gds/
              └── user_project_wrapper.gds
```

---

## Verify Your GDS

### Check File Size

```bash
ls -lh gds/user_project_wrapper.gds

# Should be 50-200 MB depending on design
# Example output:
# -rw-r--r-- 1 user user 127M Jan 15 10:23 user_project_wrapper.gds
```

**If file is very small (<1 MB), something went wrong!**

---

### Check OpenLane Summary

```bash
# View final summary
cat openlane/user_project_wrapper/runs/RUN_*/reports/final_summary_report.csv

# Key metrics:
# - DIEAREA_mm^2: Should be ~10.28
# - Instance_Count: Should be thousands
# - Runtime: Total time taken
# - Magic_violations: Should be 0
# - LVS_errors: Should be 0
```

---

### View in KLayout

```bash
klayout gds/user_project_wrapper.gds

# Quick check:
# - Should see rectangular chip
# - Should see metal layers
# - Should see standard cells
# - Zoom in to verify detail
```

**If you see layout, GDS is valid!** ✅

---

## Troubleshooting

### Problem: OpenLane Command Not Found

**Error:**
```
bash: openlane: command not found
```

**Solution:**

```bash
# Check if OpenLane is installed
ls /openlane/

# If exists, run with full path:
/openlane/flow.tcl -design openlane/user_project_wrapper

# Or add to PATH:
export PATH="/openlane:$PATH"
```

---

### Problem: PDK Not Found

**Error:**
```
[ERROR]: PDK_ROOT is not defined
```

**Solution:**

```bash
# Set PDK_ROOT
export PDK_ROOT=/path/to/pdk/sky130A

# For typical installations:
export PDK_ROOT=$HOME/.volare/sky130A

# Or system-wide:
export PDK_ROOT=/usr/share/pdk/sky130A

# Add to ~/.bashrc for persistence
echo 'export PDK_ROOT=/path/to/pdk/sky130A' >> ~/.bashrc
```

---

### Problem: Synthesis Fails

**Error:**
```
[ERROR]: Synthesis failed
```

**Solutions:**

1. **Check RTL files exist:**
   ```bash
   ls verilog/rtl/*.v
   # All required files should be present
   ```

2. **Check config.json:**
   ```bash
   cat openlane/user_project_wrapper/config.json
   # Verify all paths are correct
   ```

3. **Check log file:**
   ```bash
   tail -100 openlane/user_project_wrapper/runs/*/logs/synthesis/1-synthesis.log
   # Look for specific error messages
   ```

---

### Problem: DRC Violations

**Error:**
```
[ERROR]: Magic DRC violations found
```

**Solution:**

```bash
# View DRC report
cat openlane/user_project_wrapper/runs/*/reports/magic/magic.drc

# Common fixes:
# - Adjust FP_PDN_* parameters in config.json
# - Increase DIE_AREA
# - Check macro placement

# Re-run after fixes:
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

---

### Problem: LVS Errors

**Error:**
```
[ERROR]: LVS check failed
```

**Solution:**

```bash
# View LVS report
cat openlane/user_project_wrapper/runs/*/reports/lvs/lvs.rpt

# Common causes:
# - Missing power connections
# - Unconnected nets
# - Mismatched instances

# Fix in RTL and re-run
```

---

### Problem: Routing Fails

**Error:**
```
[ERROR]: Routing could not complete
```

**Solutions:**

1. **Reduce utilization:**
   ```json
   // In config.json
   {
     "FP_CORE_UTIL": 50  // Reduce from 70
   }
   ```

2. **Increase die area:**
   ```json
   {
     "DIE_AREA": "0 0 3000 3600"  // Increase from 2920x3520
   }
   ```

3. **Simplify design:** Remove non-essential features

---

## Step-by-Step: Complete Process

### Full Workflow

```bash
# Step 1: Navigate to project
cd /workspace/caravel_multi_peripheral

# Step 2: Verify environment
which openlane
echo $PDK_ROOT

# Step 3: Clean previous runs (optional)
rm -rf openlane/user_project_wrapper/runs/*
rm -rf gds/user_project_wrapper.gds*

# Step 4: Run macros (if you have any)
# For each macro:
openlane openlane/<macro_name>/config.json --ef-save-views-to .

# Step 5: Run user_project_wrapper (MAIN STEP)
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .

# Step 6: Wait 1-4 hours ⏱️
# Monitor progress in terminal

# Step 7: Verify output
ls -lh gds/user_project_wrapper.gds

# Step 8: Check summary
cat openlane/user_project_wrapper/runs/*/reports/final_summary_report.csv

# Step 9: View in KLayout
klayout gds/user_project_wrapper.gds

# Step 10: Enable 3D view
# Press Shift+F4 in KLayout

# Done! 🎉
```

---

## Advanced: Interactive OpenLane

### Run in Interactive Mode

**For debugging and control:**

```bash
# Start OpenLane in interactive mode
openlane -it openlane/user_project_wrapper/config.json

# Inside OpenLane shell:
% prep -design user_project_wrapper

% run_synthesis
% run_floorplan
% run_placement
% run_cts
% run_routing

% run_magic
% run_magic_spice_export
% run_magic_drc
% run_lvs

% generate_final_summary_report
% save_final_views

% exit
```

**Benefits:**
- Stop at any stage to inspect
- Modify parameters on-the-fly
- Resume from checkpoint

---

## Time Estimates

### Expected Duration

| Stage | Time | Notes |
|-------|------|-------|
| **Synthesis** | 30-60 min | RTL → gates |
| **Floorplan** | 10-20 min | Macro placement |
| **Placement** | 30-60 min | Cell placement |
| **CTS** | 15-30 min | Clock tree |
| **Routing** | 60-180 min | Main bottleneck |
| **Verification** | 20-40 min | DRC/LVS |
| **GDS Gen** | 5-10 min | Final output |
| **TOTAL** | **3-7 hours** | **Full flow** |

**Your mileage may vary** based on:
- Design complexity
- Number of instances
- Routing congestion
- CPU speed

---

## Optimization Tips

### Speed Up OpenLane

**1. Use Multiple Cores:**

```json
// In config.json
{
  "RUN_KLAYOUT": false,        // Skip KLayout DRC (use Magic only)
  "ROUTING_CORES": 8,          // Use 8 CPU cores for routing
  "SYNTH_STRATEGY": "AREA 0"   // Faster synthesis
}
```

**2. Reduce Verification:**

```json
{
  "RUN_KLAYOUT_XOR": false,
  "RUN_KLAYOUT_DRC": false,
  "QUIT_ON_MAGIC_DRC": false   // Don't stop on minor DRC
}
```

**3. Use Previous Results:**

```bash
# Don't delete runs/ directory
# OpenLane can resume from checkpoints
```

---

## Final GDS Checklist

### Before Tape-Out

- [ ] **GDS file exists** (`gds/user_project_wrapper.gds`)
- [ ] **File size reasonable** (50-200 MB)
- [ ] **DRC violations = 0** (check reports)
- [ ] **LVS clean** (no errors)
- [ ] **Antenna violations = 0**
- [ ] **Opens in KLayout** without errors
- [ ] **Layout looks correct** (visual inspection)
- [ ] **Die area correct** (2920 × 3520 µm)
- [ ] **All macros present** (check hierarchy)
- [ ] **Power grid complete** (check met4/met5)

---

## Quick Start: Minimal Commands

### Just Want GDS? Run This:

```bash
# Navigate to project
cd /workspace/caravel_multi_peripheral

# Generate GDS (one command)
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .

# Wait 3-7 hours...
# ☕ Take a break!

# Verify
ls -lh gds/user_project_wrapper.gds

# View
klayout gds/user_project_wrapper.gds

# Done! 🎉
```

**That's it!** One command generates your GDS.

---

## What to Do While Waiting

### 3-7 Hour Wait Time

**Productive activities:**

1. ✅ **Review documentation**
2. ✅ **Prepare firmware**
3. ✅ **Design PCB**
4. ✅ **Write test plans**
5. ✅ **Coffee break** ☕
6. ✅ **Lunch** 🍔
7. ✅ **Exercise** 🏃
8. ✅ **Plan next chip** 🎯

**Monitor progress occasionally:**
```bash
# Check if still running
ps aux | grep openlane

# Check latest log
tail -f openlane/user_project_wrapper/runs/*/logs/<stage>/*.log
```

---

## Summary

### How to Generate GDS File

**Simple Answer:**

```bash
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

**Wait:** 3-7 hours

**Output:** `gds/user_project_wrapper.gds`

**Verify:** `klayout gds/user_project_wrapper.gds`

**Done!** ✅

---

### Complete Process

1. ✅ **Check environment** (OpenLane, PDK)
2. ✅ **Navigate to project**
3. ✅ **Run macros** (if needed)
4. ✅ **Run user_project_wrapper** (main step)
5. ✅ **Wait 3-7 hours** ⏱️
6. ✅ **Verify GDS** (size, DRC, LVS)
7. ✅ **View in KLayout**
8. ✅ **Enable 3D view** (Shift+F4)

---

## Next Steps After GDS

1. **Visual verification** (KLayout 3D view)
2. **DRC/LVS checks** (review reports)
3. **Timing analysis** (check STA reports)
4. **Power analysis** (check power reports)
5. **Gate-level simulation** (verify functionality)
6. **Documentation** (update README)
7. **Prepare for tape-out** (when ready!)

---

**Your motor control chip is ready for fabrication!** 🎉

**Created:** 2026-03-07  
**Status:** Complete GDS generation guide

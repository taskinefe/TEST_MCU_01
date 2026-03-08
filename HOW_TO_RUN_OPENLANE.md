# How to Run OpenLane - Quick Start

## Script Locations

The `run_openlane.sh` script has been copied to multiple locations for your convenience:

```
📁 Project Structure:
/workspace/caravel_multi_peripheral/
├── run_openlane.sh                              ← Run from here ⭐
├── openlane/
│   ├── run_openlane.sh                          ← Or here
│   └── user_project_wrapper/
│       ├── run_openlane.sh                      ← Or here
│       └── config.json
```

**All three scripts do the same thing!**

---

## Method 1: Run from Project Root (Recommended) ⭐

```bash
cd /workspace/caravel_multi_peripheral
./run_openlane.sh
```

---

## Method 2: Run from openlane/ Directory

```bash
cd /workspace/caravel_multi_peripheral/openlane
./run_openlane.sh
```

---

## Method 3: Run from openlane/user_project_wrapper/

```bash
cd /workspace/caravel_multi_peripheral/openlane/user_project_wrapper
./run_openlane.sh
```

---

## Direct OpenLane Command (No Script)

If you prefer to run OpenLane directly without the script:

```bash
cd /workspace/caravel_multi_peripheral
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

---

## What the Script Does

1. ✅ Checks for OpenLane installation
2. ✅ Automatically tries these methods:
   - Direct `openlane` command
   - `/openlane/flow.tcl` script
   - Docker container
3. ✅ Runs complete RTL-to-GDS flow
4. ✅ Verifies output (DRC, LVS)
5. ✅ Shows results and file locations

---

## Expected Runtime

```
⏱️ Total Time: 3-7 hours

Breakdown:
- Synthesis:      30-60 min
- Floorplan:      10-20 min
- Placement:      30-60 min
- Clock Tree:     15-30 min
- Routing:        60-180 min  ← Longest!
- Verification:   20-40 min
- GDS Generation: 5-10 min
```

---

## Output Files

After successful completion, you'll find:

```
✅ gds/user_project_wrapper.gds       ← Your chip layout!
✅ lef/user_project_wrapper.lef       ← Abstract view
✅ lib/user_project_wrapper.lib       ← Timing library
✅ verilog/gl/user_project_wrapper.v  ← Gate-level netlist
```

---

## Verify Success

```bash
# Check GDS exists
ls -lh gds/user_project_wrapper.gds

# Check DRC (should be 0 violations)
cat openlane/user_project_wrapper/runs/*/reports/magic/magic.drc

# View in KLayout
klayout gds/user_project_wrapper.gds
# Press Shift+F4 for 3D view
```

---

## Quick Reference

| Command | Location | What it Does |
|---------|----------|--------------|
| `./run_openlane.sh` | Project root | **Easiest - use this!** ⭐ |
| `./run_openlane.sh` | openlane/ | Same thing |
| `./run_openlane.sh` | openlane/user_project_wrapper/ | Same thing |
| `openlane config.json --ef-save-views-to .` | Project root | Direct command |

---

## Summary

**Just run this:**

```bash
cd /workspace/caravel_multi_peripheral
./run_openlane.sh
```

**Wait 3-7 hours, then check:**

```bash
ls -lh gds/user_project_wrapper.gds
```

**Done!** Your GDS file is ready! 🎉

---

**Created:** 2026-03-07  
**Status:** Scripts ready in all locations

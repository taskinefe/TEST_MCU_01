# Quick Start - Generate GDS File

## ✅ Script Fixed and Ready!

The `run_openlane.sh` script is now working and can be run from **any location**.

---

## Run from Anywhere

### Option 1: Project Root (Recommended)

```bash
cd /workspace/caravel_multi_peripheral
./run_openlane.sh
```

### Option 2: openlane Directory

```bash
cd /workspace/caravel_multi_peripheral/openlane
./run_openlane.sh
```

### Option 3: user_project_wrapper Directory

```bash
cd /workspace/caravel_multi_peripheral/openlane/user_project_wrapper
./run_openlane.sh
```

**All three work identically!** The script auto-detects its location.

---

## What You'll See

```
==========================================
OpenLane GDS Generation Script
==========================================
Script location: /workspace/caravel_multi_peripheral
Project root:    /workspace/caravel_multi_peripheral
Config file:     /workspace/caravel_multi_peripheral/openlane/user_project_wrapper/config.json

Checking OpenLane installation...

✅ Found 'openlane' command
Running: openlane /workspace/caravel_multi_peripheral/openlane/user_project_wrapper/config.json --ef-save-views-to .

[OpenLane starts running...]
```

---

## Alternative: Direct Command

If you prefer, skip the script and run OpenLane directly:

```bash
cd /workspace/caravel_multi_peripheral
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

---

## Expected Runtime

⏱️ **Total Time: 3-7 hours**

The script will automatically:
1. Run synthesis (30-60 min)
2. Run floorplan (10-20 min)
3. Run placement (30-60 min)
4. Run clock tree (15-30 min)
5. Run routing (60-180 min) ← Longest!
6. Run verification (20-40 min)
7. Generate GDS (5-10 min)

---

## Check Results

After completion:

```bash
# Check GDS file
ls -lh gds/user_project_wrapper.gds

# Should see file ~50-200 MB
```

---

## View Your Chip

```bash
klayout gds/user_project_wrapper.gds

# Press Shift+F4 for 3D view
```

---

## Summary

**Just run:**

```bash
./run_openlane.sh
```

**Wait 3-7 hours**

**Your GDS will be ready at:**
`gds/user_project_wrapper.gds`

✅ **Script is fixed and working!**

🎉 **Ready to generate your motor control chip!**

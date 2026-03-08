# Running on Windows WSL / Docker Desktop

## Issue You're Seeing

When running from Docker Desktop bind mounts on WSL, the script path detection gets confused by paths like:

```
/mnt/wsl/docker-desktop-bind-mounts/Ubuntu/bf99437f7c9f10d238211ff93186e54575ed510d26b1376788332fd4150d381b
```

## ✅ Solution: Use the Simple Script

### Step 1: Navigate to Your Project

```bash
cd /path/to/your/caravel_multi_peripheral
```

**Make sure you see these when you run `ls`:**
- `openlane/`
- `verilog/`
- `gds/`
- `run_openlane_simple.sh`

### Step 2: Run the Simple Script

```bash
./run_openlane_simple.sh
```

This script:
- ✅ Works from current directory (no path detection needed)
- ✅ Checks if config.json exists
- ✅ Finds OpenLane
- ✅ Runs the flow
- ✅ Shows results

---

## Alternative: Direct Command

Skip the script entirely and run OpenLane directly:

```bash
# Navigate to project root first
cd /path/to/your/caravel_multi_peripheral

# Run OpenLane
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

---

## If OpenLane is Not Installed

### Use Docker Directly

```bash
cd /path/to/your/caravel_multi_peripheral

docker run --rm \
  -v $(pwd):/work \
  -w /work \
  efabless/openlane:latest \
  openlane/user_project_wrapper/config.json
```

---

## Files to Use

| File | When to Use |
|------|-------------|
| `run_openlane_simple.sh` | ✅ **Use this on WSL/Docker** |
| `run_openlane.sh` | For normal Linux systems |
| Direct `openlane` command | Simplest, works anywhere |

---

## Quick Check

### Are you in the right directory?

```bash
ls openlane/user_project_wrapper/config.json
```

**If you see:** `openlane/user_project_wrapper/config.json`  
**Then run:** `./run_openlane_simple.sh`

**If you see:** `No such file or directory`  
**Then:** `cd` to the correct project directory first

---

## Summary

**For Windows WSL / Docker Desktop:**

```bash
# 1. Go to project
cd /your/project/path

# 2. Verify location
ls openlane/user_project_wrapper/config.json

# 3. Run simple script
./run_openlane_simple.sh
```

**Or just run OpenLane directly:**

```bash
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

---

**The simple script avoids path detection issues!** ✅

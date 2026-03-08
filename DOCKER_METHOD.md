# Run OpenLane Using Docker - Correct Method

## Your Error

```
exec: "openlane": executable file not found in $PATH
```

**Problem:** The efabless/openlane Docker image has its own entrypoint.  
**Solution:** Don't specify `openlane` command, just pass the config file path.

---

## ✅ Correct Docker Command

### From Project Root

```bash
# Navigate to project root first
cd /mnt/c/Users/Efe/Downloads/TEST_MCU_01-TEST_MCU_01/TEST_MCU_01-TEST_MCU_01

# Run Docker with CORRECT syntax
docker run --rm \
  -v "$(pwd)":/work \
  -w /work \
  efabless/openlane:latest \
  openlane/user_project_wrapper/config.json
```

**Notice:** 
- Last line is just `openlane/user_project_wrapper/config.json`
- No `openlane` command before it
- The Docker image handles that automatically

---

## From openlane/user_project_wrapper Directory

If you're already in that directory:

```bash
cd /mnt/c/Users/Efe/Downloads/TEST_MCU_01-TEST_MCU_01/TEST_MCU_01-TEST_MCU_01/openlane/user_project_wrapper

docker run --rm \
  -v "$(pwd)/../..":/work \
  -w /work \
  efabless/openlane:latest \
  openlane/user_project_wrapper/config.json
```

**But it's easier from project root!**

---

## Step-by-Step (Copy These Commands)

### 1. Go to Project Root

```bash
cd /mnt/c/Users/Efe/Downloads/TEST_MCU_01-TEST_MCU_01/TEST_MCU_01-TEST_MCU_01
```

### 2. Verify Files Exist

```bash
ls openlane/user_project_wrapper/config.json
ls verilog/rtl/
```

### 3. Run Docker

```bash
docker run --rm \
  -v "$(pwd)":/work \
  -w /work \
  efabless/openlane:latest \
  openlane/user_project_wrapper/config.json
```

**That's it!**

---

## What This Command Does

```bash
docker run --rm \                                    # Run and remove after
  -v "$(pwd)":/work \                               # Mount current dir to /work
  -w /work \                                        # Set working directory
  efabless/openlane:latest \                        # Use OpenLane image
  openlane/user_project_wrapper/config.json         # Config file (relative to /work)
```

---

## Expected Output

```
LibreLane v2.x.x
...
[INFO]: Running Synthesis...
[INFO]: Running Floorplan...
[INFO]: Running Placement...
[INFO]: Running CTS...
[INFO]: Running Routing...
[INFO]: Running DRC/LVS...
[INFO]: Generating GDS...

Flow complete!
```

---

## After Completion (3-7 hours)

Check your GDS:

```bash
ls -lh gds/user_project_wrapper.gds
```

---

## Alternative: Use Shell Inside Container

If the direct command doesn't work, try this:

```bash
# Start container with shell
docker run --rm -it \
  -v "$(pwd)":/work \
  -w /work \
  efabless/openlane:latest \
  /bin/sh

# Then inside container:
openlane openlane/user_project_wrapper/config.json
```

---

## Common Issues

### Issue 1: "No such file or directory"

**Solution:** Make sure you're in the project root directory

```bash
# Check current directory
pwd

# Should be something like:
# /mnt/c/Users/Efe/Downloads/TEST_MCU_01-TEST_MCU_01/TEST_MCU_01-TEST_MCU_01

# Verify files exist
ls openlane/user_project_wrapper/config.json
```

---

### Issue 2: "Permission denied"

**Solution:** Make sure Docker has permission to access Windows drives

In Docker Desktop:
- Settings → Resources → File Sharing
- Add your C: drive

---

### Issue 3: Very slow on Windows

This is normal. WSL2 + Docker + Windows filesystem is slow.

**Faster option:** Copy project to WSL2 filesystem:

```bash
# Copy to WSL home
cp -r /mnt/c/Users/Efe/Downloads/TEST_MCU_01-TEST_MCU_01/TEST_MCU_01-TEST_MCU_01 ~/caravel_project

# Run from there
cd ~/caravel_project
docker run --rm -v "$(pwd)":/work -w /work efabless/openlane:latest openlane/user_project_wrapper/config.json
```

---

## Summary

**The CORRECT Docker command:**

```bash
# From project root
docker run --rm \
  -v "$(pwd)":/work \
  -w /work \
  efabless/openlane:latest \
  openlane/user_project_wrapper/config.json
```

**Key points:**
- ✅ Run from project root
- ✅ Config path is relative to /work
- ✅ NO `openlane` command before config path (Docker handles it)
- ✅ Wait 3-7 hours
- ✅ Get GDS in `gds/user_project_wrapper.gds`

---

**This should work!** 🎉

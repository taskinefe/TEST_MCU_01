# Run OpenLane Directly - No Script Needed

## The Simplest Method

Forget all the scripts. Just run this ONE command:

```bash
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

**That's it!**

---

## Step-by-Step

### 1. Navigate to Your Project

```bash
cd /path/to/caravel_multi_peripheral
```

### 2. Verify You're in the Right Place

```bash
ls openlane/user_project_wrapper/config.json
```

You should see: `openlane/user_project_wrapper/config.json`

### 3. Run OpenLane

```bash
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

---

## If "openlane: command not found"

### Option A: Install OpenLane

Follow official installation guide or use the container.

### Option B: Use Docker Container

```bash
docker run --rm \
  -v "$(pwd)":/work \
  -w /work \
  efabless/openlane:latest \
  /bin/sh -c "openlane openlane/user_project_wrapper/config.json --ef-save-views-to /work"
```

---

## Expected Output

```
LibreLane v2.x.x
...
[STEP 1] Running Synthesis
[STEP 2] Running Floorplan
[STEP 3] Running Placement
[STEP 4] Running CTS
[STEP 5] Running Routing
[STEP 6] Running DRC/LVS
[STEP 7] Generating GDS

Flow complete!
```

---

## After 3-7 Hours

Check your GDS file:

```bash
ls -lh gds/user_project_wrapper.gds
```

View it:

```bash
klayout gds/user_project_wrapper.gds
```

---

## Common Issues

### Issue: "exec format error"

**Problem:** Trying to execute the JSON file directly  
**Solution:** Use `openlane` command before the config file path

**Wrong:**
```bash
./openlane/user_project_wrapper/config.json  # ❌ Wrong
```

**Correct:**
```bash
openlane openlane/user_project_wrapper/config.json  # ✅ Correct
```

---

### Issue: "command not found"

**Solution:** Install OpenLane or use Docker method above

---

### Issue: Path errors

**Solution:** Make sure you're in the project root directory containing:
- `openlane/` folder
- `verilog/` folder
- `gds/` folder

---

## Summary

**Just run:**

```bash
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

**Wait 3-7 hours**

**Get GDS:** `gds/user_project_wrapper.gds`

**Done!** 🎉

---

## No Scripts, No Complexity

This is the official OpenLane way to run it.  
All the scripts are just wrappers around this one command.

**Keep it simple!**

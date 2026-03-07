# KLayout 3D Viewing Guide - Step by Step

## Complete Guide to View Your Motor Control Project in 3D

---

## Prerequisites

### System Requirements

- **OS:** Linux (Ubuntu/Debian recommended), macOS, or Windows
- **RAM:** 4 GB minimum, 8 GB recommended
- **Disk:** 1 GB free space
- **Display:** Graphics card with OpenGL support

---

## Step 1: Install KLayout

### Ubuntu/Debian Linux

```bash
# Method 1: APT package (recommended)
sudo apt update
sudo apt install klayout

# Method 2: Download latest from website
wget https://www.klayout.de/downloads/Ubuntu-22/klayout_0.28.12-1_amd64.deb
sudo dpkg -i klayout_0.28.12-1_amd64.deb
```

### macOS

```bash
# Using Homebrew
brew install klayout

# Or download DMG from:
# https://www.klayout.de/build.html
```

### Windows

```powershell
# Download installer from:
# https://www.klayout.de/build.html
# Run the .exe installer
```

### Verify Installation

```bash
klayout -v
# Should output: KLayout 0.28.x or higher
```

---

## Step 2: Generate Your GDS File

### Option A: If You Haven't Run OpenLane Yet

**You need to run OpenLane first to generate the GDS file:**

```bash
cd /workspace/caravel_multi_peripheral

# Run OpenLane for user_project_wrapper
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .
```

**Wait time:** 1-3 hours (depending on design complexity)

**Output:** `gds/user_project_wrapper.gds`

---

### Option B: If You Already Have GDS

**Check if GDS exists:**

```bash
ls -lh gds/user_project_wrapper.gds
```

**If file exists, you're ready!** ✅

---

## Step 3: Open Your Design in KLayout

### Basic Opening

```bash
cd /workspace/caravel_multi_peripheral
klayout gds/user_project_wrapper.gds
```

**KLayout window will open showing your design!**

---

### Advanced Opening (with SKY130 layer properties)

```bash
# Load with SKY130 layer configuration
klayout -e -nn sky130A.lyp gds/user_project_wrapper.gds
```

**Where to get `sky130A.lyp`:**

```bash
# Download SKY130 layer properties
wget https://raw.githubusercontent.com/google/skywater-pdk/main/libraries/sky130_fd_pr/latest/display/klayout/sky130A.lyp

# Or copy from OpenLane
cp $PDK_ROOT/sky130A/libs.tech/klayout/tech/sky130A.lyp .
```

---

## Step 4: Enable 3D View

### Method 1: Menu Navigation

1. **Open KLayout** with your GDS
2. **Click:** `View` → `3D View`
3. **Or use keyboard shortcut:** `Shift + F4`

**A new 3D window will open!** 🎉

---

### Method 2: Keyboard Shortcut (Fastest)

1. Open KLayout
2. Press `Shift + F4`

**Done!**

---

## Step 5: Configure 3D Layer Heights

### Set Layer Heights for Realistic View

**In KLayout main window (not 3D window):**

1. **Menu:** `Tools` → `Manage Layer Styles`
2. **Or:** Press `F5`

**Layer Style Manager opens:**

### SKY130 Layer Heights (Recommended)

| Layer | Name | Height (µm) | Z-start (µm) |
|-------|------|-------------|--------------|
| **Substrate** | - | 0.00 | 0.00 |
| **Diffusion** | diff | 0.10 | 0.00 |
| **Poly** | poly | 0.15 | 0.10 |
| **Contact** | licon1 | 0.10 | 0.25 |
| **Metal 1** | met1 | 0.36 | 0.35 |
| **Via 1** | via | 0.27 | 0.71 |
| **Metal 2** | met2 | 0.36 | 0.98 |
| **Via 2** | via2 | 0.42 | 1.34 |
| **Metal 3** | met3 | 0.845 | 1.76 |
| **Via 3** | via3 | 0.39 | 2.605 |
| **Metal 4** | met4 | 0.845 | 2.995 |
| **Via 4** | via4 | 0.505 | 3.84 |
| **Metal 5** | met5 | 1.26 | 4.345 |

---

### How to Set Heights

**For each layer:**

1. **Find layer** in list (e.g., "met1 - 68/20")
2. **Right-click** → `Properties`
3. **Set values:**
   - **Z-Start:** Starting height
   - **Z-Stop:** Ending height (Z-start + thickness)
4. **Click:** `OK`

**Repeat for all metal layers**

---

### Quick Script (Advanced)

**Save this as `sky130_3d_heights.lym`:**

```ruby
# KLayout macro to set SKY130 layer heights

# Define layer heights
layers = {
  "diff" => [0.00, 0.10],
  "poly" => [0.10, 0.25],
  "met1" => [0.35, 0.71],
  "met2" => [0.98, 1.34],
  "met3" => [1.76, 2.605],
  "met4" => [2.995, 3.84],
  "met5" => [4.345, 5.605]
}

# Apply to current layout
app = RBA::Application.instance
view = app.main_window.current_view

layers.each do |name, heights|
  view.each_layer do |layer|
    if layer.name.include?(name)
      layer.z_start = heights[0]
      layer.z_stop = heights[1]
    end
  end
end

puts "Layer heights configured for SKY130!"
```

**Load in KLayout:** `Macros` → `Import Macro` → `sky130_3d_heights.lym`

---

## Step 6: Navigate in 3D View

### Mouse Controls

**Rotation:**
- **Left mouse button + drag** → Rotate view
- **Or:** Arrow keys

**Zoom:**
- **Mouse wheel** → Zoom in/out
- **Or:** `+` / `-` keys

**Pan:**
- **Middle mouse button + drag** → Move view
- **Or:** `Shift + Arrow keys`

**Reset View:**
- **Press:** `Home` key
- **Or:** `View` → `Fit All`

---

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Shift + F4` | Toggle 3D view |
| `Home` | Reset view to fit all |
| `+` / `-` | Zoom in/out |
| `Arrow keys` | Rotate view |
| `Shift + Arrows` | Pan view |
| `Page Up/Down` | Change layer visibility |
| `Space` | Toggle rotation |

---

## Step 7: Customize 3D View

### Adjust Viewing Angle

**In 3D window:**

1. **Rotate** to desired angle with mouse
2. **Or use presets:**
   - `View` → `Top View` (bird's eye)
   - `View` → `Side View` (cross-section)
   - `View` → `Isometric` (3D angle)

---

### Layer Visibility

**Toggle layers on/off:**

1. **In main KLayout window:**
   - Click layer name in layer panel
   - Check/uncheck to show/hide

2. **In 3D view:**
   - Hidden layers won't appear
   - Useful for seeing internal structure

**Example: See only metal layers**
- Hide: diff, poly, contacts
- Show: met1, met2, met3, met4, met5

---

### Transparency

**Make layers semi-transparent:**

1. **Layer Style Manager** (`F5`)
2. **Select layer** (e.g., met5)
3. **Properties** → `Fill Color`
4. **Adjust transparency slider** (0-255)
   - 0 = Fully transparent
   - 255 = Fully opaque
   - Recommended: 180-220 for upper layers

**See through top layers to view below!** ✅

---

## Step 8: Advanced Visualization

### Color Coding

**Assign meaningful colors:**

| Layer | Recommended Color | Purpose |
|-------|-------------------|---------|
| **met1** | Blue | Local interconnect |
| **met2** | Purple | Power rails |
| **met3** | Green | Signal routing |
| **met4** | Yellow | Clock distribution |
| **met5** | Red | Top-level power |
| **poly** | Orange | Gates |
| **diff** | Brown | Transistors |

**How to change colors:**

1. `F5` → Select layer
2. `Properties` → `Fill Color`
3. Pick color
4. `OK`

---

### Lighting and Shading

**In 3D view window:**

1. **Menu:** `Options` → `3D View Options`
2. **Configure:**
   - **Lighting:** Enable/disable
   - **Shadows:** Enable for depth perception
   - **Ambient light:** Brightness (0-100%)
   - **Specular:** Shininess of surfaces

**Recommended settings:**
```
Lighting: ✓ Enabled
Shadows: ✓ Enabled
Ambient: 40%
Specular: 60%
```

---

## Step 9: Export 3D View

### Screenshot

**Capture current view:**

1. **In 3D window:** `File` → `Save Screenshot`
2. **Choose format:**
   - PNG (recommended)
   - JPEG
   - BMP
3. **Set resolution:**
   - 1920 × 1080 (HD)
   - 3840 × 2160 (4K)
4. **Save**

**Keyboard shortcut:** `Ctrl + Shift + S`

---

### Export 3D Model (Advanced)

**Export to 3D formats:**

```bash
# Using KLayout scripting
klayout -b -r export_3d.rb gds/user_project_wrapper.gds

# export_3d.rb script:
# (Export to STL, OBJ, or other 3D formats)
```

---

## Step 10: Analyze Your Design

### What to Look For

**Power Distribution:**
1. Hide all except met4 & met5
2. Look for power mesh/grid
3. Verify complete coverage

**Routing Density:**
1. Show met2 & met3
2. Look for congested areas
3. Check routing completion

**Standard Cells:**
1. Zoom in to cell level
2. View met1 connections
3. See transistor layout (poly/diff)

**Hierarchy:**
1. Select instance
2. Right-click → `Show Hierarchy`
3. Navigate through blocks

---

## Complete Workflow Example

### Full Process for Your Project

```bash
# 1. Install KLayout
sudo apt install klayout

# 2. Generate GDS (if needed)
cd /workspace/caravel_multi_peripheral
openlane openlane/user_project_wrapper/config.json --ef-save-views-to .

# 3. Download SKY130 layer properties
wget https://raw.githubusercontent.com/google/skywater-pdk/main/libraries/sky130_fd_pr/latest/display/klayout/sky130A.lyp

# 4. Open in KLayout
klayout -e -nn sky130A.lyp gds/user_project_wrapper.gds

# 5. Enable 3D view
# Press: Shift + F4

# 6. Configure layers (use Layer Style Manager - F5)

# 7. Navigate and explore!
```

---

## Troubleshooting

### Problem: 3D View is Blank

**Solution:**
- Check OpenGL support: `glxinfo | grep OpenGL`
- Update graphics drivers
- Try software rendering: `klayout -sw`

---

### Problem: Layers Have No Height

**Solution:**
- Configure layer heights in Layer Style Manager (`F5`)
- See Step 5 for heights

---

### Problem: Very Slow Rendering

**Solution:**
- Reduce visible layers (hide unnecessary)
- Lower screen resolution
- Close other applications
- Use faster computer

---

### Problem: Can't See Detail

**Solution:**
- Zoom in with mouse wheel
- Adjust layer transparency
- Hide upper layers
- Use section view

---

## Pro Tips

### Tip 1: Quick Layer Toggle

**Create layer visibility presets:**

1. **Configure visible layers**
2. **Layer Panel** → `Save Preset`
3. **Name it** (e.g., "Power Only", "All Metals")
4. **Load with one click**

---

### Tip 2: Section View

**See cross-section:**

1. **3D View Options**
2. **Enable:** `Clipping Plane`
3. **Adjust position** to "cut" through chip
4. **See internal layers**

---

### Tip 3: Animation

**Rotate automatically:**

1. **3D window:** `Options` → `Auto-rotate`
2. **Set speed:** 1-10 deg/sec
3. **Record with screen capture**
4. **Make demo videos!**

---

### Tip 4: Compare Designs

**Open multiple GDS files:**

1. **File** → `New Panel`
2. **Load different GDS**
3. **Switch between** with tabs
4. **3D view each** separately

---

## Example: View Your Motor Control

### Step-by-Step

**1. Open your design:**
```bash
klayout gds/user_project_wrapper.gds
```

**2. Enable 3D:** `Shift + F4`

**3. Configure views:**

**View A: Power Distribution**
- Show: met4, met5 only
- Look for power mesh

**View B: Signal Routing**
- Show: met2, met3 only  
- See FOC signals

**View C: Full Stack**
- Show: All layers
- Rotate to isometric view
- See complete 3D structure

**4. Take screenshots for documentation**

---

## Quick Reference Card

### Essential Shortcuts

```
Shift + F4       → Toggle 3D view
F5               → Layer Style Manager
Home             → Fit all
+/-              → Zoom in/out
Arrows           → Rotate view
Shift + Arrows   → Pan view
Ctrl + Shift + S → Screenshot
```

### Mouse Controls

```
Left drag        → Rotate
Wheel            → Zoom
Middle drag      → Pan
Right click      → Context menu
```

---

## Summary

### Complete 3D Viewing Process

1. ✅ **Install KLayout**
2. ✅ **Generate GDS** (run OpenLane)
3. ✅ **Open in KLayout**
4. ✅ **Enable 3D view** (Shift+F4)
5. ✅ **Configure layer heights** (F5)
6. ✅ **Navigate with mouse**
7. ✅ **Export screenshots**

### What You'll See

- ✅ All 5 metal layers stacked
- ✅ Your motor control logic in 3D
- ✅ Power distribution mesh
- ✅ Signal routing paths
- ✅ Standard cell placement
- ✅ Complete chip structure

---

## Additional Resources

### KLayout Documentation

- **Website:** https://www.klayout.de/
- **Manual:** https://www.klayout.de/doc/index.html
- **Forum:** https://www.klayout.de/forum/
- **Videos:** YouTube "KLayout 3D view"

### SKY130 PDK

- **Documentation:** https://skywater-pdk.readthedocs.io/
- **Layer stack:** Search "SKY130 layer stack"

---

## Next Steps

1. **Install KLayout** (if not already)
2. **Run OpenLane** to generate GDS
3. **Open your design**
4. **Enable 3D view**
5. **Explore your chip!**
6. **Take screenshots** for presentation
7. **Share with team!**

---

**Your motor control chip in glorious 3D!** 🎉

**Created:** 2026-03-07  
**Status:** Complete step-by-step guide

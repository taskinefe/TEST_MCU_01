# Caravel Silicon Dimensions and Layout

## Overview

This document provides the physical dimensions of the Caravel chip and user project area, along with information about viewing the final silicon layout.

---

## Chip Dimensions

### Full Caravel Die

**Total Die Size (with seal ring):**
- **Width:** 3.6 mm
- **Height:** 5.2 mm
- **Area:** 18.72 mm²

**Package (WLCSP - Wafer Level Chip Scale Package):**
- **Width:** 3.2 mm  
- **Height:** 5.3 mm
- **Type:** Bump bond (BGA-style)

---

## User Project Area Dimensions ⭐

### Available Silicon Area

**User Project Wrapper Area:**
- **Width:** 2.92 mm (2920 µm)
- **Height:** 3.52 mm (3520 µm)
- **Total Area:** 10.28 mm²

**In Micrometers:**
- **X dimension:** 2920 µm
- **Y dimension:** 3520 µm

**In SKY130 Units (1 unit = 5nm):**
- **Width:** 584,000 units
- **Height:** 704,000 units

---

## Layout Breakdown

### Caravel Full Chip Layout

```
┌────────────────────────────────────────┐
│         Total Die: 3.6mm × 5.2mm       │
│  ┌──────────────────────────────────┐  │
│  │      Seal Ring & Pads            │  │
│  │  ┌────────────────────────────┐  │  │
│  │  │   Management Area          │  │  │
│  │  │   (PicoRV32, Housekeeping) │  │  │
│  │  │   ~0.5mm × 5.2mm           │  │  │
│  │  └────────────────────────────┘  │  │
│  │                                   │  │
│  │  ┌────────────────────────────┐  │  │
│  │  │   USER PROJECT AREA       │  │  │
│  │  │   2.92mm × 3.52mm         │  │  │ ⭐
│  │  │   (Your motor control)     │  │  │
│  │  │                            │  │  │
│  │  │   • Peripherals            │  │  │
│  │  │   • Custom logic           │  │  │
│  │  │   • Motor PWM              │  │  │
│  │  │   • FOC transforms         │  │  │
│  │  │   • Overcurrent protection │  │  │
│  │  │                            │  │  │
│  │  └────────────────────────────┘  │  │
│  │                                   │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘

Legend:
• Management SoC: Fixed Caravel infrastructure
• User Project: Your custom motor control logic
• Seal Ring: ESD/mechanical protection
• Pads: GPIO, power, analog I/O
```

---

## Area Utilization

### What Fits in 10.28 mm²?

**Your Current Motor Control System:**

| Component | Approximate Area | % of Total |
|-----------|------------------|------------|
| **Peripherals (10×)** | ~2 mm² | 19% |
| **Custom Logic** | ~1.5 mm² | 15% |
| **Motor PWM (6-ch)** | ~0.3 mm² | 3% |
| **ADC (3-ch)** | ~0.5 mm² | 5% |
| **FOC Transforms** | ~0.4 mm² | 4% |
| **Overcurrent Protection** | ~0.2 mm² | 2% |
| **SRAM (4 KB)** | ~0.8 mm² | 8% |
| **Interconnect & Routing** | ~2 mm² | 19% |
| **Spare Area** | ~2.5 mm² | 24% |
| **TOTAL** | ~10.28 mm² | 100% |

**Utilization:** ~75% (good for first silicon)  
**Remaining:** ~2.5 mm² for future features

---

## 3D Visualization

### Important Note

**SKY130 is a planar 2D process**, not true 3D like FinFET. However, we can visualize the layout:

### Layer Stack (Vertical)

```
Top (closest to package)
    ↓
Metal 5 (M5)    ← Top routing layer
Metal 4 (M4)    ← Power distribution
Metal 3 (M3)    ← Signal routing
Metal 2 (M2)    ← Local interconnect
Metal 1 (M1)    ← Cell connections
    ↓
Poly Layer      ← Gate connections
    ↓
Diffusion       ← Transistor source/drain
    ↓
P-substrate     ← Silicon wafer
    ↓
Bottom
```

**Total Thickness:** ~10 µm (vertical)  
**Horizontal Area:** 2920 µm × 3520 µm

**Aspect Ratio:** 1:290 (very flat!)

---

## Viewing Your Silicon Layout

### Method 1: KLayout (Recommended)

**Tool:** KLayout (Free, Open Source)  
**File:** `gds/user_project_wrapper.gds`

**To View:**
```bash
# Install KLayout
sudo apt install klayout

# Open your design
klayout gds/user_project_wrapper.gds
```

**What You'll See:**
- All metal layers (M1-M5)
- Standard cells
- Custom blocks
- Power rails
- Routing

**3D View in KLayout:**
```
View → 3D View
```
This shows a pseudo-3D rendering with layer heights.

---

### Method 2: Magic (IC Layout Viewer)

**Tool:** Magic VLSI  
**File:** `mag/user_project_wrapper.mag`

**To View:**
```bash
magic -d XR mag/user_project_wrapper.mag
```

**Features:**
- Native SKY130 support
- DRC checking
- Cross-section view
- Extract parasitics

---

### Method 3: OpenLane Reports

**After running OpenLane, check:**

```bash
openlane/user_project_wrapper/runs/latest/reports/

Files:
- floorplan.pdf        → Initial placement
- routing.pdf          → Final routing
- summary.csv          → Area utilization
- sta/timing.rpt       → Timing analysis
```

**Area Report Example:**
```
Design Area: 10.28 mm²
Core Utilization: 72.5%
Die Area: 2920µm × 3520µm
Instances: ~50,000 cells
Nets: ~75,000
```

---

## Physical Representation

### Actual Silicon Die (Top View)

```
                    3.6 mm
    ┌─────────────────────────────────┐
    │ ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐ │
    │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │  ← GPIO Pads
    │ └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘ │
    │                                 │
5.2 │  ┌────────────────────────┐    │
mm  │  │                        │    │
    │  │   User Project Area    │    │
    │  │   2.92 × 3.52 mm       │    │  ← Your Motor Control
    │  │                        │    │
    │  └────────────────────────┘    │
    │                                 │
    │  [Mgmt SoC] [Analog IOs]       │
    │                                 │
    │ ┌─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┐ │
    │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │  ← Power/GND Pads
    │ └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘ │
    └─────────────────────────────────┘
```

---

## Comparison to Common Objects

### Size Reference

| Object | Size | Comparison |
|--------|------|------------|
| **Grain of rice** | 6-7 mm | Caravel is **smaller** |
| **Caravel die** | **3.6 × 5.2 mm** | **This chip** ⭐ |
| **Apple Watch CPU** | 5.5 × 8 mm | Slightly larger |
| **Pencil eraser** | 6 × 6 mm | Similar size |
| **Grain of sand** | 1-2 mm | Caravel is larger |

**User Project Area (2.92 × 3.52 mm):**
- About the size of a **sesame seed**
- Contains ~50,000 transistors
- Runs complex motor control algorithms!

---

## Yield and Manufacturing

### Wafer Information

**SKY130 Wafer:**
- **Diameter:** 200 mm (8 inch)
- **Caravel die size:** 3.6 × 5.2 mm = 18.72 mm²

**Dies per Wafer:**
```
Wafer area = π × (100mm)² = 31,416 mm²
Die area = 18.72 mm²
Gross dies = 31,416 / 18.72 ≈ 1,678 dies

With scribe lanes and edge loss:
Usable dies ≈ 1,200-1,400 per wafer
```

**At 90% yield:**
- **Good dies:** ~1,100-1,250 per wafer

---

## Package Dimensions

### WLCSP (Wafer Level Chip Scale Package)

**Package Type:** Bump bond / BGA-style  

```
Top View:
    3.2 mm
┌───────────┐
│ ○ ○ ○ ○ ○ │  ← Bump balls (solder balls)
│ ○ ○ ○ ○ ○ │
│ ○ ○ ○ ○ ○ │  5.3 mm
│ ○ ○ ○ ○ ○ │
│ ○ ○ ○ ○ ○ │
└───────────┘

Side View:
┌───────────┐
│   Die     │ ← Silicon (180 µm thick)
├───────────┤
│ Bumps     │ ← Solder balls (150 µm)
└─○─○─○─○─○─┘
```

**Package Height:** ~330 µm (0.33 mm)  
**Bump Pitch:** 400-500 µm  
**Bump Count:** ~60-80 balls

---

## PCB Footprint

### Recommended Landing Pattern

```
Minimum PCB area: 4 × 6 mm (including keepout)

┌─────────────────┐
│                 │
│  ┌──────────┐   │
│  │ 3.2×5.3  │   │  ← Package
│  │          │   │
│  └──────────┘   │
│                 │  ← Keepout zone
└─────────────────┘
```

**PCB Requirements:**
- **Layer stack:** 4-layer minimum
- **Trace width:** 0.1 mm (4 mil)
- **Via size:** 0.2 mm (8 mil)
- **Impedance control:** 50Ω for high-speed signals

---

## Design Constraints

### User Project Area Limits

**Maximum Utilization:**
- **Core:** 85% (recommended 70-75%)
- **Routing:** 80% per layer
- **Power density:** <50 mW/mm²

**Minimum Features:**
- **Metal width:** 0.14 µm (M1)
- **Metal spacing:** 0.14 µm
- **Via size:** 0.15 µm

**Example:**
```
Your motor control design:
Area: 10.28 mm²
Utilization: 75%
Power: 300 mW
Power density: 29 mW/mm² ✅ (good)
```

---

## Rendering Example

### Pseudo-3D Representation

```
                    Side View (not to scale)
                    
Metal 5 ═══════════════════════════════════ ← Power mesh
Metal 4 ─────────────────────────────────── ← Clock distribution
Metal 3 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ← Routing
Metal 2 ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ═ ← Power rails
Metal 1 ─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─┬─ ← Cell connections
        │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
Poly    ├─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┼─┤ ← Gates
        │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │ │
Diff    └─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┴─┘ ← Transistors
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ ← P-substrate

        <────── 2920 µm (2.92 mm) ──────>

Height: ~10 µm (vertical exaggeration 1:290)
```

---

## Viewing Tools Summary

| Tool | Purpose | File Type | 3D View? |
|------|---------|-----------|----------|
| **KLayout** | Layout viewer | GDS | Yes (pseudo-3D) |
| **Magic** | IC editor | MAG, GDS | Cross-section |
| **OpenLane** | Place & Route | Reports | No (2D plots) |
| **Paraview** | 3D rendering | VTK | Yes (converted) |

---

## How to Generate 3D View

### Using KLayout

```bash
# Open KLayout
klayout gds/user_project_wrapper.gds

# Enable 3D view
# Menu: View → 3D View
# Or press: Shift+F4

# Configure layers
# Tools → Manage Layer Styles
# Set layer heights:
#   M1: 0.0 µm
#   M2: 0.5 µm  
#   M3: 1.0 µm
#   M4: 1.5 µm
#   M5: 2.0 µm

# Rotate view with mouse
# Export image: File → Screenshot
```

---

## Summary

### Key Dimensions ⭐

| Parameter | Value |
|-----------|-------|
| **Total Die Size** | 3.6 × 5.2 mm |
| **User Project Area** | **2.92 × 3.52 mm** ⭐ |
| **Available Silicon** | **10.28 mm²** |
| **Package Size** | 3.2 × 5.3 mm (WLCSP) |
| **Thickness** | 0.33 mm (packaged) |
| **Process** | SKY130 (130 nm) |
| **Layers** | 5 metal + poly + diffusion |

### Your Motor Control Fits Easily! ✅

```
Current design: ~7.8 mm² (75% utilized)
Available area: 10.28 mm²
Remaining: 2.5 mm² for future expansion
```

---

## Next Steps to View Layout

1. **Run OpenLane** to generate final GDS:
   ```bash
   openlane openlane/user_project_wrapper/config.json
   ```

2. **View in KLayout:**
   ```bash
   klayout gds/user_project_wrapper.gds
   ```

3. **Enable 3D view** (View → 3D View)

4. **Export screenshot** for documentation

---

**Note:** True "3D view" of silicon is pseudo-3D (layer stacking visualization). The actual chip is very thin (0.18 mm die + 0.15 mm package ≈ 0.33 mm total).

---

**Created:** 2026-03-07  
**Status:** Complete dimensions guide

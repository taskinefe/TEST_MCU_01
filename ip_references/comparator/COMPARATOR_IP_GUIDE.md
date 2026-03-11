# Comparator IP Resources - Complete Guide

## ✅ Comparator IPs Available

Two comparator IPs are available for your motor control project:

1. **EF_ACMP_DI** - Digital Interface for Analog Comparator
2. **sky130_ef_ip__ccomp3v** - 3.3V Continuous Comparator (Analog)

---

## 1. EF_ACMP_DI - Digital Interface Comparator

**Location:** `ip_references/comparator/EF_ACMP_DI/`

**System Location:** `/nc/ip/EF_ACMP_DI/`

### Description

Digital interface wrapper for the EF_R2RVC02 analog comparator. This provides a simple digital interface to control and read an analog comparator.

### Key Features

- Digital control interface
- Simple wrapper around analog comparator
- Easy integration with digital logic
- Wishbone, APB, and AHBL bus wrappers available

### Module Interface

```verilog
module EF_ACMP_DI (
    // To analog comparator
    output  wire    sela,       // Select input A
    output  wire    selb,       // Select input B
    input   wire    vo,         // Comparator output (analog)
    
    // Digital interface
    input   wire    di_sela,    // Digital select A
    input   wire    di_selb,    // Digital select B
    output  wire    di_vo       // Digital comparator output
);
```

### Files Available

```
EF_ACMP_DI/
├── EF_ACMP_DI.json           ← Configuration
├── LICENSE                    ← Apache 2.0
├── README.md                  ← Overview
├── fw/
│   └── EF_ACMP_DI.h          ← C header file
└── hdl/rtl/
    ├── EF_ACMP_DI.v          ← Main module
    └── bus_wrapper/
        ├── EF_ACMP_DI_wb.v   ← Wishbone wrapper ⭐
        ├── EF_ACMP_DI_apb.v  ← APB wrapper
        └── EF_ACMP_DI_ahbl.v ← AHBL wrapper
```

### Usage Example

```verilog
// Simple digital interface to comparator
EF_ACMP_DI acmp_inst (
    .sela(analog_sela),      // To analog comparator
    .selb(analog_selb),
    .vo(analog_comp_out),
    
    .di_sela(digital_sela),  // From digital logic
    .di_selb(digital_selb),
    .di_vo(digital_comp_out) // To digital logic
);
```

### For Motor Control

**Use Case:** Overcurrent protection comparator interface

```verilog
// Compare motor current against threshold
EF_ACMP_DI overcurrent_comp (
    .sela(motor_current),        // Current sensor input
    .selb(current_threshold),     // Threshold voltage
    .vo(analog_comp_result),
    
    .di_sela(1'b1),              // Enable
    .di_selb(1'b1),
    .di_vo(overcurrent_flag)     // Digital flag to shutdown logic
);
```

---

## 2. sky130_ef_ip__ccomp3v - 3.3V Continuous Comparator

**Location:** `ip_references/comparator/sky130_ccomp3v/`

**System Location:** `/nc/ip/sky130_ef_ip__ccomp3v/`

### Description

High-performance 3.3V analog comparator with:
- Rail-to-rail operation (0-3.3V)
- 1mV resolution
- Continuous (non-latching) operation
- <1µs response time for 1MHz operation

### Key Features

| Feature | Specification |
|---------|---------------|
| **Supply Voltage** | 3.3V |
| **Input Range** | 0 - 3.3V (rail-to-rail) |
| **Resolution** | 1 mV |
| **Response Time** | < 1 µs |
| **Operation** | Continuous, non-latching |
| **Current** | ~80 µA |

### Architecture

**Design Approach:**

1. **Dual Amplifier Design:**
   - nFET input amplifier (for low common-mode voltages)
   - pFET input amplifier (for high common-mode voltages)
   - Outputs combined for full rail-to-rail operation

2. **Wide Range Amplifiers:**
   - 2-stage amplifiers for extended range
   - Cascoded current sources for stability
   - Matched for consistent response across full voltage range

3. **Output Buffer:**
   - Inverter chain for digital output
   - Sized to toggle on 1mV differential

### Typical Use

```
Analog Input A ──┐
                 ├──→ Comparator ──→ Digital Output (0 or 3.3V)
Analog Input B ──┘
```

**Output:**
- HIGH (3.3V) if Input A > Input B
- LOW (0V) if Input A < Input B
- Switches with ~1mV hysteresis

### Files Available

```
sky130_ccomp3v/
├── README                     ← Detailed design notes ⭐
├── LICENSE                    ← Apache 2.0
├── sky130_ef_ip__ccomp3v.yaml← Configuration
├── lef/                       ← Abstract layout
├── mag/                       ← Magic layout files
├── xschem/                    ← Schematic files
├── verilog/                   ← Behavioral model
├── lvs/                       ← LVS verification
└── reports/                   ← Characterization data
```

### Performance Characteristics

**Common-Mode Range:** 0 - 3.3V  
**Differential Input:** ±1mV minimum  
**Output Swing:** 0 - 3.3V (full rail)  
**Offset:** <1mV (matched across CM range)  
**Bandwidth:** >1MHz

### Integration Notes

**⚠️ This is an ANALOG IP**

Requires:
1. Analog power domain (VDDA/VSSA at 3.3V)
2. Analog signal pads (`analog_io[]` in Caravel)
3. Proper analog routing in layout
4. No digital synthesis (hard macro integration)

### For Motor Control - Overcurrent Protection

**Example Use Case:**

```
Current Sensor Output ──┐
                        ├──→ Comparator ──→ FAULT Signal
Threshold DAC ─────────┘                    (to shutdown PWM)
```

**Advantages:**
- Very fast response (<1µs)
- High resolution (1mV)
- Analog comparison (no ADC latency)
- Direct hardware protection

**Circuit:**
```
┌─────────────────────────────────────────────┐
│ Motor Current                               │
│      ↓                                      │
│  [Sense Resistor]                           │
│      ↓                                      │
│  [Amplifier] ────────┐                      │
│                      │                      │
│  [DAC Threshold] ────┼──→ [Comparator] ──→ FAULT
│                                             │
└─────────────────────────────────────────────┘
```

When motor current exceeds threshold:
1. Comparator output goes HIGH (<1µs)
2. FAULT signal triggers PWM shutdown
3. Motor protected from overcurrent

---

## Comparison: EF_ACMP_DI vs sky130_ccomp3v

| Feature | EF_ACMP_DI | sky130_ccomp3v |
|---------|------------|----------------|
| **Type** | Digital Interface | Analog Comparator |
| **Complexity** | Simple wrapper | Complete analog design |
| **Integration** | Easy (digital) | Complex (analog) |
| **Resolution** | Depends on analog part | 1 mV |
| **Speed** | Depends on analog part | < 1 µs |
| **Power** | Low | 80 µA |
| **Pads Needed** | Digital GPIOs | Analog IOs |
| **Layout** | Synthesizable | Hard macro |
| **Best For** | Digital control | High-performance analog |

---

## Recommendation for Motor Control

### Option 1: Use Digital Comparator Logic (Simplest) ⭐

**Instead of analog comparators, use digital comparison after ADC:**

```verilog
// Digital overcurrent detection (after ADC)
always @(posedge clk) begin
    if (motor_current_adc > OVERCURRENT_THRESHOLD)
        overcurrent_fault <= 1'b1;
    else
        overcurrent_fault <= 1'b0;
end
```

**Advantages:**
- ✅ Fully digital (easy integration)
- ✅ Programmable threshold
- ✅ No analog routing needed
- ✅ Works with external SPI ADC

**Latency:** ADC conversion time + 1 clock cycle  
(For 8 kHz sampling: 125µs + 25ns = still very fast!)

---

### Option 2: Use Analog Comparator (Fastest)

**If you need absolute minimum latency (<1µs):**

Use **sky130_ccomp3v** with:
- Analog current sensor output
- DAC for threshold setting
- Direct to PWM shutdown logic

**Requires:**
- Analog pads in Caravel
- Careful analog layout
- Hard macro integration

---

## Your Overcurrent Protection Implementation

**Current Design:** DAC + 3 Comparators

Based on your documentation, you likely want:

### Suggested Architecture

```
Phase A Current Sensor ──→ [Comparator A] ──┐
Phase B Current Sensor ──→ [Comparator B] ──┼──→ OR ──→ FAULT
Phase C Current Sensor ──→ [Comparator C] ──┘

DAC (programmable) ────→ Threshold (shared by all 3)
```

**Implementation Options:**

**A) Fully Digital (Recommended):**
- Use ADC to sample currents
- Digital comparison in RTL
- Programmable threshold via registers
- Fast enough for motor control (< 125µs)

**B) Analog Comparators (if <1µs required):**
- Use 3× sky130_ccomp3v
- Analog current sensing
- DAC for threshold
- Requires analog pads and layout

---

## Files Copied to Your Project

**Location:** `ip_references/comparator/`

```
comparator/
├── COMPARATOR_IP_GUIDE.md         ← This file
├── EF_ACMP_DI/                    ← Digital interface
│   ├── README.md
│   ├── hdl/rtl/
│   │   ├── EF_ACMP_DI.v
│   │   └── bus_wrapper/
│   │       └── EF_ACMP_DI_wb.v   ← Wishbone wrapper
│   └── fw/
│       └── EF_ACMP_DI.h
└── sky130_ccomp3v/                ← Analog comparator
    ├── README                     ← Design details
    ├── verilog/                   ← Behavioral model
    ├── xschem/                    ← Schematics
    ├── lef/                       ← Layout
    └── mag/                       ← Magic files
```

---

## Quick Start

### View Comparator Files

```bash
# View EF_ACMP_DI (digital interface)
cd ip_references/comparator/EF_ACMP_DI
ls hdl/rtl/

# View sky130_ccomp3v (analog)
cd ip_references/comparator/sky130_ccomp3v
cat README
```

### Copy to Your Project

```bash
# Copy digital interface comparator
cp ip_references/comparator/EF_ACMP_DI/hdl/rtl/*.v verilog/rtl/

# For analog comparator, use as hard macro (GDS/LEF)
```

---

## Summary

**Comparator IPs Found:** 2

| IP | Type | Location | Best For |
|----|------|----------|----------|
| **EF_ACMP_DI** | Digital Interface | `comparator/EF_ACMP_DI/` | Simple digital control |
| **sky130_ccomp3v** | Analog | `comparator/sky130_ccomp3v/` | High-performance analog |

**For Motor Overcurrent Protection:**

- **Recommended:** Digital comparison (after ADC) - simplest
- **Alternative:** Analog comparators (if <1µs required)

**All files copied and ready to use!** ✅

---

**Created:** 2026-03-11  
**Status:** Comparator IPs documented and copied

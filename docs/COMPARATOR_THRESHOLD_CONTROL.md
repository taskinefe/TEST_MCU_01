# How to Change Comparator Threshold Level

## Overview

There are **FOUR methods** to set/change the comparator threshold voltage for overcurrent detection:

1. **Fixed External Resistor Divider** (Simplest)
2. **Programmable DAC** (Most Flexible) ⭐
3. **Multiple Comparators** (Fastest)
4. **Digital Potentiometer** (External IC)

---

## Method 1: Fixed External Resistor Divider (Simplest)

### Concept

Use external resistors to create a fixed reference voltage.

### Circuit

```
VDD (3.3V)
    │
    R1
    ├────→ V_threshold → Comparator Reference Input
    R2
    │
   GND

V_threshold = VDD × R2 / (R1 + R2)
```

### Example Calculations

**For overcurrent thresholds:**

| Target Voltage | Current Trip | R1 (kΩ) | R2 (kΩ) | Comments |
|----------------|--------------|---------|---------|----------|
| 2.65V | 6A | 0.68 | 2.2 | Rated current |
| 2.80V | 7A | 0.51 | 2.2 | **Recommended** ⭐ |
| 3.00V | 8.5A | 0.33 | 2.2 | High current |
| 3.15V | 9A | 0.15 | 2.2 | Near maximum |

**Standard resistor values (E12 series):**
```
For 2.80V threshold:
R1 = 510Ω (0.51kΩ)
R2 = 2.2kΩ
V_out = 3.3V × 2.2 / (0.51 + 2.2) = 2.68V

Adjust with R1 = 560Ω for 2.70V
```

### Pros & Cons

**Pros:**
- ✅ Very simple
- ✅ No firmware needed
- ✅ Cheap (2 resistors)
- ✅ Reliable

**Cons:**
- ❌ Fixed threshold
- ❌ Cannot change without hardware modification
- ❌ Component tolerances (±1-5%)

### Implementation

**Hardware:**
```
Caravel analog_io[14] → Comparator INP (signal)
External divider       → Comparator INM (reference)

PCB:
  3.3V ──┬──
         │ R1 (510Ω)
         ├─────→ analog_io[15] (comparator reference)
         │ R2 (2.2kΩ)
        GND
```

**Firmware:**
```c
// Nothing needed! Hardware sets threshold
// Just enable comparator
WRITE_REG(COMP_CTRL, 0x01);  // Enable
```

**Best for:** Fixed, production designs where threshold never changes

---

## Method 2: Programmable DAC (Most Flexible) ⭐

### Available DAC IPs

**sky130_ef_ip__rdac3v_8bit**
- 8-bit resistive DAC
- 0 - 3.3V output
- 256 levels
- Resolution: 3.3V / 256 = 12.9 mV/step

### Concept

Use DAC output as programmable reference voltage.

### Architecture

```
Firmware
    ↓
DAC Control (8-bit value)
    ↓
DAC Output (0-3.3V)
    ↓
Comparator Reference Input
```

### Voltage Calculation

```c
// DAC equation
V_out = (DAC_value / 256) × 3.3V

// Examples:
DAC_value = 128 → V_out = 1.65V (center)
DAC_value = 204 → V_out = 2.63V (6A)
DAC_value = 216 → V_out = 2.78V (7A)
DAC_value = 232 → V_out = 2.99V (8.5A)
DAC_value = 255 → V_out = 3.29V (max)
```

### Threshold to DAC Value Table

| Threshold | Current | DAC Value (decimal) | DAC Value (hex) |
|-----------|---------|---------------------|-----------------|
| 2.48V | 5A | 192 | 0xC0 |
| 2.65V | 6A | 204 | 0xCC |
| 2.78V | 7A | **216** | **0xD8** ⭐ |
| 2.95V | 8A | 228 | 0xE4 |
| 3.13V | 9A | 243 | 0xF3 |
| 3.28V | 10A | 254 | 0xFE |

### Firmware Implementation

```c
#define DAC_BASE 0x300E0000
#define DAC_CTRL (DAC_BASE + 0x00)
#define DAC_DATA (DAC_BASE + 0x04)

// Set overcurrent threshold
void set_overcurrent_threshold(float voltage) {
    // Convert voltage to DAC value
    uint8_t dac_val = (uint8_t)((voltage / 3.3f) * 256.0f);
    
    // Write to DAC
    WRITE_REG(DAC_DATA, dac_val);
    WRITE_REG(DAC_CTRL, 0x01);  // Enable DAC
}

// Set by current (assumes 0.165V/A sensitivity)
void set_overcurrent_limit(float current_amps) {
    // Convert current to voltage
    // V = I × 0.01Ω × 20 (gain) + 1.65V (offset)
    float voltage = (current_amps * 0.165f) + 1.65f;
    
    // Clamp to valid range
    if (voltage > 3.3f) voltage = 3.3f;
    if (voltage < 0.0f) voltage = 0.0f;
    
    set_overcurrent_threshold(voltage);
}

// Usage examples
void init_overcurrent_protection(void) {
    // Set 7A threshold
    set_overcurrent_limit(7.0f);  // 7A trip point
    
    // Or set directly by voltage
    set_overcurrent_threshold(2.78f);  // 2.78V
}

// Runtime adjustment
void adjust_current_limit(void) {
    // Increase limit gradually
    for (float i = 5.0f; i <= 10.0f; i += 0.5f) {
        set_overcurrent_limit(i);
        delay_ms(100);
    }
}
```

### Advanced: Load-Dependent Threshold

```c
// Adjust threshold based on motor load
void adaptive_current_limit(float motor_speed_rpm) {
    float current_limit;
    
    if (motor_speed_rpm < 1000) {
        current_limit = 5.0f;  // Low speed, low limit
    } else if (motor_speed_rpm < 3000) {
        current_limit = 7.0f;  // Medium speed
    } else {
        current_limit = 9.0f;  // High speed, high limit
    }
    
    set_overcurrent_limit(current_limit);
}
```

### Calibration

```c
// Calibrate DAC for accurate threshold
void calibrate_dac(void) {
    // Set known voltage
    set_overcurrent_threshold(2.78f);
    
    // Measure actual output with multimeter
    // Adjust if needed:
    
    // If measured = 2.75V (low):
    uint8_t dac_val = 218;  // Increase slightly
    
    // Store calibration offset
    int8_t dac_offset = 2;  // +2 counts correction
}
```

### Pros & Cons

**Pros:**
- ✅ **Software programmable**
- ✅ **Runtime adjustable**
- ✅ **256 levels** (12.9mV resolution)
- ✅ Adaptive protection possible
- ✅ Calibration support

**Cons:**
- Requires DAC IP integration
- More complex than resistor divider
- DAC linearity/accuracy considerations

**Best for:** Flexible, adaptive, production systems ⭐

---

## Method 3: Multiple Comparators (Multi-Level)

### Concept

Use multiple comparators with different fixed thresholds.

### Architecture

```
Current Signal → Split to 3 comparators
                 ↓
    ┌────────────┼────────────┐
    │            │            │
Comp A       Comp B       Comp C
(2.65V)      (2.80V)      (3.00V)
 ↓            ↓            ↓
Warning      Trip         Critical
```

### Implementation

```c
// Multiple threshold levels
#define COMP_WARNING  0x300D0000  // 2.65V (6A)
#define COMP_TRIP     0x300D1000  // 2.80V (7A)
#define COMP_CRITICAL 0x300D2000  // 3.00V (8.5A)

void multi_level_protection(void) {
    uint32_t warning = READ_REG(COMP_WARNING + STATUS);
    uint32_t trip = READ_REG(COMP_TRIP + STATUS);
    uint32_t critical = READ_REG(COMP_CRITICAL + STATUS);
    
    if (critical) {
        // Immediate shutdown
        emergency_shutdown();
    } else if (trip) {
        // Reduce power
        reduce_motor_voltage(0.5f);
    } else if (warning) {
        // Log warning
        log_warning("Approaching current limit");
    }
}
```

### Pros & Cons

**Pros:**
- ✅ Multiple protection levels
- ✅ Graduated response
- ✅ Very fast (all hardware)

**Cons:**
- ❌ Requires multiple comparators
- ❌ More area/cost
- ❌ Fixed thresholds

**Best for:** Critical safety systems with multiple trip levels

---

## Method 4: Digital Potentiometer (External IC)

### Concept

Use external digital potentiometer to create adjustable divider.

### Example IC

**MCP4131** (128-tap digital pot)
- 10kΩ resistance
- SPI interface
- 128 positions

### Circuit

```
3.3V
  │
  ┌───────────────┐
  │ MCP4131       │
  │ Digital Pot   │
  │               │
  │ Wiper ────────┼──→ Comparator Reference
  │               │
  └───────────────┘
  │
 GND
```

### Firmware

```c
// Set digital pot via SPI
void set_dpot_threshold(uint8_t position) {
    // position: 0-127
    // V_out = 3.3V × (position / 128)
    
    spi_write(DPOT_ADDR, position);
}

// For 2.80V:
// position = (2.80 / 3.3) × 128 = 108
set_dpot_threshold(108);
```

### Pros & Cons

**Pros:**
- ✅ Programmable
- ✅ Uses existing SPI
- ✅ Non-volatile (some models)

**Cons:**
- ❌ External component
- ❌ PCB space
- ❌ Added cost

**Best for:** When DAC not available, external control needed

---

## Recommended Implementation

### For Your Motor Control System:

**Best Option: Method 2 (Programmable DAC)** ⭐

```c
//=============================================================================
// Complete Overcurrent Protection with Programmable Threshold
//=============================================================================

#define DAC_BASE  0x300E0000
#define COMP_BASE 0x300D0000

// Initialize system
void init_protection(void) {
    // Set initial threshold to 7A
    set_overcurrent_limit(7.0f);
    
    // Enable comparator
    WRITE_REG(COMP_BASE + CTRL, 0x01);
    
    // Enable interrupt
    WRITE_REG(COMP_BASE + IM, 0x01);
}

// Comparator ISR
void comp_isr(void) {
    // Overcurrent detected
    WRITE_REG(MOTOR_PWM_CTRL, 0);  // Shutdown
    
    // Log fault
    log_fault("Overcurrent", read_current());
    
    // Clear interrupt
    WRITE_REG(COMP_BASE + ICR, 0x01);
}

// Runtime threshold adjustment
void set_motor_current_limit(float amps) {
    set_overcurrent_limit(amps);
    
    // Log change
    printf("Current limit set to %.1fA\n", amps);
}
```

---

## Threshold Selection Guide

### Recommended Thresholds for PMSM

| Motor Rating | Warning (A) | Trip (A) | Critical (A) |
|--------------|-------------|----------|--------------|
| 1A motor | 1.2 | 1.5 | 2.0 |
| 3A motor | 3.6 | 4.5 | 6.0 |
| 5A motor | 6.0 | 7.5 | 10.0 |
| 10A motor | 12.0 | 15.0 | 20.0 |

**Margin:** Set trip at 120-150% of rated current

---

## Voltage to Current Conversion

### For Your Current Sensing Circuit:

**Hardware:** INA240 (G=20), 0.01Ω shunt

**Equation:**
```
V_sense = (I_motor × R_shunt × Gain) + V_offset
V_sense = (I_motor × 0.01Ω × 20) + 1.65V
V_sense = (I_motor × 0.2) + 1.65V

Simplified:
V_sense = (I_motor × 0.165) + 1.65V  (for ±10A range)
```

**Current to Voltage Table:**

| Current (A) | Voltage (V) | DAC Value | Threshold For |
|-------------|-------------|-----------|---------------|
| 0 | 1.65 | 128 | Center |
| 3 | 2.15 | 166 | Light load |
| 5 | 2.48 | 192 | Rated (5A motor) |
| 6 | 2.64 | 204 | Warning |
| 7 | 2.80 | **216** | **Trip** ⭐ |
| 8 | 2.97 | 229 | High current |
| 10 | 3.30 | 255 | Maximum |

---

## Summary Table

| Method | Flexibility | Cost | Complexity | Best For |
|--------|-------------|------|------------|----------|
| **Resistor Divider** | Low | $ | Simple | Fixed designs |
| **Programmable DAC** ⭐ | **High** | $$ | **Medium** | **Production** |
| **Multiple Comp** | Medium | $$$ | High | Safety-critical |
| **Digital Pot** | Medium | $$ | Medium | External control |

---

## Quick Answer

### "How can I change comparison level?"

**THREE WAYS:**

1. **Fixed (Hardware):** External resistor divider
   ```
   Simple: R1=510Ω, R2=2.2kΩ → 2.70V
   ```

2. **Programmable (Software):** Use DAC ⭐ **RECOMMENDED**
   ```c
   set_overcurrent_limit(7.0f);  // 7A threshold
   ```

3. **Multi-Level (Hardware):** Multiple comparators
   ```
   3 comparators: Warning, Trip, Critical
   ```

**Best Choice:** Programmable DAC (Method 2) ✅

---

## Next Steps

When you're ready to implement, I can:

1. ✅ Integrate DAC IP
2. ✅ Connect to comparator
3. ✅ Create threshold control firmware
4. ✅ Add calibration support
5. ✅ Test and document

**Just say:** "Implement programmable threshold control"

---

**Created:** 2026-03-07  
**Status:** Complete threshold control guide

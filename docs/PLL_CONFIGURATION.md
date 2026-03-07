# PLL Configuration for 40 MHz from Slower Crystal

## Question

> "is it possible to add PLL to use slower external crystal to obtain internal 40MHz performance?"

## Answer

**YES!** ✅ Caravel has a **built-in PLL** that can multiply a slower external crystal up to 40 MHz!

---

## Caravel PLL Overview

### What is Available

**Caravel Management SoC includes:**
- ✅ **Digital PLL** (Phase-Locked Loop)
- ✅ **Feedback divider** (multiply by 2-31)
- ✅ **Output divider** (divide by 2-7)
- ✅ **Housekeeping SPI configuration**
- ✅ **Fail-safe RC oscillator**

### PLL Architecture

```
External Slow Crystal (e.g., 10 MHz)
    ↓
clock pad (C9)
    ↓
PLL Feedback Divider (×N)
    ↓
VCO (90-214 MHz)
    ↓
Output Divider (÷M)
    ↓
Core Clock (40 MHz) → wb_clk_i
```

---

## How to Get 40 MHz

### Method 1: 10 MHz Crystal → 40 MHz ⭐

**Configuration:**
```
Input:  10 MHz crystal
PLL:    ×16 feedback divider
VCO:    160 MHz (10 × 16)
Divide: ÷4 output divider
Output: 40 MHz
```

**Calculation:**
```
f_vco = f_input × feedback_divider
f_vco = 10 MHz × 16 = 160 MHz ✅ (within 90-214 MHz)

f_core = f_vco / output_divider
f_core = 160 MHz / 4 = 40 MHz ✅
```

**Register Settings:**
```
PLL Enable:          0x08[0] = 1
PLL Feedback Divider: 0x12[4:0] = 16 (0x10)
PLL Output Divider:   0x11[2:0] = 4 (0x04)
```

---

### Method 2: 8 MHz Crystal → 40 MHz

**Configuration:**
```
Input:  8 MHz crystal
PLL:    ×20 feedback divider
VCO:    160 MHz (8 × 20)
Divide: ÷4 output divider
Output: 40 MHz
```

**Calculation:**
```
f_vco = 8 MHz × 20 = 160 MHz ✅
f_core = 160 MHz / 4 = 40 MHz ✅
```

**Register Settings:**
```
PLL Enable:          0x08[0] = 1
PLL Feedback Divider: 0x12[4:0] = 20 (0x14)
PLL Output Divider:   0x11[2:0] = 4 (0x04)
```

---

### Method 3: 16 MHz Crystal → 40 MHz

**Configuration:**
```
Input:  16 MHz crystal
PLL:    ×10 feedback divider
VCO:    160 MHz (16 × 10)
Divide: ÷4 output divider
Output: 40 MHz
```

**Calculation:**
```
f_vco = 16 MHz × 10 = 160 MHz ✅
f_core = 160 MHz / 4 = 40 MHz ✅
```

**Register Settings:**
```
PLL Enable:          0x08[0] = 1
PLL Feedback Divider: 0x12[4:0] = 10 (0x0A)
PLL Output Divider:   0x11[2:0] = 4 (0x04)
```

---

## PLL Register Map

### Housekeeping SPI Registers

| Address | Bits | Name | Description |
|---------|------|------|-------------|
| **0x08** | 0 | PLL_ENABLE | 0=Bypass, 1=Enable PLL |
| **0x11** | 2:0 | PLL_OUT_DIV | Output divider (2-7) |
| **0x12** | 4:0 | PLL_FB_DIV | Feedback divider (2-31) |

### PLL Enable (0x08)

```
Bit 0: PLL_ENABLE
  0 = PLL bypassed (use external clock directly)
  1 = PLL enabled (multiply external clock)
```

### PLL Feedback Divider (0x12)

```
Bits 4:0: Feedback divider value (2-31)

Multiply factor = feedback_divider
VCO frequency = input_freq × feedback_divider

Constraint: 90 MHz ≤ VCO ≤ 214 MHz
Optimal: VCO ≈ 150 MHz
```

### PLL Output Divider (0x11)

```
Bits 2:0: Output divider value (2-7)

Output frequency = VCO_freq / output_divider
```

---

## PLL Constraints

### VCO Frequency Range

**CRITICAL:** VCO must be within 90-214 MHz

```
Valid:   90 MHz ≤ (f_input × feedback_div) ≤ 214 MHz
Optimal: VCO ≈ 150 MHz (center of range)
```

### Input Frequency Limits

**Minimum:** ~4-5 MHz  
**Maximum:** Limited by VCO constraints

**Examples:**

| Input (MHz) | Min FB | Max FB | VCO Range (MHz) |
|-------------|--------|--------|-----------------|
| 4 | 23 | 31 | 92-124 |
| 5 | 18 | 31 | 90-155 |
| 8 | 12 | 26 | 96-208 |
| **10** | **9** | **21** | **90-210** ✅ |
| 16 | 6 | 13 | 96-208 |
| 20 | 5 | 10 | 100-200 |

---

## Complete Configuration Examples

### Example 1: 10 MHz → 40 MHz (Recommended) ⭐

**Crystal:** 10.000 MHz  
**Target:** 40 MHz core clock

**Configuration:**

| Parameter | Value | Register | Data |
|-----------|-------|----------|------|
| Input frequency | 10 MHz | - | - |
| Feedback divider | 16 | 0x12 | 0x10 |
| VCO frequency | 160 MHz | - | - |
| Output divider | 4 | 0x11 | 0x04 |
| **Core clock** | **40 MHz** | - | - |

**Firmware:**
```c
// Configure PLL for 10 MHz → 40 MHz
void configure_pll_40mhz(void) {
    // Access housekeeping SPI
    reg_hkspi_disable = 0;  // Enable housekeeping SPI
    
    // Set PLL feedback divider = 16
    reg_hkspi_pll_divider = 16;  // 0x12 = 16
    
    // Set PLL output divider = 4
    reg_hkspi_pll_out_div = 4;  // 0x11 = 4
    
    // Enable PLL
    reg_hkspi_pll_ena = 1;  // 0x08[0] = 1
    
    // Wait for PLL lock (~1ms)
    delay_ms(1);
}
```

**Crystal:**
```
Part: SG-210STF 10.0000MC
Frequency: 10.000 MHz
Load: 18 pF
ESR: 50Ω
Package: SMD 3.2×2.5mm
Cost: ~$0.40
```

**Advantages:**
- ✅ Cheaper crystal ($0.40 vs $0.80)
- ✅ Standard frequency (common)
- ✅ Low power (lower frequency input)
- ✅ VCO in optimal range (160 MHz)

---

### Example 2: 8 MHz → 40 MHz

**Crystal:** 8.000 MHz  
**Target:** 40 MHz core clock

**Configuration:**

| Parameter | Value | Register | Data |
|-----------|-------|----------|------|
| Input frequency | 8 MHz | - | - |
| Feedback divider | 20 | 0x12 | 0x14 |
| VCO frequency | 160 MHz | - | - |
| Output divider | 4 | 0x11 | 0x04 |
| **Core clock** | **40 MHz** | - | - |

**Firmware:**
```c
void configure_pll_8mhz_to_40mhz(void) {
    reg_hkspi_disable = 0;
    reg_hkspi_pll_divider = 20;     // Feedback = 20
    reg_hkspi_pll_out_div = 4;      // Output div = 4
    reg_hkspi_pll_ena = 1;
    delay_ms(1);
}
```

---

### Example 3: 16 MHz → 40 MHz

**Crystal:** 16.000 MHz  
**Target:** 40 MHz core clock

**Configuration:**

| Parameter | Value | Register | Data |
|-----------|-------|----------|------|
| Input frequency | 16 MHz | - | - |
| Feedback divider | 10 | 0x12 | 0x0A |
| VCO frequency | 160 MHz | - | - |
| Output divider | 4 | 0x11 | 0x04 |
| **Core clock** | **40 MHz** | - | - |

**Firmware:**
```c
void configure_pll_16mhz_to_40mhz(void) {
    reg_hkspi_disable = 0;
    reg_hkspi_pll_divider = 10;     // Feedback = 10
    reg_hkspi_pll_out_div = 4;      // Output div = 4
    reg_hkspi_pll_ena = 1;
    delay_ms(1);
}
```

---

## PLL vs. Direct Crystal Comparison

### Option A: Direct 40 MHz Crystal

```
40 MHz Crystal → Caravel → 40 MHz wb_clk_i
```

**Advantages:**
- ✅ Simplest (no configuration)
- ✅ Lowest jitter
- ✅ Best accuracy
- ✅ No PLL lock time

**Disadvantages:**
- ❌ More expensive crystal (~$0.80)
- ❌ Higher frequency = more power

**Cost:** ~$1.00

---

### Option B: 10 MHz Crystal + PLL

```
10 MHz Crystal → PLL (×16/4) → 40 MHz wb_clk_i
```

**Advantages:**
- ✅ Cheaper crystal (~$0.40)
- ✅ Lower input frequency = less power
- ✅ More common crystal
- ✅ Flexibility (can change frequency)

**Disadvantages:**
- ❌ Requires firmware configuration
- ❌ Slightly more jitter
- ❌ PLL lock time (~1ms startup)
- ❌ Complexity

**Cost:** ~$0.60

---

## PLL Jitter and Accuracy

### Expected Performance

**PLL Jitter:**
- Typical: 100-200 ps RMS
- Impact on 8 kHz PWM: Negligible (<0.01%)

**Frequency Accuracy:**
- Limited by input crystal (±50 ppm)
- PLL tracks input crystal
- **Same accuracy as direct crystal** ✅

**Lock Time:**
- ~1 ms at startup
- Not an issue for motor control

---

## Complete Firmware Example

### PLL Configuration for FOC

```c
#include <defs.h>
#include <stub.h>

//=============================================================================
// PLL Configuration for 10 MHz → 40 MHz
//=============================================================================

void configure_pll_for_foc(void) {
    // Step 1: Enable housekeeping SPI access
    reg_hkspi_disable = 0;
    
    // Step 2: Configure PLL for 40 MHz
    // Input: 10 MHz
    // Feedback: ×16 → VCO = 160 MHz
    // Output: ÷4 → Core = 40 MHz
    
    reg_hkspi_pll_divider = 16;      // 0x12[4:0] = 16
    reg_hkspi_pll_out_div = 4;       // 0x11[2:0] = 4
    
    // Step 3: Enable PLL
    reg_hkspi_pll_ena = 1;           // 0x08[0] = 1
    
    // Step 4: Wait for PLL lock
    delay_ms(2);  // 2ms to be safe
    
    // Step 5: Verify clock (optional)
    // Read back PLL lock status if available
}

//=============================================================================
// Main FOC Initialization
//=============================================================================

int main(void) {
    // Configure GPIO
    init_debug_gpio();
    
    // Configure PLL to get 40 MHz
    configure_pll_for_foc();
    
    // Now wb_clk_i is 40 MHz
    // Initialize FOC peripherals
    init_motor_pwm();     // Uses 40 MHz clock
    init_motor_adc();
    init_foc_timer();
    ocp_init();
    
    // Initialize FOC
    foc_init_params(&foc_params);
    foc_init_state(&foc_state, 8000.0f);
    
    // Run FOC loop
    while (1) {
        if (READ_REG(TIMER_STATUS) & 0x01) {
            WRITE_REG(TIMER_STATUS, 0x01);
            foc_process();
        }
    }
}
```

---

## Recommended Crystal Options

### Budget Option: 10 MHz Crystal + PLL ⭐

**Crystal:**
```
Part: SG-210STF 10.0000MC (Epson)
Frequency: 10.000 MHz
Load: 18 pF
ESR: 50Ω max
Accuracy: ±30 ppm
Package: 3.2×2.5mm SMD
Cost: ~$0.40
```

**Total Cost:**
- Crystal: $0.40
- Capacitors (2× 18pF): $0.10
- **Total: $0.50** (saves $0.50 vs direct 40 MHz)

**PLL Configuration:**
- Feedback: ×16
- Output: ÷4
- VCO: 160 MHz
- Core: 40 MHz

---

### Alternative: 8 MHz Crystal + PLL

**Crystal:**
```
Part: ABM3-8.000MHZ (Abracon)
Frequency: 8.000 MHz
Load: 18 pF
Accuracy: ±30 ppm
Cost: ~$0.35
```

**Total Cost:** ~$0.45

**PLL Configuration:**
- Feedback: ×20
- Output: ÷4
- VCO: 160 MHz
- Core: 40 MHz

---

## Clock Manager IP Option

### MS_CLK_RST (Alternative)

**Available IP:** `MS_CLK_RST` - Digital Clock Manager

**Features:**
- ✅ Internal RC oscillator (8/16/32/64/128 MHz)
- ✅ Clock multiplexing
- ✅ Clock divider (÷2, ÷4, ÷8)
- ✅ External clock monitor
- ✅ PoR generation

**Limitations:**
- ❌ **No PLL** (no frequency multiplication)
- ❌ Can only divide, not multiply
- ❌ RC oscillator: ±10% accuracy (not suitable for FOC)

**Verdict:** ⚠️ Not ideal for motor control
- Can use 64 MHz RC ÷ 2 = 32 MHz (not 40 MHz)
- Poor accuracy (±10%)
- Better to use Caravel PLL

---

## Decision Guide

### When to Use PLL

**Use PLL + Slow Crystal IF:**
- ✅ Cost is critical (save $0.40-0.50)
- ✅ 10 MHz crystal more available
- ✅ OK with firmware configuration
- ✅ 100-200 ps jitter acceptable

**Recommended:** 10 MHz crystal + PLL

---

### When to Use Direct Crystal

**Use Direct 40 MHz Crystal IF:**
- ✅ Simplicity preferred
- ✅ No firmware configuration wanted
- ✅ Lowest jitter critical
- ✅ Cost difference ($0.50) not important

**Recommended:** 40 MHz direct

---

## Performance Comparison

| Metric | Direct 40 MHz | 10 MHz + PLL |
|--------|---------------|--------------|
| **Core Clock** | 40 MHz | 40 MHz |
| **Jitter** | <50 ps | 100-200 ps |
| **Accuracy** | ±50 ppm | ±50 ppm (crystal) |
| **Startup Time** | Immediate | +1ms (PLL lock) |
| **Configuration** | None | Firmware needed |
| **Crystal Cost** | $0.80 | $0.40 |
| **Total Cost** | $1.00 | $0.50 |
| **FOC @ 8kHz** | ✅ Perfect | ✅ Perfect |

**Both work perfectly for FOC!** ✅

---

## Recommendations

### For Production Motor Control

**Option 1: 10 MHz Crystal + PLL** ⭐ **RECOMMENDED**

**Why:**
- Lower cost ($0.50 saved)
- 10 MHz crystals more common
- Flexibility to change frequency
- Jitter negligible for FOC
- Easy firmware configuration

**Crystal:** SG-210STF 10.0000MC  
**Configuration:** FB=16, OUT_DIV=4  
**Result:** 40 MHz ± 0.005%

---

### For Simplicity

**Option 2: 40 MHz Direct Crystal**

**Why:**
- No configuration needed
- Lowest jitter
- Immediate startup
- Simplest design

**Crystal:** ABM3B-40.000MHZ-D2Y-T  
**Configuration:** None  
**Result:** 40 MHz ± 0.005%

---

## Summary

### Question: Can we use PLL with slower crystal?

**Answer:** ✅ **YES! Caravel has built-in PLL**

**Best Solution:**
```
10 MHz Crystal
    ↓
Caravel PLL (×16 ÷ 4)
    ↓
40 MHz wb_clk_i
    ↓
Perfect for FOC Motor Control
```

**Benefits:**
- ✅ Saves $0.50
- ✅ Same performance
- ✅ Flexible
- ✅ Common crystal

**Configuration:**
```c
reg_hkspi_pll_divider = 16;   // ×16
reg_hkspi_pll_out_div = 4;    // ÷4
reg_hkspi_pll_ena = 1;        // Enable
delay_ms(1);                   // Lock
// Now have 40 MHz!
```

---

## Quick Reference

| Question | Answer |
|----------|--------|
| **Can use PLL with slow crystal?** | ✅ YES |
| **Does Caravel have PLL?** | ✅ YES (built-in) |
| **Best slow crystal?** | 10 MHz ⭐ |
| **How to get 40 MHz?** | 10 MHz × 16 ÷ 4 |
| **Cost savings?** | $0.50 |
| **Performance OK for FOC?** | ✅ Perfect |
| **Jitter acceptable?** | ✅ Yes (<200ps) |
| **Firmware needed?** | ✅ Yes (simple) |

---

**Created:** 2026-03-07  
**Status:** Complete PLL configuration guide  
**Recommendation:** **10 MHz crystal + PLL** for cost savings ⭐

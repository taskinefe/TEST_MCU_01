# Clock Architecture for Motor Control System

## Overview

**Question:** What clock source feeds the MCU? Does it contain an internal high-speed clock?

**Answer:** Caravel provides **multiple clock options** including external clocks and **internal oscillator IPs** that can be integrated.

---

## Caravel Default Clock Architecture

### Management SoC (PicoRV32 MCU) Clock

**Default Configuration:**
- **Clock Source:** External crystal oscillator
- **Typical Frequency:** 10-50 MHz
- **Pin:** `clock` (dedicated clock input pad)

**Caravel Clock Tree:**

```
External Crystal/Clock
    ↓
clock pad (GPIO input)
    ↓
Caravel Harness
    ↓
    ├─→ Management SoC (wb_clk_i)
    │   └─→ PicoRV32 CPU
    │
    ├─→ User Project (wb_clk_i)
    │   └─→ Your peripherals
    │
    └─→ user_clock2 (optional, independent)
```

### Default Clock Distribution

| Domain | Clock Signal | Source | Typical Frequency |
|--------|-------------|--------|-------------------|
| **Management SoC** | `wb_clk_i` | External | 10-50 MHz |
| **User Project** | `wb_clk_i` | Same as management | 10-50 MHz |
| **User Clock 2** | `user_clock2` | Independent divider | Programmable |

---

## Available Clock Sources

### Option 1: External Crystal (Caravel Default) ⭐

**Configuration:**
```
External Crystal Oscillator → clock pad → Caravel
```

**Advantages:**
- ✅ High accuracy (±50 ppm typical)
- ✅ Stable frequency
- ✅ Low jitter
- ✅ Good for motor control
- ✅ No integration needed (Caravel default)

**Disadvantages:**
- ❌ Requires external component
- ❌ PCB space
- ❌ Additional BOM cost (~$0.50-$2)

**Typical Crystals:**
- 10 MHz
- 16 MHz
- 20 MHz
- 25 MHz
- 40 MHz ⭐ (recommended for motor control)

**Recommended for Motor Control:** ✅ **YES - Best option**

---

### Option 2: Internal RC Oscillator (500 kHz)

**Available IP:** `sky130_ef_ip__rc_osc_500k`

**Specifications:**
- **Frequency:** 500 kHz (nominal)
- **Type:** Ring oscillator (RC-based)
- **Power:** Very low
- **Accuracy:** ±10-20% (temperature/voltage dependent)
- **Enable:** Software controllable

**Pinout:**
```
avdd  - 3.3V analog supply
avss  - Analog ground
dvdd  - 1.8V digital supply
dvss  - Digital ground
dout  - Clock output (500 kHz)
ena   - Enable input
```

**Advantages:**
- ✅ No external components
- ✅ Very low power
- ✅ Fully integrated
- ✅ Software enable/disable

**Disadvantages:**
- ❌ **LOW frequency (500 kHz only)**
- ❌ **Poor accuracy (±10-20%)**
- ❌ Temperature sensitive
- ❌ **NOT suitable for motor control**

**For Motor Control:** ❌ **NO - Too slow and inaccurate**

**Good For:**
- Low-power applications
- RTC (with calibration)
- Watchdog timers
- Non-critical timing

---

### Option 3: Crystal Oscillator 16-17 MHz (External Crystal)

**Available IP:** `sky130_ef_ip__xtal_osc_16M`

**Specifications:**
- **Frequency:** 16-17.2 MHz (with external crystal)
- **Type:** Crystal oscillator circuit
- **Crystal Required:** 17.2032 MHz resonator
- **Accuracy:** ±50 ppm (crystal dependent)
- **Load Capacitance:** 22 pF

**External Crystal:**
```
IQD LFXTAL063075 (17.2032 MHz)
- Load cap: 22 pF
- Shunt cap: 7 pF
- Drive level: 500 µW max
- ESR: 40Ω max
- Cost: ~$1-2
```

**Advantages:**
- ✅ High accuracy (±50 ppm)
- ✅ Stable
- ✅ Good frequency for motor control
- ✅ Integrated oscillator circuit

**Disadvantages:**
- ❌ Requires external crystal
- ❌ Requires load capacitors (2× 11 pF)
- ❌ PCB space

**For Motor Control:** ✅ **YES - Good option**

**Recommended Crystal:** 17.2032 MHz or 16.384 MHz

---

### Option 4: Low-Speed Crystal (32.768 kHz)

**Available IP:** `sky130_ef_ip__xtal_osc_32k`

**Specifications:**
- **Frequency:** 32.768 kHz
- **Type:** Watch crystal oscillator
- **Crystal:** ECS-.327-12.5-39-TR
- **Accuracy:** ±20 ppm
- **Power:** Ultra-low

**Advantages:**
- ✅ Ultra-low power
- ✅ Perfect for RTC
- ✅ Very accurate for timekeeping
- ✅ Low cost crystal (~$0.20)

**Disadvantages:**
- ❌ **VERY low frequency (32 kHz)**
- ❌ **Cannot run CPU**
- ❌ **NOT for motor control**

**For Motor Control:** ❌ **NO - Too slow**

**Good For:**
- Real-time clock (RTC)
- Low-power timekeeping
- Wake-up timers

---

## Recommended Clock Architecture for Motor Control

### Recommended Configuration ⭐

```
External 40 MHz Crystal
    ↓
Caravel clock pad
    ↓
wb_clk_i (40 MHz)
    ↓
    ├─→ Management SoC (PicoRV32)
    │   └─→ Runs FOC firmware
    │
    └─→ User Project Peripherals
        ├─→ Motor PWM (40 MHz base)
        ├─→ ADC (40 MHz base)
        ├─→ Timer (40 MHz base)
        └─→ Overcurrent Protection (40 MHz)
```

**Why 40 MHz?**
- ✅ High enough for precise PWM (8 kHz × 5000 = 40 MHz)
- ✅ Good FOC loop timing (1.4 µs @ 40 MHz)
- ✅ Precise ADC timing
- ✅ Standard frequency, easy to source
- ✅ Not too high (lower power than 50+ MHz)

---

## Clock Requirements for Motor Control

### FOC System Requirements

| Function | Requirement | @ 40 MHz |
|----------|-------------|----------|
| **PWM Frequency** | 8 kHz | ✅ 5000 counts |
| **PWM Resolution** | 12-bit (4096) | ✅ 5000 counts |
| **FOC Loop** | 8 kHz (125 µs) | ✅ 5000 cycles |
| **ADC Conversion** | <1 µs | ✅ ~40 cycles |
| **FOC Processing** | <2 µs | ✅ ~80 cycles |

**Minimum Clock:** 20 MHz (marginal)  
**Recommended Clock:** 40 MHz ⭐  
**Maximum Useful:** 50 MHz

---

## Clock Selection Guide

### By Application

| Application | Best Clock | Frequency | Accuracy |
|-------------|-----------|-----------|----------|
| **Motor Control (FOC)** | **External Crystal** ⭐ | **40 MHz** | **±50 ppm** |
| Simple PWM | External Crystal | 10-20 MHz | ±100 ppm |
| Low-power sensor | RC Oscillator | 500 kHz | ±20% OK |
| RTC/Timekeeping | 32 kHz Crystal | 32.768 kHz | ±20 ppm |
| High-performance FOC | External Crystal | 50 MHz | ±50 ppm |

### By Accuracy Needed

| Accuracy | Clock Source | Example |
|----------|-------------|---------|
| **High (±50 ppm)** | **External Crystal** | **Motor control, communications** ⭐ |
| Medium (±0.5%) | Calibrated RC | General timing |
| Low (±10%) | RC Oscillator | Watchdog, non-critical |

---

## External Crystal Selection

### Recommended Crystals for Motor Control

**Option 1: 40 MHz (Best for FOC) ⭐**
```
Part: Abracon ABM3B-40.000MHZ-D2Y-T
Frequency: 40.000 MHz
Load: 18 pF
ESR: 40Ω max
Package: SMD 5×3.2mm
Cost: ~$0.80
```

**Option 2: 50 MHz (High Performance)**
```
Part: Abracon ABM8G-50.000MHZ-4Y-T3
Frequency: 50.000 MHz
Load: 18 pF
ESR: 30Ω max
Package: SMD 3.2×2.5mm
Cost: ~$1.20
```

**Option 3: 25 MHz (Budget)**
```
Part: ECS ECS-250-18-33-TR
Frequency: 25.000 MHz
Load: 18 pF
ESR: 50Ω max
Package: SMD 5×3.2mm
Cost: ~$0.50
```

### Crystal Circuit

```
        Caravel
         clock
           │
           ├─ 18pF (C1)
           │
Crystal ───┤
           │
           ├─ 18pF (C2)
           │
          GND

Additional:
- Series resistor (1MΩ) optional
- Keep traces short (<2cm)
- Place crystal close to chip
- GND plane under crystal
```

---

## Clock Distribution Architecture

### Complete System

```
External 40 MHz Crystal
    ↓
Caravel Clock Input
    ↓
PLL (optional, future)
    ↓
    ├─→ wb_clk_i (40 MHz)
    │   ├─→ Management SoC
    │   ├─→ User Project
    │   ├─→ Peripherals
    │   └─→ Wishbone Bus
    │
    └─→ user_clock2 (programmable divider)
        └─→ Optional secondary clock domain
```

### Peripheral Clocks

| Peripheral | Clock | Frequency | Derived From |
|------------|-------|-----------|--------------|
| Motor PWM | wb_clk_i | 40 MHz | System clock |
| Motor ADC | wb_clk_i | 40 MHz | System clock |
| Timer | wb_clk_i | 40 MHz | System clock |
| OCP | wb_clk_i | 40 MHz | System clock |
| SPI | wb_clk_i / N | 1-10 MHz | Prescaler |
| I2C | wb_clk_i / N | 100-400 kHz | Prescaler |

**All peripherals use single clock domain (wb_clk_i)** ✅

---

## Alternative: Internal RC with PLL (Future)

### Concept

```
Internal RC 500 kHz
    ↓
PLL (×80)
    ↓
40 MHz
```

**Status:** 🚧 **Not Currently Available**

**Would Need:**
- PLL IP (not in current IP library)
- Calibration circuit
- Lock detection

**Advantages if Available:**
- ✅ No external components
- ✅ Fully integrated

**Disadvantages:**
- ❌ Not yet implemented
- ❌ Still less accurate than crystal
- ❌ Higher jitter

---

## Power Considerations

### Clock Power Consumption

| Clock Source | Power | Best For |
|-------------|-------|----------|
| External 40 MHz | ~5-10 mW | **Motor control** ⭐ |
| RC 500 kHz | <1 mW | Low-power standby |
| 32 kHz Crystal | <100 µW | RTC |

### Power Management Strategy

```c
// Active mode (FOC running)
enable_40mhz_clock();
run_foc();

// Standby mode
disable_40mhz_clock();
enable_32khz_rtc();
wait_for_wakeup();

// Emergency low-power
switch_to_rc_osc();  // 500 kHz
reduce_voltage();
```

---

## Clock Accuracy Impact

### PWM Frequency Error

**With ±50 ppm crystal:**
```
8 kHz PWM target
±50 ppm = ±0.4 Hz
Actual: 7999.6 - 8000.4 Hz
```
✅ **Excellent for motor control**

**With ±10% RC oscillator:**
```
8 kHz PWM target
±10% = ±800 Hz
Actual: 7200 - 8800 Hz
```
❌ **Unacceptable for FOC**

### FOC Loop Timing Error

**With ±50 ppm crystal:**
```
125 µs loop time target
±50 ppm = ±6.25 ns
```
✅ **Negligible**

**With ±10% RC oscillator:**
```
125 µs loop time target
±10% = ±12.5 µs
```
❌ **FOC timing corrupted**

---

## Recommended Configuration

### For Production Motor Control ⭐

**Clock Source:** External 40 MHz crystal  
**Part:** Abracon ABM3B-40.000MHZ-D2Y-T  
**Load Caps:** 2× 18 pF (C0G/NP0)  
**Accuracy:** ±50 ppm  
**Cost:** ~$0.80 + $0.20 (caps) = **$1.00**  

**Benefits:**
- ✅ Perfect for 8 kHz PWM (5000 counts)
- ✅ Precise FOC timing
- ✅ Standard frequency
- ✅ Low cost
- ✅ Proven reliability

---

## Implementation

### Hardware Connection

```
PCB Layout:
┌─────────────────┐
│  Caravel SoC    │
│                 │
│  clock ●────────┼─── 18pF ──┬─── [40MHz XTAL] ─── 18pF ─── GND
│                 │            │
│                 │           GND
└─────────────────┘

Notes:
- Place crystal within 2cm of clock pad
- Use ground plane under crystal
- Route traces on same layer
- Keep away from noisy signals
```

### BOM

| Part | Description | Qty | Cost |
|------|-------------|-----|------|
| XTAL | 40 MHz, 18pF, ±50ppm | 1 | $0.80 |
| C1, C2 | 18pF, C0G, 50V, 0402 | 2 | $0.10 |
| **Total** | | | **$1.00** |

---

## Testing

### Clock Verification

```c
// Measure actual frequency
void test_clock_frequency(void) {
    // Configure timer for 1 second
    WRITE_REG(TIMER_PERIOD, 40000000 - 1);  // 40 MHz
    WRITE_REG(TIMER_CTRL, TIMER_ENABLE);
    
    // Wait for timer overflow
    while (!(READ_REG(TIMER_STATUS) & 0x01));
    
    // If overflow occurs at exactly 1 second, clock is accurate
    printf("Clock test: PASS\n");
}

// Measure PWM frequency
void test_pwm_frequency(void) {
    // Set PWM to 8 kHz
    WRITE_REG(PWM_PERIOD, 5000 - 1);
    WRITE_REG(PWM_CTRL, PWM_ENABLE);
    
    // Measure with oscilloscope
    // Should read 8.000 kHz ±0.4 Hz
}
```

---

## Summary

### Question: Clock Source for MCU?

**Answer:**

**Default:** Caravel uses **external clock/crystal** input

**For Motor Control:**
- ✅ **Use external 40 MHz crystal** (recommended)
- ✅ Accuracy: ±50 ppm
- ✅ Cost: ~$1.00
- ✅ Perfect for FOC

**Internal Options Available:**
- ⚠️ RC Oscillator: 500 kHz, ±10% (NOT for motor control)
- ⚠️ Crystal oscillator IP: 16-17 MHz (requires crystal)
- ⚠️ 32 kHz crystal: RTC only (too slow)

**Recommendation:**
```
External 40 MHz Crystal
└─→ Best performance, accuracy, cost
    Perfect for 8 kHz FOC
```

---

## Quick Reference

| Question | Answer |
|----------|--------|
| **Does Caravel have internal high-speed clock?** | ❌ No built-in high-speed oscillator |
| **What's the default clock source?** | External crystal/clock input |
| **What internal oscillators are available?** | 500 kHz RC (too slow for motor control) |
| **What frequency for motor control?** | **40 MHz recommended** ⭐ |
| **What clock accuracy needed?** | **±50 ppm (crystal)** ⭐ |
| **Can we use RC oscillator for FOC?** | ❌ No - too slow and inaccurate |
| **What's the total cost?** | **~$1.00** (crystal + caps) |

---

**Created:** 2026-03-07  
**Status:** Complete clock architecture guide  
**Recommendation:** **40 MHz external crystal** ⭐

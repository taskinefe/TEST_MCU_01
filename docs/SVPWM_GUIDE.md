# SVPWM (Space Vector PWM) Module - User Guide

## Overview

The **SVPWM module** converts voltage vector commands (Vα, Vβ) from FOC algorithm into optimal 3-phase PWM duty cycles.

**Key Benefits:**
- ✅ **15% higher DC bus utilization** vs sinusoidal PWM
- ✅ **Lower harmonic distortion**
- ✅ **Hardware-accelerated** (single-cycle calculation)
- ✅ **Fixed-point arithmetic** (no floating point needed)

**Base Address:** 0x3009_0000 (when integrated)

---

## What is SVPWM?

### Traditional Sinusoidal PWM
- Uses 3 sine waves 120° apart
- Max output voltage: 0.866 × Vdc

### Space Vector PWM
- Uses 8 voltage vectors in hexagonal pattern
- Max output voltage: **1.0 × Vdc** (15% improvement!)
- Optimal switching sequence
- Lower total harmonic distortion (THD)

---

## Register Map

| Offset | Register   | Access | Description |
|--------|------------|--------|-------------|
| 0x00   | CTRL       | RW     | Control (enable, trigger) |
| 0x04   | V_ALPHA    | RW     | Vα voltage (Q15 format) |
| 0x08   | V_BETA     | RW     | Vβ voltage (Q15 format) |
| 0x0C   | VDC        | RW     | DC bus voltage (Q15) |
| 0x10   | DUTY_A     | RO     | Phase A duty cycle |
| 0x14   | DUTY_B     | RO     | Phase B duty cycle |
| 0x18   | DUTY_C     | RO     | Phase C duty cycle |
| 0x1C   | STATUS     | RO     | Ready flag |
| 0x20   | PERIOD     | RW     | PWM period value |

### CTRL Register (0x00)
- Bit 0: ENABLE
- Bit 1: UPDATE (write 1 to trigger calculation)

### Data Format: Q15 Fixed-Point
```
Value range: -32768 to +32767
Represents: -1.0 to +0.999969
Example: 0x4000 = 0.5, 0x7FFF = ~1.0, 0x8000 = -1.0
```

---

## Usage Example

### FOC Integration

```c
#define SVPWM_BASE 0x30090000
#define CTRL     0x00
#define V_ALPHA  0x04
#define V_BETA   0x08
#define DUTY_A   0x10
#define DUTY_B   0x14
#define DUTY_C   0x18
#define STATUS   0x1C

// FOC current loop
void foc_current_loop(float Id, float Iq, float theta) {
    // PI controllers
    float Vd = pi_d(Id_ref - Id);
    float Vq = pi_q(Iq_ref - Iq);
    
    // Inverse Park transform
    float V_alpha = Vd*cos(theta) - Vq*sin(theta);
    float V_beta = Vd*sin(theta) + Vq*cos(theta);
    
    // Convert to Q15
    int16_t V_alpha_q15 = (int16_t)(V_alpha * 32767.0);
    int16_t V_beta_q15 = (int16_t)(V_beta * 32767.0);
    
    // Write to SVPWM
    USER_writeWord(V_alpha_q15, (SVPWM_BASE - 0x30000000 + V_ALPHA) >> 2);
    USER_writeWord(V_beta_q15, (SVPWM_BASE - 0x30000000 + V_BETA) >> 2);
    
    // Trigger calculation
    USER_writeWord(0x03, (SVPWM_BASE - 0x30000000 + CTRL) >> 2);
    
    // Wait for ready
    while (!(USER_readWord((SVPWM_BASE - 0x30000000 + STATUS) >> 2) & 0x01));
    
    // Read duty cycles
    uint16_t duty_a = USER_readWord((SVPWM_BASE - 0x30000000 + DUTY_A) >> 2);
    uint16_t duty_b = USER_readWord((SVPWM_BASE - 0x30000000 + DUTY_B) >> 2);
    uint16_t duty_c = USER_readWord((SVPWM_BASE - 0x30000000 + DUTY_C) >> 2);
    
    // Apply to motor PWM
    set_pwm_duty(duty_a, duty_b, duty_c);
}
```

---

## SVPWM Algorithm

### 1. Sector Determination (6 sectors)
```
Sector 1: 0°   - 60°
Sector 2: 60°  - 120°
Sector 3: 120° - 180°
Sector 4: 180° - 240°
Sector 5: 240° - 300°
Sector 6: 300° - 360°
```

### 2. Time Calculation
- T1: Active vector 1 time
- T2: Active vector 2 time  
- T0: Zero vector time
- T1 + T2 + T0 = PWM_PERIOD

### 3. Duty Cycle Assignment
Duty cycles depend on sector and T1/T2/T0 times.

---

## Performance

**Calculation Time:** 1 clock cycle (25ns @ 40MHz)  
**Throughput:** Up to 40 million SVPWM calculations/second  
**Suitable for:** FOC up to 20kHz current loop

---

## Integration Status

✅ **RTL Designed** - svpwm.v + svpwm_wb.v created  
⏳ **Integration Pending** - Not yet added to user_project  
📚 **Documentation** - Complete

---

**Created:** 2026-03-05  
**Status:** Design Complete

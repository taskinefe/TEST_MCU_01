# 3-Phase Motor PWM Controller - User Guide

## Overview

The Motor PWM peripheral provides **center-aligned complementary PWM** specifically designed for driving 3-phase BLDC/PMSM motors with Field-Oriented Control (FOC).

**Base Address:** 0x3008_0000 (to be integrated)  
**IRQ Line:** 6 (to be integrated)

---

## Key Features

### ✅ Hardware Capabilities

1. **3 Complementary PWM Pairs** (6 outputs total)
   - Phase A: `pwm_ah` (high-side), `pwm_al` (low-side)
   - Phase B: `pwm_bh` (high-side), `pwm_bl` (low-side)
   - Phase C: `pwm_ch` (high-side), `pwm_cl` (low-side)

2. **Center-Aligned Counting**
   - Up/down triangle counter
   - Symmetrical PWM edges
   - Ideal for motor control (minimizes torque ripple)

3. **Programmable Dead-Time**
   - Prevents shoot-through in H-bridge
   - Configurable 0-255 clock cycles
   - At 40 MHz: 25ns - 6.375µs range

4. **ADC Synchronization**
   - Trigger pulse at PWM center (counter peak)
   - Samples motor current at zero-voltage-vector
   - Perfect for FOC current loop

5. **Adjustable PWM Frequency**
   - 5 kHz to 12 kHz (as required)
   - Programmable period register
   - Independent duty cycles for each phase

---

## Register Map

| Offset | Name       | Access | Reset | Description |
|--------|------------|--------|-------|-------------|
| 0x00   | CTRL       | RW     | 0x00  | Control register |
| 0x04   | PERIOD     | RW     | 4000  | PWM period (10kHz default) |
| 0x08   | DUTY_A     | RW     | 2000  | Phase A duty cycle |
| 0x0C   | DUTY_B     | RW     | 2000  | Phase B duty cycle |
| 0x10   | DUTY_C     | RW     | 2000  | Phase C duty cycle |
| 0x14   | DEADTIME   | RW     | 4     | Dead-time (100ns default) |
| 0x18   | STATUS     | RO     | 0x00  | Status register |

### CTRL Register (0x00)

| Bit  | Name          | Access | Description |
|------|---------------|--------|-------------|
| 31:2 | Reserved      | RO     | Reserved |
| 1    | ADC_TRIG_EN   | RW     | Enable ADC trigger output |
| 0    | ENABLE        | RW     | Enable PWM generation |

### PERIOD Register (0x04)

| Bit   | Name   | Access | Description |
|-------|--------|--------|-------------|
| 31:16 | -      | RO     | Reserved |
| 15:0  | PERIOD | RW     | PWM period value |

**PWM Frequency Calculation:**
```
f_pwm = f_clk / (2 × PERIOD)

Example @ 40 MHz clock:
- 5 kHz  → PERIOD = 4000
- 10 kHz → PERIOD = 2000
- 12 kHz → PERIOD = 1667
```

**Note:** Center-aligned mode counts UP then DOWN, so effective period is 2×PERIOD.

### DUTY_A/B/C Registers (0x08, 0x0C, 0x10)

| Bit   | Name | Access | Description |
|-------|------|--------|-------------|
| 31:16 | -    | RO     | Reserved |
| 15:0  | DUTY | RW     | Duty cycle compare value |

**Duty Cycle Calculation:**
```
Duty% = (DUTY / PERIOD) × 100%

Examples (PERIOD = 2000 for 10kHz):
- 50% duty → DUTY = 1000
- 75% duty → DUTY = 1500
- 25% duty → DUTY = 500
```

### DEADTIME Register (0x14)

| Bit  | Name     | Access | Description |
|------|----------|--------|-------------|
| 31:8 | -        | RO     | Reserved |
| 7:0  | DEADTIME | RW     | Dead-time in clock cycles |

**Dead-Time Calculation:**
```
t_deadtime = DEADTIME × (1 / f_clk)

Example @ 40 MHz clock:
- 100ns → DEADTIME = 4
- 200ns → DEADTIME = 8
- 500ns → DEADTIME = 20
- 1µs   → DEADTIME = 40
```

**Typical Values:**
- Small motors (<100W): 100-200ns
- Medium motors (100W-1kW): 200-500ns
- Large motors (>1kW): 500ns-1µs

### STATUS Register (0x18)

| Bit  | Name         | Access | Description |
|------|--------------|--------|-------------|
| 31:1 | -            | RO     | Reserved |
| 0    | PERIOD_FLAG  | RO     | PWM period complete flag |

---

## PWM Frequency Configuration Table

| Target Freq | PERIOD Value | Dead-Time (200ns) | Resolution (bits) |
|-------------|--------------|-------------------|-------------------|
| **5 kHz**   | **4000**     | 8                 | ~11.9 bit         |
| 6 kHz       | 3333         | 8                 | ~11.7 bit         |
| 7 kHz       | 2857         | 8                 | ~11.5 bit         |
| 8 kHz       | 2500         | 8                 | ~11.3 bit         |
| 9 kHz       | 2222         | 8                 | ~11.1 bit         |
| **10 kHz**  | **2000**     | 8                 | **~11.0 bit**     |
| 11 kHz      | 1818         | 8                 | ~10.8 bit         |
| **12 kHz**  | **1667**     | 8                 | **~10.7 bit**     |

**@40 MHz System Clock**

---

## Center-Aligned PWM Operation

### Waveform Diagram

```
Counter:     0 → 1000 → 2000 → 1000 → 0 → 1000 → 2000
                ↗      ↗      ↘      ↘    ↗
Direction:   UP           DOWN        UP

DUTY=1500:
PWM_RAW:     ░░░░░░░░░░░███████░░░░░░░░░░░  ← Symmetric
                        ↑
                     center point

PWM_AH:      ░░░░░░░░░░░███████░░░░░░░░░░░  ← High-side
             └─dt─┘                  └─dt─┘

PWM_AL:      ███████░░░░░░░░░░░░░░█████████  ← Low-side (inverted)
                   └─dt─┘  └─dt─┘

Dead-time zones: Both outputs LOW (safe state)
```

### ADC Trigger Timing

```
Counter:     0 → → → → PERIOD → → → → 0
                        ↑
PWM_AH:      ░░░░░█████████████░░░░░
PWM_AL:      ████░░░░░░░░░░░░░░█████

ADC_TRIG:    ────────┬─────────────  ← Trigger at center
                     ↓
                  Sample here

Why center?
- Zero voltage vector (all phases switching)
- Most accurate current measurement
- Minimizes switching noise
```

---

## Usage Examples

### Example 1: Initialize for 10 kHz PWM with 200ns Dead-Time

```c
#define MOTOR_PWM_BASE 0x30080000
#define CTRL       0x00
#define PERIOD     0x04
#define DUTY_A     0x08
#define DUTY_B     0x0C
#define DUTY_C     0x10
#define DEADTIME   0x14

// Configure period for 10 kHz @ 40 MHz
USER_writeWord(2000, (MOTOR_PWM_BASE - 0x30000000 + PERIOD) >> 2);

// Set dead-time to 200ns (8 cycles @ 40MHz)
USER_writeWord(8, (MOTOR_PWM_BASE - 0x30000000 + DEADTIME) >> 2);

// Set initial duty cycles (50%)
USER_writeWord(1000, (MOTOR_PWM_BASE - 0x30000000 + DUTY_A) >> 2);
USER_writeWord(1000, (MOTOR_PWM_BASE - 0x30000000 + DUTY_B) >> 2);
USER_writeWord(1000, (MOTOR_PWM_BASE - 0x30000000 + DUTY_C) >> 2);

// Enable PWM and ADC trigger
USER_writeWord(0x03, (MOTOR_PWM_BASE - 0x30000000 + CTRL) >> 2);
```

### Example 2: 3-Phase SVPWM (Space Vector PWM)

```c
// SVPWM sector 1, duty = 75%
// Typical FOC output after Clarke/Park transforms

uint16_t period = 2000;  // 10 kHz
uint16_t duty_alpha = 1500;  // 75%
uint16_t duty_beta = 1000;   // 50%
uint16_t duty_zero = 500;    // 25%

USER_writeWord(duty_alpha, (MOTOR_PWM_BASE - 0x30000000 + DUTY_A) >> 2);
USER_writeWord(duty_beta,  (MOTOR_PWM_BASE - 0x30000000 + DUTY_B) >> 2);
USER_writeWord(duty_zero,  (MOTOR_PWM_BASE - 0x30000000 + DUTY_C) >> 2);
```

### Example 3: Emergency Stop

```c
// Disable all PWM outputs immediately
USER_writeWord(0x00, (MOTOR_PWM_BASE - 0x30000000 + CTRL) >> 2);

// All outputs go LOW (safe state)
```

### Example 4: Variable Speed Control

```c
void set_motor_speed(float speed_percent) {
    // speed_percent: 0.0 to 100.0
    uint16_t duty = (uint16_t)((speed_percent / 100.0) * 2000);
    
    // For simple 6-step commutation (not FOC)
    USER_writeWord(duty, (MOTOR_PWM_BASE - 0x30000000 + DUTY_A) >> 2);
    USER_writeWord(duty, (MOTOR_PWM_BASE - 0x30000000 + DUTY_B) >> 2);
    USER_writeWord(duty, (MOTOR_PWM_BASE - 0x30000000 + DUTY_C) >> 2);
}

// Usage
set_motor_speed(75.0);  // 75% speed
```

---

## ADC Integration for FOC

### ADC Sampling Strategy

```c
// 1. Configure Motor PWM for 10 kHz with ADC trigger
USER_writeWord(2000, (MOTOR_PWM_BASE - 0x30000000 + PERIOD) >> 2);
USER_writeWord(0x03, (MOTOR_PWM_BASE - 0x30000000 + CTRL) >> 2);

// 2. ADC automatically triggers at PWM center
// 3. In ADC interrupt handler:
void adc_isr(void) {
    // Read phase currents
    uint16_t ia = read_adc_channel(0);
    uint16_t ib = read_adc_channel(1);
    uint16_t ic = read_adc_channel(2);
    
    // Clarke transform: abc → αβ
    float i_alpha = ia;
    float i_beta = (ia + 2*ib) / sqrt(3);
    
    // Park transform: αβ → dq
    float i_d = i_alpha*cos(theta) + i_beta*sin(theta);
    float i_q = -i_alpha*sin(theta) + i_beta*cos(theta);
    
    // PI controllers
    float v_d = pi_d(i_d_ref - i_d);
    float v_q = pi_q(i_q_ref - i_q);
    
    // Inverse Park: dq → αβ
    float v_alpha = v_d*cos(theta) - v_q*sin(theta);
    float v_beta = v_d*sin(theta) + v_q*cos(theta);
    
    // SVPWM: αβ → PWM duties
    calculate_svpwm(v_alpha, v_beta, &duty_a, &duty_b, &duty_c);
    
    // Update PWM
    USER_writeWord(duty_a, (MOTOR_PWM_BASE - 0x30000000 + DUTY_A) >> 2);
    USER_writeWord(duty_b, (MOTOR_PWM_BASE - 0x30000000 + DUTY_B) >> 2);
    USER_writeWord(duty_c, (MOTOR_PWM_BASE - 0x30000000 + DUTY_C) >> 2);
}
```

---

## Hardware Connection

### 3-Phase Inverter Connection

```
              +VDC (Battery/PSU)
                 │
    ┌────────────┼────────────┬────────────┐
    │            │            │            │
  [HS_A]       [HS_B]       [HS_C]       │
    │            │            │            │
pwm_ah ─────────┤        pwm_bh       pwm_ch
                │            │            │
    ├────────────┼────────────┼────────────┤
    │            │            │            │
  [Phase A]   [Phase B]   [Phase C]   [Motor]
    │            │            │            │
    ├────────────┼────────────┼────────────┤
    │            │            │            │
pwm_al ─────────┤        pwm_bl       pwm_cl
                │            │            │
  [LS_A]       [LS_B]       [LS_C]       │
    │            │            │            │
    └────────────┴────────────┴────────────┘
                 │
                GND

HS = High-Side MOSFET
LS = Low-Side MOSFET
```

### GPIO Pad Assignment (to be assigned)

| Pad | Signal | Direction | Description |
|-----|--------|-----------|-------------|
| TBD | pwm_ah | Output    | Phase A high-side |
| TBD | pwm_al | Output    | Phase A low-side |
| TBD | pwm_bh | Output    | Phase B high-side |
| TBD | pwm_bl | Output    | Phase B low-side |
| TBD | pwm_ch | Output    | Phase C high-side |
| TBD | pwm_cl | Output    | Phase C low-side |

**Note:** Will require 6 additional GPIO pads

---

## Timing Specifications

### At 40 MHz Clock

| Parameter | Value | Notes |
|-----------|-------|-------|
| Minimum PWM frequency | 305 Hz | PERIOD = 65535 |
| Maximum PWM frequency | 625 kHz | PERIOD = 32 |
| **Recommended range** | **5-12 kHz** | **Motor control sweet spot** |
| Dead-time resolution | 25 ns | 1 clock cycle |
| Minimum dead-time | 25 ns | DEADTIME = 1 |
| Maximum dead-time | 6.375 µs | DEADTIME = 255 |
| **Typical dead-time** | **100-500 ns** | **DEADTIME = 4-20** |
| ADC trigger pulse width | 25 ns | 1 clock cycle |
| Duty cycle resolution | 11-12 bits | Depends on frequency |

---

## Safety Features

### Built-In Protection

1. **Dead-Time Insertion**
   - Prevents simultaneous high/low-side conduction
   - Configurable for different MOSFET speeds

2. **Disable on Reset**
   - All outputs LOW on system reset
   - Safe default state

3. **Synchronous Disable**
   - CTRL[0]=0 immediately stops all PWM
   - Clean shutdown

### Recommended External Protection

1. **Gate Drivers with Fault Protection**
   - Desaturation detection
   - Over-current protection
   - Under-voltage lockout (UVLO)

2. **Hardware Interlocks**
   - Emergency stop input (external)
   - Thermal shutdown
   - Over-voltage protection

3. **Current Sense Resistors**
   - Per-phase current measurement
   - Feed to ADC for FOC

---

## Performance Characteristics

### Motor Control Capabilities

| Motor Type | Supported | Method |
|------------|-----------|--------|
| **BLDC (trapezoidal)** | ✅ | 6-step commutation |
| **PMSM (sinusoidal)** | ✅ | FOC (Field-Oriented Control) |
| **3-phase BLDC** | ✅ | Sensor or sensorless |
| **Stepper** | ⚠️ | Not optimized (use separate driver) |

### FOC Loop Performance

With ADC trigger at PWM center:
- **Current loop frequency:** Same as PWM (5-12 kHz)
- **Speed loop frequency:** PWM freq / 10 (500-1200 Hz)
- **Position loop frequency:** PWM freq / 100 (50-120 Hz)

Typical FOC execution time @ 40 MHz:
- Clarke/Park transforms: ~50 cycles
- 2× PI controllers: ~100 cycles
- Inverse Park + SVPWM: ~100 cycles
- **Total:** ~250 cycles (~6.25 µs)

**Margin at 10 kHz:** 100 µs period - 6.25 µs execution = **93.75 µs free time** ✅

---

## Status: Not Yet Integrated

⚠️ **This peripheral has been designed but not yet integrated into the project.**

To integrate:
1. Add to `user_project.v` as peripheral #7
2. Assign address 0x3008_0000
3. Connect to 6 GPIO pads (17-22)
4. Route ADC trigger to ADC peripheral
5. Update documentation

---

**Module:** motor_pwm.v, motor_pwm_wb.v  
**Created:** 2026-03-05  
**Status:** ⚠️ Design Complete, Integration Pending

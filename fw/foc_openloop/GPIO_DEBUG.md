# GPIO Debug Signals for FOC Timing Analysis

## Overview

You can assign GPIO pins to toggle on various FOC events for **oscilloscope debugging** and **timing analysis**.

---

## Available GPIO Pins

Caravel management GPIO (`reg_mprj_datal` and `reg_mprj_datah`):

```c
// Management GPIO (can control from firmware)
reg_mprj_datal[31:0]  // GPIO 0-31
reg_mprj_datah[5:0]   // GPIO 32-37

// Reserved (don't use)
// GPIO 0-4: JTAG, management

// Available for debug
// GPIO 29-37: Free for user
```

---

## GPIO Pin Assignments for FOC Debug

### Recommended Debug Signal Mapping

| GPIO | Signal | Description | Oscilloscope Channel |
|------|--------|-------------|---------------------|
| **29** | **ADC_DONE** | Toggle on ADC conversion complete | **CH1** ⭐ |
| **30** | **FOC_START** | Toggle at start of FOC loop | **CH2** |
| **31** | **FOC_DONE** | Toggle when FOC loop complete | **CH3** |
| **32** | **PWM_CENTER** | Toggle at PWM center event | **CH4** |
| **33** | **HEARTBEAT** | Slow toggle (alive indicator) | - |

---

## Implementation

### 1. GPIO Configuration

```c
#include <defs.h>
#include <stub.h>

// GPIO pin assignments
#define GPIO_ADC_DONE     29
#define GPIO_FOC_START    30
#define GPIO_FOC_DONE     31
#define GPIO_PWM_CENTER   32
#define GPIO_HEARTBEAT    33

void init_debug_gpio(void) {
    // Configure GPIO as outputs
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_32 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_33 = GPIO_MODE_MGMT_STD_OUTPUT;
    
    // Apply configuration
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);
    
    // Initialize all low
    reg_mprj_datal &= ~((1 << 29) | (1 << 30) | (1 << 31));
    reg_mprj_datah &= ~((1 << 0) | (1 << 1));  // GPIO 32, 33
}
```

### 2. Toggle Macros

```c
// Toggle GPIO macros
#define TOGGLE_GPIO(pin) do { \
    if (pin < 32) \
        reg_mprj_datal ^= (1 << (pin)); \
    else \
        reg_mprj_datah ^= (1 << ((pin) - 32)); \
} while(0)

#define SET_GPIO(pin) do { \
    if (pin < 32) \
        reg_mprj_datal |= (1 << (pin)); \
    else \
        reg_mprj_datah |= (1 << ((pin) - 32)); \
} while(0)

#define CLR_GPIO(pin) do { \
    if (pin < 32) \
        reg_mprj_datal &= ~(1 << (pin)); \
    else \
        reg_mprj_datah &= ~(1 << ((pin) - 32)); \
} while(0)
```

### 3. ADC Conversion Complete Toggle

```c
void foc_process(void) {
    // Start of FOC
    TOGGLE_GPIO(GPIO_FOC_START);
    
    // Wait for ADC conversion complete
    while (!(READ_REG(MOTOR_ADC_STATUS) & 0x01));
    
    // ADC done - toggle GPIO
    TOGGLE_GPIO(GPIO_ADC_DONE);  // ⭐ ADC conversion complete
    
    // Read ADC data
    foc_read_currents(&foc_state, 0.165f);
    
    // Run FOC transforms
    foc_loop_hw(&foc_state, &foc_params, VDC);
    
    // FOC complete
    TOGGLE_GPIO(GPIO_FOC_DONE);
}
```

### 4. Complete Example

```c
#include <defs.h>
#include <stub.h>
#include "peripherals.h"
#include "foc_lib.h"

// GPIO debug pins
#define GPIO_ADC_DONE     29
#define GPIO_FOC_START    30
#define GPIO_FOC_DONE     31
#define GPIO_HEARTBEAT    33

// Toggle macro
#define TOGGLE_GPIO(pin) reg_mprj_datal ^= (1 << (pin))

void init_debug_gpio(void) {
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;
    reg_mprj_io_33 = GPIO_MODE_MGMT_STD_OUTPUT;
    
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);
}

void foc_process(void) {
    // FOC start marker
    TOGGLE_GPIO(GPIO_FOC_START);
    
    // Wait for ADC
    while (!(READ_REG(MOTOR_ADC_STATUS) & 0x01));
    
    // ADC conversion complete! 🎯
    TOGGLE_GPIO(GPIO_ADC_DONE);
    
    // Read currents
    foc_read_currents(&foc_state, 0.165f);
    
    // Run FOC
    foc_clarke_hw(&foc_state);
    foc_park_hw(&foc_state);
    foc_state.vd = 0.0f;
    foc_state.vq = 2.0f;
    foc_inv_park_hw(&foc_state);
    foc_svpwm_hw(&foc_state, 24.0f);
    foc_update_openloop_angle(&foc_state, &foc_params);
    
    // FOC complete marker
    TOGGLE_GPIO(GPIO_FOC_DONE);
}

int main(void) {
    // Initialize debug GPIO
    init_debug_gpio();
    
    // Initialize FOC hardware
    init_motor_pwm();
    init_motor_adc();
    init_foc_timer();
    
    // Initialize FOC
    foc_init_params(&foc_params);
    foc_init_state(&foc_state, 8000.0f);
    
    uint32_t heartbeat_count = 0;
    
    while (1) {
        // Poll timer (8 kHz)
        if (READ_REG(TIMER_STATUS) & 0x01) {
            WRITE_REG(TIMER_STATUS, 0x01);
            
            // Run FOC with debug signals
            foc_process();
            
            // Heartbeat every 1000 cycles (125ms)
            if (++heartbeat_count >= 1000) {
                TOGGLE_GPIO(GPIO_HEARTBEAT);
                heartbeat_count = 0;
            }
        }
    }
}
```

---

## Oscilloscope Timing Analysis

### What You'll See

```
Time →

CH1 (GPIO 29 - ADC_DONE):
    ___╱╲___╱╲___╱╲___
    125µs period (8kHz)
    Pulse width = ADC conversion time (450ns)

CH2 (GPIO 30 - FOC_START):
    _╱╲___╱╲___╱╲___
    Marks start of FOC processing

CH3 (GPIO 31 - FOC_DONE):
    ___╱╲___╱╲___╱╲_
    Marks end of FOC loop
    
CH1 to CH3 = Total FOC execution time
```

### Measuring ADC Timing

```
PWM Center → ADC Trigger
    ↓
    450ns (ADC conversion)
    ↓
GPIO 29 toggles ← ADC DONE
    ↓
    Read ADC data
    ↓
    Clarke (50ns)
    ↓
    Park (50ns)
    ↓
    Control
    ↓
    Inv Park (50ns)
    ↓
    SVPWM (25ns)
    ↓
GPIO 31 toggles ← FOC DONE
```

**Measurement:**
- **CH1 pulse width** = ADC conversion time (~450ns)
- **CH2 to CH1** = Wait time for ADC
- **CH1 to CH3** = FOC processing time (~1.4µs)
- **CH2 to CH3** = Total loop time (~2µs)

---

## Advanced: Pulse Output (Not Toggle)

For cleaner scope traces, use **pulse** instead of toggle:

```c
// Set high when event starts
#define PULSE_START(pin) SET_GPIO(pin)

// Set low when event ends
#define PULSE_END(pin) CLR_GPIO(pin)

void foc_process(void) {
    // FOC start
    PULSE_START(GPIO_FOC_START);
    
    // Wait for ADC
    while (!(READ_REG(MOTOR_ADC_STATUS) & 0x01));
    
    // ADC done - pulse high while processing
    PULSE_START(GPIO_ADC_DONE);
    
    foc_read_currents(&foc_state, 0.165f);
    
    PULSE_END(GPIO_ADC_DONE);  // ADC read complete
    
    // FOC processing
    foc_loop_hw(&foc_state, &foc_params, VDC);
    
    PULSE_END(GPIO_FOC_START);  // FOC complete
}
```

**Scope view:**
```
GPIO_FOC_START:
    ╱‾‾‾‾╲_______________╱‾‾‾‾╲
    |<-Total FOC time->|
    
GPIO_ADC_DONE:
    ___╱‾╲_______________╱‾╲___
       |<->|
      ADC read
```

---

## Hardware Connections

### GPIO to Oscilloscope

```
Caravel Pad    → Oscilloscope
─────────────────────────────
mprj_io[29]    → CH1 (ADC Done)
mprj_io[30]    → CH2 (FOC Start)
mprj_io[31]    → CH3 (FOC Done)
GND            → GND

Probe Settings:
- 10:1 probe
- DC coupling
- 3.3V scale
- 100ns/div time
```

---

## Example Timing Measurements

### Expected Timings (Hardware FOC)

| Measurement | Expected | Description |
|-------------|----------|-------------|
| ADC conversion | 450 ns | CH1 pulse width |
| Clarke | 50 ns | Hardware |
| Park | 50 ns | Hardware |
| PI control | 100 ns | Software |
| Inv Park | 50 ns | Hardware |
| SVPWM | 25 ns | Hardware |
| **Total FOC** | **~725 ns** | CH1 to CH3 |
| **With overhead** | **~1.4 µs** | Typical |
| **FOC period** | **125 µs** | 8 kHz |

### Performance Check

```c
// Add timing measurement
uint32_t start_time, end_time, foc_time_ns;

void foc_process(void) {
    start_time = READ_REG(TIMER_COUNTER);
    
    // Run FOC...
    
    end_time = READ_REG(TIMER_COUNTER);
    foc_time_ns = ((end_time - start_time) * 1000000000) / SYSTEM_CLOCK;
    
    // Print or store timing
    if (foc_time_ns > 2000) {
        // FOC taking too long!
        error_handler();
    }
}
```

---

## Debug Pin Summary

### Quick Reference Table

| Pin | Name | When Toggles | Use Case |
|-----|------|--------------|----------|
| 29 | ADC_DONE | ADC conversion complete | **Measure ADC timing** ⭐ |
| 30 | FOC_START | Start of FOC loop | Measure FOC duration |
| 31 | FOC_DONE | End of FOC loop | Measure total time |
| 32 | PWM_CENTER | PWM center event | Trigger timing |
| 33 | HEARTBEAT | Every 125ms | Alive indicator |

---

## Production Use

### Conditional Compilation

```c
// Enable debug GPIO only in debug builds
#ifdef DEBUG_GPIO
    #define DEBUG_TOGGLE(pin) TOGGLE_GPIO(pin)
#else
    #define DEBUG_TOGGLE(pin) do {} while(0)
#endif

void foc_process(void) {
    DEBUG_TOGGLE(GPIO_FOC_START);
    
    while (!(READ_REG(MOTOR_ADC_STATUS) & 0x01));
    DEBUG_TOGGLE(GPIO_ADC_DONE);  // Only in debug builds
    
    foc_loop_hw(&foc_state, &foc_params, VDC);
    
    DEBUG_TOGGLE(GPIO_FOC_DONE);
}
```

**Build:**
```bash
# Debug build (with GPIO toggles)
make CFLAGS=-DDEBUG_GPIO

# Production build (no GPIO overhead)
make
```

---

## ✅ **YES, You Can Toggle GPIO on ADC Complete!**

**Simple answer:**
```c
// Wait for ADC
while (!(READ_REG(MOTOR_ADC_STATUS) & 0x01));

// Toggle GPIO 29 when ADC done
reg_mprj_datal ^= (1 << 29);
```

**Benefit:** Perfect for oscilloscope timing analysis! 📊

---

**Created:** 2026-03-07  
**Purpose:** Debug timing analysis with oscilloscope

# Motor ADC IRQ Usage Guide

## ADC Interrupt Generation

The **Motor ADC (3-channel)** generates an **IRQ signal** when all 3 ADC conversions complete.

### Hardware Behavior

```
PWM Center Event
    ↓
Trigger Motor ADC (external trigger)
    ↓
Start 3 simultaneous conversions
    ↓
All 3 conversions complete (450ns)
    ↓
IRQ asserted (high)
    ↓
IRQ stays high until STATUS read
```

---

## Two Methods to Detect Conversion Complete

### Method 1: Poll STATUS Register (Current)

**Firmware polls the status bit:**

```c
void foc_process(void) {
    // Wait for ADC conversion complete
    while (!(READ_REG(MOTOR_ADC_STATUS) & 0x01));
    
    // Read ADC data
    foc_read_currents(&foc_state, 0.165f);
    
    // Continue FOC...
}
```

**Pros:**
- ✅ Simple
- ✅ No interrupt setup

**Cons:**
- ❌ CPU busy-waits
- ❌ Wastes ~450ns waiting

---

### Method 2: Use ADC IRQ (Better!) ⭐

**Let the ADC interrupt tell you when ready:**

```c
// Global flag
volatile uint8_t adc_ready = 0;

// ADC ISR (called when conversion complete)
void adc_isr(void) __attribute__((interrupt)) {
    // Clear IRQ by reading STATUS
    READ_REG(MOTOR_ADC_STATUS);
    
    adc_ready = 1;
}

void foc_process(void) {
    // Wait for ADC interrupt
    while (!adc_ready);
    adc_ready = 0;
    
    // Read ADC data immediately
    foc_read_currents(&foc_state, 0.165f);
    
    // Continue FOC...
}
```

**Pros:**
- ✅ CPU free while waiting
- ✅ Precise timing
- ✅ Lower latency

**Cons:**
- Requires interrupt setup

---

## Even Better: Combined Timer + ADC IRQs

**Use Timer for FOC period, ADC IRQ for data ready:**

```c
volatile uint8_t adc_ready = 0;

// Timer ISR (8 kHz)
void timer_isr(void) {
    // Trigger happens automatically from PWM center
    // Just wait for ADC
    adc_ready = 0;  // Reset flag
}

// ADC ISR (triggered by conversion complete)
void adc_isr(void) {
    READ_REG(MOTOR_ADC_STATUS);  // Clear IRQ
    adc_ready = 1;
}

// Main FOC loop
void foc_loop(void) {
    while (1) {
        // Wait for ADC data ready
        if (adc_ready) {
            adc_ready = 0;
            
            // Read currents
            foc_read_currents(&foc_state, 0.165f);
            
            // Run FOC
            foc_clarke_hw(&foc_state);
            foc_park_hw(&foc_state);
            // ... rest of FOC
        }
    }
}
```

**Timing:**

```
PWM Center (automatic)
    ↓
Trigger ADC (hardware)
    ↓ 450ns
ADC Complete → IRQ
    ↓
adc_isr() sets flag
    ↓
Main loop detects flag
    ↓
Run FOC (1.4µs)
    ↓
Wait for next PWM center (123µs later)
```

---

## ADC IRQ Configuration

### Hardware Connections

The Motor ADC IRQ connects to the **Programmable Interrupt Controller (PIC)**:

```verilog
// In user_project.v
WB_PIC pic_inst (
    .irq_lines({
        ...,
        motor_adc_irq,  // IRQ line 7
        adc_irq,        // IRQ line 6
        ...
    }),
    .irq_out(user_irq[0])
);
```

**Motor ADC IRQ is line 7** in the PIC.

### Firmware Setup

```c
// PIC registers
#define PIC_BASE        0x30080000
#define PIC_IRQ_EN      (PIC_BASE + 0x00)
#define PIC_IRQ_STATUS  (PIC_BASE + 0x04)
#define PIC_IRQ_PENDING (PIC_BASE + 0x08)

// Enable Motor ADC interrupt (line 7)
void enable_adc_irq(void) {
    // Enable IRQ line 7 in PIC
    SET_BITS(PIC_IRQ_EN, (1 << 7));
    
    // Setup RISC-V interrupts
    setup_interrupts();
}

// Check which IRQ triggered
void global_isr(void) {
    uint32_t pending = READ_REG(PIC_IRQ_PENDING);
    
    if (pending & (1 << 7)) {
        // Motor ADC interrupt
        adc_isr();
    }
    
    if (pending & (1 << 3)) {
        // Timer interrupt
        timer_isr();
    }
    
    // Clear pending
    WRITE_REG(PIC_IRQ_PENDING, pending);
}
```

---

## Recommended Approach

### For 8 kHz FOC:

**Best:** Polled timer + polled ADC status
- Simplest
- No interrupt setup needed
- Sufficient performance

**Better:** Polled timer + ADC IRQ
- Slightly more complex
- ADC IRQ wakes CPU
- ~0.5µs saved

**Advanced:** Timer IRQ + ADC IRQ
- Most complex
- Best performance
- Lowest latency
- For high-performance FOC (>20 kHz)

---

## Example: ADC IRQ Implementation

```c
#include "peripherals.h"
#include "foc_lib.h"

volatile uint8_t adc_ready = 0;

// ADC Interrupt Handler
void adc_isr(void) __attribute__((interrupt)) {
    // Clear ADC interrupt by reading STATUS
    uint32_t status = READ_REG(MOTOR_ADC_STATUS);
    
    // Set flag for main loop
    adc_ready = 1;
    
    // Optionally read data here for lower latency
    // foc_read_currents(&foc_state, 0.165f);
}

// Setup ADC interrupts
void setup_adc_irq(void) {
    // Enable Motor ADC interrupt in PIC (line 7)
    uint32_t irq_en = READ_REG(PIC_IRQ_EN);
    irq_en |= (1 << 7);
    WRITE_REG(PIC_IRQ_EN, irq_en);
    
    // Enable global interrupts
    setup_interrupts();
}

int main(void) {
    // Initialize hardware
    init_motor_pwm();
    init_motor_adc();
    
    // Setup ADC interrupt
    setup_adc_irq();
    
    // Main loop
    while (1) {
        if (adc_ready) {
            adc_ready = 0;
            
            // Read ADC data
            foc_read_currents(&foc_state, 0.165f);
            
            // Run FOC
            foc_loop_hw(&foc_state, &foc_params, VDC);
        }
    }
}
```

---

## Timing Comparison

### Polled ADC Status

```
PWM Center
    ↓
Start ADC (450ns)
    ↓
CPU polls STATUS (busy wait 450ns) ❌
    ↓
Read data
    ↓
Run FOC (1.4µs)
    ↓
Total: ~2µs
```

### ADC IRQ

```
PWM Center
    ↓
Start ADC (450ns)
    ↓
CPU free (450ns) ✅
    ↓
ADC IRQ → adc_isr()
    ↓
Read data
    ↓
Run FOC (1.4µs)
    ↓
Total: ~1.4µs (450ns saved!)
```

---

## Summary

**Question:** Does ADC generate IRQ?  
**Answer:** ✅ **YES!** Motor ADC generates IRQ on conversion complete.

**Current firmware:** Polls STATUS (simpler)  
**Alternative:** Use ADC IRQ (more efficient)  

**For 8 kHz FOC:** Polling is fine (98% CPU free)  
**For >20 kHz FOC:** Use IRQs (better performance)

---

## Quick Reference

| Approach | Setup | CPU Free | Latency | Best For |
|----------|-------|----------|---------|----------|
| Poll STATUS | Simple | 97% | +450ns | 8 kHz FOC ✅ |
| ADC IRQ | Medium | 98.5% | Best | >20 kHz FOC |
| Timer+ADC IRQ | Complex | 99% | Best | High-performance |

**Default (current):** Poll STATUS - simplest, works great! ✅

---

**Created:** 2026-03-07  
**Status:** Informational guide

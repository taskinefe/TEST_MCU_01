# General-Purpose Timer - User Guide

## Overview

The **General-Purpose Timer** provides flexible timing and interrupt generation for system tasks.

**Base Address:** 0x300A_0000 (when integrated)  
**IRQ Line:** 8

---

## Features

✅ **32-bit Counter** - Count up or down  
✅ **Configurable Prescaler** - Divide clock by 1 to 65536  
✅ **One-shot or Periodic Mode** - Single event or repeating  
✅ **Compare Match Interrupt** - Interrupt at specific count  
✅ **Overflow Interrupt** - Interrupt on counter wrap  
✅ **PWM Output** - Optional pulse width modulation  

---

## Register Map

| Offset | Register   | Access | Description |
|--------|------------|--------|-------------|
| 0x00   | CTRL       | RW     | Control register |
| 0x04   | PRESCALER  | RW     | Clock prescaler (16-bit) |
| 0x08   | RELOAD     | RW     | Period/reload value |
| 0x0C   | COMPARE    | RW     | Compare match value |
| 0x10   | COUNTER    | RO     | Current counter value |
| 0x14   | STATUS     | RW     | Status/interrupt flags |

### CTRL Register (0x00)

| Bit | Name | Access | Description |
|-----|------|--------|-------------|
| 31:7 | Reserved | RO | Reserved |
| 6 | IRQ_ON_OVERFLOW | RW | Enable interrupt on overflow |
| 5 | IRQ_ON_COMPARE | RW | Enable interrupt on compare match |
| 4 | PWM_ENABLE | RW | Enable PWM output |
| 3 | COUNT_UP | RW | 1=Count up, 0=Count down |
| 2 | PERIODIC | RW | 1=Periodic, 0=One-shot |
| 1 | START | RW | Start timer (auto-clears) |
| 0 | ENABLE | RW | Global enable |

### PRESCALER Register (0x04)

**Value:** 0 to 65535  
**Effective Clock:** f_clk / (PRESCALER + 1)

Examples @ 40 MHz:
- PRESCALER = 0 → 40 MHz (25ns)
- PRESCALER = 39 → 1 MHz (1µs)
- PRESCALER = 399 → 100 kHz (10µs)
- PRESCALER = 39999 → 1 kHz (1ms)

### RELOAD Register (0x08)

**Count-up mode:** Counter counts from 0 to RELOAD  
**Count-down mode:** Counter counts from RELOAD to 0

### COMPARE Register (0x0C)

**Compare match occurs when:** COUNTER == COMPARE  
**Generates interrupt if:** IRQ_ON_COMPARE = 1

### COUNTER Register (0x10)

**Read-only:** Current counter value

### STATUS Register (0x14)

| Bit | Name | Access | Description |
|-----|------|--------|-------------|
| 31:3 | Reserved | RO | Reserved |
| 2 | RUNNING | RO | Timer is running |
| 1 | OVERFLOW_FLAG | W1C | Overflow occurred |
| 0 | COMPARE_FLAG | W1C | Compare match occurred |

**W1C = Write 1 to Clear**

---

## Usage Examples

### Example 1: 1ms Periodic Interrupt

```c
#define TIMER_BASE 0x300A0000
#define CTRL       0x00
#define PRESCALER  0x04
#define RELOAD     0x08
#define STATUS     0x14

void setup_1ms_timer() {
    // Configure for 1ms @ 40MHz
    // Prescaler = 39 → 1MHz tick
    // Reload = 999 → 1000 ticks = 1ms
    
    USER_writeWord(39, (TIMER_BASE - 0x30000000 + PRESCALER) >> 2);
    USER_writeWord(999, (TIMER_BASE - 0x30000000 + RELOAD) >> 2);
    
    // Enable: periodic, count-up, irq on overflow
    // CTRL = 0x47 = 0b01000111
    // Bit 0: ENABLE=1
    // Bit 1: START=1
    // Bit 2: PERIODIC=1
    // Bit 6: IRQ_ON_OVERFLOW=1
    USER_writeWord(0x47, (TIMER_BASE - 0x30000000 + CTRL) >> 2);
}

void timer_isr() {
    // Clear overflow flag
    USER_writeWord(0x02, (TIMER_BASE - 0x30000000 + STATUS) >> 2);
    
    // Your 1ms periodic code here
    tick_count++;
}
```

### Example 2: One-Shot 10µs Delay

```c
void delay_10us() {
    // Prescaler = 0 → 40MHz (25ns)
    // Reload = 399 → 400 ticks = 10µs
    
    USER_writeWord(0, (TIMER_BASE - 0x30000000 + PRESCALER) >> 2);
    USER_writeWord(399, (TIMER_BASE - 0x30000000 + RELOAD) >> 2);
    
    // One-shot mode, count-up, irq on overflow
    // CTRL = 0x43 = 0b01000011
    USER_writeWord(0x43, (TIMER_BASE - 0x30000000 + CTRL) >> 2);
    
    // Poll for completion
    uint32_t status;
    do {
        status = USER_readWord((TIMER_BASE - 0x30000000 + STATUS) >> 2);
    } while (!(status & 0x02));  // Wait for overflow flag
    
    // Clear flag
    USER_writeWord(0x02, (TIMER_BASE - 0x30000000 + STATUS) >> 2);
}
```

### Example 3: PWM Output (50% duty, 1kHz)

```c
void setup_pwm_1khz() {
    // Prescaler = 39 → 1MHz
    // Reload = 999 → 1kHz
    // Compare = 499 → 50% duty
    
    USER_writeWord(39, (TIMER_BASE - 0x30000000 + PRESCALER) >> 2);
    USER_writeWord(999, (TIMER_BASE - 0x30000000 + RELOAD) >> 2);
    USER_writeWord(499, (TIMER_BASE - 0x30000000 + 0x0C) >> 2);  // COMPARE
    
    // Enable PWM, periodic, count-up
    // CTRL = 0x17 = 0b00010111
    // Bit 0: ENABLE=1
    // Bit 1: START=1
    // Bit 2: PERIODIC=1
    // Bit 3: COUNT_UP=1
    // Bit 4: PWM_ENABLE=1
    USER_writeWord(0x17, (TIMER_BASE - 0x30000000 + CTRL) >> 2);
}
```

### Example 4: Watchdog Timer

```c
void setup_watchdog(uint32_t timeout_ms) {
    // Prescaler for 1kHz tick (1ms)
    USER_writeWord(39999, (TIMER_BASE - 0x30000000 + PRESCALER) >> 2);
    
    // Reload = timeout in ms
    USER_writeWord(timeout_ms, (TIMER_BASE - 0x30000000 + RELOAD) >> 2);
    
    // Count down, one-shot, irq on overflow
    // CTRL = 0x43 = 0b01000011
    USER_writeWord(0x43, (TIMER_BASE - 0x30000000 + CTRL) >> 2);
}

void feed_watchdog() {
    // Restart timer
    USER_writeWord(0x43, (TIMER_BASE - 0x30000000 + CTRL) >> 2);
}

void watchdog_timeout_isr() {
    // Watchdog expired - reset system or take action
    system_reset();
}
```

### Example 5: Event Counter

```c
void setup_event_counter() {
    // No prescaler
    USER_writeWord(0, (TIMER_BASE - 0x30000000 + PRESCALER) >> 2);
    
    // Max count
    USER_writeWord(0xFFFFFFFF, (TIMER_BASE - 0x30000000 + RELOAD) >> 2);
    
    // Just enable and start counting
    USER_writeWord(0x0B, (TIMER_BASE - 0x30000000 + CTRL) >> 2);
}

uint32_t read_event_count() {
    return USER_readWord((TIMER_BASE - 0x30000000 + 0x10) >> 2);  // COUNTER
}
```

---

## Timing Calculations

### Tick Period

```
Tick_period = (PRESCALER + 1) / f_clk

Example @ 40 MHz:
- PRESCALER = 0   → 25ns
- PRESCALER = 9   → 250ns
- PRESCALER = 39  → 1µs
- PRESCALER = 399 → 10µs
```

### Total Period (Periodic Mode)

```
Total_period = Tick_period × (RELOAD + 1)

Example: 1ms period @ 40MHz
- PRESCALER = 39 (1µs tick)
- RELOAD = 999 (1000 ticks)
- Period = 1µs × 1000 = 1ms
```

### Frequency Range

| Prescaler | Reload | Frequency | Period |
|-----------|--------|-----------|--------|
| 0 | 0 | 40 MHz | 25ns |
| 0 | 39 | 1 MHz | 1µs |
| 39 | 999 | 1 kHz | 1ms |
| 39999 | 999 | 1 Hz | 1s |
| 39999 | 59999 | 1/min | 60s |

---

## Interrupt Handling

### Interrupt Sources

1. **Compare Match** - Counter equals COMPARE value
2. **Overflow** - Counter reaches RELOAD (up) or 0 (down)

### ISR Template

```c
void timer_isr() {
    // Read status
    uint32_t status = USER_readWord((TIMER_BASE - 0x30000000 + STATUS) >> 2);
    
    if (status & 0x01) {
        // Compare match
        // Handle compare event
        
        // Clear flag
        USER_writeWord(0x01, (TIMER_BASE - 0x30000000 + STATUS) >> 2);
    }
    
    if (status & 0x02) {
        // Overflow
        // Handle overflow event
        
        // Clear flag
        USER_writeWord(0x02, (TIMER_BASE - 0x30000000 + STATUS) >> 2);
    }
}
```

---

## PWM Mode

### PWM Waveform

**Count-up mode:**
```
PWM_OUT = (COUNTER < COMPARE)

Duty Cycle = COMPARE / RELOAD × 100%
```

**Count-down mode:**
```
PWM_OUT = (COUNTER > COMPARE)

Duty Cycle = (RELOAD - COMPARE) / RELOAD × 100%
```

### PWM Frequency & Resolution

```
PWM_freq = f_tick / (RELOAD + 1)
Resolution = log2(RELOAD + 1) bits

Example @ 1MHz tick:
- RELOAD = 999 → 1kHz PWM, ~10-bit resolution
- RELOAD = 99 → 10kHz PWM, ~7-bit resolution
- RELOAD = 9 → 100kHz PWM, ~3-bit resolution
```

---

## Common Applications

### System Tick (RTOS)

```c
// 1ms system tick for RTOS
setup_1ms_timer();
// Use overflow interrupt for scheduler
```

### Timeout Detection

```c
// Detect if event doesn't occur within 100ms
setup_watchdog(100);
// Feed watchdog when event occurs
// If not fed, interrupt fires
```

### Periodic Sampling

```c
// Sample sensor every 10ms
setup_periodic_timer(10);
// Read sensor in ISR
```

### Delay Generation

```c
// Accurate delays without blocking loops
delay_10us();
delay_ms(100);
```

### Frequency Measurement

```c
// Count events in fixed time window
setup_gate_timer(1000);  // 1 second gate
event_count = read_counter();
frequency = event_count;
```

---

## Performance Specifications

| Parameter | Value |
|-----------|-------|
| Counter Width | 32-bit |
| Prescaler Range | 1 to 65536 |
| Min Period | 25ns @ 40MHz |
| Max Period | ~107s @ 40MHz |
| Resolution | 25ns @ 40MHz |
| Interrupt Latency | <1µs (typical) |

---

## Integration Status

✅ **Module Created** - gp_timer_wb.v  
⏳ **Integration Pending** - Add to user_project  
📚 **Documentation Complete**

---

## Typical System Use Cases

### With Motor Control

```c
// 100µs control loop tick
void setup_motor_control_timer() {
    setup_periodic_timer_us(100);
}

void motor_timer_isr() {
    // Trigger motor control algorithm
    motor_control_update();
}
```

### With Communication

```c
// Timeout for UART reception
void uart_rx_timeout() {
    setup_watchdog(10);  // 10ms timeout
}

void uart_byte_received() {
    feed_watchdog();  // Reset timeout
}
```

### With System Monitoring

```c
// Periodic health check
void setup_health_monitor() {
    setup_periodic_timer_ms(1000);  // Every 1 second
}

void health_timer_isr() {
    check_temperature();
    check_voltage();
    check_current();
}
```

---

**Created:** 2026-03-05  
**Status:** ✅ Design Complete, Ready to Integrate

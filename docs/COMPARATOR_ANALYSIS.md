# Comparator IP Analysis for High Current Detection

## Executive Summary

✅ **YES, IT IS POSSIBLE!**

We have **analog comparator IPs available** that can be used for high-current detection (overcurrent protection) in the motor control system.

---

## Available Comparator IPs

### 1. EF_ACMP_DI (Analog Comparator with Digital Interface)

**Location:** `/nc/ip/EF_ACMP_DI/v1.0.1/`  
**Type:** Analog comparator with digital control  
**Status:** ✅ **VERIFIED IP - Ready to use**  
**Bus:** Wishbone  

**Features:**
- Analog voltage comparator
- Digital interface for configuration
- Interrupt generation on threshold crossing
- Configurable input selection (sela, selb)
- Fast response time (analog speed)

**Inputs:**
- `vo` - Comparator output from analog cell
- `di_sela` - Input A select (digital)
- `di_selb` - Input B select (digital)

**Outputs:**
- `di_vo` - Comparator digital output
- `irq` - Interrupt on threshold crossing

---

## High Current Detection Architecture

### Concept

```
Motor Phase Current
    ↓
Current Sense Amplifier (INA240, G=20)
    ↓ (0-3.3V, centered at 1.65V)
Analog Comparator
    ↓
Compare with Threshold (e.g., 2.8V = 7A)
    ↓
If Current > Threshold → IRQ
    ↓
Firmware Shuts Down PWM
```

---

## Implementation Options

### Option 1: Use ADC for Current Monitoring (Current Approach)

**What we have now:**
- 3-channel simultaneous ADC
- 12-bit resolution
- Sample at 8 kHz (125µs period)
- Software checks current limits

**Pros:**
- ✅ Already integrated
- ✅ Precise measurement
- ✅ Can log data

**Cons:**
- ❌ Slow response (~125µs until next sample)
- ❌ Software overhead
- ❌ Can't catch fast transients

**Best for:** Steady-state monitoring, not fast protection

---

### Option 2: Add Analog Comparator (Hardware Protection) ⭐

**New addition:**
- Analog comparator (EF_ACMP_DI)
- Continuous comparison (no sampling delay)
- Hardware IRQ on threshold crossing
- Fast shutdown (<1µs)

**Pros:**
- ✅ Fast response (< 1µs)
- ✅ Hardware protection
- ✅ Catches fast transients
- ✅ Independent of software

**Cons:**
- Requires additional IP integration
- Needs threshold configuration

**Best for:** Fast overcurrent protection (hardware safety)

---

### Option 3: Hybrid Approach (Recommended!) 🏆

**Combine both:**
- **Comparator:** Fast hardware protection (e.g., > 10A)
- **ADC:** Precise monitoring and control (normal operation)

**Architecture:**

```
Current Sensor → Split signal
    ├─→ ADC (for FOC control)
    │   - 8 kHz sampling
    │   - FOC current control
    │   - Data logging
    │
    └─→ Comparator (for protection)
        - Continuous monitoring
        - Fast threshold detection
        - Emergency shutdown
```

**Benefits:**
- ✅ **Best of both worlds**
- ✅ Fast hardware protection (comparator)
- ✅ Precise control (ADC)
- ✅ Safety + Performance

---

## Comparator Configuration for Overcurrent Detection

### Hardware Setup

**Current Sensing:**
```
Motor Phase → 0.01Ω Shunt → INA240 (G=20) → 0-3.3V
                                            ├→ ADC (control)
                                            └→ Comparator (protection)
```

**Voltage to Current Mapping:**
```
V_sense = (I_motor × 0.01Ω) × 20 + 1.65V

Examples:
  0A   → 1.65V (center)
 +5A   → 2.65V
 +7A   → 2.80V
+10A   → 3.65V (near rail)
-5A   → 0.65V
```

### Comparator Threshold Settings

**For Overcurrent Protection:**

| Threshold Voltage | Current Limit | Use Case |
|-------------------|---------------|----------|
| 2.65V | ±5A | Rated current limit |
| 2.80V | ±7A | Warning level |
| 3.00V | ±8.5A | **Trip level (recommended)** ⭐ |
| 3.30V | ±10A | Absolute maximum |

**Recommended:** Set comparator at **2.80V** (7A) for fast protection

---

## Register Map (EF_ACMP_DI)

| Offset | Register | Access | Description |
|--------|----------|--------|-------------|
| 0x00 | SEL | RW | Input selection (sela, selb) |
| 0x0F00 | ICR | W | Interrupt clear register |
| 0x0F04 | RIS | RO | Raw interrupt status |
| 0x0F08 | IM | RW | Interrupt mask |
| 0x0F0C | MIS | RO | Masked interrupt status |

**SEL Register:**
- Bit 0: sela (input A select)
- Bit 1: selb (input B select)

**Interrupt:**
- Triggered when `vo` (comparator output) goes high
- Indicates threshold exceeded

---

## Firmware Integration

### Example 1: Basic Comparator Setup

```c
#define COMPARATOR_BASE 0x300D0000

#define COMP_SEL    (COMPARATOR_BASE + 0x00)
#define COMP_ICR    (COMPARATOR_BASE + 0x0F00)
#define COMP_RIS    (COMPARATOR_BASE + 0x0F04)
#define COMP_IM     (COMPARATOR_BASE + 0x0F08)
#define COMP_MIS    (COMPARATOR_BASE + 0x0F0C)

void init_overcurrent_protection(void) {
    // Configure input selection
    WRITE_REG(COMP_SEL, 0x00);  // Select inputs
    
    // Enable interrupt
    WRITE_REG(COMP_IM, 0x01);  // Enable IRQ
    
    // Clear any pending interrupts
    WRITE_REG(COMP_ICR, 0x01);
}
```

### Example 2: Overcurrent ISR

```c
volatile uint8_t overcurrent_fault = 0;

void comparator_isr(void) {
    // Read interrupt status
    uint32_t mis = READ_REG(COMP_MIS);
    
    if (mis & 0x01) {
        // Overcurrent detected!
        overcurrent_fault = 1;
        
        // IMMEDIATE SHUTDOWN
        WRITE_REG(MOTOR_PWM_CTRL, 0);  // Disable all PWM
        
        // Clear interrupt
        WRITE_REG(COMP_ICR, 0x01);
    }
}
```

### Example 3: Fault Handling in FOC Loop

```c
void foc_loop_with_protection(void) {
    // Check for overcurrent fault
    if (overcurrent_fault) {
        // Fault condition - stay shutdown
        motor_state = FAULT;
        return;
    }
    
    // Normal FOC operation
    foc_read_currents(&foc_state, 0.165f);
    
    // Software current limit (slower, for control)
    if (fabs(foc_state.ia) > 6.0f || 
        fabs(foc_state.ib) > 6.0f || 
        fabs(foc_state.ic) > 6.0f) {
        // Approaching limit - reduce voltage
        foc_params.vq *= 0.9f;
    }
    
    // Continue FOC
    foc_loop_hw(&foc_state, &foc_params, VDC);
}
```

---

## Multi-Phase Current Protection

### Option A: Single Comparator (One Phase)

**Simplest approach:**
- Monitor Phase A only
- Assumes balanced 3-phase

**Pros:**
- Simple
- One comparator

**Cons:**
- Doesn't catch unbalanced faults

---

### Option B: Three Comparators (All Phases) ⭐

**Robust approach:**
- One comparator per phase
- OR the outputs together
- Any phase triggers shutdown

**Implementation:**

```
Phase A sense → Comparator A ─┐
Phase B sense → Comparator B ─┤ OR → Overcurrent IRQ
Phase C sense → Comparator C ─┘
```

**Firmware:**

```c
void init_3phase_protection(void) {
    // Configure 3 comparators (if available)
    // Or use 1 comparator + analog OR gate
    
    // Base addresses
    #define COMP_A_BASE 0x300D0000
    #define COMP_B_BASE 0x300D1000
    #define COMP_C_BASE 0x300D2000
    
    // Enable all
    init_comparator(COMP_A_BASE);
    init_comparator(COMP_B_BASE);
    init_comparator(COMP_C_BASE);
}
```

---

## Response Time Comparison

| Method | Detection Time | Shutdown Time | Total Response |
|--------|----------------|---------------|----------------|
| **ADC Sampling** | 125µs (next sample) | 1µs | **~126µs** |
| **ADC + Software** | 125µs + 5µs | 1µs | **~131µs** |
| **Comparator** | <100ns | 1µs | **~1.1µs** ⭐ |

**Improvement:** 120× faster with comparator! 🚀

---

## Threshold Voltage Generation

### Option 1: External Resistor Divider

**Simple:**
```
3.3V ───┬─── To comparator threshold
        R1 (e.g., 1kΩ)
        │
        ├─── 2.80V (7A threshold)
        │
        R2 (e.g., 680Ω)
        │
       GND
```

**Calculation:**
```
V_threshold = 3.3V × R2 / (R1 + R2)
For 2.80V: R2 = 680Ω, R1 = 1.2kΩ
```

### Option 2: DAC Output

**Programmable:**
- Use internal DAC (if available)
- Software-configurable threshold
- Can adjust based on motor/load

---

## Integration Steps

### If You Decide to Implement:

1. **Add Comparator IP** to user_project
2. **Connect analog inputs** from current sensors
3. **Set threshold** (external or programmable)
4. **Wire IRQ** to PIC
5. **Create ISR** for fast shutdown
6. **Test** with overcurrent injection

**Estimated time:** 2-3 hours

---

## Recommendations

### For Your Motor Control System:

**Current Status:**
- ✅ ADC monitoring (8 kHz)
- ✅ Software limits possible

**Add for Production:**
- ⭐ **Hardware comparator** for fast protection
- ⭐ **Hybrid approach** (ADC + Comparator)

**Priority:**
- **High** if targeting production/safety-critical
- **Medium** if prototype/testing only

---

## Alternative: Use Existing Hardware Fault Pin

Many motor drivers have **hardware fault inputs**:
- nFAULT pin on gate drivers
- Can connect comparator output directly
- Hardware shutdown (even faster)

**Example:**
```
Comparator output → nFAULT → Gate Driver
                              ↓
                         Immediate PWM shutdown
                         (hardware, 0 delay)
```

---

## Cost-Benefit Analysis

### Adding Comparator

**Costs:**
- 2-3 hours integration
- Small area overhead
- Additional testing

**Benefits:**
- 120× faster protection
- Hardware safety
- Catches fast transients
- Independent of software
- Production-grade safety

**Verdict:** ✅ **Worth it for production designs**

---

## Summary

### Question: Is comparator-based overcurrent detection possible?

**Answer:** ✅ **YES, ABSOLUTELY POSSIBLE!**

### Available Resources:

1. ✅ **EF_ACMP_DI** - Analog comparator IP ready to use
2. ✅ **Wishbone interface** - Easy integration
3. ✅ **Interrupt generation** - Fast response
4. ✅ **Documentation** - This analysis complete

### Recommended Approach:

**Hybrid Protection System:**
- **Comparator:** Fast hardware trip (>7A → <1µs shutdown)
- **ADC:** Precise control (FOC current regulation)
- **Software:** Monitoring, logging, fault handling

### Implementation:

**Status:** ⏸️ Waiting for your command  
**Readiness:** ✅ Ready to implement  
**Estimated time:** 2-3 hours  
**Impact:** High (production-grade safety)

---

## Next Steps (When You're Ready)

1. **Confirm requirement** - Do you want overcurrent protection?
2. **Choose approach:**
   - Single-phase or 3-phase?
   - Comparator only or hybrid?
3. **Set threshold** - What current limit? (7A? 10A?)
4. **I'll implement:**
   - IP integration
   - Wishbone wrapper
   - IRQ handling
   - Firmware example
   - Documentation

---

**Analysis Complete!** ✅  
**Ready to implement when you give the command!** 🚀

---

**Created:** 2026-03-07  
**Status:** Analysis complete, awaiting implementation decision

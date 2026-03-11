# IPs Used in Motor Control Project

## Complete List of IP Cores

This document lists all IP cores used in the Caravel motor control user project.

---

## 1. NativeChips Verified IPs (From IP Library)

### 1.1 CF_SPI - SPI Master Controller ✅

**Version:** v2.0.1  
**Location:** `/nc/ip/CF_SPI/v2.0.1/`  
**Linked:** Yes (`ip/CF_SPI/`)

**Instances in Project:** 2×
- `spi0_inst` - Peripheral #0 at 0x3000_0000
- `spi1_inst` - Peripheral #2 at 0x3002_0000

**Purpose:** 
- SPI master interface for external peripherals
- Communication with external sensors/actuators
- Example: External SPI ADC, EEPROM, or sensors

**Module:** `CF_SPI_WB`

**Key Features:**
- Configurable clock polarity/phase
- FIFO buffers
- Full-duplex operation
- Interrupt support

**Ports Used:**
- SPI0: `spi0_sclk`, `spi0_mosi`, `spi0_miso`, `spi0_csb`
- SPI1: `spi1_sclk`, `spi1_mosi`, `spi1_miso`, `spi1_csb`

---

### 1.2 CF_I2C - I2C Controller ✅

**Version:** v2.0.0  
**Location:** `/nc/ip/CF_I2C/v2.0.0/`  
**Linked:** Yes (`ip/CF_I2C/`)

**Instances in Project:** 1×
- `i2c0_inst` - Peripheral #1 at 0x3001_0000

**Purpose:**
- I2C master interface
- Communication with I2C sensors
- Example: IMU sensors, EEPROM, RTC

**Module:** `CF_I2C_WB`

**Key Features:**
- Standard (100kHz) and Fast (400kHz) modes
- Multi-master arbitration
- Command/Read/Write FIFOs (16 deep)
- Interrupt support

**Ports Used:**
- `i2c0_scl_i`, `i2c0_scl_o`, `i2c0_scl_oen`
- `i2c0_sda_i`, `i2c0_sda_o`, `i2c0_sda_oen`

---

### 1.3 CF_TMR32 - 32-bit Timer with PWM ✅

**Version:** v2.1.0-nc  
**Location:** `/nc/ip/CF_TMR32/v2.1.0-nc/`  
**Linked:** Yes (`ip/CF_TMR32/`)

**Instances in Project:** 2×
- `pwm0_inst` - Peripheral #3 at 0x3003_0000
- `pwm1_inst` - Peripheral #4 at 0x3004_0000

**Purpose:**
- Generate basic PWM signals
- Simple duty cycle control
- Can be used for auxiliary motor control

**Module:** `CF_TMR32_WB`

**Key Features:**
- 32-bit counter
- Configurable PWM period and duty cycle
- Interrupt on overflow
- Fault input support

**Ports Used:**
- PWM0: `pwm0_out`
- PWM1: `pwm1_out`

**Note:** These are separate from the advanced motor PWM module.

---

### 1.4 CF_SRAM_1024x32 - 4KB SRAM ✅

**Version:** v1.2.0  
**Location:** `/nc/ip/CF_SRAM_1024x32/v1.2.0/`  
**Linked:** Yes (`ip/CF_SRAM_1024x32/`)

**Instance in Project:** 1×
- `sram_inst` - Peripheral #5 at 0x3005_0000

**Purpose:**
- Data storage for FOC calculations
- Buffer for sensor data
- Stack/heap memory
- Temporary storage

**Module:** `CF_SRAM_1024x32_wb_wrapper`

**Key Features:**
- Size: 1024 words × 32 bits = 4 KB
- Single-port synchronous
- Single-cycle access
- Wishbone interface

**Memory Range:**
- Base: 0x3005_0000
- Size: 4 KB (0x1000 bytes)
- End: 0x3005_0FFF

---

### 1.5 CF_IP_UTIL - IP Utilities ✅

**Version:** Latest  
**Location:** `/nc/ip/CF_IP_UTIL/`  
**Linked:** Yes (`ip/CF_IP_UTIL/`)

**Purpose:**
- Common utility modules for IP integration
- Bus wrappers and interface helpers

---

## 2. Analog IPs (From NativeChips Library)

### 2.1 sky130_ef_ip__adc3v_12bit - 12-bit ADC

**Location:** `/nc/ip/sky130_ef_ip__adc3v_12bit/`  
**Linked:** Yes (`ip/sky130_ef_ip__adc3v_12bit/`)

**Instances in Project:** 
- Used as base for `adc_wb_wrapper` (Peripheral #6)
- Used as base for `motor_adc_3ch` (Peripheral #7)

**Purpose:**
- Analog-to-digital conversion
- Current sensing for motor control
- Voltage measurement

**Type:** Analog IP (SAR ADC)

**Key Features:**
- 12-bit resolution
- Successive Approximation Register (SAR) architecture
- Analog inputs
- Comparator-based conversion

**Note:** Modified for digital interface in this project.

---

## 3. Custom Motor Control Modules (Created for This Project)

### 3.1 Motor PWM Module

**File:** `verilog/rtl/motor_pwm.v`  
**Wrapper:** `verilog/rtl/motor_pwm_wb.v`

**Purpose:**
- Generate 3-phase PWM signals for motor control
- Advanced motor drive with dead-time insertion
- Synchronization with ADC sampling

**Key Features:**
- 3-phase output (6 signals: UH, UL, VH, VL, WH, WL)
- Dead-time insertion (prevents shoot-through)
- Center-aligned PWM
- Configurable frequency
- Synchronization trigger for ADC

**Not Used Directly** - Integrated into SVPWM module

---

### 3.2 SVPWM Module

**File:** `verilog/rtl/svpwm.v`  
**Wrapper:** `verilog/rtl/svpwm_wb.v`  
**Combined:** `verilog/rtl/motor_pwm_svpwm_wb.v` (Peripheral #8)

**Instance in Project:** 1×
- Peripheral #8 at 0x3008_0000

**Purpose:**
- Space Vector PWM for motor control
- Efficient voltage utilization
- Reduced harmonic distortion
- Field-Oriented Control (FOC) support

**Key Features:**
- Clarke & Park transformations
- SVPWM algorithm
- 3-phase PWM generation with dead-time
- 12-bit resolution
- Configurable switching frequency

**Outputs:**
- 6× PWM signals (UH, UL, VH, VL, WH, WL)
- ADC trigger for synchronized sampling

---

### 3.3 ADC Wrapper

**File:** `verilog/rtl/sky130_ef_ip__adc3v_12bit_fixed.v`  
**Wrapper:** `verilog/rtl/adc_wb_wrapper.v` (defined inline in user_project.v)

**Instance in Project:** 1×
- `adc_inst` - Peripheral #6 at 0x3006_0000

**Purpose:**
- General-purpose ADC for auxiliary measurements
- Single-channel analog input
- Voltage sensing

**Key Features:**
- 12-bit resolution
- SAR algorithm in digital logic
- Wishbone interface
- Interrupt on conversion complete

**Inputs:**
- `adc_vin` - Analog input voltage
- `adc_vrefh` - Reference high
- `adc_vrefl` - Reference low

---

### 3.4 Motor 3-Channel ADC

**File:** `verilog/rtl/motor_adc_3ch.v`  
**Wrapper:** `verilog/rtl/motor_adc_3ch_wb.v`

**Instance in Project:** 1×
- `motor_adc_inst` - Peripheral #7 at 0x3007_0000

**Purpose:**
- 3-phase current sensing for motor control
- Synchronized with PWM for FOC
- Phase current measurement

**Key Features:**
- 3× independent 12-bit ADC channels
- External trigger input (from PWM)
- Sequential or simultaneous conversion
- Interrupt support

**Inputs:**
- `motor_adc_vin_a` - Phase A current
- `motor_adc_vin_b` - Phase B current
- `motor_adc_vin_c` - Phase C current
- `ext_trigger` - Trigger from PWM/SVPWM

**Key Capability:**
- Synchronized sampling with PWM center-point
- Critical for accurate FOC current control

---

### 3.5 Overcurrent Protection Module

**File:** `verilog/rtl/overcurrent_protection.v`  
**Wrapper:** `verilog/rtl/overcurrent_protection_wb.v`

**Instance in Project:** 1×
- `ocp_inst` - Peripheral #9 at 0x3009_0000

**Purpose:**
- Hardware overcurrent protection
- Safety shutdown for motor
- Fault detection and handling

**Key Features:**
- 3× analog comparators (one per phase)
- DAC for programmable threshold
- Individual phase fault detection
- Combined fault output (pwm_shutdown)
- Fault status registers

**Inputs:**
- `ocp_phase_a_current` - Phase A current (analog)
- `ocp_phase_b_current` - Phase B current (analog)
- `ocp_phase_c_current` - Phase C current (analog)

**Outputs:**
- `ocp_dac_threshold` - DAC threshold (analog)
- `ocp_pwm_shutdown` - Emergency shutdown signal

**Protection Logic:**
```
If any phase current > threshold:
    → Set fault flag
    → Assert pwm_shutdown
    → Disable PWM outputs
    → Trigger interrupt
```

---

### 3.6 CORDIC Module

**File:** `verilog/rtl/cordic.v`  
**Wrapper:** `verilog/rtl/cordic_wb.v`

**Status:** Created but NOT instantiated in user_project

**Purpose:**
- COordinate Rotation DIgital Computer
- Fast trigonometric calculations
- Useful for advanced FOC transformations

**Key Features:**
- Sine/Cosine calculation
- Vector rotation
- Magnitude/Phase calculation
- Pipelined architecture

**Note:** Available for future integration if needed.

---

### 3.7 FOC Transforms Module

**File:** `verilog/rtl/foc_transforms.v`  
**Wrapper:** `verilog/rtl/foc_transforms_wb.v`

**Status:** Created but NOT instantiated in user_project

**Purpose:**
- Field-Oriented Control transformations
- Clarke (ABC → αβ) transformation
- Park (αβ → dq) transformation
- Inverse transformations

**Key Features:**
- Hardware-accelerated transforms
- Fixed-point arithmetic
- Low latency

**Note:** SVPWM module includes these internally.

---

### 3.8 General Purpose Timer

**File:** `verilog/rtl/gp_timer_wb.v`

**Status:** Created but NOT instantiated in user_project

**Purpose:**
- Additional timing functions
- Event counting
- Timestamping

**Note:** Available for future use.

---

## 4. Infrastructure Modules

### 4.1 Wishbone Bus Splitter

**File:** `verilog/rtl/wishbone_bus_splitter.v`

**Instance:** 1× in `user_project.v`

**Purpose:**
- Decode Wishbone addresses
- Route transactions to peripherals
- Combine responses from peripherals

**Configuration:**
- `NUM_PERIPHERALS = 10`
- `ADDR_SEL_LOW_BIT = 16` (64KB windows)

**Address Mapping:**
```
Peripheral #0 (SPI0):     0x3000_0000
Peripheral #1 (I2C0):     0x3001_0000
Peripheral #2 (SPI1):     0x3002_0000
Peripheral #3 (PWM0):     0x3003_0000
Peripheral #4 (PWM1):     0x3004_0000
Peripheral #5 (SRAM):     0x3005_0000
Peripheral #6 (ADC):      0x3006_0000
Peripheral #7 (Motor ADC):0x3007_0000
Peripheral #8 (SVPWM):    0x3008_0000
Peripheral #9 (OCP):      0x3009_0000
```

---

### 4.2 Wishbone Programmable Interrupt Controller (PIC)

**File:** `verilog/rtl/WB_PIC.v`

**Status:** Available but NOT instantiated

**Purpose:**
- Manage interrupts from multiple peripherals
- Programmable priority
- Interrupt masking

**Note:** User IRQs currently wired directly. PIC available if needed.

---

## 5. Wrapper Modules

### 5.1 user_project.v

**File:** `verilog/rtl/user_project.v`

**Purpose:**
- Top-level integration module
- Instantiates all peripherals
- Connects to Wishbone bus
- Maps IOs to pads

**Contains:**
- Wishbone bus splitter
- All peripheral instances
- Interrupt routing
- IO signal routing

---

### 5.2 user_project_wrapper.v

**File:** `verilog/rtl/user_project_wrapper.v`

**Purpose:**
- Caravel interface wrapper
- Connects user_project to Caravel harness
- Maps IO pads to signals

---

## Summary Tables

### IP Cores from NativeChips Library

| IP | Version | Instances | Verified | Purpose |
|----|---------|-----------|----------|---------|
| **CF_SPI** | v2.0.1 | 2× | ✅ | SPI master communication |
| **CF_I2C** | v2.0.0 | 1× | ✅ | I2C master communication |
| **CF_TMR32** | v2.1.0-nc | 2× | ✅ | Timer/PWM generation |
| **CF_SRAM_1024x32** | v1.2.0 | 1× | ✅ | 4KB memory |
| **CF_IP_UTIL** | Latest | - | ✅ | IP utilities |
| **sky130_ef_ip__adc3v_12bit** | Latest | Base | - | 12-bit ADC (analog) |

---

### Custom Motor Control Modules

| Module | Status | Purpose |
|--------|--------|---------|
| **motor_pwm_svpwm_wb** | ✅ Active (P#8) | Space Vector PWM |
| **motor_adc_3ch_wb** | ✅ Active (P#7) | 3-phase current sensing |
| **overcurrent_protection_wb** | ✅ Active (P#9) | Safety protection |
| **adc_wb_wrapper** | ✅ Active (P#6) | General ADC |
| **cordic_wb** | Created, not used | Trigonometry |
| **foc_transforms_wb** | Created, not used | FOC transforms |
| **gp_timer_wb** | Created, not used | General timer |

---

### Infrastructure Modules

| Module | Purpose |
|--------|---------|
| **wishbone_bus_splitter** | Address decode & routing |
| **WB_PIC** | Interrupt controller (available) |
| **user_project** | Top-level integration |
| **user_project_wrapper** | Caravel interface |

---

## Peripheral Address Map

| Peripheral # | Name | Module | Base Address | Size | IRQ |
|--------------|------|--------|--------------|------|-----|
| 0 | SPI0 | CF_SPI_WB | 0x3000_0000 | 64 KB | Yes |
| 1 | I2C0 | CF_I2C_WB | 0x3001_0000 | 64 KB | Yes |
| 2 | SPI1 | CF_SPI_WB | 0x3002_0000 | 64 KB | Yes |
| 3 | PWM0 | CF_TMR32_WB | 0x3003_0000 | 64 KB | Yes |
| 4 | PWM1 | CF_TMR32_WB | 0x3004_0000 | 64 KB | Yes |
| 5 | SRAM | CF_SRAM_1024x32 | 0x3005_0000 | 4 KB | No |
| 6 | ADC | adc_wb_wrapper | 0x3006_0000 | 64 KB | Yes |
| 7 | Motor ADC | motor_adc_3ch_wb | 0x3007_0000 | 64 KB | Yes |
| 8 | SVPWM | motor_pwm_svpwm_wb | 0x3008_0000 | 64 KB | Yes |
| 9 | OCP | overcurrent_protection_wb | 0x3009_0000 | 64 KB | Yes |

**Total Peripherals:** 10  
**Total IRQ Lines:** 9 (SRAM has no IRQ)

---

## IO Pin Usage

### Communication IPs

**SPI0 (4 pins):**
- spi0_sclk
- spi0_mosi
- spi0_miso
- spi0_csb

**I2C0 (2 pins):**
- i2c0_scl (bidirectional)
- i2c0_sda (bidirectional)

**SPI1 (4 pins):**
- spi1_sclk
- spi1_mosi
- spi1_miso
- spi1_csb

---

### PWM Outputs

**Basic PWM (2 pins):**
- pwm0_out
- pwm1_out

**Motor SVPWM (6 pins + 1 trigger):**
- svpwm_uh, svpwm_ul
- svpwm_vh, svpwm_vl
- svpwm_wh, svpwm_wl
- motor_adc_trigger

---

### Analog Inputs

**General ADC (3 pins):**
- adc_vin
- adc_vrefh
- adc_vrefl
- adc_comp_out (output)

**Motor ADC (3 pins):**
- motor_adc_vin_a
- motor_adc_vin_b
- motor_adc_vin_c

**Overcurrent Protection (4 pins):**
- ocp_phase_a_current (input)
- ocp_phase_b_current (input)
- ocp_phase_c_current (input)
- ocp_dac_threshold (output, analog)
- ocp_pwm_shutdown (output, digital)

---

## Total Resource Count

**IP Cores Used:** 6 (from library)  
**Custom Modules:** 9 (created for project)  
**Active Peripherals:** 10  
**IO Pins:** ~30 (digital + analog)  
**Memory:** 4 KB SRAM  
**IRQ Lines:** 9

---

## Integration Method

All IPs are integrated using the **ipm_linker** tool:

**Configuration File:** `ip/link_IPs.json`

```json
{
  "ips": [
    {"name": "CF_SPI", "version": "v2.0.1"},
    {"name": "CF_I2C", "version": "v2.0.0"},
    {"name": "CF_TMR32", "version": "v2.1.0-nc"}
  ]
}
```

**Linked IPs Location:** `ip/` directory

---

## Key Capabilities Enabled

### By NativeChips IPs:

1. **Communication:** SPI and I2C for external sensors/peripherals
2. **Storage:** 4 KB SRAM for data buffering
3. **Timing:** Basic PWM generation

### By Custom Modules:

1. **Motor Control:** 3-phase SVPWM with FOC support
2. **Current Sensing:** 3-channel synchronized ADC
3. **Safety:** Hardware overcurrent protection
4. **Measurement:** General-purpose ADC

---

## Documentation References

**Detailed Module Documentation:**
- Motor PWM: `docs/MOTOR_PWM_GUIDE.md`
- SVPWM: `docs/SVPWM_GUIDE.md`
- Motor ADC: `docs/MOTOR_ADC_3CH_GUIDE.md`
- SRAM: `docs/SRAM_GUIDE.md`
- Overcurrent Protection: `docs/OVERCURRENT_PROTECTION_IMPLEMENTATION.md`
- CORDIC: `docs/CORDIC_GUIDE.md`
- FOC Transforms: `docs/FOC_TRANSFORMS_GUIDE.md`

**Integration Documentation:**
- Register Map: `docs/register_map.md`
- Pad Map: `docs/pad_map.md`
- Integration Notes: `docs/integration_notes.md`

---

**Created:** 2026-03-11  
**Status:** All IPs documented and integrated  
**Project:** Caravel Motor Control User Project

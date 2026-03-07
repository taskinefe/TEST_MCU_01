# Integration Notes

This document provides technical details for integrating and using the Caravel multi-peripheral user project.

## Table of Contents
1. [Clock and Reset Architecture](#clock-and-reset-architecture)
2. [IRQ Mapping](#irq-mapping)
3. [Wishbone Bus Timing](#wishbone-bus-timing)
4. [Address Decoding](#address-decoding)
5. [Simulation and Testing](#simulation-and-testing)
6. [Firmware Integration](#firmware-integration)

---

## Clock and Reset Architecture

### Clock Domain
This design uses a **single clock domain** for simplicity and to avoid CDC (Clock Domain Crossing) issues.

- **Clock Source:** `wb_clk_i` from Caravel
- **Frequency:** Typically 10-25 MHz (configurable in Caravel)
- **All peripherals operate on `wb_clk_i`**

### Reset Strategy
- **Reset Type:** Synchronous, active-high
- **Reset Signal:** `wb_rst_i` from Caravel
- **Reset Assertion:** All registers reset to defined values
- **Reset Release:** Synchronous to `wb_clk_i`

### Clock Distribution
```
wb_clk_i (from Caravel)
    |
    +-- user_project
          |
          +-- wishbone_bus_splitter
          +-- CF_SPI_WB (SPI0)
          +-- CF_I2C_WB (I2C0)
          +-- CF_SPI_WB (SPI1)
          +-- CF_TMR32_WB (PWM0)
          +-- CF_TMR32_WB (PWM1)
          +-- WB_PIC (Interrupt Controller)
```

**Note:** No clock gating is implemented. All peripherals are always clocked.

---

## IRQ Mapping

### Interrupt Architecture
```
Peripheral IRQs → WB_PIC (Interrupt Controller) → user_irq[0] → Caravel
```

### IRQ Source Mapping

| IRQ Line | Peripheral | Event Source |
|----------|------------|--------------|
| 0        | SPI0       | TX/RX FIFO threshold, transfer complete |
| 1        | I2C0       | Transfer complete, arbitration lost |
| 2        | SPI1       | TX/RX FIFO threshold, transfer complete |
| 3        | PWM0       | Timer overflow, compare match |
| 4        | PWM1       | Timer overflow, compare match |
| 5-15     | Reserved   | Future expansion |

### Interrupt Controller (WB_PIC)
- **Base Address:** `0x3005_0000`
- **Features:**
  - 16 IRQ sources (5 currently used)
  - Programmable priority (4 levels)
  - Per-IRQ enable masks
  - Global interrupt enable
  - Edge/Level triggering configurable
- **Output:** Single `user_irq[0]` to Caravel

### IRQ Handling Flow
1. Peripheral generates interrupt
2. IRQ line asserted to WB_PIC
3. WB_PIC checks enable mask and priority
4. If enabled and highest priority, assert `user_irq[0]`
5. Firmware reads WB_PIC pending register
6. Firmware services interrupt
7. Firmware writes to IC register (W1C) to clear

### Firmware IRQ Configuration Example
```c
// Enable SPI0 and I2C0 interrupts
reg_write(PIC_BASE + IRQ_ENABLE, (1 << 0) | (1 << 1));

// Set global enable
reg_write(PIC_BASE + GLOBAL_ENABLE, 1);

// In ISR: Read pending
uint32_t pending = reg_read(PIC_BASE + IRQ_PENDING);

// Clear IRQ 0
reg_write(PIC_BASE + IRQ_CLEAR, (1 << 0));
```

---

## Wishbone Bus Timing

### Bus Protocol
- **Standard:** Wishbone B4 Classic
- **Data Width:** 32 bits
- **Address Width:** 32 bits
- **Byte Enable:** 4 bits (`wbs_sel_i[3:0]`)

### Timing Diagram
```
Clock    : __|‾‾|__|‾‾|__|‾‾|__|‾‾|__|‾‾|__
cyc_i    : __|‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾|_______
stb_i    : __|‾‾‾‾‾‾‾‾|___|‾‾‾‾‾‾‾‾|______
we_i     : __|‾‾‾‾‾‾‾‾|___________|_______
adr_i    : __<  A1   ><    A2    >________
dat_i    : __<  D1   >____________________
dat_o    : _______________<  D2   >________
ack_o    : ______|‾‾|________|‾‾|__________
         ^       ^           ^
         |       |           |
       Write   ACK        Read ACK
```

### Timing Requirements
1. **Setup Time:** Address, data, and control signals must be stable before rising clock edge
2. **ACK Response:** Asserted for **exactly one cycle** after valid request
3. **Read Latency:** 1 cycle (data available same cycle as ACK)
4. **Write Latency:** 1 cycle (ACK same cycle as write strobe)

### Bus Handshake Rules
1. **Valid Transaction:** `cyc_i` AND `stb_i` both high
2. **Write:** `we_i` = 1 during valid transaction
3. **Read:** `we_i` = 0 during valid transaction
4. **Byte Lanes:** `sel_i[3:0]` enables individual bytes for writes
5. **Termination:** Slave asserts `ack_o` for one cycle

---

## Address Decoding

### Address Map Structure
The user project address space starts at `0x3000_0000` with 64 KB windows for each peripheral.

### Decode Logic
Address bits `[18:16]` select the peripheral (for 6 peripherals):

```
wbs_adr_i[18:16]  Peripheral  Base Address
----------------  ----------  ------------
3'b000           SPI0         0x3000_0000
3'b001           I2C0         0x3001_0000
3'b010           SPI1         0x3002_0000
3'b011           PWM0         0x3003_0000
3'b100           PWM1         0x3004_0000
3'b101           WB_PIC       0x3005_0000
3'b110           Invalid      -
3'b111           Invalid      -
```

### Wishbone Bus Splitter Configuration
```verilog
wishbone_bus_splitter #(
    .NUM_PERIPHERALS(6),
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32),
    .SEL_WIDTH(4),
    .ADDR_SEL_LOW_BIT(16)  // Decode bits [18:16]
) wb_splitter (
    .clk_i(wb_clk_i),
    .rst_i(wb_rst_i),
    .m_wb_adr_i(wbs_adr_i),
    // ... peripheral connections
);
```

### Invalid Address Handling
- **Invalid Reads:** Return `0xDEADBEEF`
- **Invalid Writes:** ACKed but discarded
- **Error Signal:** `wb_err_o` asserted for out-of-range

---

## Simulation and Testing

### Cocotb Test Environment
Location: `verilog/dv/cocotb/`

#### Test Structure
```
cocotb/
├── spi0_test/
│   ├── spi0_test.py
│   ├── spi0_test.c
│   └── Makefile
├── i2c0_test/
│   ├── i2c0_test.py
│   ├── i2c0_test.c
│   └── Makefile
├── spi1_test/
│   ├── spi1_test.py
│   ├── spi1_test.c
│   └── Makefile
├── pwm_test/
│   ├── pwm_test.py
│   ├── pwm_test.c
│   └── Makefile
├── system_test/
│   ├── system_test.py
│   ├── system_test.c
│   └── Makefile
├── cocotb_tests.py
└── design_info.yaml
```

#### Running Tests
```bash
cd verilog/dv/cocotb
python cocotb_tests.py -test spi0_test
python cocotb_tests.py -test all
```

#### Test Coverage
- ✅ SPI0 master read/write transactions
- ✅ I2C0 master read/write with ACK/NACK
- ✅ SPI1 master FIFO operations
- ✅ PWM0/PWM1 waveform generation
- ✅ Interrupt controller functionality
- ✅ Multi-peripheral concurrent access
- ✅ Invalid address error handling

### Waveform Analysis
Waveforms are generated in VCD format:
```bash
gtkwave sim/spi0_test/spi0_test.vcd
```

---

## Firmware Integration

### C Header File
Location: `fw/user_periph.h`

#### Base Address Definitions
```c
#define SPI0_BASE     0x30000000
#define I2C0_BASE     0x30010000
#define SPI1_BASE     0x30020000
#define PWM0_BASE     0x30030000
#define PWM1_BASE     0x30040000
#define PIC_BASE      0x30050000
```

#### Register Offset Definitions
```c
// SPI Registers
#define SPI_RXDATA    0x0000
#define SPI_TXDATA    0x0004
#define SPI_CFG       0x0008
#define SPI_CTRL      0x000C
#define SPI_PR        0x0010
#define SPI_STATUS    0x0014

// I2C Registers
#define I2C_RXDATA    0x0000
#define I2C_TXDATA    0x0004
#define I2C_PR        0x0008
#define I2C_CTRL      0x000C
#define I2C_STATUS    0x0010

// PWM Registers
#define TMR_TMR       0x0000
#define TMR_RELOAD    0x0004
#define TMR_PR        0x0008
#define TMR_CTRL      0x000C
#define TMR_CMP0      0x0010
```

#### Helper Functions
```c
static inline void reg_write(uint32_t addr, uint32_t data) {
    *((volatile uint32_t*)addr) = data;
}

static inline uint32_t reg_read(uint32_t addr) {
    return *((volatile uint32_t*)addr);
}
```

### Example: SPI Transfer
```c
void spi0_transfer(uint8_t data_out, uint8_t* data_in) {
    // Write data
    reg_write(SPI0_BASE + SPI_TXDATA, data_out);
    
    // Wait for transfer complete
    while (reg_read(SPI0_BASE + SPI_STATUS) & (1 << 3));  // TX_FULL
    
    // Read response
    *data_in = reg_read(SPI0_BASE + SPI_RXDATA) & 0xFF;
}
```

### Example: PWM Configuration
```c
void pwm0_init(uint32_t period, uint32_t duty) {
    // Set period
    reg_write(PWM0_BASE + TMR_RELOAD, period);
    
    // Set duty cycle
    reg_write(PWM0_BASE + TMR_CMP0, duty);
    
    // Enable PWM mode
    reg_write(PWM0_BASE + TMR_CTRL, 0x03);  // EN | PWM_EN
}
```

---

## Power and Area Estimates

### Expected Metrics
- **Estimated Area:** ~0.5 mm² @ 130nm
- **Power (Active):** ~5-10 mW @ 25 MHz, 1.8V
- **Power (Idle):** ~100 µW

### Resource Utilization
| Component | Gates | Flip-Flops | Memory |
|-----------|-------|------------|--------|
| SPI0      | ~500  | ~100       | 512B FIFO |
| I2C0      | ~300  | ~80        | - |
| SPI1      | ~500  | ~100       | 512B FIFO |
| PWM0      | ~400  | ~96        | - |
| PWM1      | ~400  | ~96        | - |
| WB_PIC    | ~200  | ~50        | - |
| Bus Logic | ~150  | ~30        | - |
| **Total** | ~2450 | ~552       | 1024B |

---

## Design Constraints

### Timing Constraints
- **Target Frequency:** 25 MHz (40 ns period)
- **Setup Time:** < 5 ns
- **Hold Time:** < 2 ns
- **Clock Skew:** < 1 ns

### Physical Constraints
- **Die Area:** 400µm × 400µm (user_project macro)
- **Placement:** Automatic via OpenLane
- **Routing:** 5 metal layers

---

## Known Limitations

1. **No Clock Gating:** All peripherals always clocked (higher power)
2. **Fixed Address Map:** No runtime address remapping
3. **Single IRQ Output:** Only `user_irq[0]` used
4. **No DMA:** All transfers are programmed I/O
5. **Fixed FIFO Depth:** SPI FIFO depth is 16 entries (not configurable)

---

## Troubleshooting

### Common Issues

**Issue:** Wishbone bus hangs
- **Cause:** Peripheral not acknowledging
- **Solution:** Check address decode logic, verify `ack_o` is driven

**Issue:** IRQ not firing
- **Cause:** WB_PIC not enabled or masked
- **Solution:** Check IRQ_ENABLE and GLOBAL_ENABLE registers

**Issue:** I2C not working
- **Cause:** Missing external pull-ups
- **Solution:** Add 4.7kΩ pull-ups on SCL and SDA

**Issue:** PWM output stuck
- **Cause:** PWM mode not enabled
- **Solution:** Set CTRL[1] (PWM_EN) and CTRL[0] (EN)

---

## References

- [Caravel Documentation](https://caravel-harness.readthedocs.io/)
- [Wishbone B4 Specification](https://cdn.opencores.org/downloads/wbspec_b4.pdf)
- [CF_SPI IP Documentation](../../ip/CF_SPI/README.md)
- [CF_I2C IP Documentation](../../ip/CF_I2C/README.md)
- [CF_TMR32 IP Documentation](../../ip/CF_TMR32/README.md)

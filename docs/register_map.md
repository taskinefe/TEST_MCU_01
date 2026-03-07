# Register Map

This document details the register maps for all peripherals in the Caravel multi-peripheral user project.

## Address Map Overview

| Peripheral | Base Address | Size   | Address Range           | IRQ Line |
|------------|-------------|--------|-------------------------|----------|
| SPI0       | 0x3000_0000 | 64 KB  | 0x3000_0000-0x3000_FFFF | 0        |
| I2C0       | 0x3001_0000 | 64 KB  | 0x3001_0000-0x3001_FFFF | 1        |
| SPI1       | 0x3002_0000 | 64 KB  | 0x3002_0000-0x3002_FFFF | 2        |
| PWM0       | 0x3003_0000 | 64 KB  | 0x3003_0000-0x3003_FFFF | 3        |
| PWM1       | 0x3004_0000 | 64 KB  | 0x3004_0000-0x3004_FFFF | 4        |
| ADC        | 0x3006_0000 | 64 KB  | 0x3006_0000-0x3006_FFFF | 5        |
| WB_PIC     | 0x3007_0000 | 64 KB  | 0x3007_0000-0x3007_FFFF | -        |

---

## SPI Master (CF_SPI) - SPI0 & SPI1

**Base Addresses:**
- SPI0: `0x3000_0000`
- SPI1: `0x3002_0000`

### Register Summary

| Offset | Name                | Access | Reset | Description |
|--------|---------------------|--------|-------|-------------|
| 0x0000 | RXDATA              | RO     | 0x00  | Receive data register |
| 0x0004 | TXDATA              | WO     | 0x00  | Transmit data register |
| 0x0008 | CFG                 | RW     | 0x00  | Configuration register |
| 0x000C | CTRL                | RW     | 0x00  | Control register |
| 0x0010 | PR                  | RW     | 0x00  | Prescaler/Clock divider |
| 0x0014 | STATUS              | RO     | 0x03  | Status register |
| 0xFE00 | RX_FIFO_LEVEL       | RO     | 0x00  | RX FIFO level |
| 0xFE04 | RX_FIFO_THRESHOLD   | RW     | 0x00  | RX FIFO threshold |
| 0xFE08 | RX_FIFO_FLUSH       | WO     | 0x00  | RX FIFO flush |
| 0xFE10 | TX_FIFO_LEVEL       | RO     | 0x00  | TX FIFO level |
| 0xFE14 | TX_FIFO_THRESHOLD   | RW     | 0x00  | TX FIFO threshold |
| 0xFE18 | TX_FIFO_FLUSH       | WO     | 0x00  | TX FIFO flush |
| 0xFF00 | IM                  | RW     | 0x00  | Interrupt mask |
| 0xFF04 | MIS                 | RO     | 0x00  | Masked interrupt status |
| 0xFF08 | RIS                 | RO     | 0x00  | Raw interrupt status |
| 0xFF0C | IC                  | WO     | 0x00  | Interrupt clear (W1C) |

### Register Details

#### CFG (0x0008) - Configuration
| Bit | Name | Access | Reset | Description |
|-----|------|--------|-------|-------------|
| 0   | CPOL | RW     | 0     | Clock polarity |
| 1   | CPHA | RW     | 0     | Clock phase |

#### STATUS (0x0014) - Status
| Bit | Name     | Access | Reset | Description |
|-----|----------|--------|-------|-------------|
| 0   | RX_EMPTY | RO     | 1     | RX FIFO empty |
| 1   | TX_EMPTY | RO     | 1     | TX FIFO empty |
| 2   | RX_FULL  | RO     | 0     | RX FIFO full |
| 3   | TX_FULL  | RO     | 0     | TX FIFO full |

---

## I2C Master (CF_I2C) - I2C0

**Base Address:** `0x3001_0000`

### Register Summary

| Offset | Name    | Access | Reset | Description |
|--------|---------|--------|-------|-------------|
| 0x0000 | RXDATA  | RO     | 0x00  | Receive data register |
| 0x0004 | TXDATA  | WO     | 0x00  | Transmit data register |
| 0x0008 | PR      | RW     | 0xFFFF| Prescaler register |
| 0x000C | CTRL    | RW     | 0x00  | Control register |
| 0x0010 | STATUS  | RO     | 0x00  | Status register |
| 0xFF00 | IM      | RW     | 0x00  | Interrupt mask |
| 0xFF04 | MIS     | RO     | 0x00  | Masked interrupt status |
| 0xFF08 | RIS     | RO     | 0x00  | Raw interrupt status |
| 0xFF0C | IC      | WO     | 0x00  | Interrupt clear (W1C) |

### Register Details

#### CTRL (0x000C) - Control
| Bit | Name  | Access | Reset | Description |
|-----|-------|--------|-------|-------------|
| 0   | START | RW     | 0     | Generate START condition |
| 1   | STOP  | RW     | 0     | Generate STOP condition |
| 2   | RD    | RW     | 0     | Read operation |
| 3   | WR    | RW     | 0     | Write operation |
| 4   | ACK   | RW     | 0     | ACK bit |
| 6   | EN    | RW     | 0     | I2C enable |

#### STATUS (0x0010) - Status
| Bit | Name      | Access | Reset | Description |
|-----|-----------|--------|-------|-------------|
| 0   | TIP       | RO     | 0     | Transfer in progress |
| 1   | BUSY      | RO     | 0     | Bus busy |
| 5   | RX_ACK    | RO     | 0     | Received ACK |

---

## PWM/Timer (CF_TMR32) - PWM0 & PWM1

**Base Addresses:**
- PWM0: `0x3003_0000`
- PWM1: `0x3004_0000`

### Register Summary

| Offset | Name      | Access | Reset      | Description |
|--------|-----------|--------|------------|-------------|
| 0x0000 | TMR       | RO     | 0x00000000 | Timer counter value |
| 0x0004 | RELOAD    | RW     | 0xFFFFFFFF | Reload/period value |
| 0x0008 | PR        | RW     | 0x00000000 | Prescaler value |
| 0x000C | CTRL      | RW     | 0x00000000 | Control register |
| 0x0010 | CMP0      | RW     | 0x00000000 | Compare value 0 (PWM duty) |
| 0x0014 | CMP1      | RW     | 0x00000000 | Compare value 1 |
| 0xFF00 | IM        | RW     | 0x00000000 | Interrupt mask |
| 0xFF04 | MIS       | RO     | 0x00000000 | Masked interrupt status |
| 0xFF08 | RIS       | RO     | 0x00000000 | Raw interrupt status |
| 0xFF0C | IC        | WO     | 0x00000000 | Interrupt clear (W1C) |

### Register Details

#### CTRL (0x000C) - Control
| Bit   | Name      | Access | Reset | Description |
|-------|-----------|--------|-------|-------------|
| 0     | EN        | RW     | 0     | Timer enable |
| 1     | PWM_EN    | RW     | 0     | PWM mode enable |
| 2     | ONE_SHOT  | RW     | 0     | One-shot mode |
| 3     | DIR       | RW     | 0     | Count direction (0=up, 1=down) |

#### PWM Operation
- **Period:** Set by RELOAD register
- **Duty Cycle:** Set by CMP0 register
- **Frequency:** f_pwm = f_clk / ((PR + 1) * (RELOAD + 1))
- **Duty %:** duty = (CMP0 / RELOAD) * 100%

---

## ADC (12-bit Analog-to-Digital Converter)

**Base Address:** 0x3006_0000  
**IRQ Line:** 5

### Register Summary
| Offset | Name       | Access | Reset | Description |
|--------|------------|--------|-------|-------------|
| 0x00   | CTRL       | RW     | 0x00  | Control register |
| 0x04   | STATUS     | RO     | 0x00  | Status register |
| 0x08   | DATA       | RO     | 0x00  | ADC data output |
| 0x0C   | CONFIG     | RW     | 0x04  | Configuration register |

### CTRL (Control Register) - Offset 0x00
| Bit   | Name   | Access | Reset | Description |
|-------|--------|--------|-------|-------------|
| 31:2  | -      | RO     | 0     | Reserved |
| 1     | START  | RW     | 0     | Start conversion (auto-clears on EOC) |
| 0     | ENABLE | RW     | 0     | ADC enable (1=enabled, 0=disabled) |

### STATUS (Status Register) - Offset 0x04
| Bit   | Name | Access | Reset | Description |
|-------|------|--------|-------|-------------|
| 31:13 | -    | RO     | 0     | Reserved |
| 12    | EOC  | RO     | 0     | End of conversion (1=complete, 0=busy) |
| 11:0  | DATA | RO     | 0     | ADC conversion result (12-bit) |

### DATA (Data Register) - Offset 0x08
| Bit   | Name | Access | Reset | Description |
|-------|------|--------|-------|-------------|
| 31:12 | -    | RO     | 0     | Reserved |
| 11:0  | DATA | RO     | 0     | ADC conversion result (12-bit) |

### CONFIG (Configuration Register) - Offset 0x0C
| Bit  | Name         | Access | Reset | Description |
|------|--------------|--------|-------|-------------|
| 31:4 | -            | RO     | 0     | Reserved |
| 3:0  | SAMPLE_WIDTH | RW     | 4     | Sample time in clock cycles (0-15) |

### Analog Connections
- **adc_vin:** analog_io[0] - ADC analog input (0V - 3.3V)
- **adc_vrefh:** 3.3V (fixed) - High reference voltage
- **adc_vrefl:** 0.0V (fixed) - Low reference voltage

### Conversion Formula
```
Digital_Output = (Vin / 3.3V) × 4095
Voltage = (Digital_Output / 4095) × 3.3V
```

---

## Programmable Interrupt Controller (WB_PIC)

**Base Address:** `0x3007_0000`

### Register Summary

| Offset | Name          | Access | Reset      | Description |
|--------|---------------|--------|------------|-------------|
| 0x0000 | IRQ_ENABLE    | RW     | 0x00000000 | IRQ enable mask (16 bits) |
| 0x0004 | IRQ_PENDING   | RO     | 0x00000000 | Pending IRQ status |
| 0x0008 | IRQ_CLEAR     | WO     | 0x00000000 | Clear pending IRQs (W1C) |
| 0x000C | GLOBAL_ENABLE | RW     | 0x00000000 | Global interrupt enable |
| 0x0010 | IRQ_PRIORITY_0| RW     | 0x00000000 | Priority for IRQ 0-15 |

### IRQ Source Mapping

| IRQ Line | Peripheral | Signal |
|----------|------------|--------|
| 0        | SPI0       | IRQ    |
| 1        | I2C0       | IRQ    |
| 2        | SPI1       | IRQ    |
| 3        | PWM0       | IRQ    |
| 4        | PWM1       | IRQ    |
| 5        | ADC        | EOC (End of Conversion) |
| 6-15     | Reserved   | -      |

**Output:** Single consolidated `irq_out` signal to Caravel `user_irq[0]`

---

## Access Notes

1. All registers are 32-bit aligned
2. Byte-enable signals (`wbs_sel_i`) are honored for partial writes
3. Invalid address reads return `0xDEADBEEF`
4. Invalid address writes are ACKed but discarded
5. All W1C (write-one-to-clear) registers require writing 1 to the bit to clear
6. RO registers ignore writes
7. WO registers return 0 on reads


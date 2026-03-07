# ADC Integration Summary

## Overview
Added **12-bit Analog-to-Digital Converter (ADC)** to the Caravel multi-peripheral user project.

## ADC Details
- **IP Core:** sky130_ef_ip__adc3v_12bit
- **Type:** SAR (Successive Approximation Register) ADC
- **Resolution:** 12-bit
- **Address:** 0x3006_0000
- **IRQ Line:** 5

## Integration Status: ✅ COMPLETE

### Files Created/Modified

#### New Files:
1. **`verilog/rtl/adc_wb_wrapper.v`**
   - Wishbone wrapper for ADC control
   - Integrates SAR controller with analog ADC block
   - Provides register interface for configuration and data readout

#### Modified Files:
1. **`verilog/rtl/user_project.v`**
   - Added ADC instance (peripheral #5)
   - Expanded to 7 peripherals total
   - Connected ADC analog signals

2. **`verilog/rtl/user_project_wrapper.v`**
   - Added analog pad connections
   - ADC input on analog_io[0]
   - Fixed references: Vrefh=3.3V, Vrefl=0.0V

3. **`verilog/includes/includes.rtl.caravel_user_project`**
   - Added ADC IP sources
   - Added ADC wrapper

## Updated Address Map

| Peripheral | Base Address | Size   | IRQ Line |
|------------|-------------|--------|----------|
| SPI0       | 0x3000_0000 | 64 KB  | 0        |
| I2C0       | 0x3001_0000 | 64 KB  | 1        |
| SPI1       | 0x3002_0000 | 64 KB  | 2        |
| PWM0       | 0x3003_0000 | 64 KB  | 3        |
| PWM1       | 0x3004_0000 | 64 KB  | 4        |
| **ADC**    | **0x3006_0000** | **64 KB**  | **5** |
| WB_PIC     | 0x3007_0000 | 64 KB  | -        |

## ADC Register Map

| Offset | Name       | Access | Description |
|--------|------------|--------|-------------|
| 0x00   | CTRL       | RW     | Control register (enable, start) |
| 0x04   | STATUS     | RO     | Status (EOC, data[11:0]) |
| 0x08   | DATA       | RO     | ADC data output [11:0] |
| 0x0C   | CONFIG     | RW     | Sample width configuration |

### CTRL Register (0x00)
| Bit | Name    | Description |
|-----|---------|-------------|
| 0   | ENABLE  | ADC enable |
| 1   | START   | Start conversion (auto-clears on EOC) |

### STATUS Register (0x04)
| Bit   | Name | Description |
|-------|------|-------------|
| 12    | EOC  | End of conversion flag |
| 11:0  | DATA | ADC conversion result |

### CONFIG Register (0x0C)
| Bit | Name         | Description |
|-----|--------------|-------------|
| 3:0 | SAMPLE_WIDTH | Sample time in clock cycles |

## Analog Connections

| Signal     | Source          | Description |
|------------|-----------------|-------------|
| adc_vin    | analog_io[0]    | ADC analog input (0-3.3V) |
| adc_vrefh  | 3.3V (fixed)    | High reference voltage |
| adc_vrefl  | 0.0V (fixed)    | Low reference voltage |

## How to Use the ADC

### 1. Enable the ADC
```c
#define ADC_BASE 0x30060000
#define ADC_CTRL   0x00
#define ADC_STATUS 0x04
#define ADC_DATA   0x08
#define ADC_CONFIG 0x0C

// Enable ADC
USER_writeWord(0x01, ((ADC_BASE - 0x30000000) + ADC_CTRL) >> 2);
```

### 2. Configure Sample Time
```c
// Set sample width to 4 cycles
USER_writeWord(0x04, ((ADC_BASE - 0x30000000) + ADC_CONFIG) >> 2);
```

### 3. Start Conversion
```c
// Start conversion (bit 1)
USER_writeWord(0x03, ((ADC_BASE - 0x30000000) + ADC_CTRL) >> 2);
```

### 4. Wait for End of Conversion
```c
// Poll STATUS register for EOC (bit 12)
uint32_t status;
do {
    status = USER_readWord(((ADC_BASE - 0x30000000) + ADC_STATUS) >> 2);
} while (!(status & (1 << 12)));
```

### 5. Read Result
```c
// Read 12-bit result from DATA register
uint32_t adc_value = USER_readWord(((ADC_BASE - 0x30000000) + ADC_DATA) >> 2);
uint16_t result = adc_value & 0xFFF;

// Convert to voltage
float voltage = (result / 4095.0) * 3.3;
```

## Verification Notes

### Analog Simulation
- The ADC uses `real` data types for analog signals
- Requires mixed-signal simulation (Verilog-AMS or behavioral model)
- For RTL verification: ADC input can be driven with real values
- Example: `force adc_vin = 1.65;` (mid-scale)

### Digital Interface Testing
- Wishbone register access can be tested like other peripherals
- Write to CTRL, CONFIG registers
- Read STATUS, DATA registers
- Verify interrupt (IRQ line 5) on EOC

## Architecture

```
Caravel Wishbone Bus
        |
        v
user_project @ 0x3006_0000
        |
        v
adc_wb_wrapper (Wishbone slave)
        |
        +-- sar_ctrl (Digital SAR controller)
        |      |
        |      v
        +-- sky130_ef_ip__adc3v_12bit (Analog ADC)
               ^
               |
        analog_io[0] (Analog input pad)
```

## Integration Checklist

- ✅ ADC IP linked to project
- ✅ Wishbone wrapper created
- ✅ Integrated into user_project (7 peripherals)
- ✅ Address mapping configured (0x3006_0000)
- ✅ Analog pad connected (analog_io[0])
- ✅ IRQ line assigned (peripheral_irqs[5])
- ✅ Includes file updated
- ⏳ Documentation updated
- ⏳ Verification test created
- ⏳ Firmware example created

## Next Steps

1. **Update main README** with ADC in peripheral list
2. **Update register_map.md** with ADC registers
3. **Update pad_map.md** with analog_io[0] assignment
4. **Create ADC verification test** with analog stimulus
5. **Run cocotb test** to verify Wishbone access

## Known Limitations

1. **Fixed References:** Vrefh and Vrefl are hardcoded (3.3V and 0V)
   - Could be made configurable via additional analog pads
   
2. **Single Channel:** Only one analog input supported
   - ADC IP supports one channel
   - For multi-channel, would need external analog multiplexer

3. **Verilator Linting:** ADC contains `real` types (analog signals)
   - Will show warnings in pure digital linting
   - This is expected for analog/mixed-signal IP
   - Simulation tools (iverilog, VCS) handle this correctly

## References

- ADC IP: `/nc/ip/sky130_ef_ip__adc3v_12bit/`
- Documentation: `/nc/ip/sky130_ef_ip__adc3v_12bit/docs/`
- Wrapper: `/workspace/caravel_multi_peripheral/verilog/rtl/adc_wb_wrapper.v`

---

**Date:** 2026-03-05  
**Status:** Integration Complete - Ready for Verification

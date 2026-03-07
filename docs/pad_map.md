# Pad Map

This document defines the GPIO pad assignments for all peripheral I/O signals in the Caravel multi-peripheral user project.

## Overview

The Caravel SoC provides 38 GPIO pads (`mprj_io[37:0]`) for user project connections. This design uses the following pad assignments:

**Reserved Pads:**
- `mprj_io[4:0]` - Reserved by Caravel, not used

**Available Pads:**
- `mprj_io[37:5]` - 33 pads available for user I/O

## Pad Assignment Table

| Pad Index | Direction | Peripheral | Signal Name | Description |
|-----------|-----------|------------|-------------|-------------|
| 5         | Output    | SPI0       | sclk        | SPI0 clock output |
| 6         | Output    | SPI0       | mosi        | SPI0 master out, slave in |
| 7         | Input     | SPI0       | miso        | SPI0 master in, slave out |
| 8         | Output    | SPI0       | csb         | SPI0 chip select (active low) |
| 9         | Bidir     | I2C0       | scl         | I2C0 serial clock (open-drain) |
| 10        | Bidir     | I2C0       | sda         | I2C0 serial data (open-drain) |
| 11        | Output    | SPI1       | sclk        | SPI1 clock output |
| 12        | Output    | SPI1       | mosi        | SPI1 master out, slave in |
| 13        | Input     | SPI1       | miso        | SPI1 master in, slave out |
| 14        | Output    | SPI1       | csb         | SPI1 chip select (active low) |
| 15        | Output    | PWM0       | pwm_out     | PWM0 output signal |
| 16        | Output    | PWM1       | pwm_out     | PWM1 output signal |
| 17-37     | -         | Unused     | -           | Available for future expansion |

### Analog Pad Assignment

| Pad Index    | Peripheral | Signal Name | Voltage Range | Description |
|--------------|------------|-------------|---------------|-------------|
| analog_io[0] | ADC        | adc_vin     | 0V - 3.3V     | ADC analog input |

**Note:** Analog pads are separate from digital GPIO pads. The ADC uses Caravel's analog_io array.

## Signal Details

### SPI0 (CF_SPI) - Pads 5-8

| Signal | Pad | Type   | Drive | Description |
|--------|-----|--------|-------|-------------|
| sclk   | 5   | Output | Push-pull | SPI clock, driven by master |
| mosi   | 6   | Output | Push-pull | Data from master to slave |
| miso   | 7   | Input  | -         | Data from slave to master |
| csb    | 8   | Output | Push-pull | Chip select, active low |

**Configuration:**
```verilog
assign mprj_io_out[5] = spi0_sclk;
assign mprj_io_oeb[5] = 1'b0;  // Output enable

assign mprj_io_out[6] = spi0_mosi;
assign mprj_io_oeb[6] = 1'b0;  // Output enable

assign spi0_miso = mprj_io_in[7];
assign mprj_io_out[7] = 1'b0;
assign mprj_io_oeb[7] = 1'b1;  // Input mode

assign mprj_io_out[8] = spi0_csb;
assign mprj_io_oeb[8] = 1'b0;  // Output enable
```

### I2C0 (CF_I2C) - Pads 9-10

| Signal | Pad | Type  | Drive       | Description |
|--------|-----|-------|-------------|-------------|
| scl    | 9   | Bidir | Open-drain  | Serial clock line |
| sda    | 10  | Bidir | Open-drain  | Serial data line |

**Configuration (Open-Drain):**
```verilog
assign i2c0_scl_in = mprj_io_in[9];
assign mprj_io_out[9] = 1'b0;            // Drive low when active
assign mprj_io_oeb[9] = ~i2c0_scl_oe;    // Active low OEB

assign i2c0_sda_in = mprj_io_in[10];
assign mprj_io_out[10] = 1'b0;           // Drive low when active
assign mprj_io_oeb[10] = ~i2c0_sda_oe;   // Active low OEB
```

**Note:** I2C requires external pull-up resistors on SCL and SDA lines.

### SPI1 (CF_SPI) - Pads 11-14

| Signal | Pad | Type   | Drive | Description |
|--------|-----|--------|-------|-------------|
| sclk   | 11  | Output | Push-pull | SPI clock, driven by master |
| mosi   | 12  | Output | Push-pull | Data from master to slave |
| miso   | 13  | Input  | -         | Data from slave to master |
| csb    | 14  | Output | Push-pull | Chip select, active low |

**Configuration:**
```verilog
assign mprj_io_out[11] = spi1_sclk;
assign mprj_io_oeb[11] = 1'b0;  // Output enable

assign mprj_io_out[12] = spi1_mosi;
assign mprj_io_oeb[12] = 1'b0;  // Output enable

assign spi1_miso = mprj_io_in[13];
assign mprj_io_out[13] = 1'b0;
assign mprj_io_oeb[13] = 1'b1;  // Input mode

assign mprj_io_out[14] = spi1_csb;
assign mprj_io_oeb[14] = 1'b0;  // Output enable
```

### PWM0 (CF_TMR32) - Pad 15

| Signal  | Pad | Type   | Drive | Description |
|---------|-----|--------|-------|-------------|
| pwm_out | 15  | Output | Push-pull | PWM output signal |

**Configuration:**
```verilog
assign mprj_io_out[15] = pwm0_out;
assign mprj_io_oeb[15] = 1'b0;  // Output enable
```

### PWM1 (CF_TMR32) - Pad 16

| Signal  | Pad | Type   | Drive | Description |
|---------|-----|--------|-------|-------------|
| pwm_out | 16  | Output | Push-pull | PWM output signal |

**Configuration:**
```verilog
assign mprj_io_out[16] = pwm1_out;
assign mprj_io_oeb[16] = 1'b0;  // Output enable
```

## Unused Pads Configuration

All unused pads (17-37) should be configured as inputs with output drivers disabled:

```verilog
assign mprj_io_out[37:17] = 21'b0;
assign mprj_io_oeb[37:17] = {21{1'b1}};  // All inputs
```

## Pad Configuration Summary

| Pad Range | Count | Usage |
|-----------|-------|-------|
| 0-4       | 5     | Reserved by Caravel |
| 5-8       | 4     | SPI0 |
| 9-10      | 2     | I2C0 |
| 11-14     | 4     | SPI1 |
| 15-16     | 2     | PWM0/PWM1 |
| 17-37     | 21    | Unused (available) |

### ADC - analog_io[0]

**Type:** Analog Input  
**Voltage Range:** 0V - 3.3V  
**Resolution:** 12-bit (4096 levels)  
**Conversion Time:** Depends on SAMPLE_WIDTH configuration (default: 4 clock cycles + 12 conversion cycles)

**Electrical Characteristics:**
- **Input Impedance:** High (behavioral model)
- **Reference Voltage (Vrefh):** 3.3V (fixed, internal)
- **Reference Voltage (Vrefl):** 0.0V (fixed, internal)
- **LSB Size:** 3.3V / 4095 = 0.806 mV
- **DNL/INL:** Depends on analog implementation (behavioral model is ideal)

**Recommended External Circuit:**
- **Source Impedance:** <10kΩ for accurate conversion
- **Input Protection:** Series resistor (1kΩ) + clamping diodes recommended
- **Input Filter:** 100nF capacitor to ground for noise filtering

**Conversion Formula:**
```
Vin = (ADC_Result / 4095) × 3.3V
```

**Example Connections:**
- Voltage divider for measuring higher voltages
- Temperature sensor (LM35, TMP36)
- Light sensor (photodiode, LDR)
- Potentiometer for user input
- Battery voltage monitoring

---

## How to Modify Pad Assignments

To change pad assignments:

1. Edit the `user_project_wrapper.v` file
2. Update the wire assignments for the desired peripheral
3. Update the `mprj_io_out`, `mprj_io_in`, and `mprj_io_oeb` connections
4. Ensure no pad conflicts (one function per pad)
5. Update this documentation

## Pin Muxing

This design does not implement pin muxing. Each pad is dedicated to a single function. If pin muxing is required, it must be implemented in the `user_project` module with appropriate control registers.

## External Connections

When connecting to external devices:

- **SPI**: Connect to SPI slave devices (flash, external ADC, DAC, etc.)
- **I2C**: Requires external 4.7kΩ-10kΩ pull-ups on SCL and SDA
- **PWM**: Can drive LEDs, motors, servos, or other PWM-controlled devices
- **ADC**: Connect analog sensors (0-3.3V range) to analog_io[0] with appropriate protection/filtering

## Electrical Characteristics

- **VOH (Output High):** VDDIO - 0.2V (typical 3.1V @ 3.3V VDDIO)
- **VOL (Output Low):** 0.2V (typical)
- **VIH (Input High):** 0.7 × VDDIO (typical 2.31V @ 3.3V VDDIO)
- **VIL (Input Low):** 0.3 × VDDIO (typical 0.99V @ 3.3V VDDIO)
- **Drive Strength:** Configurable via pad configuration (not exposed in this design)

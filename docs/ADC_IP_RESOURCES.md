# ADC IP Resources - Complete Guide

## Available ADC IP

**Location:** `/nc/ip/sky130_ef_ip__adc3v_12bit/`

**Type:** 12-bit CDAC-ADC (Capacitive DAC ADC)  
**Designer:** Tim Edwards (Efabless Corporation)  
**PDK:** SKY130A  
**License:** Apache 2.0

---

## Directory Structure

```
/nc/ip/sky130_ef_ip__adc3v_12bit/
├── docs/                           ← Documentation
│   ├── sky130_ef_ip__adc3v_12bit.md
│   ├── sky130_ef_ip__adc3v_12bit_schematic.svg
│   ├── sky130_ef_ip__adc3v_12bit_symbol.svg
│   ├── sky130_ef_ip__adc3v_12bit_layout.md
│   ├── sky130_ef_ip__adc3v_12bit_w.png        (Layout - white bg)
│   └── sky130_ef_ip__adc3v_12bit_b.png        (Layout - black bg)
│
├── verilog/                        ← Verilog models ⭐
│   ├── sky130_ef_ip__adc3v_12bit.v           (Main ADC module)
│   ├── sar_ctrl.v                            (SAR control logic)
│   ├── adc_testbench.v                       (Testbench)
│   └── README.md
│
├── gds/                            ← Layout (GDS)
├── lef/                            ← Abstract view
├── mag/                            ← Magic layout files
├── xschem/                         ← Schematic files
├── netlist/                        ← SPICE netlist
├── lvs/                            ← LVS files
└── ip/                             ← Sub-IP components
```

---

## Main ADC Module

**File:** `/nc/ip/sky130_ef_ip__adc3v_12bit/verilog/sky130_ef_ip__adc3v_12bit.v`

### Module Interface

```verilog
module sky130_ef_ip__adc3v_12bit #(parameter FUNCTIONAL = 1)(
`ifdef USE_POWER_PINS
   inout       vccd0,      // Digital power
   inout       vssd0,      // Digital ground
   inout       vdda0,      // Analog power (3.3V)
   inout       vssa0,      // Analog ground
`endif
   // Analog inputs (real type for simulation)
   input  real  adc_trim,      // Trim adjustment
   input  real  adc_vCM,       // Common-mode voltage
   input  real  adc_vrefL,     // Reference voltage low
   input  real  adc_vrefH,     // Reference voltage high
   input  real  adc0,          // Analog input signal
   
   // Digital control
   input        adc0_ena,      // Enable
   input        adc0_reset,    // Reset
   input        adc0_hold,     // Sample/hold control
   input [11:0] adc0_dac_val_0, // DAC value for SAR
   output       adc0_comp_out  // Comparator output
);
```

---

## Key Features

### Specifications

| Parameter | Value |
|-----------|-------|
| **Resolution** | 12 bits |
| **Architecture** | Successive Approximation (SAR) |
| **Input Type** | Single-ended analog |
| **Voltage Range** | Defined by vrefL to vrefH |
| **Supply Voltage** | 3.3V analog (vdda0) |
| **Control** | Digital (ena, reset, hold) |

### Components Included

1. **Sample & Hold** - Captures analog input
2. **12-bit CDAC** - Capacitive DAC for conversion
3. **Comparator** - Compares input to DAC output
4. **SAR Control Logic** - Successive approximation algorithm

---

## How to Use in Your Project

### Step 1: Copy Verilog Files

```bash
# Copy ADC Verilog to your project
cp /nc/ip/sky130_ef_ip__adc3v_12bit/verilog/sky130_ef_ip__adc3v_12bit.v \
   /your/project/verilog/rtl/

cp /nc/ip/sky130_ef_ip__adc3v_12bit/verilog/sar_ctrl.v \
   /your/project/verilog/rtl/
```

### Step 2: Instantiate in Your Design

```verilog
// In your top-level module
sky130_ef_ip__adc3v_12bit #(
    .FUNCTIONAL(1)  // Behavioral model for simulation
) adc_inst (
`ifdef USE_POWER_PINS
    .vccd0(vccd1),
    .vssd0(vssd1),
    .vdda0(vdda1),
    .vssa0(vssa1),
`endif
    // Analog connections
    .adc_trim(adc_trim_voltage),
    .adc_vCM(adc_common_mode),
    .adc_vrefL(1.65),        // Reference low
    .adc_vrefH(3.3),         // Reference high
    .adc0(analog_input),      // Your analog signal
    
    // Digital control
    .adc0_ena(adc_enable),
    .adc0_reset(adc_reset),
    .adc0_hold(adc_hold),
    .adc0_dac_val_0(dac_value),
    .adc0_comp_out(comparator_out)
);
```

---

## Important Notes

### ⚠️ This is an ANALOG IP

**Critical:** This ADC is an **analog/mixed-signal IP** that requires:

1. **Analog power domain** (vdda0/vssa0 at 3.3V)
2. **Analog signal routing** (special layout considerations)
3. **Reference voltages** (vrefL, vrefH)
4. **Proper analog pads** in Caravel

### For Caravel Integration

**Analog IOs in Caravel:**
- Use `analog_io[]` pads, not regular `mprj_io[]`
- Requires special analog routing in layout
- Must connect to analog power rails

**Example Caravel Connections:**
```verilog
// In user_project_wrapper
assign analog_io[0] = adc_input;     // Analog input
assign analog_io[1] = vrefH;          // Reference high
assign analog_io[2] = vrefL;          // Reference low
```

---

## Digital Wrapper (Wishbone Interface)

**Note:** The base ADC IP does **NOT** include a Wishbone interface.

You'll need to create a wrapper that:

1. **Controls the ADC** (enable, reset, hold signals)
2. **Runs SAR algorithm** (successive approximation)
3. **Reads comparator output**
4. **Provides digital result** via Wishbone

### Example Wrapper Structure

```verilog
module adc_wb_wrapper (
    // Wishbone interface
    input         wb_clk_i,
    input         wb_rst_i,
    input         wbs_stb_i,
    input         wbs_cyc_i,
    input         wbs_we_i,
    input  [31:0] wbs_adr_i,
    input  [31:0] wbs_dat_i,
    output [31:0] wbs_dat_o,
    output        wbs_ack_o,
    
    // Analog connections
    input  real   analog_input,
    // ... other analog signals
);

    // ADC control logic
    reg [11:0] adc_result;
    reg [11:0] dac_value;
    reg adc_ena, adc_hold;
    wire comp_out;
    
    // SAR state machine
    // ... implement successive approximation algorithm
    
    // ADC instance
    sky130_ef_ip__adc3v_12bit adc (
        .adc0(analog_input),
        .adc0_ena(adc_ena),
        .adc0_hold(adc_hold),
        .adc0_dac_val_0(dac_value),
        .adc0_comp_out(comp_out)
    );
    
    // Wishbone interface logic
    // ... register reads/writes
    
endmodule
```

---

## SAR Control Module

**File:** `/nc/ip/sky130_ef_ip__adc3v_12bit/verilog/sar_ctrl.v`

This module implements the **Successive Approximation Register** algorithm:

1. Start with MSB set to 1
2. Compare input to DAC output
3. Keep or clear bit based on comparator
4. Move to next bit
5. Repeat for all 12 bits

---

## Documentation Files

### Schematic

**File:** `/nc/ip/sky130_ef_ip__adc3v_12bit/docs/sky130_ef_ip__adc3v_12bit_schematic.svg`

View the complete analog schematic showing:
- Sample & Hold circuit
- 12-bit Capacitor DAC
- Comparator
- Control logic

### Layout

**Files:**
- `/nc/ip/sky130_ef_ip__adc3v_12bit/docs/sky130_ef_ip__adc3v_12bit_w.png` (white background)
- `/nc/ip/sky130_ef_ip__adc3v_12bit/docs/sky130_ef_ip__adc3v_12bit_b.png` (black background)

Shows the physical layout of the ADC in SKY130.

---

## Physical Files

### For OpenLane Integration

```
gds/  → Layout file (.gds)
lef/  → Abstract view (.lef)
mag/  → Magic layout source
```

**If hardening as macro:**
1. Use provided GDS/LEF files
2. Integrate as hard macro in OpenLane
3. Connect analog signals to analog_io pads

---

## Testbench

**File:** `/nc/ip/sky130_ef_ip__adc3v_12bit/verilog/adc_testbench.v`

Example testbench showing:
- How to set up analog inputs
- How to control the ADC
- How to run conversions
- How to read results

---

## Usage Example for Motor Control

### For 3-Phase Motor Current Sensing

```verilog
// Three ADC instances for three phase currents
sky130_ef_ip__adc3v_12bit phase_a_adc (
    .adc0(phase_a_current),  // From current sensor
    .adc_vrefL(0.0),
    .adc_vrefH(3.3),
    // ... control signals
);

sky130_ef_ip__adc3v_12bit phase_b_adc (
    .adc0(phase_b_current),
    // ...
);

sky130_ef_ip__adc3v_12bit phase_c_adc (
    .adc0(phase_c_current),
    // ...
);
```

---

## Alternative: Digital ADC Interface

**Note:** If you need a fully **digital** ADC (not analog):

**Options:**
1. Use **external ADC chip** (e.g., MCP3208) with SPI interface
2. Use **sigma-delta** digital ADC IP (if available)
3. Integrate **off-chip ADC** via SPI/I2C

**For Caravel:** External ADC + SPI is often simpler than analog integration.

---

## Summary

### ADC IP Location

```
/nc/ip/sky130_ef_ip__adc3v_12bit/
```

### Key Files

| File | Purpose |
|------|---------|
| `verilog/sky130_ef_ip__adc3v_12bit.v` | Main ADC module |
| `verilog/sar_ctrl.v` | SAR algorithm |
| `docs/*.svg` | Schematics |
| `docs/*.png` | Layout images |
| `gds/` | Physical layout |
| `lef/` | Abstract view |

### Integration Steps

1. ✅ **Copy Verilog files** to your project
2. ✅ **Create Wishbone wrapper** with SAR control
3. ✅ **Connect to analog_io pads** in Caravel
4. ✅ **Add to OpenLane config** (if using as hard macro)
5. ✅ **Route analog signals** carefully in layout

---

## Important for Your Project

**Your motor control project likely needs:**

**Option A: Use this analog ADC** (complex)
- Requires analog pad connections
- Special layout considerations
- Full analog design flow

**Option B: Use external digital ADC** (simpler) ⭐
- Connect via SPI (you already have 2× SPI masters!)
- Examples: MCP3208 (8-channel 12-bit SPI ADC)
- Purely digital interface
- Much simpler Caravel integration

**Recommendation:** For Caravel user project, **external SPI ADC** is typically easier than integrating analog IP.

---

**All ADC IP resources documented!** ✅

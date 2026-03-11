# ADC IP Resources - Now in Your Project!

## ✅ ADC Resources Copied to Your Project

**Location:** `ip_references/adc/`

I've copied all the ADC IP files from the system library to your project directory so you can access them from Windows/WSL.

---

## Directory Structure

```
ip_references/adc/
├── README.md                        ← ADC overview
├── LICENSE                          ← Apache 2.0 license
│
├── verilog/                         ← Verilog files ⭐
│   ├── sky130_ef_ip__adc3v_12bit.v ← Main ADC module
│   ├── sar_ctrl.v                   ← SAR control logic
│   ├── adc_testbench.v              ← Example testbench
│   └── README.md
│
├── docs/                            ← Documentation
│   ├── sky130_ef_ip__adc3v_12bit.md
│   ├── sky130_ef_ip__adc3v_12bit_schematic.svg
│   ├── sky130_ef_ip__adc3v_12bit_symbol.svg
│   ├── sky130_ef_ip__adc3v_12bit_layout.md
│   ├── sky130_ef_ip__adc3v_12bit_w.png  ← Layout (white bg)
│   └── sky130_ef_ip__adc3v_12bit_b.png  ← Layout (black bg)
│
├── gds/                             ← Physical layout (GDS)
├── lef/                             ← Abstract view (LEF)
├── mag/                             ← Magic layout files
├── xschem/                          ← Schematic files
├── netlist/                         ← SPICE netlist
└── ip/                              ← Sub-component IPs
```

---

## Quick Access

### View Verilog Files

```bash
# On Windows/WSL
cd /mnt/c/Users/Efe/Downloads/TEST_MCU_01-TEST_MCU_01/TEST_MCU_01-TEST_MCU_01

# View ADC module
cat ip_references/adc/verilog/sky130_ef_ip__adc3v_12bit.v

# View SAR control
cat ip_references/adc/verilog/sar_ctrl.v

# View testbench
cat ip_references/adc/verilog/adc_testbench.v
```

---

## Key Files

### Main ADC Module

**File:** `ip_references/adc/verilog/sky130_ef_ip__adc3v_12bit.v`

12-bit successive approximation ADC with:
- Analog input
- Digital control interface
- Comparator output
- SAR algorithm support

### SAR Control

**File:** `ip_references/adc/verilog/sar_ctrl.v`

Implements the successive approximation algorithm:
- Bit-by-bit conversion
- 12-bit resolution
- Digital control logic

### Testbench

**File:** `ip_references/adc/verilog/adc_testbench.v`

Example showing how to:
- Instantiate the ADC
- Provide analog signals
- Control the conversion
- Read results

---

## Documentation

### Schematic

**File:** `ip_references/adc/docs/sky130_ef_ip__adc3v_12bit_schematic.svg`

Complete circuit diagram showing:
- Sample & Hold
- 12-bit Capacitive DAC
- Comparator
- Control logic

### Layout Images

**Files:**
- `ip_references/adc/docs/sky130_ef_ip__adc3v_12bit_w.png` (white background)
- `ip_references/adc/docs/sky130_ef_ip__adc3v_12bit_b.png` (black background)

Physical layout of the ADC in SKY130 process.

---

## How to Use

### Copy to Your Design

```bash
# Copy ADC Verilog to your project RTL
cp ip_references/adc/verilog/sky130_ef_ip__adc3v_12bit.v verilog/rtl/
cp ip_references/adc/verilog/sar_ctrl.v verilog/rtl/
```

### Instantiate in Your Module

```verilog
sky130_ef_ip__adc3v_12bit #(
    .FUNCTIONAL(1)
) adc_inst (
`ifdef USE_POWER_PINS
    .vccd0(vccd1),
    .vssd0(vssd1),
    .vdda0(vdda1),
    .vssa0(vssa1),
`endif
    .adc0(analog_input),
    .adc_vrefL(1.65),
    .adc_vrefH(3.3),
    .adc0_ena(enable),
    .adc0_reset(reset),
    .adc0_hold(hold),
    .adc0_dac_val_0(dac_value),
    .adc0_comp_out(comp_out)
);
```

---

## Important Notes

### This is an Analog IP

**Requirements:**
- Analog power domain (3.3V)
- Analog signal pads
- Reference voltages
- Special layout routing

### For Caravel

**Challenges:**
- Requires `analog_io[]` pads (limited)
- Complex analog integration
- Harder to verify

### Recommendation

For motor control in Caravel:

**External SPI ADC is simpler!** ⭐

Examples:
- MCP3208 (8-ch, 12-bit, SPI)
- ADS7953 (16-ch, 12-bit, SPI)
- Connect to your SPI master (already in design!)

---

## All Files Available Now!

You can now browse all ADC IP files in:

```
ip_references/adc/
```

**No need to access /nc/ip/ - everything is in your project!** ✅

---

## View Files From Windows

If you've cloned the repo to Windows:

```
C:\Users\Efe\Downloads\TEST_MCU_01-TEST_MCU_01\TEST_MCU_01-TEST_MCU_01\ip_references\adc\
```

Open with any text editor or VS Code!

---

**All ADC resources now accessible in your project directory!** 🎉

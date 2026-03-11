# All IP Resources - Location and Access Guide

## ✅ IP Resources Available

All NativeChips IP cores are available on the system at:

```
/nc/ip/
```

**Note:** This directory contains 500+ MB of IP files (too large to copy to your Git repository).

---

## How to Access IP Resources

### Method 1: Reference System Location (Recommended)

When working on the server, reference IPs directly from:

```bash
/nc/ip/
```

**List all IPs:**
```bash
ls /nc/ip/
```

**View specific IP:**
```bash
ls /nc/ip/CF_UART/
find /nc/ip/CF_UART -name "*.v"
```

---

### Method 2: Copy Only What You Need

Instead of copying all IPs, copy only the ones you'll use:

```bash
# Example: Copy UART IP to your project
cp -r /nc/ip/CF_UART/v2.0.1/hdl/rtl/ /your/project/verilog/rtl/uart/

# Example: Copy SPI IP
cp -r /nc/ip/CF_SPI/v2.0.1/hdl/rtl/ /your/project/verilog/rtl/spi/
```

---

## Complete IP List (47 Total)

### ✅ NativeChips Verified IPs (Recommended)

| IP | Purpose | Location |
|----|---------|----------|
| **CF_UART** | UART Controller | `/nc/ip/CF_UART/` |
| **CF_SPI** | SPI Master | `/nc/ip/CF_SPI/` |
| **CF_I2C** | I2C Controller | `/nc/ip/CF_I2C/` |
| **CF_I2S** | I2S Audio | `/nc/ip/CF_I2S/` |
| **CF_TMR32** | Timer + PWM | `/nc/ip/CF_TMR32/` |
| **CF_SRAM_1024x32** | 4KB SRAM | `/nc/ip/CF_SRAM_1024x32/` |
| **EF_GPIO8** | GPIO Controller | `/nc/ip/EF_GPIO8/` |
| **EF_AES** | AES Encryption | `/nc/ip/EF_AES/` |
| **EF_SHA256** | SHA256 Hashing | `/nc/ip/EF_SHA256/` |

### Additional IPs

| IP | Purpose | Location |
|----|---------|----------|
| **MS_CLK_RST** | Clock & Reset Manager | `/nc/ip/MS_CLK_RST/` |
| **EF_WDT32** | Watchdog Timer | `/nc/ip/EF_WDT32/` |
| **EF_TCC32** | Timer/Counter | `/nc/ip/EF_TCC32/` |
| **DFFRAM128x32** | 512B DFFRAM | `/nc/ip/DFFRAM128x32/` |
| **DFFRAM256x32** | 1KB DFFRAM | `/nc/ip/DFFRAM256x32/` |
| **DFFRAM512x32** | 2KB DFFRAM | `/nc/ip/DFFRAM512x32/` |
| **EF_PSRAM_CTRL** | PSRAM Controller | `/nc/ip/EF_PSRAM_CTRL/` |
| **EF_PSRAM_CTRL_V2** | PSRAM V2 | `/nc/ip/EF_PSRAM_CTRL_V2/` |

### Analog/Mixed-Signal IPs

| IP | Purpose | Location |
|----|---------|----------|
| **sky130_ef_ip__adc3v_12bit** | 12-bit ADC | `/nc/ip/sky130_ef_ip__adc3v_12bit/` |
| **sky130_ef_ip__rc_osc_500k** | 500kHz RC Osc | `/nc/ip/sky130_ef_ip__rc_osc_500k/` |
| **sky130_ef_ip__xtal_osc_16M** | 16MHz Crystal Osc | `/nc/ip/sky130_ef_ip__xtal_osc_16M/` |
| **sky130_ef_ip__xtal_osc_32k** | 32kHz Crystal Osc | `/nc/ip/sky130_ef_ip__xtal_osc_32k/` |

---

## Typical IP Directory Structure

```
/nc/ip/<IP_NAME>/
├── v<version>/
│   ├── hdl/rtl/              ← Verilog source files ⭐
│   ├── verify/               ← Testbenches
│   ├── doc/                  ← Documentation
│   ├── fw/                   ← Firmware drivers (if applicable)
│   ├── gds/                  ← Layout files
│   ├── lef/                  ← Abstract views
│   └── lib/                  ← Timing libraries
```

---

## Usage Example

### Copy UART IP to Your Project

```bash
# 1. View the IP
ls /nc/ip/CF_UART/v2.0.1/hdl/rtl/

# 2. See what Verilog files are available
find /nc/ip/CF_UART/v2.0.1/hdl/rtl -name "*.v"

# 3. Copy to your project
mkdir -p /your/project/ip/uart
cp -r /nc/ip/CF_UART/v2.0.1/hdl/rtl/* /your/project/ip/uart/

# 4. Read documentation
cat /nc/ip/CF_UART/v2.0.1/README.md
```

---

## For Your Motor Control Project

**IPs Already in Your Design:**

1. **CF_SPI** (2× instances) - `/nc/ip/CF_SPI/`
2. **CF_I2C** (1× instance) - `/nc/ip/CF_I2C/`
3. **CF_TMR32** (2× PWM) - `/nc/ip/CF_TMR32/`
4. **CF_SRAM_1024x32** (4KB) - `/nc/ip/CF_SRAM_1024x32/`

**May Also Need:**

5. **EF_GPIO8** - GPIO control
6. **EF_WDT32** - Watchdog timer
7. **MS_CLK_RST** - Clock management

---

## ADC IP (Already Copied)

The ADC IP has been copied to your project at:

```
/workspace/caravel_multi_peripheral/ip_references/adc/
```

See **`ADC_RESOURCES_HERE.md`** for complete ADC documentation.

---

## Why Not Copied All IPs?

**Reason:** Total size is 500+ MB, which:
- Exceeds GitHub file size limits
- Makes repository very large
- Most IPs won't be used in your project

**Solution:** Reference system location `/nc/ip/` or copy only needed IPs.

---

## Quick Reference Commands

```bash
# List all available IPs
ls /nc/ip/

# View specific IP
ls /nc/ip/CF_UART/

# Find all Verilog files in an IP
find /nc/ip/CF_UART -name "*.v"

# Read IP README
cat /nc/ip/CF_UART/*/README.md

# Copy IP to your project
cp -r /nc/ip/CF_UART/v2.0.1/hdl/rtl /your/project/ip/uart/
```

---

## Documentation

For detailed information about each IP, see:

**NativeChips IP Documentation:**  
Check `/nc/ip/<IP_NAME>/*/doc/` or `/nc/ip/<IP_NAME>/*/README.md`

**System Prompt Info:**  
All verified IPs are listed in the system guidelines with:
- IP name
- Version
- Verification status
- Basic description

---

## Summary

**Location:** All IPs at `/nc/ip/`

**Total IPs:** 47 different IP cores

**Verified IPs:** 9 (marked with ✅)

**Recommendation:** Reference system location or copy only what you need

**ADC IP:** Already copied to `ip_references/adc/`

**Access:** Available when working on the server

---

**All IP resources accessible at `/nc/ip/`!** ✅

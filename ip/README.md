# IP Cores Directory

This directory contains the actual IP core files used in the motor control project.

## ✅ All IP Resources Now in Repository

**Previous:** Symbolic links to `/nc/ip/` (didn't work on Windows)  
**Now:** Actual files copied (RTL, docs, firmware)

---

## Directory Structure

```
ip/
├── CF_SPI/               ← SPI Master IP
│   ├── hdl/rtl/         ← Verilog RTL files
│   ├── fw/              ← C firmware drivers
│   ├── docs/            ← Documentation
│   └── README.md
│
├── CF_I2C/               ← I2C Master IP
│   ├── hdl/rtl/
│   ├── fw/
│   ├── docs/
│   └── README.md
│
├── CF_TMR32/             ← Timer/PWM IP
│   ├── hdl/rtl/
│   ├── fw/
│   ├── docs/
│   └── README.md
│
├── CF_SRAM_1024x32/      ← 4KB SRAM IP
│   ├── hdl/
│   ├── doc/
│   └── README.md
│
├── CF_IP_UTIL/           ← IP Utilities
│   ├── fw/
│   └── README.md
│
└── sky130_ef_ip__adc3v_12bit/  ← 12-bit ADC IP
    ├── verilog/
    ├── docs/
    ├── README.md
    └── LICENSE
```

---

## What's Included

### Essential Files ✅

**For each IP:**
- ✅ **Verilog RTL** (`hdl/rtl/*.v`) - Source files
- ✅ **README** - IP documentation
- ✅ **Firmware** (`fw/*.c`, `fw/*.h`) - C drivers
- ✅ **Docs** - Additional documentation
- ✅ **LICENSE** - License files

### What's NOT Included (Too Large)

**Excluded to keep repository size manageable:**
- ❌ GDS files (layout binaries - very large)
- ❌ LEF files (abstract layouts - available separately)
- ❌ Timing libraries (.lib files)
- ❌ SPEF files (parasitic extraction)
- ❌ Large binary files
- ❌ Build artifacts

**Note:** If you need these files, they're available on the server at `/nc/ip/`

---

## IP Versions

| IP | Version | Files |
|----|---------|-------|
| **CF_SPI** | v2.0.1 | RTL, FW, Docs |
| **CF_I2C** | v2.0.0 | RTL, FW, Docs |
| **CF_TMR32** | v2.1.0-nc | RTL, FW, Docs |
| **CF_SRAM_1024x32** | v2.1.0-nc | RTL, Docs |
| **CF_IP_UTIL** | v1.0.0 | FW, Docs |
| **sky130_ef_ip__adc3v_12bit** | Latest | Verilog, Docs |

---

## How to Use

### View IP Files

```bash
# View SPI RTL files
ls ip/CF_SPI/hdl/rtl/

# View SPI documentation
cat ip/CF_SPI/README.md

# View firmware drivers
ls ip/CF_SPI/fw/
```

### Copy to Your Project

These files are already integrated in `verilog/rtl/user_project.v`.

If you need to modify:

```bash
# Edit the IP wrapper
vim verilog/rtl/user_project.v
```

---

## File Counts

**Total Verilog files:** 58  
**Total documentation:** 7 READMEs + docs  
**Total size:** ~3 MB (git-friendly!)

---

## Integration Method

IPs are integrated using:

1. **Direct instantiation** in `user_project.v`
2. **Wishbone bus** connections
3. **Bus splitter** for address decoding

**See:** `docs/IPS_USED_IN_PROJECT.md` for complete integration details.

---

## IP Management

### Original Location

These IPs are maintained at:
```
/nc/ip/<IP_NAME>/<VERSION>/
```

### Update Process

To update an IP:

1. Get latest from `/nc/ip/`
2. Copy essential files to `ip/<IP_NAME>/`
3. Test integration
4. Commit changes

---

## Additional References

**Complete IP List:**
- `docs/IPS_USED_IN_PROJECT.md` - All IPs used
- `ip_references/ALL_IPS_LOCATION.md` - Full IP library

**IP-Specific Guides:**
- `docs/MOTOR_PWM_GUIDE.md` - PWM IP usage
- `docs/SRAM_GUIDE.md` - SRAM IP usage
- `docs/MOTOR_ADC_3CH_GUIDE.md` - ADC usage

---

## Repository Size Management

**Why lightweight?**
- GitHub free tier limits
- Faster clone/pull operations
- Focus on source code, not binaries

**Full resources available:**
- On server: `/nc/ip/`
- Reference docs: `ip_references/`
- Layout files: Available via OpenLane outputs

---

## License

Each IP has its own license (typically Apache 2.0).  
See individual `LICENSE` files in each IP directory.

---

**All IP resources now accessible in repository!** ✅

**Last Updated:** 2026-03-11

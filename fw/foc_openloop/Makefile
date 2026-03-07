# Makefile for PMSM Open-Loop FOC Firmware

# Toolchain
TOOLCHAIN_PATH = /opt/riscv/bin
TOOLCHAIN_PREFIX = riscv32-unknown-elf

CC = $(TOOLCHAIN_PATH)/$(TOOLCHAIN_PREFIX)-gcc
LD = $(TOOLCHAIN_PATH)/$(TOOLCHAIN_PREFIX)-ld
OBJCOPY = $(TOOLCHAIN_PATH)/$(TOOLCHAIN_PREFIX)-objcopy
OBJDUMP = $(TOOLCHAIN_PATH)/$(TOOLCHAIN_PREFIX)-objdump

# Caravel paths
CARAVEL_ROOT = /nc/templates/caravel
FIRMWARE_PATH = $(CARAVEL_ROOT)/verilog/dv/caravel
GCC_PATH = $(FIRMWARE_PATH)/mgmt_soc
GCC_PREFIX = riscv32

# Include paths
INCLUDES = -I. \
           -I$(FIRMWARE_PATH) \
           -I$(GCC_PATH)

# Compiler flags
CFLAGS = -march=rv32i -mabi=ilp32 -O2 -Wall -Wextra
CFLAGS += $(INCLUDES)
CFLAGS += -ffreestanding -nostdlib
CFLAGS += -DUSE_POWER_PINS

# Linker flags
LDFLAGS = -T linker.ld -nostdlib

# Math library (for sin/cos in software FOC)
LIBS = -lm

# Source files
SOURCES = main.c foc_lib.c isr.c
OBJECTS = $(SOURCES:.c=.o)

# Target
TARGET = main

.PHONY: all clean hex

all: $(TARGET).hex

# Compile C to object files
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Link object files
$(TARGET).elf: $(OBJECTS)
	$(LD) $(LDFLAGS) $(OBJECTS) $(LIBS) -o $@

# Generate hex file
$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O verilog $< $@

# Generate binary
$(TARGET).bin: $(TARGET).elf
	$(OBJCOPY) -O binary $< $@

# Generate disassembly
$(TARGET).dis: $(TARGET).elf
	$(OBJDUMP) -D $< > $@

# Generate hex and binary
hex: $(TARGET).hex $(TARGET).bin $(TARGET).dis

# Clean build artifacts
clean:
	rm -f $(OBJECTS) $(TARGET).elf $(TARGET).hex $(TARGET).bin $(TARGET).dis

# Program info
info:
	@echo "PMSM FOC Firmware Build System"
	@echo "=============================="
	@echo "Toolchain: $(TOOLCHAIN_PREFIX)"
	@echo "Target: RISC-V RV32I"
	@echo "Sources: $(SOURCES)"
	@echo ""
	@echo "Targets:"
	@echo "  make         - Build firmware"
	@echo "  make clean   - Clean build"
	@echo "  make hex     - Generate all output formats"
	@echo "  make info    - Show this information"

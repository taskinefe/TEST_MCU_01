# Verification Plan - Caravel Multi-Peripheral User Project

## Overview
This document outlines the verification strategy for the Caravel multi-peripheral user project integrating:
- 2× SPI Master controllers (CF_SPI)
- 1× I2C Master controller (CF_I2C)
- 2× PWM/Timer controllers (CF_TMR32)
- 1× Programmable Interrupt Controller (WB_PIC)

## Verification Environment
- **Framework:** Caravel-Cocotb
- **Clock Frequency:** 40 MHz (25 ns period)
- **Simulation:** RTL level
- **Synchronization:** Virtual GPIO (VGPIO) handshake mechanism

## Test Strategy

### Phase 1: Basic Integration Test
**Test Name:** `basic_test`
**Objective:** Verify basic Caravel integration and firmware execution

### Phase 2: Individual Peripheral Tests
- `spi0_test` - SPI0 @ 0x3000_0000, GPIO 5-8
- `i2c0_test` - I2C0 @ 0x3001_0000, GPIO 9-10
- `spi1_test` - SPI1 @ 0x3002_0000, GPIO 11-14
- `pwm_test` - PWM0/PWM1 @ 0x3003_0000/0x3004_0000, GPIO 15-16

### Phase 3: System Integration Test
- `system_test` - Multi-peripheral integration

## Coverage Goals
- Wishbone bus addressing and data transfer
- All GPIO pads (5-16) functionality
- Interrupt routing via WB_PIC
- Register access for all peripherals

**Document Version:** 1.0  
**Date:** 2026-03-05

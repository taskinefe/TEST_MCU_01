#ifndef OVERCURRENT_H
#define OVERCURRENT_H

#include <stdint.h>
#include "peripherals.h"

//=============================================================================
// Overcurrent Protection Module
//=============================================================================

#define OCP_BASE          0x30090000  // Peripheral #9

#define OCP_CTRL          (OCP_BASE + 0x00)
#define OCP_DAC           (OCP_BASE + 0x04)
#define OCP_STATUS        (OCP_BASE + 0x08)
#define OCP_FAULT_CLR     (OCP_BASE + 0x0C)

// Control register bits
#define OCP_ENABLE        (1 << 0)
#define OCP_DAC_ENABLE    (1 << 1)

// Status register bits
#define OCP_FAULT_A       (1 << 0)
#define OCP_FAULT_B       (1 << 1)
#define OCP_FAULT_C       (1 << 2)
#define OCP_FAULT_ANY     (1 << 3)

//=============================================================================
// Overcurrent Protection Functions
//=============================================================================

// Initialize overcurrent protection
void ocp_init(void);

// Set overcurrent threshold by voltage (0-3.3V)
void ocp_set_threshold_voltage(float voltage);

// Set overcurrent threshold by current (Amps)
void ocp_set_threshold_current(float current_amps);

// Get current threshold (Volts)
float ocp_get_threshold_voltage(void);

// Get current threshold (Amps)
float ocp_get_threshold_current(void);

// Clear fault and re-enable
void ocp_clear_fault(void);

// Check fault status
uint8_t ocp_check_fault(void);

// Get individual phase faults
uint8_t ocp_get_phase_faults(uint8_t *fault_a, uint8_t *fault_b, uint8_t *fault_c);

// Disable protection (for testing)
void ocp_disable(void);

// Enable protection
void ocp_enable(void);

//=============================================================================
// Conversion Functions
//=============================================================================

// Convert voltage to DAC value
static inline uint8_t voltage_to_dac(float voltage) {
    if (voltage > 3.3f) voltage = 3.3f;
    if (voltage < 0.0f) voltage = 0.0f;
    return (uint8_t)((voltage / 3.3f) * 256.0f);
}

// Convert DAC value to voltage
static inline float dac_to_voltage(uint8_t dac_val) {
    return (dac_val / 256.0f) * 3.3f;
}

// Convert current to voltage (for INA240, G=20, 0.01Ω shunt)
static inline float current_to_voltage(float current_amps) {
    // V = I × R × G + offset
    // V = I × 0.01 × 20 + 1.65
    // V = I × 0.2 + 1.65
    return (current_amps * 0.2f) + 1.65f;
}

// Convert voltage to current
static inline float voltage_to_current(float voltage) {
    // I = (V - 1.65) / 0.2
    return (voltage - 1.65f) / 0.2f;
}

#endif // OVERCURRENT_H

#include "overcurrent.h"

// Current DAC setting
static uint8_t current_dac_value = 0;

//=============================================================================
// Initialize Overcurrent Protection
//=============================================================================

void ocp_init(void) {
    // Disable first
    WRITE_REG(OCP_CTRL, 0);
    
    // Set default threshold to 7A
    ocp_set_threshold_current(7.0f);
    
    // Clear any existing faults
    WRITE_REG(OCP_FAULT_CLR, 0x01);
    
    // Enable protection
    WRITE_REG(OCP_CTRL, OCP_ENABLE | OCP_DAC_ENABLE);
}

//=============================================================================
// Set Threshold by Voltage
//=============================================================================

void ocp_set_threshold_voltage(float voltage) {
    current_dac_value = voltage_to_dac(voltage);
    WRITE_REG(OCP_DAC, current_dac_value);
}

//=============================================================================
// Set Threshold by Current
//=============================================================================

void ocp_set_threshold_current(float current_amps) {
    float voltage = current_to_voltage(current_amps);
    ocp_set_threshold_voltage(voltage);
}

//=============================================================================
// Get Threshold Voltage
//=============================================================================

float ocp_get_threshold_voltage(void) {
    return dac_to_voltage(current_dac_value);
}

//=============================================================================
// Get Threshold Current
//=============================================================================

float ocp_get_threshold_current(void) {
    float voltage = ocp_get_threshold_voltage();
    return voltage_to_current(voltage);
}

//=============================================================================
// Clear Fault
//=============================================================================

void ocp_clear_fault(void) {
    // Write 1 to clear fault
    WRITE_REG(OCP_FAULT_CLR, 0x01);
    
    // Small delay to ensure fault is cleared
    for (volatile int i = 0; i < 100; i++);
}

//=============================================================================
// Check Fault Status
//=============================================================================

uint8_t ocp_check_fault(void) {
    uint32_t status = READ_REG(OCP_STATUS);
    return (status & OCP_FAULT_ANY) ? 1 : 0;
}

//=============================================================================
// Get Phase Faults
//=============================================================================

uint8_t ocp_get_phase_faults(uint8_t *fault_a, uint8_t *fault_b, uint8_t *fault_c) {
    uint32_t status = READ_REG(OCP_STATUS);
    
    *fault_a = (status & OCP_FAULT_A) ? 1 : 0;
    *fault_b = (status & OCP_FAULT_B) ? 1 : 0;
    *fault_c = (status & OCP_FAULT_C) ? 1 : 0;
    
    return (status & OCP_FAULT_ANY) ? 1 : 0;
}

//=============================================================================
// Disable Protection
//=============================================================================

void ocp_disable(void) {
    WRITE_REG(OCP_CTRL, 0);
}

//=============================================================================
// Enable Protection
//=============================================================================

void ocp_enable(void) {
    WRITE_REG(OCP_CTRL, OCP_ENABLE | OCP_DAC_ENABLE);
}

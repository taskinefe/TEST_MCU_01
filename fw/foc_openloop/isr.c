/*
 * Interrupt Service Routines for RISC-V
 * 
 * This file provides true interrupt support for the FOC control loop
 * For use with RISC-V interrupt controller
 */

#include "peripherals.h"
#include "foc_lib.h"

// External references
extern foc_state_t foc_state;
extern foc_params_t foc_params;
extern volatile uint8_t foc_ready;
extern volatile uint32_t isr_count;

//=============================================================================
// RISC-V Interrupt Vector Table
//=============================================================================

// Interrupt handler prototype
void timer_isr(void) __attribute__((interrupt));

// Weak default handlers
void __attribute__((weak, interrupt)) default_handler(void) {
    while(1);  // Trap
}

// Vector table (simplified - adjust based on your RISC-V core)
void (*interrupt_vector_table[])(void) __attribute__((section(".vectors"))) = {
    default_handler,  // 0: Reserved
    default_handler,  // 1: Reserved  
    default_handler,  // 2: Reserved
    timer_isr,        // 3: Timer interrupt (example ID)
    default_handler,  // 4: Reserved
    default_handler,  // 5: Reserved
    default_handler,  // 6: Reserved
    default_handler,  // 7: Reserved
    // Add more as needed...
};

//=============================================================================
// Timer Interrupt Service Routine
//=============================================================================

void timer_isr(void) {
    // Clear timer interrupt flag
    WRITE_REG(TIMER_STATUS, 0x01);
    
    isr_count++;
    
    // Wait for ADC conversion complete (triggered at PWM center)
    // This should be very fast since ADC is triggered at PWM center
    uint32_t timeout = 1000;
    while (!(READ_REG(MOTOR_ADC_STATUS) & 0x01) && timeout--) {
        // Wait with timeout
    }
    
    if (timeout > 0) {
        // ADC data ready, run FOC
        
#if USE_HARDWARE_FOC
        // Hardware-accelerated FOC loop
        foc_loop_hw(&foc_state, &foc_params, VDC);
#else
        // Software-only FOC loop
        uint16_t duty_a, duty_b, duty_c;
        foc_loop_sw(&foc_state, &foc_params, VDC, 
                    &duty_a, &duty_b, &duty_c, PWM_PERIOD);
#endif
        
        foc_ready = 1;
    }
}

//=============================================================================
// Enable RISC-V Interrupts
//=============================================================================

void enable_interrupts(void) {
    // Enable Machine Interrupts (MIE bit in mstatus)
    asm volatile("csrsi mstatus, 0x8");
    
    // Enable specific interrupt sources in mie register
    // Bit 7 = Machine Timer Interrupt
    asm volatile("csrsi mie, 0x80");
}

//=============================================================================
// Disable RISC-V Interrupts  
//=============================================================================

void disable_interrupts(void) {
    // Disable Machine Interrupts
    asm volatile("csrci mstatus, 0x8");
}

//=============================================================================
// Setup Interrupt Vector
//=============================================================================

void setup_interrupts(void) {
    // Set mtvec to point to our vector table
    // Direct mode: mtvec[1:0] = 00
    asm volatile("csrw mtvec, %0" : : "r"(interrupt_vector_table));
    
    // Enable interrupts globally
    enable_interrupts();
}

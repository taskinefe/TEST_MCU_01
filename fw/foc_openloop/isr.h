#ifndef ISR_H
#define ISR_H

//=============================================================================
// Interrupt Service Routine Functions
//=============================================================================

// Setup interrupt vector and enable interrupts
void setup_interrupts(void);

// Enable/disable global interrupts
void enable_interrupts(void);
void disable_interrupts(void);

// Timer ISR (called by hardware)
void timer_isr(void) __attribute__((interrupt));

//=============================================================================
// Configuration
//=============================================================================

// Choose interrupt mode
// 0 = Polled mode (simpler, no interrupt setup needed)
// 1 = Interrupt mode (true interrupt-driven, requires vector setup)
#define USE_INTERRUPTS 0

#endif // ISR_H

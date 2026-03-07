/*
 * PMSM Open-Loop FOC Control with 6-Channel PWM @ 8kHz
 * 
 * Features:
 * - 8 kHz PWM frequency (125µs period)
 * - Center-aligned PWM with dead-time
 * - 3-phase simultaneous current sampling at PWM center
 * - Hardware-accelerated FOC transforms
 * - Open-loop V/F control
 * 
 * Hardware:
 * - Motor PWM: 6 channels (3-phase complementary)
 * - Motor ADC: 3 channels (simultaneous sampling)
 * - FOC Transform Engine: Clarke/Park acceleration
 */

#include "peripherals.h"
#include "foc_lib.h"
#include "overcurrent.h"
#include <defs.h>
#include <stub.h>

//=============================================================================
// Configuration
//=============================================================================

#define PWM_FREQUENCY       8000    // Hz
#define SYSTEM_CLOCK        40000000 // 40 MHz
#define PWM_PERIOD          (SYSTEM_CLOCK / PWM_FREQUENCY)  // 5000 counts
#define DEADTIME_NS         1000    // 1µs dead-time
#define DEADTIME_COUNTS     ((DEADTIME_NS * SYSTEM_CLOCK) / 1000000000)

#define VDC                 24.0f   // DC bus voltage (V)
#define SAMPLE_FREQ         8000.0f // Same as PWM frequency

#define USE_HARDWARE_FOC    1       // 1 = Hardware acceleration, 0 = Software only
#define DEBUG_GPIO          1       // 1 = Enable GPIO debug signals, 0 = Disable

//=============================================================================
// GPIO Debug Pin Assignments
//=============================================================================

#define GPIO_ADC_DONE       29      // Toggle when ADC conversion complete
#define GPIO_FOC_START      30      // Toggle at FOC loop start
#define GPIO_FOC_DONE       31      // Toggle at FOC loop end
#define GPIO_HEARTBEAT      33      // Slow heartbeat

// GPIO toggle macro
#if DEBUG_GPIO
    #define DEBUG_TOGGLE(pin) do { reg_mprj_datal ^= (1 << (pin)); } while(0)
#else
    #define DEBUG_TOGGLE(pin) do {} while(0)
#endif

//=============================================================================
// Global Variables
//=============================================================================

foc_state_t foc_state;
foc_params_t foc_params;

volatile uint8_t foc_ready = 0;
volatile uint32_t isr_count = 0;
volatile uint8_t overcurrent_fault = 0;

// Fault recovery
#define FAULT_RECOVERY_DELAY 8000  // 1 second @ 8kHz
uint32_t fault_recovery_counter = 0;

//=============================================================================
// PWM Initialization
//=============================================================================

void init_motor_pwm(void) {
    // Disable PWM first
    WRITE_REG(MOTOR_PWM_CTRL, 0);
    
    // Set PWM period for 8 kHz
    WRITE_REG(MOTOR_PWM_PERIOD, PWM_PERIOD);
    
    // Set dead-time
    WRITE_REG(MOTOR_PWM_DEADTIME, DEADTIME_COUNTS);
    
    // Initialize duty cycles to 50% (centered, no voltage)
    uint16_t center_duty = PWM_PERIOD / 2;
    WRITE_REG(MOTOR_PWM_DUTY_AH, center_duty);
    WRITE_REG(MOTOR_PWM_DUTY_AL, center_duty);
    WRITE_REG(MOTOR_PWM_DUTY_BH, center_duty);
    WRITE_REG(MOTOR_PWM_DUTY_BL, center_duty);
    WRITE_REG(MOTOR_PWM_DUTY_CH, center_duty);
    WRITE_REG(MOTOR_PWM_DUTY_CL, center_duty);
    
    // Configure PWM
    // - Enable
    // - Center-aligned mode
    // - Dead-time enabled
    // - SVPWM mode (if using hardware SVPWM)
    uint32_t ctrl = PWM_ENABLE | PWM_CENTER_ALIGNED | PWM_DEADTIME_EN;
    
#if USE_HARDWARE_FOC
    ctrl |= PWM_MODE_SVPWM;  // Use hardware SVPWM
#endif
    
    WRITE_REG(MOTOR_PWM_CTRL, ctrl);
}

//=============================================================================
// ADC Initialization
//=============================================================================

void init_motor_adc(void) {
    // Configure ADC for center-aligned trigger
    // - Enable ADC
    // - External trigger (from PWM center)
    // - Trigger at center
    uint32_t ctrl = ADC_ENABLE | ADC_TRIG_EXTERNAL | ADC_TRIG_CENTER;
    WRITE_REG(MOTOR_ADC_CTRL, ctrl);
    
    // Configure trigger source
    WRITE_REG(MOTOR_ADC_TRIG_CTRL, 0x01);  // Trigger from Motor PWM center
}

//=============================================================================
// Timer Initialization (for FOC timing)
//=============================================================================

void init_foc_timer(void) {
    // Configure timer to generate 8 kHz interrupt
    // This synchronizes with PWM period
    
    uint32_t timer_period = (SYSTEM_CLOCK / PWM_FREQUENCY) - 1;
    
    WRITE_REG(TIMER_PRESCALER, 0);  // No prescaler
    WRITE_REG(TIMER_PERIOD, timer_period);
    
    // Enable timer with interrupt and auto-reload
    WRITE_REG(TIMER_CTRL, TIMER_ENABLE | TIMER_IRQ_ENABLE | TIMER_AUTO_RELOAD);
}

//=============================================================================
// GPIO Debug Initialization
//=============================================================================

void init_debug_gpio(void) {
#if DEBUG_GPIO
    // Configure debug GPIO pins as outputs
    reg_mprj_io_29 = GPIO_MODE_MGMT_STD_OUTPUT;  // ADC_DONE
    reg_mprj_io_30 = GPIO_MODE_MGMT_STD_OUTPUT;  // FOC_START
    reg_mprj_io_31 = GPIO_MODE_MGMT_STD_OUTPUT;  // FOC_DONE
    reg_mprj_io_33 = GPIO_MODE_MGMT_STD_OUTPUT;  // HEARTBEAT
    
    // Apply GPIO configuration
    reg_mprj_xfer = 1;
    while (reg_mprj_xfer == 1);
    
    // Initialize all low
    reg_mprj_datal &= ~((1 << GPIO_ADC_DONE) | (1 << GPIO_FOC_START) | 
                        (1 << GPIO_FOC_DONE) | (1 << GPIO_HEARTBEAT));
#endif
}

//=============================================================================
// Interrupt Handling
//=============================================================================

// Note: In a polled implementation, we don't use actual interrupts
// Instead, we check the timer flag in the main loop for simplicity
// For true interrupt-driven operation, you would need:
// 1. RISC-V interrupt vector table
// 2. Trap handler setup
// 3. Timer interrupt routing

// For this demo, we use a polled approach which is simpler and sufficient

//=============================================================================
// FOC Processing Function (called every PWM period)
//=============================================================================

void foc_process(void) {
    isr_count++;
    
    // Check for overcurrent fault
    if (ocp_check_fault()) {
        overcurrent_fault = 1;
        // PWM already shutdown by hardware
        // Just wait for recovery
        return;
    }
    
    // Mark FOC loop start
    DEBUG_TOGGLE(GPIO_FOC_START);
    
    // Wait for ADC conversion complete (triggered at PWM center)
    while (!(READ_REG(MOTOR_ADC_STATUS) & 0x01));
    
    // ADC conversion complete! Toggle debug GPIO
    DEBUG_TOGGLE(GPIO_ADC_DONE);
    
#if USE_HARDWARE_FOC
    // Hardware-accelerated FOC loop
    foc_loop_hw(&foc_state, &foc_params, VDC);
#else
    // Software-only FOC loop
    uint16_t duty_a, duty_b, duty_c;
    foc_loop_sw(&foc_state, &foc_params, VDC, 
                &duty_a, &duty_b, &duty_c, PWM_PERIOD);
#endif
    
    // Mark FOC loop complete
    DEBUG_TOGGLE(GPIO_FOC_DONE);
    
    foc_ready = 1;
}

//=============================================================================
// Main Function
//=============================================================================

void main(void) {
    // Initialize debug GPIO
    init_debug_gpio();
    
    //=========================================================================
    // Initialize FOC
    //=========================================================================
    
    // Initialize FOC parameters
    foc_init_params(&foc_params);
    
    // Configure for open-loop operation
    foc_params.id_ref = 0.0f;           // No field weakening
    foc_params.iq_ref = 0.0f;           // Start with zero torque
    foc_params.open_loop_speed = 5.0f;  // 5 rad/s electrical (slow start)
    foc_params.open_loop_vq = 2.0f;     // 2V Q-axis voltage
    
    // Initialize FOC state
    foc_init_state(&foc_state, SAMPLE_FREQ);
    
    //=========================================================================
    // Initialize Hardware
    //=========================================================================
    
    // Initialize Motor PWM (8 kHz, center-aligned, dead-time)
    init_motor_pwm();
    
    // Initialize Motor ADC (center-aligned sampling)
    init_motor_adc();
    
    // Initialize FOC timer (8 kHz interrupt)
    init_foc_timer();
    
    // Initialize overcurrent protection (7A threshold)
    ocp_init();
    
    //=========================================================================
    // Open-Loop FOC Control Loop
    //=========================================================================
    
    uint32_t ramp_counter = 0;
    uint32_t heartbeat_counter = 0;
    const uint32_t RAMP_STEPS = 5000;  // Ramp up over 5000 samples (~625ms @ 8kHz)
    
    // In open-loop FOC, we set Vq directly instead of using PI controllers
    foc_params.vq = 0.0f;  // Start voltage
    foc_params.vd = 0.0f;  // No D-axis voltage
    
    while (1) {
        // Poll timer flag (8 kHz rate)
        // In production, this could be interrupt-driven
        if (READ_REG(TIMER_STATUS) & 0x01) {
            // Clear timer flag
            WRITE_REG(TIMER_STATUS, 0x01);
            
            // Process FOC
            foc_process();
        }
        
        // Handle overcurrent fault recovery
        if (overcurrent_fault) {
            // Wait for recovery delay
            if (++fault_recovery_counter >= FAULT_RECOVERY_DELAY) {
                // Get fault details
                uint8_t fa, fb, fc;
                ocp_get_phase_faults(&fa, &fb, &fc);
                
                // Clear fault
                ocp_clear_fault();
                overcurrent_fault = 0;
                fault_recovery_counter = 0;
                
                // Reset FOC state
                foc_state.vd = 0.0f;
                foc_state.vq = 0.0f;
                ramp_counter = 0;  // Restart ramp
                
                // Re-enable PWM (will start on next FOC cycle)
                init_motor_pwm();
                
                // Indicate recovery
                DEBUG_TOGGLE(GPIO_HEARTBEAT);
            }
            continue;  // Skip FOC until recovered
        }
        
        // Process FOC results when ready
        if (foc_ready) {
            foc_ready = 0;
            
            // Ramp up Vq for smooth start
            if (ramp_counter < RAMP_STEPS) {
                foc_params.vq = foc_params.open_loop_vq * 
                                ((float)ramp_counter / (float)RAMP_STEPS);
                ramp_counter++;
                
                // Override PI controller outputs for open-loop
                foc_state.vd = foc_params.vd;
                foc_state.vq = foc_params.vq;
            } else {
                // Steady-state open-loop
                foc_state.vd = foc_params.vd;
                foc_state.vq = foc_params.vq;
            }
            
            // Heartbeat every 1000 samples (125ms @ 8kHz)
            if (++heartbeat_counter >= 1000) {
                DEBUG_TOGGLE(GPIO_HEARTBEAT);
                heartbeat_counter = 0;
            }
            
            // Speed change example: ramp to higher speed after 2 seconds
            if (isr_count == 16000) {  // 2 seconds @ 8kHz
                foc_params.open_loop_speed = 20.0f;  // Increase to 20 rad/s
                foc_params.open_loop_vq = 4.0f;      // Increase voltage
                ramp_counter = 0;  // Restart ramp
            }
            
            // Speed change: ramp to even higher speed after 4 seconds
            if (isr_count == 32000) {  // 4 seconds @ 8kHz
                foc_params.open_loop_speed = 50.0f;  // 50 rad/s
                foc_params.open_loop_vq = 8.0f;      // Higher voltage
                ramp_counter = 0;
            }
        }
    }
}

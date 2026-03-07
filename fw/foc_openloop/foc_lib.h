#ifndef FOC_LIB_H
#define FOC_LIB_H

#include "peripherals.h"
#include <math.h>

//=============================================================================
// FOC Parameters
//=============================================================================

typedef struct {
    // Current setpoints (A)
    float id_ref;
    float iq_ref;
    
    // PI controller parameters - D axis
    float kp_d;
    float ki_d;
    float d_integral;
    float d_max_integral;
    
    // PI controller parameters - Q axis
    float kp_q;
    float ki_q;
    float q_integral;
    float q_max_integral;
    
    // Output limits
    float vd_max;
    float vq_max;
    
    // Motor parameters
    float pole_pairs;
    float rated_current;  // A
    float max_voltage;    // V
    
    // Open-loop parameters
    float open_loop_speed;  // rad/s (electrical)
    float open_loop_vq;     // V
    
} foc_params_t;

//=============================================================================
// FOC State
//=============================================================================

typedef struct {
    // Measured currents (A)
    float ia, ib, ic;
    
    // Clarke transform outputs
    float i_alpha, i_beta;
    
    // Park transform outputs
    float id, iq;
    
    // Controller outputs
    float vd, vq;
    
    // Inverse Park outputs
    float v_alpha, v_beta;
    
    // Rotor angle
    float theta_electrical;  // radians
    
    // Timing
    uint32_t sample_count;
    float dt;  // Sample time (s)
    
} foc_state_t;

//=============================================================================
// FOC Functions
//=============================================================================

// Initialize FOC parameters with defaults
void foc_init_params(foc_params_t *params);

// Initialize FOC state
void foc_init_state(foc_state_t *state, float sample_freq);

// Read 3-phase currents from ADC
void foc_read_currents(foc_state_t *state, float adc_scale);

// Hardware Clarke Transform (abc → αβ)
void foc_clarke_hw(foc_state_t *state);

// Software Clarke Transform (abc → αβ)
void foc_clarke_sw(foc_state_t *state);

// Hardware Park Transform (αβ → dq)
void foc_park_hw(foc_state_t *state);

// Software Park Transform (αβ → dq)
void foc_park_sw(foc_state_t *state);

// PI Controller
void foc_pi_control(foc_state_t *state, foc_params_t *params);

// Hardware Inverse Park (dq → αβ)
void foc_inv_park_hw(foc_state_t *state);

// Software Inverse Park (dq → αβ)
void foc_inv_park_sw(foc_state_t *state);

// Hardware SVPWM
void foc_svpwm_hw(foc_state_t *state, float vdc);

// Software SVPWM calculation
void foc_svpwm_sw(foc_state_t *state, float vdc, 
                  uint16_t *duty_a, uint16_t *duty_b, uint16_t *duty_c,
                  uint16_t period);

// Open-loop angle update
void foc_update_openloop_angle(foc_state_t *state, foc_params_t *params);

// Complete FOC loop (hardware accelerated)
void foc_loop_hw(foc_state_t *state, foc_params_t *params, float vdc);

// Complete FOC loop (software only)
void foc_loop_sw(foc_state_t *state, foc_params_t *params, float vdc,
                 uint16_t *duty_a, uint16_t *duty_b, uint16_t *duty_c,
                 uint16_t period);

#endif // FOC_LIB_H

#include "foc_lib.h"
#include <string.h>

#define PI 3.14159265f
#define SQRT3 1.732050808f
#define INV_SQRT3 0.577350269f
#define TWO_PI 6.28318531f

//=============================================================================
// Initialize FOC Parameters
//=============================================================================

void foc_init_params(foc_params_t *params) {
    memset(params, 0, sizeof(foc_params_t));
    
    // Default setpoints
    params->id_ref = 0.0f;      // Field weakening (typically 0 for PMSM)
    params->iq_ref = 0.5f;      // Torque current (A)
    
    // PI controller gains (tune for your motor)
    params->kp_d = 0.5f;
    params->ki_d = 50.0f;
    params->kp_q = 0.5f;
    params->ki_q = 50.0f;
    
    // Integral limits
    params->d_max_integral = 10.0f;
    params->q_max_integral = 10.0f;
    
    // Output limits
    params->vd_max = 12.0f;     // V
    params->vq_max = 12.0f;     // V
    
    // Motor parameters
    params->pole_pairs = 4.0f;
    params->rated_current = 5.0f;
    params->max_voltage = 24.0f;
    
    // Open-loop parameters
    params->open_loop_speed = 10.0f;  // rad/s (electrical)
    params->open_loop_vq = 2.0f;      // V
}

//=============================================================================
// Initialize FOC State
//=============================================================================

void foc_init_state(foc_state_t *state, float sample_freq) {
    memset(state, 0, sizeof(foc_state_t));
    state->dt = 1.0f / sample_freq;
}

//=============================================================================
// Read 3-Phase Currents
//=============================================================================

void foc_read_currents(foc_state_t *state, float adc_scale) {
    // Read ADC values (12-bit, 0-4095)
    uint32_t adc_a = READ_REG(MOTOR_ADC_PHASE_A) & 0xFFF;
    uint32_t adc_b = READ_REG(MOTOR_ADC_PHASE_B) & 0xFFF;
    uint32_t adc_c = READ_REG(MOTOR_ADC_PHASE_C) & 0xFFF;
    
    // Convert to current (A)
    // Assuming 1.65V offset, 0.165V/A sensitivity (INA240 with 0.01R shunt, G=20)
    state->ia = ((adc_a / 4095.0f) * 3.3f - 1.65f) / adc_scale;
    state->ib = ((adc_b / 4095.0f) * 3.3f - 1.65f) / adc_scale;
    state->ic = ((adc_c / 4095.0f) * 3.3f - 1.65f) / adc_scale;
}

//=============================================================================
// Hardware Clarke Transform
//=============================================================================

void foc_clarke_hw(foc_state_t *state) {
    // Convert currents to Q15
    float max_current = 10.0f;  // Normalization factor
    q15_t ia_q15 = float_to_q15(state->ia / max_current);
    q15_t ib_q15 = float_to_q15(state->ib / max_current);
    q15_t ic_q15 = float_to_q15(state->ic / max_current);
    
    // Write inputs
    WRITE_REG(FOC_IA, ia_q15);
    WRITE_REG(FOC_IB, ib_q15);
    WRITE_REG(FOC_IC, ic_q15);
    
    // Start Clarke transform
    WRITE_REG(FOC_CTRL, FOC_ENABLE | FOC_MODE_CLARKE | FOC_START);
    
    // Wait for completion (1-2 cycles, very fast)
    while (!(READ_REG(FOC_STATUS) & 0x01));
    
    // Read results
    q15_t alpha_q15 = (q15_t)READ_REG(FOC_ALPHA_OUT);
    q15_t beta_q15 = (q15_t)READ_REG(FOC_BETA_OUT);
    
    // Convert back to float
    state->i_alpha = q15_to_float(alpha_q15) * max_current;
    state->i_beta = q15_to_float(beta_q15) * max_current;
}

//=============================================================================
// Software Clarke Transform
//=============================================================================

void foc_clarke_sw(foc_state_t *state) {
    // α = Ia
    state->i_alpha = state->ia;
    
    // β = (Ia + 2*Ib) / sqrt(3)
    state->i_beta = (state->ia + 2.0f * state->ib) * INV_SQRT3;
}

//=============================================================================
// Hardware Park Transform
//=============================================================================

void foc_park_hw(foc_state_t *state) {
    // Convert to Q15
    float max_current = 10.0f;
    q15_t alpha_q15 = float_to_q15(state->i_alpha / max_current);
    q15_t beta_q15 = float_to_q15(state->i_beta / max_current);
    q15_t theta_q15 = angle_to_q15(state->theta_electrical);
    
    // Write inputs
    WRITE_REG(FOC_ALPHA_IN, alpha_q15);
    WRITE_REG(FOC_BETA_IN, beta_q15);
    WRITE_REG(FOC_THETA, theta_q15);
    
    // Start Park transform
    WRITE_REG(FOC_CTRL, FOC_ENABLE | FOC_MODE_PARK | FOC_START);
    
    // Wait
    while (!(READ_REG(FOC_STATUS) & 0x01));
    
    // Read results
    q15_t d_q15 = (q15_t)READ_REG(FOC_D_OUT);
    q15_t q_q15 = (q15_t)READ_REG(FOC_Q_OUT);
    
    state->id = q15_to_float(d_q15) * max_current;
    state->iq = q15_to_float(q_q15) * max_current;
}

//=============================================================================
// Software Park Transform
//=============================================================================

void foc_park_sw(foc_state_t *state) {
    float cos_theta = cosf(state->theta_electrical);
    float sin_theta = sinf(state->theta_electrical);
    
    // d =  α*cos(θ) + β*sin(θ)
    state->id = state->i_alpha * cos_theta + state->i_beta * sin_theta;
    
    // q = -α*sin(θ) + β*cos(θ)
    state->iq = -state->i_alpha * sin_theta + state->i_beta * cos_theta;
}

//=============================================================================
// PI Controller
//=============================================================================

void foc_pi_control(foc_state_t *state, foc_params_t *params) {
    // D-axis PI controller
    float error_d = params->id_ref - state->id;
    params->d_integral += error_d * state->dt;
    
    // Anti-windup
    if (params->d_integral > params->d_max_integral) 
        params->d_integral = params->d_max_integral;
    if (params->d_integral < -params->d_max_integral) 
        params->d_integral = -params->d_max_integral;
    
    state->vd = params->kp_d * error_d + params->ki_d * params->d_integral;
    
    // Limit output
    if (state->vd > params->vd_max) state->vd = params->vd_max;
    if (state->vd < -params->vd_max) state->vd = -params->vd_max;
    
    // Q-axis PI controller
    float error_q = params->iq_ref - state->iq;
    params->q_integral += error_q * state->dt;
    
    // Anti-windup
    if (params->q_integral > params->q_max_integral) 
        params->q_integral = params->q_max_integral;
    if (params->q_integral < -params->q_max_integral) 
        params->q_integral = -params->q_max_integral;
    
    state->vq = params->kp_q * error_q + params->ki_q * params->q_integral;
    
    // Limit output
    if (state->vq > params->vq_max) state->vq = params->vq_max;
    if (state->vq < -params->vq_max) state->vq = -params->vq_max;
}

//=============================================================================
// Hardware Inverse Park
//=============================================================================

void foc_inv_park_hw(foc_state_t *state) {
    // Convert to Q15 (normalized to max voltage)
    float max_voltage = 24.0f;
    q15_t d_q15 = float_to_q15(state->vd / max_voltage);
    q15_t q_q15 = float_to_q15(state->vq / max_voltage);
    q15_t theta_q15 = angle_to_q15(state->theta_electrical);
    
    // Write inputs
    WRITE_REG(FOC_D_IN, d_q15);
    WRITE_REG(FOC_Q_IN, q_q15);
    WRITE_REG(FOC_THETA, theta_q15);
    
    // Start Inverse Park
    WRITE_REG(FOC_CTRL, FOC_ENABLE | FOC_MODE_INV_PARK | FOC_START);
    
    // Wait
    while (!(READ_REG(FOC_STATUS) & 0x01));
    
    // Read results
    q15_t alpha_q15 = (q15_t)READ_REG(FOC_ALPHA_OUT);
    q15_t beta_q15 = (q15_t)READ_REG(FOC_BETA_OUT);
    
    state->v_alpha = q15_to_float(alpha_q15) * max_voltage;
    state->v_beta = q15_to_float(beta_q15) * max_voltage;
}

//=============================================================================
// Software Inverse Park
//=============================================================================

void foc_inv_park_sw(foc_state_t *state) {
    float cos_theta = cosf(state->theta_electrical);
    float sin_theta = sinf(state->theta_electrical);
    
    // α = d*cos(θ) - q*sin(θ)
    state->v_alpha = state->vd * cos_theta - state->vq * sin_theta;
    
    // β = d*sin(θ) + q*cos(θ)
    state->v_beta = state->vd * sin_theta + state->vq * cos_theta;
}

//=============================================================================
// Hardware SVPWM
//=============================================================================

void foc_svpwm_hw(foc_state_t *state, float vdc) {
    // Convert to Q15 (normalized to VDC)
    q15_t alpha_q15 = float_to_q15(state->v_alpha / vdc);
    q15_t beta_q15 = float_to_q15(state->v_beta / vdc);
    
    // Write to SVPWM registers
    WRITE_REG(MOTOR_PWM_SVPWM_ALPHA, alpha_q15);
    WRITE_REG(MOTOR_PWM_SVPWM_BETA, beta_q15);
    
    // Enable SVPWM mode
    SET_BITS(MOTOR_PWM_SVPWM_CTRL, (1 << 0));  // SVPWM enable
}

//=============================================================================
// Software SVPWM
//=============================================================================

void foc_svpwm_sw(foc_state_t *state, float vdc, 
                  uint16_t *duty_a, uint16_t *duty_b, uint16_t *duty_c,
                  uint16_t period) {
    // Normalize voltages
    float v_alpha_norm = state->v_alpha / vdc;
    float v_beta_norm = state->v_beta / vdc;
    
    // Calculate duty cycles (simplified SVPWM)
    float t_a = v_alpha_norm;
    float t_b = -0.5f * v_alpha_norm + SQRT3 / 2.0f * v_beta_norm;
    float t_c = -0.5f * v_alpha_norm - SQRT3 / 2.0f * v_beta_norm;
    
    // Normalize to 0-1 range
    float offset = 0.5f - (t_a > t_b ? (t_a > t_c ? t_a : t_c) : (t_b > t_c ? t_b : t_c));
    
    t_a += offset;
    t_b += offset;
    t_c += offset;
    
    // Convert to duty cycle
    *duty_a = (uint16_t)(t_a * period);
    *duty_b = (uint16_t)(t_b * period);
    *duty_c = (uint16_t)(t_c * period);
    
    // Clamp
    if (*duty_a > period) *duty_a = period;
    if (*duty_b > period) *duty_b = period;
    if (*duty_c > period) *duty_c = period;
}

//=============================================================================
// Open-Loop Angle Update
//=============================================================================

void foc_update_openloop_angle(foc_state_t *state, foc_params_t *params) {
    // Update electrical angle
    state->theta_electrical += params->open_loop_speed * state->dt;
    
    // Wrap to 0-2π
    while (state->theta_electrical > TWO_PI) {
        state->theta_electrical -= TWO_PI;
    }
    while (state->theta_electrical < 0.0f) {
        state->theta_electrical += TWO_PI;
    }
    
    state->sample_count++;
}

//=============================================================================
// Complete Hardware-Accelerated FOC Loop
//=============================================================================

void foc_loop_hw(foc_state_t *state, foc_params_t *params, float vdc) {
    // 1. Read currents
    foc_read_currents(state, 0.165f);
    
    // 2. Clarke transform (Hardware)
    foc_clarke_hw(state);
    
    // 3. Park transform (Hardware)
    foc_park_hw(state);
    
    // 4. PI controllers (Software - fast enough)
    foc_pi_control(state, params);
    
    // 5. Inverse Park (Hardware)
    foc_inv_park_hw(state);
    
    // 6. SVPWM (Hardware)
    foc_svpwm_hw(state, vdc);
    
    // 7. Update open-loop angle
    foc_update_openloop_angle(state, params);
}

//=============================================================================
// Complete Software FOC Loop
//=============================================================================

void foc_loop_sw(foc_state_t *state, foc_params_t *params, float vdc,
                 uint16_t *duty_a, uint16_t *duty_b, uint16_t *duty_c,
                 uint16_t period) {
    // 1. Read currents
    foc_read_currents(state, 0.165f);
    
    // 2. Clarke transform (Software)
    foc_clarke_sw(state);
    
    // 3. Park transform (Software)
    foc_park_sw(state);
    
    // 4. PI controllers
    foc_pi_control(state, params);
    
    // 5. Inverse Park (Software)
    foc_inv_park_sw(state);
    
    // 6. SVPWM (Software)
    foc_svpwm_sw(state, vdc, duty_a, duty_b, duty_c, period);
    
    // Write duty cycles
    WRITE_REG(MOTOR_PWM_DUTY_AH, *duty_a);
    WRITE_REG(MOTOR_PWM_DUTY_BH, *duty_b);
    WRITE_REG(MOTOR_PWM_DUTY_CH, *duty_c);
    
    // 7. Update open-loop angle
    foc_update_openloop_angle(state, params);
}

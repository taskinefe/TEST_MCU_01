#ifndef PERIPHERALS_H
#define PERIPHERALS_H

#include <stdint.h>

//=============================================================================
// Peripheral Base Addresses
//=============================================================================

#define MOTOR_PWM_BASE    0x30090000
#define MOTOR_ADC_BASE    0x30070000
#define FOC_TRANS_BASE    0x300C0000
#define SVPWM_BASE        0x30090000  // Combined with Motor PWM
#define GP_TIMER_BASE     0x300A0000

//=============================================================================
// Motor PWM + SVPWM Registers
//=============================================================================

#define MOTOR_PWM_CTRL        (MOTOR_PWM_BASE + 0x00)
#define MOTOR_PWM_PERIOD      (MOTOR_PWM_BASE + 0x04)
#define MOTOR_PWM_DEADTIME    (MOTOR_PWM_BASE + 0x08)
#define MOTOR_PWM_DUTY_AH     (MOTOR_PWM_BASE + 0x0C)
#define MOTOR_PWM_DUTY_AL     (MOTOR_PWM_BASE + 0x10)
#define MOTOR_PWM_DUTY_BH     (MOTOR_PWM_BASE + 0x14)
#define MOTOR_PWM_DUTY_BL     (MOTOR_PWM_BASE + 0x18)
#define MOTOR_PWM_DUTY_CH     (MOTOR_PWM_BASE + 0x1C)
#define MOTOR_PWM_DUTY_CL     (MOTOR_PWM_BASE + 0x20)
#define MOTOR_PWM_SVPWM_CTRL  (MOTOR_PWM_BASE + 0x24)
#define MOTOR_PWM_SVPWM_ALPHA (MOTOR_PWM_BASE + 0x28)
#define MOTOR_PWM_SVPWM_BETA  (MOTOR_PWM_BASE + 0x2C)
#define MOTOR_PWM_STATUS      (MOTOR_PWM_BASE + 0x30)

// PWM Control bits
#define PWM_ENABLE            (1 << 0)
#define PWM_MODE_SVPWM        (1 << 1)
#define PWM_CENTER_ALIGNED    (1 << 2)
#define PWM_DEADTIME_EN       (1 << 3)

//=============================================================================
// Motor ADC (3-channel) Registers
//=============================================================================

#define MOTOR_ADC_CTRL        (MOTOR_ADC_BASE + 0x00)
#define MOTOR_ADC_TRIG_CTRL   (MOTOR_ADC_BASE + 0x04)
#define MOTOR_ADC_PHASE_A     (MOTOR_ADC_BASE + 0x08)
#define MOTOR_ADC_PHASE_B     (MOTOR_ADC_BASE + 0x0C)
#define MOTOR_ADC_PHASE_C     (MOTOR_ADC_BASE + 0x10)
#define MOTOR_ADC_STATUS      (MOTOR_ADC_BASE + 0x14)

// ADC Control bits
#define ADC_ENABLE            (1 << 0)
#define ADC_TRIG_EXTERNAL     (1 << 1)
#define ADC_TRIG_CENTER       (1 << 2)

//=============================================================================
// FOC Transform Engine Registers
//=============================================================================

#define FOC_CTRL              (FOC_TRANS_BASE + 0x00)
#define FOC_IA                (FOC_TRANS_BASE + 0x04)
#define FOC_IB                (FOC_TRANS_BASE + 0x08)
#define FOC_IC                (FOC_TRANS_BASE + 0x0C)
#define FOC_ALPHA_IN          (FOC_TRANS_BASE + 0x10)
#define FOC_BETA_IN           (FOC_TRANS_BASE + 0x14)
#define FOC_D_IN              (FOC_TRANS_BASE + 0x18)
#define FOC_Q_IN              (FOC_TRANS_BASE + 0x1C)
#define FOC_THETA             (FOC_TRANS_BASE + 0x20)
#define FOC_ALPHA_OUT         (FOC_TRANS_BASE + 0x24)
#define FOC_BETA_OUT          (FOC_TRANS_BASE + 0x28)
#define FOC_D_OUT             (FOC_TRANS_BASE + 0x2C)
#define FOC_Q_OUT             (FOC_TRANS_BASE + 0x30)
#define FOC_IA_OUT            (FOC_TRANS_BASE + 0x34)
#define FOC_IB_OUT            (FOC_TRANS_BASE + 0x38)
#define FOC_IC_OUT            (FOC_TRANS_BASE + 0x3C)
#define FOC_STATUS            (FOC_TRANS_BASE + 0x40)

// FOC Transform modes
#define FOC_MODE_CLARKE       (0 << 1)  // abc → αβ
#define FOC_MODE_INV_CLARKE   (1 << 1)  // αβ → abc
#define FOC_MODE_PARK         (2 << 1)  // αβ → dq
#define FOC_MODE_INV_PARK     (3 << 1)  // dq → αβ

#define FOC_ENABLE            (1 << 0)
#define FOC_START             (1 << 3)

//=============================================================================
// GP Timer Registers (for FOC timing)
//=============================================================================

#define TIMER_CTRL            (GP_TIMER_BASE + 0x00)
#define TIMER_PRESCALER       (GP_TIMER_BASE + 0x04)
#define TIMER_PERIOD          (GP_TIMER_BASE + 0x08)
#define TIMER_COUNTER         (GP_TIMER_BASE + 0x0C)
#define TIMER_COMPARE         (GP_TIMER_BASE + 0x10)
#define TIMER_STATUS          (GP_TIMER_BASE + 0x14)

#define TIMER_ENABLE          (1 << 0)
#define TIMER_IRQ_ENABLE      (1 << 1)
#define TIMER_AUTO_RELOAD     (1 << 2)

//=============================================================================
// Helper Macros
//=============================================================================

#define REG32(addr) (*((volatile uint32_t *)(addr)))
#define REG16(addr) (*((volatile uint16_t *)(addr)))

// Write to 32-bit register
#define WRITE_REG(addr, val) REG32(addr) = (val)

// Read from 32-bit register
#define READ_REG(addr) REG32(addr)

// Set bits in register
#define SET_BITS(addr, bits) REG32(addr) |= (bits)

// Clear bits in register
#define CLR_BITS(addr, bits) REG32(addr) &= ~(bits)

//=============================================================================
// Fixed-Point Math (Q15 format)
//=============================================================================

typedef int16_t q15_t;

// Convert float to Q15
static inline q15_t float_to_q15(float x) {
    if (x > 0.999f) x = 0.999f;
    if (x < -1.0f) x = -1.0f;
    return (q15_t)(x * 32768.0f);
}

// Convert Q15 to float
static inline float q15_to_float(q15_t x) {
    return (float)x / 32768.0f;
}

// Convert angle (radians) to Q15 (normalized to π)
static inline q15_t angle_to_q15(float angle_rad) {
    float normalized = angle_rad / 3.14159265f;
    return float_to_q15(normalized);
}

// Convert Q15 angle to radians
static inline float q15_to_angle(q15_t q15_angle) {
    return q15_to_float(q15_angle) * 3.14159265f;
}

#endif // PERIPHERALS_H

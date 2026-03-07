#ifndef _USER_PERIPH_H_
#define _USER_PERIPH_H_

#include <stdint.h>

#define SPI0_BASE     0x30000000
#define I2C0_BASE     0x30010000
#define SPI1_BASE     0x30020000
#define PWM0_BASE     0x30030000
#define PWM1_BASE     0x30040000
#define PIC_BASE      0x30050000

#define SPI_RXDATA              0x0000
#define SPI_TXDATA              0x0004
#define SPI_CFG                 0x0008
#define SPI_CTRL                0x000C
#define SPI_PR                  0x0010
#define SPI_STATUS              0x0014
#define SPI_RX_FIFO_LEVEL       0xFE00
#define SPI_RX_FIFO_THRESHOLD   0xFE04
#define SPI_RX_FIFO_FLUSH       0xFE08
#define SPI_TX_FIFO_LEVEL       0xFE10
#define SPI_TX_FIFO_THRESHOLD   0xFE14
#define SPI_TX_FIFO_FLUSH       0xFE18
#define SPI_IM                  0xFF00
#define SPI_MIS                 0xFF04
#define SPI_RIS                 0xFF08
#define SPI_IC                  0xFF0C

#define SPI_STATUS_RX_EMPTY     (1 << 0)
#define SPI_STATUS_TX_EMPTY     (1 << 1)
#define SPI_STATUS_RX_FULL      (1 << 2)
#define SPI_STATUS_TX_FULL      (1 << 3)

#define SPI_CFG_CPOL            (1 << 0)
#define SPI_CFG_CPHA            (1 << 1)

#define I2C_RXDATA              0x0000
#define I2C_TXDATA              0x0004
#define I2C_PR                  0x0008
#define I2C_CTRL                0x000C
#define I2C_STATUS              0x0010
#define I2C_IM                  0xFF00
#define I2C_MIS                 0xFF04
#define I2C_RIS                 0xFF08
#define I2C_IC                  0xFF0C

#define I2C_CTRL_START          (1 << 0)
#define I2C_CTRL_STOP           (1 << 1)
#define I2C_CTRL_RD             (1 << 2)
#define I2C_CTRL_WR             (1 << 3)
#define I2C_CTRL_ACK            (1 << 4)
#define I2C_CTRL_EN             (1 << 6)

#define I2C_STATUS_TIP          (1 << 0)
#define I2C_STATUS_BUSY         (1 << 1)
#define I2C_STATUS_RX_ACK       (1 << 5)

#define TMR_TMR                 0x0000
#define TMR_RELOAD              0x0004
#define TMR_PR                  0x0008
#define TMR_CTRL                0x000C
#define TMR_CMP0                0x0010
#define TMR_CMP1                0x0014
#define TMR_IM                  0xFF00
#define TMR_MIS                 0xFF04
#define TMR_RIS                 0xFF08
#define TMR_IC                  0xFF0C

#define TMR_CTRL_EN             (1 << 0)
#define TMR_CTRL_PWM_EN         (1 << 1)
#define TMR_CTRL_ONE_SHOT       (1 << 2)
#define TMR_CTRL_DIR            (1 << 3)

#define PIC_IRQ_ENABLE          0x0000
#define PIC_IRQ_PENDING         0x0004
#define PIC_IRQ_CLEAR           0x0008
#define PIC_GLOBAL_ENABLE       0x000C
#define PIC_IRQ_PRIORITY_0      0x0010

static inline void reg_write(uint32_t addr, uint32_t data) {
    *((volatile uint32_t*)addr) = data;
}

static inline uint32_t reg_read(uint32_t addr) {
    return *((volatile uint32_t*)addr);
}

void spi0_init(uint8_t prescaler, uint8_t cpol, uint8_t cpha);
void spi0_transfer(uint8_t data_out, uint8_t* data_in);

void i2c0_init(uint16_t prescaler);
void i2c0_write(uint8_t addr, uint8_t data);
uint8_t i2c0_read(uint8_t addr);

void pwm0_init(uint32_t period, uint32_t duty);
void pwm1_init(uint32_t period, uint32_t duty);

void pic_init(void);
void pic_enable_irq(uint8_t irq_num);
void pic_clear_irq(uint8_t irq_num);

#endif

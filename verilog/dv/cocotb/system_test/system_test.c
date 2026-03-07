#include <firmware_apis.h>

#define VGPIO_REG_ADDR 0x30FFFFFC

#define SPI0_BASE 0x30000000
#define I2C0_BASE 0x30010000
#define SPI1_BASE 0x30020000
#define PWM0_BASE 0x30030000
#define PWM1_BASE 0x30040000
#define PIC_BASE  0x30050000

#define SPI_RXDATA    0x0000
#define SPI_TXDATA    0x0004
#define SPI_CFG       0x0008
#define SPI_STATUS    0x0014

#define TMR_RELOAD    0x0004
#define TMR_PR        0x0008
#define TMR_CTRL      0x000C
#define TMR_CMP0      0x0010

void vgpio_write_output(uint16_t value)
{
    volatile uint32_t *vgpio_reg = (volatile uint32_t *)VGPIO_REG_ADDR;
    uint32_t reg_val = *vgpio_reg;
    reg_val = (reg_val & 0xFFFF0000) | (value & 0xFFFF);
    *vgpio_reg = reg_val;
}

void main(void)
{
    enableHkSpi(false);
    
    GPIOs_configure(5, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(6, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(7, GPIO_MODE_USER_STD_INPUT_NOPULL);
    GPIOs_configure(8, GPIO_MODE_USER_STD_OUTPUT);
    
    GPIOs_configure(9, GPIO_MODE_USER_STD_BIDIRECTIONAL);
    GPIOs_configure(10, GPIO_MODE_USER_STD_BIDIRECTIONAL);
    
    GPIOs_configure(11, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(12, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(13, GPIO_MODE_USER_STD_INPUT_NOPULL);
    GPIOs_configure(14, GPIO_MODE_USER_STD_OUTPUT);
    
    GPIOs_configure(15, GPIO_MODE_USER_STD_OUTPUT);
    GPIOs_configure(16, GPIO_MODE_USER_STD_OUTPUT);
    
    GPIOs_loadConfigs();
    
    User_enableIF();
    
    vgpio_write_output(1);
    
    uint32_t spi0_status = USER_readWord(SPI_STATUS >> 2);
    
    USER_writeWord(0x3, SPI_CFG >> 2);
    
    USER_writeWord(0xAA, SPI_TXDATA >> 2);
    
    vgpio_write_output(2);
    
    USER_writeWord(1000, ((PWM0_BASE - SPI0_BASE) + TMR_RELOAD) >> 2);
    USER_writeWord(500, ((PWM0_BASE - SPI0_BASE) + TMR_CMP0) >> 2);
    USER_writeWord(0x03, ((PWM0_BASE - SPI0_BASE) + TMR_CTRL) >> 2);
    
    USER_writeWord(2000, ((PWM1_BASE - SPI0_BASE) + TMR_RELOAD) >> 2);
    USER_writeWord(1500, ((PWM1_BASE - SPI0_BASE) + TMR_CMP0) >> 2);
    USER_writeWord(0x03, ((PWM1_BASE - SPI0_BASE) + TMR_CTRL) >> 2);
    
    vgpio_write_output(3);
    
    USER_writeWord(0x3, ((SPI1_BASE - SPI0_BASE) + SPI_CFG) >> 2);
    USER_writeWord(0x55, ((SPI1_BASE - SPI0_BASE) + SPI_TXDATA) >> 2);
    
    vgpio_write_output(4);
    
    vgpio_write_output(5);
}

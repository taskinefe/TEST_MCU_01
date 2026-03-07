#include <firmware_apis.h>

#define VGPIO_REG_ADDR 0x30FFFFFC

void vgpio_write_output(uint16_t value)
{
    volatile uint32_t *vgpio_reg = (volatile uint32_t *)VGPIO_REG_ADDR;
    uint32_t reg_val = *vgpio_reg;
    reg_val = (reg_val & 0xFFFF0000) | (value & 0xFFFF);
    *vgpio_reg = reg_val;
}

uint16_t vgpio_read_input(void)
{
    volatile uint32_t *vgpio_reg = (volatile uint32_t *)VGPIO_REG_ADDR;
    uint32_t reg_val = *vgpio_reg;
    return (uint16_t)((reg_val >> 16) & 0xFFFF);
}

void main(void)
{
    enableHkSpi(false);
    
    GPIOs_loadConfigs();
    
    User_enableIF();
    
    vgpio_write_output(1);
    
    vgpio_write_output(2);
    
    vgpio_write_output(3);
    
    vgpio_write_output(4);
    
    vgpio_write_output(5);
}

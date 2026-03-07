`timescale 1ns / 1ps
`default_nettype none

module user_project (
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif

    input wb_clk_i,
    input wb_rst_i,

    input  wbs_stb_i,
    input  wbs_cyc_i,
    input  wbs_we_i,
    input  [3:0] wbs_sel_i,
    input  [31:0] wbs_dat_i,
    input  [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    output [2:0] user_irq,

    output spi0_sclk,
    output spi0_mosi,
    input  spi0_miso,
    output spi0_csb,

    input  i2c0_scl_i,
    output i2c0_scl_o,
    output i2c0_scl_oen,
    input  i2c0_sda_i,
    output i2c0_sda_o,
    output i2c0_sda_oen,

    output spi1_sclk,
    output spi1_mosi,
    input  spi1_miso,
    output spi1_csb,

    output pwm0_out,
    output pwm1_out,

    input  real adc_vin,
    input  real adc_vrefh,
    input  real adc_vrefl,
    output adc_comp_out,
    
    input  real motor_adc_vin_a,
    input  real motor_adc_vin_b,
    input  real motor_adc_vin_c,
    output motor_adc_trigger
);

    localparam NUM_PERIPHERALS = 9;

    wire [NUM_PERIPHERALS*32-1:0] s_wb_dat_i;
    wire [NUM_PERIPHERALS-1:0]    s_wb_ack_i;
    wire [NUM_PERIPHERALS-1:0]    s_wb_err_i;

    wire [NUM_PERIPHERALS*32-1:0] s_wb_adr_o;
    wire [NUM_PERIPHERALS*32-1:0] s_wb_dat_o;
    wire [NUM_PERIPHERALS-1:0]    s_wb_cyc_o;
    wire [NUM_PERIPHERALS-1:0]    s_wb_stb_o;
    wire [NUM_PERIPHERALS-1:0]    s_wb_we_o;
    wire [NUM_PERIPHERALS*4-1:0]  s_wb_sel_o;

    wire [NUM_PERIPHERALS-1:0] peripheral_irqs;

    wishbone_bus_splitter #(
        .NUM_PERIPHERALS(NUM_PERIPHERALS),
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .SEL_WIDTH(4),
        .ADDR_SEL_LOW_BIT(16)
    ) wb_splitter (
        .m_wb_adr_i(wbs_adr_i),
        .m_wb_dat_i(wbs_dat_i),
        .m_wb_dat_o(wbs_dat_o),
        .m_wb_sel_i(wbs_sel_i),
        .m_wb_cyc_i(wbs_cyc_i),
        .m_wb_stb_i(wbs_stb_i),
        .m_wb_we_i(wbs_we_i),
        .m_wb_ack_o(wbs_ack_o),
        .m_wb_err_o(),

        .s_wb_adr_o(s_wb_adr_o),
        .s_wb_dat_o(s_wb_dat_o),
        .s_wb_cyc_o(s_wb_cyc_o),
        .s_wb_stb_o(s_wb_stb_o),
        .s_wb_we_o(s_wb_we_o),
        .s_wb_sel_o(s_wb_sel_o),
        .s_wb_dat_i(s_wb_dat_i),
        .s_wb_ack_i(s_wb_ack_i),
        .s_wb_err_i(s_wb_err_i)
    );

    CF_SPI_WB #(
        .CDW(8),
        .FAW(4)
    ) spi0_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(s_wb_adr_o[0*32 +: 32]),
        .dat_i(s_wb_dat_o[0*32 +: 32]),
        .dat_o(s_wb_dat_i[0*32 +: 32]),
        .sel_i(s_wb_sel_o[0*4 +: 4]),
        .cyc_i(s_wb_cyc_o[0]),
        .stb_i(s_wb_stb_o[0]),
        .ack_o(s_wb_ack_i[0]),
        .we_i(s_wb_we_o[0]),
        .IRQ(peripheral_irqs[0]),
        .miso(spi0_miso),
        .mosi(spi0_mosi),
        .csb(spi0_csb),
        .sclk(spi0_sclk)
    );

    CF_I2C_WB #(
        .DEFAULT_PRESCALE(1),
        .FIXED_PRESCALE(0),
        .CMD_FIFO(1),
        .CMD_FIFO_DEPTH(16),
        .WRITE_FIFO(1),
        .WRITE_FIFO_DEPTH(16),
        .READ_FIFO(1),
        .READ_FIFO_DEPTH(16)
    ) i2c0_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(s_wb_adr_o[1*32 +: 32]),
        .dat_i(s_wb_dat_o[1*32 +: 32]),
        .dat_o(s_wb_dat_i[1*32 +: 32]),
        .sel_i(s_wb_sel_o[1*4 +: 4]),
        .cyc_i(s_wb_cyc_o[1]),
        .stb_i(s_wb_stb_o[1]),
        .ack_o(s_wb_ack_i[1]),
        .we_i(s_wb_we_o[1]),
        .IRQ(peripheral_irqs[1]),
        .scl_i(i2c0_scl_i),
        .scl_o(i2c0_scl_o),
        .scl_oen_o(i2c0_scl_oen),
        .sda_i(i2c0_sda_i),
        .sda_o(i2c0_sda_o),
        .sda_oen_o(i2c0_sda_oen)
    );

    CF_SPI_WB #(
        .CDW(8),
        .FAW(4)
    ) spi1_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(s_wb_adr_o[2*32 +: 32]),
        .dat_i(s_wb_dat_o[2*32 +: 32]),
        .dat_o(s_wb_dat_i[2*32 +: 32]),
        .sel_i(s_wb_sel_o[2*4 +: 4]),
        .cyc_i(s_wb_cyc_o[2]),
        .stb_i(s_wb_stb_o[2]),
        .ack_o(s_wb_ack_i[2]),
        .we_i(s_wb_we_o[2]),
        .IRQ(peripheral_irqs[2]),
        .miso(spi1_miso),
        .mosi(spi1_mosi),
        .csb(spi1_csb),
        .sclk(spi1_sclk)
    );

    CF_TMR32_WB #(
        .PRW(16)
    ) pwm0_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(s_wb_adr_o[3*32 +: 32]),
        .dat_i(s_wb_dat_o[3*32 +: 32]),
        .dat_o(s_wb_dat_i[3*32 +: 32]),
        .sel_i(s_wb_sel_o[3*4 +: 4]),
        .cyc_i(s_wb_cyc_o[3]),
        .stb_i(s_wb_stb_o[3]),
        .ack_o(s_wb_ack_i[3]),
        .we_i(s_wb_we_o[3]),
        .IRQ(peripheral_irqs[3]),
        .pwm0(pwm0_out),
        .pwm1(),
        .pwm_fault(1'b0)
    );

    CF_TMR32_WB #(
        .PRW(16)
    ) pwm1_inst (
        .clk_i(wb_clk_i),
        .rst_i(wb_rst_i),
        .adr_i(s_wb_adr_o[4*32 +: 32]),
        .dat_i(s_wb_dat_o[4*32 +: 32]),
        .dat_o(s_wb_dat_i[4*32 +: 32]),
        .sel_i(s_wb_sel_o[4*4 +: 4]),
        .cyc_i(s_wb_cyc_o[4]),
        .stb_i(s_wb_stb_o[4]),
        .ack_o(s_wb_ack_i[4]),
        .we_i(s_wb_we_o[4]),
        .IRQ(peripheral_irqs[4]),
        .pwm0(pwm1_out),
        .pwm1(),
        .pwm_fault(1'b0)
    );

    CF_SRAM_1024x32_wb_wrapper #(.WIDTH(12)) sram_inst (
`ifdef USE_POWER_PINS
        .VPWR(vccd1),
        .VGND(vssd1),
`endif
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(s_wb_stb_o[5]),
        .wbs_cyc_i(s_wb_cyc_o[5]),
        .wbs_we_i(s_wb_we_o[5]),
        .wbs_sel_i(s_wb_sel_o[5*4 +: 4]),
        .wbs_dat_i(s_wb_dat_o[5*32 +: 32]),
        .wbs_adr_i(s_wb_adr_o[5*32 +: 32]),
        .wbs_ack_o(s_wb_ack_i[5]),
        .wbs_dat_o(s_wb_dat_i[5*32 +: 32])
    );

    adc_wb_wrapper adc_inst (
`ifdef USE_POWER_PINS
        .vccd1(vccd1),
        .vssd1(vssd1),
`endif
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(s_wb_stb_o[6]),
        .wbs_cyc_i(s_wb_cyc_o[6]),
        .wbs_we_i(s_wb_we_o[6]),
        .wbs_sel_i(s_wb_sel_o[6*4 +: 4]),
        .wbs_dat_i(s_wb_dat_o[6*32 +: 32]),
        .wbs_adr_i(s_wb_adr_o[6*32 +: 32]),
        .wbs_ack_o(s_wb_ack_i[6]),
        .wbs_dat_o(s_wb_dat_i[6*32 +: 32]),
        .irq(peripheral_irqs[6]),
        .adc_vin(adc_vin),
        .adc_vrefh(adc_vrefh),
        .adc_vrefl(adc_vrefl),
        .adc_comp_out(adc_comp_out)
    );

    motor_adc_3ch_wb motor_adc_inst (
`ifdef USE_POWER_PINS
        .vccd1(vccd1),
        .vssd1(vssd1),
`endif
        .wb_clk_i(wb_clk_i),
        .wb_rst_i(wb_rst_i),
        .wbs_stb_i(s_wb_stb_o[7]),
        .wbs_cyc_i(s_wb_cyc_o[7]),
        .wbs_we_i(s_wb_we_o[7]),
        .wbs_sel_i(s_wb_sel_o[7*4 +: 4]),
        .wbs_dat_i(s_wb_dat_o[7*32 +: 32]),
        .wbs_adr_i(s_wb_adr_o[7*32 +: 32]),
        .wbs_ack_o(s_wb_ack_i[7]),
        .wbs_dat_o(s_wb_dat_i[7*32 +: 32]),
        .irq(peripheral_irqs[7]),
        .ext_trigger(motor_adc_trigger),
        .adc_vin_a(motor_adc_vin_a),
        .adc_vin_b(motor_adc_vin_b),
        .adc_vin_c(motor_adc_vin_c),
        .adc_vrefh(3.3),
        .adc_vrefl(0.0)
    );

    WB_PIC pic_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .irq_lines(peripheral_irqs),
        .irq_out(user_irq[0]),
        .wb_adr_i(s_wb_adr_o[8*32 +: 32]),
        .wb_dat_i(s_wb_dat_o[8*32 +: 32]),
        .wb_dat_o(s_wb_dat_i[8*32 +: 32]),
        .wb_sel_i(s_wb_sel_o[8*4 +: 4]),
        .wb_cyc_i(s_wb_cyc_o[8]),
        .wb_stb_i(s_wb_stb_o[8]),
        .wb_we_i(s_wb_we_o[8]),
        .wb_ack_o(s_wb_ack_i[8])
    );

    assign s_wb_err_i = {NUM_PERIPHERALS{1'b0}};

    assign user_irq[2:1] = 2'b00;
    
    // Motor ADC trigger (can be connected to motor PWM later)
    assign motor_adc_trigger = 1'b0;  // Tied low for now, controlled via software trigger

endmodule

`default_nettype wire

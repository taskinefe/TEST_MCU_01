`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: motor_pwm_wb
// Description: Wishbone wrapper for 3-phase motor PWM controller
//=============================================================================

module motor_pwm_wb (
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif

    // Wishbone Interface
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire        wbs_stb_i,
    input  wire        wbs_cyc_i,
    input  wire        wbs_we_i,
    input  wire [3:0]  wbs_sel_i,
    input  wire [31:0] wbs_dat_i,
    input  wire [31:0] wbs_adr_i,
    output wire        wbs_ack_o,
    output wire [31:0] wbs_dat_o,
    
    // Interrupt
    output reg         irq,
    
    // PWM Outputs
    output wire        pwm_ah,
    output wire        pwm_al,
    output wire        pwm_bh,
    output wire        pwm_bl,
    output wire        pwm_ch,
    output wire        pwm_cl,
    
    // ADC Trigger
    output wire        adc_trigger
);

    // Register Map
    localparam CTRL_REG     = 8'h00;  // Control register
    localparam PERIOD_REG   = 8'h04;  // PWM period
    localparam DUTY_A_REG   = 8'h08;  // Phase A duty
    localparam DUTY_B_REG   = 8'h0C;  // Phase B duty
    localparam DUTY_C_REG   = 8'h10;  // Phase C duty
    localparam DEADTIME_REG = 8'h14;  // Dead-time
    localparam STATUS_REG   = 8'h18;  // Status register
    
    // Registers
    reg [31:0] ctrl_reg;
    reg [31:0] period_reg;
    reg [31:0] duty_a_reg;
    reg [31:0] duty_b_reg;
    reg [31:0] duty_c_reg;
    reg [31:0] deadtime_reg;
    
    // Control signals
    wire enable;
    wire adc_trig_en;
    
    assign enable = ctrl_reg[0];
    assign adc_trig_en = ctrl_reg[1];
    
    // Wishbone control
    wire valid;
    wire [7:0] reg_addr;
    reg ack_reg;
    
    assign valid = wbs_cyc_i && wbs_stb_i;
    assign reg_addr = wbs_adr_i[7:0];
    
    // Motor PWM instance
    wire pwm_period_flag;
    wire adc_trig_internal;
    
    motor_pwm #(
        .DEADTIME_WIDTH(8)
    ) motor_pwm_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .enable(enable),
        .period(period_reg[15:0]),
        .duty_a(duty_a_reg[15:0]),
        .duty_b(duty_b_reg[15:0]),
        .duty_c(duty_c_reg[15:0]),
        .deadtime(deadtime_reg[7:0]),
        .pwm_ah(pwm_ah),
        .pwm_al(pwm_al),
        .pwm_bh(pwm_bh),
        .pwm_bl(pwm_bl),
        .pwm_ch(pwm_ch),
        .pwm_cl(pwm_cl),
        .adc_trigger(adc_trig_internal),
        .pwm_period_flag(pwm_period_flag)
    );
    
    // ADC trigger output (gated by enable bit)
    assign adc_trigger = adc_trig_internal & adc_trig_en;
    
    // Register write logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ctrl_reg <= 32'h0;
            period_reg <= 32'd4000;      // Default 10kHz @ 40MHz
            duty_a_reg <= 32'd2000;      // 50% duty
            duty_b_reg <= 32'd2000;
            duty_c_reg <= 32'd2000;
            deadtime_reg <= 32'd4;       // Default 100ns @ 40MHz
            ack_reg <= 1'b0;
        end else begin
            if (valid && !ack_reg) begin
                ack_reg <= 1'b1;
                if (wbs_we_i) begin
                    case (reg_addr)
                        CTRL_REG:     ctrl_reg <= wbs_dat_i;
                        PERIOD_REG:   period_reg <= wbs_dat_i;
                        DUTY_A_REG:   duty_a_reg <= wbs_dat_i;
                        DUTY_B_REG:   duty_b_reg <= wbs_dat_i;
                        DUTY_C_REG:   duty_c_reg <= wbs_dat_i;
                        DEADTIME_REG: deadtime_reg <= wbs_dat_i;
                        default: ;
                    endcase
                end
            end else begin
                ack_reg <= 1'b0;
            end
        end
    end
    
    // Register read logic
    reg [31:0] rdata;
    always @(*) begin
        case (reg_addr)
            CTRL_REG:     rdata = ctrl_reg;
            PERIOD_REG:   rdata = period_reg;
            DUTY_A_REG:   rdata = duty_a_reg;
            DUTY_B_REG:   rdata = duty_b_reg;
            DUTY_C_REG:   rdata = duty_c_reg;
            DEADTIME_REG: rdata = deadtime_reg;
            STATUS_REG:   rdata = {31'b0, pwm_period_flag};
            default:      rdata = 32'hDEADBEEF;
        endcase
    end
    
    assign wbs_dat_o = rdata;
    assign wbs_ack_o = ack_reg;
    
    // Interrupt generation
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            irq <= 1'b0;
        else
            irq <= pwm_period_flag;  // Interrupt on period complete
    end

endmodule

`default_nettype wire

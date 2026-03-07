`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: motor_pwm_svpwm_wb
// Description: Integrated Motor PWM + SVPWM for complete FOC control
// 
// This module combines:
//   - SVPWM calculator (Vα, Vβ → duty_a, duty_b, duty_c)
//   - Motor PWM generator (6-channel complementary PWM)
//   
// User writes Vα and Vβ from FOC algorithm, hardware automatically:
//   1. Calculates optimal duty cycles via SVPWM
//   2. Generates center-aligned complementary PWM
//   3. Triggers ADC at PWM center
//=============================================================================

module motor_pwm_svpwm_wb (
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
    
    // PWM Outputs (6 channels - complementary pairs)
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
    localparam CTRL_REG       = 8'h00;  // Control register
    localparam PERIOD_REG     = 8'h04;  // PWM period
    localparam DEADTIME_REG   = 8'h08;  // Dead-time
    localparam V_ALPHA_REG    = 8'h0C;  // SVPWM: V_alpha input
    localparam V_BETA_REG     = 8'h10;  // SVPWM: V_beta input
    localparam DUTY_A_REG     = 8'h14;  // Phase A duty (from SVPWM)
    localparam DUTY_B_REG     = 8'h18;  // Phase B duty (from SVPWM)
    localparam DUTY_C_REG     = 8'h1C;  // Phase C duty (from SVPWM)
    localparam STATUS_REG     = 8'h20;  // Status register
    localparam SECTOR_REG     = 8'h24;  // SVPWM sector (debug)
    
    // Registers
    reg [31:0] ctrl_reg;
    reg [31:0] period_reg;
    reg [31:0] deadtime_reg;
    reg signed [15:0] v_alpha_reg;
    reg signed [15:0] v_beta_reg;
    
    // Control signals
    wire pwm_enable;
    wire svpwm_enable;
    wire adc_trig_en;
    wire svpwm_update;
    
    assign pwm_enable = ctrl_reg[0];
    assign svpwm_enable = ctrl_reg[1];
    assign adc_trig_en = ctrl_reg[2];
    assign svpwm_update = ctrl_reg[3];  // Write 1 to recalculate SVPWM
    
    // Wishbone control
    wire valid;
    wire [7:0] reg_addr;
    reg ack_reg;
    
    assign valid = wbs_cyc_i && wbs_stb_i;
    assign reg_addr = wbs_adr_i[7:0];
    
    // SVPWM instance
    wire [15:0] svpwm_duty_a, svpwm_duty_b, svpwm_duty_c;
    wire svpwm_ready;
    
    // Update pulse generation
    reg update_req;
    reg update_req_r;
    wire update_pulse;
    
    assign update_pulse = update_req & ~update_req_r;
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            update_req_r <= 1'b0;
        else
            update_req_r <= update_req;
    end
    
    svpwm #(
        .DATA_WIDTH(16),
        .PWM_PERIOD(2000)
    ) svpwm_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .v_alpha(v_alpha_reg),
        .v_beta(v_beta_reg),
        .vdc(16'h7FFF),  // Fixed 1.0 for now
        .update(update_pulse & svpwm_enable),
        .duty_a(svpwm_duty_a),
        .duty_b(svpwm_duty_b),
        .duty_c(svpwm_duty_c),
        .ready(svpwm_ready)
    );
    
    // Motor PWM instance
    wire pwm_period_flag;
    wire adc_trig_internal;
    
    motor_pwm #(
        .DEADTIME_WIDTH(8)
    ) motor_pwm_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .enable(pwm_enable),
        .period(period_reg[15:0]),
        .duty_a(svpwm_duty_a),       // ← Connected to SVPWM output
        .duty_b(svpwm_duty_b),       // ← Connected to SVPWM output
        .duty_c(svpwm_duty_c),       // ← Connected to SVPWM output
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
            period_reg <= 32'd2000;      // Default 10kHz @ 40MHz
            deadtime_reg <= 32'd8;       // Default 200ns @ 40MHz
            v_alpha_reg <= 16'h0;
            v_beta_reg <= 16'h0;
            update_req <= 1'b0;
            ack_reg <= 1'b0;
        end else begin
            // Auto-clear SVPWM update bit after pulse
            if (update_pulse) begin
                ctrl_reg[3] <= 1'b0;
                update_req <= 1'b0;
            end
                
            if (valid && !ack_reg) begin
                ack_reg <= 1'b1;
                if (wbs_we_i) begin
                    case (reg_addr)
                        CTRL_REG: begin
                            ctrl_reg <= wbs_dat_i;
                            if (wbs_dat_i[3])  // SVPWM update bit
                                update_req <= 1'b1;
                        end
                        PERIOD_REG:   period_reg <= wbs_dat_i;
                        DEADTIME_REG: deadtime_reg <= wbs_dat_i;
                        V_ALPHA_REG: begin
                            v_alpha_reg <= wbs_dat_i[15:0];
                            update_req <= 1'b1;  // Auto-trigger SVPWM calc
                        end
                        V_BETA_REG: begin
                            v_beta_reg <= wbs_dat_i[15:0];
                            update_req <= 1'b1;  // Auto-trigger SVPWM calc
                        end
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
            DEADTIME_REG: rdata = deadtime_reg;
            V_ALPHA_REG:  rdata = {16'h0, v_alpha_reg};
            V_BETA_REG:   rdata = {16'h0, v_beta_reg};
            DUTY_A_REG:   rdata = {16'h0, svpwm_duty_a};
            DUTY_B_REG:   rdata = {16'h0, svpwm_duty_b};
            DUTY_C_REG:   rdata = {16'h0, svpwm_duty_c};
            STATUS_REG:   rdata = {30'b0, svpwm_ready, pwm_period_flag};
            default:      rdata = 32'hDEADBEEF;
        endcase
    end
    
    assign wbs_dat_o = rdata;
    assign wbs_ack_o = ack_reg;
    
    // Interrupt generation (PWM period complete)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            irq <= 1'b0;
        else
            irq <= pwm_period_flag;
    end

endmodule

`default_nettype wire

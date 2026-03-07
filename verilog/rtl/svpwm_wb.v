`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: svpwm_wb
// Description: Wishbone wrapper for SVPWM generator
//=============================================================================

module svpwm_wb (
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
    
    // Duty cycle outputs (to motor PWM)
    output wire [15:0] duty_a,
    output wire [15:0] duty_b,
    output wire [15:0] duty_c,
    output wire        duty_ready
);

    // Register Map
    localparam CTRL_REG     = 8'h00;  // Control register
    localparam V_ALPHA_REG  = 8'h04;  // V_alpha input (Q15)
    localparam V_BETA_REG   = 8'h08;  // V_beta input (Q15)
    localparam VDC_REG      = 8'h0C;  // DC bus voltage
    localparam DUTY_A_REG   = 8'h10;  // Phase A duty (read-only)
    localparam DUTY_B_REG   = 8'h14;  // Phase B duty (read-only)
    localparam DUTY_C_REG   = 8'h18;  // Phase C duty (read-only)
    localparam STATUS_REG   = 8'h1C;  // Status register
    localparam PERIOD_REG   = 8'h20;  // PWM period
    localparam SECTOR_REG   = 8'h24;  // Current sector (debug)
    
    // Registers
    reg [31:0] ctrl_reg;
    reg signed [15:0] v_alpha_reg;
    reg signed [15:0] v_beta_reg;
    reg [15:0] vdc_reg;
    reg [15:0] period_reg;
    
    // Control signals
    wire enable;
    wire update_trigger;
    
    assign enable = ctrl_reg[0];
    
    // Wishbone control
    wire valid;
    wire [7:0] reg_addr;
    reg ack_reg;
    
    assign valid = wbs_cyc_i && wbs_stb_i;
    assign reg_addr = wbs_adr_i[7:0];
    
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
    
    // SVPWM instance
    wire [15:0] duty_a_int, duty_b_int, duty_c_int;
    wire ready_int;
    
    svpwm #(
        .DATA_WIDTH(16),
        .PWM_PERIOD(2000)  // Will be overridden by period_reg
    ) svpwm_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .v_alpha(v_alpha_reg),
        .v_beta(v_beta_reg),
        .vdc(vdc_reg),
        .update(update_pulse & enable),
        .duty_a(duty_a_int),
        .duty_b(duty_b_int),
        .duty_c(duty_c_int),
        .ready(ready_int)
    );
    
    assign duty_a = duty_a_int;
    assign duty_b = duty_b_int;
    assign duty_c = duty_c_int;
    assign duty_ready = ready_int;
    
    // Register write logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ctrl_reg <= 32'h0;
            v_alpha_reg <= 16'h0;
            v_beta_reg <= 16'h0;
            vdc_reg <= 16'h7FFF;  // Default 1.0 in Q15
            period_reg <= 16'd2000;
            update_req <= 1'b0;
            ack_reg <= 1'b0;
        end else begin
            // Auto-clear update request after pulse
            if (update_pulse)
                update_req <= 1'b0;
                
            if (valid && !ack_reg) begin
                ack_reg <= 1'b1;
                if (wbs_we_i) begin
                    case (reg_addr)
                        CTRL_REG: begin
                            ctrl_reg <= wbs_dat_i;
                            // Bit 1 triggers update
                            if (wbs_dat_i[1])
                                update_req <= 1'b1;
                        end
                        V_ALPHA_REG: v_alpha_reg <= wbs_dat_i[15:0];
                        V_BETA_REG:  v_beta_reg <= wbs_dat_i[15:0];
                        VDC_REG:     vdc_reg <= wbs_dat_i[15:0];
                        PERIOD_REG:  period_reg <= wbs_dat_i[15:0];
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
            CTRL_REG:    rdata = ctrl_reg;
            V_ALPHA_REG: rdata = {16'h0, v_alpha_reg};
            V_BETA_REG:  rdata = {16'h0, v_beta_reg};
            VDC_REG:     rdata = {16'h0, vdc_reg};
            DUTY_A_REG:  rdata = {16'h0, duty_a_int};
            DUTY_B_REG:  rdata = {16'h0, duty_b_int};
            DUTY_C_REG:  rdata = {16'h0, duty_c_int};
            STATUS_REG:  rdata = {31'b0, ready_int};
            PERIOD_REG:  rdata = {16'h0, period_reg};
            SECTOR_REG:  rdata = 32'h0;  // Debug: can add sector output
            default:     rdata = 32'hDEADBEEF;
        endcase
    end
    
    assign wbs_dat_o = rdata;
    assign wbs_ack_o = ack_reg;
    
    // Interrupt generation (when calculation ready)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            irq <= 1'b0;
        else
            irq <= ready_int;
    end

endmodule

`default_nettype wire

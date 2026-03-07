`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: overcurrent_protection_wb
// Description: Wishbone wrapper for overcurrent protection
//=============================================================================

module overcurrent_protection_wb (
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
    output wire        irq,
    
    // Analog Inputs
    input  wire real   phase_a_current,
    input  wire real   phase_b_current,
    input  wire real   phase_c_current,
    
    // Threshold output
    output wire real   dac_threshold,
    
    // PWM Shutdown
    output wire        pwm_shutdown
);

    //=========================================================================
    // Register Map
    //=========================================================================
    
    localparam CTRL_REG      = 8'h00;  // Control register
    localparam DAC_REG       = 8'h04;  // DAC threshold value
    localparam STATUS_REG    = 8'h08;  // Fault status
    localparam FAULT_CLR_REG = 8'h0C;  // Fault clear (write 1 to clear)
    
    //=========================================================================
    // Registers
    //=========================================================================
    
    reg [31:0] ctrl_reg;
    reg [7:0]  dac_reg;
    
    // Control bits
    wire enable;
    wire dac_enable;
    
    assign enable = ctrl_reg[0];
    assign dac_enable = ctrl_reg[1];
    
    // Wishbone control
    wire valid;
    wire [7:0] reg_addr;
    reg ack_reg;
    
    assign valid = wbs_cyc_i && wbs_stb_i;
    assign reg_addr = wbs_adr_i[7:0];
    
    //=========================================================================
    // Fault Status
    //=========================================================================
    
    wire fault_a, fault_b, fault_c, fault_any;
    reg fault_clear_pulse;
    
    //=========================================================================
    // Overcurrent Protection Instance
    //=========================================================================
    
    overcurrent_protection ocp_inst (
`ifdef USE_POWER_PINS
        .vccd1(vccd1),
        .vssd1(vssd1),
`endif
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        
        // DAC control
        .dac_value(dac_reg),
        .dac_enable(dac_enable & enable),
        
        // Analog inputs
        .phase_a_current(phase_a_current),
        .phase_b_current(phase_b_current),
        .phase_c_current(phase_c_current),
        
        // DAC threshold output
        .dac_threshold(dac_threshold),
        
        // Fault control
        .fault_clear(fault_clear_pulse),
        
        // Fault status
        .fault_a(fault_a),
        .fault_b(fault_b),
        .fault_c(fault_c),
        .fault_any(fault_any),
        
        // PWM shutdown
        .pwm_shutdown(pwm_shutdown),
        
        // Interrupt
        .irq(irq)
    );
    
    //=========================================================================
    // Register Write Logic
    //=========================================================================
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ctrl_reg <= 32'h0;
            dac_reg <= 8'h00;  // 0V threshold
            ack_reg <= 1'b0;
            fault_clear_pulse <= 1'b0;
        end else begin
            // Default: no fault clear
            fault_clear_pulse <= 1'b0;
            
            if (valid && !ack_reg) begin
                ack_reg <= 1'b1;
                if (wbs_we_i) begin
                    case (reg_addr)
                        CTRL_REG: begin
                            ctrl_reg <= wbs_dat_i;
                        end
                        DAC_REG: begin
                            dac_reg <= wbs_dat_i[7:0];
                        end
                        FAULT_CLR_REG: begin
                            if (wbs_dat_i[0]) begin
                                fault_clear_pulse <= 1'b1;  // Clear fault
                            end
                        end
                        default: ;
                    endcase
                end
            end else begin
                ack_reg <= 1'b0;
            end
        end
    end
    
    //=========================================================================
    // Register Read Logic
    //=========================================================================
    
    reg [31:0] rdata;
    
    always @(*) begin
        case (reg_addr)
            CTRL_REG:      rdata = ctrl_reg;
            DAC_REG:       rdata = {24'h0, dac_reg};
            STATUS_REG:    rdata = {28'h0, fault_any, fault_c, fault_b, fault_a};
            FAULT_CLR_REG: rdata = 32'h0;  // Write-only
            default:       rdata = 32'hDEADBEEF;
        endcase
    end
    
    assign wbs_dat_o = rdata;
    assign wbs_ack_o = ack_reg;

endmodule

`default_nettype wire

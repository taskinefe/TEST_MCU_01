`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: motor_adc_3ch_wb
// Description: Wishbone wrapper for 3-channel motor current ADC
//=============================================================================

module motor_adc_3ch_wb (
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
    
    // External trigger (from motor PWM)
    input  wire        ext_trigger,
    
    // Analog inputs
    input  wire real   adc_vin_a,
    input  wire real   adc_vin_b,
    input  wire real   adc_vin_c,
    input  wire real   adc_vrefh,
    input  wire real   adc_vrefl
);

    // Register Map
    localparam CTRL_REG     = 8'h00;  // Control register
    localparam STATUS_REG   = 8'h04;  // Status register
    localparam DATA_A_REG   = 8'h08;  // Phase A data
    localparam DATA_B_REG   = 8'h0C;  // Phase B data
    localparam DATA_C_REG   = 8'h10;  // Phase C data
    localparam CONFIG_REG   = 8'h14;  // Configuration
    
    // Registers
    reg [31:0] ctrl_reg;
    reg [31:0] config_reg;
    
    // Control signals
    wire enable;
    wire trigger_en;
    wire sw_trigger;
    wire [3:0] sample_width;
    
    assign enable = ctrl_reg[0];
    assign trigger_en = ctrl_reg[1];
    assign sw_trigger = ctrl_reg[2];
    assign sample_width = config_reg[3:0];
    
    // Wishbone control
    wire valid;
    wire [7:0] reg_addr;
    reg ack_reg;
    
    assign valid = wbs_cyc_i && wbs_stb_i;
    assign reg_addr = wbs_adr_i[7:0];
    
    // 3-Channel ADC instance
    wire [11:0] data_a, data_b, data_c;
    wire eoc_a, eoc_b, eoc_c, all_eoc;
    wire trigger_in;
    
    // Trigger can come from external source OR software
    assign trigger_in = (ext_trigger & trigger_en) | sw_trigger;
    
    motor_adc_3ch motor_adc_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .trigger(trigger_in),
        .enable(enable),
        .sample_width(sample_width),
        .adc_vin_a(adc_vin_a),
        .adc_vin_b(adc_vin_b),
        .adc_vin_c(adc_vin_c),
        .adc_vrefh(adc_vrefh),
        .adc_vrefl(adc_vrefl),
        .data_a(data_a),
        .data_b(data_b),
        .data_c(data_c),
        .eoc_a(eoc_a),
        .eoc_b(eoc_b),
        .eoc_c(eoc_c),
        .all_eoc(all_eoc),
        .comp_out_a(),
        .comp_out_b(),
        .comp_out_c()
    );
    
    // Register write logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ctrl_reg <= 32'h0;
            config_reg <= 32'h04;  // Default sample width = 4
            ack_reg <= 1'b0;
        end else begin
            // Auto-clear software trigger after one cycle
            if (sw_trigger)
                ctrl_reg[2] <= 1'b0;
                
            if (valid && !ack_reg) begin
                ack_reg <= 1'b1;
                if (wbs_we_i) begin
                    case (reg_addr)
                        CTRL_REG:   ctrl_reg <= wbs_dat_i;
                        CONFIG_REG: config_reg <= wbs_dat_i;
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
            CTRL_REG:   rdata = ctrl_reg;
            STATUS_REG: rdata = {28'b0, all_eoc, eoc_c, eoc_b, eoc_a};
            DATA_A_REG: rdata = {20'b0, data_a};
            DATA_B_REG: rdata = {20'b0, data_b};
            DATA_C_REG: rdata = {20'b0, data_c};
            CONFIG_REG: rdata = config_reg;
            default:    rdata = 32'hDEADBEEF;
        endcase
    end
    
    assign wbs_dat_o = rdata;
    assign wbs_ack_o = ack_reg;
    
    // Interrupt generation (when all conversions complete)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            irq <= 1'b0;
        else
            irq <= all_eoc;
    end

endmodule

`default_nettype wire

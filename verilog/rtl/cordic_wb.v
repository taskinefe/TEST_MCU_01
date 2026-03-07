`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: cordic_wb
// Description: Wishbone wrapper for CORDIC accelerator
//=============================================================================

module cordic_wb (
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
    output reg         irq
);

    // Register Map
    localparam CTRL_REG   = 8'h00;  // Control register
    localparam X_IN_REG   = 8'h04;  // X input
    localparam Y_IN_REG   = 8'h08;  // Y input
    localparam Z_IN_REG   = 8'h0C;  // Z input (angle)
    localparam X_OUT_REG  = 8'h10;  // X output
    localparam Y_OUT_REG  = 8'h14;  // Y output
    localparam Z_OUT_REG  = 8'h18;  // Z output (angle)
    localparam STATUS_REG = 8'h1C;  // Status register
    
    // Registers
    reg [31:0] ctrl_reg;
    reg signed [15:0] x_in_reg;
    reg signed [15:0] y_in_reg;
    reg signed [15:0] z_in_reg;
    
    // Control signals
    wire enable;
    wire mode;
    wire start_bit;
    
    assign enable = ctrl_reg[0];
    assign mode = ctrl_reg[1];      // 0=Rotation, 1=Vectoring
    assign start_bit = ctrl_reg[2]; // Start calculation
    
    // Wishbone control
    wire valid;
    wire [7:0] reg_addr;
    reg ack_reg;
    
    assign valid = wbs_cyc_i && wbs_stb_i;
    assign reg_addr = wbs_adr_i[7:0];
    
    // CORDIC instance
    wire signed [15:0] x_out_int, y_out_int, z_out_int;
    wire valid_int;
    reg start_pulse;
    
    // Start pulse generation
    reg start_bit_r;
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            start_bit_r <= 1'b0;
        else
            start_bit_r <= start_bit;
    end
    
    assign start_pulse = start_bit & ~start_bit_r;
    
    cordic #(
        .WIDTH(16),
        .ITERATIONS(16)
    ) cordic_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .start(start_pulse & enable),
        .mode(mode),
        .x_in(x_in_reg),
        .y_in(y_in_reg),
        .z_in(z_in_reg),
        .x_out(x_out_int),
        .y_out(y_out_int),
        .z_out(z_out_int),
        .valid(valid_int)
    );
    
    // Register write logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ctrl_reg <= 32'h0;
            x_in_reg <= 16'h0;
            y_in_reg <= 16'h0;
            z_in_reg <= 16'h0;
            ack_reg <= 1'b0;
        end else begin
            // Auto-clear start bit after pulse
            if (start_pulse)
                ctrl_reg[2] <= 1'b0;
                
            if (valid && !ack_reg) begin
                ack_reg <= 1'b1;
                if (wbs_we_i) begin
                    case (reg_addr)
                        CTRL_REG: begin
                            ctrl_reg <= wbs_dat_i;
                        end
                        X_IN_REG: x_in_reg <= wbs_dat_i[15:0];
                        Y_IN_REG: y_in_reg <= wbs_dat_i[15:0];
                        Z_IN_REG: z_in_reg <= wbs_dat_i[15:0];
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
            X_IN_REG:   rdata = {16'h0, x_in_reg};
            Y_IN_REG:   rdata = {16'h0, y_in_reg};
            Z_IN_REG:   rdata = {16'h0, z_in_reg};
            X_OUT_REG:  rdata = {16'h0, x_out_int};
            Y_OUT_REG:  rdata = {16'h0, y_out_int};
            Z_OUT_REG:  rdata = {16'h0, z_out_int};
            STATUS_REG: rdata = {31'b0, valid_int};
            default:    rdata = 32'hDEADBEEF;
        endcase
    end
    
    assign wbs_dat_o = rdata;
    assign wbs_ack_o = ack_reg;
    
    // Interrupt generation (when calculation complete)
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            irq <= 1'b0;
        else
            irq <= valid_int;
    end

endmodule

`default_nettype wire

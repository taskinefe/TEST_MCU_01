`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: foc_transforms_wb
// Description: Wishbone wrapper for FOC Transform Engine
//=============================================================================

module foc_transforms_wb (
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
    localparam CTRL_REG     = 8'h00;  // Control/Mode register
    localparam IA_REG       = 8'h04;  // Phase A current input
    localparam IB_REG       = 8'h08;  // Phase B current input
    localparam IC_REG       = 8'h0C;  // Phase C current input
    localparam ALPHA_IN_REG = 8'h10;  // Alpha input
    localparam BETA_IN_REG  = 8'h14;  // Beta input
    localparam D_IN_REG     = 8'h18;  // D-axis input
    localparam Q_IN_REG     = 8'h1C;  // Q-axis input
    localparam THETA_REG    = 8'h20;  // Angle theta
    localparam ALPHA_OUT_REG= 8'h24;  // Alpha output
    localparam BETA_OUT_REG = 8'h28;  // Beta output
    localparam D_OUT_REG    = 8'h2C;  // D-axis output
    localparam Q_OUT_REG    = 8'h30;  // Q-axis output
    localparam IA_OUT_REG   = 8'h34;  // Phase A output
    localparam IB_OUT_REG   = 8'h38;  // Phase B output
    localparam IC_OUT_REG   = 8'h3C;  // Phase C output
    localparam STATUS_REG   = 8'h40;  // Status register
    
    // Registers
    reg [31:0] ctrl_reg;
    reg signed [15:0] ia_reg, ib_reg, ic_reg;
    reg signed [15:0] alpha_in_reg, beta_in_reg;
    reg signed [15:0] d_in_reg, q_in_reg;
    reg signed [15:0] theta_reg;
    
    // Control signals
    wire enable;
    wire [1:0] mode;
    wire start_bit;
    
    assign enable = ctrl_reg[0];
    assign mode = ctrl_reg[2:1];      // 00=Clarke, 01=Inv Clarke, 10=Park, 11=Inv Park
    assign start_bit = ctrl_reg[3];   // Start transform
    
    // Wishbone control
    wire valid;
    wire [7:0] reg_addr;
    reg ack_reg;
    
    assign valid = wbs_cyc_i && wbs_stb_i;
    assign reg_addr = wbs_adr_i[7:0];
    
    // Transform outputs
    wire signed [15:0] alpha_out_int, beta_out_int;
    wire signed [15:0] d_out_int, q_out_int;
    wire signed [15:0] ia_out_int, ib_out_int, ic_out_int;
    wire valid_int;
    
    // Start pulse generation
    reg start_bit_r;
    wire start_pulse;
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            start_bit_r <= 1'b0;
        else
            start_bit_r <= start_bit;
    end
    
    assign start_pulse = start_bit & ~start_bit_r;
    
    // FOC Transforms instance
    foc_transforms #(
        .WIDTH(16)
    ) foc_inst (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .mode(mode),
        .start(start_pulse & enable),
        
        // Clarke inputs
        .ia(ia_reg),
        .ib(ib_reg),
        .ic(ic_reg),
        
        // Park inputs
        .alpha_in(alpha_in_reg),
        .beta_in(beta_in_reg),
        .theta(theta_reg),
        
        // Inverse Park inputs
        .d_in(d_in_reg),
        .q_in(q_in_reg),
        
        // Outputs
        .alpha_out(alpha_out_int),
        .beta_out(beta_out_int),
        .d_out(d_out_int),
        .q_out(q_out_int),
        .ia_out(ia_out_int),
        .ib_out(ib_out_int),
        .ic_out(ic_out_int),
        .valid(valid_int)
    );
    
    // Register write logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ctrl_reg <= 32'h0;
            ia_reg <= 16'h0;
            ib_reg <= 16'h0;
            ic_reg <= 16'h0;
            alpha_in_reg <= 16'h0;
            beta_in_reg <= 16'h0;
            d_in_reg <= 16'h0;
            q_in_reg <= 16'h0;
            theta_reg <= 16'h0;
            ack_reg <= 1'b0;
        end else begin
            // Auto-clear start bit
            if (start_pulse)
                ctrl_reg[3] <= 1'b0;
                
            if (valid && !ack_reg) begin
                ack_reg <= 1'b1;
                if (wbs_we_i) begin
                    case (reg_addr)
                        CTRL_REG:     ctrl_reg <= wbs_dat_i;
                        IA_REG:       ia_reg <= wbs_dat_i[15:0];
                        IB_REG:       ib_reg <= wbs_dat_i[15:0];
                        IC_REG:       ic_reg <= wbs_dat_i[15:0];
                        ALPHA_IN_REG: alpha_in_reg <= wbs_dat_i[15:0];
                        BETA_IN_REG:  beta_in_reg <= wbs_dat_i[15:0];
                        D_IN_REG:     d_in_reg <= wbs_dat_i[15:0];
                        Q_IN_REG:     q_in_reg <= wbs_dat_i[15:0];
                        THETA_REG:    theta_reg <= wbs_dat_i[15:0];
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
            IA_REG:       rdata = {16'h0, ia_reg};
            IB_REG:       rdata = {16'h0, ib_reg};
            IC_REG:       rdata = {16'h0, ic_reg};
            ALPHA_IN_REG: rdata = {16'h0, alpha_in_reg};
            BETA_IN_REG:  rdata = {16'h0, beta_in_reg};
            D_IN_REG:     rdata = {16'h0, d_in_reg};
            Q_IN_REG:     rdata = {16'h0, q_in_reg};
            THETA_REG:    rdata = {16'h0, theta_reg};
            ALPHA_OUT_REG:rdata = {16'h0, alpha_out_int};
            BETA_OUT_REG: rdata = {16'h0, beta_out_int};
            D_OUT_REG:    rdata = {16'h0, d_out_int};
            Q_OUT_REG:    rdata = {16'h0, q_out_int};
            IA_OUT_REG:   rdata = {16'h0, ia_out_int};
            IB_OUT_REG:   rdata = {16'h0, ib_out_int};
            IC_OUT_REG:   rdata = {16'h0, ic_out_int};
            STATUS_REG:   rdata = {31'b0, valid_int};
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
            irq <= valid_int;
    end

endmodule

`default_nettype wire

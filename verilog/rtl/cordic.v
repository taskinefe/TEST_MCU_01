`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: cordic
// Description: CORDIC Algorithm for FOC Motor Control
// 
// Functions:
//   - Sin/Cos calculation (Rotation mode)
//   - Arctan/Magnitude calculation (Vectoring mode)
//   - Vector rotation (Clarke/Park transforms)
//
// Uses pipelined CORDIC with 16 iterations for high accuracy
// Fixed-point Q15 format: 1 sign bit + 15 fractional bits
//=============================================================================

module cordic #(
    parameter WIDTH = 16,           // Data width (Q15 format)
    parameter ITERATIONS = 16       // Number of CORDIC iterations
)(
    input  wire                   clk,
    input  wire                   rst_n,
    
    // Control
    input  wire                   start,       // Start calculation
    input  wire                   mode,        // 0=Rotation, 1=Vectoring
    
    // Inputs (Q15 fixed-point)
    input  wire signed [WIDTH-1:0] x_in,       // X input
    input  wire signed [WIDTH-1:0] y_in,       // Y input  
    input  wire signed [WIDTH-1:0] z_in,       // Z input (angle for rotation)
    
    // Outputs (Q15 fixed-point)
    output reg  signed [WIDTH-1:0] x_out,      // X output
    output reg  signed [WIDTH-1:0] y_out,      // Y output
    output reg  signed [WIDTH-1:0] z_out,      // Z output (angle for vectoring)
    
    // Status
    output reg                     valid        // Output valid
);

    // CORDIC arctangent lookup table (Q15 format)
    // atan(2^-i) values for i=0 to 15
    function [WIDTH-1:0] atan_table;
        input [3:0] index;
        begin
            case(index)
                4'd0:  atan_table = 16'h6488;  // atan(2^0)  = 45.000° = 0.7854 rad
                4'd1:  atan_table = 16'h3B59;  // atan(2^-1) = 26.565° = 0.4636 rad
                4'd2:  atan_table = 16'h1F5B;  // atan(2^-2) = 14.036° = 0.2450 rad
                4'd3:  atan_table = 16'h0FEB;  // atan(2^-3) = 7.125°  = 0.1244 rad
                4'd4:  atan_table = 16'h07FD;  // atan(2^-4) = 3.576°  = 0.0624 rad
                4'd5:  atan_table = 16'h03FF;  // atan(2^-5) = 1.790°  = 0.0312 rad
                4'd6:  atan_table = 16'h01FF;  // atan(2^-6) = 0.895°  = 0.0156 rad
                4'd7:  atan_table = 16'h0100;  // atan(2^-7) = 0.448°  = 0.0078 rad
                4'd8:  atan_table = 16'h0080;  // atan(2^-8) = 0.224°  = 0.0039 rad
                4'd9:  atan_table = 16'h0040;  // atan(2^-9) = 0.112°  = 0.0020 rad
                4'd10: atan_table = 16'h0020;  // atan(2^-10) = 0.056° = 0.0010 rad
                4'd11: atan_table = 16'h0010;  // atan(2^-11) = 0.028° = 0.0005 rad
                4'd12: atan_table = 16'h0008;  // atan(2^-12) = 0.014° = 0.0002 rad
                4'd13: atan_table = 16'h0004;  // atan(2^-13) = 0.007° = 0.0001 rad
                4'd14: atan_table = 16'h0002;  // atan(2^-14)
                4'd15: atan_table = 16'h0001;  // atan(2^-15)
                default: atan_table = 16'h0000;
            endcase
        end
    endfunction

    // Pipeline registers
    reg signed [WIDTH-1:0] x[0:ITERATIONS];
    reg signed [WIDTH-1:0] y[0:ITERATIONS];
    reg signed [WIDTH-1:0] z[0:ITERATIONS];
    
    // Iteration counter
    reg [4:0] iteration;
    reg running;
    reg mode_reg;
    
    // CORDIC gain compensation constant (K = 0.6072529350088812561694)
    // In Q15: K = 0.6072529350088812561694 * 32768 = 19898 = 0x4DBA
    localparam signed [WIDTH-1:0] CORDIC_GAIN = 16'h4DBA;
    
    // State machine
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam COMP = 2'b10;
    localparam DONE = 2'b11;
    
    reg [1:0] state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            iteration <= 0;
            running <= 0;
            valid <= 0;
            x_out <= 0;
            y_out <= 0;
            z_out <= 0;
            mode_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 0;
                    if (start) begin
                        // Initialize first stage
                        x[0] <= x_in;
                        y[0] <= y_in;
                        z[0] <= z_in;
                        iteration <= 0;
                        mode_reg <= mode;
                        state <= CALC;
                    end
                end
                
                CALC: begin
                    if (iteration < ITERATIONS) begin
                        // CORDIC iteration
                        if (mode_reg == 0) begin
                            // Rotation mode: rotate by z to drive z to zero
                            if (z[iteration] >= 0) begin
                                // Positive rotation
                                x[iteration+1] <= x[iteration] - (y[iteration] >>> iteration);
                                y[iteration+1] <= y[iteration] + (x[iteration] >>> iteration);
                                z[iteration+1] <= z[iteration] - atan_table(iteration[3:0]);
                            end else begin
                                // Negative rotation
                                x[iteration+1] <= x[iteration] + (y[iteration] >>> iteration);
                                y[iteration+1] <= y[iteration] - (x[iteration] >>> iteration);
                                z[iteration+1] <= z[iteration] + atan_table(iteration[3:0]);
                            end
                        end else begin
                            // Vectoring mode: rotate to drive y to zero
                            if (y[iteration] < 0) begin
                                x[iteration+1] <= x[iteration] - (y[iteration] >>> iteration);
                                y[iteration+1] <= y[iteration] + (x[iteration] >>> iteration);
                                z[iteration+1] <= z[iteration] - atan_table(iteration[3:0]);
                            end else begin
                                x[iteration+1] <= x[iteration] + (y[iteration] >>> iteration);
                                y[iteration+1] <= y[iteration] - (x[iteration] >>> iteration);
                                z[iteration+1] <= z[iteration] + atan_table(iteration[3:0]);
                            end
                        end
                        iteration <= iteration + 1;
                    end else begin
                        state <= COMP;
                    end
                end
                
                COMP: begin
                    // Gain compensation for rotation mode
                    // For vectoring mode, x output is already the magnitude
                    if (mode_reg == 0) begin
                        // Apply gain compensation
                        x_out <= (x[ITERATIONS] * CORDIC_GAIN) >>> 15;
                        y_out <= (y[ITERATIONS] * CORDIC_GAIN) >>> 15;
                    end else begin
                        x_out <= x[ITERATIONS];  // Magnitude (no gain needed)
                        y_out <= y[ITERATIONS];  // Should be ~0
                    end
                    z_out <= z[ITERATIONS];
                    state <= DONE;
                end
                
                DONE: begin
                    valid <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

`default_nettype wire

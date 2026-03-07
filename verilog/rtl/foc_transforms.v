`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: foc_transforms
// Description: Complete FOC Transform Engine
//
// Transforms:
//   1. Clarke Transform:         abc → αβ
//   2. Inverse Clarke Transform: αβ → abc
//   3. Park Transform:           αβ → dq
//   4. Inverse Park Transform:   dq → αβ
//
// All transforms execute in 1-2 cycles for maximum FOC loop speed
// Fixed-point Q15 format for high precision
//=============================================================================

module foc_transforms #(
    parameter WIDTH = 16  // Q15 fixed-point
)(
    input  wire                   clk,
    input  wire                   rst_n,
    
    // Control
    input  wire [1:0]             mode,        // 00=Clarke, 01=Inv Clarke, 10=Park, 11=Inv Park
    input  wire                   start,       // Start transform
    
    // Clarke Transform Inputs (abc → αβ)
    input  wire signed [WIDTH-1:0] ia,         // Phase A current (Q15)
    input  wire signed [WIDTH-1:0] ib,         // Phase B current (Q15)
    input  wire signed [WIDTH-1:0] ic,         // Phase C current (Q15)
    
    // Park Transform Inputs (αβ → dq)
    input  wire signed [WIDTH-1:0] alpha_in,   // Alpha component (Q15)
    input  wire signed [WIDTH-1:0] beta_in,    // Beta component (Q15)
    input  wire signed [WIDTH-1:0] theta,      // Rotor angle (Q15, normalized to π)
    
    // Inverse Clarke Inputs (αβ → abc)
    // Uses alpha_in, beta_in from above
    
    // Inverse Park Inputs (dq → αβ)
    input  wire signed [WIDTH-1:0] d_in,       // D-axis component (Q15)
    input  wire signed [WIDTH-1:0] q_in,       // Q-axis component (Q15)
    // Uses theta from above
    
    // Clarke/Inv Park Outputs (αβ)
    output reg  signed [WIDTH-1:0] alpha_out,
    output reg  signed [WIDTH-1:0] beta_out,
    
    // Park Outputs (dq)
    output reg  signed [WIDTH-1:0] d_out,
    output reg  signed [WIDTH-1:0] q_out,
    
    // Inverse Clarke Outputs (abc)
    output reg  signed [WIDTH-1:0] ia_out,
    output reg  signed [WIDTH-1:0] ib_out,
    output reg  signed [WIDTH-1:0] ic_out,
    
    // Status
    output reg                     valid
);

    // Constants in Q15
    // 1/sqrt(3) = 0.57735 ≈ 0x49E7
    localparam signed [WIDTH-1:0] INV_SQRT3 = 16'h49E7;
    
    // sqrt(3)/2 = 0.86603 ≈ 0x6ED9
    localparam signed [WIDTH-1:0] SQRT3_2 = 16'h6ED9;
    
    // 2/3 = 0.66667 ≈ 0x5555
    localparam signed [WIDTH-1:0] TWO_THIRDS = 16'h5555;
    
    // 1/3 = 0.33333 ≈ 0x2AAB
    localparam signed [WIDTH-1:0] ONE_THIRD = 16'h2AAB;
    
    // State machine
    localparam IDLE = 2'b00;
    localparam CALC = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state;
    reg [1:0] mode_reg;
    
    // Sin/Cos lookup or calculation (using small table for common angles)
    reg signed [WIDTH-1:0] sin_theta, cos_theta;
    
    // Intermediate calculation registers
    reg signed [31:0] temp1, temp2, temp3;
    
    // Simplified sin/cos calculation using CORDIC-style or table
    // For this implementation, we'll use a simplified approach
    // In real design, this would interface with CORDIC or use a small table
    
    // Simple 16-entry sin/cos table for demonstration
    // In practice, use CORDIC or larger table
    always @(*) begin
        // Extract upper 4 bits of theta for table lookup
        // theta is in Q15 format, normalized to π
        case (theta[14:11])
            4'h0: begin sin_theta = 16'h0000; cos_theta = 16'h7FFF; end  // 0°
            4'h1: begin sin_theta = 16'h30FC; cos_theta = 16'h7642; end  // 22.5°
            4'h2: begin sin_theta = 16'h5A82; cos_theta = 16'h5A82; end  // 45°
            4'h3: begin sin_theta = 16'h7642; cos_theta = 16'h30FC; end  // 67.5°
            4'h4: begin sin_theta = 16'h7FFF; cos_theta = 16'h0000; end  // 90°
            4'h5: begin sin_theta = 16'h7642; cos_theta = 16'hCF04; end  // 112.5°
            4'h6: begin sin_theta = 16'h5A82; cos_theta = 16'hA57E; end  // 135°
            4'h7: begin sin_theta = 16'h30FC; cos_theta = 16'h89BE; end  // 157.5°
            4'h8: begin sin_theta = 16'h0000; cos_theta = 16'h8001; end  // 180°
            4'h9: begin sin_theta = 16'hCF04; cos_theta = 16'h89BE; end  // 202.5°
            4'hA: begin sin_theta = 16'hA57E; cos_theta = 16'hA57E; end  // 225°
            4'hB: begin sin_theta = 16'h89BE; cos_theta = 16'hCF04; end  // 247.5°
            4'hC: begin sin_theta = 16'h8001; cos_theta = 16'h0000; end  // 270°
            4'hD: begin sin_theta = 16'h89BE; cos_theta = 16'h30FC; end  // 292.5°
            4'hE: begin sin_theta = 16'hA57E; cos_theta = 16'h5A82; end  // 315°
            4'hF: begin sin_theta = 16'hCF04; cos_theta = 16'h7642; end  // 337.5°
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            alpha_out <= 0;
            beta_out <= 0;
            d_out <= 0;
            q_out <= 0;
            ia_out <= 0;
            ib_out <= 0;
            ic_out <= 0;
            valid <= 0;
            mode_reg <= 0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 0;
                    if (start) begin
                        mode_reg <= mode;
                        state <= CALC;
                    end
                end
                
                CALC: begin
                    case (mode_reg)
                        2'b00: begin  // Clarke Transform: abc → αβ
                            // α = Ia
                            // β = (Ia + 2*Ib) / sqrt(3)
                            alpha_out <= ia;
                            
                            // Calculate β
                            temp1 = ia + (ib <<< 1);  // Ia + 2*Ib
                            temp2 = (temp1 * INV_SQRT3) >>> 15;  // Divide by sqrt(3)
                            beta_out <= temp2[WIDTH-1:0];
                            
                            state <= DONE;
                        end
                        
                        2'b01: begin  // Inverse Clarke: αβ → abc
                            // Ia = α
                            // Ib = -α/2 + sqrt(3)/2 * β
                            // Ic = -α/2 - sqrt(3)/2 * β
                            
                            ia_out <= alpha_in;
                            
                            // Ib calculation
                            temp1 = -(alpha_in >>> 1);  // -α/2
                            temp2 = (beta_in * SQRT3_2) >>> 15;  // sqrt(3)/2 * β
                            ib_out <= (temp1 + temp2);
                            
                            // Ic calculation
                            ic_out <= (temp1 - temp2);
                            
                            state <= DONE;
                        end
                        
                        2'b10: begin  // Park Transform: αβ → dq
                            // d =  α*cos(θ) + β*sin(θ)
                            // q = -α*sin(θ) + β*cos(θ)
                            
                            // D-axis
                            temp1 = (alpha_in * cos_theta) >>> 15;
                            temp2 = (beta_in * sin_theta) >>> 15;
                            d_out <= (temp1 + temp2);
                            
                            // Q-axis
                            temp3 = (alpha_in * sin_theta) >>> 15;
                            q_out <= (-temp3 + temp1);
                            
                            state <= DONE;
                        end
                        
                        2'b11: begin  // Inverse Park: dq → αβ
                            // α = d*cos(θ) - q*sin(θ)
                            // β = d*sin(θ) + q*cos(θ)
                            
                            // Alpha
                            temp1 = (d_in * cos_theta) >>> 15;
                            temp2 = (q_in * sin_theta) >>> 15;
                            alpha_out <= (temp1 - temp2);
                            
                            // Beta
                            temp3 = (d_in * sin_theta) >>> 15;
                            beta_out <= (temp3 + ((q_in * cos_theta) >>> 15));
                            
                            state <= DONE;
                        end
                    endcase
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

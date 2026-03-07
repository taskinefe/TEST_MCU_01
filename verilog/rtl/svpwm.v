`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: svpwm
// Description: Space Vector PWM Generator for 3-Phase Motor Control
// 
// Converts V_alpha and V_beta (from inverse Park transform) into
// 3-phase PWM duty cycles (Ta, Tb, Tc) using SVPWM algorithm
//
// Features:
//   - 6 sector calculation
//   - Automatic duty cycle computation
//   - Optimized for hardware implementation
//   - Fixed-point arithmetic (16-bit)
//=============================================================================

module svpwm #(
    parameter DATA_WIDTH = 16,      // Fixed-point Q15 format
    parameter PWM_PERIOD = 2000     // Default 10kHz @ 40MHz
)(
    input  wire                      clk,
    input  wire                      rst_n,
    
    // Input voltage vector (Q15 fixed-point, -1.0 to +1.0)
    input  wire signed [DATA_WIDTH-1:0] v_alpha,  // Alpha component
    input  wire signed [DATA_WIDTH-1:0] v_beta,   // Beta component
    input  wire        [15:0]            vdc,      // DC bus voltage (for normalization)
    input  wire                          update,   // Update strobe
    
    // Output duty cycles (0 to PWM_PERIOD)
    output reg  [15:0]               duty_a,
    output reg  [15:0]               duty_b,
    output reg  [15:0]               duty_c,
    output reg                       ready
);

    // SVPWM constants (Q15 format)
    localparam signed [DATA_WIDTH-1:0] SQRT3 = 16'sh6ED9;  // 1.732 in Q15 = 0.866 normalized
    localparam signed [DATA_WIDTH-1:0] ONE   = 16'sh7FFF;  // 1.0 in Q15
    localparam signed [DATA_WIDTH-1:0] HALF  = 16'sh4000;  // 0.5 in Q15
    
    // Sector determination signals
    reg [2:0] sector;
    wire signed [DATA_WIDTH-1:0] v1, v2, v3;
    
    // Calculate reference frame vectors
    // v1 = v_beta
    // v2 = (-v_beta + sqrt(3)*v_alpha) / 2
    // v3 = (-v_beta - sqrt(3)*v_alpha) / 2
    
    assign v1 = v_beta;
    
    wire signed [DATA_WIDTH*2-1:0] v2_temp;
    wire signed [DATA_WIDTH*2-1:0] v3_temp;
    wire signed [DATA_WIDTH-1:0] sqrt3_alpha;
    
    // Multiply v_alpha by sqrt(3)
    assign v2_temp = (v_alpha * SQRT3) >>> 15;
    assign v3_temp = (v_alpha * SQRT3) >>> 15;
    assign sqrt3_alpha = v2_temp[DATA_WIDTH-1:0];
    
    assign v2 = (-v_beta + sqrt3_alpha) >>> 1;  // Divide by 2
    assign v3 = (-v_beta - sqrt3_alpha) >>> 1;
    
    // Sector determination (based on sign of v1, v2, v3)
    always @(*) begin
        case ({v3[15], v2[15], v1[15]})  // Check sign bits
            3'b001: sector = 3'd1;
            3'b011: sector = 3'd2;
            3'b010: sector = 3'd3;
            3'b110: sector = 3'd4;
            3'b100: sector = 3'd5;
            3'b101: sector = 3'd6;
            default: sector = 3'd1;
        endcase
    end
    
    // Time calculations (T1, T2, T0)
    reg signed [DATA_WIDTH-1:0] t1, t2;
    reg [15:0] t0;
    reg [15:0] t1_cycles, t2_cycles, t0_cycles;
    
    // Calculate T1 and T2 based on sector
    always @(*) begin
        case (sector)
            3'd1: begin
                t1 = -v2;
                t2 = -v3;
            end
            3'd2: begin
                t1 = v2;
                t2 = v1;
            end
            3'd3: begin
                t1 = -v1;
                t2 = v2;
            end
            3'd4: begin
                t1 = v3;
                t2 = -v1;
            end
            3'd5: begin
                t1 = -v3;
                t2 = -v2;
            end
            3'd6: begin
                t1 = v1;
                t2 = v3;
            end
            default: begin
                t1 = 0;
                t2 = 0;
            end
        endcase
    end
    
    // Convert to PWM cycles
    // T1_cycles = (T1 * PWM_PERIOD) / 32768
    wire [31:0] t1_product;
    wire [31:0] t2_product;
    
    assign t1_product = (t1 >= 0) ? (t1 * PWM_PERIOD) : 0;
    assign t2_product = (t2 >= 0) ? (t2 * PWM_PERIOD) : 0;
    
    always @(*) begin
        t1_cycles = t1_product[30:15];  // Divide by 32768 (Q15)
        t2_cycles = t2_product[30:15];
        
        // T0 = PWM_PERIOD - T1 - T2 (zero vector time)
        if (t1_cycles + t2_cycles < PWM_PERIOD)
            t0_cycles = PWM_PERIOD - t1_cycles - t2_cycles;
        else begin
            // Saturation
            t1_cycles = PWM_PERIOD >> 1;
            t2_cycles = PWM_PERIOD >> 1;
            t0_cycles = 0;
        end
    end
    
    // Calculate duty cycles based on sector
    reg [15:0] ta_temp, tb_temp, tc_temp;
    
    always @(*) begin
        case (sector)
            3'd1: begin
                ta_temp = t1_cycles + t2_cycles + (t0_cycles >> 1);
                tb_temp = t2_cycles + (t0_cycles >> 1);
                tc_temp = t0_cycles >> 1;
            end
            3'd2: begin
                ta_temp = t1_cycles + (t0_cycles >> 1);
                tb_temp = t1_cycles + t2_cycles + (t0_cycles >> 1);
                tc_temp = t0_cycles >> 1;
            end
            3'd3: begin
                ta_temp = t0_cycles >> 1;
                tb_temp = t1_cycles + t2_cycles + (t0_cycles >> 1);
                tc_temp = t2_cycles + (t0_cycles >> 1);
            end
            3'd4: begin
                ta_temp = t0_cycles >> 1;
                tb_temp = t1_cycles + (t0_cycles >> 1);
                tc_temp = t1_cycles + t2_cycles + (t0_cycles >> 1);
            end
            3'd5: begin
                ta_temp = t2_cycles + (t0_cycles >> 1);
                tb_temp = t0_cycles >> 1;
                tc_temp = t1_cycles + t2_cycles + (t0_cycles >> 1);
            end
            3'd6: begin
                ta_temp = t1_cycles + t2_cycles + (t0_cycles >> 1);
                tb_temp = t0_cycles >> 1;
                tc_temp = t1_cycles + (t0_cycles >> 1);
            end
            default: begin
                ta_temp = PWM_PERIOD >> 1;
                tb_temp = PWM_PERIOD >> 1;
                tc_temp = PWM_PERIOD >> 1;
            end
        endcase
    end
    
    // Register outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            duty_a <= PWM_PERIOD >> 1;
            duty_b <= PWM_PERIOD >> 1;
            duty_c <= PWM_PERIOD >> 1;
            ready <= 1'b0;
        end else if (update) begin
            duty_a <= ta_temp;
            duty_b <= tb_temp;
            duty_c <= tc_temp;
            ready <= 1'b1;
        end else begin
            ready <= 1'b0;
        end
    end

endmodule

`default_nettype wire

`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: motor_pwm
// Description: 3-Phase Center-Aligned Complementary PWM for BLDC/PMSM Motor Control
// Features:
//   - 3 complementary PWM pairs (6 outputs)
//   - Center-aligned (up/down counting)
//   - Programmable dead-time
//   - ADC trigger at PWM center
//   - Adjustable frequency (5-12 kHz @ 40MHz clock)
//=============================================================================

module motor_pwm #(
    parameter DEADTIME_WIDTH = 8
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // Control
    input  wire        enable,
    input  wire [15:0] period,          // PWM period (ARR)
    input  wire [15:0] duty_a,          // Phase A duty cycle
    input  wire [15:0] duty_b,          // Phase B duty cycle
    input  wire [15:0] duty_c,          // Phase C duty cycle
    input  wire [DEADTIME_WIDTH-1:0] deadtime,  // Dead-time in clock cycles
    
    // PWM Outputs (complementary pairs)
    output wire        pwm_ah,          // Phase A high-side
    output wire        pwm_al,          // Phase A low-side
    output wire        pwm_bh,          // Phase B high-side
    output wire        pwm_bl,          // Phase B low-side
    output wire        pwm_ch,          // Phase C high-side
    output wire        pwm_cl,          // Phase C low-side
    
    // ADC Trigger
    output reg         adc_trigger,     // Pulse at PWM center
    
    // Status
    output reg         pwm_period_flag  // Period complete flag
);

    // Center-aligned counter
    reg [15:0] counter;
    reg        direction;  // 1=up, 0=down
    
    // Compare match flags
    wire match_period;
    wire match_zero;
    wire match_a;
    wire match_b;
    wire match_c;
    
    assign match_period = (counter == period);
    assign match_zero   = (counter == 16'h0000);
    assign match_a      = (counter == duty_a);
    assign match_b      = (counter == duty_b);
    assign match_c      = (counter == duty_c);
    
    // Center-aligned up/down counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 16'h0000;
            direction <= 1'b1;  // Start counting up
        end else if (enable) begin
            if (direction) begin
                // Counting up
                if (match_period) begin
                    direction <= 1'b0;  // Switch to down
                    counter <= counter - 1;
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                // Counting down
                if (match_zero) begin
                    direction <= 1'b1;  // Switch to up
                    counter <= counter + 1;
                end else begin
                    counter <= counter - 1;
                end
            end
        end else begin
            counter <= 16'h0000;
            direction <= 1'b1;
        end
    end
    
    // Period flag generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_period_flag <= 1'b0;
        else
            pwm_period_flag <= match_period & direction;  // Flag at top
    end
    
    // ADC trigger generation (at center - when reaching period while counting up)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            adc_trigger <= 1'b0;
        else
            adc_trigger <= match_period & direction;  // Trigger at center (top)
    end
    
    // PWM generation with SR flip-flop behavior (center-aligned)
    reg pwm_a_raw, pwm_b_raw, pwm_c_raw;
    
    // Phase A PWM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_a_raw <= 1'b0;
        else if (!enable)
            pwm_a_raw <= 1'b0;
        else begin
            if (match_a) begin
                if (direction)
                    pwm_a_raw <= 1'b1;  // Set on match while counting up
                else
                    pwm_a_raw <= 1'b0;  // Clear on match while counting down
            end
        end
    end
    
    // Phase B PWM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_b_raw <= 1'b0;
        else if (!enable)
            pwm_b_raw <= 1'b0;
        else begin
            if (match_b) begin
                if (direction)
                    pwm_b_raw <= 1'b1;
                else
                    pwm_b_raw <= 1'b0;
            end
        end
    end
    
    // Phase C PWM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pwm_c_raw <= 1'b0;
        else if (!enable)
            pwm_c_raw <= 1'b0;
        else begin
            if (match_c) begin
                if (direction)
                    pwm_c_raw <= 1'b1;
                else
                    pwm_c_raw <= 1'b0;
            end
        end
    end
    
    // Dead-time insertion for complementary outputs
    reg [DEADTIME_WIDTH-1:0] dt_counter_ah, dt_counter_al;
    reg [DEADTIME_WIDTH-1:0] dt_counter_bh, dt_counter_bl;
    reg [DEADTIME_WIDTH-1:0] dt_counter_ch, dt_counter_cl;
    
    reg pwm_ah_reg, pwm_al_reg;
    reg pwm_bh_reg, pwm_bl_reg;
    reg pwm_ch_reg, pwm_cl_reg;
    
    // Phase A dead-time logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_ah_reg <= 1'b0;
            dt_counter_ah <= {DEADTIME_WIDTH{1'b0}};
        end else begin
            if (pwm_a_raw && !pwm_ah_reg) begin
                // Rising edge - apply dead-time
                if (dt_counter_ah == deadtime) begin
                    pwm_ah_reg <= 1'b1;
                    dt_counter_ah <= {DEADTIME_WIDTH{1'b0}};
                end else begin
                    dt_counter_ah <= dt_counter_ah + 1;
                end
            end else if (!pwm_a_raw && pwm_ah_reg) begin
                // Falling edge - immediate
                pwm_ah_reg <= 1'b0;
                dt_counter_ah <= {DEADTIME_WIDTH{1'b0}};
            end
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_al_reg <= 1'b0;
            dt_counter_al <= {DEADTIME_WIDTH{1'b0}};
        end else begin
            if (!pwm_a_raw && pwm_al_reg) begin
                // Rising edge (inverted) - apply dead-time
                if (dt_counter_al == deadtime) begin
                    pwm_al_reg <= 1'b0;
                    dt_counter_al <= {DEADTIME_WIDTH{1'b0}};
                end else begin
                    dt_counter_al <= dt_counter_al + 1;
                end
            end else if (pwm_a_raw && !pwm_al_reg) begin
                // Falling edge (inverted) - immediate
                pwm_al_reg <= 1'b1;
                dt_counter_al <= {DEADTIME_WIDTH{1'b0}};
            end else if (!pwm_a_raw && !pwm_al_reg) begin
                // Both low during dead-time
                pwm_al_reg <= 1'b0;
            end
        end
    end
    
    // Phase B dead-time logic (same as A)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_bh_reg <= 1'b0;
            dt_counter_bh <= {DEADTIME_WIDTH{1'b0}};
        end else begin
            if (pwm_b_raw && !pwm_bh_reg) begin
                if (dt_counter_bh == deadtime) begin
                    pwm_bh_reg <= 1'b1;
                    dt_counter_bh <= {DEADTIME_WIDTH{1'b0}};
                end else begin
                    dt_counter_bh <= dt_counter_bh + 1;
                end
            end else if (!pwm_b_raw && pwm_bh_reg) begin
                pwm_bh_reg <= 1'b0;
                dt_counter_bh <= {DEADTIME_WIDTH{1'b0}};
            end
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_bl_reg <= 1'b0;
            dt_counter_bl <= {DEADTIME_WIDTH{1'b0}};
        end else begin
            if (!pwm_b_raw && pwm_bl_reg) begin
                if (dt_counter_bl == deadtime) begin
                    pwm_bl_reg <= 1'b0;
                    dt_counter_bl <= {DEADTIME_WIDTH{1'b0}};
                end else begin
                    dt_counter_bl <= dt_counter_bl + 1;
                end
            end else if (pwm_b_raw && !pwm_bl_reg) begin
                pwm_bl_reg <= 1'b1;
                dt_counter_bl <= {DEADTIME_WIDTH{1'b0}};
            end else if (!pwm_b_raw && !pwm_bl_reg) begin
                pwm_bl_reg <= 1'b0;
            end
        end
    end
    
    // Phase C dead-time logic (same as A)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_ch_reg <= 1'b0;
            dt_counter_ch <= {DEADTIME_WIDTH{1'b0}};
        end else begin
            if (pwm_c_raw && !pwm_ch_reg) begin
                if (dt_counter_ch == deadtime) begin
                    pwm_ch_reg <= 1'b1;
                    dt_counter_ch <= {DEADTIME_WIDTH{1'b0}};
                end else begin
                    dt_counter_ch <= dt_counter_ch + 1;
                end
            end else if (!pwm_c_raw && pwm_ch_reg) begin
                pwm_ch_reg <= 1'b0;
                dt_counter_ch <= {DEADTIME_WIDTH{1'b0}};
            end
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_cl_reg <= 1'b0;
            dt_counter_cl <= {DEADTIME_WIDTH{1'b0}};
        end else begin
            if (!pwm_c_raw && pwm_cl_reg) begin
                if (dt_counter_cl == deadtime) begin
                    pwm_cl_reg <= 1'b0;
                    dt_counter_cl <= {DEADTIME_WIDTH{1'b0}};
                end else begin
                    dt_counter_cl <= dt_counter_cl + 1;
                end
            end else if (pwm_c_raw && !pwm_cl_reg) begin
                pwm_cl_reg <= 1'b1;
                dt_counter_cl <= {DEADTIME_WIDTH{1'b0}};
            end else if (!pwm_c_raw && !pwm_cl_reg) begin
                pwm_cl_reg <= 1'b0;
            end
        end
    end
    
    // Output assignments
    assign pwm_ah = pwm_ah_reg;
    assign pwm_al = ~pwm_al_reg;  // Inverted for complementary
    assign pwm_bh = pwm_bh_reg;
    assign pwm_bl = ~pwm_bl_reg;
    assign pwm_ch = pwm_ch_reg;
    assign pwm_cl = ~pwm_cl_reg;

endmodule

`default_nettype wire

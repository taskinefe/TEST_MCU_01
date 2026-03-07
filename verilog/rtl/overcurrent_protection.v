`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: overcurrent_protection
// Description: 3-Phase Overcurrent Protection with Programmable DAC Threshold
//
// Features:
// - Programmable 8-bit DAC for threshold control
// - 3 independent comparators (one per phase)
// - Fault output (high when any phase exceeds threshold)
// - PWM shutdown on fault
// - Software-controlled fault clear
//=============================================================================

module overcurrent_protection (
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif

    // System
    input  wire        clk,
    input  wire        rst_n,
    
    // DAC Control (threshold setting)
    input  wire [7:0]  dac_value,       // 8-bit threshold control
    input  wire        dac_enable,      // DAC enable
    
    // Analog Inputs (from current sensors)
    input  wire real   phase_a_current, // Phase A analog voltage
    input  wire real   phase_b_current, // Phase B analog voltage
    input  wire real   phase_c_current, // Phase C analog voltage
    
    // Threshold output (from DAC)
    output wire real   dac_threshold,   // DAC output voltage
    
    // Fault Control
    input  wire        fault_clear,     // Clear fault (write 1)
    
    // Fault Status
    output wire        fault_a,         // Phase A fault
    output wire        fault_b,         // Phase B fault
    output wire        fault_c,         // Phase C fault
    output wire        fault_any,       // Any phase fault (OR)
    
    // PWM Shutdown
    output wire        pwm_shutdown,    // Stop all PWMs
    
    // Interrupt
    output wire        irq              // Fault IRQ
);

    //=========================================================================
    // 8-bit DAC (Resistive Ladder)
    //=========================================================================
    
    // DAC output voltage calculation
    // V_out = (dac_value / 256) × 3.3V
    
    real dac_voltage;
    
    always @(*) begin
        if (dac_enable) begin
            dac_voltage = (dac_value / 256.0) * 3.3;
        end else begin
            dac_voltage = 0.0;
        end
    end
    
    assign dac_threshold = dac_voltage;
    
    //=========================================================================
    // 3 Analog Comparators (one per phase)
    //=========================================================================
    
    // Comparator A: Phase A current vs threshold
    reg comp_a_out;
    always @(*) begin
        if (phase_a_current > dac_voltage) begin
            comp_a_out = 1'b1;  // Overcurrent detected
        end else begin
            comp_a_out = 1'b0;
        end
    end
    
    // Comparator B: Phase B current vs threshold
    reg comp_b_out;
    always @(*) begin
        if (phase_b_current > dac_voltage) begin
            comp_b_out = 1'b1;  // Overcurrent detected
        end else begin
            comp_b_out = 1'b0;
        end
    end
    
    // Comparator C: Phase C current vs threshold
    reg comp_c_out;
    always @(*) begin
        if (phase_c_current > dac_voltage) begin
            comp_c_out = 1'b1;  // Overcurrent detected
        end else begin
            comp_c_out = 1'b0;
        end
    end
    
    //=========================================================================
    // Fault Latching Logic
    //=========================================================================
    
    // Latch faults until cleared by software
    reg fault_a_latched;
    reg fault_b_latched;
    reg fault_c_latched;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fault_a_latched <= 1'b0;
            fault_b_latched <= 1'b0;
            fault_c_latched <= 1'b0;
        end else begin
            if (fault_clear) begin
                // Clear all faults
                fault_a_latched <= 1'b0;
                fault_b_latched <= 1'b0;
                fault_c_latched <= 1'b0;
            end else begin
                // Latch faults
                if (comp_a_out) fault_a_latched <= 1'b1;
                if (comp_b_out) fault_b_latched <= 1'b1;
                if (comp_c_out) fault_c_latched <= 1'b1;
            end
        end
    end
    
    // Output fault status
    assign fault_a = fault_a_latched;
    assign fault_b = fault_b_latched;
    assign fault_c = fault_c_latched;
    assign fault_any = fault_a_latched | fault_b_latched | fault_c_latched;
    
    //=========================================================================
    // PWM Shutdown Control
    //=========================================================================
    
    // Immediately shutdown PWM on any fault
    assign pwm_shutdown = fault_any;
    
    //=========================================================================
    // Interrupt Generation
    //=========================================================================
    
    // Generate interrupt on fault (edge detection)
    reg fault_any_prev;
    reg irq_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fault_any_prev <= 1'b0;
            irq_reg <= 1'b0;
        end else begin
            fault_any_prev <= fault_any;
            
            // Rising edge detection
            if (fault_any && !fault_any_prev) begin
                irq_reg <= 1'b1;  // Fault occurred
            end else if (fault_clear) begin
                irq_reg <= 1'b0;  // Clear IRQ with fault
            end
        end
    end
    
    assign irq = irq_reg;

endmodule

`default_nettype wire

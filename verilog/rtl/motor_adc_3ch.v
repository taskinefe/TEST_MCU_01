`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: motor_adc_3ch
// Description: 3-Channel Simultaneous ADC Controller for Motor Current Sensing
// Features:
//   - 3 independent 12-bit SAR ADCs
//   - Simultaneous sampling on external trigger
//   - Individual result registers
//   - Combined EOC flag
//=============================================================================

module motor_adc_3ch (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control
    input  wire        trigger,         // External trigger (from motor PWM)
    input  wire        enable,          // Global enable
    input  wire [3:0]  sample_width,    // Sample time for all channels
    
    // Analog inputs
    input  wire real   adc_vin_a,       // Phase A current sense
    input  wire real   adc_vin_b,       // Phase B current sense
    input  wire real   adc_vin_c,       // Phase C current sense
    input  wire real   adc_vrefh,       // Reference high
    input  wire real   adc_vrefl,       // Reference low
    
    // Digital outputs
    output wire [11:0] data_a,          // Phase A result
    output wire [11:0] data_b,          // Phase B result
    output wire [11:0] data_c,          // Phase C result
    output wire        eoc_a,           // End of conversion A
    output wire        eoc_b,           // End of conversion B
    output wire        eoc_c,           // End of conversion C
    output wire        all_eoc,         // All conversions complete
    
    // Comparator outputs (internal)
    output wire        comp_out_a,
    output wire        comp_out_b,
    output wire        comp_out_c
);

    // Trigger synchronization
    reg trigger_r1, trigger_r2;
    wire trigger_pulse;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trigger_r1 <= 1'b0;
            trigger_r2 <= 1'b0;
        end else begin
            trigger_r1 <= trigger;
            trigger_r2 <= trigger_r1;
        end
    end
    
    assign trigger_pulse = trigger_r1 & ~trigger_r2;  // Rising edge detection
    
    // Start signal for all SAR controllers (synchronized)
    wire start_conversion;
    assign start_conversion = trigger_pulse & enable;
    
    // SAR Controller for Channel A
    sar_ctrl #(.SIZE(12)) sar_a (
        .clk(clk),
        .rst_n(rst_n),
        .soc(start_conversion),
        .cmp(comp_out_a),
        .en(enable),
        .swidth(sample_width),
        .sample_n(),
        .data(data_a),
        .eoc(eoc_a),
        .dac_rst()
    );
    
    // SAR Controller for Channel B
    sar_ctrl #(.SIZE(12)) sar_b (
        .clk(clk),
        .rst_n(rst_n),
        .soc(start_conversion),
        .cmp(comp_out_b),
        .en(enable),
        .swidth(sample_width),
        .sample_n(),
        .data(data_b),
        .eoc(eoc_b),
        .dac_rst()
    );
    
    // SAR Controller for Channel C
    sar_ctrl #(.SIZE(12)) sar_c (
        .clk(clk),
        .rst_n(rst_n),
        .soc(start_conversion),
        .cmp(comp_out_c),
        .en(enable),
        .swidth(sample_width),
        .sample_n(),
        .data(data_c),
        .eoc(eoc_c),
        .dac_rst()
    );
    
    // ADC Analog Block for Channel A
    reg sample_hold_a;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sample_hold_a <= 1'b0;
        else if (start_conversion)
            sample_hold_a <= 1'b1;
        else if (eoc_a)
            sample_hold_a <= 1'b0;
    end
    
    sky130_ef_ip__adc3v_12bit_fixed #(.FUNCTIONAL(1)) adc_a (
        .adc_trim(1.8),
        .adc_vCM(0.9),
        .adc_vrefL(adc_vrefl),
        .adc_vrefH(adc_vrefh),
        .adc0(adc_vin_a),
        .adc0_ena(enable),
        .adc0_reset(~rst_n),
        .adc0_hold(sample_hold_a),
        .adc0_dac_val_0(data_a),
        .adc0_comp_out(comp_out_a)
    );
    
    // ADC Analog Block for Channel B
    reg sample_hold_b;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sample_hold_b <= 1'b0;
        else if (start_conversion)
            sample_hold_b <= 1'b1;
        else if (eoc_b)
            sample_hold_b <= 1'b0;
    end
    
    sky130_ef_ip__adc3v_12bit_fixed #(.FUNCTIONAL(1)) adc_b (
        .adc_trim(1.8),
        .adc_vCM(0.9),
        .adc_vrefL(adc_vrefl),
        .adc_vrefH(adc_vrefh),
        .adc0(adc_vin_b),
        .adc0_ena(enable),
        .adc0_reset(~rst_n),
        .adc0_hold(sample_hold_b),
        .adc0_dac_val_0(data_b),
        .adc0_comp_out(comp_out_b)
    );
    
    // ADC Analog Block for Channel C
    reg sample_hold_c;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sample_hold_c <= 1'b0;
        else if (start_conversion)
            sample_hold_c <= 1'b1;
        else if (eoc_c)
            sample_hold_c <= 1'b0;
    end
    
    sky130_ef_ip__adc3v_12bit_fixed #(.FUNCTIONAL(1)) adc_c (
        .adc_trim(1.8),
        .adc_vCM(0.9),
        .adc_vrefL(adc_vrefl),
        .adc_vrefH(adc_vrefh),
        .adc0(adc_vin_c),
        .adc0_ena(enable),
        .adc0_reset(~rst_n),
        .adc0_hold(sample_hold_c),
        .adc0_dac_val_0(data_c),
        .adc0_comp_out(comp_out_c)
    );
    
    // All conversions complete flag
    assign all_eoc = eoc_a & eoc_b & eoc_c;

endmodule

`default_nettype wire

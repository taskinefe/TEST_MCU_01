//--------------------------------------------------------
// Testbench for cosimulation of the ADC analog parts with
// the SAR controller.  This cosimulation requires ngspice
// version 42 or newer.  The SAR controller is implemented
// as a git submodule to this repository.
//
//--------------------------------------------------------
// Written by:
// Tim Edwards
// Efabless corporation
// November 10, 2024
//--------------------------------------------------------

`timescale 1ns/1ps

// The SAR controller is defined here:
// `include "../dependencies/EF_ADC1008A/hdl/rtl/sar_ctrl.v"
`include "sar_ctrl.v"

module adc_testbench(en, dac_rst, sample_n, data, cmp);
   input wire   cmp;		// Comparator output
   output wire	dac_rst;	// RST to CDAC
   output wire	sample_n;	// HOLD to CDAC
   output wire [11:0] data;	// D value to CDAC
   output reg	en;		// ENA to comparator

    // Testbench values to SAR controller
    reg [3:0] swidth;
    reg clk;
    reg rst_n;
    reg soc;

    // SAR controller outputs back to the testbench
    wire eoc;

    // Stimulus
    initial begin
	$display("ADC simulation starting.");
	clk = 1'b0;
	rst_n = 1'b0;
	soc = 1'b0;
	swidth = 4'd4;
	en = 1'b0;

	// Bring system out of reset
	#225;
	rst_n = 1'b1;

	#500;
	// Enable the ADC
	en = 1'b1; 

	#500;
	// Start a conversion
	soc = 1'b1;
	#200;
	soc = 1'b0;

	// Keep running clock until the end of the conversion
	#10000;
	$display("ADC stimulus finished.");
	$finish();
    end

    // Clock
    always begin
	#50;
	clk <= ~clk;
    end

    // Instantiate the SAR controller

    sar_ctrl #(
	.SIZE(12)
    ) sar_ctrl (
	.clk(clk),		// System clock
	.rst_n(rst_n),		// System ~reset
	.soc(soc),		// Start-of-conversion signal
	.cmp(cmp),		// Comparator result
	.en(en),		// ADC enable
	.swidth(swidth),	// 4 bits sample time width in clock cycles
	.sample_n(sample_n),	// sample_n = !sample = HOLD output to CDAC
	.data(data),		// 12-bit output value
	.eoc(eoc),		// end-of-conversion output signal
	.dac_rst(dac_rst)	// RST output to CDAC
    );
    
endmodule;

// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none
/*
 *-------------------------------------------------------------
 *
 * user_project_wrapper
 *
 * This wrapper enumerates all of the pins available to the
 * user for the user project.
 *
 * An example user project is provided in this wrapper.  The
 * example should be removed and replaced with the actual
 * user project.
 *
 *-------------------------------------------------------------
 */

module user_project_wrapper #(
    parameter BITS = 32
) (
`ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
`endif

    // Wishbone Slave ports (WB MI A)
    input wb_clk_i,
    input wb_rst_i,
    input wbs_stb_i,
    input wbs_cyc_i,
    input wbs_we_i,
    input [3:0] wbs_sel_i,
    input [31:0] wbs_dat_i,
    input [31:0] wbs_adr_i,
    output wbs_ack_o,
    output [31:0] wbs_dat_o,

    // Logic Analyzer Signals
    input  [127:0] la_data_in,
    output [127:0] la_data_out,
    input  [127:0] la_oenb,

    // IOs
    input  [`MPRJ_IO_PADS-1:0] io_in,
    output [`MPRJ_IO_PADS-1:0] io_out,
    output [`MPRJ_IO_PADS-1:0] io_oeb,

    // Analog (direct connection to GPIO pad---use with caution)
    // Note that analog I/O is not available on the 7 lowest-numbered
    // GPIO pads, and so the analog_io indexing is offset from the
    // GPIO indexing by 7 (also upper 2 GPIOs do not have analog_io).
    inout [`MPRJ_IO_PADS-10:0] analog_io,

    // Independent clock (on independent integer divider)
    input   user_clock2,

    // User maskable interrupt signals
    output [2:0] user_irq
);

    wire spi0_sclk;
    wire spi0_mosi;
    wire spi0_miso;
    wire spi0_csb;

    wire i2c0_scl_i;
    wire i2c0_scl_o;
    wire i2c0_scl_oen;
    wire i2c0_sda_i;
    wire i2c0_sda_o;
    wire i2c0_sda_oen;

    wire spi1_sclk;
    wire spi1_mosi;
    wire spi1_miso;
    wire spi1_csb;

    wire pwm0_out;
    wire pwm1_out;

    wire adc_comp_out;
    wire real adc_vin;
    wire real adc_vrefh;
    wire real adc_vrefl;
    
    wire motor_adc_trigger;
    wire real motor_adc_vin_a;
    wire real motor_adc_vin_b;
    wire real motor_adc_vin_c;

user_project mprj (
`ifdef USE_POWER_PINS
    .vccd1(vccd1),
    .vssd1(vssd1),
`endif
    .wb_clk_i(wb_clk_i),
    .wb_rst_i(wb_rst_i),
    .wbs_stb_i(wbs_stb_i),
    .wbs_cyc_i(wbs_cyc_i),
    .wbs_we_i(wbs_we_i),
    .wbs_sel_i(wbs_sel_i),
    .wbs_dat_i(wbs_dat_i),
    .wbs_adr_i(wbs_adr_i),
    .wbs_ack_o(wbs_ack_o),
    .wbs_dat_o(wbs_dat_o),
    .user_irq(user_irq),
    .spi0_sclk(spi0_sclk),
    .spi0_mosi(spi0_mosi),
    .spi0_miso(spi0_miso),
    .spi0_csb(spi0_csb),
    .i2c0_scl_i(i2c0_scl_i),
    .i2c0_scl_o(i2c0_scl_o),
    .i2c0_scl_oen(i2c0_scl_oen),
    .i2c0_sda_i(i2c0_sda_i),
    .i2c0_sda_o(i2c0_sda_o),
    .i2c0_sda_oen(i2c0_sda_oen),
    .spi1_sclk(spi1_sclk),
    .spi1_mosi(spi1_mosi),
    .spi1_miso(spi1_miso),
    .spi1_csb(spi1_csb),
    .pwm0_out(pwm0_out),
    .pwm1_out(pwm1_out),
    .adc_vin(adc_vin),
    .adc_vrefh(adc_vrefh),
    .adc_vrefl(adc_vrefl),
    .adc_comp_out(adc_comp_out),
    .motor_adc_vin_a(motor_adc_vin_a),
    .motor_adc_vin_b(motor_adc_vin_b),
    .motor_adc_vin_c(motor_adc_vin_c),
    .motor_adc_trigger(motor_adc_trigger)
);

    assign io_out[5] = spi0_sclk;
    assign io_oeb[5] = 1'b0;

    assign io_out[6] = spi0_mosi;
    assign io_oeb[6] = 1'b0;

    assign spi0_miso = io_in[7];
    assign io_out[7] = 1'b0;
    assign io_oeb[7] = 1'b1;

    assign io_out[8] = spi0_csb;
    assign io_oeb[8] = 1'b0;

    assign i2c0_scl_i = io_in[9];
    assign io_out[9] = 1'b0;
    assign io_oeb[9] = i2c0_scl_oen;

    assign i2c0_sda_i = io_in[10];
    assign io_out[10] = 1'b0;
    assign io_oeb[10] = i2c0_sda_oen;

    assign io_out[11] = spi1_sclk;
    assign io_oeb[11] = 1'b0;

    assign io_out[12] = spi1_mosi;
    assign io_oeb[12] = 1'b0;

    assign spi1_miso = io_in[13];
    assign io_out[13] = 1'b0;
    assign io_oeb[13] = 1'b1;

    assign io_out[14] = spi1_csb;
    assign io_oeb[14] = 1'b0;

    assign io_out[15] = pwm0_out;
    assign io_oeb[15] = 1'b0;

    assign io_out[16] = pwm1_out;
    assign io_oeb[16] = 1'b0;

    assign io_out[`MPRJ_IO_PADS-1:17] = {(`MPRJ_IO_PADS-17){1'b0}};
    assign io_oeb[`MPRJ_IO_PADS-1:17] = {(`MPRJ_IO_PADS-17){1'b1}};

    assign io_out[4:0] = 5'b0;
    assign io_oeb[4:0] = 5'b1;

    assign la_data_out = 128'b0;

    assign adc_vin = analog_io[0];
    assign adc_vrefh = 3.3;
    assign adc_vrefl = 0.0;
    
    assign motor_adc_vin_a = analog_io[1];
    assign motor_adc_vin_b = analog_io[2];
    assign motor_adc_vin_c = analog_io[3];

endmodule	// user_project_wrapper

`default_nettype wire

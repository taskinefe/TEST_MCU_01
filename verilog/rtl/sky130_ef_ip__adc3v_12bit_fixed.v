`timescale 1ns / 1ps
`default_nettype none

module sky130_ef_ip__adc3v_12bit_fixed #(parameter FUNCTIONAL = 1)(
   input  real  adc_trim,
   input  real  adc_vCM,
   input  real  adc_vrefL,
   input  real  adc_vrefH,
   input  real  adc0,
   input        adc0_ena,
   input        adc0_reset,
   input        adc0_hold,
   input [11:0] adc0_dac_val_0,
   output       adc0_comp_out
);

generate
   if(FUNCTIONAL == 1) begin : functional_model
      real dac_value;
      real held_value;

      initial begin
         dac_value = 0.0;
         held_value = 0.0;
      end
      
      always @(posedge adc0_hold) begin
        held_value = adc0;
      end

      always @(*) begin
         if (adc0_ena == 1'b1) begin
            dac_value = adc_vrefL + (adc0_dac_val_0 * (adc_vrefH - adc_vrefL) / 4095.0);
         end else begin
            dac_value = 0.0;
         end
      end
      
      assign adc0_comp_out = (held_value > dac_value) ? 1'b1 : 1'b0;
   end
endgenerate

endmodule
`default_nettype wire

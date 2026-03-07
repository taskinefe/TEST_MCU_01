`timescale 1ns / 1ps
`default_nettype none

module adc_wb_wrapper (
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif

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

    output reg irq,

    input  real adc_vin,
    input  real adc_vrefh,
    input  real adc_vrefl,
    output adc_comp_out
);

    localparam CTRL_REG     = 8'h00;
    localparam STATUS_REG   = 8'h04;
    localparam DATA_REG     = 8'h08;
    localparam CONFIG_REG   = 8'h0C;

    reg [31:0] ctrl_reg;
    reg [31:0] config_reg;
    wire [31:0] status_reg;
    wire [11:0] adc_data;

    wire valid;
    wire [7:0] reg_addr;
    reg ack_reg;

    assign valid = wbs_cyc_i && wbs_stb_i;
    assign reg_addr = wbs_adr_i[7:0];

    wire adc_enable;
    wire adc_start;
    wire [3:0] sample_width;
    assign adc_enable = ctrl_reg[0];
    assign adc_start = ctrl_reg[1];
    assign sample_width = config_reg[3:0];

    wire adc_eoc;
    wire adc_sample_n;

    sar_ctrl #(
        .SIZE(12)
    ) sar_controller (
        .clk(wb_clk_i),
        .rst_n(~wb_rst_i),
        .soc(adc_start),
        .cmp(adc_comp_out),
        .en(adc_enable),
        .swidth(sample_width),
        .sample_n(adc_sample_n),
        .data(adc_data),
        .eoc(adc_eoc),
        .dac_rst()
    );

    wire [11:0] adc_dac_val;
    assign adc_dac_val = adc_data;

    sky130_ef_ip__adc3v_12bit_fixed #(
        .FUNCTIONAL(1)
    ) adc_analog (
        .adc_trim(1.8),
        .adc_vCM(0.9),
        .adc_vrefL(adc_vrefl),
        .adc_vrefH(adc_vrefh),
        .adc0(adc_vin),
        .adc0_ena(adc_enable),
        .adc0_reset(wb_rst_i),
        .adc0_hold(~adc_sample_n),
        .adc0_dac_val_0(adc_dac_val),
        .adc0_comp_out(adc_comp_out)
    );

    assign status_reg = {19'b0, adc_eoc, adc_data};

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ctrl_reg <= 32'h0;
            config_reg <= 32'h0004;
            ack_reg <= 1'b0;
        end else begin
            if (valid && !ack_reg) begin
                ack_reg <= 1'b1;
                if (wbs_we_i) begin
                    case (reg_addr)
                        CTRL_REG: ctrl_reg <= wbs_dat_i;
                        CONFIG_REG: config_reg <= wbs_dat_i;
                        default: ;
                    endcase
                end
            end else begin
                ack_reg <= 1'b0;
                if (adc_eoc) begin
                    ctrl_reg[1] <= 1'b0;
                end
            end
        end
    end

    reg [31:0] rdata;
    always @(*) begin
        case (reg_addr)
            CTRL_REG:   rdata = ctrl_reg;
            STATUS_REG: rdata = status_reg;
            DATA_REG:   rdata = {20'b0, adc_data};
            CONFIG_REG: rdata = config_reg;
            default:    rdata = 32'hDEADBEEF;
        endcase
    end

    assign wbs_dat_o = rdata;
    assign wbs_ack_o = ack_reg;

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            irq <= 1'b0;
        else
            irq <= adc_eoc;
    end

endmodule

`default_nettype wire

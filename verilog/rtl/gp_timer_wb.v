`timescale 1ns / 1ps
`default_nettype none

//=============================================================================
// Module: gp_timer_wb
// Description: General-Purpose Timer with Interrupt
// 
// Features:
//   - 32-bit up/down counter
//   - Configurable prescaler (1 to 65536)
//   - One-shot or periodic mode
//   - Compare match interrupt
//   - Overflow interrupt
//   - Optional PWM output
//=============================================================================

module gp_timer_wb (
`ifdef USE_POWER_PINS
    inout vccd1,
    inout vssd1,
`endif

    // Wishbone Interface
    input  wire        wb_clk_i,
    input  wire        wb_rst_i,
    input  wire        wbs_stb_i,
    input  wire        wbs_cyc_i,
    input  wire        wbs_we_i,
    input  wire [3:0]  wbs_sel_i,
    input  wire [31:0] wbs_dat_i,
    input  wire [31:0] wbs_adr_i,
    output wire        wbs_ack_o,
    output wire [31:0] wbs_dat_o,
    
    // Interrupt output
    output reg         irq,
    
    // Optional PWM output
    output reg         pwm_out
);

    // Register Map
    localparam CTRL_REG      = 8'h00;  // Control register
    localparam PRESCALER_REG = 8'h04;  // Prescaler value
    localparam RELOAD_REG    = 8'h08;  // Reload/period value
    localparam COMPARE_REG   = 8'h0C;  // Compare value
    localparam COUNTER_REG   = 8'h10;  // Current counter value
    localparam STATUS_REG    = 8'h14;  // Status/interrupt flags
    
    // Registers
    reg [31:0] ctrl_reg;
    reg [15:0] prescaler_reg;
    reg [31:0] reload_reg;
    reg [31:0] compare_reg;
    reg [31:0] counter_reg;
    reg [31:0] status_reg;
    
    // Control bits
    wire timer_enable;
    wire timer_start;
    wire periodic_mode;
    wire count_up;
    wire pwm_enable;
    wire irq_on_compare;
    wire irq_on_overflow;
    
    assign timer_enable = ctrl_reg[0];
    assign timer_start = ctrl_reg[1];
    assign periodic_mode = ctrl_reg[2];
    assign count_up = ctrl_reg[3];
    assign pwm_enable = ctrl_reg[4];
    assign irq_on_compare = ctrl_reg[5];
    assign irq_on_overflow = ctrl_reg[6];
    
    // Status flags
    wire compare_flag;
    wire overflow_flag;
    
    assign compare_flag = status_reg[0];
    assign overflow_flag = status_reg[1];
    
    // Wishbone control
    wire valid;
    wire [7:0] reg_addr;
    reg ack_reg;
    
    assign valid = wbs_cyc_i && wbs_stb_i;
    assign reg_addr = wbs_adr_i[7:0];
    
    // Prescaler counter
    reg [15:0] prescaler_counter;
    wire prescaler_tick;
    
    assign prescaler_tick = (prescaler_counter == 16'h0000);
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            prescaler_counter <= 16'h0000;
        else if (timer_enable) begin
            if (prescaler_tick)
                prescaler_counter <= prescaler_reg;
            else
                prescaler_counter <= prescaler_counter - 1;
        end else
            prescaler_counter <= prescaler_reg;
    end
    
    // Timer running state
    reg timer_running;
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            timer_running <= 1'b0;
        else if (timer_start && timer_enable)
            timer_running <= 1'b1;
        else if (!periodic_mode && overflow_flag)
            timer_running <= 1'b0;  // Stop in one-shot mode
        else if (!timer_enable)
            timer_running <= 1'b0;
    end
    
    // Main counter
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            counter_reg <= 32'h0000_0000;
        else if (timer_running && prescaler_tick) begin
            if (count_up) begin
                // Count up
                if (counter_reg >= reload_reg)
                    counter_reg <= 32'h0000_0000;  // Overflow
                else
                    counter_reg <= counter_reg + 1;
            end else begin
                // Count down
                if (counter_reg == 32'h0000_0000)
                    counter_reg <= reload_reg;  // Reload
                else
                    counter_reg <= counter_reg - 1;
            end
        end else if (timer_start && !timer_running)
            counter_reg <= count_up ? 32'h0000_0000 : reload_reg;
    end
    
    // Compare flag
    reg compare_flag_reg;
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            compare_flag_reg <= 1'b0;
        else if (timer_running && prescaler_tick) begin
            if (counter_reg == compare_reg)
                compare_flag_reg <= 1'b1;
            else if (status_reg[0])  // Write 1 to clear
                compare_flag_reg <= 1'b0;
        end else if (status_reg[0])
            compare_flag_reg <= 1'b0;
    end
    
    // Overflow flag
    reg overflow_flag_reg;
    
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            overflow_flag_reg <= 1'b0;
        else if (timer_running && prescaler_tick) begin
            if (count_up && counter_reg >= reload_reg)
                overflow_flag_reg <= 1'b1;
            else if (!count_up && counter_reg == 32'h0000_0000)
                overflow_flag_reg <= 1'b1;
            else if (status_reg[1])  // Write 1 to clear
                overflow_flag_reg <= 1'b0;
        end else if (status_reg[1])
            overflow_flag_reg <= 1'b0;
    end
    
    // PWM output
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            pwm_out <= 1'b0;
        else if (pwm_enable) begin
            if (count_up)
                pwm_out <= (counter_reg < compare_reg);
            else
                pwm_out <= (counter_reg > compare_reg);
        end else
            pwm_out <= 1'b0;
    end
    
    // Interrupt generation
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            irq <= 1'b0;
        else
            irq <= (compare_flag_reg && irq_on_compare) || (overflow_flag_reg && irq_on_overflow);
    end
    
    // Register write logic
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            ctrl_reg <= 32'h0;
            prescaler_reg <= 16'h0000;  // No prescaling
            reload_reg <= 32'hFFFF_FFFF;
            compare_reg <= 32'h7FFF_FFFF;
            status_reg <= 32'h0;
            ack_reg <= 1'b0;
        end else begin
            // Auto-clear start bit
            if (timer_start && timer_running)
                ctrl_reg[1] <= 1'b0;
                
            if (valid && !ack_reg) begin
                ack_reg <= 1'b1;
                if (wbs_we_i) begin
                    case (reg_addr)
                        CTRL_REG:      ctrl_reg <= wbs_dat_i;
                        PRESCALER_REG: prescaler_reg <= wbs_dat_i[15:0];
                        RELOAD_REG:    reload_reg <= wbs_dat_i;
                        COMPARE_REG:   compare_reg <= wbs_dat_i;
                        STATUS_REG:    status_reg <= wbs_dat_i;  // Write 1 to clear flags
                        default: ;
                    endcase
                end
            end else begin
                ack_reg <= 1'b0;
                // Update status register
                status_reg[0] <= compare_flag_reg;
                status_reg[1] <= overflow_flag_reg;
                status_reg[2] <= timer_running;
            end
        end
    end
    
    // Register read logic
    reg [31:0] rdata;
    always @(*) begin
        case (reg_addr)
            CTRL_REG:      rdata = ctrl_reg;
            PRESCALER_REG: rdata = {16'h0, prescaler_reg};
            RELOAD_REG:    rdata = reload_reg;
            COMPARE_REG:   rdata = compare_reg;
            COUNTER_REG:   rdata = counter_reg;
            STATUS_REG:    rdata = status_reg;
            default:       rdata = 32'hDEADBEEF;
        endcase
    end
    
    assign wbs_dat_o = rdata;
    assign wbs_ack_o = ack_reg;

endmodule

`default_nettype wire

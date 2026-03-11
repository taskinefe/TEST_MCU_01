
module sar_ctrl #(
    parameter SIZE = 8
) ( 
    input   wire                clk,        // The core clock
    input   wire                rst_n,      // Active low reset
    input   wire                soc,        // Start of conversion
    input   wire                cmp,        // Analog comparator output
    input   wire                en,	    // ADC enable
    input   wire [3:0]          swidth,     // Sample time width in clock cycles
    output  wire                sample_n,   // Sample_n = !sample = hold
    output  wire [SIZE-1:0]     data,       // The output value
    output  wire                eoc,        // End of conversion
    output  wire                dac_rst     // reset for capacitive array DAC
);
	
    reg [SIZE-1:0]  result;
    reg [SIZE-1:0]  shift;
    reg [3:0]       sample_ctr;

    wire            sample_ctr_match;
    wire [SIZE-1:0] current;
    wire [SIZE-1:0] next;

    assign sample_ctr_match = (swidth == sample_ctr);
	
    // FSM to handle the SAR operation
    reg [2:0]   state, nstate;

    localparam [2:0] IDLE   = 3'd0, 
	             SAMPLE = 3'd1, 
                     RST    = 3'd2,
		     START  = 3'd3,
	             CONV   = 3'd4, 
	             DONE   = 3'd5;

    always @* begin
	case (state)
            IDLE:
		if (soc)
		    nstate = SAMPLE;
                else
		    nstate = IDLE;
            SAMPLE:
		nstate = RST;
            RST:
		if (sample_ctr_match)
		    nstate = START;
                else
		    nstate = RST;
	    START:
		nstate = CONV;
            CONV:
		if (shift == 'b1)
		    nstate = DONE;
                else
		    nstate = CONV;
            DONE:
		nstate = IDLE;
            default:
		nstate = IDLE;
	endcase
    end
	  
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else if (en)
            state <= nstate;
    end

    // Sample Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            sample_ctr <= 'b0;
        else if (en & (state == RST))
            if (sample_ctr_match)
                sample_ctr <= 'b0;
            else
                sample_ctr <= sample_ctr + 'b1;
    end
    
    // Shift Register
    always @(posedge clk or negedge rst_n) begin
 	if (!rst_n)
	    shift <= 'b0;
        else if (en)
            if (state == IDLE) 
                shift <= 1'b1 << (SIZE-1);
            else if (state == CONV)
                shift <= (shift >> 1);
    end

    // The SAR
    assign current = (cmp == 1'b0) ? ~shift : {SIZE{1'b1}};
    assign next = shift >> 1;

    always @(posedge clk or negedge rst_n) begin
	if (!rst_n)
	    result <= 'b0;
        else if (en)
            if (state == IDLE)
                result <= 'b0;
            else if (state == RST) 
                result <= 1'b1 << (SIZE-1);
            else if (state == CONV)
                result <= (result | next) & current; 
    end
    
    assign data = result;
    assign eoc = (state == DONE);
    assign sample_n = ~((state == SAMPLE) || (state == RST));
    assign dac_rst = ((state == RST) || (state == START));

endmodule


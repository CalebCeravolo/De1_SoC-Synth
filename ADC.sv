module ADC 
	// parameters
	// SD: Single ended or differential. 1 for single ended
	// coding (0: two's complement, 1: straight binary)
	#(parameter CODING = 1'b1, parameter SD = 1'b1, parameter OLD = 1'b1)
	// inputs and outputs
	(clk, reset, data, ADC_CONVST, ADC_DIN, ADC_SCLK, ADC_DOUT);
	output ADC_CONVST, ADC_DIN, ADC_SCLK;
	input ADC_DOUT, clk, reset;
	output logic [7:0][11:0] data;
	logic [1:0][7:0][11:0] datac;
	logic [1:0] ADC_CONVSTc, ADC_DINc, ADC_SCLKc;
	ADCn #(.CODING(CODING), .SD(SD)) new_chip_hookup (.clk, .reset, .data(datac[0]), .ADC_CONVST(ADC_CONVSTc[0]), .ADC_DIN(ADC_DINc[0]), .ADC_SCLK(ADC_SCLKc[0]), .ADC_DOUT);
	ADCo #(.CODING(CODING), .RANGE(~SD)) old_chip_hookup (.clk, .reset, .data(datac[1]), .ADC_CONVST(ADC_CONVSTc[1]), .ADC_DIN(ADC_DINc[1]), .ADC_SCLK(ADC_SCLKc[1]), .ADC_DOUT);
	always_comb begin
		ADC_CONVST = (OLD ? ADC_CONVSTc[1] : ADC_CONVSTc[0]);
		ADC_DIN    = (OLD ? ADC_DINc[1]    : ADC_DINc[0]);
		ADC_SCLK   = (OLD ? ADC_SCLKc[1]   : ADC_SCLKc[0]);
		data       = (OLD ? datac[1]       : datac[0]);
	end
endmodule


/*
Description:
Driver for LTC2308 ADC on DE1_SoC board.
See accompanying tutorial document for details.
*/

module ADCn

	// parameters
	// SD: Single ended or differential. 1 for single ended
	// coding (0: two's complement, 1: straight binary)
	#(parameter CODING = 1'b1, parameter SD = 1'b1)
	
	// inputs and outputs
	(clk, reset, data, ADC_CONVST, ADC_DIN, ADC_SCLK, ADC_DOUT);

	// interface inputs / outputs
	input clk, reset;          // clk (50MHz) and reset
	output reg [7:0][11:0] data; // ADC data out, 8 channels, 12 bits per channel
	
	// connect to top level pins
	output logic ADC_CONVST;         // ADC CONVST
	output logic ADC_DIN;          // ADC serial data in (to ADC)
	output logic ADC_SCLK;         // ADC serial clk
	input ADC_DOUT;              // ADC serial data out (from ADC)
	
	// states
	logic [2:0] addr;    // present channel address
	logic [6:0] count;   // present cycle count. CONVST high marks the start of a cycle. 1 count = 20ns with 50Mhz clk
	logic [2:0] which;   // selector of which serial data to send based on the current serial clk cycle
	logic [11:0] buffer; // buffer to store incoming data
	logic OS;
	assign OS = (SD ? addr[0] : 1'b0);
	
	
	// initial values
	initial begin
		ADC_DIN <= 0;
		ADC_SCLK <= 0;
		addr <= 0;
		count <= 0;
		buffer <= 0;
		which <= 0;
	end
	
	// present outgoing serial data bit
	logic sdata;
	// determine serial data output
	always_comb
		case (which)
			3'b000: // Single ended/differential
				sdata = SD;
			3'b001: // ODD/SIGN
				sdata = OS;
			3'b010: // ADDR2 
				sdata = addr[2];
			3'b011: // ADDR1
				sdata = addr[1];
			3'b100: // CODING
				sdata = CODING;
			3'b101: // SLEEP
				sdata = 1'b0;
			default: // DON'T CARE
				sdata = 1'bx;
		endcase
	
	// Sampling cycle control
	always @(posedge clk) begin
		if (reset) begin
			ADC_DIN <= 0;
			ADC_SCLK <= 0;
			addr <= 0;
			count <= 0;
			buffer <= 0;
			which <= 0;
		end
		else begin
	end
			count<=count+1'b1;
			if (count==0) ADC_CONVST<=1'b1; //
			if (count==2) ADC_CONVST<=1'b0; //Toggle ADC_CONVST to start analog to digital conversion
			
			if (count==78) begin 			  //Prepare first serial data bit
				ADC_DIN<=sdata;
				which<=which+1'b1;
			end
			
			if ((count>=80)&(count<=103)) begin  // After 80 ns, begin serial data transfer
				if (count[0]) begin  //If on an even count. Works only if lower bound of this section is an even number. Otherwise change count to ~count
					ADC_SCLK<=1'b0;
					ADC_DIN<=sdata;
					which<=which+1'b1;
				end else begin
					ADC_SCLK<=1'b1;
					buffer<={buffer[10:0], ADC_DOUT};  //Loads buffer
				end
			end
			
			if (count==120) begin  //After enough time, send data to the buffer and move to the next address 
				data[addr-1'b1]<=buffer;
				addr<=addr+1'b1;
				which<=0;
			end
		end
endmodule

/*
Description:
Driver for AD7928 ADC on DE1_SoC board.
See accompanying tutorial document for details.
*/
module ADCo

	// parameters
	// range (0: 0V-5V, 1: 0V-2.5V)
	// coding (0: two's complement, 1: straight binary)
	#(parameter CODING = 1'b1, parameter RANGE = 1'b0)
	
	// inputs and outputs
	(clk, reset, data, ADC_CONVST, ADC_DIN, ADC_SCLK, ADC_DOUT);

	// interface inputs / outputs
	input clk, reset;          // clk (50MHz) and reset
	output reg [7:0][11:0] data; // ADC data out, 8 channels, 12 bits per channel
	// connect to top level pins
	output reg ADC_CONVST;         // ADC chip selection
	output reg ADC_DIN;          // ADC serial data in (to ADC)
	output reg ADC_SCLK;         // ADC serial clk
	input ADC_DOUT;              // ADC serial data out (from ADC)
	
	logic toggle_bit;
	// internal state holding elements
	logic [2:0] addr;    // present channel address
	logic [5:0] count;   // present cycle count. CONVST high marks the start of a cycle. 1 count = 20ns with 50Mhz clk
	logic [3:0] which;   // selector of which serial data to send based on the current serial clk cycle
	logic [14:0] buffer; // buffer to store incoming data
	logic write;
	logic [1:0] first;
	// initial values
	initial begin
		ADC_DIN <= 1;
		ADC_SCLK <= 1'b1;
		count <= 0;
		buffer <= 0;
		which <= 0;
		toggle_bit<=0;
		ADC_CONVST<=1'b1;
		write<=1'b1;
		addr<=0;
		first<=2'b11;
	end
	
	// intermediate values
	logic sdata;              // present serial data bit
	
	// determine sdata
	always_comb
		case (which)
			4'b0000: // WRITE
				sdata = write;
			4'b0001: // SEQ
				sdata = 1'b1;
			4'b0010: // DON'T CARE
				sdata = 1'bx;
			4'b0011: // ADD2
				sdata = 1'b1;
			4'b0100: // ADD1
				sdata = 1'b1;
			4'b0101: // ADD0
				sdata = 1'b1;
			4'b0110: // PM1
				sdata = 1'b1;
			4'b0111: // PM0
				sdata = 1'b1;
			4'b1000: // SHADOW
				sdata = 1'b1;
			4'b1001: // DON'T CARE
				sdata = 1'bx;
			4'b1010: // RANGE
				sdata = RANGE;
			4'b1011: // CODING
				sdata = CODING;
			default: // DON'T CARE
				sdata = 1'bx;
		endcase
	
	// transitions for state holding elements
	always @(posedge clk) begin
		if (reset) begin
			ADC_DIN <= 0;
			ADC_SCLK <=1'b1;
			count <= 0;
			buffer <= 0;
			which <= 0;
			toggle_bit<=0;
			ADC_CONVST<=1'b1;
			addr<=0;
			first<=1'b1;
		end
		else begin
			toggle_bit<=toggle_bit+1'b1;
			if (&toggle_bit) begin 
				count<=count+1'b1;
				if (|first) begin
					if (first!=2'b11) begin
						if (count==0) begin 
							ADC_CONVST<=1'b0;
							ADC_DIN<=1'b1;
						end
						if ((count>=1)&(count<=31)) begin  
							if (count[0]) begin  //If on an odd count. Works only if lower bound of this section is an even number. Otherwise change count to ~count
								ADC_SCLK<=1'b0;
							end else begin
								ADC_SCLK<=1'b1;
								ADC_DIN<=1'b1;
							end
						end
						if (count==32) begin
							ADC_SCLK<=1'b1;
						end
						if (count==33) begin
							ADC_CONVST<=1'b1;
							first<=first-1'b1;
							count<=0;
						end
					end
					if (count==63) first<=first-1'b1;
				end
				else if (write) begin
					if (count==0) begin 
						ADC_CONVST<=1'b0;
						ADC_DIN<=sdata;
						which<=which+1'b1;
					end
					if ((count>=1)&(count<=31)) begin  
						if (count[0]) begin  //If on an odd count. Works only if lower bound of this section is an even number. Otherwise change count to ~count
							ADC_SCLK<=1'b0;
						end else begin
							ADC_SCLK<=1'b1;
							ADC_DIN<=sdata;
							which<=which+1'b1;
						end
					end
					if (count==32) begin
						ADC_SCLK<=1'b1;
					end
					if (count==33) begin
						ADC_CONVST<=1'b1;
					end
					if (count==63) begin
						write<=0;
						ADC_DIN<=1'b0;
					end
				end 
				else begin
					if (count==0) begin 
						ADC_CONVST<=1'b0;
					end
					if ((count>=11)&(count<=42)) begin  
						if (count[0]) begin  //If on an odd count. Works only if lower bound of this section is an even number. Otherwise change count to ~count
							ADC_SCLK<=1'b0;
							buffer<={buffer[13:0], ADC_DOUT}; //Loads buffer
						end else begin
							ADC_SCLK<=1'b1;
						end
					end
					if (count==43) begin  //After enough time, send data to the buffer and move to the next address 
						data[buffer[14:12]]<=buffer[11:0];
						ADC_CONVST<=1'b1;
					end
				end
			end
		end
	end
endmodule 
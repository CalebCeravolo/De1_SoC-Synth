/*/
	Module for the combination of the different instruments except for the triangle wave. Even though it is called sinewave
	it is actually for all non mathematically generated instruments. When given the
/*/
module sinewave 
	#(parameter num_notes = 6)
	(clk, out, stop, freq, reset, CLOCK_50, volume, which);
	
	logic [num_notes-1:0][16:0] x_val;
	input logic [1:0] which;
	input logic [num_notes-1:0][11:0] freq;
	input logic [num_notes-1:0] stop;
	input logic clk, reset, CLOCK_50;
	input logic [num_notes-1:0][3:0] volume;
	integer i;
	
	output logic signed [num_notes-1:0][23:0] out;
	
	logic [3:0] current;
	logic signed [23:0] wave;
	logic signed [23:0] fwave;
	logic signed [23:0] twave;
	logic signed [23:0] swave;
	
	//logic next_toggle;
	
	trumpet tvals (.x_val(x_val[current]), .out(twave), .clk(CLOCK_50));
	flute   fvals (.x_val(x_val[current]), .out(fwave), .clk(CLOCK_50));
	sine    svals (.x_val(x_val[current]), .out(swave), .clk(CLOCK_50));
	
	
	assign wave = (which[1] ? (which[0] ?  swave : 0) : (which[0] ?  twave : fwave));
	
	logic trigger;
	on_press advance_xvals (.in(clk), .out(trigger), .clk(CLOCK_50), .reset);
	
	integer j;
	
	logic [3:0] previous;
	
	always_ff @(posedge CLOCK_50) begin
		if (reset) begin
			current<=0;
			x_val<=0;
			out<=0;
		end
		else begin
			if (current==num_notes-1'b1) current<=0;
			else current<=current+1'b1;
			
			out[previous]<=(wave>>>volume[previous]);
			previous<=current;
		end
		if (trigger) begin
			if (~reset) begin
				for (j=0; j<num_notes; j=j+1) begin
					if ((x_val[j]+freq[j])>=48000) x_val[j]<=(x_val[j]+freq[j])-48000;
					
					else if (stop[j]) begin
						if (((x_val[j]<(24000-freq[j]))|(x_val[j]>24000+freq[j]))) x_val[j]<=x_val[j]+freq[j];
						else x_val[j]<=24000;
					end
					else x_val[j]<=x_val[j]+freq[j];
//					else begin
//						if (&which) x_val[j]<=x_val[j]+(freq[j]>>1);
//						else x_val[j]<=x_val[j]+freq[j];
//					end
					
				end
			end
		end
	end
endmodule


module sinewave_testbench();
	logic [5:0][11:0] freq;
	logic clk;
	logic signed [5:0][23:0] out;
	logic reset;
	logic [5:0] stop;
	logic CLOCK_50;
	logic [5:0][3:0] volume;
	logic [1:0] which;
	sinewave testing (.clk, .out, .stop, .freq, .reset, .CLOCK_50, .volume, .which);
	
	initial begin 
		CLOCK_50 = 0;
		forever #(1) CLOCK_50<= ~CLOCK_50;
	end
	
	initial begin
		clk = 0;
		forever #(50) clk <= ~clk; // Forever toggle the clock
	end
		
	initial begin
		which<=2'b11;
		reset<=1;
		stop<=0;
		freq <= {{10'b0000001111},{10'b0000001111},{10'b0000011110},{10'b0000111100},{10'b0001111000},{10'b0000000001}};
		volume <='0;
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		reset<=0;
		repeat(48000) begin
			@(posedge clk);
		end
		$stop;
	end
endmodule


module Triangle_wave (freq, clk, out, reset, stop, volume);
	input logic stop;
	input logic [11:0] freq;
	logic signed [16:0] x_val;
	logic signed [12:0] signed_freq;
	assign signed_freq	= {{1'b0},freq};
	input logic clk;
	output logic signed [23:0] out;
	input logic reset;
	input logic [3:0] volume;
	logic signed [23:0] x_val_logical;

	logic signed [31:0] amplitude;
	logic signed [31:0] slope;
	logic signed [31:0] sampling_rate;
	logic [31:0] negative_amp;
	assign negative_amp	= 32'b11111111111000000000000000000000;
	assign sampling_rate = 48000;
	assign amplitude =  32'b00000000010000000000000000000000;
	assign slope = 4*(amplitude/sampling_rate);
	
	
	
	always_ff @(posedge clk) begin
	
		if (reset) x_val<='0;
		else if ((x_val+signed_freq)>=48000) x_val<=(x_val+signed_freq)-48000;
		else if (stop) begin
			if (((x_val<(12000-freq))|(x_val>12000+freq))&(((x_val<(36000-freq))|(x_val>36000+freq))))
				x_val<=x_val+signed_freq;
			else x_val<=12000;
		end
		else x_val<=x_val+signed_freq;
		
	end
	
	//If you want to change amplitudes, follow the CH::
	always_comb begin
		if (x_val>= 24000) x_val_logical = 48000-x_val;
		else x_val_logical = x_val;
		
		out = (slope * x_val_logical+negative_amp+40576)>>>volume; //CH:: first num to 4(amplitude)/48000, second to amplitude
	end
endmodule

module Triangle_wave_testbench();
	logic [11:0] freq;
	logic clk;
	logic signed [23:0] out;
	logic reset;
	logic stop;
	Triangle_wave testing (.freq, .clk, .out, .reset, .stop);
	
	initial begin
		clk = 0;
		forever #(1) clk <= ~clk; // Forever toggle the clock
	end
		
	initial begin
		reset<=1;
		stop<=0;
		freq <= 10'b0000000001;
		@(posedge clk);
		reset<=0;
		repeat(48000) begin
			@(posedge clk);
		end
		$stop;
	end
endmodule

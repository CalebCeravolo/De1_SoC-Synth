
module tracker (in, write, current_note, current, reset, RedPixels, GrnPixels, clk, mute);
	input logic [10:0] current;
	input logic [2:0] current_note;
	input logic reset, clk, write;
	logic [3:0] pointer;
	input logic in;
	input logic [4:0] mute;
	assign pointer = current/146;
	//logic trigger;
	//input_output_modified2 trig (.in(current_note[0]), .out(trigger), .clk, .reset);
	output logic [15:0][15:0] RedPixels; // 16x16 array of red LEDs
   output logic [15:0][15:0] GrnPixels; // 16x16 array of green LEDs
	integer i;
	always_ff @(posedge clk) begin
		if (reset) begin
			RedPixels<=0;
			GrnPixels<=0;
		end
		else if (write) begin
			GrnPixels[current_note][15-pointer] <= GrnPixels[current_note][15-pointer]|in;
		end
		RedPixels<=0;
		RedPixels[current_note][15-pointer] <= 1'b1;
		for (i=0; i<5; i=i+1) begin
			RedPixels[i][0] <= mute[i];
		end
	end
endmodule

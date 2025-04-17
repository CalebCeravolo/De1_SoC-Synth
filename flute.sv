
module flute (x_val, out, clk);
	input logic clk;
	input logic [16:0] x_val;
	
	(* romstyle = "M10K" *) reg [23:0] memory [48000:0];
	
	output logic signed [23:0] out;
	
	initial $readmemb("flute.txt", memory);
	
	always_ff @(posedge clk) begin
		out<=memory[x_val];
	end
endmodule

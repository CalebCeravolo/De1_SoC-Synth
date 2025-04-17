
module sine (x_val, out, clk);
	input logic [16:0] x_val;
	logic [16:0] logicalX;
	(* romstyle = "logic" *) reg [23:0] memory [48000:0];
	output logic signed [23:0] out;
	input logic clk;
	initial $readmemb("sine.txt", memory);
	
	always_ff @(posedge clk) begin
		out<=memory[x_val];
	end
endmodule


module sine_testbench();
	logic clk;
	logic [16:0] x_val;
	logic signed [23:0] out;
	
	sine test (.x_val, .out, .clk);
	
	initial begin 
		clk = 0;
		forever #(50) clk<=~clk;
	end
	
	initial begin
		x_val<=0;
		@(posedge clk);
		@(posedge clk);
		x_val<=1;
		@(posedge clk);
		x_val<=2;
		@(posedge clk);
		
		repeat(1000) begin
			x_val<=x_val+48;
			@(posedge clk);
		end
		$stop;
	end
endmodule 
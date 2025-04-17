
module trumpet (x_val, out, clk);
	input logic clk;
	input logic [16:0] x_val;
	
	(* romstyle = "M10K" *) reg [23:0] memory [48000:0];
	
	output logic signed [23:0] out;
	
	initial $readmemb("trumpet.txt", memory);
	
	always_ff @(posedge clk) begin
		out<=memory[x_val];
	end
	
endmodule

module trumpet_testbench();
	logic clk;
	logic [16:0] x_val;
	logic signed [23:0] out;
	
	trumpet test (.x_val, .out, .clk);
	
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
		repeat(4800) begin
			x_val<=x_val+1;
			@(posedge clk);
		end
		$stop;
	end
endmodule


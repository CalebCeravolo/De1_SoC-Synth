<<<<<<< HEAD
module sound_ram (clk, addr, in, out, we);
	input logic clk, we;
	reg [64:0][23:0] data;
	input logic [15:0] addr;
	output logic [23:0] out;
	input logic [23:0] in;
	always_ff @(posedge clk) begin
		if (we) data[addr]<=in;
		out<=data[addr];
	end
endmodule
=======
module sound_ram (clk, addr, in, out, we);
	input logic clk, we;
	reg [64:0][23:0] data;
	input logic [15:0] addr;
	output logic [23:0] out;
	input logic [23:0] in;
	always_ff @(posedge clk) begin
		if (we) data[addr]<=in;
		out<=data[addr];
	end
endmodule
>>>>>>> 6cffe6cf964782db9a1364a623e5a75c99bb60cf

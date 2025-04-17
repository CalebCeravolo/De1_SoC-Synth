
module sequence_ram (in,write, address, reset, clk, out, current_note);
	reg [4:0] memory [2047:0]; //1875 representing 375hz sampling for 5 seconds. 4:0 representing 5 notes
	input logic write, reset, clk;
	input logic in;
	input logic [10:0] address;
	input logic [2:0] current_note;
	output logic [4:0] out;
	logic [4:0] write_signal;
	always_comb begin
		case (current_note)
			3'b000: write_signal = {memory[address][4:1], in};
			3'b001: write_signal = {{memory[address][4:2]}, {in}, {memory[address][0]}};
			3'b010: write_signal = {memory[address][4:3], in, memory[address][1:0]};
			3'b011: write_signal = {memory[address][4], in, memory[address][2:0]};
			3'b100: write_signal = {in, memory[address][3:0]};
			default: write_signal = {memory[address][4:1], in};
		endcase
	end
	
	always_ff @(posedge clk) begin
		if (reset)
			memory[address]<=5'b00000;
		else if (write) begin
			memory[address]<=write_signal;
			out<=write_signal;
		end
		else out<=memory[address];
	end
endmodule

module sequence_ram_testbench();
	logic in, write, reset, clk;
	logic [10:0] address;
	logic [4:0] out;
	logic [2:0] current_note;
	sequence_ram testest (.in,.write, .address, .reset, .clk, .out, .current_note);
	initial begin
		clk = 0;
		forever #(1) clk <= ~clk; // Forever toggle the clock
	end
	initial begin
		address = '0;
		current_note = 3'b001;
		in=1'b0;
		write = 0;
		reset = 1;
		@(posedge clk)
		@(posedge clk)
		reset<=0;
		@(posedge clk)
		write<=1;
		in<=1;
		@(posedge clk)
		@(posedge clk)
		@(posedge clk)
		current_note<=1;
		@(posedge clk)
		@(posedge clk)
		@(posedge clk)
		@(posedge clk)
		current_note<=2;
		write<=0;
		@(posedge clk)
		@(posedge clk)
		address = 1;
		@(posedge clk)
		@(posedge clk)
		address = 0;
		@(posedge clk)
		@(posedge clk)
		$stop;
	end
endmodule

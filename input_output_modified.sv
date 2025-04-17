
module input_output_modified (in, out, clk, reset);
	input logic in, clk, reset;
	output logic out;
	logic next_out;
	enum {not_pressed, pressed} state, ns;
	always_comb begin
		case (state)
			not_pressed:
				if (in) begin 
					ns = pressed;
					next_out = 1;
				end
				else begin 
					ns = not_pressed;
					next_out = 0;
				end
			pressed:
				if (in) begin 
					ns = pressed;
					next_out = 0;
				end
				else begin 
					ns = not_pressed;
					next_out = 0;
			end
		endcase
	end
	
	always_ff @(posedge clk) begin
		if (reset) begin
			out <= 0;
			state <= not_pressed;
			end
		else begin
			state <= ns;
			out <= next_out;
			end
	end
endmodule

module input_output_modified_testbench();
	logic in, clk, reset;
	logic out;
	input_output testing (.in, .out, .clk, .reset);
	parameter CLOCK_PERIOD=100;
	initial begin
		clk <= 0;
		forever #(CLOCK_PERIOD/2) clk <= ~clk; // Forever toggle the clock
	end
	initial begin
		reset<=1;
		@(posedge clk);
		reset<=0;
		@(posedge clk);
		in <=0;
		repeat(4) @(posedge clk);
		in <=1;
		repeat(4) @(posedge clk);
		in <=0;
		repeat(4) @(posedge clk);
		in <=1;
		repeat(4) @(posedge clk);
		$stop;
	end
endmodule 
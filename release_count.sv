
module release_count (in, out, reset, clk);
	input logic in, clk, reset;
	output logic out;
	logic next_out, pre_out;
	enum {not_pressed, pressed} state, ns;
	always_comb begin
		case (state)
			not_pressed:
				if (in) begin 
					ns = pressed;
					next_out = 0;
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
					next_out = 1;
			end
		endcase
	end
	
	always_ff @(posedge clk) begin
		if (reset) begin
			out <= 0;
			pre_out<=0;
			state <= not_pressed;
			end
		else begin
			state <= ns;
			pre_out <= next_out;
			out <= pre_out;
			end
	end
endmodule

module release_count_testbench();
	logic in, clk, reset, out;
	release_count testicle (.in, .clk, .reset, .out);
	initial begin
		clk = 0;
		forever #(1) clk <= ~clk; // Forever toggle the clock
	end
		
	initial begin
		in<=0;
		reset<=1;
		@(posedge clk)
		reset<=0;
		@(posedge clk)
		@(posedge clk)
		in<=1;
		@(posedge clk)
		in<=0;
		@(posedge clk)
		@(posedge clk)
		@(posedge clk)
		@(posedge clk)
		in<=1;
		@(posedge clk)
		@(posedge clk)
		$stop;
	end
endmodule	

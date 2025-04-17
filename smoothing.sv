module smoothing (clk, reset, data, smooth);
	input logic clk, reset;
	input logic [11:0] data;
	output logic [11:0] smooth;
	reg [127:0][11:0] all_data;
	logic [6:0] pointer  = 0;
	integer i;
	logic [31:0] sum;
	always_comb begin
		sum=0;
		for (i=0; i<128; i++) begin
			sum=sum+all_data[i];
		end
		smooth = sum/128;
	end
	
	always_ff @(posedge clk) begin
		if (reset) begin
			pointer<=0;
			all_data<=0;
		end
		else begin
			all_data[pointer] <= data;
			pointer<=pointer+1;
		end
	end
endmodule


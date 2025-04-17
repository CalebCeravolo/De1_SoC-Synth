module seg7 (value, HEX, clk);
	input logic [3:0] value;
	input logic clk;
	output logic [6:0] HEX;
	reg [6:0] ROM [10:0];
	
	always_ff @(posedge clk) begin
		HEX<=ROM[value];
	end
	
	always_comb begin
    ROM[0]  = 7'b1000000;
    ROM[1]  = 7'b1111001;
    ROM[2]  = 7'b0100100;
    ROM[3]  = 7'b0110000;
    ROM[4]  = 7'b0011001;
    ROM[5]  = 7'b0010010;
    ROM[6]  = 7'b0000010;
    ROM[7]  = 7'b1111000;
    ROM[8]  = 7'b0000000;
    ROM[9]  = 7'b0010000;
	 ROM[10] = 7'b1111111;
end
endmodule
 
<<<<<<< HEAD
// divided_clocks[0] = 25MHz, [1] = 12.5Mhz, ... [23] = 3Hz, [24] = 1.5Hz, [25] = 0.75Hz, ...
module clock_divider (clock, reset, divided_clocks);
	input logic reset, clock;
	output logic [31:0] divided_clocks = 0;
	always_ff @(posedge clock) begin
		divided_clocks <= divided_clocks + 1;
end
=======
// divided_clocks[0] = 25MHz, [1] = 12.5Mhz, ... [23] = 3Hz, [24] = 1.5Hz, [25] = 0.75Hz, ...
module clock_divider (clock, reset, divided_clocks);
	input logic reset, clock;
	output logic [31:0] divided_clocks = 0;
	always_ff @(posedge clock) begin
		divided_clocks <= divided_clocks + 1;
end
>>>>>>> 6cffe6cf964782db9a1364a623e5a75c99bb60cf
endmodule
module binary_to_bcd (
    input  logic [11:0] binary_in,    // 12-bit ADC value
	 output logic [3:0] thousands,
    output logic [3:0] hundreds,
    output logic [3:0] tens,
    output logic [3:0] ones
);
    logic [27:0] shift_reg; // 12 bits for input + 12 bits BCD + 4 bits buffer

    integer i;
    always_comb begin
        // Clear shift register
        shift_reg = 28'd0;

        // Load binary input into the lower bits
        shift_reg[11:0] = binary_in;

        // Perform 12 shift-add-3 operations (one for each bit)
        for (i = 0; i < 12; i = i + 1) begin
            // ones digit
            if (shift_reg[15:12] >= 5)
                shift_reg[15:12] = shift_reg[15:12] + 3;

            // Tens digit
            if (shift_reg[19:16] >= 5)
                shift_reg[19:16] = shift_reg[19:16] + 3;

            // Hundreds digit
            if (shift_reg[23:20] >= 5)
                shift_reg[23:20] = shift_reg[23:20] + 3;
				// Thousands digit
				
				if (shift_reg[27:24] >= 5)
                shift_reg[27:24] = shift_reg[27:24] + 3;
            // Shift left by 1
            shift_reg = shift_reg << 1;
        end

        // Extract the BCD digits
        ones 	  = shift_reg[15:12];
        tens     = shift_reg[19:16];
        hundreds = shift_reg[23:20];
		  thousands= shift_reg[27:24];
    end
endmodule

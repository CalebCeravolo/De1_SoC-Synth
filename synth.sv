module synth (reset, freqs, play, clk, out, which, volume, CLOCK_50);
	parameter num_notes = 6;
	input logic reset, clk, CLOCK_50;   // clk should be hooked up to advance (the audio clock)
	input logic [5:0] play; 				// Play stores whether to play each note at that instance
	input logic [5:0][11:0] freqs;   	// 9:0 is the bits for representing which frequency a note is
	output logic signed [23:0] out; 		// the audio data to be played
	logic signed [5:0][23:0] note; 		// set of notes from triangle functions to combine
	logic signed [5:0][23:0] mem_notes; // mem notes are the notes generated from memory files and not from math
	logic signed [5:0][23:0] tri_note;  // these are the notes generated from mathematical triangle functions
	input logic [1:0] which; 				// this chooses which instrument to play
	input logic [num_notes-1:0][3:0] volume; 
	logic [11:0] freq;
	logic [3:0] current;
	logic [23:0] triwave;
	
	
	sinewave s_wave (.clk, .out(mem_notes), .stop(~play), .freq(freqs), .reset, .CLOCK_50, .volume, .which);
	
	
	genvar n;
	generate
		for (n=0; n<num_notes; n = n+1) begin : all_notes
			Triangle_wave tr_note (.freq(freqs[n]), .clk(clk), .out(tri_note[n]), .reset, .stop(~play[n]), .volume(volume[n]));
		end
	endgenerate
	
	//assign note = (which ? tri_note : sine_note);
	
	always_comb begin
		case (which)
			2'b10: note = tri_note;
			default: note = mem_notes;
		endcase
	end
	
	logic signed [31:0] numerator;
	assign numerator = 
    (play[0] ? (({{8{note[0][23]}}, note[0]})) : 0) + 
    (play[1] ? (({{8{note[1][23]}}, note[1]})) : 0) + 
    (play[2] ? (({{8{note[2][23]}}, note[2]})) : 0) +
    (play[3] ? (({{8{note[3][23]}}, note[3]})) : 0) +
    (play[4] ? (({{8{note[4][23]}}, note[4]})) : 0) +
	 ((({{8{note[5][23]}}, note[5]})));
	 

	
	logic signed [31:0] denominator;
	assign denominator = (play[0]+play[1]+play[2]+play[3]+play[4]+1'b1);
	
	assign out = numerator/denominator;
endmodule

module synth_testbench();
	logic reset, clk;
	logic signed [23:0] out;
	logic [5:0] play;
	logic [5:0][11:0] freqs;
	logic [1:0] which;
	logic CLOCK_50;
	logic [5:0][3:0] volume;
	synth testing (.reset, .freqs, .play, .clk, .out, .which, .volume, .CLOCK_50);
	
	initial begin
		clk = 0;
		forever #(50) clk <= ~clk; // Forever toggle the clock
	end
	initial begin 
		CLOCK_50 = 0;
		forever #(1) CLOCK_50<= ~CLOCK_50;
	end
	initial begin
		reset<=1;
		freqs <= {{10'b0000001111},{10'b0000001111},{10'b0000011110},{10'b0000111100},{10'b0001111000},{10'b0000000010}};
		which<=2'b11;
		play <= {0,0,0,0,0};
		volume <={6{4'b0000}};
		@(posedge clk);
		reset<=0;
		@(posedge clk);
		@(posedge clk);
		play <= {0,0,0,0,0,1'b1};
		
		repeat(48000) begin
			@(posedge clk);
		end
		$stop;
	end
endmodule 
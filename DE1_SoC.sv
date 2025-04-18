/*/
Top level module connecting together all the lower level modules to the wires of the board.
This project is a Synthesizer. It can be controlled using a potentiometer connected to the adc channels. 
Which channel it is depends on Switches 7-5. There are a range of instruments that can be played, more to follow
I am currently working on interfacing with the on board SDRAM chip which will allow me much more flexibility in what 
the recording feature does. This project started as a final lab project for my college digital logic class but quickly 
became a passion project that I have worked on in my free time
/*/

module DE1_SoC (CLOCK_50, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, KEY, LEDR, SW, GPIO_1,
	FPGA_I2C_SCLK, FPGA_I2C_SDAT, AUD_XCK, AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT, AUD_DACDAT,
	ADC_CONVST, ADC_DIN, ADC_SCLK, ADC_DOUT);
	
	output FPGA_I2C_SCLK;   // I2C Clock Line
   inout  FPGA_I2C_SDAT;  // I2C Data Line
   output AUD_XCK;         // Master Clock to Audio Codec
   input AUD_DACLRCK;     // DAC Left/Right Clock
   input AUD_ADCLRCK;     // ADC Left/Right Clock
   input AUD_BCLK;        // Bit Clock for Serial Audio Data
   input  AUD_ADCDAT;      // ADC Data from Codec
   output AUD_DACDAT; 
	
	input logic CLOCK_50; // 50MHz clock.
	output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	output logic [9:0] LEDR;
	input logic [3:0] KEY; // True when not pressed, False when pressed
	input logic [9:0] SW;
	output logic [35:0] GPIO_1;
	
	logic [31:0] clk;
	clock_divider divider (.clock(CLOCK_50), .divided_clocks(clk));
	
	parameter num_notes = 6;
	logic [3:0] menu;
	assign menu[0] = (~SW[9])&(~SW[8]);
	assign menu[1] = (SW[9])&(~SW[8]); //movement menu (changing notes, adjusting frequencies)
	assign menu[2] = (~SW[9])&(SW[8]); //debug menu
	assign menu[3] = (SW[9])&(SW[8]); //volume menu
	
 	logic [3:0] key_press;
	logic reset;
	logic record; 
	logic play;
	logic voice;
	logic record_released;
	logic reset_released;
	logic next_note;
	logic set_freq;
	logic [1:0] instrument_select;
	logic replay;
	logic [5:0][3:0] volume = {6{4'b0010}};
	logic volume_increase;
	logic volume_decrease;
	logic [num_notes-2:0] mute = 0;
	logic master_volume;
	logic mute_toggle;
	//logic stop;
	
	//Menuing assignments
	always_comb begin 
		reset = ~KEY[2]&menu[0];               	//General reset variable
		record = ~KEY[0]&menu[0];				   	//Records the current frequency on the current note track and advances the pointer
		play = ((~KEY[1]&(~menu[3]))|SW[0]);   	//Pressing key1 or flipping sw0 will always play the current frequency
		voice = ~KEY[3]&menu[0];				   	//Causes data from the audio in channel to play to the audio out channel
		next_note = key_press[0]&(menu[1]);	   	//Moves on to the next note track
		set_freq = key_press[2]&menu[1]|record;	//Sets the frequency of the current note track to the current frequency
		//erase = KEY[3]&menu[1];
		volume_increase = menu[3]&(key_press[3]); //Increases the volume decrease (I know this is confusing)
		volume_decrease = menu[3]&(key_press[1]); //Decreases the volume decrease
		master_volume   = menu[3]&(~KEY[2]);      //Toggles to master volume which causes volume buttons to control all note tracks
		mute_toggle     = menu[3]&(key_press[0]);	//Mutes the current note track
		//single = SW[4];
		instrument_select = {SW[3],SW[2]};			//Selects which instrument will play across all tracks and the constant note
		replay = SW[4];									//Allows the recording and playback pointer to move. Currently causes note disturbance
	end
	
	// Creates signals that go true for one cycle after a button is pressed
	on_press key0_press (.in(~KEY[0]), .out(key_press[0]), .clk(CLOCK_50), .reset);
	on_press key1_press (.in(~KEY[1]), .out(key_press[1]), .clk(CLOCK_50), .reset);
	on_press key2_press (.in(~KEY[2]), .out(key_press[2]), .clk(CLOCK_50), .reset);
	on_press key3_press (.in(~KEY[3]), .out(key_press[3]), .clk(CLOCK_50), .reset);
	
	// Logic for release of record and reset
	release_count record_release (.in(record), .out(record_released), .reset, .clk(advance));
	release_count reset_release (.in(reset), .out(reset_released), .reset(1'b0), .clk(CLOCK_50));
	
	
	// assign stop = (~&recorded_notes)&(~play);
	
	
	/////Audio testing//////
	logic [23:0] dac_left, dac_right, adc_left, adc_right;
	logic advance;
	logic [31:0] div_clock_recording;
	clock_divider rclk (.clock(advance), .divided_clocks(div_clock_recording)); //Divides the advance clock signal which comes from the audio driver
	logic recording_clk; 																		//Uses above divider to generate clock for recording the times to play the notes
	assign recording_clk = div_clock_recording[6];										//^^^
	logic trigger;																					//Trigger that moves the notes player forward at the same rate as the recording clock
	on_press trig (.in(recording_clk), .out(trigger), .clk(advance), .reset(1'b0));//^^^
	
	logic [10:0] current_recording=0; //Where the recording pointer is currently
	logic [4:0] recorded_notes; //set of trues and falses that tells the synth which notes to play at this moment
	logic [2:0] current_note;  //which note the recorder should record to
	logic [4:0][11:0] freqs;   //frequencies 
	logic [11:0] freq;			//current frequency, played by "play"
	logic signed [23:0] wave; 	//wave output from synth to be put into DAC
	logic [10:0] furthest_point = '0; //furthest point in the recording.
	
	//Ram for recording the play signals for the synth
	sequence_ram rec (.in(play), .write(record), .address(current_recording), .reset, .clk(CLOCK_50), .out(recorded_notes), .current_note); 
	
	//Code for 16x16 light display showing the recorded notes
	tracker lighting (.write(record), .current_note, .current(current_recording), .reset, .RedPixels, .GrnPixels, .clk(CLOCK_50), .in(play), .mute); 
	
	//Synth hookup
	synth playa (.reset, .freqs({{freq},{freqs}}), .play(SW[1] ?{{play&(~record)},5'b0}:{{play&(~record)},{(~mute)&recorded_notes}}), .clk(advance), .CLOCK_50, .out(wave), .which(instrument_select), .volume);
	
	//audio driver. Self explanitory
	audio_driver let_there_be_sound (.CLOCK_50, .reset, .dac_left, .dac_right, .adc_left, .adc_right, .advance, .FPGA_I2C_SCLK, .FPGA_I2C_SDAT, .AUD_XCK, .AUD_DACLRCK, .AUD_ADCLRCK, .AUD_BCLK, .AUD_ADCDAT, .AUD_DACDAT);
	
	//Switching between using the switches for the frequency and using the ADC. For debugging hence menu2
	always_comb begin
		if (KEY[3]&menu[2])                  
			freq = {{SW[9:0]},{2'b00}};
		else freq = data;
	end
	
	//logic for activating the audio as soon as the advance signal from the audio driver becomes true
	logic advance2;
	on_press clock_setup (.in(advance), .out(advance2), .clk(CLOCK_50),.reset);
	
	//Integer for looping through notes for audio control
	integer vc;
	
	always_ff @(posedge CLOCK_50) begin
		if (reset) begin
			dac_left<=0;
			dac_right<=0;
			current_note<=0;
			current_recording<=current_recording+1;
		end
		else if (reset_released) begin
			current_recording<=0;
			furthest_point<=0;
		end
		if (next_note) begin
			if (current_note==3'b100)
				current_note<=3'b000;
			else current_note<=current_note+1;
		end
		if (mute_toggle) begin
			mute[current_note] = ~mute[current_note];
		end
		if (set_freq) freqs[current_note]<=freq;
		if (volume_increase) begin
			if (master_volume) begin
					for (vc=0; vc<num_notes-1; vc=vc+1) begin
						if (volume[vc]!=4'b1111) volume[vc]<=volume[vc]+1;
					end
				end
			else begin
				if (play) begin
					if (volume[5]!=4'b1111) begin
						volume[5]<=volume[5]+1;
					end
				end
				else if (volume[current_note]!=4'b1111) begin
					volume[current_note]<=volume[current_note]+1;
				end
			end
		end
		else if (volume_decrease) begin
			if (master_volume) begin
					for (vc=0; vc<num_notes-1; vc=vc+1) begin
						if (volume[vc]!=4'b0001) volume[vc]<=volume[vc]-1;
					end
				end
			
			else begin
				if (play) begin
					if (volume[5]!=4'b0001) begin
						volume[5]<=volume[5]-1;
					end
				end
				else if (volume[current_note]!=4'b0001) begin
					volume[current_note]<=volume[current_note]-1;
				end
			end
		end
		if (advance2) begin
		if (trigger&replay)begin
			if ((~record)&(current_recording==(furthest_point)))
				current_recording<=0;
			else current_recording<=current_recording+1;
		end
		else begin
			
			if (record) begin
				if (furthest_point<current_recording)
					furthest_point<=current_recording;
			end
			
			if (voice) begin
				dac_left <= adc_left;
				dac_right <= adc_right;
			end
//			else if (stop&smooth_stop) begin
//				dac_left <= dac_left>>>1;
//				dac_right <= dac_right>>>1;
//			end
			else begin				
				dac_left<=wave;
				dac_right<=wave;
			end 
		end
		end
	end
	////////////////////////////////
	
	
	/////Visual testing//////
	//Clock for the led board
	logic SYSTEM_CLOCK;
	
	
	assign SYSTEM_CLOCK = clk[14];
	//////////////////////////////
	logic [15:0][15:0]RedPixels; // 16 x 16 array representing red LEDs
   logic [15:0][15:0]GrnPixels; // 16 x 16 array representing green LEDs
	//
	//Connecting to the LED driver module so now you can just interact with red and green pixels directly
	
	LEDDriver Driver (.CLK(SYSTEM_CLOCK), .RST(reset), .EnableCount(1'b1), .RedPixels, .GrnPixels, .GPIO_1);
	
	//conways lighttesting (.reset, .RedPixels, .GrnPixels, .clk(clk[24]));
	//bumpin lightbars (.sound(dac_left),.reset, .RedPixels, .GrnPixels, .clk(clk[24]));
	
	
	/////////////////////////////////////////
	///ADC///
	logic [7:0][11:0] adc_data;
	logic [11:0] data;
	
	smoothing smoth (.clk(clk[14]), .reset, .data(adc_data[SW[7:5]]), .smooth(data));
	
	//assign data = adc_data[SW[7:5]];
	output reg ADC_CONVST;         // ADC chip selection
	output reg ADC_DIN;          // ADC serial data in (to ADC)
	output reg ADC_SCLK;           // ADC serial clock
	input ADC_DOUT;              // ADC serial data out (from ADC)
	ADCo potentiometer_connect (.clk(CLOCK_50), .data(adc_data) ,.reset, .ADC_CONVST, .ADC_DIN, .ADC_SCLK, .ADC_DOUT);
	
	assign LEDR = data[11:2];
	
	logic [5:0][3:0] values;
	
	binary_to_bcd numnum (.binary_in(data), .ones(values[0]), .tens(values[1]), .hundreds(values[2]), .thousands(values[3]));
	assign HEX4 = '1;
	assign HEX5 = '1;
	seg7 bit0 (.value(values[0]), .HEX(HEX0), .clk(CLOCK_50));
	seg7 bit1 (.value(values[1]), .HEX(HEX1), .clk(CLOCK_50));
	seg7 bit2 (.value(values[2]), .HEX(HEX2), .clk(CLOCK_50));
	seg7 bit3 (.value(values[3]), .HEX(HEX3), .clk(CLOCK_50));
	/////////////////////////////////////////
endmodule

module DE1_SoC_testbench();
	
endmodule 
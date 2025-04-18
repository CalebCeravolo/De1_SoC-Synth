# De1_SoC-Synth
Synth for the FPGA. Contains multiple instruments that are selected using the switches on the De1-SoC board.
Peripherals used include the DE-1 LED Diplay Expansion Board designed by Cai Biesinger

INSTRUCTIONS - 
To activate the recording and playback function, flip up switch 4. Otherwise the recording/playback pointer wont move and the notes at the instant it is currently at get recorded to and read from

Switch 0 always plays a note. 

Switch 1 mutes all notes except the constantly played note

Switches 3,2 control which instrument you play
00 is flute
01 is trumpet
10 is triangle
11 is sine

Switches 7-5 control which adc channel the frequency is controlled by

Using the different features of the synth requires the transversal of several menus. Which menu you are on is controlled by switches 9 and 8 (the switches on the far left)

for switch combination 00 (down and down):
KEY0: Record. Records the currently selected frequency on the currently selected note
KEY1: Play. Plays the note when pressed. Same as flipping switch 0
KEY2: Reset. Erases all note recordings, resets the pointer to zero
KEY3: Voice. Sends the data from the audio in channel to the audio out directly. Used to test that the setup is working

for switch combination 01:
KEY0: Next note. Moves on to the next note in the recording. The current note is only seen if using the LED display
KEY1: Play. Plays the note when pressed. Same as flipping switch 0
KEY2: Set Frequency. Sets the frequency of the currently selected note to the current frequency
KEY3: N/A (Planned to be an erase note section in the future)

For switch combination 10: Used as a debug menu. Switch to it to play a constant frequency to bypass adc

For swtich combination 11: 
KEY0: Mute. Mutes the current note
KEY1: Volume up. Increases the volume of the constantly played note (played by switch 0, or key 1 in first 2 menus)
KEY2: Master volume. Hold this to have the volume up and down buttons control all notes volumes (aside from the constantly played note)
KEY3: Volume down. Decreases the volume of the constantly played note

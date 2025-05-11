# CPE 487 Final Project - Piano Note Trainer

##  1. Setup and Board Programming

- Connect the Pmod I2S2 digital to analog converter to port JA on the Nexys A7-100T board
- Connect the plug on the speaker to the green line out audio jack on the I2S2 
- Similarly, connect the Pmod keypad extension to the JB port
- See picture below for proper connections
- ![image](https://github.com/user-attachments/assets/66869f6f-878c-4f6b-b29e-20640a96dc28)


## 2. Create new Vivado project called pianoProject

- Create 7 new VHDL source files named *piano, songs, leddec, keypad, dac_if, wail*, and *tone*
- Create a new XDC design constraint file named *piano*
- Choose the Nexys A7-100T board –> ‘Finish’
- Open design sources and copy the appropriate source files from the repository into Vivado
- Open constraints and do the same with *piano.xdc*
- Alternatively, you can download the code from GitHub and upload it directly into Vivado
- If done correctly, the resulting module hierarchy can be seen below
- ![vhdl hierarchy](https://github.com/user-attachments/assets/f79837ed-986b-491a-b3b2-49185b32e86c)

## 3. Run synthesis
## 4. Run implementation
## 5. Generate bitstream
- Open hardware manager
- Connect to target board
- Upload program

## 6. Usage Instruction
- Use the on-board up and down buttons to select a song
- Click the center button to begin the song
- From there, click the corresponding note on the keypad to match the note displayed on the 7 segment display
- Continue to play, and learn simple piano songs

—

# Code & Modifications

## piano.vhd
*piano.vhd* is the top-level module, and combines the output of all of the lower modules. The file was written from scratch and contains a finite state machine, controlling the functionality of this project. The FSM diagram can be seen below. It also generates the timing for the 7 segment display multiplexer, the keypad sampling clock, and the dac_if and wail modules.

![fsm](https://github.com/user-attachments/assets/a4182262-3fda-463e-9285-300e8fd7b4f8)





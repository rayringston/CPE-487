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


![fsm](https://github.com/user-attachments/assets/c0d8d970-d7bd-4535-b866-969574a6a1c5)

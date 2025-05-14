# CPE 487 Final Project - Piano Note Trainer

##  1. Setup and Board Programming

- Connect the Pmod I2S2 digital to analog converter to port JA on the Nexys A7-100T board
- Connect the plug on the speaker to the green line out audio jack on the I2S2 
- Similarly, connect the Pmod keypad extension to the JB port
- See picture below for proper connections
- ![image](https://github.com/user-attachments/assets/66869f6f-878c-4f6b-b29e-20640a96dc28)


https://github.com/user-attachments/assets/84e967ae-8d87-49e0-90ee-43ad72103245



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
- 
## 7. Video Demo
Click on the image below to watch the video.

[![Watch the video](https://img.youtube.com/vi/KI-7L2Fd2b4/maxresdefault.jpg)](https://youtu.be/KI-7L2Fd2b4)

---

# Code & Modifications

## piano.vhd
*piano.vhd* is the top-level module, and combines the output of all of the lower modules. The file was written from scratch and contains a finite state machine, controlling the functionality of this project. The FSM diagram can be seen below. It also generates the timing for the 7 segment display multiplexer, the keypad sampling clock, and the dac_if and wail modules. The onboard inputs used are Pmod Jb ports for the keypad, as well as BTNU, BTND, and BTNC. The outputs used are the the 7 segment display, and Pmod port Ja to output to the speaker.

![fsm](https://github.com/user-attachments/assets/a4182262-3fda-463e-9285-300e8fd7b4f8)

## songs.vhd

The songs module contains the various songs we have included in this project. It takes an index and a song choice, and outputs the current note, and the length of the song. Each song is implemented as an array of hex values, each corresponding to a note. Currently, we have 4 songs included, Hot Cross Buns (HCb), Mary had a Little Lamb (HLL), Twinkle Twinkle Little Star (tLS), and Row Row Row Your Boat (rYb). Since certain characters cannot be displayed on a seven segment display, the abbreviations in parentheses are what is instead displayed.

## keypad.vhd

This module was reused from Lab 4, with little changes added. The module samples the keypad, and finds the resulting input. In order to make this connect better with other modules, we changed the mapping of the keypad so the first two rows output 0 to 7, rather than the value on the buttons. One other issue with the keypad is the inability to register multiple button presses at the same time. Clearly, on a real piano, you can play multiple notes simultaneously. But, this is not possible with the current implementation of the keypad.

## leddec.vhd

Again, this module has been taken from our previous labs, with some modifications. We used 3 digits to display the title of the song, and only 1 to display the current note. We included an input called title, to choose whether we are currently showing the song choices. While in the ENTER_NOTE state, the current note of the song is instead displayed. This caused another issue, where it was difficult to tell if the button hadn’t been pressed or if the note was simply repeated. To fix this, we included another input called displaying, which, when 0, cleared the display. While in the RELEASE_NOTE state, displaying is set to 0, and the display is briefly empty.

## wail.vhd

This module caused the most issue during its implementation. This file was used in lab 5, but in a very different context. In this lab, the tone is played continuously, and is never stopped. In order to only play the note while a button is pressed, changes were necessary. Previously, the inputs to the module included a low frequency, high frequency, and a wail speed. These were all replaced with a note input, which is the input from the keypad module. We also added a playing input to control when the speaker was making noise. The frequency of each note is included as a constant, and the corresponding frequency is passed down to the tone module.

## tone.vhd

In order to stop the speaker from making noise, the changes had to be made to this module. When the playing input is 1, the data out of this module is just the sawtooth wave we used during the lab. However, when playing is 0, data out becomes 0 and the speaker becomes silent.

## dac_if.vhd
Finally, there is the dac_if, which is used to turn the outputted data from the tone module into noise from the speaker. This module worked perfectly, and did not need any modifications to be functional. This module, as well as *tone.vhd*, were used in lab 5.

## piano.xdc

This is the constraints file, and includes all of the inputs and outputs of the board. For this project, we used the 100 Mhz clock, the anodes and segments of the 7 segment display, BTNU, BTND, BTNC, Pmod port Ja for the speaker and port Jb for the keypad.

---
# Difficulties

The largest issue we encountered while creating this system was during the implementation of the speaker. Since the original lab used frequencies as inputs, and had no capability of stopping a note, major modifcations were necessary. Initially we tried sending a frequency of 0 when the note was not supposed to play, but this didn't work. However, this made the intentional notes not play properly, and didn't remove the unintentional ones. It took very long before we realized that the modifications should be made to tone.vhd, and not wail.vhd. Finally, we set the data out from the tone module to be 0, whenever the not was not supposed to be played, which is what worked.

One other difficulty we had was in finding songs to add. This did not affect the actual implementation of our code, but it still worth mentioning. We used the notes from the C major scale, which means that we could only use songs that are also in this scale. Furthermore, many of these simple, traditional songs are very similar, like the Alphabet Song and Twinkle Twinkle Little Star, which have identical melodies.

---
# Contributions
Ray Ringston:
- Setup the finite state machine and the state logic process
- Created the songs module to store the catalog of songs
- Modified the 7 segment display varying size messages, and custom messages for the titles

Andrea Antropow:
- Modified the keypad module, created new mappings and connected it to the other components
- Implemented the speaker, and added functionality to play a tone only when necessary
- Performed testing to ensure all aspects performed properly



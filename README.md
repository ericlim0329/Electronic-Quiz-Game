# Electronic-Quiz-Game
Fabricated an Electronic quiz game
This project was a collaborative effort with two other UBC students

-Peter van den Doel

-Eric Lim

-Brandon Seo

A quiz game where questions are true/false or yes/no and two players compete, gaining a point for a correct answer and losing a point for a wrong answer. Capacitive buttons were used for players to input true or false

Info on uploads

QuizGame_withRNG.asm is the final version of the project with randomized question order

QuizGame_template.asm is an older version of the project with a set order of questions

cap_flag_tester.asm was used to test the ability for the project to register capacitive button presses and debug issues with noise in measurements

cap_measurment_picofarads.asm was used to measure the capacitance of the 4 sensors

Design Details

There are 7 true/false questions and the sequence of questions is determined by a random number generator and using linear probing on the list of questions. A random number between 1 and 6 is generated and used as a step length. The question sequence will be determined by stepping forward through the list of questions by the step length, skipping over questions that have already been asked, wrapping around once the question number has passed 7, and ending the game one all 7 questions have been answered. This linear probing inspired method works because 7 is a prime number so this algorithm is guaranteed to ask all questions once.

Made with an AMTEL AT89LP51IC2 microcontroller and programmed in 8051 assembly. A BO230XS serial USB Adaptor is used to interface with a laptop to upload code onto the microcontroller
An LCD 1602 module is used to display questions and points
A 22.1184MHZ crystal is used for the clock.
Four homemade capacitive sensors made with cardboard and aluminum foil are used as buttons triggered by a human hand and not pressure
Four Texas Instruments NE555P timer chips are used in the astable oscillator configuration, and the output frequency is used to determine capacitance Wires are twisted and timers are spaced apart to minimize noise Buzzer tones are used to signal wins and losses

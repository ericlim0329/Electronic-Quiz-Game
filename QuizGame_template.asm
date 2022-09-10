



$NOLIST
$MODLP51
$LIST


CLK           EQU 22118400 ;  crystal frequency (Hz)
TIMER0_RATE0  EQU ((2048*2)+100)
TIMER0_RATE1  EQU ((2048*2)-100)
TIMER0_RELOAD0 EQU ((65536-(CLK/TIMER0_RATE0)))
TIMER0_RELOAD1 EQU ((65536-(CLK/TIMER0_RATE1)))
TIMER0_HIGH_FREQUENCY EQU 2600 ;frequency to compliment square wave to generate 1300hz signal				
TIMER0_MEDIUM_FREQUENCY EQU 2000 ;to generate 1000hz signal
TIMER0_LOW_FREQUENCY EQU 1400 ;to generate 700hz signal
TIMER0_HIGH EQU (65536-(CLK/TIMER0_HIGH_FREQUENCY))
TIMER0_MEDIUM EQU (65536-(CLK/TIMER0_MEDIUM_FREQUENCY))
TIMER0_LOW EQU (65536-(CLK/TIMER0_LOW_FREQUENCY))
;65536 is the default overflow value
; so count clock cycles up to 65536 then overflow

unit_conversion_button equ P4.5
SOUND_OUT     equ P1.1
START_BUTTON equ P1.2	;CHANGE THESE
INC_BUTTON equ p1.2  	;THESE ARENT THE RIGHT BUTTONS

org 0000H
   ljmp MyProgram
   
; Timer/Counter 0 overflow interrupt vector
org 0x000B
	ljmp Timer0_ISR

; Timer/Counter 2 overflow interrupt vector
org 0x002B
	ljmp Timer2_ISR








; These register definitions needed by 'math32.inc'
DSEG at 30H
x:   ds 4
y:   ds 4
bcd: ds 5
overflow_counter: ds 2
p1_points: ds 1
p2_points: ds 1
Qnum: ds 1
q_total: ds 1
qstep: ds 1
seed_num: ds 1

BSEG
mf: dbit 1 ;comparison flag for the 32-bit library
pf_flag: dbit 1
nf_flag: dbit 1	;flags to choose which units to display
uf_flag: dbit 1
P1T: dbit 1
P1F: dbit 1
P2T: dbit 1
P2F: dbit 1
;flags indicating that questions were visited
question1_flag: dbit 1
question2_flag: dbit 1
question3_flag: dbit 1
question4_flag: dbit 1
question5_flag: dbit 1
question6_flag: dbit 1
question7_flag: dbit 1
question8_flag: dbit 1



$NOLIST

$include(math32.inc)
$LIST

cseg
; These 'equ' must match the hardware wiring
LCD_RS equ P3.2
;LCD_RW equ PX.X ; Not used in this code, connect the pin to GND
LCD_E  equ P3.3
LCD_D4 equ P3.4
LCD_D5 equ P3.5
LCD_D6 equ P3.6
LCD_D7 equ P3.7


$NOLIST
$include(LCD_4bit.inc) ; A library of LCD related functions and utility macros
$LIST

;                     1234567890123456    <- This helps determine the location of the counter
Initial_Message:  db 'Capacitance:(  )', 0
No_Signal_Str:    db 'No signal      ', 0
pf_string: db 'pf',0
nf_string: db 'nf',0
uf_string: db 'uf',0
p1_correct:  db 'P1 Correct!', 0
p2_correct:  db 'P2 Correct!', 0
p1_incorrect:  db 'P1 Incorrect!', 0
p2_incorrect:  db 'P2 Incorrect!', 0
clear_screen: db '                ', 0
point_display: db 'p1     p2       ',0
draw_string: db 'Its a draw!!!!!!!!',0
p1_winner_string: db 'Player 1 wins!!!',0
p2_winner_string: db 'Player 2 wins!!!',0

seed_prompt: db 'Seed RNG:             ', 0
GAME_START: db 'Starts in:         ', 0
GAME_GO: db 'GO!                    ', 0

clear_string: db '                ',0
question1_line1: db 'Is the sky blue?',0
question2_line1: db '9+10=21?        ',0
question3_line1: db 'Canadas national',0
question3_line2: db 'sport is hockey?',0
question4_line1: db 'Heat increases  ',0
question4_line2: db 'heart rate?     ',0
question5_line1: db 'Do neutrinos    ',0
question5_line2: db 'have mass?      ',0
question6_line1: db 'Does GABA       ',0
question6_line2: db 'excite neurons? ',0
question7_line1: db 'Can you overdose',0
question7_line2: db 'on coffee?      ',0
question8_line1: db 'Are male cows   ',0
question8_line2: db 'called Bison?   ',0
question9_line1: db '',0
question9_line2: db '',0




;---------------------------------;
; RNG subroutines                 ;
;---------------------------------;


Seed:

Set_Cursor(1,1)
Send_constant_string(#seed_prompt)
Set_Cursor(2,1) 
DISPLAY_BCD(seed_num)

;this must be initialized in the main initialization subroutine
;mov seed_num, #0
jb INC_BUTTON, DONT_INCRIMENT
Wait_Milli_Seconds(#50)
jb INC_BUTTON, DONT_INCRIMENT
INCRIMENT: jnb INC_BUTTON, INCRIMENT
inc seed_num
DONT_INCRIMENT:


jb START_BUTTON, DONT_START
Wait_Milli_Seconds(#50)
jb START_BUTTON, DONT_START
START: jnb START_BUTTON, START
ljmp Countdown
DONT_START:

;loop back awaiting input
ljmp Seed







qnum_update:
;this algorithim performs linear probing across the 7(prime number) questions and steps qnum forward by
;randomized number qstep until it lands on a question that has not been asked

mov a,qnum
add a,qstep
mov qnum,a


mov x+0,qnum
mov x+1,#0
mov x+2,#0
mov x+3,#0

mov y+0,#7
mov y+1,#0
mov y+2,#0
mov y+3,#0


clr mf
lcall x_gt_y
;mf stores bool value of (x>y)
jb mf,qnummod7
sjmp skip_qnummod7
qnummod7:
lcall sub32 ;now X stores qnum-7
skip_qnummod7:

mov qnum,x+0

;repeat this process if the qnum-7th flag is set

mov a,qnum

;if on question 1
cjne a,#1,ignore1
;if question 1 was already visited
jnb question1_flag,ignore1
;step forward again
ljmp qnum_update
ignore1:

;if on question 2
cjne a,#2,ignore2
;if question 2 was already visited
jnb question2_flag,ignore2
;step forward again
ljmp qnum_update
ignore2:


;if on question 3
cjne a,#3,ignore3
;if question 3 was already visited
jnb question3_flag,ignore3
;step forward again
ljmp qnum_update
ignore3:


;if on question 4
cjne a,#4,ignore4
;if question 1 was already visited
jnb question4_flag,ignore4
;step forward again
ljmp qnum_update
ignore4:


;if on question 5
cjne a,#5,ignore1
;if question 5 was already visited
jnb question5_flag,ignore5
;step forward again
ljmp qnum_update
ignore5:


;if on question 6
cjne a,#6,ignore6
;if question 6 was already visited
jnb question6_flag,ignore6
;step forward again
ljmp qnum_update
ignore6:



;if on question 7
cjne a,#7,ignore7
;if question 7 was already visited
jnb question7_flag,ignore7
;step forward again
ljmp qnum_update
ignore7:



;since this subroutine is being called in Qsel
ljmp Qsel


Countdown: 
;A COUNTDOWN TO BE DISPLAYED AT THE START OF THE GAME

Set_Cursor(1,1)
send_constant_string(#GAME_START)
Set_Cursor(2,1) 
DISPLAY_BCD(#3)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
DISPLAY_BCD(#2)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
DISPLAY_BCD(#1)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Set_Cursor(1,1)
send_constant_string(#GAME_GO)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
ljmp Qsel








Timer0_ISR:

	cpl SOUND_OUT 
	reti


;---------------------------------;
; time delay subroutines          ;
;---------------------------------;

;waits for the number of miliseconds in register 2
WaitR2ms:
    push AR0
    push AR1
loop3: mov R1, #45
loop2: mov R0, #166
loop1: djnz R0, loop1 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, loop2 ; 22.51519us*45=1.013ms
    djnz R2, loop3 ; number of millisecons to wait passed in R2
    pop AR1
    pop AR0
    ret

;waits for 22.5*R2 microseconds
WaitR2X22us:
    push AR0
    push AR1
L33: mov R1, #1
L22: mov R0, #166
L11: djnz R0, L11 ; 3 cycles->3*45.21123ns*166=22.51519us
    djnz R1, L22 ; 22.51519us*22.1519us
    djnz R2, L33 ; number of millisecons to wait passed in R2
    pop AR1
    pop AR0
    ret

;---------------------------------;
; buzzer subroutines              ;
;---------------------------------;

;INDIVIDUAL BUZZ SUBROUTINES WILL RUN FOR ABOUT 0.33S 

;generate a 1300hz signal for 0.33 seconds
new_high_buzz:
	
	clr TR0
	mov RH0, #high(TIMER0_HIGH) ;how many clock cycles to interrupt at
	mov RL0, #low(TIMER0_HIGH)
	setb TR0	;timer is on
	;keep the timer running for 0.33 seconds 
	Wait_Milli_Seconds(#200)
	Wait_Milli_Seconds(#133)
	clr TR0

ret
;generate 1000hz signal for 0.33s
new_medium_buzz:
	
	clr TR0
	mov RH0, #high(TIMER0_MEDIUM) ;how many clock cycles to interrupt at
	mov RL0, #low(TIMER0_MEDIUM)
	setb TR0	;timer is on
	;keep the timer running for 0.33 seconds 
	Wait_Milli_Seconds(#200)
	Wait_Milli_Seconds(#133)
	clr TR0

ret
;generate 700hz signal for 0.33s
new_low_buzz:
	
	clr TR0
	mov RH0, #high(TIMER0_LOW) ;how many clock cycles to interrupt at
	mov RL0, #low(TIMER0_LOW)
	setb TR0	;timer is on
	;keep the timer running for 0.33 seconds 
	Wait_Milli_Seconds(#200)
	Wait_Milli_Seconds(#133)
	clr TR0

ret










winning_buzz:
set_cursor(2,1)
send_constant_string(#point_display)
;display the actual score
set_cursor(2,5)
display_bcd(p1_points)

set_cursor(2,13)
display_bcd(p2_points)

;clear flags to not trigger next question
clr P1T
clr P1F
clr P2T
clr P2F

;GENERATE A LOW,MEDIUM,then HIGH buzz

;generate a low tone for 0.33s
	clr TR0
	mov RH0, #high(TIMER0_LOW) ;how many clock cycles to interrupt at
	mov RL0, #low(TIMER0_LOW)
	setb TR0	;timer is on
	;keep the timer running for 0.33 seconds 
	Wait_Milli_Seconds(#200)
	Wait_Milli_Seconds(#133)
	clr TR0


;generate a medium tone for 0.33s
	clr TR0
	mov RH0, #high(TIMER0_MEDIUM) ;how many clock cycles to interrupt at
	mov RL0, #low(TIMER0_MEDIUM)
	setb TR0	;timer is on
	;keep the timer running for 0.33 seconds 
	Wait_Milli_Seconds(#200)
	Wait_Milli_Seconds(#133)
	clr TR0
	
;generate a high tone for 0.33s
	clr TR0
	mov RH0, #high(TIMER0_HIGH) ;how many clock cycles to interrupt at
	mov RL0, #low(TIMER0_HIGH)
	setb TR0	;timer is on
	;keep the timer running for 0.33 seconds 
	Wait_Milli_Seconds(#200)
	Wait_Milli_Seconds(#133)
	clr TR0


;ljmp new_low_buzz
;ljmp new_medium_buzz
;ljmp new_high_buzz

;wait for 3 more seconds so 15*200ms
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)

ljmp Qsel

losing_buzz:
set_cursor(2,1)
send_constant_string(#point_display)
;display the actual score
set_cursor(2,5)
display_bcd(p1_points)

set_cursor(2,13)

display_bcd(p2_points)


;clear flags to not trigger next question
clr P1T
clr P1F
clr P2T
clr P2F

;GENERATE A HIGH,MEDIUM,then LOW buzz, this should take 1s






	
;generate a high tone for 0.33s
	clr TR0
	mov RH0, #high(TIMER0_HIGH) ;how many clock cycles to interrupt at
	mov RL0, #low(TIMER0_HIGH)
	setb TR0	;timer is on
	;keep the timer running for 0.33 seconds 
	Wait_Milli_Seconds(#200)
	Wait_Milli_Seconds(#133)
	clr TR0

;generate a medium tone for 0.33s
	clr TR0
	mov RH0, #high(TIMER0_MEDIUM) ;how many clock cycles to interrupt at
	mov RL0, #low(TIMER0_MEDIUM)
	setb TR0	;timer is on
	;keep the timer running for 0.33 seconds 
	Wait_Milli_Seconds(#200)
	Wait_Milli_Seconds(#133)
	clr TR0


;generate a low tone for 0.33s
	clr TR0
	mov RH0, #high(TIMER0_LOW) ;how many clock cycles to interrupt at
	mov RL0, #low(TIMER0_LOW)
	setb TR0	;timer is on
	;keep the timer running for 0.33 seconds 
	Wait_Milli_Seconds(#200)
	Wait_Milli_Seconds(#133)
	clr TR0
;ljmp new_high_buzz
;ljmp new_medium_buzz
;ljmp new_low_buzz



;wait for 3 more seconds so 15*200ms
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)
Wait_Milli_Seconds(#200)





ljmp Qsel




Timer2_ISR:
;lcall button_registering

clr TF2 ;no more overflow after we have gone into the ISR
push acc
inc overflow_counter+0 ; count one overflow
mov a, overflow_counter+0 
jnz coal_miner
;if the code got hrere then oeverflow_counter+0 was 0 meaning that overflow_counter+1 must be incrimented
inc overflow_counter+1
coal_miner:;to skip over incrimenting bit 1 of overflow counter
pop acc
reti


; Sends 10-digit BCD number in bcd to the LCD
Display_10_digit_BCD:
	Display_BCD(bcd+4)
	Display_BCD(bcd+3)
	Display_BCD(bcd+2)
	Display_BCD(bcd+1)
	Display_BCD(bcd+0)
	ret

;Initializes timer/counter 2 as a 16-bit timer
InitTimer2:
	mov T2CON, #0 ; Stop timer/counter.  Set as timer (clock input is pin 22.1184MHz).
	; Set the reload value on overflow to zero (just in case is not zero)
	mov RCAP2H, #0
	mov RCAP2L, #0
	setb ET2
    ret


button_registering:
	;look for button press to change units
	jb unit_conversion_button,dont_change_units_boogaloo
	;debounce delay
	Wait_Milli_Seconds(#50)
	jb unit_conversion_button,dont_change_units_boogaloo
	;wait for button release
	benadryl: jnb unit_conversion_button, benadryl
	;WHAT YOU WANT TO DO WHEN BUTTON IS PRESSED
	dont_change_units_boogaloo:
ret



;---------------------------------;
; question subs                   ;
;---------------------------------;


question_1:
set_cursor(1,1) 
Send_Constant_String(#question1_line1)
set_cursor(2,1)
send_constant_string(#clear_string)

;check flags to determine right answer
;player 1 gets a point if they say sky blue
jb P1T,p1_q1_point
sjmp avoid_p1_q1_point
p1_q1_point:
setb question1_flag
ljmp p1_right
avoid_p1_q1_point:
;player 2 gets a point if they say sky blue
jb P2T,p2_q1_point
sjmp avoid_p2_q1_point
p2_q1_point:
setb question1_flag
ljmp p2_right
avoid_p2_q1_point:



;player 1 loses a point if they say sky not blue
jb P1f,p1_q1_lose
sjmp avoid_p1_q1_lose
p1_q1_lose:
setb question1_flag
ljmp p1_wrong
avoid_p1_q1_lose:
;player 2 lose a point if they say sky not blue
jb P2F,p2_q1_lose
sjmp avoid_p2_q1_lose
p2_q1_lose:
setb question1_flag
ljmp p2_wrong
avoid_p2_q1_lose:

ljmp measure_caps ;look for any button presses
;keep looping awaiting answer
ljmp question_1
ret


question_2:
set_cursor(1,1) 
Send_Constant_String(#question2_line1)
set_cursor(2,1)
send_constant_string(#clear_string)

;check flags to determine right answer
;player 1 lose a point if they say 9+10=21
jb p1t,p1_q2_lose
sjmp avoid_p1_q2_lose
p1_q2_lose:
setb question2_flag
ljmp p1_wrong
avoid_p1_q2_lose:
;player 2 lose a point if they say 9+10=21
jb p2t,p2_q2_lose
sjmp avoid_p2_q2_lose
p2_q2_lose:
setb question2_flag
ljmp p2_wrong
avoid_p2_q2_lose:



;player 1 gain a point if they say 9+10!=21
jb p1f,p1_q2_win
sjmp avoid_p1_q2_win
p1_q2_win:
setb question2_flag
ljmp p1_right
avoid_p1_q2_win:
;player 2 gain a point if they say 9+10!=21
jb p2f,p2_q2_win
sjmp avoid_p2_q2_win
p2_q2_win:
setb question2_flag
ljmp p2_right
avoid_p2_q2_win:

ljmp measure_caps ;look for any button presses
;keep looping awaiting answer
ljmp question_2
ret



question_3: 
set_cursor(1,1) 
Send_Constant_String(#question3_line1)
set_cursor(2,1)
Send_constant_string(#question3_line2)

;check flags to determine right answer

;canadas national sport is not hockey so players will gain a point for saying F and lose a point for saying T

jb p1t,p1_q3_lose
sjmp avoid_p1_q3_lose
p1_q3_lose:
setb question3_flag
ljmp p1_wrong
avoid_p1_q3_lose:

jb p2t,p2_q3_lose
sjmp avoid_p2_q3_lose
p2_q3_lose:
setb question3_flag
ljmp p2_wrong
avoid_p2_q3_lose:




jb p1f,p1_q3_win
sjmp avoid_p1_q3_win
p1_q3_win:
setb question3_flag
ljmp p1_right
avoid_p1_q3_win:

jb p2f,p2_q3_win
sjmp avoid_p2_q3_win
p2_q3_win:
setb question3_flag
ljmp p2_right
avoid_p2_q3_win:

ljmp measure_caps ;look for any button presses
;keep looping awaiting answer
ljmp question_3
ret


question_4:
set_cursor(1,1) 
Send_Constant_String(#question4_line1)
set_cursor(2,1)
send_constant_string(#question4_line2)

;check flags to determine right answer

;player 1 gets a point if they say heat increases heart rate
jb p1t,p1_q4_point
sjmp avoid_p1_q4_point
p1_q4_point:
setb question4_flag
ljmp p1_right
avoid_p1_q4_point:
;player 2 gets a point if they say heat raises BPM
jb p2t,p2_q4_point
sjmp avoid_p2_q4_point
p2_q4_point:
setb question4_flag
ljmp p2_right
avoid_p2_q4_point:



;player 1 loses a point if they heat no raise BPM
jb p1f,p1_q4_lose
sjmp avoid_p1_q4_lose
p1_q4_lose:
setb question4_flag
ljmp p1_wrong
avoid_p1_q4_lose:
;player 2 lose a point if they say heat no raise BPM
jb p2f,p2_q4_lose
sjmp avoid_p2_q4_lose
p2_q4_lose:
setb question4_flag
ljmp p2_wrong
avoid_p2_q4_lose:

ljmp measure_caps ;look for any button presses
;keep looping awaiting answer
ljmp question_4
ret



question_5:
set_cursor(1,1) 
Send_Constant_String(#question5_line1)
set_cursor(2,1)
send_constant_string(#question5_line2)

;check flags to determine right answer
;player 1 gets a point if they say neutrino have mass
jb p1t,p1_q5_point
sjmp avoid_p1_q5_point
p1_q5_point:
setb question5_flag
ljmp p1_right
avoid_p1_q5_point:
;player 2 gets a point if they say neutrino have mass
jb p2t,p2_q5_point
sjmp avoid_p2_q5_point
p2_q5_point:
setb question5_flag
ljmp p2_right
avoid_p2_q5_point:



;player 1 loses a point if they say neutrino massless
jb p1f,p1_q5_lose
sjmp avoid_p1_q5_lose
p1_q5_lose:
setb question5_flag
ljmp p1_wrong
avoid_p1_q5_lose:
;player 2 lose a point if they say neutrino massless
jb p2f,p2_q5_lose
sjmp avoid_p2_q5_lose
p2_q5_lose:
setb question5_flag
ljmp p2_wrong
avoid_p2_q5_lose:

ljmp measure_caps ;look for any button presses
;keep looping awaiting answer
ljmp question_5
ret



question_6: 
set_cursor(1,1) 
Send_Constant_String(#question6_line1)
set_cursor(2,1)
Send_constant_string(#question6_line2)

;check flags to determine right answer

;GABA inhibits neurons so players lose points for answering true

jb p1t,p1_q6_lose
sjmp avoid_p1_q6_lose
p1_q6_lose:
setb question6_flag
ljmp p1_wrong
avoid_p1_q6_lose:

jb p2t,p2_q6_lose
sjmp avoid_p2_q6_lose
p2_q6_lose:
setb question6_flag
ljmp p2_wrong
avoid_p2_q6_lose:




jb p1f,p1_q6_win
sjmp avoid_p1_q6_win
p1_q6_win:
setb question6_flag
ljmp p1_right
avoid_p1_q6_win:

jb p2f,p2_q6_win
sjmp avoid_p2_q6_win
p2_q6_win:
setb question6_flag
ljmp p2_right
avoid_p2_q6_win:

ljmp measure_caps ;look for any button presses
;keep looping awaiting answer
ljmp question_6
ret



question_7:
set_cursor(1,1) 
Send_Constant_String(#question7_line1)
set_cursor(2,1)
send_constant_string(#question7_line2)

;check flags to determine right answer

;player gets a point if they say you can OD on coffee
jb p1t,p1_q7_point
sjmp avoid_p1_q7_point
p1_q7_point:
setb question7_flag
ljmp p1_right
avoid_p1_q7_point:

jb p2t,p2_q7_point
sjmp avoid_p2_q7_point
p2_q7_point:
setb question7_flag
ljmp p2_right
avoid_p2_q7_point:



jb p1f,p1_q7_lose
sjmp avoid_p1_q7_lose
p1_q7_lose:
setb question7_flag
ljmp p1_wrong
avoid_p1_q7_lose:

jb p2f,p2_q7_lose
sjmp avoid_p2_q7_lose
p2_q7_lose:
setb question7_flag
ljmp p2_wrong
avoid_p2_q7_lose:

ljmp measure_caps ;look for any button presses
;keep looping awaiting answer
ljmp question_7
ret



question_8: 
set_cursor(1,1) 
Send_Constant_String(#question8_line1)
set_cursor(2,1)
Send_constant_string(#question8_line2)

;check flags to determine right answer

;GABA inhibits neurons so players lose points for answering true

jb p1t,p1_q8_lose
sjmp avoid_p1_q8_lose
p1_q8_lose:
setb question8_flag
ljmp p1_wrong
avoid_p1_q8_lose:

jb p2t,p2_q8_lose
sjmp avoid_p2_q8_lose
p2_q8_lose:
setb question8_flag
ljmp p2_wrong
avoid_p2_q8_lose:




jb p1f,p1_q8_win
sjmp avoid_p1_q8_win
p1_q8_win:
setb question8_flag
ljmp p1_right
avoid_p1_q8_win:

jb p2f,p2_q8_win
sjmp avoid_p2_q8_win
p2_q8_win:
setb question8_flag
ljmp p2_right
avoid_p2_q8_win:

ljmp measure_caps ;look for any button presses
;keep looping awaiting answer
ljmp question_8
ret


winner:
set_cursor(2,1)
send_constant_string(#clear_screen)
;compare each players points to see who won
;p1_points
;p2_points

;first say it was a draw if point numbers are equal
mov a,p1_points
cjne a,p2_points,dont_display_draw

;display a draw message here
set_cursor(1,1)
send_constant_string(#draw_string)
ljmp winner ;to loop and continue displaying the draw
dont_display_draw:

;p1_points is in acc
;subb a,p2_points
;acc contains p1_points-p2_points

;values can be compared using the 32bit library
mov x+0,p1_points
mov x+1,#0
mov x+2,#0
mov x+3,#0
mov y+0,p2_points
mov y+1,#0
mov y+2,#0
mov y+3,#0
;make sure no false positives for mf flag
clr mf
lcall x_gt_y ;mf=1 if p1_points>p2_points, else mf=0

jb mf,p1_wins
sjmp avoid_p1_wins
p1_wins:
set_cursor(1,1)
send_constant_string(#p1_winner_string)
avoid_p1_wins:

jnb mf,p2_wins
sjmp avoid_p2_wins
p2_wins:
set_cursor(1,1)
send_constant_string(#p2_winner_string)
avoid_p2_wins:




;loop
ljmp winner



;---------------------------------;
; question selection subroutine   ;
;---------------------------------;

Qsel:
	
	;if all the question flags are on, jump to the winner subroutine
	jnb question1_flag,no_winner
	jnb question2_flag,no_winner
	jnb question3_flag,no_winner
	jnb question4_flag,no_winner
	jnb question5_flag,no_winner
	jnb question6_flag,no_winner
	jnb question7_flag,no_winner
	ljmp winner
	no_winner:
	
	;if at least one question flag is off, update qnum
	;MAKE SURE THAT THIS REPLACES INCRIMENTING QNUM IN THE P1/2 RIGHT/WRONG SUBROUTINES
	;ljmp qnum_update
	
	
	
	mov q_total, #7 ;total number of questions
	mov a,qnum
	cjne a, #1, avoid1
	;this code with the flag is unneeded 
	;jb question1_flag,avoid1
	ljmp question_1
	avoid1:

	cjne a, #2, avoid2
	;jb question2_flag,avoid2
	ljmp question_2
	avoid2:
		
	cjne a, #3, avoid3
	;jb question3_flag,avoid3
	ljmp question_3
	avoid3:

	cjne a, #4, avoid4
	;jb question4_flag,avoid4
	ljmp question_4
	avoid4:

	cjne a, #5, avoid5
	;jb question5_flag,avoid5
	ljmp question_5
	avoid5:

	cjne a, #6, avoid6
	;jb question6_flag,avoid6	
	ljmp question_6
	avoid6:
	
	cjne a, #7,avoid7
	;jb question7_flag,avoid7	
	ljmp question_7
	avoid7:
	
	;8th question is not asked because qnum_update uses linear probing which
	;only works with a prime number of questions
	;cjne a, #8,avoid8
	;jb question8_flag,avoid2	
	;ljmp question_8
	;avoid8:
	
	
	
	;make sure to modify this for the number of questions
	;cjne a, #8,avoidwin
	;ljmp winner
	;avoidwin:

ret












;---------------------------------;
; Hardware initialization         ;
;---------------------------------;
Initialize_All:
    lcall InitTimer2
    lcall LCD_4BIT ; Initialize LCD
	setb EA
	ret








;---------------------------------;
; point adjustment subs           ;
;---------------------------------;


p1_right:

mov a,p1_points
add a,#1
mov p1_points,a


;IF RNG WORKS THEN INCRIMENTING QNUM IS NOT NEEDED
mov a,Qnum
add a,#1
mov Qnum,a

Set_Cursor(1, 1)
Send_Constant_String(#clear_screen)
Set_Cursor(1, 1)
Send_Constant_String(#p1_correct)
ljmp winning_buzz
;this goes in buzzer subroutine
;ljmp Qsel

p1_wrong:

;FIRST CHECK IF 0
mov a,p1_points
cjne a,#0,reduce_p1_points
sjmp skip_this_boy
;reduce points if not already 0
reduce_p1_points:
mov a,p1_points
subb a,#1
mov p1_points,a
skip_this_boy:

;SUBB p1_points, #1
;ADD Qnum, #1
mov a,Qnum
add a,#1
mov Qnum,a

Set_Cursor(1, 1)
Send_Constant_String(#clear_screen)
Set_Cursor(1, 1)
Send_Constant_String(#p1_incorrect)
ljmp losing_buzz
;ljmp Qsel

p2_right:
;ADD p2_points, #1
mov a,p2_points
add a,#1
mov p2_points,a

;ADD Qnum, #1
mov a,Qnum
add a,#1
mov Qnum,a

Set_Cursor(1, 1)
Send_Constant_String(#clear_screen)
Set_Cursor(1, 1)	
Send_Constant_String(#p2_correct)
ljmp winning_buzz
;goes in buzzer sub
;ljmp Qsel

p2_wrong:
;SUBB p2_points, #1
;FIRST CHECK IF 0
mov a,p2_points
cjne a,#0,carpool2boogaloo
sjmp skip_this_boiii
;reduce points of not already 0
carpool2boogaloo:
mov a,p2_points
subb a,#1
mov p2_points,a
skip_this_boiii:



;ADD Qnum, #1
mov a,Qnum
add a,#1
mov Qnum,a


Set_Cursor(1, 1)
Send_Constant_String(#clear_screen)
Set_Cursor(1, 1)
Send_Constant_String(#p2_incorrect)
ljmp losing_buzz
;goes in buzzer sub
;ljmp Qsel












;---------------------------------;
; capactience program loop        ;
;---------------------------------;
MyProgram:
    ; Initialize the hardware:
    mov SP, #7FH
    lcall Initialize_All
    setb P0.0 ; Pin is used as input
    setb P0.1 ;to measure a second capacitence 
    setb P0.2
    setb P0.3
	setb unit_conversion_button
	setb SOUND_OUT
	clr SOUND_OUT

    clr pf_flag  ;start off displaying picofarads
    setb nf_flag
    clr uf_flag
    clr P1T 
    clr P2T
    clr P1F
    clr P2F
    ;start off saying no questions have been visited
    clr question1_flag
    clr question2_flag
    clr question3_flag
    clr question4_flag
    clr question5_flag
    clr question6_flag
    clr question7_flag
    clr question8_flag
    
    
    MOV P1_points,#0 ;both players start off with 0 points
    MOV P2_points,#0
    MOV Qnum,#1 ;start with question number 1
    
    mov seed_num, #0 ;initializing RNG seed
    
    ;initialize timer 0 for the buzzer
    mov a, TMOD
	anl a, #0xf0 ; 11110000 Clear the bits for timer 0
	orl a, #0x01 ; 00000001 Configure timer 0 as 16-timer
	mov TMOD, a
	mov TH0, #high(TIMER0_RELOAD1)
	mov TL0, #low(TIMER0_RELOAD1)
	; Set autoreload value
	mov RH0, #high(TIMER0_RELOAD1) ;putting values into these sets the frequency
	mov RL0, #low(TIMER0_RELOAD1) ;some default values to start with
	; Enable the timer and interrupts
    setb ET0  ; Enable timer 0 interrupt
    setb TR0  
    clr TR0 ;timer 0 starts off as off
    
    ;ljmp measure_caps
    ;ljmp new_high_buzz
    ljmp Qsel
    
    
measure_caps:


;PIN 0 REPRESENTS PLAYER 1 TRUE

;measuring from P0.0


    ; synchronize with rising edge of the signal applied to pin F
   
    clr TR2 ; Stop timer 2
    mov TL2, #0
    mov TH2, #0
    mov overflow_counter+0,#0
    mov overflow_counter+1,#0 ;initialize the overflow counter as having detected 0 overflows since the timer is being reset
    clr TF2
    ;mov R0,#2 ;taking 100 samples
    setb TR2
    period_loop:
    jb P0.0, $
    jnb P0.0, $
    ;djnz R0, period_loop
    clr TR2 ; Stop counter 2, TH2-TL2 has the period
    
    
synch1:
	;jb TF2, no_signal ; If the timer overflows, we assume there is no signal
    mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal ; If the count is larger than 0x01ffffffff*45ns=1.16s, we assume there is no signal THIS RUINS 1000uf measruements so get rid of it 
    jb P0.0, synch1
synch2:   
	 
	;jb TF2, no_signal
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal
    jnb P0.0, synch2
    
    ; Measure the period of the signal applied to pin P0.0
    clr TR2
    mov TL2, #0
    mov TH2, #0
    mov overflow_counter+0,#0
    mov overflow_counter+1,#0 ;initialize the overflow counter as having detected 0 overflows
    clr TF2
    setb TR2 ; Start timer 2
    
    
measure1:
	;jb TF2, no_signal
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal 
    jb P0.0, measure1
measure2:    
	
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal
	;jb TF2, no_signal ;can't have it jumping to a branch instead of the ISR when overflows are detected
    jnb P0.0, measure2
    clr TR2 ; Stop timer 2,	the higher bits to detect overflow must be incorporated
    ;as in the example  [overflow_counter+1,overflow_counter+0,TH2,TL2] * 45.21123ns is the period


	;the no signal subroutine is placed here in order to make sure the jb instructions are close enough
	sjmp avoid_no_signal
	no_signal:	
	Set_Cursor(2, 1)
    Send_Constant_String(#No_Signal_Str)
    ljmp synch12 ; If there is no signal in P0.0, start measuring from P0.1
	
	avoid_no_signal:


	; Make sure [overflow_counter+1,overflow_counter+0,TH2,TL2]!=0
	mov a, TL2
	orl a, TH2
	;or with the overflow bits too
	orl a,overflow_counter+0
	orl a,overflow_counter+1
	jz no_signal


	; Using integer math, convert the period to frequency:
	mov x+0, TL2
	mov x+1, TH2
	mov x+2, overflow_counter+0
	mov x+3, overflow_counter+1	

	;dividing number of cycles by 1000 to not cause overflow when multiplying by clock period 
	
	;TO BE CLEAR C WILL BE AROUND 0.3NF SO DIVIDING BY 1000 WILL PROBABLY RUIN THE DATA FOR THE PROJECT
	
	Load_y(1000)
	;lcall div32

	Load_y(45211) ; One clock pulse is 45211.23/1000ns, the 1/1000 is taken care of by the last two instructions
	;just use 45ns for less accuracy and less hassle
	;Load_y(45)
	lcall mul32
	;now x stores #_of_pulses*clock_period(ns) to get period or nanoseconds transpired 


	;CODE TO CONVERT PERIOD MEASURMENT INTO CAPACITENCE
	
	
	;C=period/(ln(2)*(Ra+2*Rb))
	;Ra=980ohm Rb=1953, (ln(2)*(Ra+2*Rb))=2036
	Load_y(2036)
	lcall div32 ;now x has capacitence in nf 
	;FROM P0.0 MEASURMENTS 
	
	
	;Seeing if player 1 hit the true button and modifying flag accordingly
	
	;testing if flag corresponds to output correctly
	
	
	
	clr mf ;button not pressed by default
	Load_y(9000) ;if C>9000pf then the button was pressed
	;for testing with capacitors 
	;Load_y(200000)
	lcall x_gt_y
	;mf=(C>50nf)
	jb mf, player_1_true
	sjmp avoid_p1t
	player_1_true:
	setb P1T
	avoid_p1t:
	
	;clearing P1T if button not pressed
	jnb mf, player_1_not_true
	sjmp avoid_not_p1t
	player_1_not_true:
	clr P1T
	avoid_not_p1t:
	
	
	
	; Convert the result to BCD and display on LCD
	;Set_Cursor(1, 1)
	;lcall hex2bcd
	;lcall Display_10_digit_BCD








;Pin 1 represents Player 1 false

;Cap from P0.1


synch12:
	;jb TF2, no_signal ; If the timer overflows, we assume there is no signal
    mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal ; If the count is larger than 0x01ffffffff*45ns=1.16s, we assume there is no signal THIS RUINS 1000uf measruements so get rid of it 
    jb P0.1, synch12
synch22:   
	 
	;jb TF2, no_signal
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal
    jnb P0.1, synch22
    
    ; Measure the period of the signal applied to pin P0.1
    clr TR2
    mov TL2, #0
    mov TH2, #0
    mov overflow_counter+0,#0
    mov overflow_counter+1,#0 ;initialize the overflow counter as having detected 0 overflows
    clr TF2
    setb TR2 ; Start timer 2
    
    
measure12:
	;jb TF2, no_signal
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal 
    jb P0.1, measure12
measure22:    
	
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal
	;jb TF2, no_signal ;can't have it jumping to a branch instead of the ISR when overflows are detected
    jnb P0.1, measure22
    clr TR2 ; Stop timer 2,	the higher bits to detect overflow must be incorporated
    ;as in the example  [overflow_counter+1,overflow_counter+0,TH2,TL2] * 45.21123ns is the period


	;the no signal subroutine is placed here in order to make sure the jb instructions are close enough
	sjmp avoid_no_signal2
	no_signal2:	
	Set_Cursor(1, 1)
    Send_Constant_String(#No_Signal_Str)
    ljmp synch13 ; If there is no signal from P0.1, measure from P0.2
	
	avoid_no_signal2:


	; Make sure [overflow_counter+1,overflow_counter+0,TH2,TL2]!=0
	mov a, TL2
	orl a, TH2
	;or with the overflow bits too
	orl a,overflow_counter+0
	orl a,overflow_counter+1
	jz no_signal2


	; Using integer math, convert the period to frequency:
	mov x+0, TL2
	mov x+1, TH2
	mov x+2, overflow_counter+0
	mov x+3, overflow_counter+1	

	;dividing number of cycles by 1000 to not cause overflow when multiplying by clock period 
	Load_y(1000)
	;lcall div32

	Load_y(45211) ; One clock pulse is 45211.23/1000ns, the 1/1000 is taken care of by the last two instructions
	;just use 45ns for less accuracy and less hassle
	;Load_y(45)
	lcall mul32
	;now x stores #_of_pulses*clock_period(ns) to get period or nanoseconds transpired 




	;CODE TO CONVERT PERIOD MEASURMENT INTO CAPACITENCE
	
	
	;C=period/(ln(2)*(Ra+2*Rb))
	;Ra=980ohm Rb=1953, (ln(2)*(Ra+2*Rb))=2036
	Load_y(2036)
	lcall div32 ;now x has capacitence in nf 
	;FROM P0.1 MEASURMENTS 
	
	
	
	
	;Seeing if player 1 hit the false button
	
	clr mf ;button not pressed by default
	Load_y(10000) ;if C>10000pf then the button was pressed
	;Load_y(200000)
	lcall x_gt_y
	;mf=(C>50nf)
	jb mf, player_1_false
	sjmp avoid_p1f
	player_1_false:
	setb P1F
	avoid_p1f:

	
	;clearing P1F if button not pressed
	jnb mf, player_1_not_false
	sjmp avoid_not_p1f
	player_1_not_false:
	clr P1F
	avoid_not_p1f:
	
	
	; Convert the result to BCD and display on LCD
	;Set_Cursor(1, 2)
	;lcall hex2bcd
	;lcall Display_10_digit_BCD












	
	
	
	
;Pin 2 represents player 2 true
	
;MEASURING CAP FROM P0.2
	
	
	
synch13:
	;jb TF2, no_signal ; If the timer overflows, we assume there is no signal
    mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal ; If the count is larger than 0x01ffffffff*45ns=1.16s, we assume there is no signal THIS RUINS 1000uf measruements so get rid of it 
    jb P0.2, synch13
synch23:   
	 
	;jb TF2, no_signal
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal
    jnb P0.2, synch23
    
    ; Measure the period of the signal applied to pin P0.2
    clr TR2
    mov TL2, #0
    mov TH2, #0
    mov overflow_counter+0,#0
    mov overflow_counter+1,#0 ;initialize the overflow counter as having detected 0 overflows
    clr TF2
    setb TR2 ; Start timer 2
    
    
measure13:
	;jb TF2, no_signal
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal 
    jb P0.2, measure13
measure23:    
	
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal
	;jb TF2, no_signal ;can't have it jumping to a branch instead of the ISR when overflows are detected
    jnb P0.2, measure23
    clr TR2 ; Stop timer 2,	the higher bits to detect overflow must be incorporated
    ;as in the example  [overflow_counter+1,overflow_counter+0,TH2,TL2] * 45.21123ns is the period


	;the no signal subroutine is placed here in order to make sure the jb instructions are close enough
	sjmp avoid_no_signal3
	no_signal3:	
	Set_Cursor(1, 1)
    Send_Constant_String(#No_Signal_Str)
    ljmp synch14 ; If there is no signal from P0.2, measure from P0.3
	
	avoid_no_signal3:


	; Make sure [overflow_counter+1,overflow_counter+0,TH2,TL2]!=0
	mov a, TL2
	orl a, TH2
	;or with the overflow bits too
	orl a,overflow_counter+0
	orl a,overflow_counter+1
	jz no_signal3


	; Using integer math, convert the period to frequency:
	mov x+0, TL2
	mov x+1, TH2
	mov x+2, overflow_counter+0
	mov x+3, overflow_counter+1	

	;dividing number of cycles by 1000 to not cause overflow when multiplying by clock period 
	Load_y(1000)
	;lcall div32

	Load_y(45211) ; One clock pulse is 45211.23/1000ns, the 1/1000 is taken care of by the last two instructions
	;just use 45ns for less accuracy and less hassle
	;Load_y(45)
	lcall mul32
	;now x stores #_of_pulses*clock_period(ns) to get period or nanoseconds transpired 




	;CODE TO CONVERT PERIOD MEASURMENT INTO CAPACITENCE
	
	
	;C=period/(ln(2)*(Ra+2*Rb))
	;Ra=980ohm Rb=1953, (ln(2)*(Ra+2*Rb))=2036
	Load_y(2036)
	lcall div32 ;now x has capacitence in nf 
	
	
	;FROM P0.2 MEASURMENTS 
	

	;Seeing if player 2 hit the true button
	
	clr mf ;button not pressed by default
	Load_y(11000) ;if C>8000pf then the button was pressed
	;Load_y(200000)
	lcall x_gt_y
	;mf=(C>50nf)
	jb mf, player_2_true
	sjmp avoid_p2t
	player_2_true:
	setb P2T
	avoid_p2t:
	
	;clearing P2T if button not pressed
	jnb mf, player_2_not_true
	sjmp avoid_not_p2t
	player_2_not_true:
	clr P2T
	avoid_not_p2t:
	
	
	; Convert the result to BCD and display on LCD
	;Set_Cursor(2, 1)
	;lcall hex2bcd
	;lcall Display_10_digit_BCD


	
	
	
	
	
	
	
	
	
	
	
	
	
;Pin 3 represents player 2 false
	
	;P0.3 cap	
synch14:
	;jb TF2, no_signal ; If the timer overflows, we assume there is no signal
    mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal ; If the count is larger than 0x01ffffffff*45ns=1.16s, we assume there is no signal THIS RUINS 1000uf measruements so get rid of it 
    jb P0.3, synch14
synch24:   
	 
	;jb TF2, no_signal
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal
    jnb P0.3, synch24
    
    ; Measure the period of the signal applied to pin P0.3
    clr TR2
    mov TL2, #0
    mov TH2, #0
    mov overflow_counter+0,#0
    mov overflow_counter+1,#0 ;initialize the overflow counter as having detected 0 overflows
    clr TF2
    setb TR2 ; Start timer 2
    
    
measure14:
	;jb TF2, no_signal
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal 
    jb P0.3, measure14
measure24:    
	
	mov a, overflow_counter+1
	anl a, #0xfe
	;jnz no_signal
	;jb TF2, no_signal ;can't have it jumping to a branch instead of the ISR when overflows are detected
    jnb P0.3, measure24
    clr TR2 ; Stop timer 2,	the higher bits to detect overflow must be incorporated
    ;as in the example  [overflow_counter+1,overflow_counter+0,TH2,TL2] * 45.21123ns is the period


	;the no signal subroutine is placed here in order to make sure the jb instructions are close enough
	sjmp avoid_no_signal4
	no_signal4:	
	Set_Cursor(1, 1)
    Send_Constant_String(#No_Signal_Str)
    ljmp measure_caps ; If there is no signal from P0.3, measure from P0.0
	
	avoid_no_signal4:


	; Make sure [overflow_counter+1,overflow_counter+0,TH2,TL2]!=0
	mov a, TL2
	orl a, TH2
	;or with the overflow bits too
	orl a,overflow_counter+0
	orl a,overflow_counter+1
	jz no_signal4


	; Using integer math, convert the period to frequency:
	mov x+0, TL2
	mov x+1, TH2
	mov x+2, overflow_counter+0
	mov x+3, overflow_counter+1	

	;dividing number of cycles by 1000 to not cause overflow when multiplying by clock period 
	Load_y(1000)
	;lcall div32

	Load_y(45211) ; One clock pulse is 45211.23/1000ns, the 1/1000 is taken care of by the last two instructions
	;just use 45ns for less accuracy and less hassle
	;Load_y(45)
	lcall mul32
	;now x stores #_of_pulses*clock_period(ns) to get period or nanoseconds transpired 




	;CODE TO CONVERT PERIOD MEASURMENT INTO CAPACITENCE
	
	
	;C=period/(ln(2)*(Ra+2*Rb))
	;Ra=980ohm Rb=1953, (ln(2)*(Ra+2*Rb))=2036
	Load_y(2036)
	lcall div32 ;now x has capacitence in nf 
	;FROM P0.3 MEASURMENTS 
	


	;Seeing if player 2 hit the false button
	
	clr mf ;button not pressed by default
	Load_y(9000) ;if C>9000pf then the button was pressed
	;Load_y(200000)
	lcall x_gt_y
	;mf=(C>50nf)
	jb mf, player_2_false
	sjmp avoid_p2f
	player_2_false:
	setb P2F
	avoid_p2f:
	
	;clearing P2F if button not pressed
	jnb mf, player_2_not_false
	sjmp avoid_not_p2f
	player_2_not_false:
	clr P2F
	avoid_not_p2f:
	
	
	
	; Convert the result to BCD and display on LCD
	Set_Cursor(2, 2)
	;lcall hex2bcd
	;lcall Display_10_digit_BCD
	
	
		



	
	
	

	;ljmp measure_caps
	ljmp Qsel

end

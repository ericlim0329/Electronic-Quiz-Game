;\\\\\\\\\\\
;NOTE
;this code was modelled on Period_RC2_math_over.asm from piazza note 316
;\\\\\\\\\\\



$NOLIST
$MODLP51
$LIST

unit_conversion_button equ P4.5



org 0000H
   ljmp MyProgram


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

BSEG
mf: dbit 1 ;comparison flag for the 32-bit library
pf_flag: dbit 1
nf_flag: dbit 1	;flags to choose which units to display
uf_flag: dbit 1
p1t: dbit 1
p1f: dbit 1
p2t: dbit 1
p2f: dbit 1

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

clear_string: db '                ',0
question1_line1: db 'Is the sky blue?',0
question2_line1: db '9+10=21?        ',0
question3_line1: db 'Canadas national',0
question3_line2: db 'sport is hockey?',0






;this isr code was modelled off of piazza note 316

Timer2_ISR:
lcall button_registering

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
	;ljmp unit_change
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
ljmp measure_caps ;look for any button presses
;check flags to determine right answer
;player 1 gets a point if they say sky blue
jb p1t,p1_q1_point
sjmp avoid_p1_q1_point
p1_q1_point:
ljmp p1_right
avoid_p1_q1_point:
;player 2 gets a point if they say sky blue
jb p2t,p2_q1_point
sjmp avoid_p2_q1_point
p2_q1_point:
ljmp p2_right
avoid_p2_q1_point:



;player 1 loses a point if they say sky not blue
jb p1f,p1_q1_lose
sjmp avoid_p1_q1_lose
p1_q1_lose:
ljmp p1_wrong
avoid_p1_q1_lose:
;player 2 lose a point if they say sky not blue
jb p2f,p2_q1_lose
sjmp avoid_p2_q1_lose
p2_q1_lose:
ljmp p2_wrong
avoid_p2_q1_lose:


;keep looping awaiting answer
ljmp question_1
ret


question_2:
set_cursor(1,1) 
Send_Constant_String(#question2_line1)
set_cursor(2,1)
send_constant_string(#clear_string)
ljmp measure_caps ;look for any button presses
;check flags to determine right answer
;player 1 lose a point if they say 9+10=21
jb p1t,p1_q2_lose
sjmp avoid_p1_q2_lose
p1_q2_lose:
ljmp p1_wrong
avoid_p1_q2_lose:
;player 2 lose a point if they say 9+10=21
jb p2t,p2_q2_lose
sjmp avoid_p2_q2_lose
p2_q2_lose:
ljmp p2_wrong
avoid_p2_q2_lose:



;player 1 gain a point if they say 9+10!=21
jb p1f,p1_q2_win
sjmp avoid_p1_q2_win
p1_q2_win:
ljmp p1_right
avoid_p1_q2_win:
;player 2 gain a point if they say 9+10!=21
jb p2f,p2_q2_win
sjmp avoid_p2_q2_win
p2_q2_win:
ljmp p2_right
avoid_p2_q2_win:


;keep looping awaiting answer
ljmp question_2
ret



question_3: 
set_cursor(1,1) 
Send_Constant_String(#question3_line1)
set_cursor(2,1)
Send_constant_string(#question3_line2)
ljmp measure_caps ;look for any button presses
;check flags to determine right answer

;canadas national sport is not hockey so players will gain a point for saying F and lose a point for saying T

jb p1t,p1_q3_lose
sjmp avoid_p1_q3_lose
p1_q3_lose:
ljmp p1_wrong
avoid_p1_q3_lose:

jb p2t,p2_q3_lose
sjmp avoid_p2_q3_lose
p2_q3_lose:
ljmp p2_wrong
avoid_p2_q3_lose:




jb p1f,p1_q3_win
sjmp avoid_p1_q3_win
p1_q3_win:
ljmp p1_right
avoid_p1_q3_win:

jb p2f,p2_q3_win
sjmp avoid_p2_q3_win
p2_q3_win:
ljmp p2_right
avoid_p2_q3_win:


;keep looping awaiting answer
ljmp question_3
ret


;---------------------------------;
; question selection sub          ;
;---------------------------------;



Qsel:
	mov q_total, #5
	mov a,qnum
	cjne a, #1, avoid1
	ljmp question_1
	avoid1:

	cjne a, #2, avoid2
	ljmp question_2
	avoid2:
		
	cjne a, #3, avoid3
	ljmp question_3
	avoid3:

	cjne a, #4, avoid4
	;ljmp question_4
	avoid4:

	cjne a, #5, avoid5
	;ljmp question_5
	avoid5:

	cjne a, #6, avoidwin
	;ljmp Winner
	avoidwin:

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

mov a,Qnum
add a,#1
mov Qnum,a

Set_Cursor(1, 1)
Send_Constant_String(#clear_screen)
Set_Cursor(1, 1)
Send_Constant_String(#p1_correct)
;ljmp high_buzz_2s 
;this goes in buzzer subroutine
;ljmp Qsel

p1_wrong:

;FIRST CHECK IF 0
mov a,p1_points
cjne a,#0,carpool
sjmp skip_this_boy
;reduce points of not already 0
carpool:
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
;ljmp low_buzz_2s
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
Send_Constant_String(#p1_correct)
;ljmp high_buzz_2s
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
Send_Constant_String(#p1_incorrect)
;ljmp low_buzz_2s
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

    clr pf_flag  ;start off displaying picofarads
    setb nf_flag
    clr uf_flag
    clr P1T 
    clr P2T
    clr P1F
    clr P2F
    
    MOV P1_points,#0 ;both players start off with 0 points
    MOV P2_points,#0
    MOV Qnum,#1 ;start with question number 1
    
    ;ljmp measure_caps
    ;ljmp Qsel
    
    
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
	Load_y(9000) ;if C>50nf then the button was pressed
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
	Load_y(10000) ;if C>50nf then the button was pressed
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
	Load_y(8000) ;if C>50nf then the button was pressed
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
	Load_y(9000) ;if C>50nf then the button was pressed
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
	
	
		
	


	
	
	;Finally displaying the outputs after all flag measures have been taken
	
	
	;SIGNALLING WHETHER OR NOT PLAYER 1 PRESSED TRUE BUTTON
    set_cursor(1,1)
    ;showing 1 if button pressed
    jb P1T, show_p1t
    sjmp avoid_show_p1t
    show_p1t:
    Display_char(#'1')
	avoid_show_p1t:

	;showing 0 if button not pressed
	jnb P1T,show_not_p1t
	sjmp avoid_show_not_p1t
	show_not_p1t:
	Display_char(#'0')
	avoid_show_not_p1t:
	
	
	
	
	set_cursor(1,2)
	 ;SIGNALLING WHETHER OR NOT PLAYER 1 PRESSED FALSE BUTTON
    
    ;showing 1 if button pressed
    jb P1F, show_p1f
    sjmp avoid_show_p1f
    show_p1f:
    Display_char(#'1')
	avoid_show_p1f:

	;showing 0 if button not pressed
	jnb P1F,show_not_p1f
	sjmp avoid_show_not_p1f
	show_not_p1f:
	Display_char(#'0')
	avoid_show_not_p1f:

	
	
	set_cursor(2,1)
	;SIGNALLING WHETHER OR NOT PLAYER 2 PRESSED TRUE BUTTON
    
    ;showing 1 if button pressed
    jb P2T, show_p2t
    sjmp avoid_show_p2t
    show_p2t:
    Display_char(#'1')
	avoid_show_p2t:

	;showing 0 if button not pressed
	jnb P2T,show_not_p2t
	sjmp avoid_show_not_p2t
	show_not_p2t:
	Display_char(#'0')
	avoid_show_not_p2t:

	
	
	
	
	;SIGNALLING WHETHER OR NOT PLAYER 2 PRESSED FALSE BUTTON
    
    set_cursor(2,2)
    ;showing 1 if button pressed
    jb P2F, show_p2f
    sjmp avoid_show_p2f
    show_p2f:
    Display_char(#'1')
	avoid_show_p2f:

	;showing 0 if button not pressed
	jnb P2F,show_not_p2f
	sjmp avoid_show_not_p2f
	show_not_p2f:
	Display_char(#'0')
	avoid_show_not_p2f:
	
	
	

	ljmp measure_caps
	;ljmp Qsel

end

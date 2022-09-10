;This code was made using a template of Period_RC2_math_over.asm from note 316 on piazza


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

BSEG
mf: dbit 1
pf_flag: dbit 1
nf_flag: dbit 1	;flags to choose which units to display
uf_flag: dbit 1

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


unit_change:
;cycle between pf->nf->uf->pf, one subroutine for each transition 


jb pf_flag,change_to_nf
jb nf_flag,change_to_uf
jb uf_flag,change_to_pf

sjmp skip_change_to_pf
change_to_pf:
setb pf_flag
clr nf_flag
clr uf_flag
skip_change_to_pf:

sjmp skip_change_to_uf
change_to_uf:
setb uf_flag
clr pf_flag
clr nf_flag
skip_change_to_uf:

sjmp skip_change_to_nf
change_to_nf:
setb nf_flag
clr pf_flag
clr uf_flag
skip_change_to_nf:



ret





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
	ljmp unit_change
	dont_change_units_boogaloo:
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
; Main program loop               ;
;---------------------------------;
MyProgram:
    ; Initialize the hardware:
    mov SP, #7FH
    lcall Initialize_All
    setb P0.0 ; Pin is used as input
	setb unit_conversion_button
	Set_Cursor(1, 1)
    Send_Constant_String(#Initial_Message)
    clr pf_flag  ;start off displaying picofarads
    setb nf_flag
    clr uf_flag
forever:
;ljmp button_registering


    ; synchronize with rising edge of the signal applied to pin P0.0
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
    ljmp forever ; Repeat! 
	
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
	Load_y(1000)
	;lcall div32

	Load_y(45211) ; One clock pulse is 45211.23/1000ns, the 1/1000 is taken care of by the last two instructions
	;just use 45ns for less accuracy and less hassle
	;Load_y(45)
	lcall mul32
	;now x stores #_of_pulses*clock_period(ns) to get period or nanoseconds transpired 



	;x now stores the number of nanoseconds transpired
	; Convert from ns to Hz
	;lcall copy_xy ;y now stores nanoseconds transpired
	;Load_x(1000000000);x=10^9
	;lcall div32 ;x=10^9*(1/(nanoseconds))=(10^9/10^9)*(1/seconds)=hertz




	;CODE TO CONVERT PERIOD MEASURMENT INTO CAPACITENCE
	
	
	;C=period/(ln(2)*(Ra+2*Rb))
	;Ra=980ohm Rb=1953, (ln(2)*(Ra+2*Rb))=2036
	Load_y(2036)
	lcall div32 ;now x has capacitence in nf 
	
	;this value is to be transformed depending on the status flags


	jb nf_flag,display_nanofarads
	;no conversion needed if trying to display nf
	jnb pf_flag, do_not_convert_to_pf
	
	;convert nf to picofarads
	Load_y(1000)
	lcall mul32
	;make sure to display that it is pf on the LCD
	set_cursor(1,14)
	Send_Constant_String(#pf_string)
	ljmp end_unit_conversion ;make sure to skip over converting to uf after converting to pf
	do_not_convert_to_pf:
	
	;converting nf to uf
	Load_y(1000)
	lcall div32
	;make sure to display that it is uf on the LCD
	set_cursor(1,14)
	Send_Constant_String(#uf_string)
	ljmp end_unit_conversion
	
	display_nanofarads:
	set_cursor(1,14)
	Send_Constant_String(#nf_string)
	
	end_unit_conversion:
	
	
	
	
	;code to convert a period measurment into the a value of Ra
	;X currently holds period in ns
	
	;Ra=(period-2*ln(2)*Rb*C)/(C*ln(2))
	;Working with C=0.1uf,Rb=1953
	
	;2*ln(2)*Rb*C=270743ns need it to be in ns to subtract from period in ns
	;load_y(270743)
	;lcall sub32 ;now  x=(period-2*ln(2)*Rb*C) in ns
	
	;doing this may cause x to overflow and ruin data for higher resistances or capacitances
	;load_y(1000)
	;lcall mul32 ;now x is in ps so that greater accuracy can be achived when dividing
	
	;C*ln(2)=69315pf need it to be in pf to divide ps by it to get Resistance
	
	;load_y(69)
	
	;using this number may cause overflow 
	;load_y(69315)
	
	;lcall div32 ;x now stores Ra
	
	
	; Convert the result to BCD and display on LCD
	Set_Cursor(2, 1)
	lcall hex2bcd
	lcall Display_10_digit_BCD
 	
 	;this code is to display the overflow counter for testing purposes
    ;Display_BCD(overflow_counter+0)
    ;Set_cursor(2,4)
    ;Display_BCD(overflow_counter+1)
    
    ljmp forever ; Repeat! 


end

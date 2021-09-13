A_IN			BIT		P2.6
B_IN			BIT		P2.7
C_IN			BIT		P2.4
BUZZER_PIN		BIT		P2.5
SW1_PIN			BIT		P2.1
SW4_PIN			BIT		P2.0

COUNTER_BIT		BIT		20H.0
BEEP_ON			BIT		20H.1
SW1_PRESSED		BIT		20H.2
SW4_PRESSED		BIT		20H.3
RESET_READY		BIT		20H.4
	
DISP_COUNTER	EQU		30H				;1 to keep track of the display no. to which data has been sent(0-5)
DISP_DATA		EQU		31H				;6 bytes from 30H are used to store the hex values to be sent to P0 for the 6 displays(6 bytes)
DISP_REG		EQU		37H				;6 keep track of the digits to be displayed on the 6 displays(6 bytes
COUNT1			EQU		3DH				; 1
DIGIT			EQU		3EH				; 1
COUNTER_REG		EQU		3FH				; 3
SEC_ONES		EQU		42H				; 2
BUZ_COUNTER		EQU		44H				; 1
SW1_COUNTER		EQU		45H				; 1
SW4_COUNTER		EQU		46H				; 1
SERIAL_REG		EQU		47H				; 7
DECIMAL_ASCII	EQU		2EH

CSEG
		ORG		0000H
		LJMP	MAIN

		ORG		000BH
		LJMP	ISR_T0

		ORG		0030H					;bypass vector table
MAIN:	CLR		BUZZER_PIN
		CLR		BEEP_ON
		CLR		RESET_READY
		CLR		SW1_PRESSED
		MOV		BUZ_COUNTER,#0
		MOV		DISP_COUNTER,#0
		MOV		P0,#0FFH
		MOV		TMOD,#21H				;Timer0,Mode1(16-bit) and Timer1,Mode2(8-bit auto-reload)
		MOV		TH0,#0F8H				;load initial count value for Timer0
		MOV		TL0,#0CDH
		MOV		TH1,#-6					;load initial count value for Timer1(will be used for serial comm)
		MOV		SCON,#50H				;Serial Mode1(1 start and 1 stop bit),REN enabled
		MOV		IE,#82H					;enable Timer0 interrupt
		SETB	TR0						;start Timer0
		SETB	TR1						;start Timer1
;------------starting of power on display sequence(scrolling of 0-9 once)----------------		
		MOV		DISP_REG,#0AH
		MOV		DISP_REG+1,#0AH
		MOV		DISP_REG+2,#0AH
		MOV		DISP_REG+3,#0AH
		MOV		DISP_REG+4,#0AH
		MOV		DISP_REG+5,#0AH
		LCALL	LOAD_DISP_DATA
		LCALL	DELAY

		MOV		DIGIT,#0
REPEAT1:	
		LCALL	SHIFT_DIGIT
		MOV		DISP_REG,DIGIT
		LCALL	LOAD_DISP_DATA
		LCALL	DELAY
		INC		DIGIT
		MOV		A,DIGIT
		CJNE	A,#10,REPEAT1

		
		MOV		R4,#6
REPEAT2:
		LCALL	SHIFT_DIGIT
		MOV		DISP_REG,#0AH
		LCALL	LOAD_DISP_DATA
		LCALL	DELAY
		DJNZ	R4,REPEAT2
		
		
;--------starting of millisecond counter-----------
		
LOOP001:
		CLR		RESET_READY
		SETB	BEEP_ON
		SETB	SW1_PIN
		SETB	SW4_PIN
		MOV		COUNTER_REG,#0		;MSB
		MOV		COUNTER_REG+1,#0
		MOV		COUNTER_REG+2,#0	;LSB
		LCALL	UNPACK_COUNT
		LCALL	LOAD_DISP_DATA
		ANL		DISP_DATA+3,#0BFH
		MOV		SEC_ONES,#0
		MOV		SEC_ONES+1,#0

		CLR		SW1_PRESSED
		CLR		SW4_PRESSED
		CLR		COUNTER_BIT
INITIAL_WAIT:		
		JNB		SW1_PRESSED,INITIAL_WAIT		;initial START
		CLR		SW1_PRESSED
		
LOOP002:JNB		COUNTER_BIT,LOOP002
		CLR		COUNTER_BIT
		LCALL	UPDATE_COUNTER
		LCALL	UNPACK_COUNT
		LCALL	REMOVE_LEADING_ZEROS
		LCALL	CHECK_SEC_DELAY
		LCALL	LOAD_DISP_DATA
		ANL		DISP_DATA+3,#0BFH
		JNB		SW1_PRESSED,LOOP002				;if SW1_PRESSED equals 0,then continue by jumping to LOOP002(else STOP)
		CLR		SW1_PRESSED
		LCALL	LOAD_SERIAL_REG
		LCALL	SERIAL_TRANSFER
LOOP003:SETB	RESET_READY
		JB		SW4_PRESSED,LOOP001				;if SW4_PRESSED=1,then reset by jumping to LOOP001
		JNB		SW1_PRESSED,LOOP003				;if SW1_PRESSED equals 0,then wait here only(START)
		CLR		SW1_PRESSED

		CLR		COUNTER_BIT
		SJMP	LOOP002

;-------------end of MAIN------------------
SERIAL_TEST:
		;MOV		A,#41H
		MOV		SBUF,A
SERIAL_LOOP:
		JNB		TI,SERIAL_LOOP
		CLR		TI
		RET

;------------------------------------------
SERIAL_TRANSFER:
		CLR		REN
		CLR		TI
		MOV		R0,#SERIAL_REG+6
LOOP060:MOV		A,@ R0
		CJNE	A,#3AH,LOOP061					;if A not equal to 3AH,then continue by jumping to LOOP061
		SJMP	LOOP063										;else,we've got a leading zero,therefore simply return
LOOP061:MOV		SBUF,A
		LCALL	XMIT_BYTE
LOOP063:DEC		R0
		CJNE	R0,#SERIAL_REG-1,LOOP060		;repeat the process till transmission of 7 bytes of SERIAL_REG is complete
		MOV		SBUF,#0DH
		LCALL	XMIT_BYTE
		MOV		SBUF,#0AH
		LCALL	XMIT_BYTE
		RET
		
XMIT_BYTE:		
LOOP062:JNB		TI,LOOP062						;wait for TI flag to be set(i.e. till completion of serial transfer of 1 character)
		CLR		TI								;clear TI flag to get ready for next character transfer
		RET

;------------------------------------------
LOAD_SERIAL_REG:
		MOV		R0,#DISP_REG
		MOV		R1,#SERIAL_REG
LOOP070:MOV		A,@ R0
		ORL		A,#30H				;ANDing with 30H to get ASCII value of the digit stored in R1,storing this value in accumulator
		MOV		@ R1,A							;and then loading it to R1
		INC		R0
		INC		R1
		CJNE	R0,#DISP_REG+3,LOOP071			;if R0=#DISP_REG+3,we need to load the ascii value of the decimal point next
		MOV		@ R1,#DECIMAL_ASCII
		INC		R1
LOOP071:CJNE	R0,#DISP_REG+6,LOOP070
		RET
;------------------------------------------
REMOVE_LEADING_ZEROS:
		MOV		R0,#DISP_REG+5
LOOP080:MOV		A,@ R0
		CJNE	A,#00,EXIT_SUBROUTINE
		MOV		@ R0,#0AH
		DEC		R0
		CJNE	R0,#DISP_REG+3,LOOP080
EXIT_SUBROUTINE:
		RET
		

;------------------------------------------
CHECK_SEC_DELAY:
		MOV		A,SEC_ONES
		CJNE	A,DISP_REG+3,LOOP081
		RET
LOOP081:
		MOV		SEC_ONES,DISP_REG+3
		SETB	BEEP_ON
		RET
;		MOV		A,SEC_ONES				;old value
;		CJNE	A,DISP_REG+3,LOOP082	;new value
;		MOV		A,SEC_ONES+1			;old value
;		CJNE	A,DISP_REG+2,LOOP081	;new value
;		RET
;LOOP081:
;		MOV		SEC_ONES+1,DISP_REG+2	;new value
;		CLR		BUZZER_PIN
;		RET	

;LOOP082:
;		MOV		SEC_ONES,DISP_REG+3		;new value
;		MOV		SEC_ONES+1,DISP_REG+2	;new value
;		SETB	BUZZER_PIN
;		RET

;------------------------------------------

UNPACK_COUNT:
		MOV		R0,#COUNTER_REG
		MOV		R1,#DISP_REG+5
LOOP090:MOV		A,@ R0
		SWAP	A
		ANL		A,#0FH
		MOV		@ R1,A
		DEC		R1
		MOV		A,@ R0
		ANL		A,#0FH
		MOV		@ R1,A
		DEC		R1
		INC		R0
		CJNE	R0,#COUNTER_REG+3,LOOP090
		RET
;---------------------------------------------
UPDATE_COUNTER:
		CLR		C
		MOV		A,COUNTER_REG+2
		ADDC	A,#1
		DA		A
		MOV		COUNTER_REG+2,A
		MOV		A,COUNTER_REG+1
		ADDC	A,#0
		DA		A
		MOV		COUNTER_REG+1,A
		MOV		A,COUNTER_REG
		ADDC	A,#0
		DA		A
		MOV		COUNTER_REG,A
		RET

;-----------------------------------------------

SHIFT_DIGIT:
		MOV		DISP_REG+5,DISP_REG+4
		MOV		DISP_REG+4,DISP_REG+3
		MOV		DISP_REG+3,DISP_REG+2
		MOV		DISP_REG+2,DISP_REG+1
		MOV		DISP_REG+1,DISP_REG
		RET

DELAY:	MOV		R5,#5
LOOP100:MOV		R6,#0
LOOP101:MOV		R7,#0
LOOP102:DJNZ	R7,LOOP102
		DJNZ	R6,LOOP101
		DJNZ	R5,LOOP100
		RET
;------------------------------------------


LOAD_DISP_DATA:
		MOV		R0,#DISP_DATA
		MOV		R1,#DISP_REG
		MOV		DPTR,#TABLE2
LOOP110:MOV		A,@ R1
		MOVC	A,@ A+DPTR				;A contains the hex databyte that is to be loaded in disp_data space location
		MOV		@ R0,A					;perform loading disp_data location using Table2 data and disp_reg 
		INC		R0
		INC		R1
		CJNE	R1,#DISP_REG+6,LOOP110
		RET
;----------------------------------------------					
					
ISR_T0:		PUSH	PSW
			PUSH	ACC
			CLR		TF0						;clear Timer0 flag bit
			MOV		TH0,#0F8H
			MOV		TL0,#0CDH
			SETB	COUNTER_BIT	
			JNB		RESET_READY,CONTINUE_ISR
			LCALL	SW4_ROUTINE
CONTINUE_ISR:
			LCALL	SW1_ROUTINE
			LCALL	DISPLAY_ROUTINE
			LCALL	BUZZER_SERVICE
EXIT_ISR:	POP		ACC
			POP		PSW
			RETI					
;---------------------------------------------
SW1_ROUTINE:
			JNB		SW1_PIN,LOOP120					;if SW1=0(pressed),jump to LOOP120
			MOV		SW1_COUNTER,#40					;if SW1=1(not pressed),reset SW1_COUNTER
			RET										;and return
LOOP120:	MOV		A,SW1_COUNTER
			CJNE	A,#0,LOOP121					;if SW1_COUNTER not equals 0,then jump to LOOP121
			RET										;if SW1_COUNTER=0,then return

LOOP121:	DJNZ	SW1_COUNTER,EXIT_SW1_ROUTINE		;and jump to EXIT if it is not equal to 0
			SETB	SW1_PRESSED						;if it is reduced to 0,set SW1_PRESSED flag bit
			;SETB	BEEP_ON

EXIT_SW1_ROUTINE:
			RET
;---------------------------------------------

SW4_ROUTINE:
			JNB		SW4_PIN,LOOP130					;if SW4=0(pressed),jump to LOOP130
			MOV		SW4_COUNTER,#40					;if SW4=1(not pressed),reset SW4_COUNTER
			RET										;and return
LOOP130:	MOV		A,SW4_COUNTER
			CJNE	A,#0,LOOP131					;if SW4_COUNTER not equals 0,then jump to LOOP131
			RET										;if SW4_COUNTER=0,then return

LOOP131:	DJNZ	SW4_COUNTER,EXIT_SW4_ROUTINE		;and jump to EXIT if it is not equal to 0
			SETB	SW4_PRESSED						;if it is reduced to 0,set SW4_PRESSED flag bit
			;SETB	BEEP_ON

EXIT_SW4_ROUTINE:
			RET

;---------------------------------------------
BUZZER_SERVICE:
			JNB		BEEP_ON,RESET_BUZZER_SERVICE
			SETB	BUZZER_PIN
			DJNZ	BUZ_COUNTER,EXIT_BUZZER_SERVICE
			CLR		BUZZER_PIN
			CLR		BEEP_ON
RESET_BUZZER_SERVICE:			
			MOV		BUZ_COUNTER,#40
EXIT_BUZZER_SERVICE:
			RET

;---------------------------------------------

DISPLAY_ROUTINE:
			PUSH	00H
			PUSH	01H
			PUSH	05H
			MOV		P0,#0FFH				;0FF
			LCALL	TO_BIN
			MOV 	A,#DISP_DATA
			ADD		A,DISP_COUNTER
			MOV		R0,A
			MOV		P0,@ R0
			INC		DISP_COUNTER
			MOV		A,DISP_COUNTER
			CJNE	A,#6,EXIT_DISPLAY_ROUTINE
			MOV		DISP_COUNTER,#0H
EXIT_DISPLAY_ROUTINE:
			POP		05H
			POP		01H
			POP		00H
			RET

;-----------------------------------------------
TO_BIN:	CLR		A_IN			;initially set the decoder's inputs to 0
		CLR		B_IN
		CLR		C_IN
		MOV		R5,DISP_COUNTER
		INC		R5
		MOV		A,R5			;make A=R5
		MOV		B,#2			;base 2 since we want to convert to binary
		DIV		AB				;perform A/B, quotient and remainder stored in A and B resp.
		MOV		R1,A			;temporarily store A in R1
		MOV		A,B				;copy B in A for some computation
		CJNE	A,#1,NEXT1		;if A not equals 1,jump to NEXT1(A here has a copy of B)
		SETB	A_IN			;if A=1 then make a=1 as well(A here has a copy of B)
NEXT1:	MOV		B,#2			;load base 2 again
		MOV		A,R1			;load back the original value into A
		DIV		AB				;perform A/B, quotient and remainder stored in A and B resp.
		MOV		R1,A			;temporarily store A in R1
		MOV		A,B				;copy B in A for some computation
		CJNE	A,#1,NEXT2		;if A not equals 1,jump to NEXT2(A here has a copy of B)
		SETB	B_IN			;if A=1 then make b=1 as well(A here has a copy of B)
NEXT2:	MOV		A,R1			;load back the original value into A
		CJNE	A,#1,NEXT3		;if A not euals 1,jump to NEXT3
		SETB	C_IN			;if A=1 then make c=1 as well
NEXT3:	RET						;return from subroutine


;------------------------------------------------

TABLE2:				DB	44H,7DH,0C8H,68H,71H,62H,42H,07CH,40H,70H,0FFH	;hex values to be sent to seven segment display for displaying digits 0-9

					END
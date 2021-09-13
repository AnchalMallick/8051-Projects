A_IN			BIT		P2.6
B_IN			BIT		P2.7
C_IN			BIT		P2.4
BUZ				BIT		P2.5
DISP_COUNTER	EQU		50H				;to keep track of the display no. to which data has been sent(0-5)
DISP_DATA		EQU		30H				;6 bytes from 30H are used to store the hex values to be sent to P0 for the 6 displays(6 bytes)
DISP_REG		EQU		40H				;keep track of the digits to be displayed on the 6 displays(6 bytes
COUNT1			EQU		47H
DIGIT			EQU		48H

CSEG
		ORG		0000H
		LJMP	MAIN

		ORG		000BH
		LJMP	ISR_T0

		ORG		0030H					;bypass vector table
MAIN:	CLR		BUZ
		CLR		A_IN
		CLR		B_IN
		SETB	C_IN
		MOV		DISP_COUNTER,#0
		MOV		P0,#0FFH
		MOV		TMOD,#01H				;Timer0,Mode1(16-bit)
		MOV		TH0,#0F8H				;load initial count value
		MOV		TL0,#0CDH
		MOV		IE,#82H					;enable Timer0 interrupt
		SETB	TR0
;------------starting of power on display sequence(scrolling of 0-9 once)----------------		
LOOP001:MOV		DISP_REG,#0AH
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
		
		MOV		COUNT1,#0
		MOV		DISP_REG,#00H
		MOV		DISP_REG+1,#00H
		MOV		DISP_REG+2,#00H
		MOV		DISP_REG+3,#00H
		MOV		DISP_REG+4,#00H
		MOV		DISP_REG+5,#00H
		LCALL	LOAD_DISP_DATA
		ANL		DISP_DATA+3,#0BFH
;HERE_M:	SJMP	HERE_M
REPEAT3:
		MOV		A,COUNT1
		CJNE	A,#1,REPEAT3
		MOV		COUNT1,#0
		;LCALL	DELAY
		
LOOP_1:	LCALL	ADD_1ms
		LCALL	LOAD_DISP_DATA
		ANL		DISP_DATA+3,#0BFH
REPEAT4:
		MOV		A,COUNT1
		CJNE	A,#1,REPEAT4
		MOV		COUNT1,#0
		SJMP	LOOP_1
;-------------end of MAIN-----------------


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

ADD_1ms:
		INC		DISP_REG
		MOV		A,DISP_REG
		CJNE	A,#0AH,HERE1
		MOV		DISP_REG,#0
		SJMP	DISP2
HERE1:	RET						;LJMP	EXIT1
		
DISP2:	INC		DISP_REG+1
		MOV		A,DISP_REG+1
		CJNE	A,#0AH,HERE2	
		MOV		DISP_REG+1,#0
		SJMP	DISP3
HERE2:	RET						;LJMP	EXIT1
		
DISP3:	INC		DISP_REG+2
		MOV		A,DISP_REG+2
		CJNE	A,#0AH,HERE3
		MOV		DISP_REG+2,#0
		SJMP	DISP4
HERE3:	RET						;LJMP	EXIT1

DISP4:	INC		DISP_REG+3
		MOV		A,DISP_REG+3
		CJNE	A,#0AH,HERE4
		MOV		DISP_REG+3,#0
		SJMP	DISP5
HERE4:	RET						;LJMP	EXIT1
		
DISP5:	INC		DISP_REG+4
		MOV		A,DISP_REG+4
		CJNE	A,#0AH,HERE5
		MOV		DISP_REG+4,#0
		SJMP	DISP6
HERE5:	RET						;LJMP	EXIT1
		
DISP6:	INC		DISP_REG+5
		MOV		A,DISP_REG+5
		CJNE	A,#0AH,EXIT1
		MOV		DISP_REG+5,#0
EXIT1:	RET						;LJMP	EXIT1



;-----------------------------------------------
		

LOAD_DISP_DATA:
		MOV		R0,#DISP_DATA
		MOV		R1,#DISP_REG
		MOV		DPTR,#TABLE2
LOOP010:MOV		A,@ R1
		MOVC	A,@ A+DPTR				;A contains the hex databyte that is to be loaded in disp_data space location
		MOV		@ R0,A					;perform loading disp_data location using Table2 data and disp_reg 
		INC		R0
		INC		R1
		CJNE	R1,#DISP_REG+6,LOOP010
		RET
;----------------------------------------------					
					
ISR_T0:		PUSH	PSW
			PUSH	ACC
			INC		COUNT1
			CLR		TF0						;clear Timer0 flag bit
			MOV		TH0,#0F8H
			MOV		TL0,#0CDH
			MOV		P0,#0FFH				;0FF
			LCALL	TO_BIN
			MOV 	A,#DISP_DATA
			ADD		A,DISP_COUNTER
			MOV		R0,A
			MOV		P0,@ R0
			INC		DISP_COUNTER
			MOV		A,DISP_COUNTER
			CJNE	A,#6,EXIT_ISR
			MOV		DISP_COUNTER,#0H
EXIT_ISR:	POP		ACC
			POP		PSW
			RETI					
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
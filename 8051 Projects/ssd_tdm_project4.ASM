A_IN			BIT		P2.6
B_IN			BIT		P2.7
C_IN			BIT		P2.4
BUZ				BIT		P2.5
DISP_COUNTER	EQU		50H				;to keep track of the display no. to which data has been sent(0-5)
DISP_DATA		EQU		30H				;6 bytes from 30H are used to store the hex values to be sent to P0 for the 6 displays(6 bytes)
DISP_REG		EQU		40H				;keep track of the digits to be displayed on the 6 displays(6 bytes)
LOC				EQU		46H
COUNT1			EQU		47H
COUNT2			EQU		49H
DIGIT			EQU		48H
CSEG
			ORG		0000H
			LJMP	MAIN
			ORG		000BH
			LJMP	ISR_T0
			ORG		0030H					;bypass vector table
MAIN:		CLR		BUZ
			MOV		P0,#0FFH
			MOV		DPTR,#TABLE
			MOV		TMOD,#01H
			MOV		TH0,#0F8H
			MOV		TL0,#0CDH
			MOV		IE,#82H					;enable Timer0 interrupt
			MOV		COUNT2,#00H

			SETB	TR0						;start Timer0
LOAD:		MOV		DIGIT,#0
NEXT:		MOV		LOC,#00H
HERE:		MOV		A,#DISP_REG
			ADD		A,LOC
			MOV		R0,A					;R0 pointing to DISP_REG space
			MOV		@ R0,DIGIT
			MOV		A,#DISP_DATA
			ADD		A,LOC
			MOV		R1,A					;R1 pointing to DISP_DATA space
			LCALL	CONV_TO_DISP
			INC		LOC
			MOV		A,LOC
			CJNE	A,#6,HERE
BACK:		MOV		A,COUNT2
			CJNE	A,#10,BACK
			MOV		COUNT2,#0
			INC		DIGIT
			MOV		A,DIGIT
			CJNE	A,#10,NEXT
			LJMP	LOAD
	

			
CONV_TO_DISP:	MOV		A,DIGIT
				MOVC	A,@	A+DPTR
				MOV		@R1,A
				RET
				

ISR_T0:		PUSH	PSW
			PUSH	ACC
			;INC		COUNT1
			MOV		A,COUNT1
			CJNE	A,#99,LINE1
			MOV		COUNT1,#0
			INC		COUNT2
LINE1:		INC		COUNT1
			CLR		TF0						;clear Timer0 flag bit
			MOV		TH0,#0F8H
			MOV		TL0,#0CDH
			MOV		P0,#0FFH
			LCALL	TO_BIN
			MOV 	A,#DISP_DATA
			ADD		A,DISP_COUNTER
			MOV		R0,A
			MOV		P0,@R0
			INC		DISP_COUNTER
			MOV		A,DISP_COUNTER
			CJNE	A,#6,EXIT_ISR
			MOV		DISP_COUNTER,#00H
EXIT_ISR:	POP		ACC
			POP		PSW
			RETI

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


TABLE:	DB	44H,0D7H,0C8H,68H,71H,62H,42H,07CH,40H,70H	;hex values to be sent to seven segment display for displaying digits 0-9

		END
		

			
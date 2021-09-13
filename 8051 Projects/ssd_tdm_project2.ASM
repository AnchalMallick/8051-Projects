		ORG		0000H
		LJMP 	MAIN			;bypass interrupt vector table
		
		ORG		000BH			;Timer0 interrupt space in vector table
		LJMP	ISR_T0			;jump to ISR serving Timer1 interrupt
		
		ORG		30H				;start with main program after vector table
MAIN:	CLR 	P2.5			;clear buzzer pin
		MOV		TMOD,#01H		;Timer0,Mode1(16-bit)
		MOV		TH0,#0F8H		;loading initial count value in TH0 and TL0
		MOV		TL0,#0CDH
		MOV		IE,#10000010B	;enable Timer0 in IE register
		SETB	TR0				;start Timer0
AGAIN:	MOV		DPTR,#TABLE		;point to 1st data bytestored in code space
		MOV		R5,#0			;make R5=0
HERE:	MOV		A,R5			;load the content of R5 in A
		CJNE	A,#6,HERE		;if A not equals 6,jump to HERE
		SJMP	AGAIN			;repeat the loop

ISR_T0:	PUSH	PSW
		PUSH	ACC
		;PUSH	B
		;PUSH	DPH
		;PUSH	DPL
		INC		R5				;increment R5 by 1
		MOV		P0,#0FFH		;to make sure that P0 is cleared
		LCALL	TO_BIN			;Call TO_BIN subroutine,this will set the decoder's inputs
		MOVC	A,@ A+DPTR		;fetch data byte from code space
		MOV		P0,A			;send the data fetched to Port0
		INC		DPTR			;increment DPTR so that it points to next data byte
		MOV		TH0,#0F8H		;load the initial count again
		MOV		TL0,#0CDH
		;POP		DPL
		;POP		DPH
		;POP		B
		POP		ACC
		POP		PSW
		RETI					;return from ISR

TO_BIN:	CLR		P2.6			;initially set the decoder's inputs to 0
		CLR		P2.7
		CLR		P2.4
		MOV		A,R5			;make A=R5
		MOV		B,#2			;base 2 since we want to convert to binary
		DIV		AB				;perform A/B, quotient and remainder stored in A and B resp.
		MOV		R1,A			;temporarily store A in R1
		MOV		A,B				;copy B in A for some computation
		CJNE	A,#1,NEXT1		;if A not equals 1,jump to NEXT1(A here has a copy of B)
		SETB	P2.6			;if A=1 then make a=1 as well(A here has a copy of B)
NEXT1:	MOV		B,#2			;load base 2 again
		MOV		A,R1			;load back the original value into A
		DIV		AB				;perform A/B, quotient and remainder stored in A and B resp.
		MOV		R1,A			;temporarily store A in R1
		MOV		A,B				;copy B in A for some computation
		CJNE	A,#1,NEXT2		;if A not equals 1,jump to NEXT2(A here has a copy of B)
		SETB	P2.7			;if A=1 then make b=1 as well(A here has a copy of B)
NEXT2:	MOV		A,R1			;load back the original value into A
		CJNE	A,#1,NEXT3		;if A not euals 1,jump to NEXT3
		SETB	P2.4			;if A=1 then make c=1 as well
NEXT3:	CLR		A				;make A=0
		RET						;return from subroutine


TABLE:	DB	0D7H,0C8H,68H,71H,62H,42H	;hex values to be sent to seven segment display for displaying digits 1-6
		END
			
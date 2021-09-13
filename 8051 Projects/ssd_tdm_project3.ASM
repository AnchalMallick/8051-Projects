		N				EQU		31H				;to keep track of the the no. of digits displayed 
		COUNT			EQU		30H				;to keep track of the no. of clock pulses counted(max value goes till 200,i.e. for 1 ms delay)
		A_IN			BIT		P2.6			;decoder input A
		B_IN			BIT		P2.7			;decoder input B
		C_IN			BIT		P2.4			;decoder input C

		DSEG			AT		20H
		DISP_DATA		EQU		30H


		CSEG
		ORG		0000H
		LJMP 	MAIN			;bypass interrupt vector table
		
		ORG		000BH			;Timer0 interrupt space in vector table
		LJMP	ISR_T0			;jump to ISR serving Timer1 interrupt
		
		ORG		30H				;start with main program after vector table
MAIN:			
	
		CLR 	P2.5			;clear buzzer pin
		MOV		TMOD,#01H		;Timer0,Mode1(16-bit)
		MOV		TH0,#0DCH		;loading initial count value in TH0 and TL0
		MOV		TL0,#00H
		MOV		IE,#10000010B	;enable Timer0 in IE register
		SETB	TR0				;start Timer0
		MOV		N,#0            ;load initial values
		MOV		DPTR,#TABLE
		MOV		COUNT,#0
		MOV		R5,#0
		
AGAIN:	MOV		A,COUNT			;load the value stored at location COUNT into A
		CJNE	A,#200,HERE		;if A not equals 200,jump to HERE(A has value of COUNT)
		MOV		COUNT,#0
		INC		DPTR
		INC		N
		MOV		A,N
		CJNE	A,#10,NEXT		;if A not equals 10,jump to NEXT(A has value of N)
		MOV		N,#0
		MOV		DPTR,#TABLE
NEXT:	SJMP	AGAIN
HERE:	MOV		A,R5
		CJNE	A,#6,HERE1		;if A not equals 6,jump to HERE1(A has value of R5)
		MOV		R5,#0
HERE1:	SJMP	AGAIN
		

ISR_T0:	PUSH	PSW
		PUSH	ACC
		;PUSH	B
		;PUSH	DPH
		;PUSH	DPL
		INC		R5				;increment R5 by 1
		INC		COUNT			;increment content at COUNT by 1b 
		MOV		P0,#0FFH		;to make sure that P0 is cleared
		LCALL	TO_BIN			;Call TO_BIN subroutine,this will set the decoder's inputs
		MOVC	A,@ A+DPTR		;fetch data byte from code space
		MOV		P0,A			;send the data fetched to Port0
		MOV		TH0,#0DCH		;load the initial count again
		MOV		TL0,#00H
		;POP		DPL
		;POP		DPH
		;POP		B
		POP		ACC
		POP		PSW
		RETI					;return from ISR

TO_BIN:	CLR		A_IN			;initially set the decoder's inputs to 0
		CLR		B_IN
		CLR		C_IN
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
NEXT3:	CLR		A				;make A=0
		RET						;return from subroutine


TABLE:	DB	44H,0D7H,0C8H,68H,71H,62H,42H,07CH,40H,70H	;hex values to be sent to seven segment display for displaying digits 1-6
		END
			
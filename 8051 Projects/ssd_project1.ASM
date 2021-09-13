;interfacing 8051 with seven segment display
		ORG		0000H
		LJMP	POWER_ON


		ORG		0030H
POWER_ON:
		SETB	P2.6        ;clearing A(1st input of 3 to 8 decoder)
		CLR		P2.7        ;clearing B(2nd input of 3 to 8 decoder)
		CLR		P2.4        ;setting C(3rd input of 3 to 8 decoder)
							;clearing A,B,C will ensure that only display1 is active	   
AGAIN: 	MOV 	DPTR,#TABLE ;load ROM pointer in DPTR
		MOV 	R1,#10    	;load counter value
BACK:  	CLR 	A         	;clear accumulator
		MOVC 	A,@A+DPTR 	;save data from ROM location into A
		MOV 	P0,A      	;send the data fetched from code space to Port0
		MOV		R4,#20
HERE:	LCALL 	DELAY   	;giving some delay
		DJNZ	R4,HERE
		INC 	DPTR      	;increment DPTR by 1 so that it points to next data byte stored in code space
		DJNZ 	R1,BACK  	;repeat 10 times
		SJMP 	AGAIN    	;repeat infinitely

DELAY: 	MOV 	R2,#0FFH
HERE1: 	MOV 	R3,#0FFH  	;outer loop
HERE2: 	DJNZ 	R3,HERE2 	;inner loop
		DJNZ 	R2,HERE1
		RET
		
TABLE: 	DB  	44H,0D7H,0C8H,68H,71H,62H,42H,7CH,40H,70H  ;lookup table of hex values to display digits

		END
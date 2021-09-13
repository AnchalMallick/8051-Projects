SDA_PIN				BIT		P1.0
SCL_PIN				BIT		P1.1
WP_PIN				BIT		P1.2
BUZZER_PIN			BIT		P2.5
ERROR_BIT			BIT		20H.0
FIRST_WORD_ADDR		EQU		30H
SECOND_WORD_ADDR	EQU		31H
DEVICE_ADDR			EQU		32H
DATA_BYTE			EQU		33H
TRIALS				EQU		34H
			ORG		0000H
			LJMP	MAIN
			ORG		0030H
MAIN:		MOV		TMOD,#20H			;Timer1,Mode2 i.e. auto-reload(used by uart)
			MOV		TH1,#-6				;baud rate 9600
			MOV		SCON,#40H			;Serial mode1(8-bit data,1 start  and 1 stop bit),REN disabled
			SETB	TR1					;start Timer1
			CLR		BUZZER_PIN
			LCALL	DELAY
I2C_ROUTINE:
;-----------------------------------------------
										;page write
			CLR		WP_PIN

			MOV		TRIALS,#5

LOOP020:	LCALL	START_EEPROM
			
			MOV		DEVICE_ADDR,#0A6H
			MOV		A,DEVICE_ADDR
			LCALL	SEND_BYTE			;sending device address
			JB		ERROR_BIT,LOOP021
			
			MOV		FIRST_WORD_ADDR,#00H
			MOV		A,FIRST_WORD_ADDR
			LCALL	SEND_BYTE			;sending first word address
			JB		ERROR_BIT,LOOP021
			
			MOV		SECOND_WORD_ADDR,#00H
			MOV		A,SECOND_WORD_ADDR
			LCALL	SEND_BYTE			;sending second word address
			JB		ERROR_BIT,LOOP021
			
			MOV		DATA_BYTE,#42H
			MOV		A,DATA_BYTE
			LCALL	SEND_BYTE			;sending data byte
		
			
;			MOV		DATA_BYTE,#31H
;			MOV		A,DATA_BYTE
;			LCALL	SEND_BYTE			;sending data byte
			
LOOP021:	LCALL	STOP_EEPROM

			JNB		ERROR_BIT,LOOP022	;If error flag is not raised,then just continue as usual
			DJNZ	TRIALS,LOOP020		;try again for a specific no. of times

			LCALL	TRANSMISSION_FAILED	;else,after all the failed trials,display a failure message

LOOP022:	SETB	WP_PIN




			LCALL	DELAY
;-----------------------------------------------
										;sequential read
			;--------------------		;dummy write
			LCALL	START_EEPROM
			
			MOV		DEVICE_ADDR,#0A6H
			MOV		A,DEVICE_ADDR
			MOV		TRIALS,#5
			LCALL	SEND_BYTE			;sending device address
			
			MOV		A,FIRST_WORD_ADDR
			MOV		TRIALS,#5
			LCALL	SEND_BYTE			;sending first word address
			
			MOV		A,SECOND_WORD_ADDR
			MOV		TRIALS,#5
			LCALL	SEND_BYTE			;sending second word address



;--------------------
			LCALL	START_EEPROM
			
			MOV		DEVICE_ADDR,#0A7H
			MOV		A,DEVICE_ADDR
			MOV		TRIALS,#5
			LCALL	SEND_BYTE			;sending device address
			
			LCALL	RECEIVE_BYTE
			MOV		A,DATA_BYTE
			SETB	BUZZER_PIN
			LCALL	SERIAL_TRANSFER		;to display data byte fetched
			LCALL	DELAY
			CLR		BUZZER_PIN
			
;			LCALL	RECEIVE_BYTE
;			MOV		A,DATA_BYTE
;			LCALL	SERIAL_TRANSFER		;to display data byte fetched
			
			LCALL	STOP_EEPROM
STOP:		SJMP	STOP			

WRITE_ROUTINE:							;byte write
			LCALL	START_EEPROM
			MOV		DEVICE_ADDR,#0A6H	;R/W=0 for Write
			MOV		A,DEVICE_ADDR		;send device address
			LCALL	SEND_BYTE
			MOV		A,FIRST_WORD_ADDR	;send first word address
			LCALL	SEND_BYTE
			MOV		A,SECOND_WORD_ADDR	;send second word address
			LCALL	SEND_BYTE
			MOV		A,DATA_BYTE			;send data byte
			LCALL	SEND_BYTE
			LCALL	STOP_EEPROM
			RET

READ_ROUTINE:							;random read
			;-------------------		;Dummy write
			LCALL	START_EEPROM
			MOV		DEVICE_ADDR,#0A6H	;R/W=0 for Write
			MOV		A,DEVICE_ADDR		;send device address
			LCALL	SEND_BYTE
			MOV		A,FIRST_WORD_ADDR	;send first word address
			LCALL	SEND_BYTE
			MOV		A,SECOND_WORD_ADDR	;send second word address
			LCALL	SEND_BYTE
			;-------------------
			LCALL	START_EEPROM
			MOV		DEVICE_ADDR,#0A7H	;R/W=1 for Read
			LCALL	SEND_BYTE
			LCALL	RECEIVE_BYTE
			LCALL	STOP_EEPROM
			RET
			
			
START_EEPROM:							;START--> sda high to low while scl is high
			SETB	SDA_PIN
			SETB	SCL_PIN
			JNB		SDA_PIN,START_EEPROM
			JNB		SCL_PIN,START_EEPROM
			CLR		SDA_PIN
			LCALL	NOP_5
			CLR		SCL_PIN
			LCALL	NOP_5
			RET

STOP_EEPROM:							;STOP-->  sda low to high while scl is high
			CLR		SDA_PIN
			LCALL	NOP_5
			SETB	SCL_PIN
			LCALL	NOP_5
			SETB	SDA_PIN
			RET

SEND_BYTE:
			MOV		R3,#8				;since 1 byte is to be transferred
			CLR		C
LOOP001:	
			LCALL	NOP_5
			RLC		A					;this step ensures that CY flag is loaded with MSB
			MOV		SDA_PIN,C
			LCALL	NOP_5
			SETB	SCL_PIN
			LCALL	NOP_5
			CLR		SCL_PIN				;high-to-low clock pulse gives a falling edge(required for transfer in i2c)
			DJNZ	R3,LOOP001
			SETB	SDA_PIN
			LCALL	NOP_5
			SETB	SCL_PIN
			LCALL	NOP_5
			MOV		C,SDA_PIN			;get the ACK bit
			LCALL	NOP_5
			CLR		SCL_PIN				;ACK bit received in 9th clock pulse
			MOV		ERROR_BIT,C			;get the ACK bit
			RET


RECEIVE_BYTE:
			SETB	SDA_PIN				
			MOV		R3,#8				;since 1 byte is to be transferred
LOOP002:	MOV		C,SDA_PIN			;receives 1 bit from slave
			RLC		A					;since msb comes in first
			LCALL	NOP_5
			SETB	SCL_PIN
			LCALL	NOP_5
			CLR		SCL_PIN				;high-to-low clock pulse gives a falling edge(required from transfer in i2c)
			LCALL	NOP_5
			DJNZ	R3,LOOP002
			MOV		DATA_BYTE,A			;save the data byte received
			LCALL	NACK
			;SETB	SDA_PIN				;send NACK bit from master to slave
			RET
			
NACK:		SETB	SDA_PIN
			JNB		SDA_PIN,NACK
			SETB	SCL_PIN
			LCALL	NOP_5
			CLR		SCL_PIN
			RET
ACK:		CLR		SDA_PIN
			JB		SDA_PIN,NACK
			SETB	SCL_PIN
			LCALL	NOP_5
			CLR		SCL_PIN
			RET			

TRANSMISSION_FAILED:
			MOV		DPTR,#FAIL_MESSAGE
LOOP003:	CLR		A
			MOVC	A,@ A+DPTR
			ACALL	SERIAL_TRANSFER
			INC		DPTR
			CJNE	A,#0,LOOP003
			RET

NOP_5:		NOP
			NOP
			NOP
			NOP
			NOP
			RET
			
SERIAL_TRANSFER:
			CLR		TI
			MOV		SBUF,A
LOOP004:	JNB		TI,LOOP004
			CLR		TI
			RET

INCREMENT_ADDRESS:								;Address range from 0000H to 1FFFH
			MOV		A,SECOND_WORD_ADDR
			ADD		A,#1
			MOV		SECOND_WORD_ADDR,A
			JC		LOOP005
			RET
LOOP005:	MOV		A,FIRST_WORD_ADDR
			ADDC	A,#0
			CJNE	A,#20H,LOOP006
			MOV		FIRST_WORD_ADDR,#00H
			RET
LOOP006:	MOV		FIRST_WORD_ADDR,A
			RET

DELAY:		
			MOV		R1,#255
LOOP008:	MOV		R2,#255
LOOP009:	DJNZ	R2,LOOP009
			DJNZ	R1,LOOP008
			RET
FAIL_MESSAGE:	DB	"TRANSMISSION FAILED!",0
			END
	;funcgen.asm: FOR A DUMMY FUNCTION GENERATOR
	;MICROCONTROLLER:		AT89S51
	;DDS:				AD9833
	;WAVEFORM SELECTION:		PUSH BUTTON SWITCHES
	;FREQUENCY ADJUSTMENT SPEED 
	;SELECTION:			SPST TOGGLE SWITCHES
	;FREQUENCY ADJUSTMENT:		ROTARY ENCODER

	;INPUT FROM ROTARY ENCODER
	.EQU	ROTA, 90H
	.EQU	ROTB, 91H
	;INPUT FROM SPST TOGGLE SWITCHES
	.EQU	SW1, 92H
	.EQU	SW2, 93H
	.EQU	SW3, 94H
	.EQU	SW4, 95H
	;INPUT FROM PUSH BOTTON SWITCHES
	.EQU	SWSIN, 0A0H
	.EQU	SWSQU, 0A1H
	.EQU	SWTRI, 0A2H
	;OUTPUT TO AD9833
	.EQU	SCLK, 0A3H
	.EQU	SDATA, 0A4H
	.EQU	FSYNC, 0A5H

	LJMP	MAIN
	.ORG	0BH
	LJMP	TIMER0
	.ORG	1BH
	LJMP	TIMER1
	
	.ORG	30H
MAIN:	MOV	R7, #0
	CLR	00H
	CLR	01H
	CLR	02H		;NOT TO SEND FREQUENCY
	;BIT 03H, 04H NEED NOT TO BE INITIALIZED
	CLR	05H		;NOT TO SEND WAVEFORM
	MOV	30H, #13	;1KHZ MOST SIGNIFFICANT BIT #
	MOV	31H, #11110001B	;SEQUENCE TO PRESENT 1KHZ
	MOV	32H, #00101001B
	MOV	33H, #00000000B
	MOV	34H, #0		;SINEWAVE FIRST
	MOV	40H, #00000001B	;HELP CALCULATING
	MOV	41H, #00000010B
	MOV	42H, #00000100B
	MOV	43H, #00001000B
	MOV	44H, #00010000B
	MOV	45H, #00100000B
	MOV	46H, #01000000B
	MOV	47H, #10000000B
	MOV	TMOD, #11H	;TIMER1 MODE1, TIMER0 MODE1
	MOV	IE, #8AH	;TIMER1, TIMER0 INTERRUPT ENABLE
	MOV	TL0, #0FDH	;ABOUT 50MS TO OVERFLOW
	MOV	TH0, #4BH
	MOV	TL1, #1AH	;ABOUT 250US TO OVERFLOW
	MOV	TH1, #0FFH
	MOV	R4, #21H	;AD9833 INITIALIZATION
	MOV	R3, #00H
	ACALL	SENDW
	MOV	R4, #01101001B
	MOV	R3, #11110001B
	ACALL	SENDW
	MOV	R4, #40H
	MOV	R3, #00H
	ACALL	SENDW
	MOV	R4, #0C0H
	MOV	R3, #00H
	ACALL	SENDW
	MOV	R4, #20H
	MOV	R3, #00H
	ACALL	SENDW
	SETB	TR0
LOOP:	ACALL	GETF
	ACALL	GETW
	SJMP	LOOP

	;TIMER0: EVERY 50MS, SEND AD9833 NEW FREQUENCY AND 
	;	 WAVEFORM IF NEEDED AND PERMITTED
	;WHEN JUMP HERE, TF0 IS CLEARED
TIMER0:	JNB	02H, CHANGEW
CHANGEF:PUSH	0E0H		;SAVE A
	MOV	A, 32H
	ANL	A, #00111111B
	ORL	A, #01000000B
	MOV	R4, A
	MOV	R3, 31H
	ACALL	SENDW
	MOV	R4, #40H
	MOV	A, 33H
	RL	A
	RL	A
	ANL	A, #11111100B
	MOV	R3, A
	MOV	A, 32H
	RL	A
	RL	A
	ANL	A, #00000011B
	ORL	A, R3
	MOV	R3, A
	ACALL	SENDW
	POP	0E0H
	CLR	02H
CHANGEW:JNB	05H, RET3
	PUSH	0E0H
	MOV	A, 34H
	CJNE	A, #0, NOTSINW
SINW:	MOV	R3, #00000000B
	SJMP	CONT9
NOTSINW:MOV	A ,34H
	CJNE	A, #1, TRIW
SQUW:	MOV	R3, #00101000B
	SJMP	CONT9
TRIW:	MOV	R3, #00000010B
CONT9:	MOV	R4, #20H
	ACALL	SENDW
	POP	0E0H
	CLR	05H
RET3:	MOV	TL0, #0FDH
	MOV	TH0, #4BH
	SETB	TR0
	RETI

	;TIMER1: SET BY GETF, CALLS CALCF, TOGETHER UPDATE 31H-33H
	;WHICH CONTAINS FRQUENCY INFO
	;WHEN JUMP HERE, TF1 IS CLEARED
TIMER1:	CLR	TR1
	MOV	TL1, #1AH
	MOV	TH1, #0FFH	
	CLR	01H
	JB	00H, CONT4
	SETB	00H
	RETI
CONT4:	CJNE	R7, #1, CHECK_B
CHECK_A:JB	ROTA, CONT5
	MOV	R7, #2
	RETI	
CONT5:	CLR	03H
	ACALL	CALCF
	SJMP	FI_RET2
CHECK_B:JB	ROTB,CONT6
	MOV	R7, #1
	RETI
CONT6:	SETB	03H
	ACALL	CALCF
FI_RET2:MOV	R7, #0
	CLR	00H
	RETI

	;GETF: GET FREQUENCY CHANGE INFO
GETF:	JNB	01H, CONT0
	RET
CONT0:	CJNE	R7, #0, ROT_X
	JB	ROTA, CONT1
	MOV	R7, #1
	RET
CONT1:	JB	ROTB, RET0
	MOV	R7, #2
RET0:	RET
ROT_X:	CJNE	R7, #1, ROT_B
ROT_A:	JB	00H, CONT2
	JB	ROTB, RET1
	SJMP	TR_RET1
CONT2:	JNB	ROTB, RET1
	SJMP	TR_RET1
ROT_B:	JB	00H, CONT3
	JB	ROTA, RET1
	SJMP	TR_RET1
CONT3:	JNB	ROTA, RET1
TR_RET1:SETB	TR1
	SETB	01H
RET1:	RET

	;CALCF: CALCULATE NEW FREQUENCY
CALCF:	PUSH	0E0H
	MOV	A, 90H		;P1
	RR	A
	RR	A
	RRC	A
	JNC	CALC1
CALC0:	JB	03H, MUL2
DIV2:	CLR	02H
	CLR	C
	MOV	A, 33H
	RRC	A
	MOV	33H, A
	MOV	A, 32H
	RRC	A
	MOV	32H, A
	MOV	A, 31H
	RRC	A
	MOV	31H, A
	SJMP	CHECKMIN
MUL2:	CLR	02H
	CLR	C
	MOV	A, 31H
	RLC	A
	MOV	31H, A
	MOV	A, 32H
	RLC	A
	MOV	32H, A
	MOV	A, 33H
	RLC	A
	MOV	33H, A
	SJMP	CHECKMAX
CALC1:	MOV	R5, A		;SAVE (MODIFIED) P1
	MOV	C, 03H
	MOV	A, 30H
	ADDC	A, #0
	MOV	R6, A
SUB5:	MOV	A, R6
	CLR	C
	SUBB	A, #5
	MOV	R6, A
	RLC	A
	JNC	NEXT0
	MOV	R6, #0
	SJMP	CALC2
NEXT0:	MOV	A, R5
	RRC	A
	MOV	R5, A
	JNC	SUB5
CALC2:	MOV	A, R6
	ANL	A, #00000111B
	ADD	A, #40H
	MOV	R1, A
	MOV	A, R6
	RR	A
	RR	A
	RR	A
	ANL	A, #00000011B
	MOV	R5, A
	ADD	A, #31H
	MOV	R0, A
	CLR	02H
	MOV	A, @R0
	JB	03H, PLUS0
MINUS0:	CLR	C
	SUBB	A, @R1
	SJMP	NEXT1
PLUS0:	ADD	A, @R1
NEXT1:	MOV	@R0, A
LOOP0:	MOV	04H, C		;CJNE IS MODIFYING CARRY
	CJNE	R5, #2, NEXT2
	JB	03H, CHECKMAX
	SJMP	CHECKMIN
NEXT2:	INC	R0		;NO FLAGS ARE AFFECTED
	MOV	A, @R0
	MOV	C, 04H
	JB	03H, PLUS1
MINUS1:	SUBB	A, #0
	SJMP	NEXT3
PLUS1:	ADDC	A, #0
NEXT3:	MOV	@R0, A
	INC	R5
	SJMP	LOOP0
CHECKMIN:MOV	A, 33H
	ORL	A, 32H
	ORL	A, 31H
	JNZ	FINISH0
	MOV	31H, #1
	SJMP	FINISH0
CHECKMAX:MOV	A, 33H
	ANL	A, #11100000B
	JZ	FINISH0
	MOV	33H, #00011111B
	MOV	32H, #255
	MOV	31H, #255
FINISH0:SETB	02H
	MOV	R5, #23
	MOV	R1, #33H
	MOV	R0, #3
LOOP2:	MOV	A, @R1
	MOV	R6, #8
LOOP1:	RLC	A
	JC	FINISH1
	DEC	R5
	DJNZ	R6, LOOP1
	DEC	R1
	DJNZ	R0, LOOP2
FINISH1:MOV	30H, R5		;NEW MOST SIGNIFICANT BIT #
	POP	0E0H
	RET

	;GETW: GET WAVEFORM INFO
GETW:	JNB	SWSIN, CONT7
	MOV	A, 34H
	CJNE	A, #0, CHG0
	RET
CHG0:	MOV	34H, #0
	SJMP	RET5
CONT7:	JNB	SWSQU, CONT8
	MOV	A, 34H
	CJNE	A, #1, CHG1
	RET
CHG1:	MOV	34H, #1
	SJMP	RET5
CONT8:	JNB	SWTRI, RET4
	MOV	A, 34H
	CJNE	A, #2, CHG2
	RET
CHG2:	MOV	34H, #2
RET5:	SETB	05H
RET4:	RET

	;SENDW: SEND A 16-BIT WORD TO AD9833
 	;THE WORD IS IN R4R3, R4.7 SHOULD FIRST BE SENT
SENDW:	CLR	FSYNC
	MOV	A, R4
	MOV	R2, #8
SHIFT1:	RLC	A
	MOV	SDATA, C
	CLR	SCLK
	SETB	SCLK
	DJNZ	R2, SHIFT1
	MOV	A, R3
	MOV	R2, #8
SHIFT2:	RLC	A
	MOV	SDATA, C
	CLR	SCLK
	SETB	SCLK
	DJNZ	R2, SHIFT2
	SETB	FSYNC
	RET

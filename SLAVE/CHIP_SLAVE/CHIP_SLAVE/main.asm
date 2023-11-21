;
; CHIP_SLAVE.asm
;
; Created: 11/16/2023 15:45:50 AM
; Replace with your application code
.ORG 0	; START THE PROGRAM AT MEMORY ADDRESS 0
.EQU SIGNAL = 0
.EQU PIN_SS = 4
.EQU PIN_MOSI = 5
.EQU PIN_MISO = 6
.EQU PIN_SCK = 7
.EQU SPI_DDR = DDRB
.EQU SPI_PORT = PORTB
.EQU SPI_PIN = PINB
.EQU KEY_PORT = PORTD ; KEY DATA PORT
.EQU KEY_PIN = PIND ; KEY DATA PIN
.EQU KEY_DDR = DDRD ; KEY DATA DDR
.EQU REQ = 1		; DEFINE GENERAL PURPOSE REGISTERS
.DEF TEMP = R16
.DEF DATA_TEMP = R17

;DEFINE GENERAL PURPOSE REGISTERS

MAIN:
		CALL INIT_PORT ; CALL INIT_PORT SUBROUTINE
		CALL INIT_SSPI

LOOP:
		SBIC SPI_PIN, REQ	; CHECK IF REQ BIT IS CLEAR IN SPI_IN
		RJMP LOOP	
		SBI SPI_PORT, SIGNAL 
		RCALL SCANKEY
		;CPI DATA_TEMP, 16
		;BREQ PASS
		RCALL DATA_CONVERT

;PASS:
		RCALL SSPI_RECEIVE
		RJMP LOOP

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_PORT:
		LDI TEMP, (1 << PIN_MISO) | (1 << SIGNAL); LOAD IMMEDIATE VALUE INTO TEMP, CONFIGURING PIN_MISO AND SIGNAL AS OUTPUT
		OUT SPI_DDR, TEMP
		LDI TEMP, 0x0F
		OUT KEY_DDR, TEMP ; SET PC0-3 OUTPUT COLUMN, PC4-7 INPUT ROW 
		LDI TEMP, 0xF0
		OUT KEY_PORT, TEMP ; PULL-UP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
INIT_SSPI:
		LDI TEMP, (1 << SPE0)
		OUT SPCR0, TEMP
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SSPI_RECEIVE:
		OUT SPDR0, DATA_TEMP ; STORE KEY VALUE IN SLAVE
		CBI SPI_PORT, SIGNAL 

SSPI_WAIT_RECEIVE:
		IN TEMP, SPSR0	 ; INPUT VALUE OF SPSRO REGISTER INTO TEMP
		SBRS TEMP, SPIF0 ; WAIT FOR RECEPTION FROM MASTER
		RJMP SSPI_WAIT_RECEIVE
		SBI SPI_PORT, SIGNAL
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SCANKEY:
		LDI R20, 0x0F
		OUT KEY_PORT, R20
		LDI R22, 0b11110111 ; LOAD VALUE 0b11110111 INTO R22
		LDI R23, 0
		LDI R24, 3

KEYPAD_SCAN_LOOP:
		OUT KEY_PORT, R22
		CALL DELAY_10ms
		SBIC KEY_PIN, 4
		RJMP KEYPAD_SCAN_CHECK_COL_2
		RJMP KEYPAD_SCAN_FOUND

KEYPAD_SCAN_CHECK_COL_2:
		SBIC KEY_PIN, 5
		RJMP KEYPAD_SCAN_CHECK_COL_3
		LDI R23, 1
		RJMP KEYPAD_SCAN_FOUND

KEYPAD_SCAN_CHECK_COL_3:
		SBIC KEY_PIN, 6
		RJMP KEYPAD_SCAN_CHECK_COL_4
		LDI R23, 2
		RJMP KEYPAD_SCAN_FOUND

KEYPAD_SCAN_CHECK_COL_4:
		SBIC KEY_PIN, 7
		RJMP KEYPAD_SCAN_NEXT_ROW
		LDI R23, 3
		RJMP KEYPAD_SCAN_FOUND

KEYPAD_SCAN_NEXT_ROW:
		CPI R24, 0
		BREQ KEYPAD_SCAN_NOT_FOUND
		ROR R22
		DEC R24
		RJMP KEYPAD_SCAN_LOOP

KEYPAD_SCAN_FOUND:
		LSL R23
		LSL R23
		ADD R23, R24 ; KEYPAD VALUE IN R23
		MOV DATA_TEMP, R23
		RET

KEYPAD_SCAN_NOT_FOUND:
		LDI DATA_TEMP, 0xFF
		RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DATA_CONVERT:
		LDI TEMP, HIGH(ARRAY << 1)
		MOV ZH, TEMP
		LDI TEMP, LOW(ARRAY << 1)
		MOV ZL, TEMP
		ADD ZL, DATA_TEMP
		LPM DATA_TEMP, Z
		RET

ARRAY:
.DB '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 0xFF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
DELAY_10ms:
		LDI TEMP, 0b00001010 ; CTC MODE, CLK/8
		STS TCCR1B, TEMP
		LDI TEMP, 0x27		 ; LOAD IMMEDIATE VALUE 0x27 INTO TEMP 
		STS OCR1AH, TEMP	 ; STORE IN 0CR1AH
		LDI TEMP, 0x10
		STS OCR1AL, TEMP
		CLR TEMP
		STS TCNT1H, TEMP
		STS TCNT1L, TEMP

DELAY10ms_LOOP:
		SBIS TIFR1, OCF1A
		RJMP DELAY10ms_LOOP 
		SBI TIFR1, OCF1A ; RESET TIMER1
		CLR TEMP
		STS TCCR1A, TEMP
		STS TCCR1B, TEMP
		RET



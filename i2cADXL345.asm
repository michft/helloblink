;
; i2cADXL345.asm
;
; LED blinking through ADXL345 accelerometer input.
;
;
; copyright (CC BY-NC 3.0)
; http://creativecommons.org/licenses/by-nc/3.0/
;
; Version           : 0.1
; Date		    : 20120603
; Author	    : Michael Tomkins
; Target MCU        : ATTiny13A
;

;**** Includes ****

; You can get the tn13def.inc from http://www.attiny.com/software/AVR000.zip
; or http://www.atmel.com/products/microcontrollers/avr/tinyAVR.aspx

.include "tn13def.inc"			; My syntax fixed version.

; i2c library from
; http://www.cs.washington.edu/education/courses/cse466/00au/Projects/LakeMan/adv/datasheets/i2c_ex.asm
;.include "i2c_ex.S"

.include "libi2c.S"			; My syntax fixed version, changed i2c delay length (48 cycles)


;**** Global I2C Constants ****

.equ	SCLP	, 4			; SCL Pin number (port D)
.equ	SDAP	, 3			; SDA Pin number (port D)

RESET:
        ldi     temp, 0x38
	rcall 	longDelay

        sbi	DDRB, 0
        sbi	PORTB, 0
        sbi	DDRB, 2
        sbi	PORTB, 2

	sbi     PORTB, 1
	rcall	i2c_init		; initialize I2C interface
main:

	ldi	r18, 0x3a		; Set device address and write
	ldi	r20, i2cwr

	rcall	i2c_start		; Send start condition and address

	ldi	r17, 0x2d		; Write word address (0x0
	rcall	i2c_do_transfer		; Execute transfer

	ldi	r17, 8			; Set write data to 00001000
	rcall	i2c_do_transfer		; Execute transfer


        rcall   i2c_stop
	ldi     r18, 0x3a       	; Set device address and write
        ldi     r20, i2cwr
	rcall   i2c_start


	ldi	r17, 0x32		; Write word address
	rcall	i2c_do_transfer		; Execute transfer

        rcall   i2c_stop

	ldi	r18, 0x3b		; Set device address and read
	ldi	r20, i2crd
	rcall	i2c_rep_start		; Send repeated start condition and address

	sec				; Set no acknowledge (read is followed by a stop condition)
	rcall	i2c_do_transfer		; Execute transfer (read)

	rcall	i2c_stop		; Send stop condition - releases bus

	cbi	PORTB, 0
	cbi	PORTB, 1
	cbi	PORTB, 2
	sbrc	r17, 7
	sbi	PORTB, 2
	sbrc	r17, 6
	sbi	PORTB, 1
	sbrc	r17, 5
	sbi	PORTB, 0

	rjmp	main			; Loop forewer

;**** End of File ****



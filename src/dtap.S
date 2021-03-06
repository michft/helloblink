;
; dtap.asm
;
; LED blinking through ADXL345 tap/dtap interrupts.
;
;
; copyright (CC BY-NC 3.0)
; http://creativecommons.org/licenses/by-nc/3.0/
;
; Version           : 0.1
; Date		    : 20120613
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

.equ	SCLP,	4			; SCL Pin number (port B)
.equ	SDAP,	3			; SDA Pin number (port B)

; below make use of "reserved" I/O registers, may break non-attiny13a.
;.equ	T1,	0x01
;.equ	T2,	0x02
;.equ	temp,	0x19
;.equ	address,0x1a
;.equ	value,	0x1b

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; write address value
;
writei2c:
        ldi     r18, 0x3a               ; Set device address and write
        ldi     r20, i2cwr
        rcall   i2c_start               ; Send start condition and address
        mov     r17, r29                ; Write word address
        rcall   i2c_do_transfer         ; Execute transfer
        mov     r17, r30
        rcall   i2c_do_transfer         ; Execute transfer
        rcall   i2c_stop
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read address value, placed in r17
;
readi2c:
        rcall   i2c_stop
        ldi     r18, 0x3a               ; Set device address and write
        ldi     r20, i2cwr
        rcall   i2c_start
        mov     r17, r29            ; Write word address
        rcall   i2c_do_transfer         ; Execute transfer
        rcall   i2c_stop
        ldi     r18, 0x3b               ; Set device address and read
        ldi     r20, i2crd
        rcall   i2c_rep_start           ; Send repeated start condition and address
        sec                             ; Set no acknowledge (read is followed by a stop condition)
        rcall   i2c_do_transfer         ; Execute transfer (read)
        rcall   i2c_stop                ; Send stop condition - releases bus
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; read address value, placed in r17
; (~590000 cycles times x-1)

delayx: dec   r1
        brne  delayx
        dec   r2
        brne  delayx
        dec   r31
        brne  delayx
	ret


RESET:
        sbi	PORTB, 0
	sbi     PORTB, 1
        sbi	PORTB, 2
	rcall	i2c_init		; initialize I2C interface

; Tap evenst are around 5ms duration with 20ms gap

; setup Register 0x1D THRESH_TAP The THRESH_TAP register is eight bits and holds the threshold value for tap interrupts. The data format is unsigned, so the magnitude of the tap event is compared with the value in THRESH_TAP. The scale factor is 62.5 mg/LSB (that is, 0xFF = +16 g). A value of 0 may result in undesirable behavior if tap/ double tap interrupts are enabled.

	ldi 	r29, 0x1d
	ldi	r30, 4
	rcall	writei2c
        cbi     PORTB, 0
        cbi     PORTB, 1
        cbi     PORTB, 2


; setup Register 0x21 DUR (Read/Write) The DUR register is eight bits and contains an unsigned time value representing the maximum time that an event must be above the THRESH_TAP threshold to qualify as a tap event. The scale factor is 625 μs/LSB. A value of 0 disables the tap/double tap functions.
	ldi 	r29, 0x21
	ldi	r30, 20
	rcall	writei2c
        sbi     PORTB, 0
        cbi     PORTB, 1
        cbi     PORTB, 2


; setup Register 0x22 Latent (Read/Write) The latent register is eight bits and contains an unsigned time value representing the wait time from the detection of a tap event to the start of the time window (defined by the window register) during which a possible second tap event can be detected. The scale factor is 1.25 ms/LSB. A value of 0 disables the double tap function.

	ldi 	r29, 0x22
	ldi	r30, 4
	rcall	writei2c
        cbi     PORTB, 0
        sbi     PORTB, 1
        cbi     PORTB, 2

; setup Register 0x23 Window (Read/Write) The window register is eight bits and contains an unsigned time value representing the amount of time after the expiration of the latency time (determined by the latent register) during which a second valid tap can begin. The scale factor is 1.25 ms/LSB. A value of 0 disables the double tap function.

	ldi 	r29, 0x23
	ldi	r30, 24
	rcall	writei2c
        sbi     PORTB, 0
        sbi     PORTB, 1
        cbi     PORTB, 2

; setup Register 0x24 THRESH_ACT (Read/Write) The THRESH_ACT register is eight bits and holds the threshold value for detecting activity. The data format is unsigned, so the magnitude of the activity event is compared with the value in the THRESH_ACT register. The scale factor is 62.5 mg/LSB. A value of 0 may result in undesirable behavior if the activity interrupt is enabled.

	ldi 	r29, 0x24
	ldi	r30, 2
	rcall	writei2c
        cbi     PORTB, 0
        cbi     PORTB, 1
        sbi     PORTB, 2

; setup Register 0x25 THRESH_INACT (Read/Write) The THRESH_INACT register is eight bits and holds the threshold value for detecting inactivity. The data format is unsigned, so the magnitude of the inactivity event is compared with the value in the THRESH_INACT register. The scale factor is 62.5 mg/LSB. A value of 0 mg may result in undesirable behavior if the inactivity interrupt is enabled.

	ldi 	r29, 0x25
	ldi	r30, 1
	rcall	writei2c
        sbi     PORTB, 2

; setup Register 0x26 TIME_INACT (Read/Write) The TIME_INACT register is eight bits and contains an unsigned time value representing the amount of time that acceleration must be less than the value in the THRESH_INACT register for inactivity to be declared. The scale factor is 1 sec/LSB. Unlike the other interrupt functions, which use unfiltered data (see the Threshold section), the inactivity function uses filtered output data. At least one output sample must be generated for the inactivity interrupt to be triggered. This results in the function appearing unresponsive if the TIME_INACT register is set to a value less than the time constant of the output data rate. A value of 0 results in an interrupt when the output data is less than the value in the THRESH_INACT register.

	ldi 	r29, 0x26
	ldi	r30, 1
	rcall	writei2c
        sbi     PORTB, 0
        cbi     PORTB, 1
        sbi     PORTB, 2

; setup Register 0x27 ACT_INACT_CTL (Read/Write)
; 	D7	 	D6 		D5		D4
;	ACT ac/dc	ACT_X enable	ACT_Y enable	ACT_Z enable
;	D3		D2		D1		D0
;	INACT ac/dc	INACT_X enable	INACT_Y enable	INACT_Z enable
;ACT AC/DC and INACT AC/DC Bits
; A setting of 0 selects dc-coupled operation, and a setting of 1 enables ac-coupled operation. In dc-coupled operation, the current acceleration magnitude is compared directly with THRESH_ACT and THRESH_INACT to determine whether activity or inactivity is detected.
; In ac-coupled operation for activity detection, the acceleration value at the start of activity detection is taken as a reference value. New samples of acceleration are then compared to this reference value, and if the magnitude of the difference exceeds the THRESH_ACT value, the device triggers an activity interrupt.
; Similarly, in ac-coupled operation for inactivity detection, a reference value is used for comparison and is updated whenever the device exceeds the inactivity threshold. After the reference value is selected, the device compares the magnitude of the difference between the reference value and the current acceleration with THRESH_INACT. If the difference is less than the value in THRESH_INACT for the time in TIME_INACT, the device is considered inactive and the inactivity interrupt is triggered.
; ACT_x Enable Bits and INACT_x Enable Bits
; A setting of 1 enables x-, y-, or z-axis participation in detecting activity or inactivity. A setting of 0 excludes the selected axis from participation. If all axes are excluded, the function is disabled.

	ldi 	r29, 0x27
	ldi	r30, 0xff
	rcall	writei2c
        cbi     PORTB, 0
        sbi     PORTB, 1
        sbi     PORTB, 2

	ldi 	r29, 0x2a
	ldi	r30, 0x07
	rcall	writei2c
        sbi     PORTB, 0
        cbi     PORTB, 1
        cbi     PORTB, 2

; Register 0x2E INT_ENABLE (Read/Write)
;D7		D6		D5		D4
;DATA_READY	SINGLE_TAP	DOUBLE_TAP	Activity
;D3		D2		D1		D0
;Inactivity	FREE_FALL	Watermark	Overrun

; setup
; setup
	ldi 	r29, 0x2e
	ldi	r30, 0x78
	rcall	writei2c
        cbi     PORTB, 0
        sbi     PORTB, 1
        cbi     PORTB, 2

	ldi 	r28,	0x1a

main:

; check "on" flag

; check activity
; when inactive
; ajust Register 0x1E, Register 0x1F, Register 0x20 OFSX, OFSY, OFSZ (Read/Write)
; The OFSX, OFSY, and OFSZ registers are each eight bits and offer user-set offset
; adjustments in twos complement format with a scale factor of 15.6 mg/LSB (that is, 0x7F = +2 g).


;D7		D6		D5		D4
;DATA_READY	SINGLE_TAP	DOUBLE_TAP	Activity
;D3		D2		D1		D0
;Inactivity	FREE_FALL	Watermark	Overrun

	ldi 	r29, 0x30
	rcall	readi2c
        cbi     PORTB, 0
        cbi     PORTB, 1
        cbi     PORTB, 2
	ldi	r31, 0x20
	rcall	delayx

        sbrc    r28, 2
        sbi     PORTB, 2
        sbrc    r28, 1
        sbi     PORTB, 1
        sbrc    r28, 0
        sbi     PORTB, 0

	ldi	r31, 0x20
	rcall	delayx

	mov 	r29, r28
	rcall	readi2c
        cbi     PORTB, 0
        cbi     PORTB, 1
        cbi     PORTB, 2
	ldi	r31, 0x20
	rcall	delayx


;        sbi     PORTB, 2
        sbrc    r17, 7
        sbi     PORTB, 1
        sbrc    r17, 6
        sbi     PORTB, 0


	ldi	r31, 0x20
	rcall	delayx

        cbi     PORTB, 0
        cbi     PORTB, 1
        cbi     PORTB, 2

        sbrc    r17, 5
        sbi     PORTB, 2
        sbrc    r17, 4
        sbi     PORTB, 1
        sbrc    r17, 3
        sbi     PORTB, 0

	ldi	r31, 0x20
	rcall	delayx

        cbi     PORTB, 0
        cbi     PORTB, 1
        cbi     PORTB, 2

        sbrc    r17, 2
        sbi     PORTB, 2
        sbrc    r17, 1
        sbi     PORTB, 1
        sbrc    r17, 0
        sbi     PORTB, 0

	ldi	r31, 0x20
	rcall	delayx
        sbi     PORTB, 0
        sbi     PORTB, 1
        sbi     PORTB, 2

	inc 	r28
	rjmp	main			; Loop forewer


;**** End of File ****



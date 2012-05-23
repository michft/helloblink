;********************************************************************
;* LED flasher: LED will flash with a X on/off ratio at PD6
;*
;* NOTE: delay depends in the value of X, 1 is fast, 255 is slow
;*
;* No copyright ©1998 RESÆ * FREEWARE *
;*
;* NOTE: Connect a low current LED with a 1k resistor in serie from
;*	 Vdd to pin 11 of the MCU. (Or a normal LED with a 330ohm)
;*
;* RESÆ can be reached by email: at90s2313@europe.com
;* or visit the website: http://www.attiny.com
;*
;* Original Version  :1.0
;* Date		     :12/26/98
;* Author	     :Rob's ElectroSoft
;* Target MCU        :AT90S1200-12PI@4MHz
;*
;* copyright (CC BY-NC 3.0)
;* http://creativecommons.org/licenses/by-nc/3.0/
;*
;* Version           : 0.1
;* Date		     : 20120523
;* Author	     : Michael Tomkins
;* Target MCU        : ATTINY13
;********************************************************************


; You can get the tn13def.inc from http://www.attiny.com/software/AVR000.zip
; or http://www.atmel.com/products/microcontrollers/avr/tinyAVR.aspx

.include "tn13def.inc"

	rjmp	RESET		;reset handle


;* Long delay

;* Register variables

	.equ  T1, 0x01
	.equ  T2, 0x02
	.equ  temp, 0x19

;* Code
longDelay:
	clr   T1		;T1 used as delay 2nd count
	clr   T2		;T2 used as delay 3d count
delay_1:
	dec   T2
	brne  delay_1
	dec   T1
	brne  delay_1
	dec   temp		;temp must be preset as
	brne  delay_1		; delay master count
	ret


;* Resets the data direction register D

;* Defines

	.equ  led, 0		;LED at PB0

;* Code

RESET:
  .equ SREG, 0x3f
  .equ TIMSK0, 0x39
  .equ TCCR0B, 0x33
  .equ PORTB,0x18
  .equ DDRB ,0x17
  .equ PINB, 0x16

;* Main program

;* This part will let the LED go on and off by X

;* Register variables

	.equ  X, 5 	;enter delaytime X

flash:	sbi   PORTB, led	;LED on
	ldi   temp, X		;X sec delay
	rcall longDelay
	cbi   PORTB, led	;LED off
	ldi   temp, X		;X sec delay
	rcall longDelay
	rjmp  flash		;another run

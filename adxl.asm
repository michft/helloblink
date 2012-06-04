;
; adxl.asm
;
; moving ears via attiny13A from adxl345 i2c input.
;
;
; copyright (CC BY-NC 3.0)
; http://creativecommons.org/licenses/by-nc/3.0/
;
; Version           : 0.1
; Date		    : 20120523
; Author	    : Michael Tomkins
; Target MCU        : ATTINY13
;

; You can get the tn13def.inc from http://www.attiny.com/software/AVR000.zip
; or http://www.atmel.com/products/microcontrollers/avr/tinyAVR.aspx

.include "tn13def.inc"

; i2c library from
; http://www.cs.washington.edu/education/courses/cse466/00au/Projects/LakeMan/adv/datasheets/i2c_ex.asm

.include "i2c_ex.S"

Referenced code from

; http://www.nickdademo.com/articles/avr/how-to-peter-fleurys-i2c-driver-and-the-avr-xmega
; http://www.jrobot.net/Download/AVRcam_tiny12.asm

Other Links

; http://mil.ufl.edu/5666/papers/IMDL_Report_Summer_03/koessick_max/Assembly%20Files/TWI/avr300_asm.htm
; http://homepage.hispeed.ch/peterfleury/avr-software.html
; http://www.attiny.com/software/AVR000.zip
; http://www.atmel.com/products/microcontrollers/avr/tinyAVR.aspx

.equ    SCLP    , 4                     ; SCL Pin number (port D)
.equ    SDAP    , 3                     ; SDA Pin number (port D)

.equ    b_dir   , 0                     ; transfer direction bit in r18

.equ    i2crd   , 1
.equ    i2cwr   , 0

;**** Global Register Variables ****

; did find/paste because syntax eluded me. mich
;.set   i2cdelay, r16                   ; Delay loop variable
;.set   i2cdata , r17                   ; I2C data transfer register
;.set   i2cadr  , r18                   ; I2C address and direction register
;.set   i2cstat , r19                   ; I2C bus status register


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
	dec   temp		; temp must be preset as
	brne  delay_1		; delay master count
	ret

;*************************************************************************
; http://www.nickdademo.com/articles/avr/how-to-peter-fleurys-i2c-driver-and-the-avr-xmega
; delay half period
; For I2C in normal mode (100kHz), use T/2 > 5us
; For I2C in fast mode (400kHz),   use T/2 > 1.3us
;*************************************************************************
;       .func main_delay
my_i2c_delay:             ; 3 cycles
; =============================
;    delay loop generator
;     3 cycles:
; -----------------------------
; delaying 41 cycles, 1 ldi, 3 cycles per loop, ret 4 cycles
          ldi  r16, 13  ; 1
WGLOOP:  dec  r16       ; 1
         brne WGLOOP    ; 1 false 2 true
         nop
         ret             ; 4 cycles

; =============================
;    ret                 ; 3 cycles
;        .endfunc        ; total 48 cyles = 5.0 microsec with 9.6 Mhz clock
                        ; since 10 cycles = 5.0 microsec with 2 Mhz clock 


RESET:

;* Main program

;* Register variables

	.equ  X, 5 	;enter delaytime X

main:	sbi   PORTB, led	;LED on
	cbi   PORTB, led1	;LED on
	sbi   PORTB, led2	;LED on
	ldi   temp, X		;X sec delay
	rcall longDelay
	cbi   PORTB, led	;LED off
	sbi   PORTB, led1	;LED off
	cbi   PORTB, led2	;LED off
	ldi   temp, X		;X sec delay
	rcall longDelay
	rjmp  blink		;another run




; get adxl values

; process values

; flip pins



;
; adxl.asm
;
; moving ears via attiny13A from adxl345 i2c input.
; written for 'as' GNU assembler version 2.22
;
;
; copyright (CC BY-NC 3.0)
; http://creativecommons.org/licenses/by-nc/3.0/
;
; Version           : 0.1
; Date		    : 20120613
; Author	    : Michael Tomkins
; Target MCU        : ATTINY13
;

; You can get the tn13def.inc from http://www.attiny.com/software/AVR000.zip
; or http://www.atmel.com/products/microcontrollers/avr/tinyAVR.aspx

.NOLIST
.include "tn13def.inc"

; i2c library from
; http://www.cs.washington.edu/education/courses/cse466/00au/Projects/LakeMan/adv/datasheets/i2c_ex.asm

;.include "i2c_ex.S"
.include "libi2c.S"	; My syntax fixed version

; http://www.instructables.com/id/Animatronic-Cat-Ears/

; .include "kears_equ.S"
.LIST



; NOTE, output port mapping to motors is:
; 0 bottom right
; 1 bottom left
; 2 up left
; 3 up right



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; set up aux timer and transition state
.macro aux_trans x
  cli
  ldi   r18, AUX_COUNTER_H
  mov   r13, r18
  ldi   r18, AUX_COUNTER_L
  mov   r12, r18
  ldi   r16, \x
  sei
.endm

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; test aux counter for expiration
.macro aux_n_exp skip_label  ; aux not expired, go to skip_label
  tst   r13
  brne  \skip_label
  tst   r12
  brne  \skip_label
.endm

;;;;;;;;;;;;;;;;;;;;;;
;;; set up aux counter
.macro set_aux_cnt
  cli
  ldi   r18, AUX_COUNTER_H
  mov   r13, r18
  ldi   r18, AUX_COUNTER_L
  mov   r12, r18
  sei
.endm

.macro  set_ear_state a, b, c, d
  cli
  ldi   r25, \a
  ldi   r26, \b
  ldi   r27, \c
  ldi   r28, \d
  sei
.endm

.macro moto_func state, ppos
  cp    r24, \state
  brne  moto_func_end_macro_\state
  cbi   PORTB, \ppos
  moto_func_end_macro_\state:
.endm


.org 0x00
reset:
rjmp main        ; reset
rjmp defaultInt  ; ext_int0
rjmp defaultInt  ; pcint0
rjmp tim0_ovf    ; tim0_ovf
rjmp defaultInt  ; ee_rdy
rjmp defaultInt  ; ana_comp
rjmp defaultInt  ; tim0_compa
rjmp defaultInt  ; tim0_compb
rjmp defaultInt  ; watchdog
rjmp defaultInt  ; adc

defaultInt:
reti

;;;;; TIMER0 ON OVERFLOW
tim0_ovf:

  ;;;;;;;;;;;;;;
  ;;; save state
  ;;; 3
    push  r17
    in    r17, SREG
    push  r17


  ;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; incrememnt counter
  ;;; 3
    inc   r24
    brne  skip_hcounter_incr
    inc   r23
  skip_hcounter_incr:


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;; reset counter and set portb high
  ;;; 9
    cpi   r23, HPW
    brne  skip_set_moto
    cpi   r24, LPW
    brne  skip_set_moto
    ldi   r23, 0
    ldi   r24, 0

    in    r17, PORTB
    ori   r17, 0x0f
    out   PORTB, r17

  skip_set_moto:

  ;;;;;;;;;;;;;;;;;;;;;
  ;;;;; motor functions
  ;;; 6 + 44
    tst  r23
    brne moto_func_end

    moto_func r25, 0
    moto_func r26, 1
    moto_func r27, 2
    moto_func r28, 6

  moto_func_end:


  ;;;;;;;;;;;;;;;;;
  ;;;;; aux counter
  ;;; 4-6
    tst   r12
    brne  aux_counter_dec_l
    tst   r13
    breq   aux_counter_end
    dec   r13
  aux_counter_dec_l:
    dec   r12
  aux_counter_end:


  ;;;;;;;;;;;
  ;;; restore
  ;;; 3
    pop   r17
    out   SREG, r17
    pop   r17

reti



;;;;;;;;;;;;;;
;;;;
;;;;/* MAIN */
;;;;
;;;;;;;;;;;;;;
main:
; Referenced code from

; http://www.nickdademo.com/articles/avr/how-to-peter-fleurys-i2c-driver-and-the-avr-xmega
; http://www.jrobot.net/Download/AVRcam_tiny12.asm

; Other Links

; http://mil.ufl.edu/5666/papers/IMDL_Report_Summer_03/koessick_max/Assembly%20Files/TWI/avr300_asm.htm
; http://homepage.hispeed.ch/peterfleury/avr-software.html
; http://www.attiny.com/software/AVR000.zip
; http://www.atmel.com/products/microcontrollers/avr/tinyAVR.aspx

.equ    SCLP    , 4                     ; SCL Pin number (port B)
.equ    SDAP    , 3                     ; SDA Pin number (port B)

.equ    b_dir   , 0                     ; transfer direction bit in r18

.equ    i2crd   , 1
.equ    i2cwr   , 0

;**** Global Register Variables ****

; did find/paste because syntax eluded me. mich
;.set   i2cdelay, r16                   ; Delay loop variable
;.set   i2cdata , r17                   ; I2C data transfer register
;.set   i2cadr  , r18                   ; I2C address and direction register
;.set   i2cstat , r19                   ; I2C bus status register





;*************************************************************************
; Modified code from
; http://www.nickdademo.com/articles/avr/how-to-peter-fleurys-i2c-driver-and-the-avr-xmega
;
; For I2C in normal mode (100kHz), use T/2 > 5us
; For I2C in fast mode (400kHz),   use T/2 > 1.3us
;*************************************************************************
;       .func main_delay
my_i2c_delay:             ; 3 cycles,
; =============================
;    delay loop generator
;     3 cycles:
; -----------------------------
; delaying 41 cycles, 1 ldi, 3 cycles per loop, ret 4 cycles
          ldi  r16, 13  ; 1
wg_loop:  dec  r16       ; 1
         brne wg_loop    ; 1 false | 2 true
         nop
         ret             ; 4 cycles

;    ret                 ; 3 cycles
;        .endfunc        ; total 48 cyles = 5.0 microsec with 9.6 Mhz clock
                         ; since 10 cycles = 5.0 microsec with 2 Mhz clock
; =============================


;***************************************************************************
;*
;* PROGRAM
;*      main - Test of I2C master implementation
;*
;* DESCRIPTION
;*      Initializes I2C interface and shows an example of using it.
;*
;***************************************************************************




       ; ldi     temp, 0x38
      ;  rcall   longDelay

  ;      sbi DDRB, 0
   ;     sbi PORTB, 0
    ;    sbi DDRB, 2
     ;   sbi PORTB, 2

      ;  sbi     PORTB, 1
        rcall   i2c_init                ; initialize I2C interface


  ;;;;;;;;;;;;;;;;
  ;;;;;; init

  ; PB0-PB3 set as output, rest as input
  ldi   r17, 0x08
  out   DDRB, r17

  ; no prescaling
  in    r17, TCCR0B
  andi  r17, 0xf8
  ori   r17, 1
  out   TCCR0B, r17

  ; enable timer interrupte
  in    r17, TIMSK0
  ori   r17, 2
  out   TIMSK0, r17

  ; initialize global variables
  eor   r8, r8

  eor   r20, r20
  eor   r21, r21

  eor   r22, r22
  eor   r10, r10
  eor   r11, r11

  eor   r23, r23
  eor   r24, r24

  eor   r15, r15
  eor   r13, r13
  eor   r12, r12

  ldi   r16, ears_START

  ldi   r19, EAR_STATE_IDLE
  set_ear_state PWM_POS_c, PWM_POS_2, PWM_POS_a, PWM_POS_4

  eor   r18, r18
  eor   r17, r17

  sei

read_accel:

        ldi     r18, 0x3a       ; Set device address and write
        ldi     r20, i2cwr

        rcall   i2c_start               ; Send start condition and address

        ldi     r17, 0x2d               ; Write word address (0x0
        rcall   i2c_do_transfer         ; Execute transfer

        ldi     r17, 8          ; Set write data to 00001000
        rcall   i2c_do_transfer         ; Execute transfer


        rcall   i2c_stop
        ldi     r18, 0x3a       ; Set device address and write
        ldi     r20, i2cwr
        rcall   i2c_start


        ldi     r17, 0x32               ; Write word address, interupt reg
        rcall   i2c_do_transfer         ; Execute transfer

        rcall   i2c_stop

        ldi     r18, 0x3b       ; Set device address and read
        ldi     r20, i2crd
        rcall   i2c_rep_start           ; Send repeated start condition and address

        sec                             ; Set no acknowledge (read is followed by a stop condition)
        rcall   i2c_do_transfer         ; Execute transfer (read)

        rcall   i2c_stop                ; Send stop condition - releases bus

        ldi   r19, EAR_STATE_IDLE
	sbrc    r17, 7
        ldi   r19, EAR_STATE_SURPRISE
	sbrc    r17, 7
        rjmp  ear_state_surprise


	sbrc    r17, 6
        ldi   r19, EAR_STATE_ANGRY
	sbrc    r17, 6
        rjmp  ear_state_angry

main_while:

;;;;;;;;;;;;;;;
;;;; ear states

  ldi   r31, pm_hi8(ear_state_jt)
  ldi   r30, pm_lo8(ear_state_jt)
  add   r30, r19
  adc   r31, r8
  ijmp

ear_state_jt:
  rjmp  ear_state_idle
  rjmp  ear_state_surprise
  rjmp  ear_state_angry
  rjmp  ear_state_distracted0
  rjmp  ear_state_distracted1
  rjmp  ear_state_distracted2
  rjmp  ear_state_distracted3


  ; back to idle
;  set_ear_state PWM_POS_c, PWM_POS_2, PWM_POS_4, PWM_POS_a

;;  rjmp  ear_state_end

ear_state_idle:
  set_ear_state PWM_POS_c, PWM_POS_2, PWM_POS_a, PWM_POS_4
  rjmp read_accel
  rjmp ear_state_end
ear_state_surprise:
  set_ear_state PWM_POS_c, PWM_POS_2, PWM_POS_d, PWM_POS_1
  rjmp ear_state_end
ear_state_angry:
  set_ear_state PWM_POS_2, PWM_POS_c, PWM_POS_4, PWM_POS_a
  rjmp ear_state_end
ear_state_distracted0:
  set_ear_state PWM_POS_c, PWM_POS_7, PWM_POS_4, PWM_POS_4
  rjmp ear_state_end
ear_state_distracted1:
  set_ear_state PWM_POS_c, PWM_POS_7, PWM_POS_a, PWM_POS_4
  rjmp ear_state_end
ear_state_distracted2:
  set_ear_state PWM_POS_c, PWM_POS_7, PWM_POS_4, PWM_POS_4
  rjmp ear_state_end
ear_state_distracted3:
 set_ear_state PWM_POS_c, PWM_POS_7, PWM_POS_a, PWM_POS_4

ear_state_end:



end:
;rjmp main_bridge
  rjmp  main_while

        rjmp    main                    ; Loop forever

;**** End of File ****

; get adxl values

; process values

; flip pins

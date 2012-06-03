I2C ADXL345 accelerometer blink.
================================

This is just a test rig to check I can actually read ADXL registers before doing more indepth code.  

This gets the value of DATAx0 and uses this to turn on and off PORTB 0-2.

  Atmel ATTiny13A used.
  fuse bits low 0x7A
  fuse bits high 0xFF
  ADXL345 referenced as A
  ATTiny13A referenced as T


  VccA, VccT(8), CS, SDO  to 3.3volts.
  GNDA, GNDT(4) to ground.
  SDA to T(2) (PORTB3)
  SCL to T(3) (PORTB4)
  SCA, SCL through 5k resistors to Vcc (no pullups on PCB)
  LED's PORTB 0-2 T(5-7) to GND

Gotcha's (May be different for your ADXL345 PCB)
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- SDO high or low changes read and write addresses.
- CS high or low changes SPI or I2C mode.
- make sure I2c delay and attiny clock cycles agree (set L0x6A when I had calculated for L0x7A).
- Device ID is not read or write i2c bus slave address.
- SDA and SCL need to be pulled high and driven low. May require off PCB resistors.
- ADXL345 needs a stop/start between write address and read value, most libraries don't do this.

AVI link

- http://mich431.net/image/i2c345_1.avi

Based on code from

- http://www.cs.washington.edu/education/courses/cse466/00au/Projects/LakeMan/adv/datasheets/i2c_ex.asm

Referenced code from

  http://mil.ufl.edu/5666/papers/IMDL_Report_Summer_03/koessick_max/Assembly%20Files/TWI/avr300_asm.htm
  http://www.jrobot.net/Download/AVRcam_tiny12.asm
  http://homepage.hispeed.ch/peterfleury/avr-software.html
  http://www.attiny.com/software/AVR000.zip
  http://www.atmel.com/products/microcontrollers/avr/tinyAVR.aspx

Michael Tomkins

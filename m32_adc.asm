.INCLUDE "m32def.inc"

.DEF TEMP = r16
.DEF LIGHT = r17
.DEF NUMBER = r18
.DEF CURRENT_INDICATOR = r19

.ORG 0
    rjmp RESET

.ORG 20
.cseg
seg7_codes:
    .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F

RESET:
	; Инициализация стека
    ldi TEMP, high(RAMEND)
    out SPH, TEMP
    ldi TEMP, low(RAMEND)
    out SPL, TEMP

	rcall INITSYS
	rjmp main
	
main:	
	rcall Out_Light
	rcall wait
	
	lsl CURRENT_INDICATOR
	ldi TEMP, 0XF
	and CURRENT_INDICATOR, TEMP
	
	ldi TEMP, 0
	cp CURRENT_INDICATOR, TEMP
	breq Init_indicator
	
	ldi TEMP, 1
	add NUMBER, TEMP
	ldi TEMP, 5
	cp NUMBER, TEMP
	breq Init_number

	rjmp main
	
Init_indicator:
	ldi CURRENT_INDICATOR, 1
	
Init_number:
	ldi NUMBER, 0
	
Out_Light:
	out PORTD, CURRENT_INDICATOR
	mov TEMP, ZL
	add ZL, NUMBER
	lpm LIGHT, Z
	mov ZL, TEMP
    out PORTB, LIGHT

wait:
    ldi r20, 100
w1:
    ldi r21, 255
w2:
    nop
    dec r21
    brne w2
    dec r20
    brne w1
    ret

	
INITSYS:
	ldi TEMP, 0xFF
    out DDRB, TEMP

	ldi TEMP, 0xFF
	out DDRD, TEMP

	ldi ZH, high(seg7_codes << 1)  ; Загружаем адрес таблицы (умножаем на 2, т.к. PC 16-битный)
    ldi ZL, low(seg7_codes << 1)

	ldi NUMBER, 0
	ldi LIGHT, 0
	ldi CURRENT_INDICATOR, 1
	ret
	
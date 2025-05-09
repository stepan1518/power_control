.INCLUDE "m32def.inc"

.DEF TEMP = r16
.DEF LIGHT = r17
.DEF NUMBER = r18
.DEF CURRENT_INDICATOR = r19
.DEF PARAM_0 = r20
.DEF PARAM_1 = r21
.DEF POWER_0 = r22
.DEF POWER_1 = r23

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
	mov PARAM_0, POWER_0
	mov PARAM_1, POWER_1
	rcall mod10_16bit
	
	;ADC!!!
	;ldi TEMP, 199
	;out ADCSRA, TEMP
;SysDoLoop_S2:
	;sbic	ADCSRA,ADSC
	;rjmp	SysDoLoop_S2

	;in NUMBER, ADCL
	call mod10_16bit
	mov NUMBER, PARAM_0
			
	rcall Out_Light
	rcall wait
	
	lsl CURRENT_INDICATOR
	ldi TEMP, 0XF
	and CURRENT_INDICATOR, TEMP
	
	ldi TEMP, 0
	cp CURRENT_INDICATOR, TEMP
	breq Init_indicator

	rjmp main
	
Init_indicator:
	ldi CURRENT_INDICATOR, 1
	
Out_Light:
	out PORTD, CURRENT_INDICATOR
	mov TEMP, ZL
	add ZL, NUMBER
	lpm LIGHT, Z
	mov ZL, TEMP
    out PORTB, LIGHT

mod10_16bit:
check_param_0:
	ldi TEMP, 10
	cp PARAM_0, TEMP
	brlo check_param_1
mod10_loop:
	ldi TEMP, 10
    sub PARAM_0, TEMP
	clr TEMP
    sbc PARAM_1, TEMP

	rjmp check_param_0
check_param_1:
	ldi TEMP, 0
	cp PARAM_1, TEMP
	breq mod10_done
	rjmp mod10_loop
mod10_done:
    ret

wait:
    ldi r20, 100
w1:
    ldi r21, 250
w2:
    nop
    dec r21
    brne w2
    dec r20
    brne w1
    ret
	
INITSYS:
	ldi TEMP, 0
	out DDRA, TEMP
	ldi TEMP, 0x87
	out ADCSRA, TEMP
	ldi TEMP, 0
	out ADMUX, TEMP
	

	ldi TEMP, 0xFF
    out DDRB, TEMP

	ldi TEMP, 0xFF
	out DDRD, TEMP

	ldi ZH, high(seg7_codes << 1)  ; Загружаем адрес таблицы (умножаем на 2, т.к. PC 16-битный)
    ldi ZL, low(seg7_codes << 1)

	ldi POWER_0, 0b11111100
	ldi POWER_1, 12
	ldi NUMBER, 0
	ldi LIGHT, 0
	ldi CURRENT_INDICATOR, 1
	ret
	
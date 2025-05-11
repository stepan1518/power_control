.INCLUDE "m32def.inc"

.DEF TEMP = r16
.DEF LIGHT = r17
.DEF NUMBER = r18
.DEF CURRENT_INDICATOR = r19
.DEF PARAM_0 = r20
.DEF PARAM_1 = r21
.DEF PARAM_3 = r24
.DEF PARAM_4 = r25
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
	rcall Update_Power

	mov PARAM_0, POWER_0
	mov PARAM_1, POWER_1
	rcall Out_Number_On_Board
	
	rjmp main
	
;args PARAM_1;PARAM_0
Out_Number_On_Board:
	ldi CURRENT_INDICATOR, 1 << 3
Out_Number_On_Board_Loop:
	rcall mod10_16bit
	mov NUMBER, PARAM_0
	mov PARAM_0, PARAM_3
	mov PARAM_1, PARAM_4
			
	rcall Out_Light
	
	lsr CURRENT_INDICATOR
	
	ldi TEMP, 0
	cp CURRENT_INDICATOR, TEMP
	in TEMP, SREG
	lsr TEMP
	andi TEMP, 1
	sbrs TEMP, 0
	
	rjmp Out_Number_On_Board_Loop
	ret
	
;args NUMBER, CURRENT_INDICATOR
Out_Light:
	out PORTD, CURRENT_INDICATOR
	mov TEMP, ZL
	add ZL, NUMBER
	lpm LIGHT, Z
	mov ZL, TEMP
    out PORTB, LIGHT

	rcall wait
	ret

;args PARAM_1;PARAM_0
;return PARAM_0 = mod 10
;return PARAM_4;PARAM_3 = PARAM_1;PARAM_0 // 10
mod10_16bit:
	clr PARAM_3
	clr PARAM_4

	push r18
	push r19
check:
	ldi TEMP, 10
	cp PARAM_0, TEMP
	in r18, SREG
	andi r18, 0x01
	
	ldi TEMP, 0
	cp PARAM_1, TEMP
	in r19, SREG
	lsr r19
	andi r19, 0x01
	
	and r18, r19
	sbrc r18, 0
	rjmp mod10_done
	
	clr r18
	clr r19
mod10_loop:
	;16 bit num -= 10
	ldi TEMP, 10
    sub PARAM_0, TEMP
	clr TEMP
    sbc PARAM_1, TEMP

	;param1 = PARAM_4;PARAM_3
	;param1 = 16 bit num // 10
	;param1 += 1
	ldi TEMP, 1
	add PARAM_3, TEMP
	ldi TEMP, 0
	adc PARAM_4, TEMP

	rjmp check
mod10_done:
	pop r19
	pop r18
    ret

Update_Power:
	push r17
	push r18

	;ADC!!!
	ldi TEMP, 199
	out ADCSRA, TEMP
SysDoLoop_S2:
	sbic	ADCSRA,ADSC
	rjmp	SysDoLoop_S2

	in PARAM_0, ADCL
	in PARAM_1, ADCH
	
	;Пока так надо баг убрать
	ldi PARAM_0, 255
	ldi PARAM_1, 3
	ldi PARAM_3, 15
	rcall multiply_16x8
	
	ldi PARAM_3, 255
	ldi PARAM_4, 3
	rcall Divide16x16
	
	;Деление не работает нормально - разобраться
	;inc PARAM_0
	;Теперь в PARAM_0 текущее I амплитудное
	
	;sqrt(2) = 0.707; * 10 = 7
	ldi PARAM_3, 7
	rcall multiply_16x8
	;В PARAM_0 I действующее
	
	;U = 220В
	ldi PARAM_3, 220
	rcall multiply_16x8
	;в PARAM_1;PARAM_0 теперь мощность
	
	;Отбрасываем вещественную часть
	ldi PARAM_3, 10
	ldi PARAM_4, 0
	rcall Divide16x16
	
	cp POWER_1, PARAM_1	
	in TEMP, SREG
	
	mov r17, TEMP
	andi r17, 1
	
	lsr TEMP
	mov r18, TEMP
	cp POWER_0, PARAM_0
	in TEMP, SREG
	and r18, TEMP
	
	or r17, r18
	sbrc r17, 0
	rcall Set_New_Power_Value
	
	pop r18
	pop r17
	ret
Set_New_Power_Value:
	mov POWER_1, PARAM_1
	mov POWER_0, PARAM_0
	ret

wait:
	push r20
	push r21
    ldi r20, 100
w1:
    ldi r21, 250
w2:
    nop
    dec r21
    brne w2
    dec r20
    brne w1
	
	pop r21
	pop r20 
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

	ldi POWER_0, 0
	ldi POWER_1, 0
	ldi NUMBER, 0
	ldi LIGHT, 0
	ldi CURRENT_INDICATOR, 1
	ret
	
multiply_16x8:
    ; умножаем младший байт
    mul PARAM_0, PARAM_3           ; результат в r1:r0
    mov PARAM_0, r0            ; младший байт результата
    mov TEMP, r1            ; старший байт пока промежуточный

    ; умножаем старший байт
    mul PARAM_1, PARAM_3           ; результат в r1:r0
    add TEMP, r0            ; прибавляем к старшему байту результата
    ; старший байт результата может выйти за пределы 16 бит, но игнорируем

    ; сохраняем 16-битный результат
    mov PARAM_1, TEMP       ; старший байт

    clr r1                 ; обнуляем r1 после mul

    ret

Divide16x16:
	push r17
	push r18
	push r19
Divide_Loop:
	cp PARAM_1, PARAM_4
	in TEMP, SREG
	
	mov r17, TEMP
	andi r17, 1
	
	lsr TEMP
	mov r18, TEMP
	andi r18, 1
	cp PARAM_0, PARAM_3
	in TEMP, SREG
	and r18, TEMP
	
	or r17, r18
	
	sbrs r17, 0
	inc r19
	sbrs r17, 0
	rcall Subtract16x16
	sbrs r17, 0
	rjmp Divide_Loop
	
	mov PARAM_0, r19
	
	pop r19
	pop r18
	pop r17
	ret
	

Subtract16x16:
    sub PARAM_0, PARAM_3
    sbc PARAM_1, PARAM_4

    ret	
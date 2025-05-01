.INCLUDE "m32def.inc"

.DEF TEMP = r16
.DEF LIGHT = r17
.DEF NUMBER = r18

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
	
	ldi NUMBER, 6

    ; Настройка Timer1 на 1 секунду
    ; Предположим F_CPU = 1 МГц → нужен делитель 1024
    ; 1_000_000 / 1024 = 976.5625 тиков в секунду → OCR1A = 976

    ;ldi TEMP, (1 << WGM12)         ; CTC режим (Clear Timer on Compare Match)
    ;out TCCR1B, TEMP

    ;ldi TEMP, 0x0F	                ; Выставляем OCR1A = 976 (low byte)
    ;out OCR1AL, TEMP
    ;ldi TEMP, 0x00               ; 976 = 0x03D0 (high byte = 0x03)
    ;out OCR1AH, TEMP

    ; Установка делителя 1024: CS12=1, CS10=1
    ;ldi TEMP, (1 << CS12) | (1 << CS10)
    ;out TCCR1B, TEMP
	
	rcall Out_Light
	
Out_Light:
	ldi TEMP, 1
	out PORTD, TEMP
	ldi NUMBER, 1
	add ZL, NUMBER
	lpm LIGHT, Z
    mov TEMP, LIGHT
    out PORTB, TEMP

	ldi TEMP, 2
	out PORTD, TEMP
	ldi NUMBER, 1
	add ZL, NUMBER
	lpm LIGHT, Z
    mov TEMP, LIGHT
    out PORTB, TEMP
	
INITSYS:
	ldi TEMP, 0xFF
    out DDRB, TEMP

	ldi TEMP, 0xFF
	out DDRD, TEMP

	ldi ZH, high(seg7_codes << 1)  ; Загружаем адрес таблицы (умножаем на 2, т.к. PC 16-битный)
    ldi ZL, low(seg7_codes << 1)
	ret
	
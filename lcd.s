; vim: set syntax=asmM6502:
; vim; set ai

PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

value = $0200 ; 2 bytes
mod10 = $0202 ; 2 bytes
message = $0204 ; 6 bytes
;counter = $020a ; 2 bytes

RS = $20 	; 00100000
RW = $40	; 01000000
E  = $80	; 10000000

  .org $8000

reset:
  ldx #$ff
  txs

  lda #%11111111
  sta DDRB

  lda #%11100000	; RS RW E output
  sta DDRA

  lda #$38	; 8-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  
  lda #$0e	; display on; cursor on; blink off
  jsr lcd_instruction
  
  lda #$06	; increment and shift cursor
  jsr lcd_instruction
  
  lda #$01	; clr screen
  jsr lcd_instruction

  lda #0
  sta message

  ; initialize value to be number to convert
  lda number	 ; load first byte
  sta value      ; store in RAM at position defined by value
  lda number + 1 ; load second byte of 16 bit word 
  sta value + 1  ; store second byte in RAM

divide:
  ; initialize remainder to zero
  lda #0
  sta mod10
  sta mod10 + 1 
  clc

  ldx #16
divloop:
  ; rotate quotient and remainder
  rol value	 ; https://www.youtube.com/watch?v=v3-a-zqKfgA&t=36s
  rol value + 1
  rol mod10
  rol mod10 + 1

  sec
  lda mod10
  sbc #10
  tay ; save low byte in Y
  lda mod10 + 1
  sbc #0
  bcc ignore_result	; branch if divident < divisor
  sty mod10
  sta mod10 + 1

ignore_result:
  dex
  bne divloop
  rol value
  rol value + 1
  
  lda mod10
  clc
  adc #"0"
  jsr push_char

  ; if value != 0; continue dividing
  lda value
  ora value + 1
  bne divide

  
  ldx #0
print:
  lda message,x
  beq loop 
  jsr print_char
  inx
  jmp print

loop:
  jmp loop

number: .word 1729

; add the character in the A register to the beginning of the 
; null-terminated string `message`
push_char:
  pha ; push new first char onto stack
  ldy #0

char_loop:
  lda message,y ; get char from string and put into X
  tax
  pla
  sta message,y ; pull char off stack and add it to the string
  iny
  txa
  pha		; push char from string onto stack
  bne char_loop
  
  pla
  sta message,y ; pull null off the stack and add to the end of the string


;message: .asciiz "  Hello                                    World!"

lcd_wait:
  pha			; save content of A reg to stack (push a)
  lda #$00
  sta DDRB
lcd_busy:
  lda #RW
  sta PORTA
  lda #(RW | E)
  sta PORTA
  lda PORTB
  and #%10000000	; will set zero flag if result of and is zero
  bne lcd_busy		; branch if as long zero flag is set -> lcd busy not set

  lda #RW
  sta PORTA
  lda #$ff
  sta DDRB
  pla			; restore contents of a from stack (pull a)
  rts

lcd_instruction:
  jsr lcd_wait
  sta PORTB	; put data in register a on data bus
  lda #0	; clear RS/RW/E
  sta PORTA	
  lda #E	; set E 
  sta PORTA     
  lda #0	; clear RS/RW/E
  sta PORTA
  rts

print_char:
  jsr lcd_wait
  sta PORTB
  lda #RS
  sta PORTA
  lda #(RS | E) ; set E and RS
  sta PORTA
  lda #RS
  sta PORTA
  rts

  .org $fffc
  .word reset
  .word $0000

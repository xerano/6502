; vim: set syntax=asmM6502:
; vim; set ai

PORTB = $6000
DDRB = $6002

  .org	$8000

  lda #$ff
  sta DDRB

  lda #$50
  sta PORTB

loop:
  ror
  sta PORTB

  jmp loop

  .org  $fffc
  .word $8000
  .word $0000

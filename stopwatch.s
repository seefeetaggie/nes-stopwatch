  countsix = $f5
  tenths = $f4
  seconds = $f3
  decasec = $f2
  mins = $f1
  decamin = $f0
.segment "HEADER"
  ; .byte "NES", $1A      ; iNES header identifier
  .byte $4E, $45, $53, $1A
  .byte 2               ; 2x 16KB PRG code
  .byte 1               ; 1x  8KB CHR data
  .byte $01, $00        ; mapper 0, vertical mirroring

.segment "VECTORS"
  ;; When an NMI happens (once per frame if enabled) the label nmi:
  .addr nmi
  ;; When the processor first turns on or is reset, it will jump to the label reset:
  .addr reset
  ;; External interrupt IRQ (unused)
  .addr 0

; "nes" linker config requires a STARTUP section, even if it's empty
.segment "STARTUP"

; Main code segment for the program
.segment "CODE"

reset:
  sei		; disable IRQs
  cld		; disable decimal mode
  ldx #$40
  stx $4017	; disable APU frame IRQ
  ldx #$ff 	; Set up stack
  txs		;  .
  inx		; now X = 0
  stx $2000	  ; disable NMI
  stx $2001 	; disable rendering
  stx $4010 	; disable DMC IRQs

;; first wait for vblank to make sure PPU is ready
vblankwait1:
  bit $2002
  bpl vblankwait1

;; second wait for vblank, PPU is ready after this
vblankwait2:
  bit $2002
  bpl vblankwait2

main:
; initialize times to zero
  lda #0
  sta countsix
  sta tenths
  sta seconds
  sta decasec
  sta mins
  sta decamin

enable_rendering:
  lda #%10000000	; Enable NMI
  sta $2000
  lda #%00011110	; Enable background and sprites
  sta $2001

forever:
  jmp forever

nmi:
; This is called when vertical blank starts after each frame is drawn,
; or 60 times every second

load_palettes:
  lda $2002
  lda #$3F
  sta $2006
  lda #$00
  sta $2006

; .byte $37,$00,$10,$3c
; .byte $37,$01,$16,$0f

  lda #$22
  sta $2007
  lda #$00
  sta $2007
  lda #$10
  sta $2007
  lda #$0f
  sta $2007

  lda #$37
  sta $2007
  lda #$01
  sta $2007
  lda #$16
  sta $2007
  lda #$0f
  sta $2007

load_nametable:
  lda $2002
  lda #$21
  sta $2006
  lda #$AC
  sta $2006

Diglett:
  ; decaminutes
  lda decamin
  ora #$c0
  sta $2007
  ; minutes
  lda mins
  ora #$c0
  sta $2007
  ; colon
  lda #$e6
  sta $2007
  ; decaseconds
  lda decasec
  ora #$c0
  sta $2007
  ; seconds
  lda seconds
  ora #$c0
  sta $2007
  ; period
  lda #$e4
  sta $2007
  ; tenths
  lda tenths
  ora #$c0
  sta $2007

ResetScroll:
  lda $2002
  lda #$00
  sta $2005
  sta $2005

Eevee:
  ldx countsix
  inx
  cpx #$06
  beq Pokemon
  stx countsix
  jmp miraidon

Pokemon:
  ldx #$00
  stx countsix

  ldx tenths
  inx
  cpx #$0a
  beq dratini
  stx tenths
  jmp miraidon 

dratini:
  ldx #$00
  stx tenths

  ldx seconds
  inx 
  cpx #$0a
  beq bidoof
  stx seconds
  jmp miraidon

bidoof:
  ldx #$00
  stx seconds

  ldx decasec
  inx 
  cpx #$06
  beq fidough
  stx decasec
  jmp miraidon

fidough:
  ldx #$00
  stx decasec
  ldx mins
  inx 
  cpx #$0a
  beq Oshawott
  stx mins
  jmp miraidon

Oshawott:
  ldx #$00
  stx mins
  ldx decamin
  inx 
  cpx #$06
  beq Arceus
  stx decamin
  jmp miraidon

Arceus:
  ldx #$00
  stx decamin


miraidon:
  rti

.segment "CHARS"
; Include the CHR ROM that has the different tiles available.
.incbin "stopwatch.chr"

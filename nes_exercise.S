.db "NES", $1A, 2, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
.org $8000

.define PPUCTRL $2000
.define PPUMASK $2001
.define PPUSTATUS $2002
.define OAMADDR $2003
.define OAMDATA $2004
.define PPUSCROLL $2005
.define PPUADDR $2006
.define PPUDATA $2007
.define OAMDMA $4014

.define JOYPAD1 $4016
.define JOYPAD2 $4017

.define SCROLL_X $00
.define SCROLL_Y $01

.define buttons $02
.define PlayerX $03
.define PlayerY $04



start:
    LDA #%10100000
    STA PPUCTRL
    LDA #%00011110
    STA PPUMASK
    
    ; load background palette
    LDA #$3f
    STA PPUADDR
    LDA #0
    STA PPUADDR

    ; LDA #$19
    ; STA PPUDATA
    ; LDA #$05
    ; STA PPUDATA
    ; LDA #$28
    ; STA PPUDATA
    ; LDA #$0F
    ; STA PPUDATA

    ; load first sprite palette
    ; LDA #$3f
    ; STA PPUADDR
    ; LDA #$10
    ; STA PPUADDR

    ; LDA #$21
    ; STA PPUDATA
    ; LDA #$22
    ; STA PPUDATA
    ; LDA #$23
    ; STA PPUDATA
    ; LDA #$24
    ; STA PPUDATA

    ; load second sprite palette
    ; LDA #$16
    ; STA PPUDATA
    ; LDA #$17
    ; STA PPUDATA
    ; LDA #$18
    ; STA PPUDATA
    ; LDA #$19
    ; STA PPUDATA

    ; load background tiles
    ; LDA #$20
    ; STA PPUADDR
    ; LDA #$00
    ; STA PPUADDR
    ; LDA #$02
    ; STA PPUDATA
    ; LDA #$FD
    ; STA PPUDATA
    ; LDA #$FE
    ; STA PPUDATA


    LDA #00
    STA OAMADDR
    LDA #$00
    STA OAMDATA
    LDA #$75
    STA OAMDATA
    ; LDA #%10000001
    ; STA OAMDATA
    ; LDA #$22
    ; STA OAMDATA

    ; LDA #4
    ; STA OAMADDR
    ; LDA #$00
    ; STA OAMDATA
    ; LDA #$F6
    ; STA OAMDATA
    ; LDA #%00000000
    ; STA OAMDATA
    ; LDA #$11
    ; STA OAMDATA
    ; load background tiles
    LoadPalette:
        LDA PPUSTATUS             ; read PPU status to reset the high/low latch
        LDA #$3F
        STA PPUADDR             ; write the high byte of $3F00 address
        LDA #$00
        STA PPUADDR             ; write the low byte of $3F00 address
        LDX #$00              ; start out at 0

    LoadBackgroundPaletteLoop:
    LDA background_palette,X        ; load data from address (palette + the value in x)
                          ; 1st time through loop it will load palette+0
                          ; 2nd time through loop it will load palette+1
                          ; 3rd time through loop it will load palette+2
                          ; etc
    STA PPUDATA             ; write to PPU
    INX                   ; X = X + 1
    CPX #$20              ; Compare X to hex $10, decimal 16
    BNE LoadBackgroundPaletteLoop  ; Branch to LoadBackgroundPaletteLoop if compare was Not Equal to zero

    
    .define NameTableStartAddressHigh   $05
    .define NameTableStartAddressLow    $06
    .define NT_CurrentAddressLow         $07
    .define NT_CurrentAddressHigh        $08
    .define PatternTableCounter         $09
    .define LineCounter                 $0A
    .define ColumnCounter               $0B



    
    LDA #$20
    STA NameTableStartAddressHigh
    

    LDA #$00
    STA NameTableStartAddressLow

    JSR FillNametable


    LDA #$24
    STA NameTableStartAddressHigh
    
    LDA #$00
    STA NameTableStartAddressLow
   

    JSR FillNametable


loop:
    JMP loop

FillNametable:

    LDA  NameTableStartAddressHigh
    STA NT_CurrentAddressHigh
    STA PPUADDR

    
    LDA NameTableStartAddressLow
    STA NT_CurrentAddressLow
    STA PPUADDR

    LDY #0
    LDX #0
    STX PatternTableCounter
    STX LineCounter
    STX ColumnCounter
    LDA #%10010000
    STA PPUCTRL
        
    NewRow:
        LDA #%10010000
        STA PPUCTRL
        LDA PatternTableCounter
        STA PPUDATA
        INC PatternTableCounter
        LDA PatternTableCounter
        CMP #$FF
        BEQ END

        INC NT_CurrentAddressLow
        
        LDA NT_CurrentAddressLow

        CMP #$00
        BEQ HighIncrease
    



        INC ColumnCounter
        LDA ColumnCounter
        
        CMP #$10
        BEQ NewLine
        JMP NewRow

    NewLine:
        LDA #%10010100
        STA PPUCTRL
        LDA NT_CurrentAddressHigh
        STA PPUADDR
        LDA NT_CurrentAddressLow
        ADC #$0F
        STA NT_CurrentAddressLow
        STA PPUADDR
        LDA #0
        STA ColumnCounter
        INC LineCounter
        LDA LineCounter
        CMP #$08
        BNE SkipHighIncrease
            HighIncrease:
            INC NT_CurrentAddressHigh
            LDA NT_CurrentAddressHigh
            STA NT_CurrentAddressHigh
            STA PPUADDR
            LDA #$00
            STA NT_CurrentAddressLow
            STA PPUADDR
        SkipHighIncrease:
        LDA LineCounter
        CMP #$10
        BNE NewRow

    END:
    RTS

readjoy:
    LDA #$01
    STA JOYPAD1
    STA buttons
    LDA #$00
    STA JOYPAD1
joyloop:
    LDA JOYPAD1
    LSR A 
    ROL buttons
    BCC joyloop
    RTS

nmi:
    PHA
    JSR readjoy
    PLA

    ReadMoveUp:
        LDA buttons
        AND #%00001000
        BNE StartMoveUp
        JMP ReadUpDone

    ReadUpDone:

    ReadMoveDown:
        LDA buttons
        AND #%00000100
        BNE StartMoveDown
        JMP ReadDownDone

    ReadDownDone:

    ReadMoveLeft:
        LDA buttons
        AND #%00000010
        BNE StartMoveLeft
        JMP ReadLeftDone

    ReadLeftDone:

    ReadMoveRight:
            LDA buttons
            AND #%00000001
            BNE StartMoveRight
            JMP ReadRightDone
ReadRightDone:
CancelScroll:
  RTI

StartMoveLeft:
    LDA SCROLL_X
    SBC #1
    CMP #$00
    BEQ CancelScroll
    STA SCROLL_X
    JSR ApplyScroll
    JMP ReadLeftDone

StartMoveRight:
    CLC
    LDA SCROLL_X

    ADC #1
    CMP #$FF
    BEQ CancelScroll
    STA SCROLL_X
    JSR ApplyScroll
    JMP ReadRightDone

StartMoveDown:
    CLC
    LDA SCROLL_Y
    ADC #1
    CMP #$00
    BEQ CancelScroll
    STA SCROLL_Y
    JSR ApplyScroll
    JMP ReadDownDone

StartMoveUp:
    SEC
    LDA SCROLL_Y
    SBC #1
    CMP #$00
    BEQ CancelScroll
    STA SCROLL_Y
    JSR ApplyScroll
    JMP ReadUpDone

ApplyScroll:
    LDA SCROLL_X
    STA PPUSCROLL
    
    LDA SCROLL_Y
    STA PPUSCROLL
    

    LDA #0
    STA OAMADDR
    LDA SCROLL_Y
    STA OAMDATA
    LDA #3
    STA OAMADDR
    LDA SCROLL_X
    STA OAMDATA


RTS


irq:
    RTI

background_palette:
  .db $21,$0F,$28,$30	;background palette 1
  .db $21,$0F,$28,$30	;background palette 2
  .db $21,$0F,$28,$30	;background palette 3
  .db $21,$0F,$28,$30	;background palette 4  
  .db $21,$1F,$15,$30	;background palette 5
  .db $21,$1F,$15,$30	;background palette 6
  .db $21,$1F,$15,$30	;background palette 7
  .db $21,$1F,$15,$30	;background palette 8  

.goto $FFFA

.dw nmi
.dw start
.dw irq
.incbin mario0.chr
.incbin aiv256.chr
// IO macros

#importonce

#import "kernal_const.asm"

// Print a character to current output (usually screen) using kernal (CHROUT) 
.macro PrintChar(char)
{
    lda #char        // clear screen
    jsr CHROUT
}
    
.macro PrintClearScreen()
{
    PrintChar(147)
}
    
// Print a zero-terminated string to current output (usually screen) using kernal (CHROUT) 
// Note: maximum string size is 256 chars (inclusing the null) 
// because absolute indexed adressing is used load chars from the string
// and also because the loop terminated after 256 iterations. 

.macro PrintString(string_addr) 
{
    ldx #0
loop:
    lda string_addr,x
    beq exit                // zero terminates string
    jsr CHROUT 
    inx
    bne loop 
exit:
}

// Set cursor position to given values (using kernal PLOT routine)
.macro SetCursor(row, col)
{
    clc
    ldx #row
    ldy #col
    jsr PLOT
    // TODO: instead of using PLOT, just set $D6 and $D3?
    // No, that doesn't seem to work. I think just basic 
    // looks at $D6 and $D3.  
}

// Set cursor position to from guiven byte adresses (using kernal PLOT routine)
.macro SetCursor_Bytes(row_byte, col_byte)
{
    clc
    ldx row_byte
    ldy col_byte
    jsr PLOT
    // TODO: instead of using PLOT, just set $D6 and $D3?
    // No, that doesn't seem to work. I think just basic 
    // looks at $D6 and $D3.  
}


// Convert byte valye to two hexidecimal digits (ASCII bytes) in hex_string 
// Note: hex_string should have space for 3 bytes
// for two hex digits and a third zero byte to terminate the string

.macro ByteToHex(byte_addr, hex_string)
{
    clc                 // needed for ADC later
    lda byte_addr
    and #$0F             // low nybble
    cmp #$0A            
    bpl letter
    // nybble is 0-9
    adc #48     // ASCII "0"
    jmp first
letter:
    // nybble is A-F
    adc #54     // ASCII "A" - 10
first:
    sta hex_string+1        // store second digit in string
    
    clc
    lda byte_addr
    lsr              // high nybble
    lsr
    lsr
    lsr
    cmp #$0A            
    bpl letter2
    // nybble is 0-9
    adc #48     // ASCII "0"
    jmp second
letter2:
    // nybble is A-F
    adc #54     // ASCII "A" - 10
second:
    sta hex_string        // store second digit in string
    
    lda #0                // string terminator 
    sta hex_string+2
 
}

// Like ByteToHex but for a two byte word. Needs a 5 byte hex string.  
// The word is the usual C64 low byte, high byte order
// The hex string is high-to-low order.   
.macro WordToHex(word_addr, hex_string)
{
    ByteToHex(word_addr+1, hex_string)          // high byte
    ByteToHex(word_addr, hex_string+2)          // low byte
    
}


// Convert byte valye to two hexidecimal digits (SCREEN code bytes) in hex_string 
// Note: hex_string should have space for 3 bytes
// for two hex digits and a third zero byte to terminate the string

.macro ByteToHex_Screen(byte_addr, hex_string)
{
    clc                 // needed for ADC later
    lda byte_addr
    and #$0F             // low nybble
    cmp #$0A            
    bpl letter
    // nybble is 0-9
    adc #48         // Screencode for "0"
    jmp first
letter:
    // nybble is A-F
    adc #-9         // A=1, 10->A
first:
    sta hex_string+1        // store second digit in string
    
    clc
    lda byte_addr
    lsr              // high nybble
    lsr
    lsr
    lsr
    cmp #$0A            
    bpl letter2
    // nybble is 0-9
    adc #48     // ASCII "0"
    jmp second
letter2:
    // nybble is A-F
    adc #-9                 // "A"=1, 10->"A"
second:
    sta hex_string        // store second digit in string
    
    lda #0                // string terminator 
    sta hex_string+2
 
}


// Like ByteToHex_Screen but for a two byte word. Needs a 5 byte hex string.  
// The word is the usual C64 low byte, high byte order
// The hex string is high-to-low order.   
.macro WordToHex_Screen(word_addr, hex_string)
{
    ByteToHex_Screen(word_addr+1, hex_string)          // high byte
    ByteToHex_Screen(word_addr, hex_string+2)          // low byte
    
}

// write string directly to screen buffer
// stops when string is zero terminated or >255 bytes
// does not stop when wring outside of screen buffer
.macro StringToScreen(string, screen, row, col)
{
    ldx #0
loop:
    lda string,x
    beq finish
    sta screen+row*40+col,x
    inx
    bne loop
finish:
}

// Push and Pop regeisters A,X,Y
// useful when io macros are used for debugging
.macro PushRegs()
{
    pha     // push A
    tya
    pha     // push Y
    txa
    pha     // push X
}

.macro PopRegs()
{
    pla     // pull X
    tax     
    pla     // pull Y
    tay     
    pla     // pull A
}
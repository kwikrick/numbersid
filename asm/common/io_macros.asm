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
    adc #54     // ASCII "0" + 6 to skip to "A"
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
    adc #54     // ASCII "0" + 6 to skip to "A"
second:
    sta hex_string        // store second digit in string
    
    lda #0                // string terminator 
    sta hex_string+2
 
}


// Old version: awkward placement of data

//.macro ByteToHex(byte_addr, hex_string)
//{
    //lda byte_addr
    //and #$0F
    //tax                     // X is low nybble of byte_add
    //lda hex_digits,x        // load byte x from hex_digits
    //sta hex_string+1        // store second digit in string
    
    //lda byte_addr
    ////and $F0                 // not needed
    //lsr
    //lsr
    //lsr
    //lsr
    //tax                     // X is high nybble of byte_add
    //lda hex_digits,x        // load byte x from hex_digits
    //sta hex_string          // store first digit in string
    
    //jmp after_data
//hex_digits:
//.text "0123456789ABCDEF"
//after_data:
//}


// Like ByteToHex but for a two byte word. Needs a 5 byte hex string.  
// The word is the usual C64 low byte, high byte order
// The hex string is high-to-low order.   
.macro WordToHex(word_addr, hex_string)
{
    ByteToHex(word_addr+1, hex_string)          // high byte
    ByteToHex(word_addr, hex_string+2)          // low byte
    
}

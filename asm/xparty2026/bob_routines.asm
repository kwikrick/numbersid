#importonce 

#import "bob_macros.asm"
#import "common/word_macros.asm"


/*

// create character
// inputs:
// zp_charset_addr   : (zeros page) word with target adress
// todo     : the shape parameter
// affect A,X,Y

bob_create_character:
{
    ldy #0
loop_y:
    ldx #0
loop_x:

    jsr bob_pixel_in_radius
    bcc skip_set_pixel

    txa
    pha
    jsr bob_set_pixel
    pla
    tax

skip_set_pixel:
    inx
    cpx #8
    bne loop_x
    iny
    cpy #8
    bne loop_y

    rts
}

// set pixel in character
// zp_tgt: adress of character
// X: x position (0-8)
// Y: y position (0-8)
bob_set_pixel:
{
    lda #1 
loop_shift:
    cpx #0
    beq done
    asl
    dex
    jmp loop_shift 
done:
    ora (zp_charset_addr),y
    sta (zp_charset_addr),y
    rts
}


// get pixel in radius
// A
// X: x position (0-8)
// Y: y position (0-8)
bob_pixel_in_radius:
{
    stx ZP_FREE+1
    sty ZP_FREE+2

    tax
    pha
    tay
    pha
    Word_Mul_LoHi(ZP_FREE+1)
    pla
    tay
    pla
    tax

    .const RADIUS=4
    Word_Compare_Value(ZP_FREE+1,RADIUS*2)
    rts
}

*/
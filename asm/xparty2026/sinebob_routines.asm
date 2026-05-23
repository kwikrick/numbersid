#importonce 

#import "sinebob_macros.asm"
#import "common/word_macros.asm"
#import "demo_zeropage.asm"

sinebob_update_transitions:
{
.break
	Word_Add_Value(sinebob_transition_offset, 8, sinebob_transition_offset)		
	Word_AND_Value(sinebob_transition_offset, (8*64)-1, sinebob_transition_offset)		// TODO: combine for speed and size
    Word_Copy(sinebob_transition_offset, ZP_IRQ_OFF)
    
  	Word_Store_Value(ZP_IRQ_SRC, character_data1)
	
	//Word_Store_Value(ZP_IRQ_TGT, bob_charset_addr+8)		// skip char 0
	//Word_Add_Word(ZP_IRQ_TGT, ZP_IRQ_OFF, ZP_IRQ_TGT)

    // copy char 1,2,3,4,5
    ldx #0
loop_block1:
    txa
    pha
    jsr sinebob_copy_transitions
    Word_Add_Value(ZP_IRQ_SRC,8,ZP_IRQ_SRC)
    pla
    tax
    inx
    cpx #5                  // TODO: just make 8 chars and copy all in order? Safe space or not? (Probably not actually)
    bne loop_block1

    // copy char 4,3,2
    Word_Add_Value(ZP_IRQ_SRC,-2*8,ZP_IRQ_SRC) 

   ldx #0
loop_block2:
    txa
    pha
    jsr sinebob_copy_transitions
    Word_Add_Value(ZP_IRQ_SRC,-8,ZP_IRQ_SRC) 		// note: previous source char
    pla
    tax
    inx
    cpx #3
    bne loop_block2

    rts
}

// copy source character twice, to target position and target position + 7 character definitons (7*8 bytes)
// input; 
// ZP_IRQ_SRC (IRQ safe temp var)
// ZP_IRQ_OFF (IRQ safe temp var)
// bob_charset_addr
// Affects: A,X,Y, ZP_IRQ_TGT, ZP_IRQ_OFF

sinebob_copy_transitions:
{
        ldx #0
    loop_char:

        // compute ZP_IRQ_TGT from ZP_IRQ_OFF
        Word_AND_Value(ZP_IRQ_OFF, (8*64)-1, ZP_IRQ_OFF)
        Word_Add_Value(ZP_IRQ_OFF, bob_charset_addr+8, ZP_IRQ_TGT)  // note skip char 0

        ldy #0
    loop_row:
        lda (ZP_IRQ_SRC),y
        sta (ZP_IRQ_TGT),y
        iny
        cpy #8
        bne loop_row

        inx
        cpx #2
        beq done

        // target adress += 7 chars
        Word_Add_Value(ZP_IRQ_OFF, 7*8, ZP_IRQ_OFF)
        
        
        clc
        bcc loop_char

    done:

    // target adress += 1 chars
    Word_Add_Value(ZP_IRQ_OFF, 1*8, ZP_IRQ_OFF)

    rts
}

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
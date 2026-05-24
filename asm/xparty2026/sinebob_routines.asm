#importonce 

#import "sinebob_macros.asm"
#import "common/word_macros.asm"
#import "demo_zeropage.asm"


// copy charset 
//  from character_data1
//  to bob_charset_addr

sinebob_init_charset:
{
    // just calls sinebob_update_transitions 8 times
    ldx #8
loop_update:
    txa
    pha
    jsr sinebob_update_transitions
    pla
    tax
    dex
    bne loop_update
    rts
}

// Update charset - copies character defintions at transition boudaries
// inputs:
//  sinebob_transition_offset
//  character_data1
//  bob_charset_addr
// Affects A,X,Y, sinebob_transition_offset, ZP_IRQ_SRC, ZP_IRQ_TGT, ZP_IRQ_OFF

sinebob_update_transitions:
{
    // increment sinebob_transition_offset; copy to ZP_IRQ_OFF
	Word_Add_Value(sinebob_transition_offset, 8, sinebob_transition_offset)		
    Word_Copy(sinebob_transition_offset, ZP_IRQ_OFF)
    
    // ZP_IRQ_SRC = start of charset
  	Word_Store_Value(ZP_IRQ_SRC, character_data1)
	
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
        Word_Add_Value(ZP_IRQ_OFF, bob_charset_addr+BOB_CHAR_START*8, ZP_IRQ_TGT)  // note skip char 0

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

sinebob_init_history:
{
    // init clear_pixel ptr
    Word_Store_Value(ZP_CLEAR_PIXEL_PTR, clear_pixel_history)

    // init history with safe values
    Fill(clear_pixel_history,CLEAR_HISTORY_SIZE*2,$C0)        // $C0C0 is pretty far in memory, and not used by me or anyone    

    rts
}
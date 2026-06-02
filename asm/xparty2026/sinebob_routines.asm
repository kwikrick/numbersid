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
	Word_Add_Value(sinebob_transition_offset, BOB_CHARSET_STEP, sinebob_transition_offset)		
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

// copy source character twice, to target position and target position + BOB_CHARSET_STEP-1 (*8 bytes)
// and increments target position by BOB_CHARSET_STEP (*8 bytes)
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
        Word_AND_Value(ZP_IRQ_OFF, (8*BOB_CHARSET_LENTGH)-1, ZP_IRQ_OFF)
        Word_Add_Value(ZP_IRQ_OFF, bob_charset_addr+BOB_CHARSET_START*8, ZP_IRQ_TGT)

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

        // target adress += BOB_CHARSET_STEP-1 chars
        Word_Add_Value(ZP_IRQ_OFF, (BOB_CHARSET_STEP-1)*8, ZP_IRQ_OFF)
          
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

sinebob_compute_tables:
{
    .const SINE_TABLE_PTR = ZP_FREE
    .const SINE_TABLE_PTR_h = ZP_FREE+1
    .const SINE_VALUE_L = ZP_FREE+2
    .const SINE_VALUE_H = ZP_FREE+3
    .const AMPLITUDE = ZP_FREE+4
    
    Word_Store_Value(SINE_TABLE_PTR, sine_tables)
    
    ldx #0
loop_x:
    ldy #0              
loop_y:
    lda sine_256_256,y
    sta SINE_VALUE_L

    txa
    clc          
    sta AMPLITUDE
    asl             
    sta SINE_VALUE_H
    
    txa
    pha
    tya
    pha
    Word_Mul_LoHi(SINE_VALUE_L)
    pla
    tay
    pla
    tax


    lda SINE_VALUE_H
    sec
    sbc AMPLITUDE

    sta (SINE_TABLE_PTR),y
    
    iny
    //cpy #0      // 256 times
    bne loop_y

    Word_Add_Value(SINE_TABLE_PTR,256,SINE_TABLE_PTR)
    
    inx
    cpx #32     // 32 times 
    bne loop_x

    rts
}

sinebob_compute:
{

    .const SINE_TABLE_PTR = ZP_IRQ+5		// word
	
	ldx #0
loop_compute:
	// load amplitude
    // Note: only low byte (TODO: handle sign? if negative, add half cycle to phase?)
    // limit between 0 and 31
	lda amplitudes,x	
	and #31
    sta ZP_IRQ

    // compute SINE_TABLE_PTR from amplitude
    // adding low byte of amplitude to high byte of sine_table_ptr; 256 bytes for each amplitude
    Word_Store_Value(SINE_TABLE_PTR, sine_tables)
    lda SINE_TABLE_PTR+1
    clc
    adc ZP_IRQ
    sta SINE_TABLE_PTR+1           

	// load counter
	lda counters,x
	sta ZP_IRQ
	lda counters+1,x	
	sta ZP_IRQ+1
	
	// load freq
	lda freqs,x
	sta ZP_IRQ+2
	lda freqs+1,x	
	sta ZP_IRQ+3
	
	// add freq to counter
	Word_Add_Word(ZP_IRQ,ZP_IRQ+2,ZP_IRQ)
	
	// store counter
	lda ZP_IRQ
	sta counters,x
	lda ZP_IRQ+1
	sta counters+1,x

	// get counter high byte and add phase
	lda counters+1,x		// get counter high byte, divides by 256
	adc phases,x			// add phase (low byte only)
                            // TODO: low byte of phase is wrong when negative?

	// get sine value
	tay
	lda (SINE_TABLE_PTR),y
    
    // store
    //  TODO: sine value is a signed byte, but positions is signed word. 
    //  Waste of memory, but no perormance inpact?
    sta sine_values,x     
	//lda #0
	//sta sine_values+1,x
	
	inx
	inx
	cpx #NUM_SINES*2       // two bytes per sine
	beq end_loop_compute
	jmp loop_compute		// need long jump

end_loop_compute:

    // --- add sines to position_x, poistion_y ----

    .const SINE_VALUE_PTR = ZP_IRQ+5		// word
    .const ZP_ORBIT = ZP_IRQ+7

    Word_Store_Value(SINE_VALUE_PTR, sine_values)
    
    ldx #0
loop_bob:

    lda #20
    sta bob_xs,x
    lda #13 
    sta bob_ys,x

    lda bob_num_orbits,x
    sta ZP_ORBIT
loop_orbits:
    ldy #0
 	lda (SINE_VALUE_PTR),y	    
	clc
    adc bob_xs,x
    sta bob_xs,x

    iny
    iny
    lda (SINE_VALUE_PTR),y
	clc
    adc bob_ys,x
    sta bob_ys,x

    Word_Add_Value(SINE_VALUE_PTR,4,SINE_VALUE_PTR)

    dec ZP_ORBIT
    bne loop_orbits

    // increment bob step counter; note parameter is word, but counter is byte!
    txa
    asl
    tay
	lda bob_steps,y
    clc
	adc sinebob_step_counters,x
	//and #BOB_CHARSET_LENTGH-1		// just loop at 256
	sta sinebob_step_counters,x

    inx
    cpx #NUM_BOBS
    bne loop_bob

    rts
}


.const ZP_X = ZP_IRQ+4		        // word
.const ZP_Y = ZP_IRQ+6		        // word	
.const ZP_COLOR = ZP_IRQ+8
.const ZP_COUNTER = ZP_IRQ+9

sinebob_draw:
{ 
    ldx #0
    loop_bob:

    txa
    asl
    tay     // Y=2*X

    // enabled parameter?
    lda bob_enables,y
    and #1
    bne enabled_draw
    jmp skip_draw

    enabled_draw:

    // load x sum of sines, convert from byte to word
    lda bob_xs,x
    sta ZP_IRQ          // TODO: intermediate not needed, make a x-indexed version of singed byte->word conversion 
    Word_Store_Signed_Byte(ZP_X, ZP_IRQ)
    
    // add x position parameter
    lda bob_position_xs,y
    sta ZP_IRQ
    lda bob_position_xs+1,y
    sta ZP_IRQ+1
    Word_Add_Word(ZP_X, ZP_IRQ, ZP_X)
    
    // load x sum of sines, convert from byte to word
    lda bob_ys,x
    sta ZP_IRQ 
    Word_Store_Signed_Byte(ZP_Y, ZP_IRQ)

    // add y position parameter
    lda bob_position_ys,y
    sta ZP_IRQ
    lda bob_position_ys+1,y
    sta ZP_IRQ+1
    Word_Add_Word(ZP_Y, ZP_IRQ, ZP_Y)

    lda bob_colors,y
    sta ZP_COLOR

    lda sinebob_step_counters,x
    sta ZP_COUNTER

    txa
    pha 
    jsr sinebob_draw_one
    pla
    tax

skip_draw:

    inx
    cpx #NUM_BOBS
    beq end_loop_bob
    jmp loop_bob

end_loop_bob:

    rts
}



sinebob_draw_one:
{
	.const ZP_CELL = ZP_IRQ   		    // word
	.const ZP_CELL_H = ZP_IRQ+1   		// word
	.const ZP_TEMP = ZP_IRQ+2			// note: used by Word_Mul_40 too
	.const ZP_TEMP_H = ZP_IRQ+3
    
    
	// ------- check screen bounds -------

	// TODO: modulo 25 easy to compute?
	Word_Compare_Value_Y(ZP_Y, 2)
	bmi skip1
	Word_Compare_Value_Y(ZP_Y, 25)
	bpl skip1

	// TODO: modulo 40 easy to compute?
	Word_Compare_Value_Y(ZP_X, 0)
	bmi skip1
	Word_Compare_Value_Y(ZP_X, 40)
	bpl skip1
	
	clc
	bcc cont1
	skip1:
	jmp skip
	cont1:

	// ---- clear pixels from history

	ldy #0
	lda (ZP_CLEAR_PIXEL_PTR),y
	sta ZP_CELL
	iny
	lda (ZP_CLEAR_PIXEL_PTR),y
	sta ZP_CELL+1

	lda #0					// clear pixel value
	ldy #0
	sta (ZP_CELL),y			// write to screen (assuming ZP_CELL is in screen ram, hopefully!)

	// -------- draw to screen ---- 

	// compute cell offset (relative to screen or color ram)
	Word_Copy(ZP_Y,ZP_CELL)
	Word_Mul_40(ZP_CELL)						// ZP_CELL(word) = 40*y		// NOTE: Mul_40 uses ZP_CELL+2,ZP_CELL+3
	Word_Add_Word(ZP_CELL, ZP_X, ZP_CELL)		// ZP_CELL = 40*y+x  

	Word_Add_Value(ZP_CELL,screen,ZP_CELL)			// ZP_CELL = screen ram cell
	
	// write character to screen ram
	lda ZP_COUNTER              // TODO: per bob
	lsr							// div by 2 so we compress 256 steps to 128 chars 
	clc
	adc #BOB_CHARSET_START 
	ldy #0						// must be zero
	sta (ZP_CELL),y				// store in screen ram

	// store pixel adress in history
	//ldy #0
	lda ZP_CELL
	sta (ZP_CLEAR_PIXEL_PTR),y
	lda ZP_CELL+1
	iny
	sta (ZP_CLEAR_PIXEL_PTR),y

	// increase pointer
	Word_Add_Value(ZP_CLEAR_PIXEL_PTR, 2, ZP_CLEAR_PIXEL_PTR) 
	Word_Compare_Value_X(ZP_CLEAR_PIXEL_PTR, clear_pixel_history+CLEAR_HISTORY_SIZE*2)
	bmi history_ptr_in_bounds
	Word_Store_Value(ZP_CLEAR_PIXEL_PTR, clear_pixel_history)
history_ptr_in_bounds:

	// write color to color ram
	Word_Add_Value(ZP_CELL, screen_colors - screen, ZP_CELL)	// ZP_CELL = color ram cell
	lda ZP_COLOR
	ldy #0
	sta (ZP_CELL),y				// store in color ram
	
skip:

    rts
}
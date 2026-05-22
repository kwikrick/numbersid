// simple text scroller
// will scroll text with a 2x2 character font
// (so two actuall screen lines)
// the font is created from the ROM font, scaled-up


#import "common/rasterirq_macros.asm"
#import "common/keyboard_macros.asm"
#import "common/vic_const.asm"
#import "common/cia_const.asm"
#import "common/word_macros.asm"
#import "common/gfx_macros.asm"

// ---

#import "text_scroll_macros.asm"

// -------- routines

textscroll_init: 
{
 	
    // ---- copy charset ----
    
    // disable timer interrupts from CIA1
    lda #127					// bit 0 low means clear all interupts for which other bits are high
	sta CIA1_ICR				// on CIA1 interrupt control register
	
    // switch CHAREN bit to 0
    lda IO_DATA
    and #~4
    sta IO_DATA
    
    //SRC=$D000
    lda #$00
    sta zp_src
    lda #$D0		
    sta zp_src+1
    
    // TGT=charset_addr
    lda #<charset_addr
    sta zp_tgt
    lda #>charset_addr
    sta zp_tgt+1
    
    // scale 64 chars
    ldx #0
loop_character:
	jsr scale_character
    Word_Add_Value(zp_src,8,zp_src)
    Word_Add_Value(zp_tgt,32,zp_tgt)
    inx
    cpx #64
    bne loop_character
  
    // switch CHAREN bit back to 1
    lda IO_DATA
    ora #4
    sta IO_DATA
    
    // restore timer IRQ? No need since i'm using raster
    
    //---  scale message  -----
    .const ROW1PTR = zp_free
    .const ROW2PTR = zp_free+2
    
    lda #<text_buffer_row1
    sta ROW1PTR
    lda #>text_buffer_row1
    sta ROW1PTR+1
    
    lda #<text_buffer_row2
    sta ROW2PTR
    lda #>text_buffer_row2
    sta ROW2PTR+1
    
    ldx #0
loop_text:
	lda text_data,x
	asl
	asl			// a=a*4
	ldy #0
	sta (ROW1PTR),y
	adc #1
	iny
	sta (ROW1PTR),y
	adc #1
	ldy #0
	sta (ROW2PTR),y
	adc #1
	iny
	sta (ROW2PTR),y
	Word_Add_Value(ROW1PTR,2,ROW1PTR)
	Word_Add_Value(ROW2PTR,2,ROW2PTR)
	inx
	//cpx #256
    bne loop_text
  
    
    // ---- setup VIC-II ----
    
    // hide first and last column (clear bit 4 of vic-ii control register 2)
    lda VIC_MODE2
    and #~VIC_MODE2_COLUMNS
    sta VIC_MODE2
    
    // choose charset addr using bit 1-3 VIC_ADDR (note bit 0 is always 1)
    lda VIC_ADDR
    and #~$F   	// clear low nybble
    ora #CHARSET*2+1
    sta VIC_ADDR
    
    // --- clear two rows of screen
    
	ldx #80
	lda #(32*4)			// char 32 (space) * 4
loop_clear:
	sta screen,x
	dex
	bne loop_clear
    
    // --- colorize the two lines --
    ldx #0
    lda #TEXT_COLOR
color_loop:
    sta color_row1,x
    sta color_row2,x
	inx
	cpx #40
	bne color_loop   
	
	// --- reset variables
	
	Word_Store_Value(text_offset,-1)		// ensures that on first update will be offset 0
	
	lda #0
	sta scroll_pos
    
	rts
}


//    // ----
//
//    InstallRasterIRQ_WithKernal(raster_irq_handler_startline, SCROLL_START_LINE)
//
//	WaitKey()
//	
//	RestoreRasterIRQ_WithKernal()
//	
//	rts
//}

// -----------

/*

raster_irq_handler_startline:
{
	RasterIRQBegin_WithKernal()	
	
	lda scroll_pos
	and #VIC_MODE2_HSCROLL
	sta VIC_MODE2
	
	RasterIRQNext_WithKernal(raster_irq_handler_endline, SCROLL_END_LINE)
}

raster_irq_handler_endline:
{
	RasterIRQBegin_WithKernal()	
	
	lda #4
	and #VIC_MODE2_HSCROLL
	sta VIC_MODE2
	
	RasterIRQNext_WithKernal(raster_irq_handler_compute, SCROLL_COMPUTE_LINE)
}

raster_irq_handler_compute:
{
	RasterIRQBegin_WithKernal()

	inc $d020
	
	// udpate scroll position
	dec scroll_pos
	dec scroll_pos		// double speed
	bpl cont
	
	// reset scroll and increment text offset
	lda #7
	sta scroll_pos
	Word_Inc(text_offset)
	Word_Compare_Value(text_offset,512)
	bne lt512
	Word_Store_Value(text_offset,0)
lt512:
	
	// scroll screen buffer
	ldx #0
loop:
	lda screen_row1+1,x
	sta screen_row1,x
	lda screen_row2+1,x
	sta screen_row2,x
	inx
	cpx #39						// 39 columns
	bne loop
	
	// copy text to last column on screen
	.const ROW1PTR = zp_free
    .const ROW2PTR = zp_free+2
    
    lda #<text_buffer_row1
    sta ROW1PTR
    lda #>text_buffer_row1
    sta ROW1PTR+1
    
    lda #<text_buffer_row2
    sta ROW2PTR
    lda #>text_buffer_row2
    sta ROW2PTR+1
    
    Word_Add_Word(ROW1PTR, text_offset, ROW1PTR)
    Word_Add_Word(ROW2PTR, text_offset, ROW2PTR)
    
	ldy #0
	lda (ROW1PTR),y
	sta screen_row1+39
	lda (ROW2PTR),y
	sta screen_row2+39
	
cont:
	
	dec $d020

	
	RasterIRQNext_WithKernal(raster_irq_handler_startline, SCROLL_START_LINE)
}
*/

// ------------

scale_character:
{
	// save X
	txa
	pha
	
	jsr scale_character_top_left
	jsr scale_character_top_right
	jsr scale_character_bottom_left
	jsr scale_character_bottom_right
	
	// restore X
	pla
	tax
	
	rts
}


scale_character_top_left:
{
	ldy #0			// y is index in src
	ldx #0			// x in index in tgt
loop:
	lda (zp_src),y
	sta zp_in
	jsr scale_left
	
	tya		// backup y
	pha
	
	txa
	tay	
	lda zp_out
	sta (zp_tgt),y
	iny 	
	sta (zp_tgt),y
	inx
	inx
	
	pla
	tay		// restore y
	
	iny
	cpy #4
	bne loop
	
	rts
}

scale_character_top_right:
{
	ldy #0			// y is index in src
	ldx #8			// x in index in tgt
loop:
	lda (zp_src),y
	sta zp_in
	jsr scale_right
	
	tya		// backup y
	pha
	
	txa
	tay	
	lda zp_out
	sta (zp_tgt),y
	iny 	
	sta (zp_tgt),y
	inx
	inx
	
	pla
	tay		// restore y
	
	iny
	cpy #4
	bne loop
	
	rts
}

scale_character_bottom_left:
{
	ldy #4			// y in index in src
	ldx #16			// x in index in tgt
loop:
	lda (zp_src),y
	sta zp_in
	jsr scale_left
	
	tya		// backup y
	pha
	
	txa
	tay	
	lda zp_out
	sta (zp_tgt),y
	iny 	
	sta (zp_tgt),y
	inx
	inx
	
	pla
	tay		// restore y
	
	iny
	cpy #8
	bne loop
	
	rts
}

scale_character_bottom_right:
{
	ldy #4			// y in index in src
	ldx #24			// x in index in tgt
loop:
	lda (zp_src),y
	sta zp_in
	jsr scale_right
	
	tya		// backup y
	pha
	
	txa
	tay	
	lda zp_out
	sta (zp_tgt),y
	iny 	
	sta (zp_tgt),y
	inx
	inx
	
	pla
	tay		// restore y
	
	iny
	cpy #8
	bne loop
	
	rts
}

// read zp_in (also modified)
// write zp_out
// scale left 4 pixels (high nybble) of input byte to fill output bytes 

scale_left:
{
	// temp
	//sta zp_out
	//rts

	txa
	pha
	
	lda #0
	sta zp_out

	
	ldx #4
	clc			// roll in zeroes
loop:
	lda zp_in
	and #$80
	beq zero
	
	lda zp_out
	ora #$1				// #3 for both pixels; 1 or 2 for alternating
	sta zp_out
	
zero:
	dex
	beq done
	
	asl zp_out
	asl zp_out
	asl zp_in
	
	jmp loop

done:
	pla
	tax
	rts

}


// read zp_in (also modified)
// write zp_out
// scale right 4 pixels (low nybble) of input byte to fill output bytes 

scale_right:
{
	// temp
	//sta zp_out
	//rts

	txa
	pha
	
	lda #0
	sta zp_out

	
	ldx #4
	clc			// roll in zeroes
loop:
	lda zp_in
	and #$1
	beq zero
	
	lda zp_out
	ora #$40			// $c0 for both pixels, $80 or $40 for alternating
	sta zp_out
	
zero:
	dex
	beq done
	
	lsr zp_out
	lsr zp_out
	lsr zp_in
	
	jmp loop

done:
	pla
	tax
	rts

	
}


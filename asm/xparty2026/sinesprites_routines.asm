 
#import "common/vic_const.asm"
#import "common/default_screen_const.asm"
#import "common/word_macros.asm"
#import "common/rasterirq_macros.asm"
#import "common/misc_macros.asm"

 sinesprites_init:
 {
    // TEMP: generate sprite data
    Fill(sprite_data1, 64, $FF) 

	// set inital phases for y axis (quarter cycle over x)
	lda #64
	ldy #0
loop_init_phases:
	sta phases+3,y		// y high
	iny
	iny
	iny
	iny
	cpy #32
	bne loop_init_phases

	// --- setup sprites
	ldy #0					// Y is sprite nr
    loop_setup_sprites:	
			// set spriteblock for this sprite
			lda #(sprite_data1 >> 6) 		// A is spriteblock nr 
			sta SPRBLK, y 
			// set color for this sprite
			tya						
			clc				// A is spritenr+1 used as color
			adc #1
			sta VIC_SPR0_COL, y
    		
			iny
    		cmp #8
    		bne loop_setup_sprites
    
    // enable all sprites
    lda #$FF
    sta VIC_SPR_EN

    rts
 }

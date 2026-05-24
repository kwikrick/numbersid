//  numberisid player

.cpu _6502

#import "common/word_macros.asm"
#import "common/io_macros.asm"
#import "common/keyboard_macros.asm"
#import "common/cia_const.asm"
#import "common/sid_const.asm"
#import "common/sid_macros.asm"
#import "common/cia_const.asm"
#import "common/rasterirq_macros.asm"
#import "common/misc_macros.asm"
#import "common/vic_const.asm"

#import "demo_zeropage.asm"

// -----------------------
// import generated header
// ----------------------- 

#import "generated_header.asm"

// -----------------------
//  consts and macros
// ----------------------- 

#import "numbersid_macros.asm"

#import "text_scroll_macros.asm"

#import "sinebob_macros.asm"

.const NUMBERSID_RASTER_LINE = 100
.const SINEBOB_RASTER_IRQ_LINE=150

.const NUM_FRAMES = 64		// must be power of 2 and <=256
.const FRAME_SIZE = 32		// bytes, must be power of 2 and <=256
.const FRAME_SIZE_SHIFT = 5	// must match frame size

.const DEBUG_FRAME_COUNT = false		// note: will switch character set; TODO: doesn't work when not using kernal int handler?


// -----------------------------------------
// -------------- Main section -------------
// -----------------------------------------

// generate basic start code

BasicUpstart2(main)

// main

*=* "Main"

main:
	
	// clear memory for variables, sequences, arrays, voice data, global data, etc.
	//Fill(clear_mem_start, clear_mem_end-clear_mem_start, 0)
	Fill(clear_mem_start, 8192, 0)		// compiler cannot compute, make a guess

	ClearScreen(screen, 32)
	lda #0
	sta $d020			// fg color
	lda #0
	sta $d021			// border color

	jsr textscroll_init

	// jsr sinebob_init

	jsr sinebob_init_charset

	BOB_INIT_PHASES()

	.if (DEBUG_FRAME_COUNT) {
		// switch CHAREN bit to 0
		lda IO_DATA
		and #~4
		sta IO_DATA

		Copy($D000, bob_charset_addr, 2048)

		// switch CHAREN bit back to 1
		lda IO_DATA
		ora #4
		sta IO_DATA

	}

	// for numbersid play

	SidReset()	
	
	// Set initial parameter values for voices and global parameters
	// note: generated functions
	jsr init_voice_parameter_values
	jsr init_global_parameter_values
	jsr init_sine_parameter_values
	
	// apply all initial parameter values
	// TODO do for all voices; loop should not be hardcoded
	//.for (var voice=0;voice<3;voice++) {   
	//.for (var channel=0;channel<3;channel++) {   
	lda #0
	sta ZP_VOICE
loop_init_voices:
		lda ZP_VOICE
		jsr set_voice		
		Apply_Voice_Parameter(Voice_Param_gate)
		Apply_Voice_Parameter(Voice_Param_note)
		Apply_Voice_Parameter(Voice_Param_scale)
		Apply_Voice_Parameter(Voice_Param_transpose)
		Apply_Voice_Parameter(Voice_Param_pitch)
		Apply_Voice_Parameter(Voice_Param_waveform)
		Apply_Voice_Parameter(Voice_Param_pulsewidth)
		Apply_Voice_Parameter(Voice_Param_sync)
		Apply_Voice_Parameter(Voice_Param_ring)
		Apply_Voice_Parameter(Voice_Param_attack)
		Apply_Voice_Parameter(Voice_Param_decay)
		Apply_Voice_Parameter(Voice_Param_sustain)
		Apply_Voice_Parameter(Voice_Param_release)
		Apply_Voice_Parameter(Voice_Param_filter)
		inc ZP_VOICE
		lda #3
		cmp ZP_VOICE
		bne loop_init_voices
	//}
	
	jsr set_global
	Apply_Global_Parameter(Global_Param_filter_mode)
	Apply_Global_Parameter(Global_Param_filter_cutoff)
	Apply_Global_Parameter(Global_Param_filter_resonance)
	Apply_Global_Parameter(Global_Param_volume)

	// init frame counters 
	// Note: not needed, all data is zeroed already at startup
	//Word_Store_Value(read_frame_counter, 0)
	//Word_Store_Value(write_frame_counter, 0)
	
	// copy frame counter to variable 'T' 
	//.encoding "ascii"
	//Word_Copy(write_frame_counter, variable_adress('T'))

	Word_Store_Value(read_frame_counter, -16)		// generate some frames before starting 		

	// mark all its dependencies dirty
	// Note this code must be generated! 84 is ascii for T 
	//jsr variable_changed_84	

	// run first update of sequences to apply initial parameter values to sid data
	// jsr update_sequences
	
	// --------------

	// start the raster interrupt handler
	InstallRasterIRQ_NoKernal(raster_irq_handler_startline, SCROLL_START_LINE)

	// main loop, handles keyboard input
	// and shows some text
	main_loop:

		// if write_frame >= read_frame+NUM_FRAMES-1, wait
		Word_Copy(read_frame_counter, ZP_FREE)
		Word_Add_Value(ZP_FREE, NUM_FRAMES-1, ZP_FREE)			// Note -1 is needed to prevent writing to currently read frame
		Word_Compare_Word_X(write_frame_counter, ZP_FREE)
		bpl main_loop

		// copy frame counter to variable 'T'
        .encoding "ascii"
        Word_Copy(write_frame_counter, variable_adress('T'))

        // mark all its dependencies dirty
        // Note this code must be generated! 84 is ascii for T 
        jsr variable_changed_84	

 		// magical computation!
        jsr update_sequences

		// copy sid_data to frame
		// ZP_FREE/ZP_F is pointer to frame
		lda write_frame_counter
		and #(NUM_FRAMES-1)
		sta ZP_FREE
		lda #0
		sta ZP_FREE+1
		Word_Shift_Left(ZP_FREE, FRAME_SIZE_SHIFT)
		Word_Add_Value(ZP_FREE, sid_frames, ZP_FREE)

		ldy #0
sid_frame_copy_loop:
		lda sid_data,y
		sta (ZP_FREE),y 
		iny
		cpy #25
		bne sid_frame_copy_loop

		// increase write frame counter
        Word_Inc(write_frame_counter)


	jmp main_loop


// ---------------------------
// -------IRQ handlers -------
// ---------------------------

raster_irq_handler_startline:
{
	RasterIRQBegin_NoKernal()	
	lda scroll_pos
	and #VIC_MODE2_HSCROLL
	sta VIC_MODE2

	ChooseCharacterSet(SCROLL_CHARSET)

	RasterIRQNext_NoKernal(raster_irq_handler_endline, SCROLL_END_LINE)
}

raster_irq_handler_endline:
{
	RasterIRQBegin_NoKernal()	

	inc $d020					// DEBUG
	// reset VIC hscroll to default
	lda #7
	and #VIC_MODE2_HSCROLL
	sta VIC_MODE2

	ChooseCharacterSet(BOB_CHARSET)		// default
	
	// udpate scroll position
	dec scroll_pos
	dec scroll_pos		// double speed
	bpl cont
	
	// reset scroll and increment text offset
	lda #7
	sta scroll_pos
	Word_Inc(text_offset)
	Word_Compare_Value_X(text_offset,512)
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
	.const ROW1PTR = ZP_IRQ
    .const ROW2PTR = ZP_IRQ+2
    
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

	dec $d020					// DEBUG
	RasterIRQNext_NoKernal(raster_irq_handler_numbersid, NUMBERSID_RASTER_LINE)

}

raster_irq_handler_numbersid:
{
		RasterIRQBegin_NoKernal()	

        inc $d020					// DEBUG
		// debug
		.if (DEBUG_FRAME_COUNT) {

			.encoding "screencode_upper"
			lda #'W'
			sta text_string
			WordToHex_Screen(write_frame_counter,text_string+1)
			StringToScreen(text_string, screen, 4,0)
			
			lda #'R'
			sta text_string
			WordToHex_Screen(read_frame_counter,text_string+1)
			StringToScreen(text_string, screen, 5,0)
		}

		// if read_frame < 0, do increment counter, but don't sound yet
		lda read_frame_counter+1
		bmi wait_for_frame_zero

		// if read_frame >= write_frame, wait 
		Word_Compare_Word_X(read_frame_counter, write_frame_counter)
		bcs wait_for_new_frame

		// copy frame data to sid
		// ZP_IRQ/ZP_IRQ+1 is pointer to frame
		lda read_frame_counter
		and #(NUM_FRAMES-1)
		sta ZP_IRQ
		lda #0
		sta ZP_IRQ+1
		Word_Shift_Left(ZP_IRQ, FRAME_SIZE_SHIFT)
		Word_Add_Value(ZP_IRQ, sid_frames, ZP_IRQ)

		ldy #0
sid_frame_copy_loop:
		lda (ZP_IRQ),y
		sta SID_BASE,y
		iny
		cpy #25 
		bne sid_frame_copy_loop

wait_for_frame_zero:

		Word_Inc(read_frame_counter)

wait_for_new_frame:

        dec $d020					// DEBUG

		RasterIRQNext_NoKernal(raster_irq_handler_sinebob, SINEBOB_RASTER_IRQ_LINE)
}

raster_irq_handler_sinebob:
{
	RasterIRQBegin_NoKernal()

	inc $D020			// DEBUG

	// --- compute sines

	ldy #0
loop_compute:

	// load phase
	lda phases,y	
	sta ZP_IRQ
	lda phases+1,y	
	sta ZP_IRQ+1
	
	// load freq
	lda freqs,y	
	sta ZP_IRQ+2
	lda freqs+1,y	
	sta ZP_IRQ+3
	
	// add freq to phase
	Word_Add_Word(ZP_IRQ,ZP_IRQ+2,ZP_IRQ)
	
	// store phase
	lda ZP_IRQ
	sta phases,y	
	lda ZP_IRQ+1
	sta phases+1,y	
	
	// get sine value
	// lda phases+1,y		// note: use high byte, divides word by 256
	tax
	lda sine_256_256,x
	sta ZP_IRQ
	
	// multiply by amplitude
	lda amplitudes,y			// note: only using low byte of amplitude
	sta ZP_IRQ+1

	Word_Mul_LoHi(ZP_IRQ)		// multiply sine * amplitude
	
	// divide by 128
	Unsigned_Shift_Right(ZP_IRQ, 7)
	
	// subtract amplitude
	lda amplitudes,y
	sta ZP_IRQ+2
	lda #0
	sta ZP_IRQ+3
	Word_Neg(ZP_IRQ+2, ZP_IRQ+2)
	Word_Add_Word(ZP_IRQ,ZP_IRQ+2,ZP_IRQ)
	
	// // add offset
	// lda offsets,y
	// sta ZP_IRQ+2
	// lda offsets+1,y
	// sta ZP_IRQ+3
	// Word_Add_Word(ZP_IRQ,ZP_IRQ+2,ZP_IRQ)
	
	// store
	lda ZP_IRQ
	sta positions,y
	lda ZP_IRQ+1
	sta positions+1,y
	
	iny
	iny
	cpy #NUM_SINES*2       // two bytes per sine
	beq end_loop_compute
	jmp loop_compute		// need long jump

end_loop_compute:

	//-----  add sines to compute X,Y for one bob ------ 
	.const ZP_X = ZP_IRQ+5		// word
	.const ZP_Y = ZP_IRQ+7		// word		

	Word_Store_Value(ZP_X,20)		// TODO: needs to be configarable
	Word_Store_Value(ZP_Y,13)

	ldx #0

loop_add_sines:

	lda positions+0,x		    
	sta ZP_IRQ
	lda positions+1,x	
	sta ZP_IRQ+1

	Word_Add_Word(ZP_X,ZP_IRQ,ZP_X)

	lda positions+2,x		    
	sta ZP_IRQ
	lda positions+3,x	
	sta ZP_IRQ+1

	Word_Add_Word(ZP_Y,ZP_IRQ,ZP_Y)
	inx
	inx
	inx
	inx
	cpx #NUM_SINES*2		// two bytes per sine
	bne loop_add_sines

	inc $D020       // DEBUG


	// ----- draw bobs on screen

	// TODO: should be a separate IRQ handler, run after line 200
	// note: compute time for sines is now unknown, determined by generated code)
	
	.const ZP_CELL = ZP_IRQ   		// word
	.const ZP_CELL_H = ZP_IRQ+1   		// word
	.const ZP_TEMP = ZP_IRQ+2			// note: used by Word_Mul_40 too
	.const ZP_TEMP_H = ZP_IRQ+3
	//.const ZP_COLOR = ZP_IRQ+4		// byte
	//.const ZP_CHAR = ZP_IRQ+6

	ldx #0					// X is index in positions
	//lda #1					// TODO: get color from a parameter
	//sta ZP_COLOR			
	//lda #0
	//sta ZP_CHAR			// TODO: increment char by some amount given by pamameter

	// TODO: modulo 25 easy to compute?
	Word_Compare_Value_Y(ZP_Y, 2)
	bmi skip1
	Word_Compare_Value_Y(ZP_Y, 25)
	bpl skip1
	bmi cont1

	// TODO: modulo 40 easy to compute?
	Word_Compare_Value_Y(ZP_X, 0)
	bmi skip1
	Word_Compare_Value_Y(ZP_X, 40)
	bpl skip1

	skip1:
	jmp skip
	cont1:

	// compute cell offset (relative to screen or color ram)
	Word_Copy(ZP_Y,ZP_CELL)
	Word_Mul_40(ZP_CELL)						// ZP_CELL(word) = 40*y		// NOTE: Mul_40 uses ZP_CELL+2,ZP_CELL+3
	Word_Add_Word(ZP_CELL, ZP_X, ZP_CELL)		// ZP_CELL = 40*y+x  

	Word_Add_Value(ZP_CELL,screen,ZP_CELL)			// ZP_CELL = screen ram cell
	
	lda read_frame_counter		// determine character from frame (TODO: make a parameter per bob)
	and #63
	adc #BOB_CHAR_START 

	ldy #0						// must be zero
	sta (ZP_CELL),y				// store in screen ram

	Word_Add_Value(ZP_CELL, screen_colors - screen, ZP_CELL)	// ZP_CELL = color ram cell

	lda bob_color_parameter_value
	//ldy #0
	sta (ZP_CELL),y				// store in color ram

skip:

	inc $D020    // DEBUG

	// ----- update charset

	jsr sinebob_update_transitions

	// -----

    // DEBUG
	dec $D020
	dec $D020
	dec $D020
		
	RasterIRQNext_NoKernal(raster_irq_handler_startline, SCROLL_START_LINE)
}

// ---- routines ------

*=* "Numbersid routines"

#import "numbersid_routines.asm"

*=* "Text scroll routines"

#import "text_scroll_routines.asm"

*=* "Sinebob routines"
#import "sinebob_routines.asm"

// ----------------------------------------
// ------------ data section --------------
// ----------------------------------------

*=* "Numbersid data"

#import "numbersid_data.asm"

*=* "Text scroll data"

#import "text_scroll_data.asm"

*=* "Sine sprite data"

#import "sinebob_data.asm"

*=* "Bob Charset data"

#import "character_data.asm"

// -------------------------------------
// ----------- generated code -----------
// -------------------------------------

*=* "Generated Code"

#import "generated_code.asm"

// --------------------------------------
// ------------variables ----------------
// --------------------------------------

// note: this is a virtual segment
// code should reset all to zero (or other default values)

clear_mem_start:

// ---- Charset data --- 

// chatset data, must be in $2000-$4000 range ($1000-$2000 VICII sees ROM charsset)
// and alligned to $400 bytes 

*=scroll_charset_addr "Charset Scroll" virtual
.fill 2048, random()*65536

*=bob_charset_addr "Charset Sinebob" virtual
.fill 2048, random()*65536


// ---- Sprite data --- 

// spite data, must be in $2000-$4000 range ($1000-$2000 VICII sees ROM charset)
// and alligned to 64 bytes

/*
.align 64
*=* "Sprites" virtual
sprite_data1:
.fill 64, random()*65536
*/

// ------

*=* "Text scroll variables" virtual

#import "text_scroll_variables.asm"

*=* "Numbersid variables" virtual

#import "numbersid_variables.asm"

*=* "Sine sprites variables" virtual

#import "sinebob_variables.asm"

*=* "Demo Variables" virtual
read_frame_counter: .word 0
write_frame_counter: .word 0
sid_frames: .fill NUM_FRAMES * FRAME_SIZE, 0

// TODO: debug only
text_string: .fill 40,32 ; .byte 0

clear_mem_end:

.var clear_mem_size = clear_mem_end - clear_mem_start
.print "Bytes to clear =  "+ clear_mem_size
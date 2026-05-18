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


// -----------------------
// import generated header
// ----------------------- 

#import "generated_header.asm"

// -----------------------
//  consts and macros
// ----------------------- 

#import "numbersid_macros.asm"

#import "text_scroll_macros.asm"

.const NUMBERSID_RASTER_LINE = 100
.const SINESRPITES_RASTER_IRQ_LINE=150

.const NUM_FRAMES = 64		// must be power of 2 and <=256
.const FRAME_SIZE = 32		// bytes, must be power of 2 and <=256
.const FRAME_SIZE_SHIFT = 5	// must match frame size

.const DEBUG_FRAME_COUNT = true		// note: will switch character set; TODO: doesn't work when not using kernal int handler?

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

	jsr textscroll_init

	jsr sinesprites_init

	// for numbersid play

	SidReset()	
	
	// Set initial parameter values for voices and global parameters
	// note: generated functions
	jsr init_voice_parameter_values
	jsr init_global_parameter_values

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

// Note: don't use ZP_FREE in the IRQ handlers; numbersid wull use those on main thread
// and numbersid will also use zero page up to $11 (currently)

.const ZP_IRQ = $16		// need 4 bytes for scroll handler, 5 for sinesprites
.const ZP_IRQ1 = $16
.const ZP_IRQ2 = $17
.const ZP_IRQ3 = $18
.const ZP_IRQ4 = $19
.const ZP_IRQ5 = $20

raster_irq_handler_startline:
{
.break
	RasterIRQBegin_NoKernal()	
	lda scroll_pos
	and #VIC_MODE2_HSCROLL
	sta VIC_MODE2

	.if (DEBUG_FRAME_COUNT) {
		ChooseCharacterSet(CHARSET)
	}

.break
	RasterIRQNext_NoKernal(raster_irq_handler_endline, SCROLL_END_LINE)
}

raster_irq_handler_endline:
{
	RasterIRQBegin_NoKernal()	
.break
	inc $d020					// DEBUG
	// reset VIC hscroll to default
	lda #4
	and #VIC_MODE2_HSCROLL
	sta VIC_MODE2


	.if (DEBUG_FRAME_COUNT) {
		ChooseCharacterSet(2)		// default
	}
	
	
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

.break
	dec $d020					// DEBUG
	RasterIRQNext_NoKernal(raster_irq_handler_numbersid, NUMBERSID_RASTER_LINE)

}

raster_irq_handler_numbersid:
{
		RasterIRQBegin_NoKernal()	
.break
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
			
			
			/*
			SetCursor(6,0)
			PrintChar('W')
			WordToHex(write_frame_counter,text_string)
			PrintString(text_string)
			PrintChar(13)
			PrintChar('R')
			WordToHex(read_frame_counter,text_string)
			PrintString(text_string)	
			*/		
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

.break
        dec $d020					// DEBUG

		RasterIRQNext_NoKernal(raster_irq_handler_sinesprites, SINESRPITES_RASTER_IRQ_LINE)
}

raster_irq_handler_sinesprites:
{
	RasterIRQBegin_NoKernal()
.break
	inc $D020			// DEBUG

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
	// lda phases+1,y		// note: divides word by 256
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
	
	// add offset
	lda offsets,y
	sta ZP_IRQ+2
	lda offsets+1,y
	sta ZP_IRQ+3
	Word_Add_Word(ZP_IRQ,ZP_IRQ+2,ZP_IRQ)
	
	// store
	lda ZP_IRQ
	sta positions,y
	lda ZP_IRQ+1
	sta positions+1,y
	
	iny
	iny
	cpy #32
	beq end_loop_compute
	jmp loop_compute		// need long jump

end_loop_compute:

	inc $D020       // DEBUG

	// update sprite
	ldy #0
	lda #0
	sta ZP_IRQ+4		// ZP_IRQ+4 spritenr
loop_move_sprite:
	 
	// ZP_IRQ(+1) = x
	lda positions,y
	sta ZP_IRQ
	lda positions+1,y
	sta ZP_IRQ+1
	// ZP_IRQ+2(+3) = y
	lda positions+2,y
	sta ZP_IRQ+2
	lda positions+3,y
	sta ZP_IRQ+3
	
	tya
	pha
	MoveSprite2(ZP_IRQ+4, ZP_IRQ, ZP_IRQ+2)
	pla
	tay
	
	inc ZP_IRQ+4
	iny
	iny
	iny
	iny
	cpy #32
	bne loop_move_sprite

	dec $D020    // DEBUG
.break
	dec $D020
		
	RasterIRQNext_NoKernal(raster_irq_handler_startline, SCROLL_START_LINE)
}

// ---- routines ------

*=* "Numbersid routines"

#import "numbersid_routines.asm"

*=* "Text scroll routines"

#import "text_scroll_routines.asm"

*=* "Sine sprite routines"

#import "sinesprites_routines.asm"


// ----------------------------------------
// ------------ data section --------------
// ----------------------------------------

*=* "Numbersid data"

#import "numbersid_data.asm"

*=* "Text scroll data"

#import "text_scroll_data.asm"

*=* "Sine sprite data"

#import "sinesprites_data.asm"

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

*=charset_addr "Charset" virtual
.fill 2048, random()*65536

// ---- Sprite data --- 

// spite data, must be in $2000-$4000 range ($1000-$2000 VICII sees ROM charset)
// and alligned to 64 bytes

.align 64
*=* "Sprites" virtual
sprite_data1:
.fill 64, random()*65536

// ------

*=* "Text scroll variables" virtual

#import "text_scroll_variables.asm"

*=* "Numbersid variables" virtual

#import "numbersid_variables.asm"

*=* "Sine sprites variables" virtual

#import "sinesprites_variables.asm"

*=* "Demo Variables" virtual
read_frame_counter: .word 0
write_frame_counter: .word 0
sid_frames: .fill NUM_FRAMES * FRAME_SIZE, 0

// TODO: debug only
text_string: .fill 40,32 ; .byte 0

clear_mem_end:

.var clear_mem_size = clear_mem_end - clear_mem_start
.print "Bytes to clear =  "+ clear_mem_size
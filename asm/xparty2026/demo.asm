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

.const NUMBERSID_RASTER_LINE = 150
.const NUM_FRAMES = 64		// must be power of 2 and <=256
.const FRAME_SIZE = 32		// bytes, must be power of 2 and <=256
.const FRAME_SIZE_SHIFT = 5	// must match frame size

.const DEBUG_FRAME_COUNT = true		// note: will switch character set

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
	InstallRasterIRQ_WithKernal(raster_irq_handler_startline, SCROLL_START_LINE)

	// main loop, handles keyboard input
	// and shows some text
	main_loop:

		// if write_frame >= read_frame+NUM_FRAMES, wait
		Word_Copy(read_frame_counter, ZP_FREE)
		Word_Add_Value(ZP_FREE, NUM_FRAMES-1, ZP_FREE)			// Note -1 is needed to prevent writing to currently read frame
		Word_Compare_Word(write_frame_counter, ZP_FREE)
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

.const ZP_IRQ = $16		// need 4 bytes for scroll handler


raster_irq_handler_startline:
{
	RasterIRQBegin_WithKernal()	

	lda scroll_pos
	and #VIC_MODE2_HSCROLL
	sta VIC_MODE2

	.if (DEBUG_FRAME_COUNT) {
		ChooseCharacterSet(CHARSET)
	}

	RasterIRQNext_WithKernal(raster_irq_handler_endline, SCROLL_END_LINE)
}

raster_irq_handler_endline:
{
	RasterIRQBegin_WithKernal()	

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
	
	RasterIRQNext_WithKernal(raster_irq_handler_numbersid, NUMBERSID_RASTER_LINE)

}

raster_irq_handler_numbersid:
{
		RasterIRQBegin_WithKernal()	

        inc $d020					// DEBUG

		// debug
		.if (DEBUG_FRAME_COUNT) {
			SetCursor(6,0)
			PrintChar('W')
			WordToHex(write_frame_counter,text_string)
			PrintString(text_string)
			PrintChar(13)
			PrintChar('R')
			WordToHex(read_frame_counter,text_string)
			PrintString(text_string)			
		}

		// if read_frame < 0, do increment counter, but don't sound yet
		Word_Compare_Value(read_frame_counter,0)
		.break
		bmi wait_for_frame_zero

		// if read_frame >= write_frame, wait 
		Word_Compare_Word(read_frame_counter, write_frame_counter)
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

		RasterIRQNext_WithKernal(raster_irq_handler_startline, SCROLL_START_LINE)
}

// ---- routines ------

*=* "Numbersid routines"

#import "numbersid_routines.asm"

*=* "Text scroll routines"

#import "text_scroll_routines.asm"

// ----------------------------------------
// ------------ data section --------------
// ----------------------------------------

*=* "Numbersid data"

#import "numbersid_data.asm"

*=* "Text scroll data"

#import "text_scroll_data.asm"

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

// TODO: move some data to zero_page for speed?

clear_mem_start:

*=* "Text scroll variables" virtual

#import "text_scroll_variables.asm"

*=* "Numbersid variables" virtual

#import "numbersid_variables.asm"

*=* "Demo Variables" virtual
read_frame_counter: .word 0
write_frame_counter: .word 0
sid_frames: .fill NUM_FRAMES * FRAME_SIZE, 0

// TODO: debug only
text_string: .fill 40,32 ; .byte 0

clear_mem_end:

.var clear_mem_size = clear_mem_end - clear_mem_start
.print "Bytes to clear =  "+ clear_mem_size
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

.const NUMBERSID_RASTER_LINE   = 90
.const SINEBOB_COMPUTE_RASTER_LINE = 110
.const SINEBOB_DRAW_RASTER_LINE   = 250

.const NUM_FRAMES = 64		// must be power of 2 and <=256
.const FRAME_SIZE = 32		// bytes, must be power of 2 and <=256
.const FRAME_SIZE_SHIFT = 5	// must match frame size

.const DEBUG_FRAME_COUNT = false
.const DEBUG_RASTER_IRQ_TIMES = true

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
	Fill(clear_mem_start, 24*1024, 0)		// compiler cannot compute, make a guess

	jsr textscroll_init_charset

	// for debug print, copy orginal charset to bob_charset
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
	
	// init sinebobs
	jsr sinebob_init_charset
	jsr sinebob_init_history
	jsr sinebob_compute_tables
	
	// TODO: needed? avoids pop at start?
	SidReset()	
	
	// Set initial parameter values for voices and global parameters
	// note: generated functions
	jsr init_voice_parameter_values
	jsr init_global_parameter_values
	jsr init_sine_parameter_values
	jsr init_bob_parameter_values

	
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
	
	// ---- setup screen last moment

	ClearScreen(screen, 32)
	lda #0
	sta $d020			// fg color
	lda #0
	sta $d021			// border color

	jsr textscroll_init_screen 

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

	.if (DEBUG_RASTER_IRQ_TIMES) {
		inc $d020
	}

	// reset VIC hscroll to default
	lda #7
	and #VIC_MODE2_HSCROLL
	sta VIC_MODE2

	ChooseCharacterSet(BOB_CHARSET)		// default
	
	jsr textscroll_update

	.if (DEBUG_RASTER_IRQ_TIMES) {
		dec $d020				
	}
	
	RasterIRQNext_NoKernal(raster_irq_handler_numbersid, NUMBERSID_RASTER_LINE)

}

raster_irq_handler_numbersid:
{
		RasterIRQBegin_NoKernal()	

		.if (DEBUG_RASTER_IRQ_TIMES) {
        	inc $d020
		}
		
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

		ldy #25
sid_frame_copy_loop:
		dey
		bmi end_sid_frame_copy_loop
		lda (ZP_IRQ),y
		sta SID_BASE,y
		clc
		bcc sid_frame_copy_loop
end_sid_frame_copy_loop:

wait_for_frame_zero:

		Word_Inc(read_frame_counter)

wait_for_new_frame:

		.if (DEBUG_RASTER_IRQ_TIMES) {
        	dec $d020
		}

		RasterIRQNext_NoKernal(raster_irq_handler_sinebob_compute, SINEBOB_COMPUTE_RASTER_LINE)
}

raster_irq_handler_sinebob_compute:
{
	RasterIRQBegin_NoKernal()

	// ---- compile time fix for NUM_SINES==0
	.if (NUM_SINES==0) {
		RasterIRQNext_NoKernal(raster_irq_handler_startline, SCROLL_START_LINE)
	}

	.if (DEBUG_RASTER_IRQ_TIMES) {
		inc $D020
	}

	jsr sinebob_compute


    .if (DEBUG_RASTER_IRQ_TIMES) {
		dec $D020
	}
		
	RasterIRQNext_NoKernal(raster_irq_handler_sinebob_draw, SINEBOB_DRAW_RASTER_LINE)
}


raster_irq_handler_sinebob_draw:
{
	RasterIRQBegin_NoKernal()

	.if (DEBUG_RASTER_IRQ_TIMES) {
		inc $D020
	}

	jsr sinebob_draw

	.if (DEBUG_RASTER_IRQ_TIMES) {
		inc $D020
	}

	jsr sinebob_update_transitions


    .if (DEBUG_RASTER_IRQ_TIMES) {
		dec $D020
		dec $D020
	}
		
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

.label clear_mem_start = scroll_charset_addr

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
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
	Fill(clear_mem_start, 1427, 0)		// compiler cannot compute, make a guess

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

	// init frame counter to 0
	Word_Store_Value(frame_counter, 0)
	
	// copy frame counter to variable 'T' 
	.encoding "ascii"
	Word_Copy(frame_counter, variable_adress('T'))

	// mark all its dependencies dirty
	// Note this code must be generated! 84 is ascii for T 
	jsr variable_changed_84	

	// run first update of sequences to apply initial parameter values to sid data
	// TODO: this is a big macro, invoked twice (see irq handler); 
	// move code to routine and jump, or avoid this update altogether (start frame=-1?)
	UpdateSequences()
	
	// --------------
	
	// start the raster interrupt handler
	InstallRasterIRQ_WithKernal(raster_irq_handler_startline, SCROLL_START_LINE)
		
	// main loop, handles keyboard input
	// and shows some text
	loop:
	jmp loop


// ---------------------------
// -------IRQ handlers -------
// ---------------------------

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

	inc $d020					// DEBUG
	
	// reset VIC hscroll to default
	lda #4
	and #VIC_MODE2_HSCROLL
	sta VIC_MODE2
	
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

	dec $d020					// DEBUG
	
	RasterIRQNext_WithKernal(raster_irq_handler_numbersid, NUMBERSID_RASTER_LINE)

}

raster_irq_handler_numbersid:
{
		RasterIRQBegin_WithKernal()	

        inc $d020					// DEBUG: next border color

        // copy sid_data to the chip
        .for(var i=0; i<25; i++) {
        	lda sid_data+i
        	sta SID_BASE+i
        }
        	
        // increase frame counter
        Word_Inc(frame_counter)

		// copy frame counter to variable 'T'
        .encoding "ascii"
        Word_Copy(frame_counter, variable_adress('T'))
    
        // mark all its dependencies dirty
        // Note this code must be generated! 84 is ascii for T 
        jsr variable_changed_84	

 		// magical computation!
        UpdateSequences()
        
        dec $d020					// DEBUG: previous border color
        
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

*=* "Demo Variables" virtual

clear_mem_start:

// application
frame_counter: .word 0

// TODO: debug only
text_string: .fill 40,32 ; .byte 0

*=* "Numbersid variables" virtual

// numbersid
#import "numbersid_variables.asm"

*=* "Text scroll variables" virtual

// text scroll
#import "text_scroll_variables.asm"

clear_mem_end:

.var clear_mem_size = clear_mem_end - clear_mem_start
.print "Bytes to clear =  "+ clear_mem_size
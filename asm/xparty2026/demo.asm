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

// -----------------------
// import generated header
// ----------------------- 

#import "generated_header.asm"

// -----------------------
// numbersaid consts and macros
// ----------------------- 

#import "numbersid_macros.asm"

// --------- misc macros -------

// -----------------------------------------
// -------------- code section -------------
// -----------------------------------------

// generate basic start code

BasicUpstart2(main)

// main

*=* "Main"

main:

	// clear memory for variables, sequences, arrays, voice data, global data, etc.
	//Fill(clear_mem_start, clear_mem_end-clear_mem_start, 0)
	Fill(clear_mem_start, $401, 0)		// compiler cannot compute, make a guess

	PrintClearScreen()
    
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
	
	// start the raster interrupt handler
	InstallRasterIRQ_WithKernal(raster_irq_handler, 50)
		
	// main loop, handles keyboard input
	// and shows some text
	loop:
	jmp loop

// -------end main -------

raster_irq_handler:
{
		// note: IRQ handler at $efff/$ffff pushes a,x,y registers
		// then call this handler (via vector $314/$315)
        asl $d019					// clear VIC-II raster scan interrupt flag
        
        inc $d020					// DEBUG: next border color

        // copy sid_data to the chip
        .for(var i=0; i<25; i++) {
        	lda sid_data+i
        	sta SID_BASE+i
        }
        
		// check for paused state
		lda paused
		bne skip_frame_update

        // increase frame counter
        Word_Inc(frame_counter)

skip_frame_update:

		Word_Compare_Word(frame_counter, variable_adress('T'))
		beq skip_mark_dirty
		// copy frame counter to variable 'T' 
		.encoding "ascii"

		// copy frame counter to variable 'T'
        .encoding "ascii"
        Word_Copy(frame_counter, variable_adress('T'))
    
        // mark all its dependencies dirty
        // Note this code must be generated! 84 is ascii for T 
        jsr variable_changed_84	
        
skip_mark_dirty:

 		// magical computation!
        UpdateSequences()
        
        dec $d020					// DEBUG: previous border color
        
        // jump to default interrupt handler (for keyboard handling)
		jmp $EA31
        
        // Note: default interrupt handler above will also pull stack and return from interrupt
        //pla							
        //tay							// 1 byte from stack to Y
        //pla
        //tax                         // 1 byte from stack to X
        //pla							// 1 byte from stack to A
        //rti                         
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

*=* "Variables" virtual

clear_mem_start:

// application
paused: .byte 0
frame_counter: .word 0
text_string: .fill 40,32 ; .byte 0

// numbersid
#import "numbersid_variables.asm"

// text scroll
#import "text_scroll_variables.asm"

clear_mem_end:

.var clear_mem_size = clear_mem_end - clear_mem_start
.print "Bytes to clear =  "+ clear_mem_size
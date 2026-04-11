//  numberisid player

.cpu _6502

#import "common/word_macros.asm"
#import "common/io_macros.asm"
#import "common/keyboard_macros.asm"
#import "common/cia_const.asm"
#import "common/sid_const.asm"
#import "common/sid_macros.asm"
#import "common/cia_const.asm"


// constants
.const debug = true

.const  MAX_SEQUENCES   = 16
.const  MAX_VARIABLES   = 26    // A-Z
.const  MAX_ARRAYS      = 8
.const  MAX_ARRAY_SIZE  = 16
.const  MAX_VOICES      = 8
.const  NUM_CHANNELS    = 3    // SID hardware channels

.const VOICE_SIZE		= 14*2					// 14 words = 28 bytes
.const SEQUENCE_SIZE	= 11*2 + 1				// 11 words + 1 byte = 23 bytes
.const ARRAY_SIZE   	= MAX_ARRAY_SIZE * 2	// word values

// for frequency table
.const FREQ_TABLE_LENGTH = 64
.const HIGHEST_SEMITONE = 38
.const LOWEST_SEMITONE = HIGHEST_SEMITONE-FREQ_TABLE_LENGTH

// ZP adresses
// TODO: SAFE WHEN PRINTING TEXT VIA KERNAL???  

.const ZP_PARAMETERS_PTR = $02		// WORD
.const ZP_CHANNEL = $04				// BYTE		
.const ZP_VOICE = $05				// BYTE	
.const ZP_ACCUMULATOR = $06 		// WORD
.const ZP_OPERAND = $08   			// WORD
.const ZP_SIDDATA_PTR = $10			// WORD


//.if (MAX_VOICES*VOICE_SIZE>256) {
//	.error "space for voice data exeeds 256 bytes"
//}

//.if (MAX_SEQUENCES*SEQUENCE_SIZE>256) {
//	.error "space for sequence data exeeds 256 bytes"
//}
//.if (MAX_ARRAYS*ARRAY_SIZE>256) {
//	.error "space for array data exeeds 256 bytes"
//}


// ---- some macros ---- 

.macro InstallRasterIRQHandler(irqhandler, rasterline)
{
        sei							// disable interrups
        lda #<irqhandler
        sta $0314					// set IRQ low byte
        lda #>irqhandler
        sta $0315					// set IRQ high byte
        asl $d019					// clear VIC-II interrupt flags ?
        lda #$7b					
        sta $dc0d					// CIA 1 interrupt control register, clear all interrupt masks
        lda #$81
        sta $d01a					// VIC-II raster scan interupt enable
        lda #$1b
        sta $d011					// VIC-II show screen, 25 rows, normal vertical position 
        lda #rasterline    					// raster line for interupt
        sta $d012					// VIC-II set raster lien for for interupt 
        cli							// enable interrupts        
}


.macro StopRasterIRQ()
{
		sei
	
    	lda #0
    	sta $d01a					// disable all vic interrupts
    
    	// install default IRQ handler
    	.const default_irq_handler = $EA31
    	lda #<default_irq_handler
		sta $0314					// set IRQ low byte
		lda #>default_irq_handler
		sta $0315					// set IRQ high byte
		
		// set cia interrupt enable for timer A
		lda #129
		sta CIA1_ICR
		
		cli
    
}

// --------- sequence evaluation  ------

// sum digits in base x
// accumulator_word: the input and output; word adress 
// base_word: the base (x) to use; word adress 
// uses zero-page: ZP_FREE;ZP_FREE+1
// (and affects most registers)
.macro Base_Sum(accumulator_word, base_word)
{
	Word_Copy(accumulator_word, ZP_FREE)
	Word_Store_Value(accumulator_word, 0)
	// TODO: first test always usign base 2
	ldx #15
loop:
	lda ZP_FREE
	and #1
	beq zero
one:
	Word_Inc(accumulator_word)
zero:
	Signed_Shift_Right(ZP_FREE,1)
	dex
	bne loop
}

// ----- 

.const Variable = 'V'
.const Number = 'N'
.const Voice_Param_gate = 0
.const Voice_Param_note = 1 
.const Voice_Param_scale = 2 
.const Voice_Param_transpose = 3
.const Voice_Param_pitch = 4
.const Voice_Param_waveform = 5 
.const Voice_Param_pulsewidth = 6 
.const Voice_Param_ring = 7
.const Voice_Param_sync = 8 
.const Voice_Param_attack = 9 
.const Voice_Param_decay = 10 
.const Voice_Param_sustain = 11 
.const Voice_Param_release = 12 
.const Voice_Param_filter = 13 

.const Global_Param_filter_mode = 0
.const Global_Param_filter_cutoff = 1
.const Global_Param_filter_resonance = 2
.const Global_Param_volume = 3


.encoding "ascii"
.function variable_adress(variable) {
	.return variable_values+(variable-'A')*2
}

.function voice_parameter_value_adress(voice, parameter) {
	.return voice_parameter_values + (voice * 16 + parameter)*2
}

// not used
//.function voice_parameter_dirty_adress(voice, parameter) {
//	.return voice_parameter_dirty + (voice * 16 + parameter)
//}


.macro Load_Accumulator(type,varonum) 
{
	.if (type == Number) {
		Word_Store_Value(ZP_ACCUMULATOR, varonum)
		.print("Load_Accumulator "+type+varonum)
	}
	.if (type == Variable) {
		.encoding "ascii"
		Word_Copy(variable_adress(varonum), ZP_ACCUMULATOR)
		.print("Load_Accumuator "+type+(varonum-'A'))
	}
	.if (false) {
		PrintChar('L')
		WordToHex(ZP_ACCUMULATOR,text_string)
		PrintString(text_string)
		PrintChar(32)
	}
}


.macro Load_Operand(type,varonum) 
{
	.if (type == Number) {
		Word_Store_Value(ZP_OPERAND, varonum)
		.print("Load_Operand "+type+varonum)
	}
	.if (type == Variable) {
		Word_Copy(variable_adress(varonum), ZP_OPERAND)
		.print("Load_Operand "+type+(varonum-'A'))
	}
}

.macro Eval_Add(type, varonum)
{
	Load_Operand(type, varonum)
	Word_Div_Word(ZP_ACCUMULATOR, ZP_OPERAND, ZP_ACCUMULATOR)		// TODO: jsr to save space
}

.macro Eval_Mul(type, varonum)
{
	Load_Operand(type, varonum)
	Word_Mul_Word(ZP_ACCUMULATOR, ZP_OPERAND, ZP_ACCUMULATOR)		// TODO: jsr to save space
}

.macro Eval_Mod(type, varonum)
{
	Load_Operand(type, varonum)
	Word_Div_Word(ZP_ACCUMULATOR, ZP_OPERAND, ZP_FREE)		// TODO: jsr to save space
	Word_Copy(ZP_FREE, ZP_ACCUMULATOR)
}

.macro Eval_Div(type, varonum)
{
	Load_Operand(type, varonum)
	Word_Div_Word(ZP_ACCUMULATOR, ZP_OPERAND, ZP_FREE)		// TODO: jsr to save space
}


.macro Eval_Base(type,varonum) {
	Load_Operand(type, varonum)
	Base_Sum(ZP_ACCUMULATOR, ZP_OPERAND)					// TODO: jsr to save space
}

.macro Store_Accumulator(variable) {
  Word_Copy(ZP_ACCUMULATOR, variable_adress(variable))
  .print("Store_Accumulator "+(variable-'A'))
  
  .if (false) {
		PrintChar(variable)
		WordToHex(ZP_ACCUMULATOR,text_string)
		PrintString(text_string)
		PrintChar(32)
	}
}


.macro Compare_Accumulator(variable) {
  Word_Compare_Word(ZP_ACCUMULATOR, variable_adress(variable))
}

.macro Mark_Variable_Dirty(variable) {
	// TODO: not needed?
}

.macro Mark_Sequence_Dirty(sequence_index) {
	lda #1
	ldx #sequence_index
	sta sequence_dirty,x
}

.macro Mark_Sequence_Clean(sequence_index) {
	lda #0
	ldx #sequence_index
	sta sequence_dirty,x
}

.macro Apply_Voice_Parameter(parameter)
{
	.if (parameter==Voice_Param_gate) {
		jsr apply_gate
	}
	.if (parameter==Voice_Param_note) {
		jsr apply_note
	}
	.if (parameter==Voice_Param_scale) {
		jsr apply_scale
	}
	.if (parameter==Voice_Param_transpose) {
		jsr apply_transpose
	}
	.if (parameter==Voice_Param_pitch) {
		jsr apply_pitch
	}
	.if (parameter==Voice_Param_waveform) {
		jsr apply_waveform
	}
	.if (parameter==Voice_Param_pulsewidth) {
		jsr apply_pulsewidth
	}
	.if (parameter==Voice_Param_ring) {
		jsr apply_ring
	}
	.if (parameter==Voice_Param_sync) {
		jsr apply_ring
	}
	.if (parameter==Voice_Param_attack) {
		jsr apply_attack
	}
	.if (parameter==Voice_Param_decay) {
		jsr apply_decay
	}
	.if (parameter==Voice_Param_sustain) {
		jsr apply_sustain
	}
	.if (parameter==Voice_Param_release) {
		jsr apply_release
	}
	.if (parameter==Voice_Param_filter) {
		jsr apply_filter
	}
}


.macro Apply_Global_Parameter(parameter)
{
	.if (parameter==Global_Param_filter_mode) {
		jsr apply_filter_mode
	}
	.if (parameter==Global_Param_filter_cutoff) {
		jsr apply_filter_cutoff
	}
	.if (parameter==Global_Param_filter_resonance) {
		jsr apply_filter_resonance
	}
	.if (parameter==Global_Param_volume) {
		jsr apply_volume
	}
}

.macro Apply_Variable_To_Voice_Parameter(variable, voice, parameter) {
	lda #voice
	jsr set_voice
	
	.if (false) {
		SetCursor(voice+7,0)
		PrintChar('&')
		WordToHex(ZP_PARAMETERS_PTR,text_string)
		PrintString(text_string)
		PrintChar(32)
		
		PrintChar('*')
		WordToHex(ZP_SIDDATA_PTR,text_string)
		PrintString(text_string)
		PrintChar(32)
		
	}
	
	ldx #variable-'A'
	ldy #parameter
	
	jsr copy_from_variable_in_x_to_voice_parameter_in_y
	
	Apply_Voice_Parameter(parameter)

}


.macro Apply_Variable_To_Global_Parameter(variable, parameter) {
	jsr set_global
	ldx #variable-'A'
	ldy #parameter
	
	jsr copy_from_variable_in_x_to_global_parameter_in_y
	
	Apply_Global_Parameter(parameter)
}
// --------- sequence ------

// update all sequences

.macro UpdateSequences() {
	 .if (debug) {
		SetCursor(4,0)
	}
	
	// loop over jump table
	ldx #0
loop:
	// check sequence dirty
	lda sequence_dirty,x
	beq skip
	// clear mark
	lda #0
	sta sequence_dirty,x
	// push x
	txa
	pha
	// indirect subroutine jump usign RTS!
	// push (return adress -1) on stack  (order hi-lo) 
	lda #>(return_adress-1)
	pha
	lda #<(return_adress-1)
	pha
	// push jump adress on stack (hi-lo) 
	txa 
	asl		// mul x by 2 for word index
	tay
	lda sequence_eval_table+1,y
	pha
	lda sequence_eval_table,y
	pha		
	// indirect jump
	rts
return_adress:
	// pull x
	pla
	tax
skip:
	// increment and compare to size of table
	inx
	txa
	cmp sequence_eval_count
	bne loop
}

// --------- misc macros -------

// fill an array with max 255 bytes
.macro FillX(adress, size, value) {
	.if (size>255) {
		.error "FillX cannot fille more than 255 bytes" 
	}
	
	lda #value
	ldx #size
loop:
	sta adress,x
	dex
	bne loop
}

.macro FillXY(adress, size, value) 
{
	.if (size>65535) {
		.error "FillXY cannot fille more than 65535 bytes" 
	}
	ldy #>size
	lda #value
loopY:
	ldx #<size
loopX:
	sta adress,x
	dex
	bne loopX
	dey
	bne loopY
}

// -------------- code section -------------

// generate basic start code

BasicUpstart2(main)

// main

*=* "Main"

main:


	// clear memory for variables, sequences, arrays, voice data, global data, etc.
	//FillXY(clear_mem_start, clear_mem_end-clear_mem_start, 0)
	FillXY(clear_mem_start, $1000, 0)		// compilor cannot compute, guess

	PrintClearScreen()
    
    SetCursor(2,0)
    
	PrintString(help_string)
	
    Word_Store_Value(frame_counter,0)
    
	SidReset()
	
	// SidSetVolumeConst(15)
	
	// clear sid data (25 bytes)
	
	lda #0
	ldx #25
clear_sid_data_loop:
	sta sid_data,x
	dex
	bne clear_sid_data_loop	

	// test code 	

	// set volume (clear filters)
	lda #15
	sta sid_data+SID_FILTER_VOLUME

/*
	// set a frequency for voice 0
	lda #0
	sta sid_data+SID_V1+SID_FREQ_L
	lda #40
	sta sid_data+SID_V1+SID_FREQ_H
	
	// voice 0, set attack, decay, sustain, release
	lda #(0|2<<4)   // decay, attack
	sta sid_data+SID_V1+SID_ATT_DEC
	lda #(1|15<<4) 	// release, sustain
	sta sid_data+SID_V1+SID_SUS_REL
	
	// voice 1, set attack, decay, sustain, release
	lda #(0|2<<4)   // decay, attack
	sta sid_data+SID_V2+SID_ATT_DEC
	lda #(1|15<<4) 	// release, sustain
	sta sid_data+SID_V2+SID_SUS_REL
	
	// voice , set attack, decay, sustain, release
	lda #(0|2<<4)   // decay, attack
	sta sid_data+SID_V3+SID_ATT_DEC
	lda #(1|15<<4) 	// release, sustain
	sta sid_data+SID_V3+SID_SUS_REL

	// vocie 0, set waveform
	lda #SID_CR_TRI
	sta sid_data+SID_V1+SID_CR
	
	// set pulse width 
	lda #0 
	sta sid_data+SID_PW_L
	lda #1
	sta sid_data+SID_PW_H
	
	// start a note (set bit 0)
	lda sid_data+SID_V1+SID_CR
	ora #1
	sta sid_data+SID_V1+SID_CR
*/	
	
	// note: generated function
	jsr init_voice_parameter_values
	jsr init_global_parameter_values
	
	// apply all initial parameter values
	// TODO do for all voices; loop should not be hardcoded
	//.for (var voice=0;voice<3;voice++) {   
	.for (var channel=0;channel<3;channel++) {   
		lda #channel
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
	}
	
	jsr set_global
	Apply_Global_Parameter(Global_Param_filter_mode)
	Apply_Global_Parameter(Global_Param_filter_cutoff)
	Apply_Global_Parameter(Global_Param_filter_resonance)
	Apply_Global_Parameter(Global_Param_volume)
		
	InstallRasterIRQHandler(raster_irq_handler, 50)
		
	loop:

			WaitKey()			// ascii code in A
			//pha
			//SetCursor(4,0)
			//pla
			//jsr CHROUT
			
			.encoding "petscii_upper"
			cmp #'Q'
			beq quit
			
			jmp loop
		
	quit:
		
	StopRasterIRQ()
	
	// return to basic
	rts
	
raster_irq_handler:
{
		// note: IRQ handler at $efff/$ffff pushes a,x,y registers
		// then call this handler (via vector $314/$315)
        asl $d019					// clear VIC-II raster scan interrupt flag
        
        inc $d020					// DEBUG: next border color
        
        // copy frame counter to variable 'T'
        .encoding "ascii"
        Word_Copy(frame_counter, variable_adress('T'))
        
        // mark all its dependencies dirty
        // Note this code must be generated! 84 is ascii for T 
        jsr variable_changed_84	
        
        // magical computation!
        UpdateSequences()
        
        // copy sid_data to the chip
        .for(var i=0; i<25; i++) {
        	lda sid_data+i
        	sta SID_BASE+i
        }
        
        // increase frame counter
        Word_Inc(frame_counter)
        
        // show in top left
        WordToHex(frame_counter,text_string)
        SetCursor(0,0)
        PrintString(text_string)
        
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

// ---- routines  -----

// input: A
// 
// output: 
// ZP_VOICE
// ZP_CHANNEL
// ZP_PARAMETERS_PTR (word) = zp_voice_parameter_values+(ZP_VOICE*16+0)*2
// ZP_SIDDATA_PTR (word) = sid_data + ZP_CHANNEL*7
// 
set_voice:
{
	sta ZP_VOICE

	// compute_voice_parameters_offset:
	asl
	asl
	asl
	asl
	asl					// a = ZP_VOICE * 32		// note: max 8 voices
	sta ZP_PARAMETERS_PTR
	lda #0
	sta ZP_PARAMETERS_PTR+1
	Word_Add_Value(ZP_PARAMETERS_PTR, voice_parameter_values, ZP_PARAMETERS_PTR)

	// TODO: get channel; for now we just copy
	lda ZP_VOICE	
	sta ZP_CHANNEL
	
	// compute ZP_SIDDATA_PTR from ZP_CHANNEL
	lda ZP_CHANNEL
	asl
	tax							// x = channel*2 (word index)
	lda zp_data_table,x
	sta ZP_SIDDATA_PTR
	lda zp_data_table+1,x
	sta ZP_SIDDATA_PTR+1

	rts
zp_data_table:
	.word sid_data+0, sid_data+7, sid_data+14
}


// output: 
// ZP_PARAMETERS_PTR (word) = zp_global_parameter_values
// ZP_SIDDATA_PTR (word) = sid_data
set_global:
{
	lda #<sid_data
	sta ZP_SIDDATA_PTR
	lda #>sid_data
	sta ZP_SIDDATA_PTR+1

	lda #<global_parameter_values
	sta ZP_PARAMETERS_PTR
	lda #>global_parameter_values
	sta ZP_PARAMETERS_PTR+1
	
	rts
}

// input: 
//   variable in x
//   parameter in y
//   ZP_PARAMETERS_PTR  (set by set_voice)
// result:
//  reads from variable_values
//  writes to voice_parameter_values
copy_from_variable_in_x_to_voice_parameter_in_y:
{
	txa
	asl
	tax					// x = variable*2
	
	tya					
	asl					
	tay					// y = parameter*2
	
	lda variable_values,x
	sta (ZP_PARAMETERS_PTR),y
	lda variable_values+1,x
	iny
	sta (ZP_PARAMETERS_PTR),y
	rts
}

// input: 
//   variable in x
//   global parameter in y
//   ZP_PARAMETERS_PTR  (set by set_global)
// result:
//  reads from variable_values
//  writes to global_parameter_values
copy_from_variable_in_x_to_global_parameter_in_y:
{
	txa
	asl
	tax					// x = variable*2
	
	tya					
	asl					
	tay					// y = parameter*2
	
	lda variable_values,x
	sta (ZP_PARAMETERS_PTR),y
	lda variable_values+1,x
	iny
	sta (ZP_PARAMETERS_PTR),y
	rts
}

// inputs:
// ZP_PARAMETERS_PTR (computed with compute_voice_parameters_offset)
// ZP_SID_DATA_PTR
// ouput: 
// writes to sid_data
apply_gate:
{	
	ldy #Voice_Param_gate*2
	lda (ZP_PARAMETERS_PTR),y
	and #1
	sta ZP_FREE				// ZP_FREE = gate 0 or 1
	
	ldy #SID_CR
	lda (ZP_SIDDATA_PTR),y		// load from sid_data
	and #~1						// clear bit 0
	ora ZP_FREE					// set gate
	sta (ZP_SIDDATA_PTR),y		// save to sid_data  
	
	rts
}
 apply_note:
 {
	ldy #Voice_Param_note*2
	lda (ZP_PARAMETERS_PTR),y
	sta ZP_FREE
	iny
	lda (ZP_PARAMETERS_PTR),y
	sta ZP_FREE+1
	Word_Add_Value(ZP_FREE, -LOWEST_SEMITONE, ZP_FREE)
	lda ZP_FREE
	asl  // word index
	tax
	lda freq_table,x
	ldy #SID_FREQ_L
	sta (ZP_SIDDATA_PTR),y	
	lda freq_table+1,x
	ldy #SID_FREQ_H
	sta (ZP_SIDDATA_PTR),y
	
 	rts
 }
 
 apply_scale:
 {
 	rts
 }
 apply_transpose:
 {
 	rts
 }
 apply_pitch:
 {
 	rts
 }
 apply_waveform:
 {
	ldy #Voice_Param_waveform*2
	lda (ZP_PARAMETERS_PTR),y
	asl
	asl
	asl
	asl					// shift left 4 
	sta ZP_FREE
	
	ldy #SID_CR
	lda (ZP_SIDDATA_PTR),y		// load from sid_data
	and #~$F0					// clear upper for bits 
	ora ZP_FREE					// set waveform
	sta (ZP_SIDDATA_PTR),y		// save to sid_data 
	
	rts
 }
 
 apply_pulsewidth:
 {
	ldy #Voice_Param_pulsewidth*2
	lda (ZP_PARAMETERS_PTR),y
	sta ZP_FREE
	iny
	lda (ZP_PARAMETERS_PTR),y
	sta ZP_FREE+1

	lda ZP_FREE
	ldy #SID_PW_L
	sta (ZP_SIDDATA_PTR),y
	lda ZP_FREE+1
	ldy #SID_PW_H
	sta (ZP_SIDDATA_PTR),y
	
	rts
 }

 apply_ring:
 {
 	ldy #Voice_Param_ring*2
	lda (ZP_PARAMETERS_PTR),y
	and #1
	asl 
	asl
	sta ZP_FREE				// ZP_FREE = ring, 0 or 1 in bit 2
	
	ldy #SID_CR
	lda (ZP_SIDDATA_PTR),y		// load from sid_data
	and #~4						// clear bit 2
	ora ZP_FREE					// set bit 2
	sta (ZP_SIDDATA_PTR),y		// save to sid_data  

	rts
 }

 apply_sync:
 {
	ldy #Voice_Param_sync*2
	lda (ZP_PARAMETERS_PTR),y
	and #1
	asl 
	sta ZP_FREE				// ZP_FREE = sync, 0 or 1 in bit 2
	
	ldy #SID_CR
	lda (ZP_SIDDATA_PTR),y		// load from sid_data
	and #~2						// clear bit 1
	ora ZP_FREE					// set bit 1
	sta (ZP_SIDDATA_PTR),y		// save to sid_data  

 	rts
 }

 apply_attack:
 {
 	ldy #Voice_Param_attack*2
	lda (ZP_PARAMETERS_PTR),y
	asl
	asl
	asl
	asl					// shift left 4 
	sta ZP_FREE
	
	ldy #SID_ATT_DEC
	lda (ZP_SIDDATA_PTR),y		// load from sid_data
	and #~$F0					// clear upper for bits 
	ora ZP_FREE					// set attack
	sta (ZP_SIDDATA_PTR),y		// save to sid_data  
	
	rts
 }

 apply_decay:
 {
 	ldy #Voice_Param_decay*2
	lda (ZP_PARAMETERS_PTR),y
	and #$0F					// mask lower 4 bits
	sta ZP_FREE
	
	ldy #SID_ATT_DEC
	lda (ZP_SIDDATA_PTR),y		// load from sid_data
	and #~$0F					// clear lower 4 bits 
	ora ZP_FREE					// set decay
	sta (ZP_SIDDATA_PTR),y		// save to sid_data  
	
	rts
 }

 apply_sustain:
 {
	ldy #Voice_Param_sustain*2
	lda (ZP_PARAMETERS_PTR),y
	asl
	asl
	asl
	asl					// shift left 4 
	sta ZP_FREE
	
	ldy #SID_SUS_REL
	lda (ZP_SIDDATA_PTR),y		// load from sid_data
	and #~$F0					// clear upper for bits 
	ora ZP_FREE					// set sustain
	sta (ZP_SIDDATA_PTR),y		// save to sid_data  
	
	rts
 }

 apply_release:
 {
 	ldy #Voice_Param_release*2
	lda (ZP_PARAMETERS_PTR),y
	and #$0F					// mask lower 4 bits
	sta ZP_FREE
	
	ldy #SID_SUS_REL
	lda (ZP_SIDDATA_PTR),y		// load from sid_data
	and #~$0F					// clear lower 4 bits 
	ora ZP_FREE					// set release
	sta (ZP_SIDDATA_PTR),y		// save to sid_data  
	
	rts
 }

 apply_filter:
 {
 	ldy #Voice_Param_filter*2
	lda (ZP_PARAMETERS_PTR),y
	and #$01					// mask bit 0
	beq zero

//one:
	lda ZP_CHANNEL
	tax
	lda masks1,x
	sta ZP_FREE			// ZP_FREE contains 1,2 or 4

	ldy #SID_FILTER_RES_VOICE
	lda sid_data,y		// load from sid_data
	ora ZP_FREE			// set bits from mask
	sta sid_data,y		// save to sid_data  

	rts
zero:
	lda ZP_CHANNEL
	tax
	lda masks0,x
	sta ZP_FREE			// ZP_FREE contains 1,2 or 4

	ldy #SID_FILTER_RES_VOICE
	lda sid_data,y		// load from sid_data
	and ZP_FREE			// clear bits from mask
	sta sid_data,y		// save to sid_data  
	
	rts

masks1:
	.byte 1,2,4
masks0:
	.byte ~1,~2,~4
 }

 apply_filter_mode:
 {
	ldy #Global_Param_filter_mode*2
	lda (ZP_PARAMETERS_PTR),y
	asl
	asl
	asl
	asl								// shift left 4
	sta ZP_FREE

	ldy #SID_FILTER_VOLUME
	lda sid_data,y				// load from sid_data
	and #$0F					// clear upper 4 bits
	ora ZP_FREE					// set filter mode
	sta sid_data,y				// save to sid_data

 	rts
 }

 apply_filter_cutoff:
 {
 	ldy #Global_Param_filter_cutoff*2
	lda (ZP_PARAMETERS_PTR),y
	sta ZP_FREE
	iny
	lda (ZP_PARAMETERS_PTR),y
	sta ZP_FREE+1

	ldy #SID_FILTER_L
	lda ZP_FREE
	sta sid_data,y				// save low byte to sid_data
	lda ZP_FREE+1
	ldy #SID_FILTER_H
	sta sid_data,y				// save high byte to sid_data

	rts
 }

 apply_filter_resonance:
 {
 	ldy #Global_Param_filter_resonance*2
	lda (ZP_PARAMETERS_PTR),y
	asl
	asl
	asl
	asl								// shift left 4
	sta ZP_FREE

	ldy #SID_FILTER_RES_VOICE
	lda sid_data,y				// load from sid_data
	and #$0F					// clear upper 4 bits
	ora ZP_FREE					// set filter mode
	sta sid_data,y				// save to sid_data

 	rts
 }

 apply_volume:
 {
 	ldy #Global_Param_volume*2
	lda (ZP_PARAMETERS_PTR),y
	and #$0F					// mask lower 4 bits
	sta ZP_FREE

	ldy #SID_FILTER_VOLUME
	lda sid_data,y				// load from sid_data
	and #$F0					// clear lower 4 bits
	ora ZP_FREE					// set volume bits
	sta sid_data,y				// save to sid_data

	rts
 }
 
// ----------------------------------------
// ------------ data section --------------
// ----------------------------------------

*=* "Frequency table"
/*
# freq table
def note_freq(base, semitones):
    return base*pow(2, semitones/12)
 

# for SID
def sid_value_pal(freq):
    return int(freq * 17.0309)

# SID freq table
#  with semitone 0 at base 440, +37 is the max (<65536). Low end usefulness?
for semitone in range(38-64,38):
    f=note_freq(440,semitone)
    print("{0}\t{1}\t{2}".format(semitone, f, sid_value_pal(f)))  
*/

.function note_freq(base, semitone)
{
	.return base * pow(2, semitone/12)
}

.function sid_freq_pal(freq) {
    // note: 16.40426  for NTSC
	.return floor(freq * 17.034) 
}

.for (var i=0;i<FREQ_TABLE_LENGTH;i++) {
	.var f = sid_freq_pal(note_freq(440, i+LOWEST_SEMITONE))
	//.print f
}

// table with SID frequency register values. Index 0 is the lowest semitone, and middle C (440HZ) is at index 0+lowest_semitone 

freq_table:
.fillword FREQ_TABLE_LENGTH, sid_freq_pal(note_freq(440, i+LOWEST_SEMITONE))



*=* "Application Data"

.encoding "petscii_upper"
help_string: .text "NUMBERSID PLAYER - PRESS Q TO QUIT"; .byte 0

// -------------------------------------
// ----------- generated code -----------
// -------------------------------------

*=* "Generated Code"

#import "generated.asm"

// --------------------------------------
// ------------variables ----------------
// --------------------------------------

// note: this is a virtual segment
// code should reset all to zero (or other default values)

*=* "Variables" virtual

clear_mem_start:

frame_counter: .word 0
text_string: .fill 40,32 ; .byte 0
sid_data: .fill 25, 0

.label sid_filter_l = sid_data+SID_FILTER_L
.label sid_filter_h = sid_data+SID_FILTER_H
.label sid_filter_res_voice = sid_data+SID_FILTER_RES_VOICE
.label sid_filter_volume = sid_data+SID_FILTER_VOLUME


	// TODO: move sid_data to zero_page?

// the values of the variables used in the numbersid sequences
variable_values:
.fillword MAX_VARIABLES, 0

sequence_dirty:
.fill MAX_SEQUENCES, 0

voice_parameter_values:
.fill MAX_VOICES * 16 * 2, 0			// reserve 16 words per voice; faster to compute by 4xlshift

global_parameter_values:
filter_mode_parameter_value: .word 0
filter_cutoff_parameter_value: .word 0
filter_resonance_parameter_value: .word 0
volume_parameter_value: .word 0

clear_mem_end:

// TODO: not used?
/*

voice_parameter_dirty:
.fill MAX_VOICES * 16, 0 				// reserve 16 words per voice; faster to compute by 4xlshift

variable_dirty:
.fill MAX_VARIABLES, 0
	
num_voices: .byte 0

channel_voices_start_ptr: .word 0				// pointer to start of channel-voice data (3 varonums)
										// followed by filter and volume (4 varonums)
num_sequences: .byte 0

sequence_data_start_ptr: .word 0		// pointer to start of sequence data 
 
sequence_data_cur_ptr: .word 0			// pointer to currently processing sequence data 

*/
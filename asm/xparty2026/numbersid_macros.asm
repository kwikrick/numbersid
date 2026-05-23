// macros for numbersid
#importonce 

#import "common/word_macros.asm"
#import "common/io_macros.asm"
#import "common/keyboard_macros.asm"
#import "common/cia_const.asm"
#import "common/sid_const.asm"
#import "common/sid_macros.asm"
#import "common/cia_const.asm"

// consts used by numbersid

.const  MAX_VARIABLES   = 26    // A-Z
.const  MAX_SEQUENCES   = 16
.const  MAX_VOICES      = 8
.const  MAX_ARRAYS      = 8
.const  MAX_ARRAY_SIZE  = 16
.const  NUM_CHANNELS    = 3    // SID hardware channels

// for frequency table
.const FREQ_TABLE_LENGTH = 64
.const HIGHEST_SEMITONE = 38
.const LOWEST_SEMITONE = HIGHEST_SEMITONE-FREQ_TABLE_LENGTH
.const MIDDLE_C_INDEX = -LOWEST_SEMITONE

// ZP adresses
// TODO: SAFE WHEN PRINTING TEXT VIA KERNAL???  

.const ZP_PARAMETERS_PTR = $02		// WORD
.const ZP_CHANNEL = $04				// BYTE		
.const ZP_VOICE = $05				// BYTE	
.const ZP_ACCUMULATOR = $06 		// WORD
.const ZP_OPERAND = $08   			// WORD
.const ZP_SIDDATA_PTR = $10			// WORD

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
	// TODO: first test always using base 2, generalize later
	ldx #15
loop:
	lda ZP_FREE
	and #1
	beq zero
one:
	Word_Inc(accumulator_word)
zero:
	Signed_Shift_Right(ZP_FREE,1)	// TODO: signed needed? Just stop shifting after 15?
	dex
	bne loop
}

// ----- constants used in generated code ----

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
	Word_Add_Word(ZP_ACCUMULATOR, ZP_OPERAND, ZP_ACCUMULATOR)		// TODO: jsr to save space
}

.macro Eval_Mul(type, varonum)
{
	Load_Operand(type, varonum)
	Word_Copy(ZP_ACCUMULATOR, ZP_FREE+2)		// TODO: can we avoid this copy?
	Word_Mul_Word(ZP_FREE+2, ZP_OPERAND, ZP_ACCUMULATOR)		// TODO: jsr to save space
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
  Word_Compare_Word(ZP_ACCUMULATOR, variable_adress(variable))		// TODO use jsr to save space
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
	 .if (false) {
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

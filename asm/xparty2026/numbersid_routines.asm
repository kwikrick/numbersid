#import "numbersid_macros.asm"

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

// TODO: ecactly the same as copy_from_variable_in_x_to_voice_parameter_in_y?

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
	.const w_note = ZP_FREE		// and ZP_FREE+1
	.const b_scale = ZP_FREE+2
	.const w_scale_ptr = ZP_FREE+3  // and ZP_FREE+4
	.const w_transpose = ZP_FREE+2	// overwrites scale, but it's okay

	// load note parameter
	ldy #Voice_Param_note*2
	lda (ZP_PARAMETERS_PTR),y
	sta w_note
	iny
	lda (ZP_PARAMETERS_PTR),y
	sta w_note+1

	// load scale parameter
	ldy #Voice_Param_scale*2		
	lda (ZP_PARAMETERS_PTR),y
	sta b_scale   					
	
	// check scale exists
	cmp #1
	bmi skip_scale
	cmp #NUM_SCALES
	bmi skip_scale

	// lookup scale ptr: X=(A-1)*2
	sec
	sbc #1
	asl
	tax 
	lda scales_ptr_array,x
	sta w_scale_ptr
	lda scales_ptr_array+1,x
	sta w_scale_ptr+1
	
	// lookup semitone value from scale
	// ZP_FREE byte used to index scale, add offset and clip to size of scale array
	Word_Add_Value(w_note, SCALE_MIDDLE_INDEX, w_note)
	lda w_note+1
	bmi note_negative		// skip negative index 
	lda w_note	
	and #SCALE_SIZE-1		// clip high index, assumed power of 2
	tay
	lda (w_scale_ptr),y
	sta w_note 				// Note: scale has only low byte for note/semitone
	lda #0
	sta w_note+1

skip_scale:

	// load transpose parameter
	ldy #Voice_Param_transpose*2
	lda (ZP_PARAMETERS_PTR),y
	sta w_transpose
	iny
	lda (ZP_PARAMETERS_PTR),y
	sta w_transpose+1

	Word_Add_Word(w_note, w_transpose, w_note)

	// TODO: apply pitch

	// lookup in frequency table
	Word_Add_Value(w_note, MIDDLE_C_INDEX, w_note)
	lda w_note+1    
	bmi note_negative   			// skip negative note index
	lda w_note
	and #FREQ_TABLE_LENGTH-1		// clip high index, assumed power of 2 
	asl  // word index
	tax
	lda freq_table,x
	ldy #SID_FREQ_L
	sta (ZP_SIDDATA_PTR),y	
	lda freq_table+1,x
	ldy #SID_FREQ_H
	sta (ZP_SIDDATA_PTR),y
note_negative:
 	rts
 }
 
 apply_scale:
 {
	// TODO: not efficient!
	jsr apply_note
 	rts
 }
 apply_transpose:
 {
	// TODO: not efficient!
	jsr apply_note
 	rts
 }
 apply_pitch:
 {
	// TODO: not efficient!
	jsr apply_note
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
	and #$07					// mask lower 3 bits
	sta sid_data,y				// save lowest 3 bits to sid_data+SID_FILTER_L

	Signed_Shift_Right(ZP_FREE, 3)	// shift right 3 to get upper bits
	lda ZP_FREE
	ldy #SID_FILTER_H
	sta sid_data,y					// save bits 3-10 byte to sid_data_SID_FILTER_H

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

// called at least twice
 update_sequences:
	UpdateSequences()
	rts
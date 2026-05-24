// numbersid generated code
eval_seq_0:
   Load_Accumulator(Variable,84)
   Eval_Div(Number,10)
   Compare_Accumulator(83)
   beq eval_seq_0_finish
   Store_Accumulator(83)
   jsr variable_changed_83
eval_seq_0_finish:
   rts
eval_seq_1:
   Load_Accumulator(Variable,83)
   Eval_Base(Number,2)
   Compare_Accumulator(65)
   beq eval_seq_1_finish
   Store_Accumulator(65)
   jsr variable_changed_65
eval_seq_1_finish:
   rts
sequence_eval_count:
  .byte 2
sequence_eval_table:
  .word eval_seq_0-1
  .word eval_seq_1-1
variable_changed_84:
   Mark_Sequence_Dirty(0)
   rts
variable_changed_83:
   Mark_Sequence_Dirty(1)
   rts
variable_changed_65:
   Apply_Variable_To_Voice_Parameter(65, 0, Voice_Param_note)
   Apply_Variable_To_Sine_Parameter(65, 1, Sine_Param_phase)
   rts
init_voice_parameter_values:
   // voice 0 gate
   lda #<1
   sta voice_parameter_values+0
   // voice 0 waveform
   lda #<1
   sta voice_parameter_values+10
   // voice 0 sustain
   lda #<15
   sta voice_parameter_values+22
   // voice 1 waveform
   lda #<1
   sta voice_parameter_values+42
   // voice 1 sustain
   lda #<15
   sta voice_parameter_values+54
   // voice 2 waveform
   lda #<1
   sta voice_parameter_values+74
   // voice 2 sustain
   lda #<15
   sta voice_parameter_values+86
   rts
init_global_parameter_values:
   // volume
   lda #<15
   sta volume_parameter_value
   // bob_color
   lda #<1
   sta bob_color_parameter_value
   rts
init_sine_parameter_values:
   // sine 0 freq
   lda #<256
   sta freqs+0
   lda #>256
   sta freqs+1+0
   // sine 0 amplitude
   lda #<18
   sta amplitudes+0
   // sine 1 freq
   lda #<256
   sta freqs+2
   lda #>256
   sta freqs+1+2
   // sine 1 amplitude
   lda #<11
   sta amplitudes+2
   rts
scales_decoded:
scales_ptr_array:

// numbersid generated code
eval_seq_0:
   Load_Accumulator(Variable,84)
   Eval_Div(Number,64)
   Compare_Accumulator(83)
   beq eval_seq_0_finish
   jsr variable_changed_83
   Store_Accumulator(83)
eval_seq_0_finish:
   rts
sequence_eval_count:
  .byte 1
sequence_eval_table:
  .word eval_seq_0-1
variable_changed_84:
   Mark_Sequence_Dirty(0)
   rts
variable_changed_83:
   Apply_Variable_To_Voice_Parameter(83, 0, Voice_Param_gate)
   Apply_Variable_To_Global_Parameter(83, Global_Param_filter_mode)
   rts
init_voice_parameter_values:
   // voice 0 waveform
   lda #<2
   sta voice_parameter_values+10
   // voice 0 attack
   lda #<12
   sta voice_parameter_values+18
   // voice 0 decay
   lda #<1
   sta voice_parameter_values+20
   // voice 0 sustain
   lda #<8
   sta voice_parameter_values+22
   // voice 0 release
   lda #<12
   sta voice_parameter_values+24
   // voice 0 filter
   lda #<1
   sta voice_parameter_values+26
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
   // filter_cutoff
   lda #<2000
   sta filter_cutoff_parameter_value
   lda #>2000
   sta filter_cutoff_parameter_value+1
   // volume
   lda #<15
   sta volume_parameter_value
   rts

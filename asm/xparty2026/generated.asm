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
eval_seq_2:
   Load_Accumulator(Variable,84)
   Eval_Mul(Number,8)
   Compare_Accumulator(82)
   beq eval_seq_2_finish
   Store_Accumulator(82)
   jsr variable_changed_82
eval_seq_2_finish:
   rts
sequence_eval_count:
  .byte 3
sequence_eval_table:
  .word eval_seq_0-1
  .word eval_seq_1-1
  .word eval_seq_2-1
variable_changed_84:
   Mark_Sequence_Dirty(0)
   Mark_Sequence_Dirty(2)
   rts
variable_changed_83:
   Mark_Sequence_Dirty(1)
   Apply_Variable_To_Voice_Parameter(83, 2, Voice_Param_gate)
   Apply_Variable_To_Voice_Parameter(83, 0, Voice_Param_gate)
   rts
variable_changed_65:
   Apply_Variable_To_Voice_Parameter(65, 1, Voice_Param_gate)
   Apply_Variable_To_Voice_Parameter(65, 0, Voice_Param_note)
   rts
variable_changed_82:
   Apply_Variable_To_Voice_Parameter(82, 1, Voice_Param_pulsewidth)
   rts
variable_changed_45:
   Apply_Variable_To_Voice_Parameter(45, 2, Voice_Param_note)
   rts
init_voice_parameter_values:
   // voice 0 waveform
   lda #<3
   sta voice_parameter_values+10
   // voice 0 attack
   lda #<1
   sta voice_parameter_values+18
   // voice 0 decay
   lda #<8
   sta voice_parameter_values+20
   // voice 1 waveform
   lda #<4
   sta voice_parameter_values+42
   // voice 1 sustain
   lda #<4
   sta voice_parameter_values+54
   // voice 1 filter
   lda #<1
   sta voice_parameter_values+58
   // voice 2 waveform
   lda #<8
   sta voice_parameter_values+74
   // voice 2 attack
   lda #<4
   sta voice_parameter_values+82
   // voice 2 decay
   lda #<4
   sta voice_parameter_values+84
   // voice 2 sustain
   lda #<2
   sta voice_parameter_values+86
   // voice 2 release
   lda #<4
   sta voice_parameter_values+88
   // voice 2 filter
   lda #<1
   sta voice_parameter_values+90
   rts
init_global_parameter_values:
   // filter_mode
   lda #<1
   sta filter_mode_parameter_value
   // filter_cutoff
   lda #<400
   sta filter_cutoff_parameter_value
   lda #>400
   sta filter_cutoff_parameter_value+1
   // volume
   lda #<15
   sta volume_parameter_value
   rts

// numbersid generated code
eval_seq_0:
   Load_Accumulator(Variable,84)
   Eval_Div(Number,10)
   Compare_Accumulator(83)
   beq eval_seq_0_finish
   jsr variable_changed_83
   Store_Accumulator(83)
eval_seq_0_finish:
   rts
eval_seq_1:
   Load_Accumulator(Variable,83)
   Eval_Base(Number,2)
   Compare_Accumulator(65)
   beq eval_seq_1_finish
   jsr variable_changed_65
   Store_Accumulator(65)
eval_seq_1_finish:
   rts
sequence_eval_count:
  .byte 2
sequence_eval_table:
  .word eval_seq_0-1
  .word eval_seq_1-1
variable_changed_84:
   Mark_Variable_Dirty(84)
   Mark_Sequence_Dirty(0)
   rts
variable_changed_83:
   Mark_Variable_Dirty(83)
   Mark_Sequence_Dirty(1)
   Apply_Variable_To_Voice_Parameter(83, 0, Param_gate)
   rts
variable_changed_65:
   Mark_Variable_Dirty(65)
   Apply_Variable_To_Voice_Parameter(65, 0, Param_note)
   Apply_Variable_To_Voice_Parameter(65, 1, Param_gate)
   rts
init_voice_parameter_values:
   // voice 0 waveform
   lda #<1
   sta voice_parameter_values+10
   // voice 0 sustain
   lda #<15
   sta voice_parameter_values+22
   // voice 1 waveform
   lda #<2
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

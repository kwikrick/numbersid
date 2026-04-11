// numbersid generated code
eval_seq_0:
   Load_Accumulator(Variable,84)
   Eval_Div(Number,8)
   Compare_Accumulator(83)
   beq eval_seq_0_finish
   Store_Accumulator(83)
   jsr variable_changed_83
eval_seq_0_finish:
   rts
eval_seq_1:
   Load_Accumulator(Variable,83)
   Eval_Div(Number,8)
   Compare_Accumulator(82)
   beq eval_seq_1_finish
   Store_Accumulator(82)
   jsr variable_changed_82
eval_seq_1_finish:
   rts
eval_seq_2:
   Load_Accumulator(Variable,83)
   Eval_Mul(Number,31)
   Eval_Base(Number,2)
   Compare_Accumulator(65)
   beq eval_seq_2_finish
   Store_Accumulator(65)
   jsr variable_changed_65
eval_seq_2_finish:
   rts
eval_seq_3:
   Load_Accumulator(Variable,83)
   Eval_Mul(Number,63)
   Eval_Base(Number,2)
   Eval_Add(Number,-7)
   Compare_Accumulator(66)
   beq eval_seq_3_finish
   Store_Accumulator(66)
   jsr variable_changed_66
eval_seq_3_finish:
   rts
eval_seq_4:
   Load_Accumulator(Variable,83)
   Eval_Mul(Number,127)
   Eval_Base(Number,2)
   Eval_Add(Number,-12)
   Compare_Accumulator(67)
   beq eval_seq_4_finish
   Store_Accumulator(67)
   jsr variable_changed_67
eval_seq_4_finish:
   rts
eval_seq_5:
   Load_Accumulator(Variable,82)
   Eval_Mul(Number,7)
   Eval_Base(Number,2)
   Compare_Accumulator(75)
   beq eval_seq_5_finish
   Store_Accumulator(75)
   jsr variable_changed_75
eval_seq_5_finish:
   rts
eval_seq_6:
   Load_Accumulator(Variable,82)
   Eval_Mul(Number,15)
   Eval_Base(Number,2)
   Compare_Accumulator(76)
   beq eval_seq_6_finish
   Store_Accumulator(76)
   jsr variable_changed_76
eval_seq_6_finish:
   rts
eval_seq_7:
   Load_Accumulator(Variable,82)
   Eval_Mul(Number,31)
   Eval_Base(Number,2)
   Compare_Accumulator(77)
   beq eval_seq_7_finish
   Store_Accumulator(77)
   jsr variable_changed_77
eval_seq_7_finish:
   rts
sequence_eval_count:
  .byte 8
sequence_eval_table:
  .word eval_seq_0-1
  .word eval_seq_1-1
  .word eval_seq_2-1
  .word eval_seq_3-1
  .word eval_seq_4-1
  .word eval_seq_5-1
  .word eval_seq_6-1
  .word eval_seq_7-1
variable_changed_84:
   Mark_Sequence_Dirty(0)
   rts
variable_changed_83:
   Mark_Sequence_Dirty(1)
   Mark_Sequence_Dirty(2)
   Mark_Sequence_Dirty(3)
   Mark_Sequence_Dirty(4)
   rts
variable_changed_82:
   Mark_Sequence_Dirty(5)
   Mark_Sequence_Dirty(6)
   Mark_Sequence_Dirty(7)
   rts
variable_changed_75:
   Apply_Variable_To_Voice_Parameter(75, 0, Voice_Param_gate)
   rts
variable_changed_65:
   Apply_Variable_To_Voice_Parameter(65, 0, Voice_Param_note)
   rts
variable_changed_76:
   Apply_Variable_To_Voice_Parameter(76, 1, Voice_Param_gate)
   rts
variable_changed_66:
   Apply_Variable_To_Voice_Parameter(66, 1, Voice_Param_note)
   rts
variable_changed_77:
   Apply_Variable_To_Voice_Parameter(77, 2, Voice_Param_gate)
   rts
variable_changed_67:
   Apply_Variable_To_Voice_Parameter(67, 2, Voice_Param_note)
   rts
init_voice_parameter_values:
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
   rts

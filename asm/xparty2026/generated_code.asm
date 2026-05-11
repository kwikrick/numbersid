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
   Eval_Add(Number,-4)
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
   Eval_Add(Number,-7)
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
   // voice 0 scale
   lda #<2
   sta voice_parameter_values+4
   // voice 0 waveform
   lda #<1
   sta voice_parameter_values+10
   // voice 0 sustain
   lda #<15
   sta voice_parameter_values+22
   // voice 1 scale
   lda #<2
   sta voice_parameter_values+36
   // voice 1 transpose
   lda #<-12
   sta voice_parameter_values+38
   // voice 1 waveform
   lda #<2
   sta voice_parameter_values+42
   // voice 1 sustain
   lda #<15
   sta voice_parameter_values+54
   // voice 2 scale
   lda #<2
   sta voice_parameter_values+68
   // voice 2 transpose
   lda #<-12
   sta voice_parameter_values+70
   // voice 2 waveform
   lda #<2
   sta voice_parameter_values+74
   // voice 2 sustain
   lda #<15
   sta voice_parameter_values+86
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
   // filter_resonance
   lda #<8
   sta filter_resonance_parameter_value
   // volume
   lda #<15
   sta volume_parameter_value
   rts
scales_decoded:
   // scale #0 = 2741
   .byte -69,-67,-65,-63,-62,-60,-58,-56,-54,-52,-51,-49,-47,-45,-43,-41,-40,-38,-36,-34,-32,-30,-29,-27,-25,-23,-21,-19,-18,-16,-14,-12,-10,-8,-7,-5,-3,-1,0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43
   // scale #1 = 1354
   .byte -83,-81,-79,-77,-75,-72,-70,-68,-66,-64,-61,-59,-57,-55,-53,-50,-48,-46,-44,-42,-39,-37,-35,-33,-31,-28,-26,-24,-22,-20,-17,-15,-13,-11,-9,-6,-4,-2,1,3,6,8,10,13,15,18,20,22,25,27,30,32,34,37,39,42,44,46,49,51,54,56,58,61
scales_ptr_array:
   .word scales_decoded + 0 * SCALE_SIZE
   .word scales_decoded + 1 * SCALE_SIZE

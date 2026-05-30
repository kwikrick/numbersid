// numbersid generated code
eval_seq_0:
   Load_Accumulator(Variable,84)
   Eval_Div(Number,16)
   Compare_Accumulator(83)
   beq eval_seq_0_finish
   Store_Accumulator(83)
   jsr variable_changed_83
eval_seq_0_finish:
   rts
eval_seq_1:
   Load_Accumulator(Variable,83)
   Eval_Div(Number,16)
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
   Eval_Mod(Number,4)
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
   Eval_Mod(Number,4)
   Compare_Accumulator(66)
   beq eval_seq_3_finish
   Store_Accumulator(66)
   jsr variable_changed_66
eval_seq_3_finish:
   rts
eval_seq_4:
   Load_Accumulator(Variable,65)
   Eval_Mul(Number,4)
   Compare_Accumulator(80)
   beq eval_seq_4_finish
   Store_Accumulator(80)
   jsr variable_changed_80
eval_seq_4_finish:
   rts
eval_seq_5:
   Load_Accumulator(Variable,66)
   Eval_Mul(Number,4)
   Compare_Accumulator(81)
   beq eval_seq_5_finish
   Store_Accumulator(81)
   jsr variable_changed_81
eval_seq_5_finish:
   rts
eval_seq_6:
   Load_Accumulator(Variable,82)
   Eval_Mod(Number,2)
   Eval_Mod(Number,2)
   Eval_Add(Number,1)
   Compare_Accumulator(67)
   beq eval_seq_6_finish
   Store_Accumulator(67)
   jsr variable_changed_67
eval_seq_6_finish:
   rts
eval_seq_7:
   Load_Accumulator(Variable,67)
   Eval_Add(Number,1)
   Compare_Accumulator(68)
   beq eval_seq_7_finish
   Store_Accumulator(68)
   jsr variable_changed_68
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
   rts
variable_changed_65:
   Mark_Sequence_Dirty(4)
   Apply_Variable_To_Voice_Parameter(65, 0, Voice_Param_gate)
   Apply_Variable_To_Voice_Parameter(65, 0, Voice_Param_note)
   rts
variable_changed_66:
   Mark_Sequence_Dirty(5)
   Apply_Variable_To_Voice_Parameter(66, 1, Voice_Param_gate)
   Apply_Variable_To_Voice_Parameter(66, 1, Voice_Param_note)
   rts
variable_changed_82:
   Mark_Sequence_Dirty(6)
   rts
variable_changed_67:
   Mark_Sequence_Dirty(7)
   Apply_Variable_To_Voice_Parameter(67, 1, Voice_Param_waveform)
   rts
variable_changed_68:
   Apply_Variable_To_Voice_Parameter(68, 1, Voice_Param_filter)
   rts
variable_changed_80:
   Apply_Variable_To_Sine_Parameter(80, 1, Sine_Param_amplitude)
   Apply_Variable_To_Sine_Parameter(80, 0, Sine_Param_amplitude)
   Apply_Variable_To_Bob_Parameter(80, 0, Bob_Param_color)
   rts
variable_changed_81:
   Apply_Variable_To_Sine_Parameter(81, 3, Sine_Param_amplitude)
   rts
init_voice_parameter_values:
   // voice 0 scale
   lda #<1
   sta voice_parameter_values+4
   // voice 0 transpose
   lda #<-36
   sta voice_parameter_values+6
   lda #>-36
   sta voice_parameter_values+1+6
   // voice 0 waveform
   lda #<2
   sta voice_parameter_values+10
   // voice 0 attack
   lda #<8
   sta voice_parameter_values+18
   // voice 0 sustain
   lda #<10
   sta voice_parameter_values+22
   // voice 0 release
   lda #<15
   sta voice_parameter_values+24
   // voice 0 filter
   lda #<1
   sta voice_parameter_values+26
   // voice 1 scale
   lda #<1
   sta voice_parameter_values+36
   // voice 1 attack
   lda #<1
   sta voice_parameter_values+50
   // voice 1 decay
   lda #<2
   sta voice_parameter_values+52
   // voice 1 sustain
   lda #<15
   sta voice_parameter_values+54
   // voice 1 release
   lda #<12
   sta voice_parameter_values+56
   // voice 2 scale
   lda #<1
   sta voice_parameter_values+68
   // voice 2 waveform
   lda #<1
   sta voice_parameter_values+74
   // voice 2 sustain
   lda #<15
   sta voice_parameter_values+86
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
   lda #<3
   sta filter_resonance_parameter_value
   // volume
   lda #<15
   sta volume_parameter_value
   rts
init_sine_parameter_values:
   // sine 0 freq
   lda #<2048
   sta freqs+0
   lda #>2048
   sta freqs+1+0
   // sine 1 freq
   lda #<2048
   sta freqs+2
   lda #>2048
   sta freqs+1+2
   // sine 1 phase
   lda #<64
   sta phases+2
   // sine 2 freq
   lda #<32
   sta freqs+4
   // sine 2 amplitude
   lda #<19
   sta amplitudes+4
   // sine 3 freq
   lda #<2048
   sta freqs+6
   lda #>2048
   sta freqs+1+6
   rts
init_bob_parameter_values:
   // bob 0 step
   lda #<1
   sta bob_steps+0
   // bob 1 step
   lda #<8
   sta bob_steps+1
   // bob 1 color
   lda #<2
   sta bob_colors+1
   rts
scales_decoded:
   // scale #0 = 1058
   .byte -139,-134,-132,-128,-123,-121,-117,-112,-110,-106,-101,-99,-95,-90,-88,-84,-79,-77,-73,-68,-66,-62,-57,-55,-51,-46,-44,-40,-35,-33,-29,-24,-22,-18,-13,-11,-7,-2,1,5,10,13,17,22,25,29,34,37,41,46,49,53,58,61,65,70,73,77,82,85,89,94,97,101
scales_ptr_array:
   .word scales_decoded + 0 * SCALE_SIZE
bob_num_orbits:
.byte 1
.byte 1

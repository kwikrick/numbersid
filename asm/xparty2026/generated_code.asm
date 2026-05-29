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
   Eval_Div(Number,8)
   Eval_Add(Number,1)
   Compare_Accumulator(81)
   beq eval_seq_2_finish
   Store_Accumulator(81)
   jsr variable_changed_81
eval_seq_2_finish:
   rts
eval_seq_3:
   Load_Accumulator(Variable,83)
   Eval_Mul(Number,31)
   Eval_Base(Number,2)
   Compare_Accumulator(65)
   beq eval_seq_3_finish
   Store_Accumulator(65)
   jsr variable_changed_65
eval_seq_3_finish:
   rts
eval_seq_4:
   Load_Accumulator(Variable,83)
   Eval_Mul(Number,63)
   Eval_Base(Number,2)
   Eval_Add(Number,-4)
   Compare_Accumulator(66)
   beq eval_seq_4_finish
   Store_Accumulator(66)
   jsr variable_changed_66
eval_seq_4_finish:
   rts
eval_seq_5:
   Load_Accumulator(Variable,83)
   Eval_Mul(Number,127)
   Eval_Base(Number,2)
   Eval_Add(Number,-7)
   Compare_Accumulator(67)
   beq eval_seq_5_finish
   Store_Accumulator(67)
   jsr variable_changed_67
eval_seq_5_finish:
   rts
eval_seq_6:
   Load_Accumulator(Variable,82)
   Eval_Mul(Number,7)
   Eval_Base(Number,2)
   Eval_Mul(Number,128)
   Compare_Accumulator(75)
   beq eval_seq_6_finish
   Store_Accumulator(75)
   jsr variable_changed_75
eval_seq_6_finish:
   rts
eval_seq_7:
   Load_Accumulator(Variable,82)
   Eval_Mul(Number,15)
   Eval_Base(Number,2)
   Eval_Mul(Number,128)
   Eval_Add(Variable,83)
   Compare_Accumulator(76)
   beq eval_seq_7_finish
   Store_Accumulator(76)
   jsr variable_changed_76
eval_seq_7_finish:
   rts
eval_seq_8:
   Load_Accumulator(Variable,82)
   Eval_Mul(Number,31)
   Eval_Base(Number,2)
   Eval_Mul(Number,128)
   Eval_Add(Variable,84)
   Compare_Accumulator(77)
   beq eval_seq_8_finish
   Store_Accumulator(77)
   jsr variable_changed_77
eval_seq_8_finish:
   rts
eval_seq_9:
   Load_Accumulator(Variable,81)
   Eval_Mul(Number,31)
   Eval_Base(Number,2)
   Compare_Accumulator(72)
   beq eval_seq_9_finish
   Store_Accumulator(72)
   jsr variable_changed_72
eval_seq_9_finish:
   rts
eval_seq_10:
   Load_Accumulator(Variable,81)
   Eval_Mul(Number,63)
   Eval_Base(Number,2)
   Compare_Accumulator(73)
   beq eval_seq_10_finish
   Store_Accumulator(73)
   jsr variable_changed_73
eval_seq_10_finish:
   rts
eval_seq_11:
   Load_Accumulator(Variable,81)
   Eval_Div(Number,8)
   Eval_Mul(Number,1341)
   Eval_Mod(Number,8)
   Eval_Mul(Number,32)
   Eval_Add(Number,64)
   Compare_Accumulator(74)
   beq eval_seq_11_finish
   Store_Accumulator(74)
   jsr variable_changed_74
eval_seq_11_finish:
   rts
sequence_eval_count:
  .byte 12
sequence_eval_table:
  .word eval_seq_0-1
  .word eval_seq_1-1
  .word eval_seq_2-1
  .word eval_seq_3-1
  .word eval_seq_4-1
  .word eval_seq_5-1
  .word eval_seq_6-1
  .word eval_seq_7-1
  .word eval_seq_8-1
  .word eval_seq_9-1
  .word eval_seq_10-1
  .word eval_seq_11-1
variable_changed_84:
   Mark_Sequence_Dirty(0)
   Mark_Sequence_Dirty(8)
   rts
variable_changed_83:
   Mark_Sequence_Dirty(1)
   Mark_Sequence_Dirty(2)
   Mark_Sequence_Dirty(3)
   Mark_Sequence_Dirty(4)
   Mark_Sequence_Dirty(5)
   Mark_Sequence_Dirty(7)
   rts
variable_changed_82:
   Mark_Sequence_Dirty(8)
   Mark_Sequence_Dirty(6)
   Mark_Sequence_Dirty(7)
   rts
variable_changed_81:
   Mark_Sequence_Dirty(9)
   Mark_Sequence_Dirty(10)
   Mark_Sequence_Dirty(11)
   Apply_Variable_To_Bob_Parameter(81, 1, Bob_Param_color)
   rts
variable_changed_65:
   Apply_Variable_To_Voice_Parameter(65, 0, Voice_Param_note)
   rts
variable_changed_75:
   Apply_Variable_To_Voice_Parameter(75, 0, Voice_Param_pulsewidth)
   rts
variable_changed_66:
   Apply_Variable_To_Voice_Parameter(66, 1, Voice_Param_note)
   rts
variable_changed_76:
   Apply_Variable_To_Voice_Parameter(76, 1, Voice_Param_pulsewidth)
   rts
variable_changed_67:
   Apply_Variable_To_Voice_Parameter(67, 2, Voice_Param_note)
   rts
variable_changed_77:
   Apply_Variable_To_Voice_Parameter(77, 2, Voice_Param_pulsewidth)
   rts
variable_changed_72:
   Apply_Variable_To_Sine_Parameter(72, 1, Sine_Param_amplitude)
   Apply_Variable_To_Sine_Parameter(72, 0, Sine_Param_amplitude)
   rts
variable_changed_73:
   Apply_Variable_To_Sine_Parameter(73, 2, Sine_Param_amplitude)
   Apply_Variable_To_Sine_Parameter(73, 3, Sine_Param_amplitude)
   rts
variable_changed_74:
   Apply_Variable_To_Sine_Parameter(74, 3, Sine_Param_phase)
   rts
init_voice_parameter_values:
   // voice 0 gate
   lda #<1
   sta voice_parameter_values+0
   // voice 0 scale
   lda #<1
   sta voice_parameter_values+4
   // voice 0 transpose
   lda #<-24
   sta voice_parameter_values+6
   lda #>-24
   sta voice_parameter_values+1+6
   // voice 0 waveform
   lda #<4
   sta voice_parameter_values+10
   // voice 0 sustain
   lda #<15
   sta voice_parameter_values+22
   // voice 1 gate
   lda #<1
   sta voice_parameter_values+32
   // voice 1 scale
   lda #<1
   sta voice_parameter_values+36
   // voice 1 transpose
   lda #<-24
   sta voice_parameter_values+38
   lda #>-24
   sta voice_parameter_values+1+38
   // voice 1 waveform
   lda #<4
   sta voice_parameter_values+42
   // voice 1 sustain
   lda #<15
   sta voice_parameter_values+54
   // voice 2 gate
   lda #<1
   sta voice_parameter_values+64
   // voice 2 scale
   lda #<1
   sta voice_parameter_values+68
   // voice 2 transpose
   lda #<-24
   sta voice_parameter_values+70
   lda #>-24
   sta voice_parameter_values+1+70
   // voice 2 waveform
   lda #<4
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
   lda #<1000
   sta filter_cutoff_parameter_value
   lda #>1000
   sta filter_cutoff_parameter_value+1
   // filter_resonance
   lda #<10
   sta filter_resonance_parameter_value
   // volume
   lda #<15
   sta volume_parameter_value
   rts
init_sine_parameter_values:
   // sine 0 freq
   lda #<256
   sta freqs+0
   lda #>256
   sta freqs+1+0
   // sine 1 freq
   lda #<256
   sta freqs+2
   lda #>256
   sta freqs+1+2
   // sine 1 phase
   lda #<64
   sta phases+2
   // sine 2 freq
   lda #<4096
   sta freqs+4
   lda #>4096
   sta freqs+1+4
   // sine 3 freq
   lda #<4096
   sta freqs+6
   lda #>4096
   sta freqs+1+6
   // sine 4 freq
   lda #<2040
   sta freqs+8
   lda #>2040
   sta freqs+1+8
   // sine 4 amplitude
   lda #<20
   sta amplitudes+8
   // sine 5 freq
   lda #<32
   sta freqs+10
   // sine 5 amplitude
   lda #<11
   sta amplitudes+10
   rts
init_bob_parameter_values:
   // bob 0 step
   lda #<1
   sta bob_steps+0
   // bob 0 color
   lda #<1
   sta bob_colors+0
   // bob 1 step
   lda #<1
   sta bob_steps+1
   rts
scales_decoded:
   // scale #0 = 1354
   .byte -83,-81,-79,-77,-75,-72,-70,-68,-66,-64,-61,-59,-57,-55,-53,-50,-48,-46,-44,-42,-39,-37,-35,-33,-31,-28,-26,-24,-22,-20,-17,-15,-13,-11,-9,-6,-4,-2,1,3,6,8,10,13,15,18,20,22,25,27,30,32,34,37,39,42,44,46,49,51,54,56,58,61
scales_ptr_array:
   .word scales_decoded + 0 * SCALE_SIZE
bob_num_orbits:
.byte 2
.byte 1

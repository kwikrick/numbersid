// numbersid generated code
eval_seq_0:
   Load_Accumulator(Variable,84)
   Eval_Add(Number,64)
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
   Load_Accumulator(Variable,82)
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
   Load_Accumulator(Variable,81)
   Eval_Div(Number,4)
   Eval_Base(Number,2)
   Eval_Add(Number,-27)
   Compare_Accumulator(68)
   beq eval_seq_6_finish
   Store_Accumulator(68)
   jsr variable_changed_68
eval_seq_6_finish:
   rts
eval_seq_7:
   Load_Accumulator(Variable,83)
   Eval_Mod(Number,128)
   Eval_Mul(Number,16)
   Eval_Add(Number,1024)
   Compare_Accumulator(75)
   beq eval_seq_7_finish
   Store_Accumulator(75)
   jsr variable_changed_75
eval_seq_7_finish:
   rts
eval_seq_8:
   Load_Accumulator(Variable,83)
   Eval_Mod(Number,256)
   Eval_Mul(Number,8)
   Eval_Add(Number,1024)
   Compare_Accumulator(76)
   beq eval_seq_8_finish
   Store_Accumulator(76)
   jsr variable_changed_76
eval_seq_8_finish:
   rts
eval_seq_9:
   Load_Accumulator(Variable,83)
   Eval_Mod(Number,512)
   Eval_Mul(Number,4)
   Eval_Add(Number,1024)
   Compare_Accumulator(77)
   beq eval_seq_9_finish
   Store_Accumulator(77)
   jsr variable_changed_77
eval_seq_9_finish:
   rts
eval_seq_10:
   Load_Accumulator(Variable,81)
   Eval_Mul(Number,31)
   Eval_Base(Number,2)
   Eval_Mul(Number,64)
   Eval_Add(Number,256)
   Compare_Accumulator(72)
   beq eval_seq_10_finish
   Store_Accumulator(72)
   jsr variable_changed_72
eval_seq_10_finish:
   rts
eval_seq_11:
   Load_Accumulator(Variable,81)
   Eval_Mul(Number,63)
   Eval_Base(Number,2)
   Eval_Mul(Number,64)
   Eval_Add(Number,256)
   Compare_Accumulator(73)
   beq eval_seq_11_finish
   Store_Accumulator(73)
   jsr variable_changed_73
eval_seq_11_finish:
   rts
eval_seq_12:
   Load_Accumulator(Variable,82)
   Eval_Mul(Number,31)
   Eval_Base(Number,2)
   Eval_Mul(Number,6)
   Eval_Add(Number,8192)
   Compare_Accumulator(74)
   beq eval_seq_12_finish
   Store_Accumulator(74)
   jsr variable_changed_74
eval_seq_12_finish:
   rts
eval_seq_13:
   Load_Accumulator(Variable,81)
   Eval_Add(Number,1)
   Eval_Mod(Number,3)
   Eval_Div(Number,2)
   Compare_Accumulator(78)
   beq eval_seq_13_finish
   Store_Accumulator(78)
   jsr variable_changed_78
eval_seq_13_finish:
   rts
eval_seq_14:
   Load_Accumulator(Variable,81)
   Eval_Add(Number,2)
   Eval_Mod(Number,3)
   Eval_Div(Number,2)
   Compare_Accumulator(79)
   beq eval_seq_14_finish
   Store_Accumulator(79)
   jsr variable_changed_79
eval_seq_14_finish:
   rts
eval_seq_15:
   Load_Accumulator(Variable,81)
   Eval_Add(Number,3)
   Eval_Mod(Number,3)
   Eval_Div(Number,2)
   Compare_Accumulator(80)
   beq eval_seq_15_finish
   Store_Accumulator(80)
   jsr variable_changed_80
eval_seq_15_finish:
   rts
sequence_eval_count:
  .byte 16
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
  .word eval_seq_12-1
  .word eval_seq_13-1
  .word eval_seq_14-1
  .word eval_seq_15-1
variable_changed_84:
   Mark_Sequence_Dirty(0)
   rts
variable_changed_83:
   Mark_Sequence_Dirty(1)
   Mark_Sequence_Dirty(3)
   Mark_Sequence_Dirty(4)
   Mark_Sequence_Dirty(5)
   Mark_Sequence_Dirty(7)
   Mark_Sequence_Dirty(8)
   Mark_Sequence_Dirty(9)
   rts
variable_changed_82:
   Mark_Sequence_Dirty(2)
   Mark_Sequence_Dirty(12)
   rts
variable_changed_81:
   Mark_Sequence_Dirty(6)
   Mark_Sequence_Dirty(10)
   Mark_Sequence_Dirty(11)
   Mark_Sequence_Dirty(13)
   Mark_Sequence_Dirty(14)
   Mark_Sequence_Dirty(15)
   rts
variable_changed_65:
   Apply_Variable_To_Voice_Parameter(65, 0, Voice_Param_note)
   rts
variable_changed_68:
   Apply_Variable_To_Voice_Parameter(68, 1, Voice_Param_transpose)
   Apply_Variable_To_Voice_Parameter(68, 2, Voice_Param_transpose)
   Apply_Variable_To_Voice_Parameter(68, 0, Voice_Param_transpose)
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
variable_changed_74:
   Apply_Variable_To_Sine_Parameter(74, 0, Sine_Param_freq)
   Apply_Variable_To_Sine_Parameter(74, 3, Sine_Param_freq)
   rts
variable_changed_72:
   Apply_Variable_To_Sine_Parameter(72, 9, Sine_Param_freq)
   Apply_Variable_To_Sine_Parameter(72, 7, Sine_Param_freq)
   Apply_Variable_To_Sine_Parameter(72, 4, Sine_Param_freq)
   Apply_Variable_To_Sine_Parameter(72, 8, Sine_Param_freq)
   rts
variable_changed_73:
   Apply_Variable_To_Sine_Parameter(73, 6, Sine_Param_freq)
   Apply_Variable_To_Sine_Parameter(73, 11, Sine_Param_freq)
   Apply_Variable_To_Sine_Parameter(73, 10, Sine_Param_freq)
   Apply_Variable_To_Sine_Parameter(73, 5, Sine_Param_freq)
   rts
variable_changed_78:
   Apply_Variable_To_Bob_Parameter(78, 0, Bob_Param_enable)
   Apply_Variable_To_Bob_Parameter(78, 1, Bob_Param_enable)
   rts
variable_changed_79:
   Apply_Variable_To_Bob_Parameter(79, 3, Bob_Param_enable)
   Apply_Variable_To_Bob_Parameter(79, 2, Bob_Param_enable)
   rts
variable_changed_80:
   Apply_Variable_To_Bob_Parameter(80, 4, Bob_Param_enable)
   rts
init_voice_parameter_values:
   // voice 0 gate
   lda #<1
   sta voice_parameter_values+0
   // voice 0 scale
   lda #<1
   sta voice_parameter_values+4
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
   // sine 0 amplitude
   lda #<19
   sta amplitudes+0
   // sine 0 phase
   lda #<64
   sta phases+0
   // sine 1 freq
   lda #<4118
   sta freqs+2
   lda #>4118
   sta freqs+1+2
   // sine 1 amplitude
   lda #<11
   sta amplitudes+2
   // sine 2 freq
   lda #<4118
   sta freqs+4
   lda #>4118
   sta freqs+1+4
   // sine 2 amplitude
   lda #<19
   sta amplitudes+4
   // sine 3 amplitude
   lda #<11
   sta amplitudes+6
   // sine 3 phase
   lda #<64
   sta phases+6
   // sine 4 amplitude
   lda #<20
   sta amplitudes+8
   // sine 5 amplitude
   lda #<11
   sta amplitudes+10
   // sine 6 amplitude
   lda #<20
   sta amplitudes+12
   // sine 7 amplitude
   lda #<11
   sta amplitudes+14
   // sine 8 amplitude
   lda #<13
   sta amplitudes+16
   // sine 9 amplitude
   lda #<7
   sta amplitudes+18
   // sine 9 phase
   lda #<64
   sta phases+18
   // sine 10 amplitude
   lda #<5
   sta amplitudes+20
   // sine 11 amplitude
   lda #<5
   sta amplitudes+22
   // sine 11 phase
   lda #<64
   sta phases+22
   rts
init_bob_parameter_values:
   // bob 0 step
   lda #<1
   sta bob_steps+0
   // bob 0 color
   lda #<7
   sta bob_colors+0
   // bob 1 step
   lda #<1
   sta bob_steps+2
   // bob 1 color
   lda #<9
   sta bob_colors+2
   // bob 2 step
   lda #<253
   sta bob_steps+4
   // bob 2 color
   lda #<5
   sta bob_colors+4
   // bob 3 step
   lda #<3
   sta bob_steps+6
   // bob 3 color
   lda #<3
   sta bob_colors+6
   // bob 4 step
   lda #<1
   sta bob_steps+8
   // bob 4 color
   lda #<13
   sta bob_colors+8
   rts
scales_decoded:
   // scale #0 = 1354
   .byte -83,-81,-79,-77,-75,-72,-70,-68,-66,-64,-61,-59,-57,-55,-53,-50,-48,-46,-44,-42,-39,-37,-35,-33,-31,-28,-26,-24,-22,-20,-17,-15,-13,-11,-9,-6,-4,-2,1,3,6,8,10,13,15,18,20,22,25,27,30,32,34,37,39,42,44,46,49,51,54,56,58,61
scales_ptr_array:
   .word scales_decoded + 0 * SCALE_SIZE
bob_num_orbits:
.byte 1
.byte 1
.byte 1
.byte 1
.byte 2

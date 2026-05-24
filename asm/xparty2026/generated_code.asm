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
   Load_Accumulator(Variable,83)
   Eval_Div(Number,8)
   Compare_Accumulator(66)
   beq eval_seq_2_finish
   Store_Accumulator(66)
   jsr variable_changed_66
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
   rts
variable_changed_83:
   Mark_Sequence_Dirty(1)
   Mark_Sequence_Dirty(2)
   Apply_Variable_To_Voice_Parameter(83, 0, Voice_Param_gate)
   rts
variable_changed_65:
   Apply_Variable_To_Voice_Parameter(65, 1, Voice_Param_gate)
   Apply_Variable_To_Voice_Parameter(65, 0, Voice_Param_note)
   rts
variable_changed_66:
   Apply_Variable_To_Global_Parameter(66, Global_Param_bob_color)
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
init_sine_parameter_values:
   // sine 0 freq
   lda #<256
   sta freqs+0
   lda #>256
   sta freqs+1+0
   // sine 0 amplitude
   lda #<20
   sta amplitudes+0
   // sine 1 freq
   lda #<256
   sta freqs+2
   lda #>256
   sta freqs+1+2
   // sine 1 amplitude
   lda #<12
   sta amplitudes+2
   // sine 1 phase
   lda #<64
   sta phases+2
   // sine 2 freq
   lda #<2560
   sta freqs+4
   lda #>2560
   sta freqs+1+4
   // sine 2 amplitude
   lda #<4
   sta amplitudes+4
   // sine 3 freq
   lda #<2560
   sta freqs+6
   lda #>2560
   sta freqs+1+6
   // sine 3 amplitude
   lda #<4
   sta amplitudes+6
   // sine 3 phase
   lda #<64
   sta phases+6
   rts
scales_decoded:
   // scale #0 = 2741
   .byte -69,-67,-65,-63,-62,-60,-58,-56,-54,-52,-51,-49,-47,-45,-43,-41,-40,-38,-36,-34,-32,-30,-29,-27,-25,-23,-21,-19,-18,-16,-14,-12,-10,-8,-7,-5,-3,-1,0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43
scales_ptr_array:
   .word scales_decoded + 0 * SCALE_SIZE

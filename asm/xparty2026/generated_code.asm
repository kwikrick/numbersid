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
   Store_Accumulator(65)
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
   // sine 1 phase
   lda #<64
   sta phases+2
   // sine 2 freq
   lda #<32
   sta freqs+4
   // sine 2 amplitude
   lda #<4
   sta amplitudes+4
   // sine 3 freq
   lda #<32
   sta freqs+6
   // sine 3 amplitude
   lda #<4
   sta amplitudes+6
   // sine 3 phase
   lda #<64
   sta phases+6
   // sine 4 freq
   lda #<800
   sta freqs+8
   lda #>800
   sta freqs+1+8
   // sine 4 amplitude
   lda #<5
   sta amplitudes+8
   // sine 5 freq
   lda #<900
   sta freqs+10
   lda #>900
   sta freqs+1+10
   // sine 5 amplitude
   lda #<5
   sta amplitudes+10
   // sine 5 phase
   lda #<64
   sta phases+10
   rts
init_bob_parameter_values:
   // bob 0 step
   lda #<1
   sta bob_steps+0
   // bob 0 color
   lda #<1
   sta bob_colors+0
   // bob 1 color
   lda #<4
   sta bob_colors+1
   rts
scales_decoded:
scales_ptr_array:
bob_num_orbits:
.byte 2
.byte 1

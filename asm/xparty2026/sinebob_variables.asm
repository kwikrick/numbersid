#import "sinebob_macros.asm"

// TODO: phase needs to be controllable as a parameter too?
// idea 1 (simplest, same as original)
//   - at initialisation, just set phase = 128 for y (odd numbered phases)
// idea 2:
//  - add a phase0 parameter (16 words)
//  - when phase0(i) is changed (by sequencer), set phase(i)=phase0(i)
// idea 3:
//  - add a reset parameter (one for all)
//  - when rest parameter is triggered, rest all phases, 0 or 128 for x an y 

// computed: for each bob, phase x and phase y
phases:
.fillword BOB_NUM_SINES*2,0

// computed: for each bob, position x and position y
positions:
.fillword BOB_NUM_SINES*2, 0

// offset in the charset where transitions are to be update0
// note: offset in bytes, so 8 bytes per char, increase insteps of 8 
sinebob_transition_offset:
.word 0


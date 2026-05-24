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

// paramters: for each 8 sprites, freq x and freq y
freqs:
.word 5 * 256 + 032 , 5 * 256 + 032
.word 50 * 256 + 000 , 50 * 256 + 000
.word 01 * 256 + 000 , 01 * 256 + 000
.word 01 * 256 + 000 , 01 * 256 + 000

// paramters: for each 8 sprites: scale x and scale y
// Note: we store word values to make indexing simpler (all others are words)
// But we only use low byte, value <=256
amplitudes:
 .word 14,7
 .word 4,4
 .word 0,0
 .word 0,0


// computed: for each bob, phase x and phase y
phases:
.fillword NUM_SINES*2,0

// computed: for each bob, position x and position y

// TODO: are these still needed, we add all the sines...
// why keep them? Unless we want to recombine seleted sines
// into differnt bobs?
positions:
.fillword NUM_SINES*2, 0

// offset in the charset where transitions are to be update0
// note: offset in bytes, so 8 bytes per char, increase insteps of 8 
sinebob_transition_offset:
.word 0


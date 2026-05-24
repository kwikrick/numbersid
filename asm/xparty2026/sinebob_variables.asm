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

// paramters: for each sine, a frequency, scaled by 256. Added to counter each frame.
// range 0-65536; 256 means one cycle every 256 frames
freqs:
.fillword NUM_SINES,0

// paramters: for each sine, an amplitude
// Note: we store word values to make indexing simpler (all others are words)
// But we only use low byte, value <=256
amplitudes:
.fillword NUM_SINES,0

// parameter: for each bob, the phase; added to counter before lookup in sine table
// Note: we store word values to make indexing simpler (all others are words)
// But we only use low byte, value <=256
phases:
.fillword NUM_SINES,0

// computed: for each bob
counters:
.fillword NUM_SINES,0

// computed: for each sine, the position/value of sine.
// TODO: are these still needed, we add all the sines...
// why keep them? Unless we want to recombine seleted sines
// into differnt bobs?
positions:
.fillword NUM_SINES, 0

// offset in the charset where transitions are to be updated
// note: offset in bytes, so 8 bytes per char, increase insteps of 8 
sinebob_transition_offset:
.word 0

// a history of screen adresses to clear
clear_pixel_history:
.fillword 1024,CLEAR_HISTORY_SIZE

// pointer to current place in history
//clear_pixel_ptr: 
//.word 0 
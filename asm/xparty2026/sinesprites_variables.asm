
// TODO: phase needs to be controllable as a parameter too?
// idea 1 (simplest, same as original)
//   - at initialisation, just set phase = 128 for y (odd numbered phases)
// idea 2:
//  - add a phase0 parameter (16 words)
//  - when phase0(i) is changed (by sequencer), set phase(i)=phase0(i)
// idea 3:
//  - add a reset parameter (one for all)
//  - when rest parameter is triggered, rest all phases, 0 or 128 for x an y 

// computed: for each 8 sprites, phase x and phase y
phases:
.fillword 16,0

// computed: for each 8 spites, position x and position y
positions:
.fillword 16, 0



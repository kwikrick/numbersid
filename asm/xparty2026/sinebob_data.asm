// 256 values in range 0-256 
sine_256_256:
.fill 256, 127.5+127.5*sin(toRadians(i*360/256))

// TODO: parameters should be moved to variables (virtual segment) and set by (generated) code

// paramters: for each 8 sprites, freq x and freq y
freqs:
.word 0.5 * 256 + 00 , 0.5 * 256 + 000
.word 05 * 256 + 000 , 05 * 256 + 000
.word 01 * 256 + 000 , 01 * 256 + 000
.word 01 * 256 + 000 , 01 * 256 + 000

// paramters: for each 8 sprites, offset x and offset y

// TODO: remove? not needed anymore?

offsets:
.word 20,12
.word 20,12
.word 20,12
.word 20,12

// paramters: for each 8 sprites: scale x and scale y
// Note: we store word values to make indexing simpler (all others are words)
// But we only use low byte, value <=256
amplitudes:
.word 14,7
.word 4,4
.word 0,0
.word 0,0

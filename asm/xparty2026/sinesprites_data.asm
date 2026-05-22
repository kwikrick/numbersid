// 256 values in range 0-256 
sine_256_256:
.fill 256, 127.5+127.5*sin(toRadians(i*360/256))

// TODO: parameters should be moved to variables (virtual segment) and set by (generated) code

// paramters: for each 8 sprites, freq x and freq y
freqs:
.word 01 * 256 + 000 , 01 * 256 + 000
.word 02 * 256 + 000 , 01 * 256 + 000
.word 01 * 256 + 000 , 02 * 256 + 000
.word 03 * 256 + 000 , 01 * 256 + 000
.word 01 * 256 + 000 , 03 * 256 + 000
.word 02 * 256 + 000 , 03 * 256 + 000
.word 03 * 256 + 000 , 02 * 256 + 000
.word 05 * 256 + 000 , 05 * 256 + 000

// paramters: for each 8 sprites, offset x and offset y
offsets:
.word 20,12
.word 20,12
.word 20,12
.word 20,12
.word 20,12
.word 20,12
.word 20,12
.word 20,12

// paramters: for each 8 sprites: scale x and scale y
// Note: we store word values to make indexing simpler (all others are words)
// But we only use low byte, value <=256
amplitudes:
.word 4,2
.word 8,4
.word 12,6
.word 16,8
.word 20,10
.word 24,12
.word 28,14
.word 32,18

// 256 values in range 0-256 
sine_256_256:
.fill 256, 127.5+127.5*sin(toRadians(i*360/256))

// TODO: parameters should be moved to variables (virtual segment) and set by (generated) code

// paramters: for each 8 sprites, freq x and freq y
freqs:
.word 256 + 16 , 256 + 16
.word 256 + 32 , 256 + 32
.word 256 + 64 , 256 + 64
.word 256 + 128 , 256 + 128
.word 256 + 16 , 256 + 16
.word 256 + 32, 256 + 32
.word 256 + 64 , 256 + 64
.word 256 + 128, 256 + 128

// paramters: for each 8 sprites, offset x and offset y
offsets:
.word 170,140
.word 170,140
.word 170,140
.word 170,140
.word 170,140
.word 170,140
.word 170,140
.word 170,140

// paramters: for each 8 sprites: scale x and scale y
// Note: we store word values to make indexing simpler (all others are words)
// But we only use low byte, value <=256
amplitudes:
.word 20,10
.word 40,20
.word 60,30
.word 80,40
.word 100,50
.word 120,60
.word 140,70
.word 160,80

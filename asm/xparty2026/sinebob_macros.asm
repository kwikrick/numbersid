#importonce 

#import "demo_zeropage.asm"

.const BOB_CHARSET = 5
.label bob_charset_addr = BOB_CHARSET*$0800
.print "BOB CHARSET ADDR = "+bob_charset_addr

.const ZP_IRQ_SRC = ZP_IRQ			//word
.const ZP_IRQ_TGT = ZP_IRQ+2		//word
.const ZP_IRQ_OFF = ZP_IRQ+4        // word

.const BOB_NUM_SINES = 8            // must be a multiple of 2 (X and Y)

.const BOB_CHAR_START = 64          // first char in charset used for bobs

.macro BOB_INIT_PHASES()
{
    // set inital phases for y axis (quarter cycle over x)
	lda #64
	ldy #0
loop_init_phases:
	sta phases+3,y		// y high
	iny
	iny
	iny
	iny
	cpy #BOB_NUM_SINES*2       // two bytes per sine
	bne loop_init_phases
}


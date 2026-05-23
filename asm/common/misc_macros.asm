#importonce 

#import "zeropage_const.asm"
#import "word_macros.asm"

// miscellaneous macros

// Fill a memory block with given value
// Not the fastest, but can fill up to 65535 bytes
// uses A,X,Y 
// and ZP_FREE, ZP_FREE+1

.macro Fill(adress, size, value) 
{
	.if (size==0) {
		.error "Fill cannot fill 0 bytes" 
	}

	.if (size>65535) {
		.error "Fill cannot fill more than 65535 bytes" 
	}

	// use zero page indirect addressing to fill memory
	lda #<adress
	sta ZP_FREE

	lda #>adress
	sta ZP_FREE+1

	// A = value to write
	lda #value

	// fill size/256 blocks of 256 bytes 
	ldx #>size
	beq skip				// skip if zero blocks
loopX:
	ldy #0
loopY:
	sta (ZP_FREE),y
	dey
	bne loopY
	Word_Inc(ZP_FREE+1)		// next 256 byte block
	dex
	bne loopX
skip:
	// fill remaining size%256 bytes
	ldy #<size
	beq skip2
loopY2:
	dey
	sta (ZP_FREE),y
	bne loopY2
skip2:
}



// Fill a memory block with given value
// Not the fastest, but can fill up to 65535 bytes
// uses A,X,Y 
// and ZP_FREE, ZP_FREE+1
// and ZP_FREE+1, ZP_FREE+2

.macro Copy(source, target, size) 
{
	.if (size==0) {
		.error "Fill cannot fill 0 bytes" 
	}

	.if (size>65535) {
		.error "Fill cannot fill more than 65535 bytes" 
	}

	// use zero page indirect addressing to fill memory
	Word_Store_Value(ZP_FREE, target)
	Word_Store_Value(ZP_FREE+2,source)
	
	// fill size/256 blocks of 256 bytes 
	ldx #>size
	beq skip				// skip if zero blocks
loopX:
	ldy #0
loopY:
	lda (ZP_FREE+2),y
	sta (ZP_FREE),y
	dey
	bne loopY
	Word_Inc(ZP_FREE+1)		// next 256 byte block
	Word_Inc(ZP_FREE+3)		// next 256 byte block
	dex
	bne loopX
skip:
	// fill remaining size%256 bytes
	ldy #<size
	beq skip2
loopY2:
	dey
	lda (ZP_FREE+2),y
	sta (ZP_FREE),y
	bne loopY2
skip2:
}

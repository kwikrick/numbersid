//  test multiplication

#import "common/zeropage_const.asm"
#import "common/word_macros.asm"
#import "common/io_macros.asm"

.const debug_scale_decode = true

.const SCALE_SIZE = 64
.const SCALE_MID_INDEX = 38     // TODO: good value?

// generated
.const NUM_SCALES = 2


// generate basic start code

BasicUpstart2(main)

// main

*=* "Main"

main:

    jsr decode_scales
    rts



decode_scales:
{
	ldx #0
loop:
	jsr decode_scale
    inx
    inx
    cpx #NUM_SCALES*2
	bne loop
	rts
}

// X is index*2 (word index)
// preserves X on stack
decode_scale:
{
	// Algorithm: 

	// if encoded_scale%1==true then 
	//   write note value 
	//   y++
	//   if y==SCALE_SIZE-1; end
	// increment note valie
	// shift right encoded scale
	// if 12 shifts:
	//   reload encoded scale
	// loop


	.const decoded_scale_ptr = ZP_FREE // +ZP_FREE+1
	.const encoded_scale = ZP_FREE+2  // +ZP+FREE+3
	.const note_value = ZP_FREE+4

	txa
	pha

	// load pointer
	lda scales_ptr_array,x
	sta decoded_scale_ptr
	lda scales_ptr_array+1,x
	sta decoded_scale_ptr+1
	
	// load encoded scale
	lda scales_encoded,x
	sta encoded_scale
    lda scales_encoded+1,x
	sta encoded_scale+1
    
	// load note value
	lda #0					
	sta note_value 			

	ldy #SCALE_MID_INDEX		// Y = index in decoded_scale to write to
	ldx #12					    // count number of shifts

loop_forwards:
	
	lda encoded_scale
	and #1
	beq skip_note

    .if (debug_scale_decode) {
        PushRegs()
        ByteToHex(note_value,text_string)
        PrintString(text_string)
        PopRegs()
    }

	lda note_value
	sta (decoded_scale_ptr),y
	
	iny
	cpy #SCALE_SIZE
	beq finish_forward

skip_note:

	Unsigned_Shift_Right(encoded_scale,1)
	dex
	bne next_forward

	ldx #12			// reset encoded 
    pla             // note: need x from stack
    tax
	lda scales_encoded,x
	sta encoded_scale
    lda scales_encoded+1,x
	sta encoded_scale+1
    txa
    pha

next_forward:

	.if (debug_scale_decode) {
        PushRegs()
        PrintChar('+')
        PopRegs()
    }

    inc note_value
	clc
	bcc loop_forwards
	
finish_forward:
 
    .if (debug_scale_decode) {
        PushRegs()
        PrintChar('/')
        PopRegs()
    }

    // backwards pass

	// load note value
	lda #-1					
	sta note_value 			

	ldy #SCALE_MID_INDEX-1		// Y = index in decoded_scale to write to
	ldx #12					    // count number of shifts

loop_backwards:
	
	lda encoded_scale+1
	and #1<<3      // test bit 11 (bit 3 of second byte)
	beq skip_note_backwards

    .if (debug_scale_decode) {
       PushRegs()
       ByteToHex(note_value,text_string)
       PrintString(text_string)
       PopRegs()
    }

	lda note_value
	sta (decoded_scale_ptr),y
	
	dey
    cpy #-1
	bmi finish_backwards

skip_note_backwards:

	Word_Shift_Left(encoded_scale,1)
	dex
	bne next_backwards

	ldx #12			// reset encoded 
    pla             // note: need x from stack
    tax
	lda scales_encoded,x
	sta encoded_scale
    lda scales_encoded+1,x
	sta encoded_scale+1
    txa
    pha

next_backwards:

	.if (debug_scale_decode) {
        PushRegs()
        PrintChar('-')
        PopRegs()
    }

    dec note_value
	clc
	bcc loop_backwards
	
finish_backwards:
 
    .if (debug_scale_decode) {
        PushRegs()
        PrintChar(13)
        PopRegs()
	}
    
	pla
	tax
	rts

}

// generated
scales_encoded:
   .word 2741
   .word 1354
scales_ptr_array:
   .word scales_decoded + 0 * SCALE_SIZE
   .word scales_decoded + 1 * SCALE_SIZE

.print ("Size of code for function decode_scales + generated data:")
.print(* - decode_scales)

*=$2000
// space to decode to
scales_decoded:
   .fill 2 * SCALE_SIZE, 0

// space to ByteToHex/WordToHex
text_string: .fill 40,32 ; .byte 0



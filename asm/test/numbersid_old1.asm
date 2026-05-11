//  numberisid player

.cpu _6502

#import "common/word_macros.asm"
#import "common/io_macros.asm"
#import "common/keyboard_macros.asm"
#import "common/cia_const.asm"
#import "common/sid_const.asm"
#import "common/sid_macros.asm"
#import "common/cia_const.asm"


// constants
.const debug = true

.const  MAX_SEQUENCES   = 10
.const  MAX_VARIABLES   = 26    // A-Z
.const  MAX_ARRAYS      = 8
.const  MAX_ARRAY_SIZE  = 16
.const  MAX_VOICES      = 8
.const  NUM_CHANNELS    = 3    // SID hardware channels

.const VOICE_SIZE		= 14*2					// 14 words = 28 bytes
.const SEQUENCE_SIZE	= 11*2 + 1				// 11 words + 1 byte = 23 bytes
.const ARRAY_SIZE   	= MAX_ARRAY_SIZE * 2	// word values

// for frequency table
.const FREQ_TABLE_LENGTH = 64
.const HIGHEST_SEMITONE = 38
.const LOWEST_SEMITONE = HIGHEST_SEMITONE-FREQ_TABLE_LENGTH

// ZP adresses used by varonum evaluation routines
// evaluate the varonum stored in the zero page ZP_EVAL_IN_PTR,ZP_EVAL_IN_PTR+1
// store result in ZP_EVAL_OUT,ZP_EVAL_OUT+1
// Note: zero page adresses $02-06 normalled used by basic floating point 
// Note: zero page adress $07 is used as dimilting char for screen editor; breaks BASIC
.const ZP_EVAL_IN_PTR = $02			// WORD
.const ZP_EVAL_OUT = $04		// WORD
.const ZP_CHANNEL = $06			// BYTE		
.const ZP_VOICE = $07			// BYTE	

// ZP used by UpdateSequences
// note: ZP_FREE,ZP_FREE+1 is used by MUL/DIV operators, so we go up one word
.const ZP_ACCUMULATOR = ZP_FREE+2		// WORD

// zp used by UpdateChannels 
.const ZP_SIDDATA_PTR = ZP_FREE+2			// WORD (0xFD & 0xFE)



//.if (MAX_VOICES*VOICE_SIZE>256) {
//	.error "space for voice data exeeds 256 bytes"
//}

//.if (MAX_SEQUENCES*SEQUENCE_SIZE>256) {
//	.error "space for sequence data exeeds 256 bytes"
//}
//.if (MAX_ARRAYS*ARRAY_SIZE>256) {
//	.error "space for array data exeeds 256 bytes"
//}


// ---- some macros ---- 

.macro InstallRasterIRQHandler(irqhandler, rasterline)
{
        sei							// disable interrups
        lda #<irqhandler
        sta $0314					// set IRQ low byte
        lda #>irqhandler
        sta $0315					// set IRQ high byte
        asl $d019					// clear VIC-II interrupt flags ?
        lda #$7b					
        sta $dc0d					// CIA 1 interrupt control register, clear all interrupt masks
        lda #$81
        sta $d01a					// VIC-II raster scan interupt enable
        lda #$1b
        sta $d011					// VIC-II show screen, 25 rows, normal vertical position 
        lda #rasterline    					// raster line for interupt
        sta $d012					// VIC-II set raster lien for for interupt 
        cli							// enable interrupts        
}


.macro StopRasterIRQ()
{
		sei
	
    	lda #0
    	sta $d01a					// disable all vic interrupts
    
    	// install default IRQ handler
    	.const default_irq_handler = $EA31
    	lda #<default_irq_handler
		sta $0314					// set IRQ low byte
		lda #>default_irq_handler
		sta $0315					// set IRQ high byte
		
		// set cia interrupt enable for timer A
		lda #129
		sta CIA1_ICR
		
		cli
    
}

.macro ReadData()
{
	// copy num voices 
	lda numbersid_data+0			// num voices
	sta num_voices
	
	// debug
	SetCursor(4,0)
	PrintChar('#')
	ByteToHex(num_voices,text_string)
	PrintString(text_string)
	PrintChar(' ')
	

/*
	// copy voice data
	// lda num_voices
	tay						// number of voice
	
	.const ZP_IN = $FC
	.const ZP_OUT = $FE
	Word_Store_Value(ZP_IN, numbersid_data+1)
	Word_Store_Value(ZP_OUT, voices)
	
loop1:

	ldx #VOICE_SIZE/2     // number of parameters
	
loop2:

	Word_Copy(ZP_IN, ZP_OUT)
	Word_Add_Value(ZP_IN,2,ZP_IN)
	Word_Add_Value(ZP_OUT,VOICE_SIZE,ZP_OUT)
	dex
	bne loop2
	
	Word_Add_Value(ZP_OUT,2,ZP_OUT)
	Word_Add_Value(ZP_OUT,-VOICE_SIZE,ZP_OUT)

	dey	
	bne loop1
	
*/

	// calculate start of sequence data
	lda num_voices
	sta ZP_FREE
	lda #VOICE_SIZE
	sta ZP_FREE+1
	Word_Mul_LoHi(ZP_FREE)						// ZP_FREE = num_voices * size
	Word_Add_Value(ZP_FREE, numbersid_data+1, ZP_FREE)	// ptr = data start + 1 + (num_voices * voice_size) 
	
	// save start adrr of channel-voices data
	Word_Copy(ZP_FREE, channel_voices_start_ptr)
	
	// skip 3 words for channel-voice mapping
	// skip 4 words for filter-volume
	Word_Add_Value(ZP_FREE, 14, ZP_FREE)			// ptr = data start + 1 + (num_voices * voice_size) + 14
	
	// dereference ptr to read num_sequences
	Dereference_Byte(ZP_FREE,num_sequences)
	
	// debug
	SetCursor(5,0)
	PrintChar('#')
	ByteToHex(num_sequences,text_string)
	PrintString(text_string)
	PrintChar(' ')
	
	// skip 1 byte for num_sequences
	Word_Add_Value(ZP_FREE, 1, ZP_FREE)			// ptr = data start + 1 + (num_voices * voice_size) + 14
	
	// save pointer to start of sequences
	Word_Copy(ZP_FREE, sequence_data_start_ptr)
	
}



// -------- Varonum evaluation ---- 

// evaluate varonum at given varonum_addr (word)
// store value in value_addr (word)
// affects A,X

.macro Eval_Varonum(varonum_addr, value_addr)
{
	lda varonum_addr+1		// read high byte
	bmi is_variable			// bit 15 indicates type
is_value:
	sta value_addr+1		// store high byte
	
	and #$40							// bit 14 set? (bit 6 on high byte)
	beq not_neg
	lda value_addr+1
	ora #$80							// set bit 15
	sta value_addr+1
	
not_neg:
	lda varonum_addr		// read low byte
	sta value_addr			// store low byte
	jmp end
	
is_variable:
	lda varonum_addr		// read low byte, A is the variable number
	asl 					// times two
	tax						// X is offset in variable_values
	lda variable_values,x	// real low
	sta value_addr			// store low
	lda variable_values+1,x	// read high
	sta value_addr+1		// store high
end:
}


// evaluate varonum at given indirect adress (zeropage),Y
// store value in value_addr (word)
// affects A,X,Y

.macro Eval_Varonum_Indirect_Y(varonum_indirect_zp, value_addr)
{
	iny								// plus one for high byte
	lda (varonum_indirect_zp),y		// read high byte in A
	bmi is_variable					// bit 15 indicates type
is_value:
	sta value_addr+1				// store high byte
	
	and #$40							// bit 14 set? (bit 6 on high byte)
	beq not_neg
	lda value_addr+1
	ora #$80							// set bit 15
	sta value_addr+1
	
not_neg:
	dey								// next load will read low byte
	lda (varonum_indirect_zp),y		// read low byte
	sta value_addr					// store low byte
	jmp end
	
is_variable:
	dey								// next load will read low byte
	lda (varonum_indirect_zp),y		// read low byte, A is the variable number
	asl 							// times 2
	tax								// X is index in variable_values
	lda variable_values,x			// read low
	sta value_addr					// store low
	lda variable_values+1,x 		// read high
	sta value_addr+1				// store high
end:
}


// --------- calculations ------


// sum digits in base x
// accumulator_word: the input and output; word adress 
// base_word: the base (x) to use; word adress 
// uses zero-page: ZP_FREE;ZP_FREE+1
// (and affects most registers)
.macro Base_Sum(accumulator_word, base_word)
{
	Word_Copy(accumulator_word, ZP_FREE)
	Word_Store_Value(accumulator_word, 0)
	// TODO: first test always usign base 2
	ldx #15
loop:
	lda ZP_FREE
	and #1
	beq zero
one:
	Word_Inc(accumulator_word)
zero:
	Signed_Shift_Right(ZP_FREE,1)
	dex
	bne loop
}

// update all sequences
// (requires sequence_data_start_ptr is set)

.macro UpdateSequences() {
	
	SetCursor(6,0)
		
	Word_Copy(sequence_data_start_ptr, sequence_data_cur_ptr)
	
	//ldx num_sequences
	ldx num_sequences
loop_sequences:	
		txa
		pha
		UpdateSequence()
		Word_Add_Value(sequence_data_cur_ptr, SEQUENCE_SIZE, sequence_data_cur_ptr)
		pla
		tax
		dex	
		beq end
		jmp loop_sequences	// far jump
end:

}

// update sequence given by sequence_data_cur_ptr

.macro UpdateSequence() {
	
	
	// set zero page var to first varonum of sequence, used by eval_vaonum_indictect_zp_y
	Word_Copy(sequence_data_cur_ptr, ZP_EVAL_IN_PTR)
	
	Word_Inc(ZP_EVAL_IN_PTR)		// note: skip first byte of sequence 
	
	ldy #0	// y indicates offset in sequence (2 bytes per varonum) 
	jsr eval_varonum_indirect_zp_y
	// first varonum goes to accumulator
	
	Word_Copy(ZP_EVAL_OUT, ZP_ACCUMULATOR)

/*
	// debug
	SetCursor(6,0)
	WordToHex(ZP_EVAL_IN_PTR,text_string)
	PrintString(text_string)
	PrintChar('=')
	
	WordToHex(ZP_EVAL_OUT,text_string)
	PrintString(text_string)
	PrintChar(32)
*/


	// second varonum: add
	iny
	iny
	jsr eval_varonum_indirect_zp_y
	Word_Add_Word(ZP_EVAL_OUT, ZP_ACCUMULATOR, ZP_ACCUMULATOR)
	
	// div
	iny
	iny
	jsr eval_varonum_indirect_zp_y
	Word_Compare_Value(ZP_EVAL_OUT,0)
	beq !skip+
	tya
	pha
	Word_Div_Word(ZP_ACCUMULATOR, ZP_EVAL_OUT, ZP_FREE)
	pla
	tay
!skip:

	// mul
	iny
	iny
	jsr eval_varonum_indirect_zp_y
	Word_Compare_Value(ZP_EVAL_OUT,0)
	beq !skip+
	tya
	pha
	Word_Mul_Word(ZP_ACCUMULATOR, ZP_EVAL_OUT, ZP_ACCUMULATOR)
	pla
	tay
!skip:

	
	// mod
	iny
	iny
	jsr eval_varonum_indirect_zp_y
	Word_Compare_Value(ZP_EVAL_OUT,0)
	beq !skip+
	tya
	pha
	Word_Div_Word(ZP_ACCUMULATOR, ZP_EVAL_OUT, ZP_FREE)		// TODO: need floor-modulus
	Word_Copy(ZP_FREE, ZP_ACCUMULATOR)
	pla
	tay
!skip:


	// base
	iny
	iny
	jsr eval_varonum_indirect_zp_y
	Word_Compare_Value(ZP_EVAL_OUT,0)
	beq !skip+
	tya
	pha
	Base_Sum(ZP_ACCUMULATOR, ZP_EVAL_OUT)
	pla
	tay
!skip:
	
	
	// TODO: mod2
	// TODO: mul2
	// TODO: div2
	// TODO: add2
	// TODO: array
	
	// write accumulator to output variable
	
	
	Word_Copy(sequence_data_cur_ptr,ZP_FREE)		// first element in sequence is output variable
	ldy #0
	lda (ZP_FREE),y				// dereference; A = variable number
	bmi !skip+					// note: output variable = -64 when left empty
	jmp continue			
!skip:						// TMP, for debug need long jump
	jmp end	
continue:
	// for debug
	.if (debug) {
		sta ZP_FREE
	}
	//end debug
	asl							// multiple A by 2 (variable_values is words)
	tax							// X is index in array
	lda ZP_ACCUMULATOR
	sta variable_values,x
	lda ZP_ACCUMULATOR+1
	sta variable_values+1,x
	
	// debug
	.if (debug) {
			.encoding "ascii"
			lda ZP_FREE
			clc
			adc #'A'
			sta ZP_FREE				
			lda #0
			sta ZP_FREE+1
		
			PrintString(ZP_FREE)
			PrintChar('=')
			WordToHex(ZP_ACCUMULATOR,text_string)
			PrintString(text_string)
			PrintChar(32)
	}
end:	
	
}

.macro UpdateChannels() {

	/*
	for each channel c= 1, 2, 3
		varonum vvoice = channel_voice[c]
		int voice = eval_varonum(vvoice)
		
		varonum vgate = voice_data[voice][GATE]
		int gate = eval_varonum(vgate)
		
		sid_data[voice][CONTROL] = gate&&1 + ...
	*/
	
	.if (debug) {
		SetCursor(7,0)
	}
	
	
	// set ZP_SIDDATA_PTR for channel #0
	Word_Store_Value(ZP_SIDDATA_PTR, sid_data)
	
	lda #0
	sta ZP_CHANNEL

loop:
	UpdateChannel()
	
	// next adress for storing channel sid_data, 7 bytes
	Word_Add_Value(ZP_SIDDATA_PTR, 7, ZP_SIDDATA_PTR)   
	
	inc ZP_CHANNEL
	lda ZP_CHANNEL
	cmp #3
	beq done
	jmp loop		// need long jump
done:
	
}

// input values:
//  ZP_CHANNEL (0,1 or 2)
// output:
//  writes to sid_data
.macro UpdateChannel() {

	
	// set ZP_EVAL_IN_PTR to channel_voices (3 varonums)
	lda channel_voices_start_ptr
	sta ZP_EVAL_IN_PTR
	lda channel_voices_start_ptr+1
	sta ZP_EVAL_IN_PTR+1
	
	// y indexes channel given in A (word)
	lda ZP_CHANNEL
	asl		// word index
	tay

	// eval vaonum and store result as voice
	jsr eval_varonum_indirect_zp_y
	lda ZP_EVAL_OUT
	sta ZP_VOICE

	// note: voice 0 is silent, active voices start at 1
	lda ZP_VOICE
	bne not_silent
	jmp silent		// need long jump
	
not_silent:
	
	// ZP_FREE is ZP_VOICE * ZP_VOICE_SIZE
	sec				
	sbc #1				// voice 1 is index 0 in voice data
	sta ZP_FREE
	lda #VOICE_SIZE
	sta ZP_FREE+1
	Word_Mul_LoHi(ZP_FREE)
	
	// set ZP_EVAL_IN_PTR to point to start of voice varonums
	Word_Store_Value(ZP_EVAL_IN_PTR, numbersid_data+1)		// start of varonums of first voice
	Word_Add_Word(ZP_EVAL_IN_PTR, ZP_FREE, ZP_EVAL_IN_PTR)		// +offset for voice
	
	// gate (y=0)
	ldy #0
	jsr eval_varonum_indirect_zp_y
	lda ZP_EVAL_OUT
	and #1
	sta ZP_FREE				// ZP_FREE = gate 0 or 1
	
	// waveform (y=10)
	ldy #10
	jsr eval_varonum_indirect_zp_y
	lda ZP_EVAL_OUT
	clc
	asl
	asl
	asl
	asl					// shift left 4 
	ora ZP_FREE			// or with gate value	
	ldy #SID_CR
	sta (ZP_SIDDATA_PTR),y	
	
	/*
	.if (debug) {
		PrintChar('W')
		WordToHex(ZP_EVAL_OUT,text_string)
		PrintString(text_string)
		PrintChar(32)
	}
	*/
		
	// note
	ldy #2
	jsr eval_varonum_indirect_zp_y
	Word_Add_Value(ZP_EVAL_OUT, -LOWEST_SEMITONE, ZP_EVAL_OUT)
	lda ZP_EVAL_OUT
	asl  // word index
	tax
	lda freq_table,x
	ldy #SID_FREQ_L
	sta (ZP_SIDDATA_PTR),y	
	lda freq_table+1,x
	ldy #SID_FREQ_H
	sta (ZP_SIDDATA_PTR),y
	
	// TODO: 
	// scale (y=4)
	// transpose (y=6)
	// pitch (y=8)
	

	// TODO
	// pulsewidth (y=12)
	ldy #12
	jsr eval_varonum_indirect_zp_y
	lda ZP_EVAL_OUT
	ldy #SID_PW_L
	sta (ZP_SIDDATA_PTR),y
	lda ZP_EVAL_OUT+1
	ldy #SID_PW_H
	sta (ZP_SIDDATA_PTR),y
	
	
	// TODO
	// ring (y=14)
	// sync (y=16)
	
	// attack (y=18)
	ldy #18
	jsr eval_varonum_indirect_zp_y
	lda ZP_EVAL_OUT
	and #$0F
	clc
	asl
	asl
	asl
	asl
	sta ZP_FREE			// ZP_FREE is attack in high nibble
	
	// decay (y=20)
	ldy #20
	jsr eval_varonum_indirect_zp_y
	lda ZP_EVAL_OUT
	and #$0F				// low nybble
	ora ZP_FREE			// or with attack high nibble
	// store in sid_data for this voice
	ldy #SID_ATT_DEC
	sta (ZP_SIDDATA_PTR),y
	
	// sustain (y=22)
	ldy #22
	jsr eval_varonum_indirect_zp_y
	lda ZP_EVAL_OUT
	and #$0F
	clc
	asl
	asl
	asl
	asl
	sta ZP_FREE			// ZP_FREE is sustain in high nibble
	
	// release (y=24)
	ldy #24
	jsr eval_varonum_indirect_zp_y
	lda ZP_EVAL_OUT
	and #$0F				// low nybble
	ora ZP_FREE			// or with sustain high nibble
	// store in sid_data for this voice
	ldy #SID_SUS_REL
	sta (ZP_SIDDATA_PTR),y
	
	// TODO
	// filter (y=28)
	
	/*
	.if (debug) {
		PrintChar('N')
		WordToHex(ZP_EVAL_OUT,text_string)
		PrintString(text_string)
		PrintChar(32)
	}
	*/
	
	silent:
	// TODO: silence channel if voice is 0
	
}

.macro ClearVariableValues() {

	lda #0
	ldx #MAX_VARIABLES
loop:
	sta variable_values,x
	dex
	bne loop

}




// -------------- code section -------------

// generate basic start code

BasicUpstart2(main)

// main

*=* "Main"

main:

	PrintClearScreen()
    
    SetCursor(2,0)
    
	PrintString(help_string)
	
    Word_Store_Value(frame_counter,0)
    
	SidReset()
	
	// SidSetVolumeConst(15)
	
	// clear sid data (25 bytes)
	
	lda #0
	ldx #25
clear_sid_data_loop:
	sta sid_data,x
	dex
	bne clear_sid_data_loop	

	// test code 	
	// set volume (clear filters)
	lda #15
	sta sid_data+SID_FILTER_VOLUME

	// ste a frequency for voice 0
	lda #0
	sta sid_data+SID_V1+SID_FREQ_L
	lda #40
	sta sid_data+SID_V1+SID_FREQ_H
	
	// set attack, decay, sustain, release
	lda #(0|2<<4)   // decay, attack
	sta sid_data+SID_V1+SID_ATT_DEC
	lda #(1|15<<4) 	// release, sustain
	sta sid_data+SID_V1+SID_SUS_REL
	
	// set attack, decay, sustain, release
	lda #(0|2<<4)   // decay, attack
	sta sid_data+SID_V2+SID_ATT_DEC
	lda #(1|15<<4) 	// release, sustain
	sta sid_data+SID_V2+SID_SUS_REL
	
	// set attack, decay, sustain, release
	lda #(0|2<<4)   // decay, attack
	sta sid_data+SID_V3+SID_ATT_DEC
	lda #(1|15<<4) 	// release, sustain
	sta sid_data+SID_V3+SID_SUS_REL
	
	
	// set waveform
	lda #SID_CR_TRI
	sta sid_data+SID_V1+SID_CR
	
	// set pulse width 
	lda #0 
	sta sid_data+SID_PW_L
	lda #1
	sta sid_data+SID_PW_H
	

	// start a note (set bit 0)
	lda sid_data+SID_V1+SID_CR
	ora #1
	sta sid_data+SID_V1+SID_CR


	ReadData()
	
	ClearVariableValues()

	InstallRasterIRQHandler(raster_irq_handler, 50)

		
	loop:

			WaitKey()			// ascii code in A
			//pha
			//SetCursor(4,0)
			//pla
			//jsr CHROUT
			
			.encoding "petscii_upper"
			cmp #'Q'
			beq quit
			
			jmp loop
		
	quit:
		
	StopRasterIRQ()
	
	// return to basic
	rts
	
raster_irq_handler:
{
		// note: IRQ handler at $efff/$ffff pushes a,x,y registers
		// then call this handler (via vector $314/$315)
        asl $d019					// clear VIC-II raster scan interrupt flag
        
        inc $d020					// DEBUG: next border color
        
        UpdateSequences()
        
        UpdateChannels()
        
        // copy sid_data to the chip
        .for(var i=0; i<25; i++) {
        	lda sid_data+i
        	sta SID_BASE+i
        }
        
        // show framenumber top-left
        Word_Inc(frame_counter)
        WordToHex(frame_counter,text_string)
        SetCursor(0,0)
        PrintString(text_string)
        
        // copy frame counter to variable 'T'
        .encoding "ascii"
        Word_Copy(frame_counter, variable_values+(('T'-'A')*2))
        
/*
        // test varnum eval
        
        // create a varonum in zero_page
        lda #('T'-'A')
        sta ZP_EVAL_IN_PTR
        lda #$80
        sta ZP_EVAL_IN_HIGH
        
        // eval it 
        //Eval_Varonum(ZP_FREE, ZP_FREE+2)
        jsr eval_varonum_zp
        // print result
        SetCursor(1,0)
 		WordToHex(ZP_EVAL_OUT,text_string)
        PrintString(text_string)
 */
        
     
        dec $d020					// DEBUG: previous border color
        
        // jump to default interrupt handler (for keyboard handling)
		jmp $EA31
        
        // Note: default interrupt handler above will also pull stack and return from interrupt
        //pla							
        //tay							// 1 byte from stack to Y
        //pla
        //tax                         // 1 byte from stack to X
        //pla							// 1 byte from stack to A
        //rti                         
}

// ---- routines  -----

eval_varonum_zp:
	Eval_Varonum(ZP_EVAL_IN_PTR, ZP_EVAL_OUT)
	rts

eval_varonum_indirect_zp_y:
	Eval_Varonum_Indirect_Y(ZP_EVAL_IN_PTR, ZP_EVAL_OUT)
	rts


// ----------------------------------------
// ------------ data section --------------
// ----------------------------------------

*=* "Frequency table"
/*
# freq table
def note_freq(base, semitones):
    return base*pow(2, semitones/12)
 

# for SID
def sid_value_pal(freq):
    return int(freq * 17.0309)

# SID freq table
#  with semitone 0 at base 440, +37 is the max (<65536). Low end usefulness?
for semitone in range(38-64,38):
    f=note_freq(440,semitone)
    print("{0}\t{1}\t{2}".format(semitone, f, sid_value_pal(f)))  
*/

.function note_freq(base, semitone)
{
	.return base * pow(2, semitone/12)
}

.function sid_freq_pal(freq) {
    // note: 16.40426  for NTSC
	.return floor(freq * 17.034) 
}

.for (var i=0;i<FREQ_TABLE_LENGTH;i++) {
	.var f = sid_freq_pal(note_freq(440, i+LOWEST_SEMITONE))
	.print f
}

// table with SID frequency register values. Index 0 is the lowest semitone, and middle C (440HZ) is at index 0+lowest_semitone 

freq_table:
.fillword FREQ_TABLE_LENGTH, sid_freq_pal(note_freq(440, i+LOWEST_SEMITONE))



*=* "Application Data"

.encoding "petscii_upper"
help_string: .text "NUMBERSID PLAYER - PRESS Q TO QUIT"; .byte 0


*=* "Numbersid Data"

numbersid_data:
.byte 3 // num_voices
.word 32786 // gate S
.word 32768 // note A
.word 1352 // scale
.word 32756 // transpose
.word 0 // pitch
.word 1 // waveform
.word 0 // pulsewidth
.word 0 // ring
.word 0 // sync
.word 1 // attack
.word 0 // decay
.word 15 // sustain
.word 0 // release
.word 1 // filter
.word 32768 // gate A
.word 32768-12 // note -12
.word 1352 // scale
.word 32756 // transpose
.word 0 // pitch
.word 2 // waveform
.word 0 // pulsewidth
.word 0 // ring
.word 0 // sync
.word 1 // attack
.word 0 // decay
.word 15 // sustain
.word 0 // release
.word 1 // filter
.word 32787 // gate T
.word 32768-6 // note   -6
.word 1352 // scale
.word 32756 // transpose
.word 0 // pitch
.word 8 // waveform
.word 0 // pulsewidth
.word 0 // ring
.word 0 // sync
.word 8 // attack
.word 0 // decay
.word 32768 // sustain A
.word 1 // release
.word 1 // filter
.word 1 // channel[0] voice
.word 2 // channel[1] voice
.word 3 // channel[2] voice
.word 2 // filter_mode
.word 100 // cutoff
.word 0 // resonance
.word 15 // volume
.byte 4 // num_sequences
.byte 18 // variable
.word 32787 // count
.word 0 // add1
.word 10 // div1
.word 0 // mul1
.word 0 // mod1
.word 0 // base
.word 0 // mod2
.word 0 // mul2
.word 0 // div2
.word 0 // add2
.word 0 // array
.byte 0 // variable
.word 32786 // count
.word 0 // add1
.word 0 // div1
.word 0 // mul1
.word 0 // mod1
.word 2 // base
.word 0 // mod2
.word 0 // mul2
.word 0 // div2
.word 0 // add2
.word 0 // array
.byte -65 // variable
.word 0 // count
.word 0 // add1
.word 0 // div1
.word 0 // mul1
.word 0 // mod1
.word 0 // base
.word 0 // mod2
.word 0 // mul2
.word 0 // div2
.word 0 // add2
.word 0 // array
.byte -65 // variable
.word 0 // count
.word 0 // add1
.word 0 // div1
.word 0 // mul1
.word 0 // mod1
.word 0 // base
.word 0 // mod2
.word 0 // mul2
.word 0 // div2
.word 0 // add2
.word 0 // array
.byte 2 // num_arrays
.byte 4 // array_size
.word 0 // element
.word 0 // element
.word 0 // element
.word 0 // element
.byte 4 // array_size
.word 0 // element
.word 0 // element
.word 0 // element
.word 0 // element
	
// --------------------------------------
// ------------variables ----------------
// --------------------------------------

// note: this is a virtual segment
// code should reset all to zero (or other default values)

*=* "Variables" virtual
frame_counter: .word 0
text_string: .fill 40,32 ; .byte 0
sid_data: .fill 25, 0

	// TODO: move sid_data to zero_page?

// the values of the variables used in the numbersid sequences
variable_values:
.fillword MAX_VARIABLES, 0

	// TODO: move variable_values to zero_page?
	
	
num_voices: .byte 0

channel_voices_start_ptr: .word 0				// pointer to start of channel-voice data (3 varonums)
										// followed by filter and volume (4 varonums)
num_sequences: .byte 0

sequence_data_start_ptr: .word 0		// pointer to start of sequence data 
 
sequence_data_cur_ptr: .word 0			// pointer to currently processing sequence data 

/*
//-------- TODO: next part maybe not needed ----

// runtime numbersid data 
// created from load-time data 
// more convenient format

channel_voices:
.fillword NUM_CHANNELS, 0 

num_voices:
.byte 0

voices:
//.fill MAX_VOICES * VOICE_SIZE, 0
gate: .fillword MAX_VOICES, 0
note: .fillword MAX_VOICES, 0
scale: .fillword MAX_VOICES, 0
transpose: .fillword MAX_VOICES, 0
pitch: .fillword MAX_VOICES, 0
waveform: .fillword MAX_VOICES, 0
pulsewidth: .fillword MAX_VOICES, 0
ring: .fillword MAX_VOICES, 0
sync: .fillword MAX_VOICES, 0
attack:.fillword MAX_VOICES, 0
decay: .fillword MAX_VOICES, 0
sustain: .fillword MAX_VOICES, 0
release: .fillword MAX_VOICES, 0
filter: .fillword MAX_VOICES, 0

num_sequences:
.word 0				// Note: extra byte just for printing
sequences:
.fill MAX_SEQUENCES * SEQUENCE_SIZE, 0
num_arrays:
.byte 0
arrays:
.fill MAX_ARRAYS * ARRAY_SIZE, 0 
*/
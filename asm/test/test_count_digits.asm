//  test multiplication

#import "common/word_macros.asm"
#import "common/io_macros.asm"

// macro

.macro Base_Sum(accumulator_word, base_word)
{
	Word_Copy(accumulator_word, ZP_FREE)
	Word_Store_Value(accumulator_word, 0)
	// TODO: first test always using base 2, generalize later
	ldx #15
loop:
	lda ZP_FREE
	and #1
	beq zero
one:
	Word_Inc(accumulator_word)
zero:
	Signed_Shift_Right(ZP_FREE,1)	// TODO: signed needed? Just stop shifting after 15?
	dex
	bne loop
}

// generate basic start code

BasicUpstart2(main)

// main

*=* "Main"

main:
    // test base 2 sum    

    .for (var x = 0; x<64; x++)
    {
        Word_Store_Value(word1, x)
        Word_Store_Value(word2, 31)
        Word_Mul_Word(word1, word2, word3)
        Base_Sum(word3, $0)         // 2nd arg is ignored
        
        WordToHex(word3,text_string)
        PrintString(text_string)
        PrintChar(' ')
        
    }
    
    PrintChar(13)

    rts
    
word1: .word  0
word2: .word  0  
word3: .word 0
text_string: .fill 40,32 ; .byte 0

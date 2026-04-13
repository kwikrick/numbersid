//  test multiplication

#import "common/word_macros.asm"
#import "common/io_macros.asm"


// generate basic start code

BasicUpstart2(main)

// main

*=* "Main"

main:
    // test multiplication    

    .for (var x = 0; x<64; x++)
    {
        Word_Store_Value(word1, x)
        Word_Store_Value(word2, 31)
        Word_Mul_Word(word1, word2, word1)    // note: output overlaps!

        // print result (should be x*31)
        
        WordToHex(word1,text_string)
        PrintString(text_string)
        PrintChar(' ')
        
    }
    
    PrintChar(13)

    Word_Store_Value(word1, 0)
    Word_Store_Value(word2, 31)
        
    .for (var x = 0; x<64; x++)
    {
        
        // print result (should be x*31)
        
        WordToHex(word1,text_string)
        PrintString(text_string)
        PrintChar(' ')
        
        Word_Add_Word(word1, word2, word1)      // note: output overlaps!

    }
    Word_Store_Value(word1, 31)
    Word_Store_Value(word2, 2)
    Word_Mul_Word(word1, word2, word1)
    
    rts
    
word1: .word  0
word2: .word  0  
word3: .word 0
text_string: .fill 40,32 ; .byte 0

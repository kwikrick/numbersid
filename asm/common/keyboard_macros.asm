// keyboard macros & routines

#importonce

#import "zeropage_const.asm"
#import "kernal_const.asm"

// waitkey: waits for a keypress (check length of keyboard buffer !=0)
// and returns the character in register A

.macro WaitKey() {
    loop:
    lda NDX             // get keyboard buffer size
    beq loop            // loop if zero length
    jsr GETKBC          // get from buffer, char in A
}

// getkey: does not wait for a keypress, but if there is one (in the buffer) 
// then the return the character in register A
// otherwise, zero is returned in A.

.macro GetKey() {
    lda #0
    lda NDX
    beq done            // if no char in buffer, then done 
    jsr GETKBC          // else: get char from buffer, store in A
done:
}

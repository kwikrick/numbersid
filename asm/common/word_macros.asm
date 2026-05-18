// Math macros with two byte words

#importonce

#import "zeropage_const.asm"

// Set word at addr to value
// Affects: A, flags
.macro Word_Store_Value(addr, value) 
{
    lda #<value                  // low byte
    sta addr
    lda #>value                 // high byte
    sta addr+1
}

// Add value to word at addr
// Affects: A, flags
// Note: tgt can be src1 or src2, overwriting is no problem. (but tgt cannot be src1+1 or src2+1!)  
.macro Word_Add_Value(addr, value, tgt) 
{
    clc
    lda addr             // low byte
    adc #<value
    sta tgt
    lda addr+1           // high byte
    adc #>value
    sta tgt+1
}

// Add words at addresses src1 and src2 and strores result in tgt adress
// Note: tgt can be src1 or src2, overwriting is no problem. (but tgt cannot be src1+1 or src2+1!)  
// Affects: A, flags (last set by ADC on high byte)

.macro Word_Add_Word(src1, src2, tgt) 
{
    clc
    lda src1             // low byte
    adc src2
    sta tgt
    lda src1+1             // high byte
    adc src2+1
    sta tgt+1
}

// Copy word from  addresses src to adress tgt
// Affects: A, flags (last LDA high byte)

.macro Word_Copy(src,tgt) 
{ 
        lda src
        sta tgt
        lda src+1
        sta tgt+1
}

// Shift word at address N times to right
// Note: shift_value must be a variable, not an adress.
// Will be faster if addr is in zero-page   
// Affects: only flags (last ROR low byte)
.macro Unsigned_Shift_Right(addr, shift_value)
{ 
    .for (var i=0;i<shift_value;i++) 
    {
       lsr addr+1
       ror addr
    }
}

// Shift word at address N times to right
// Divide by 2^shift_value
// Note: shift_value must be a variable, not an adress.
// Will be faster if addr is in zero-page   
// Affects: A, flags 
.macro Signed_Shift_Right(addr, shift_value)
{ 
	lda addr+1
	php
	bpl pos
	Word_Neg(addr,addr)
pos:
    Unsigned_Shift_Right(addr, shift_value)
    plp
    bpl done
	Word_Neg(addr,addr)
done:
}


// Shift word at address N times to left
// Note: N must be a contant value, not an adress.
// Will be faster if addr is in zero-page   
// Affects: only flags (last ROR low byte)
.macro Word_Shift_Left(addr, shift_value)
{ 
    .for (var i=0;i<shift_value;i++) 
    {
       asl addr
       rol addr+1
    }
}

// Multiply low byte with high byte at address
// and store result at same adress (as a two byte word in high-low order) 
// Note: much faster if the word in in zero page!
// Affects A,X, flags

.macro Word_Mul_LoHi(addr)
{
    clc
    lda #0
    ldx #8
label1:
    ror
    ror addr
    bcc label2
    clc
    adc addr+1
label2:
    dex
    bpl label1
    sta addr+1
}


// Multiply  
// target_adrr is also a word. Overflow is lost. 
// Note: target_addr must not overlap  src1 or src2!
// Note: uses zero page adresses (ZP_FREE, ZP_FREE+1 = $FB,$FC)
.macro Word_Mul_Word(src1, src2, target_addr)
{
	.const zp_low = ZP_FREE
	.const zp_high = ZP_FREE + 1
    
	// Mul low bytes
    lda src1
    sta zp_low
    lda src2
    sta zp_high
    Word_Mul_LoHi(zp_low)
    
    // copy to target
    Word_Copy(zp_low, target_addr)
    
    // Mul src1 high byte with src2 low byte
    lda src1+1
    sta zp_low
    lda src2
    sta zp_high
    Word_Mul_LoHi(zp_low)
    
    // add result low byte to target high byte
    lda target_addr+1
    clc
    adc zp_low
    sta target_addr+1


    // Mul src2 high byte with src1 low byte
    lda src1
    sta zp_low
    lda src2+1
    sta zp_high
    Word_Mul_LoHi(zp_low)
    
    // add result low byte to target high byte
    lda target_addr+1
    clc
    adc zp_low
    sta target_addr+1

}


// Multiply a word with constant Value
// target_adrr is also a word. Overflow is lost. 
// TODO: what happens if target is src1 ???
// Note: uses zero page adresses (ZP_FREE, ZP_FREE+1 = $FB,$FC)

.macro Word_Mul_Value(src1, value, target_addr)
{
	.const zp_low = ZP_FREE
	.const zp_high = ZP_FREE + 1
    
    // Mul low bytes
    lda src1
    sta zp_low
    lda #<value
    sta zp_high
    Word_Mul_LoHi(zp_low)
    
    // copy to target
    Word_Copy(zp_low, target_addr)
    
    // Mul src1 high byte with src2 low byte
    lda src1+1
    sta zp_low
    lda #<value
    sta zp_high
    Word_Mul_LoHi(zp_low)
    
    // add result low byte to target high byte
    lda target_addr+1
    clc
    adc zp_low
    sta target_addr+1


    // Mul src2 high byte with src1 low byte
    lda src1
    sta zp_low
    lda #>value
    sta zp_high
    Word_Mul_LoHi(zp_low)
    
    // add result low byte to target high byte
    lda target_addr+1
    clc
    adc zp_low
    sta target_addr+1

}


// Divide a word by a byte.
// The result is left in the low byte of the word.
// and the remainder in the high byte of the word.
// The dividing byte is unaffected.
// Note: This routine only works if the result fits in a single byte, i.e. result is <= $FF !!!
// Note: significantly faster when using zero-page adresses!
// ? What happens if we divide by zero? It seems it does nothing, result is equal to initial value. 

.macro Word_Div_Byte(word_addr, byte_addr)
{
    clc
    ldx #$08
    lda word_addr+1
label1:
    rol word_addr
    rol
    bcs label2
    cmp byte_addr
    bcc label3
label2:
    sbc byte_addr
    sec
label3:
    dex
    bne label1
    rol word_addr
    sta word_addr+1
}

// 16 bit division (from: https://codebase.c64.org/doku.php?id=base:16bit_division_16-bit_result)
//divisor	 : adress of word value
//dividend	 : adress of word value
//remainder  : adress of word value
//result = dividend ;save memory by reusing divident to store the result

.macro Word_Div_Word(dividend, divisor, remainder)
{
	.const result = dividend
divide:	
	lda #0	        	// preset remainder to 0
	sta remainder
	sta remainder+1
	ldx #16	        	// repeat for each bit: ...
divloop:	
	asl dividend		//dividend lb & hb*2, msb -> Carry
	rol dividend+1	
	rol remainder		// remainder lb & hb * 2 + msb from carry
	rol remainder+1
	lda remainder
	sec
	sbc divisor			// substract divisor to see if it fits in
	tay	        		// lb result -> Y, for we may need it later
	lda remainder+1
	sbc divisor+1
	bcc skip			// if carry=0 then divisor didn't fit in yet
	sta remainder+1		// else save substraction result as new remainder,
	sty remainder	
	inc result			// and INCrement result cause divisor fit in 1 times
skip:	
	dex
	bne divloop	
}

// Negative of byte value (2s complement)
.macro Byte_Neg(src, tgt)
{
    lda src
    eor #$FF
    clc
    adc #1
    sta tgt
}

// Negative of word value (2s complement)
.macro Word_Neg(src, tgt)
{
    lda src+1
    eor #$FF
    sta src+1
    lda src
    eor #$FF
    clc
    adc #1
    sta src
    lda src+1
    adc #0
    sta src+1
}


// Subtract value from word at src adress and store at tgt adress
// affects A, flags

.macro Word_Sub_Value(src, value, tgt)
{
    sec
    lda src
    sbc #<value
    sta tgt
    lda src+1
    sbc #>value
    sta tgt+1
}

// Subtract src2 from src1 and store result in tgt
// Note tgt may be same as src1 or src2 (but not src1+1 or src2+1)
// affects A, flags
.macro Word_Sub_Word(src1, src2, tgt)
{
    sec
    lda src1
    sbc src2
    sta tgt
    lda src1+1
    sbc src2+1
    sta tgt+1
}

// Subtract value from word at src adress and store at tgt adress
// affects A, flags

.macro Value_Sub_Word(value, src, tgt)
{
    sec
    lda #<value
    sbc src
    sta tgt
    lda #>value
    sbc src+1
    sta tgt+1
}


// Increment word at given address
// Affects: flags Z, N
.macro Word_Inc(addr)
{
	inc addr        // increment low byte
	bne continue	// if not loops to zero, done  
	inc addr+1		// increment high byte
continue:
}


// Decrement word at given address
// Affects: A, flags
.macro Word_Dec(addr)
{
	lda addr			// get low byte
	bne declow			// go to low byte if low byte not zero
	dec addr+1			// decrement high byte
declow:
	dec addr			// decrement low byte
}

// compare a word and a value
// affects: A, flags and uses $FB on zero page for temp storage (difference of low bytes)
// Z is set if values are equal
// C is set if A >= B 
// Use BEQ for ==, BCC for < and BCS for >=
// For signed aritmetic, use BMI for < and BPL for >= instead of BCC and BCS.

.macro Word_Compare_Value(addr, value)
{
	sec
	lda addr
	sbc #<value
	sta $FB
	lda addr+1
	sbc #>value
	bne done
	lda $FB
	beq done
	lda #$01			// clear N flag, clear Z flag
done:
}


// compare a word and a word
// affects: A, flags and uses $FB on zero page for temp storage (difference of low bytes)
// Z is set if values are equal
// C is set if A >= B
// Use BEQ for ==, BCC for < and BCS for >= 
// For signed aritmetic, use BMI for < and BPL for >= instead of BCC and BCS.

.macro Word_Compare_Word(addrA, addrB)
{
	sec
	lda addrA
	sbc addrB
	sta $FB
	lda addrA+1
	sbc addrB+1
	bne done
	lda $FB
	beq done
	lda #$01			// clear N flag, clear Z flag
done:
}

// dereference a pointer to a byte
// pointer_word_addr: adress of a word (of which value is also an adress, i.e. apointer)
// value_byte_addr: adress of byte to write value to 
// affects A,Y
.macro Dereference_Byte(pointer_word_addr, value_byte_addr)
{
	ldy #0
	lda (pointer_word_addr),y
	sta value_byte_addr
}

// dereference a pointer to a word
// pointer_word_addr: adress of a word (of which value is also an adress, i.e. apointer)
// value_word_addr: adress of byte to write value to 
// affects A,Y
.macro Dereference_Word(pointer_word_addr, value_word_addr)
{
	ldy #0
	lda (pointer_word_addr),y
	sta value_word_addr
	iny
	lda (pointer_word_addr),y
	sta value_word_addr+1
}

// TODO: fast divide by 10 (for printing decimal numbers)

// TODO: use pseudo-opps so we don't need seperate version for immediate values and absolute adresses? Possible working for indirect as well?



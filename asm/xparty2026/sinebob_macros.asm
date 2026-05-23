#importonce 

#import "demo_zeropage.asm"

.const BOB_CHARSET = 5
.label bob_charset_addr = BOB_CHARSET*$0800
.print "BOB CHARSET ADDR = "+bob_charset_addr

.const ZP_IRQ_SRC = ZP_IRQ			//word
.const ZP_IRQ_TGT = ZP_IRQ+2		//word
.const ZP_IRQ_OFF = ZP_IRQ+4        // word

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
	cpy #32
	bne loop_init_phases
}

// TODO: this whole init routine may be unnessecary, can be done on the fly by sinebob_update_transitions

.macro BOB_COPY_CHARSET(bob_charset_src)
{
    Fill(bob_charset_addr, 2048, 0)     // clear charset        // TODO: use same fill routine at demo start

    // adress of char to read
    lda #<bob_charset_src 
    sta ZP_IRQ_SRC
    lda #>bob_charset_src
    sta ZP_IRQ_SRC+1

    // adress of char to write
    // skip 8 bytes of first char (0) stays empty
    lda #<(bob_charset_addr+8)
    sta ZP_IRQ_TGT
    lda #>(bob_charset_addr+8)
    sta ZP_IRQ_TGT+1
    
    // copy char 1,2,3,4,5
    ldx #0
loop_block1:
    txa
    pha
    jsr copy_8_times
    Word_Add_Value(ZP_IRQ_SRC,8,ZP_IRQ_SRC) 
    pla
    tax
    inx
    cpx #5                  // TODO: need more? and reverse!
    bne loop_block1

    // copy char 4,3,2
    Word_Add_Value(ZP_IRQ_SRC,-2*8,ZP_IRQ_SRC) 

   ldx #0
loop_block2:
    txa
    pha
    jsr copy_8_times
    Word_Add_Value(ZP_IRQ_SRC,-8,ZP_IRQ_SRC) 
    pla
    tax
    inx
    cpx #3                  // TODO: need more? and reverse!
    bne loop_block2

    jmp exit

    // ------- TODO: sily, subroutine in a macro

copy_8_times:
    ldx #0
loop_character:
    
    ldy #0
loop_row:
    lda (ZP_IRQ_SRC),y
    sta (ZP_IRQ_TGT),y
    iny
    cpy #8
    bne loop_row

    Word_Add_Value(ZP_IRQ_TGT,8,ZP_IRQ_TGT)

    inx
    cpx #8
    bne loop_character
    rts

    // ---- 

    exit:
}


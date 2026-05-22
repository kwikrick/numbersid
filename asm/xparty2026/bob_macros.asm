#importonce 

.const BOB_CHARSET = 5
.label bob_charset_addr = BOB_CHARSET*$0800
.print "BOB CHARSET ADDR = "+bob_charset_addr

.label zp_char_src=zp_free       // word
.label zp_char_tgt=zp_free+2       // word


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


.macro BOB_COPY_CHARSET(bob_charset_src)
{
    Fill(bob_charset_addr, 2048, 0)     // clear charset        // TODO: use same fill routine at demo start

    // adress of char to read
    lda #<bob_charset_src 
    sta zp_char_src
    lda #>bob_charset_src
    sta zp_char_src+1

    // adress of char to write
    // skip 8 bytes of first char (0) stays empty
    lda #<(bob_charset_addr+8)
    sta zp_char_tgt
    lda #>(bob_charset_addr+8)
    sta zp_char_tgt+1
    
    ldx #0
loop_block1:
    txa
    pha
    jsr copy_8_times
    Word_Add_Value(zp_char_src,8,zp_char_src) 
    pla
    tax
    inx
    cpx #5                  // TODO: need more? and reverse!
    bne loop_block1
   
    Word_Add_Value(zp_char_src,-2*8,zp_char_src) 

   ldx #0
loop_block2:
    txa
    pha
    jsr copy_8_times
    Word_Add_Value(zp_char_src,-8,zp_char_src) 
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
    lda (zp_char_src),y
    sta (zp_char_tgt),y
    iny
    cpy #8
    bne loop_row

    Word_Add_Value(zp_char_tgt,8,zp_char_tgt)

    inx
    cpx #8
    bne loop_character
    rts

    // ---- 

    exit:
}


// basic gfx routines

#importonce

#import "vic_const.asm"
#import "default_screen_const.asm"
#import "cia_const.asm"
#import "kernal_const.asm"
#import "zeropage_const.asm"


// WaitScan: wait until scan line is greater than given number)
// affects: A (scanline), flags 
// Note: only works for linenr <=255. Always stops if rasterline high bit is set.
.macro WaitScan(linenr)
{
wait_scan:
    lda VIC_MODE1
    and #VIC_MODE1_SCANHIGH
    bne stop
	lda VIC_SCAN
    cmp #linenr
    bcc wait_scan		// loop if VIC_SCAN < linenr
  stop:
}

// ClearScreen: clears screen at given adress with 1024 bytes of given value 
// Note: this also clears the sprite pointers!
// affects A 
// affects X

.macro ClearScreen(screen,clearByte) {
    lda #clearByte
    ldx #0
Loop:         // The loop label can’t be seen from the outside
    sta screen,x
    sta screen+$100,x
    sta screen+$200,x
    sta screen+$300,x
    inx
    bne Loop
}

// SetupSprite.
// set up sprite data 
//   spritenr: value (0-8)
//   data: pointer to sprite data. Note: data adress must be aligned on a 64 byte boundary.
//         The last byte is the sprite color (low nybble, bits 0-3) and multi-color bit (bit 7).
// Note: does not set VIC-II bank. Sprites must be in same 16K bank as screen. The highest 2 bits of sprite adresss are ignored.  
// Note: Currently only works with screen adress at $400 (and sprite pointers at the end of the 1K block).  
// TODO: allow different screen adress.
// affects: A, flags

.macro SetupSprite(spritenr,data)
{
    // compute value for 64 byte block
    lda #(data >> 6) 
    sta SPRBLK+spritenr

    // set color from last byte of 64 byte block (low nybble, register ignores top nybble)
    lda data+63         
    sta VIC_SPR0_COL+spritenr
    
    // multicolor bit N x pos high bit
    //lda data+63        
    and #$80     // bit 7
    beq clear 
    lda VIC_SPR_MC
    ora #(1 << spritenr)            // set bit N
    jmp done
clear:
    lda VIC_SPR_MC
    and #(~(1 << spritenr))        // clear bit N
done:
    sta VIC_SPR_MC
}

// MoveSprite: move a sprite to x,y position 
// x: adress of unsigned word (low byte, high byte). Note: modulo 512 
// y: adress of unsigned byte (or word, no matter).
// Affects: A, flags

.macro MoveSprite(spritenr, x_addr, y_addr) {

    lda y_addr
    sta VIC_SPR0_Y + spritenr*2    // sprite N x pos

    lda x_addr
    sta VIC_SPR0_X + spritenr*2    // sprite N x pos
    
    // sprite N x pos high bit
    lda x_addr+1
    and #1
    beq clear 
    lda VIC_SPR_HX
    ora #(1 << spritenr)            // set bit N
    jmp done
clear:
    lda VIC_SPR_HX
    and #(~(1 << spritenr))        // clear bit N
done:
    sta VIC_SPR_HX
    
}

// like MoveSprite, but spritenr is also an adress
// affect A,X,Y
.macro MoveSprite2(spritenr_addr, x_addr, y_addr) {

	// Y=spritenr*2
    lda spritenr_addr
    asl						
    tay
    
    // store y pos, and x-low pos
    lda y_addr
    sta VIC_SPR0_Y,y
    lda x_addr
    sta VIC_SPR0_X,y 
    
    // make bitmap for high x 
    lda #1
	ldy spritenr_addr
    beq shift_done
shift:
    asl
    dey
    bne shift
    
shift_done:
	tax			// x holds bitmap
   
	// check x high bit
    lda x_addr+1
    and #1
    beq clear 
    
set:
	txa
	ora VIC_SPR_HX
	jmp done

clear:
	txa
	eor #$FF
	and VIC_SPR_HX

done:
    sta VIC_SPR_HX
    
}


.macro EnableSprite(spritenr)
{
    // enable sprite
    lda VIC_SPR_EN
    ora #(1 << spritenr) 
    sta VIC_SPR_EN
}
    
.macro DisableSprite(spritenr)
{
    // enable sprite
    lda VIC_SPR_EN
    and #~(1 << spritenr) 
    sta VIC_SPR_EN
}

.macro ColorSprite(spritenr, color)
{
    // set color from last byte of 64 byte block (low nybble, register ignores top nybble)
    lda #color         
    sta VIC_SPR0_COL+spritenr
}


// Copies data to the screen (40x25 chars or 1000 color bytes) at screen_addr 
// from the map at src_addr with the given width src_width (max 255) 
// and an offset in the map given by: src_offset_addr (pointing to a word).
// Note: uses zero page $FB,$FC,$FD,$FE  (and A,X,Y,Flags)
// Note: this one is not the fastest for scrolling horizontally, but could be used for onmi-directional scrolling.
// TODO: turn into a complete Blit operation with src_x_pos, src_y_pos, src_width, tgt_xpos, tgt_ypos, tgt_width

.macro CopyToScreenOffset (screen_addr, src_addr, src_offset_addr, src_width) {

    // $FB,$FC for for source adresss
    lda #<src_addr //lo
    adc src_offset_addr
    sta $FB  
    lda #>src_addr //hi
    adc src_offset_addr+1
    sta $FC
    
    // $FD,$FE for for target adresss
    lda #<screen_addr //lo
    sta $FD  
    lda #>screen_addr //hi
    sta $FE
    
    ldx #0          // count rows
outer:
    ldy #0          // count columns
inner:
    lda ($FB),y
    sta ($FD),y
    iny
    cpy #40          // break at column 40
    bne inner
    
    // next source line
    lda $FB
    clc
    adc #src_width
    sta $FB
    lda $FC
    adc #0
    sta $FC 
    
    // next target line (+40)
    lda $FD
    clc
    adc #40
    sta $FD
    lda $FE
    adc #0
    sta $FE 
    
    inx 
    cpx #25      // break at line 25
    bne outer

}


// Copies columns from MapAddr to ScreenAddr where the map is scrolled by a given the number of columns.
// ScreenAddr: adress of screen
// MapAddr: adress of map
// MapWidth: the total number of columns in the map
// scroll_x_byte: points to a byte that specifies the first column of the map. 
// Note: copies full screen of 25x40 characters (or color map data if $D800 is used for ScreenAddr).  
// Note: Faster thann CopyToScreenOffset, but only allows for horizontal scrolling. 
// Note: scroll_x+40 <=255
// Affects registers A,X,Y and flags 

.macro CopyToScreenScrollX (ScreenAddr, MapAddr, scrollx_byte, MapWidth) 
{
	ldx #0
	ldy scrollx_byte
loop:
	.for (var Row=0;Row<25;Row++) 
	{
		lda MapAddr+Row*MapWidth,y
		sta ScreenAddr+Row*40,x
	}
	iny
	inx
	cpx #40
	beq done
	jmp loop
done:
	
}


// Like version CopyToScreenScrollX but copies only the given columns.
// screen_col_start_byte: points to a byte with the start column of the screen
// and screen_col_end_byte: points to a byte tith the end column of the screen
// 

.macro CopyToScreenScrollXColumns (ScreenAddr, MapAddr, scrollx_byte, MapWidth, screen_col_start_byte, screen_col_end_byte) 
{
	// TODO: move code for lookup start and end columns in table to here

	lda screen_col_start_byte
	tax 		// x is screen column
	clc
	adc scrollx_byte
	tay			// y is map column

loop:
	.for (var Row=0;Row<25;Row++) 
	{
		lda MapAddr+Row*MapWidth,y
		sta ScreenAddr+Row*40,x
	}
	iny
	inx
	cpx screen_col_end_byte
	beq done
	jmp loop
done:
	
}

//  Like 2, but with start and end row.
//  StartRow: integer. The first row
//  End Row: integer. The row after the last row that will be copied 
//  (e.g. use 0 and 25 to copy rows 0-24) 

.macro CopyToScreenScrollXRows (ScreenAddr, MapAddr, scrollx_byte, MapWidth, StartRow, EndRow) 
{
	ldx #0
	ldy scrollx_byte
loop:
	.for (var Row=StartRow;Row<EndRow;Row++) 
	{
		lda MapAddr+Row*MapWidth,y
		sta ScreenAddr+Row*40,x
	}
	iny
	inx
	cpx #40
	beq done
	jmp loop
done:
	
}

// A color program, for fast copying of color data.
// Writes 1000 bytes of color data to $D800.
// Uses 5001 bytes of space and 6000 cycles of time.
// It's just 1000 repetions of:
//   lda #color
//   sta $D800+i
// Note: the colors can be set using UpdateColorProgramScrollXColumns
.macro ColorProgram()
{
		.for (var i=0;i<1000;i++) {
			lda #i
			sta $D800+i
		}
		rts
}

// generates a ColorProgram at runtime (saving space in your PRG file)
.macro CreateColorProgram(program_adress)
{
	.label d800plus = ZP_FREE		// word
	lda #$00
	sta d800plus
	lda #$D8
	sta d800plus+1
	
	.label target = ZP_FREE+2		// word
	lda #<program_adress
	sta target
	lda #>program_adress
	sta target+1
	
loop:
	ldy #0
	
	lda #$A9 		// LDA immediate
	sta (target),y
	iny
	
	lda #0 		// immediate placeholder
	sta (target),y
	iny
	
	lda #$8D 	    // STA absolute
	sta (target),y
	iny
	
	lda d800plus		// low byte
	sta (target),y
	iny
	
	lda d800plus+1		// high byte
	sta (target),y
	iny
	
	clc					// inc d800plus
	lda d800plus
	adc #1
	sta d800plus
	lda d800plus+1
	adc #0
	sta d800plus+1
	
	// loop until d800plus = dbe8
	// lda d800plus+1
	cmp #$DB
	bne next
	lda d800plus
	cmp #$E8
	bne next
	beq done
	
next:	
	clc					// inc  target by 5
	lda target
	adc #5
	sta target
	lda target+1
	adc #0
	sta target+1	
	jmp loop
	
done:
	lda #$60	// RTS
	sta (target),y
}

// Updates a color program at given adress (ColorProgAddr).
// Copies color data from color map at MapAddr. Map must have fixed with given by MapWidth.
// Scrolls the map by number of columns given by byte at adress scrollx_byte.
// Copies only columns gvien by bytes at adresses: screen_col_start_byte and screen_col_start_byte.
// Note: affects, A,X,Y registers, zeropage ZP_FREE ($FB).
// Note: the color program can be created by macro ColorProgram.

.macro UpdateColorProgramScrollXColumns (ColorProgAddr, MapAddr, scrollx_byte, MapWidth, screen_col_start_byte, screen_col_end_byte) 
{
	
	.label end_x = ZP_FREE        // Note: max for x = 5*40=200, so will fit in a single byte
	
	lda screen_col_start_byte
	clc
	adc scrollx_byte
	tay			// y is map column
	
	// compute start and end values for x
	lda screen_col_start_byte
	asl		// times 2 
	asl		// times 4
	clc
	adc screen_col_start_byte		// times 5
	tax 		// x is column in color program (5 bytes per column)
	
	lda screen_col_end_byte
	asl		// times 2 
	asl		// times 4
	clc
	adc screen_col_end_byte		// times 5
	sta end_x
	
loop:
	.for (var Row=0;Row<25;Row++) 
	{
		lda MapAddr+Row*MapWidth,y
		sta ColorProgAddr+(Row*40*5)+1,x			// each row is 40 columns * 5 bytes, modify second byte (LDA #color) 
	}
	iny
	//inx; inx; inx; inx; inx	            // 10 cycles
	txa							// 2
	adc #5						// 2
	tax							// 2 -> 6 cycles
	cpx end_x
	beq done
	jmp loop
done:
	
}


// Set horizontal scroll position on VIC-II chip from given byte, using last 3 bits (range 0-7)
// Note: value on chip is 7 minus scroll_x value
.macro SetHorizontalScroll(scroll_x_byte)
{
	lda VIC_MODE2
    and #~VIC_MODE2_HSCROLL		// clear 3 least significant bits
    sta VIC_MODE2
    lda #7						// compute 7 minus scroll position
    sec
    sbc scroll_x_byte
    and #VIC_MODE2_HSCROLL       // set 3 least significant bits
    ora VIC_MODE2               
    sta VIC_MODE2
}


// Set vertical scroll position on VIC-II chip from given byte, using last 3 bits (range 0-7)
// Note: value on chip is 7 minus scroll_y value
// Note: default (power-on) value is 3, which is only way to fit 25 rows exactly
.macro SetVerticalScroll(scroll_y_byte)
{
	lda VIC_MODE1
    and #~VIC_MODE1_VSCROLL		// clear 3 least significant bits
    sta VIC_MODE1
    lda #7						// compute 7 minus scroll position
    sec
    sbc scroll_y_byte
    and #VIC_MODE1_VSCROLL       // set 3 least significant bits
    ora VIC_MODE1              
    sta VIC_MODE1
}

// Set screen adress in VIC register
// Note: aligned to 1K blocks
// Note: currenly only sets VIC_ADDR but not bank. So only correct for bank 0 ($0000-$3FFF)
// TODO: set adress $288 for basic/Kernal print routine  
// TODO: bank switch too (in CIA)? Not so-useful without setting character defenitions also. 

.macro SetScreenAddr(Addr) 
{
	.var value = (((Addr>>10)&$FF)<<4)		// ((adress/1024)%256)*16
	lda VIC_ADDR
	and #$0F		    	 // clear high nybble
	ora #(value&$F0)  	     // set high nybble
	sta VIC_ADDR
}

// Set screen adress in VIC-II register, sets VIC-II bank in CIA and sets $288 for Basic/Kernal print routines.  
// Note: aligned to 1K blocks
// Note: not really properly tested on other banks!

.macro SetScreenAddrComplete(Addr) 
{
	SetScreenAddr(Addr)
	
	.var bank = ~(Addr >> 14)&3		// last two bits, inverted
	lda CIA2_PORT_A
	and #(~3)						// clear bit 0 and 1
	ora #(bank&3)
	sta CIA2_PORT_A					// set bit 0 and 1
	
	lda <Addr			// high bute of screen addr to veriable for kernal/basic print routines
	sta HIBASE
}



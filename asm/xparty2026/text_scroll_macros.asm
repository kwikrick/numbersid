#importonce 

#import "common/vic_const.asm"

// consts

.const SCROLL_START_ROW = 0

.const SCROLL_START_LINE = 50+SCROLL_START_ROW*8
.const SCROLL_END_LINE = 50+(SCROLL_START_ROW+2)*8

// .const SCROLL_COMPUTE_LINE = 200

.const SCROLL_CHARSET = 6		// 0-7; 2 = default, upper; 3=lower		 

.const TEXT_COLOR = 1

// zero page labels

.label zp_free = $FB
.const zp_src = zp_free+1
.const zp_tgt = zp_free+3

.label zp_in = $02
.label zp_out = $03


// other labels

.label screen = $0400
.label screen_row1 = screen + SCROLL_START_ROW*40
.label screen_row2 = screen + (SCROLL_START_ROW+1)*40

.label screen_colors = $D800
.label color_row1 = screen_colors + SCROLL_START_ROW*40
.label color_row2 = screen_colors + (SCROLL_START_ROW+1)*40


.label scroll_charset_addr = SCROLL_CHARSET*$0800
.print "SCROLL CHARSET ADDR = "+scroll_charset_addr 


// choose character set (2 is default, 3 is lowercase) 
.macro ChooseCharacterSet(charset_number){
		// choose charset addr using bit 1-3 VIC_ADDR (note bit 0 is always 1)
		lda VIC_ADDR
		and #~$F   					// clear low bybble
		ora #(charset_number*2+1)
		sta VIC_ADDR
}
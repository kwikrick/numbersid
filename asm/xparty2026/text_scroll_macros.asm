#importonce 

// consts

.const SCROLL_START_ROW = 0

.const SCROLL_START_LINE = 50+SCROLL_START_ROW*8
.const SCROLL_END_LINE = 50+(SCROLL_START_ROW+2)*8

// .const SCROLL_COMPUTE_LINE = 200

.const CHARSET = 4		// 0-7; 2 = default, upper; 3=lower		 

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


.label charset_addr = CHARSET*$0800
.print "CHARSET ADDR = "+charset_addr 

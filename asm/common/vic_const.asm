// adresses of the VIC chip

#importonce

.const VIC_SPR0_X   = $D000        // sprite 0 x pos (low byte)
.const VIC_SPR0_Y   = $D001        // sprite 0 y pos
.const VIC_SPR1_X   = $D002        // sprite 1 x pos (low byte)
.const VIC_SPR1_Y   = $D003        // sprite 1 y pos
.const VIC_SPR2_X   = $D004        // sprite 2 x pos (low byte)
.const VIC_SPR2_Y   = $D005        // sprite 2 y pos
.const VIC_SPR3_X   = $D006        // sprite 3 x pos (low byte)
.const VIC_SPR3_Y   = $D007        // sprite 3 y pos
.const VIC_SPR4_X   = $D008        // sprite 4 x pos (low byte)
.const VIC_SPR4_Y   = $D009        // sprite 4 y pos
.const VIC_SPR5_X   = $D00A        // sprite 5 x pos (low byte)
.const VIC_SPR5_Y   = $D00B        // sprite 5 y pos
.const VIC_SPR6_X   = $D00C        // sprite 6 x pos (low byte)
.const VIC_SPR6_Y   = $D00D        // sprite 6 y pos
.const VIC_SPR7_X   = $D00E        // sprite 7 x pos (low byte)
.const VIC_SPR7_Y   = $D00F        // sprite 7 y pos
.const VIC_SPR_HX   = $D010        // sprite x pos high bits 

.const VIC_MODE1    = $D011         // bitfields for: color mode, bitmap mode, blanking, rows and vertical scrolling
.const    VIC_MODE1_VSCROLL  = $7		// 3 bits for vertical scroll position (inverted)	(default = 3)
.const    VIC_MODE1_ROWS     = $8       // 1 for 25 rows, 0 for 24 rows (default = 1)
.const    VIC_MODE1_BLANK    = $10		// screen blanking. 0 = blank, 1=normal
.const    VIC_MODE1_BITMAP   = $20      // bitmap mode: 0 = off, 1=on
.const    VIC_MODE1_EXTCOL   = $40      // extended color mode: 0=off, 1=on
.const    VIC_MODE1_SCANHIGH = $80		// high bit for scanline >255
.const VIC_SCAN     = $D012         // scan line (read), and write register for raster interrupts
.const VIC_PEN_X    = $D013         // light pen x pos
.const VIC_PEN_Y    = $D014         // light penyx pos
.const VIC_SPR_EN   = $D015         // sprite enable bits (1=enable, 0=off)
 
.const VIC_MODE2    = $D016         // bitfields for chip reset, muticolor mode, number of columns and horizontal scrolling  
.const    VIC_MODE2_HSCROLL  = $7		// 3 bits for scroll postion (inverted)
.const    VIC_MODE2_COLUMNS	 = $8       // 1 for 40 columns, 0 for 38 columns
.const    VIC_MODE2_MULTI    = $10  
.const    VIC_MODE2_RESET    = $20  
.const VIC_SPR_VE   = $D017         // sprite vertical expand bits (1=expand, 0=off)
.const VIC_ADDR     = $D018         // screen base adress (high 4 bits) and character definitions base adress (low 4 bits)
.const VIC_INT      = $D019         // read flags for interrupts: light pen (bit 3), sprite-sprite collisions (bit 2) , sprite-char collision (bit 1), raster scan (bit 0)
.const VIC_INT_EN   = $D01A         // write flags for interrupts: light pen (bit 3), sprite-sprite collisions (bit 2) , sprite-char collision (bit 1), raster scan (bit 0)
.const VIC_SPR_DP   = $D01B         // sprite data priority bits (0 = in front, 1 = behind characters) 
.const VIC_SPR_MC   = $D01C         // sprite multicolor mode (1=multui-color, 0=high res mono)
.const VIC_SPR_HE   = $D01D         // sprite horizontal expansion bits (1=expand, 0=off)
.const VIC_COL_SPR  = $D01E         // sprite-sprite collision (cleared on read)
.const VIC_COL_CHR  = $D01F         // sprite-character collision (cleared on read)

.const VIC_BORDER   = $D020         // border color         (4 lowest bits)
.const VIC_BG       = $D021         // bg color             (4 lowest bits)
.const VIC_BG1      = $D022         // bg color 1           (4 lowest bits)
.const VIC_BG2      = $D023         // bg color 2           (4 lowest bits)
.const VIC_BG3      = $D024         // bg color 3           (4 lowest bits)
.const VIC_SPR_MC0  = $D025         // sprite multicolor 0  (4 lowest bits)
.const VIC_SPR_MC1  = $D026         // sprite multicolor 1  (4 lowest bits)

.const VIC_SPR0_COL   = $D027       // sprite 0 color (4 lowest bits)
.const VIC_SPR1_COL   = $D028       // sprite 1 color (4 lowest bits)
.const VIC_SPR2_COL   = $D029       // sprite 2 color (4 lowest bits)
.const VIC_SPR3_COL   = $D02A       // sprite 3 color (4 lowest bits)
.const VIC_SPR4_COL   = $D02B       // sprite 4 color (4 lowest bits)
.const VIC_SPR5_COL   = $D02C       // sprite 5 color (4 lowest bits)
.const VIC_SPR6_COL   = $D02D       // sprite 6 color (4 lowest bits)
.const VIC_SPR7_COL   = $D02E       // sprite 7 color (4 lowest bits)


// --- vars----

*=* "Text scroll variables" virtual

// 512 chars (for now)
text_buffer_row1:
.fill 512, 32		// spaces

// 512 chars (for now)
text_buffer_row2:
.fill 512, 32		// spaces

text_offset: 
.word 0

scroll_pos:
.byte 0			// todo, if 8 is needed, move to code?

//*=charset_addr
//
//.fill 2048, random()*65536




// --- vars----

.const text_length = text_data_end - text_data

// 512 chars (for now)
text_buffer_row1:
.fill text_length*2, 32		// spaces

// 512 chars (for now)
text_buffer_row2:
.fill text_length*2, 32		// spaces

// hardwarde scroll value (0-7) for VICII xscroll register  
scroll_pos:
.byte 0



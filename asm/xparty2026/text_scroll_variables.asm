
// --- vars----

// TODO: use fixed max length, so we don't have to adjust number of bytes cleared.

.const text_length = text_data_end - text_data

text_buffer_row1:
.fill text_length*2, 32		// spaces

text_buffer_row2:
.fill text_length*2, 32		// spaces

// hardwarde scroll value (0-7) for VICII xscroll register  
scroll_pos:
.byte 0



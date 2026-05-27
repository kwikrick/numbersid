
// --- vars----

.const text_length = text_data_end - text_data

// 512 chars (for now)
text_buffer_row1:
.fill text_length*2, 32		// spaces

// 512 chars (for now)
text_buffer_row2:
.fill text_length*2, 32		// spaces

text_offset: 
.word 0

scroll_pos:
.byte 0			// todo, if 8 is needed, move to code?



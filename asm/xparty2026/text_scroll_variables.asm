
// --- vars----

.const text_length = text_data_end - text_data

.if (text_length > MAX_TEXT_LENGTH) {
    .error "text_length > MAX_TEXT_LENGTH"
}

text_buffer_row1:
.fill MAX_TEXT_LENGTH*2, 32		// spaces

text_buffer_row2:
.fill MAX_TEXT_LENGTH*2, 32		// spaces

// hardwarde scroll value (0-7) for VICII xscroll register  
scroll_pos:
.byte 0



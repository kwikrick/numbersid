// ----- text scroll data ------

// max 256 chars (for now)
text_data:
.encoding "screencode_upper"
.text "HELLO XPARTY! I GOT MY C64 ONLY TWO YEARS AGO AND FELL IN LOVE. THIS IS MY FIRST DEMO. PLEASE HAVE MERCY. FRACTAL MUSIC AND GRAPHICS COMPUTED REAL-TIME. MANY THANKS TO: ALL OF YOU KEEPING THE SCENE ALIVE. CODE BY KWIKRICK, UNAFFELIATED."
.fill 256-(*-text_data), 32		// spaces

text_gradient:
.byte  9,  5,  5,  13 
.byte 13,  7,  1,   7
.byte 13, 13, 13,  13
.byte 13, 13, 13,  13
.byte  5,  5,  9,   9 
// 20 bytes, repeated to fill 40 columns
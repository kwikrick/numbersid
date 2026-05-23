#importonce 

#import "demo_zeropage.asm"

.const BOB_CHARSET = 5
.label bob_charset_addr = BOB_CHARSET*$0800
.print "BOB CHARSET ADDR = "+bob_charset_addr

.const ZP_IRQ_SRC = ZP_IRQ			//word
.const ZP_IRQ_TGT = ZP_IRQ+2		//word
.const ZP_IRQ_OFF = ZP_IRQ+4        // word

.const BOB_NUM_SINES = 8            // must be a multiple of 2 (X and Y)

.const BOB_CHAR_START = 64          // first char in charset used for bobs

.macro BOB_INIT_PHASES()
{
    // set inital phases for y axis (quarter cycle over x)
	lda #64
	ldy #0
loop_init_phases:
	sta phases+3,y		// y high
	iny
	iny
	iny
	iny
	cpy #BOB_NUM_SINES*2       // two bytes per sine
	bne loop_init_phases
}



// ------ to be used by generated code ------

.const Sine_Param_freq = 0
.const Sine_Param_amplitude = 1

.macro Apply_Variable_To_Sine_Parameter(variable, sine, parameter) {
	.print "Apply_Variable_To_Sine_Parameter(" + variable + " " + sine + " " + parameter +")"

    ldx #((variable-'A')*2)
    .if (parameter == Sine_Param_freq) {
        lda variable_values,x
        sta freqs,x
        lda variable_values+1,x
        sta freqs+1,x
    }
    .if (parameter == Sine_Param_amplitude)
    {
        lda variable_values,x
        sta amplitudes,x
        lda variable_values+1,x
        sta amplitudes+1,x
    }
}


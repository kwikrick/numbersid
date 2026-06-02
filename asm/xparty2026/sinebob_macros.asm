#importonce 

#import "demo_zeropage.asm"

.const MAX_BOBS = 8
.const MAX_SINES = 32

.const BOB_CHARSET = 7
.label bob_charset_addr = BOB_CHARSET*$0800
.print "BOB CHARSET ADDR = "+bob_charset_addr

.const ZP_IRQ_SRC = ZP_IRQ			//word
.const ZP_IRQ_TGT = ZP_IRQ+2		//word
.const ZP_IRQ_OFF = ZP_IRQ+4        // word

.const BOB_CHARSET_START = 128          // first char in charset used for bobs
.const BOB_CHARSET_LENTGH = 128
.const BOB_CHARSET_STEP = BOB_CHARSET_LENTGH / 8 

.const CLEAR_HISTORY_SIZE = 256    // 2 bytes per history entry

// .macro BOB_INIT_PHASES()
// {
//     // set inital phases for y axis (quarter cycle over x)
// 	lda #64
// 	ldy #0
// loop_init_phases:
// 	sta phases+3,y		// y high
// 	iny
// 	iny
// 	iny
// 	iny
// 	cpy #NUM_SINES*2       // two bytes per sine; note: constant from generated_header.ash
// 	bne loop_init_phases
// }



// ------ to be used by generated code ------

//.const Global_Param_bob_color = global_param_count++
//.const Global_Param_bob_step = global_param_count++

.const Sine_Param_freq = 0
.const Sine_Param_amplitude = 1
.const Sine_Param_phase = 2

.macro Apply_Variable_To_Sine_Parameter(variable, sine, parameter) {
	.print "Apply_Variable_To_Sine_Parameter(" + variable + " " + sine + " " + parameter +")"


    // TODO: this is 16 bytes, but pretty fast; compare with  Apply_Variable_To_Voice_Parameter, is 12 bytes, but slower

    ldx #((variable-'A')*2)
    ldy #sine*2
    .if (parameter == Sine_Param_freq) {
        lda variable_values,x
        sta freqs,y
        lda variable_values+1,x
        sta freqs+1,y
    }
    .if (parameter == Sine_Param_amplitude)
    {
        // TODO: negative values ok?
        lda variable_values,x               // Note: only 1 byte needed
        sta amplitudes,y
        //lda variable_values+1,x
        //sta amplitudes+1,x
    }
    .if (parameter == Sine_Param_phase)
    {
        // TODO: negative values ok?
        lda variable_values,x              // Note: only 1 byte needed
        sta phases,y                
        //lda variable_values+1,x
        //sta phases+1,x
    }
}


.const Bob_Param_step = 0
.const Bob_Param_color = 1
.const Bob_Param_position_x = 2
.const Bob_Param_position_y = 3
.const Bob_Param_enable = 5

.macro Apply_Variable_To_Bob_Parameter(variable, bob, parameter) {
	.print "Apply_Variable_To_Bob_Parameter(" + variable + " " + bob + " " + parameter +")"

    // TODO: this is 16 bytes, but pretty fast; compare with  Apply_Variable_To_Voice_Parameter, is 12 bytes, but slower

    ldx #((variable-'A')*2)
    ldy #bob*2
  
    .if (parameter == Bob_Param_step) {
         // TODO: negative values ok?
        lda variable_values,x
        sta bob_steps,y
        //lda variable_values+1,x
        //sta bob_steps+1,y
    }
    .if (parameter == Bob_Param_color)
    {
         // TODO: negative values ok?
        lda variable_values,x               // Note: only 1 byte needed
        sta bob_colors,y
        //lda values+1,x
        //sta amplitudes+1,x
    }
    .if (parameter == Bob_Param_enable) {
         // TODO: negative values ok?
        lda variable_values,x               // Note: only 1 byte needed
        sta bob_enables,y
        //lda values+1,x
        //sta bob_enables+1,x
    }
    .if (parameter == Bob_Param_position_x) {       
        lda variable_values,x
        sta bob_position_xs,y
        lda variable_values+1,x
        sta bob_position_xs+1,y
    }
    .if (parameter == Bob_Param_position_y) {
        lda variable_values,x
        sta bob_position_ys,y
        lda variable_values+1,x
        sta bob_position_ys+1,y
    }
    
}



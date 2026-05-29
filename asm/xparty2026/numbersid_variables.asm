#import "numbersid_macros.asm"

sid_data: .fill 25, 0

.label sid_filter_l = sid_data+SID_FILTER_L
.label sid_filter_h = sid_data+SID_FILTER_H
.label sid_filter_res_voice = sid_data+SID_FILTER_RES_VOICE
.label sid_filter_volume = sid_data+SID_FILTER_VOLUME

// the values of the variables used in the numbersid sequences
variable_values:
.fillword MAX_VARIABLES, 0

sequence_dirty:
.fill MAX_SEQUENCES, 0

voice_parameter_values:
.fill MAX_VOICES * 16 * 2, 0			// reserve 16 words per voice; faster to compute by 4xlshift

// Note: the labels of global parameters must end with "_parameter_value" to work with code gen
global_parameter_values:
filter_mode_parameter_value: .word 0
filter_cutoff_parameter_value: .word 0
filter_resonance_parameter_value: .word 0
volume_parameter_value: .word 0

// TODO: i'd like to move this to sinebob_variables.asm, 
// but needs to be adjacent to other global parameters. For now...
//bob_color_parameter_value: .word 0
//bob_step_parameter_value: .word 0


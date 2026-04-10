//Memory layout
//-----

.const  NUM_CHANNELS    = 3         // SID hardware channels

.const  MAX_SEQUENCES   = 16
.const  MAX_VARIABLES   = 26    // A-Z
.const  MAX_ARRAYS      = 8
.const  MAX_ARRAY_SIZE  = 16
.const  MAX_VOICES      = 8			// max_voices * 11 musyt be less than 256 
.const  MAX_VARONUMS 	= 256		// due to indirect adressing constraints; but is it enough???
.const  MAX_VARIABLE_USE = 9		// MAX_VARIABLES*MAX_USE <= 256 enough? might be problem in arrays
.const  MAX_SEQUENCE_VARONUMS = 16		// 10*10 <=256

*=* "Structure" virtual

// from the original data
// actually we could add these labels in the generated data

num_voices: .byte 0
num_sequences: .byte 0
num_arrays: .byte 0

// re-structured data

channel_voice_varonum_indexes: .fill 3, 0                // one byte for each index to a varonum

sequence_input_variables: .fill MAX_SEQUENCES, 0         // one byte for each index to a variable
sequence_output_variables: .fill MAX_SEQUENCES, 0        // one byte for each index to a variable
sequence_varonum_indexes: .fill MAX_SEQUENCES*MAX_SEQUENCE_VARONUMS, 0 	// one byte for each index to a varonum
sequence_dirty: .fill MAX_SEQUENCES, 0 					// one byte for each dirty flag

voice_gate_varonum_indexes: .fill MAX_VOICES, 0
voice_note_varonum_indexes: .fill MAX_VOICES, 0
//.. etc for 11 parameters

filter_cutoff_varonum_index: .byte 0			// index of varonum
filter_resonance_varonum_index: .byte 0			// index of varonum
filter_volume_varonum_index: .byte 0		// index of varonum

varonum_types: .fill MAX_VARONUMS, 0
varonum_variables: .fill MAX_VARONUMS, 0
varonum_values_low: .fill MAX_VARONUMS, 0
varonum_values_high: .fill MAX_VARONUMS, 0
varonum_dirty: .fill MAX_VARONUMS, 0												// needed? Perhaps not if seuences, parameters and arrays are marked

variable_values_low: .fill MAX_VARIABLES, 0 
variable_values_high: .fill MAX_VARIABLES, 0
variable_values_dirty: .fill MAX_VARIABLES, 0 	 										// needed?


variable_used_in_varonum_indexes:.fill MAX_VARIABLES * MAX_VARIABLE_USE, 0				// needed? 
variable_used_in_sequence: .fill MAX_VARIABLES * MAX_VARIABLE_USE, 0					// to mark as dirty when value changed
variable_used_in_voice_parameter: .fill MAX_VARIABLES * MAX_VARIABLE_USE, 0             // to send to sid when value changed
variable_used_in_channel_voice: .fill MAX_VARIABLES * MAX_VARIABLE_USE, 0               // to send all voice parameters to sid when 
variable_used_in_array: .fill MAX_VARIABLES * MAX_VARIABLE_USE, 0 						// TODO

		
// TODO: arrays






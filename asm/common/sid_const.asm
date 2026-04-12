// SID chip constants


#importonce

.const SID_BASE   		= $D400        // SID chip base adress

// offset for voice relative to sid_base
.const SID_V1		= 0
.const SID_V2		= 7
.const SID_V3		= 14

// per voice control registers
// offsets on SID_BASE+Voice*7+offset
// note: write only!

.const SID_FREQ_L		 = 0			// frequency low byte	
.const SID_FREQ_H		 = 1			// frequency high byte
.const SID_PW_L			 = 2 			// pulse width bits 0-7
.const SID_PW_H			 = 3 			// register low four bits map to pw bit 8-11 
.const SID_CR			 = 4			// control register
    .const SID_CR_GATE		 = 1							//  bit 0: GATE (write 1 to start attack, write 0 to start release)
	.const SID_CR_SYNC		 = 2							//  bit 1: SYNC (sync freq to previous voice) 
	.const SID_CR_RING		 = 4							//  bit 2: RING (ring modulation using previous voice's freq)
	.const SID_CR_TEST		 = 8							//  bit 3: TEST (write 1 to suspend voice, write 0 to restart.)
	.const SID_CR_TRI		 = 16							//  bit 4: triange waveform
	.const SID_CR_SAW		 = 32							//  bit 5: saw waveform
	.const SID_CR_PULSE		 = 64							//  bit 6: pulse wwaveform
	.const SID_CR_NOISE      = 128							//  but 7: noise; Note: do not combine with oter waveforms, or voice locks (unlock: SET TEST + CLEAR TEST)
.const SID_ATT_DEC		= 5				// attack time (high bibble) and decay time(low nibble)  
.const SID_SUS_REL		= 6				// sustain level (high nibble) and release time (low nibble)  

// global registers (not per-voice) 
// use SID_BASE + offset
// Note: write only!

.const SID_FILTER_L				= 21				// filter bits 0,1,2 (rest unused)
.const SID_FILTER_H				= 22				// filter bits 3-10 
			// TODO document filter bits
.const SID_FILTER_RES_VOICE 	= 23				// filter resonsance (high nibble) and voice selection (low nibble)
	.const SID_FILTER_V0	    	= 1						// bit 0 - voice 1
	.const SID_FILTER_V1	    	= 2						// bit 1 - voice 2
	.const SID_FILTER_V2	    	= 4						// bit 2 - voice 3
	.const SID_FILTER_EXT			= 8						// bit 3 - external input
	.const SID_FILTER_RES_MASK		= $F0					// bit 4-7 - filter resonance

.const SID_FILTER_VOLUME 		= 24					// filter type (high nibble) and volume (low nibble) 
	.const SID_VOLUME_MASK 			= $F						// bit 0-3 volume
	.const SID_FILTER_LOWPASS 		= 16						// bit 4: low pass filter
	.const SID_FILTER_BANDPASS 		= 32						// bit 5: low pass filter
	.const SID_FILTER_HIGHPASS 		= 64						// bit 6: low pass filter
	.const SID_FILTER_CUT3 	  		= 128						// bit 7: voice 3 cutout  (silenced, but still generates envelope and wave)
	
// read only registers
.const SID_POTX					= 25			// poteniometer X 
.const SID_POTY					= 26			// poteniometer Y
.const SID_WAVE3				= 27			// wave form of voice 3
.const SID_ENV3					= 28 			// envelope of voice 3


	


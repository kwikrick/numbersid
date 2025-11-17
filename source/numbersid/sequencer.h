/*
    Sequencer core logic. 

    Do this:
    ~~~C
    #define CHIPS_UI_IMPL
    ~~~
    before you include this file in *one* C++ file to create the
    implementation.

*/

#include <stdlib.h>

typedef struct {
    char variable;           // if 0, then number
    int16_t number;
} var_or_number_t;


typedef struct {
    char variable;
    var_or_number_t count;

    var_or_number_t add1;
    var_or_number_t div1;
    var_or_number_t mul1;
    var_or_number_t mod1;

    var_or_number_t base;

    var_or_number_t mod2;
    var_or_number_t mul2;
    var_or_number_t div2;
    var_or_number_t add2;
} sequence_t;

typedef struct {
    var_or_number_t gate;
    var_or_number_t note;
    var_or_number_t scale;
    var_or_number_t transpose;
    var_or_number_t pitch;
    var_or_number_t waveform;
    var_or_number_t pulsewidth;
    var_or_number_t ring;
    var_or_number_t sync;    
    var_or_number_t attack;
    var_or_number_t decay;
    var_or_number_t sustain;
    var_or_number_t release;
    var_or_number_t filter;
} voice_t;

#define NUM_PREVIEW_ROWS 50
#define NUM_PREVIEW_COLS 8

typedef struct {
    int step;
    int offset;
    bool follow;
    char variables[NUM_PREVIEW_COLS];
    uint16_t frames[NUM_PREVIEW_ROWS];
    int16_t values[NUM_PREVIEW_ROWS][NUM_PREVIEW_COLS];
} preview_t;

#define NUM_SEQUENCES  16

typedef struct {
    m6581_t* sid;
    bool running;
    bool muted;
    int frame;
    sequence_t sequences[NUM_SEQUENCES];
    voice_t voices[3];
    var_or_number_t filter_mode;
    var_or_number_t cutoff;
    var_or_number_t resonance;
    var_or_number_t volume;
    int16_t values[26];             // A-Z
    preview_t preview;
} sequencer_t;

/*-- IMPLEMENTATION ----------------------------------------------------------*/
#ifdef CHIPS_IMPL

void sequencer_init(sequencer_t* sequencer, m6581_t* sid) {
    sequencer->sid = sid;
    sequencer->frame = 0;
    sequencer->running = true;
    sequencer->muted = false;
    // nice defaults
    sequencer->volume.number = 15;
    sequencer->preview.step = 1;
    sequencer->preview.follow = true;
    for (int i=0;i<3;i++){
        sequencer->voices[i].waveform.number = 1;
        sequencer->voices[i].sustain.number = 15;
    }
    for (int i=0;i<NUM_SEQUENCES;i++){
        sequencer->sequences[i].mul1.number = 1;
        sequencer->sequences[i].mul2.number = 1;
    }
    
    // add a test sequence
    sequencer->sequences[0] = (sequence_t){
        .variable = 'S',
        .count = (var_or_number_t){.variable = 'T'},
        .div1 = (var_or_number_t){.number = 10},
        .mul1 = (var_or_number_t){.number = 1},
        .base = (var_or_number_t){.number = 0},
        .mul2 = (var_or_number_t){.number = 1},
    };
    sequencer->sequences[1] = (sequence_t){
        .variable = 'A',
        .count = (var_or_number_t){.variable = 'S'},
        .mul1 = (var_or_number_t){.number = 1},
        .base = (var_or_number_t){.number = 2},
        .mul2 = (var_or_number_t){.number = 1},
    };
}

int16_t floor_mod(int16_t value, int16_t mod) {
    int16_t absmod = abs(mod);
    int16_t count = value / absmod;
    if (value < 0) count = (value - absmod + 1) / absmod;
    int16_t result = value - (count*absmod);
    if (mod < 0) result = absmod - result - 1;
    return result;
}

float note_freq(float base, float semitones) {
    return base*pow(2, semitones/12);
}

uint16_t freq_to_sid_value_pal(float freq) {
    return (uint16_t)(freq * 17.0309);
}

int16_t varonum_eval(var_or_number_t* varonum, sequencer_t* sequencer) {
    if (varonum->variable == 0) {
        return varonum->number;
    }
    else {
        uint8_t var_index = (varonum->variable - 'A') % 26;
        return sequencer->values[var_index];
    }
} 

int16_t sum_digits(int16_t base, int16_t value) {
    if (base <= 1) return value;        // TODO more options
    int16_t remainder = value;
    int16_t sum = 0;
    while(remainder != 0) {
        int16_t digit = floor_mod(remainder,base);
        sum += digit;
        remainder = remainder / base;
    }
    return sum;
}

// returns number of fingers
// fills finger_note map, must be array of size 12
uint8_t decode_scale(int16_t scale, uint8_t* finger_notes) 
{
    memset(finger_notes, 0, 12);        // clear 12 bytes
    int16_t remainder = scale;
    int8_t fingers = 0;
    int8_t note = 0;
    while(remainder != 0) {
        int16_t digit = remainder % 2;
        if (digit) { 
            finger_notes[fingers] = note;
            fingers += 1;
        }
        remainder = remainder / 2;
        note+=1;
    }
    return fingers;
}

void update_sequence(sequence_t* sequence, sequencer_t* sequencer) {
    if (sequence->variable == 0) return;    // inactive sequence
    
    int16_t count = varonum_eval(&sequence->count, sequencer);
    int16_t base = varonum_eval(&sequence->base, sequencer);
    int16_t add1 = varonum_eval(&sequence->add1, sequencer);
    int16_t div1 = varonum_eval(&sequence->div1, sequencer);
    int16_t mul1 = varonum_eval(&sequence->mul1, sequencer);
    int16_t mod1 = varonum_eval(&sequence->mod1, sequencer);
    int16_t mod2 = varonum_eval(&sequence->mod2, sequencer);
    int16_t mul2 = varonum_eval(&sequence->mul2, sequencer);
    int16_t div2 = varonum_eval(&sequence->div2, sequencer);
    int16_t add2 = varonum_eval(&sequence->add2, sequencer);

    int16_t value = count; 
    
    value = value + add1;

    if (div1 != 0) {
        value = value / div1;
    }

    value = value * mul1;
    
    if (mod1 != 0) {                     // TODO: more options?
        value = floor_mod(value,mod1);
    }
    
    value = sum_digits(base, value);
    
    if (mod2 != 0) {                     // TODO: more options?
        value = floor_mod(value,mod2); 
    }
    
    value = value * mul2;
    
    if (div2 != 0) {
        value = value / div2;
    }
    value = value + add2;

    // get old sequence value
    uint8_t var_index = (sequence->variable - 'A') % 26;
    uint16_t old = sequencer->values[var_index];

    // determine change first bit from zero to non-zero
    if ((old%2) == 0 && (value%2) != 0) {
        // used as voice gate? increment X,Y,Z, reset U,V,W
        for (int voice=0;voice<3;++voice){
            if (sequencer->voices[voice].gate.variable == sequence->variable) {
                uint8_t gate_count_index = 'X' + voice - 'A';
                sequencer->values[gate_count_index] += 1;           // TODO: skip if time is not updated!
                uint8_t gate_time_index = 'U' + voice - 'A';
                sequencer->values[gate_time_index] = 0;
            }
        }
    }
    
    // store result
    sequencer->values[var_index] = value;
}

void update_sid(sequencer_t* sequencer)
{
    for (int v=0;v<3;v++) {

        // ctrl
        int16_t gate = varonum_eval(&sequencer->voices[v].gate, sequencer);
        int16_t sync = varonum_eval(&sequencer->voices[v].sync, sequencer);
        int16_t ring = varonum_eval(&sequencer->voices[v].ring, sequencer);
        int16_t wave = varonum_eval(&sequencer->voices[v].waveform, sequencer);
        _m6581_set_ctrl(&sequencer->sid->voice[v], (gate&1) + ((sync&1)<<1) + ((ring&1)<<2 ) + ((wave&15)<<4));

        // compute freqence from  note, scale,trans,pitch
        int16_t note = varonum_eval(&sequencer->voices[v].note, sequencer);
        int16_t scale = varonum_eval(&sequencer->voices[v].scale, sequencer);
        int16_t transpose = varonum_eval(&sequencer->voices[v].transpose, sequencer);
        int16_t pitch = varonum_eval(&sequencer->voices[v].pitch, sequencer);

        scale = scale & ((1<<12)-1);            // 12 bits for 2 notes in a scale
        if (scale == 0) scale = ((1<<12)-1);    // default full chromatic scale
        uint8_t finger_notes[12];
        uint8_t fingers = decode_scale(scale, finger_notes);
        if (fingers == 0) fingers = 1;         // should not happen if scale !=0, but just in case
        int16_t octave = note / fingers;
        if (note < 0) octave = (note - fingers+1) / fingers;          // because we want floor(note / fingers) but using integer math 
        int16_t finger = note - (octave * fingers);
        int16_t semitone = octave * 12 + finger_notes[finger];
        semitone += transpose;
        float freq = note_freq(440.0, (float)semitone + (float)pitch/100);
        
        int16_t sid_freq_value = freq_to_sid_value_pal(freq);
        _m6581_set_freq_hi(&sequencer->sid->voice[v], (sid_freq_value>>8));
        _m6581_set_freq_lo(&sequencer->sid->voice[v], (sid_freq_value&0xFF));

        // pulsewidth
        int16_t pulsewidth = varonum_eval(&sequencer->voices[v].pulsewidth, sequencer);
        _m6581_set_pw_lo(&sequencer->sid->voice[v], (pulsewidth&0xFF));
        _m6581_set_pw_hi(&sequencer->sid->voice[v], (pulsewidth>>8));

        // envelope
        int16_t attack = varonum_eval(&sequencer->voices[v].attack, sequencer);
        int16_t decay = varonum_eval(&sequencer->voices[v].decay, sequencer);
        int16_t sustain = varonum_eval(&sequencer->voices[v].sustain, sequencer);
        int16_t release = varonum_eval(&sequencer->voices[v].release, sequencer);
        _m6581_set_atkdec(&sequencer->sid->voice[v], ((attack&15)<<4) + (decay&15));
        _m6581_set_susrel(&sequencer->sid->voice[v], ((sustain&15)<<4) + (release&15));
        
    }

    int16_t cutoff = varonum_eval(&sequencer->cutoff, sequencer);
    _m6581_set_cutoff_lo(&sequencer->sid->filter, (cutoff&0xFF));
    _m6581_set_cutoff_hi(&sequencer->sid->filter, (cutoff>>8));

    int16_t resonance = varonum_eval(&sequencer->resonance, sequencer);
    int16_t filter1 = varonum_eval(&sequencer->voices[0].filter, sequencer);
    int16_t filter2 = varonum_eval(&sequencer->voices[1].filter, sequencer);
    int16_t filter3 = varonum_eval(&sequencer->voices[2].filter, sequencer);
    
    _m6581_set_resfilt(&sequencer->sid->filter, 
        ((resonance&15)<<4)  + (filter1&1) + ((filter2&1)<<1) + ((filter3&1)<<2));

     int16_t volume = varonum_eval(&sequencer->volume, sequencer);
     int16_t filter_mode = varonum_eval(&sequencer->filter_mode, sequencer);
    _m6581_set_modevol(sequencer->sid, (volume&15) + ((filter_mode&15)<<4));
    
}

void update_sequence_variables(sequencer_t* sequencer, int frame) {

    // update gate time counters
    int delta_frame = frame - sequencer->values['T'-'A'];
    if (delta_frame == 1) {
        for (int voice=0;voice<3;++voice) {
            uint8_t gate_time_index = 'U' + voice - 'A';
            sequencer->values[gate_time_index] += delta_frame; 
        }
    }
    else {
        // reset gate count/time variables when jumpign in time
        for (int voice=0;voice<3;++voice){
            uint8_t gate_count_index = 'X' + voice - 'A';
            sequencer->values[gate_count_index] = 0; 
            uint8_t gate_time_index = 'U' + voice - 'A';
            sequencer->values[gate_time_index] = 0; 
        }
    }

    // set frame time variable
    sequencer->values['T'-'A'] = frame;

    // compute sequences
    for (int i=0;i<NUM_SEQUENCES;++i) {
        update_sequence(&sequencer->sequences[i], sequencer);
    }
}

void update_preview(sequencer_t* sequencer)
{
    preview_t* preview = &sequencer->preview;

    // backup variable values
    int16_t backup[26];
    memcpy(backup, sequencer->values,sizeof(backup));

    int frame = preview->follow ? sequencer->frame : preview->offset;

    update_sequence_variables(sequencer, frame);
    
    for (int row=0;row<NUM_PREVIEW_ROWS;++row) {

        // save in preview
        preview->frames[row] = frame;
        for (int col=0;col<NUM_PREVIEW_COLS;++col) {
            char var = preview->variables[col];
            if (var >= 'A' && var <='Z') { 
                int index = var - 'A';
                preview->values[row][col] = sequencer->values[index];
            }
        }

        for (int step=0;step<preview->step;++step) {
            frame +=1;          
            // Note simulating every frame can get expensive for large step value! 
            // Needed for UVWXYZ and effects dependend on evaluation order.
            // note: changes sequencer variable states

            update_sequence_variables(sequencer, frame);
        }
    }

    // restore variable values
    memcpy(sequencer->values,backup,sizeof(backup));
}

void update_sequencer(sequencer_t* sequencer) 
{
    update_preview(sequencer);

    // update variables using frame number as input (and previous state)
    update_sequence_variables(sequencer, sequencer->frame);
    
    // send voices/parameters to sid
    if (!sequencer->muted) {
        update_sid(sequencer);
    }
    else {
        int16_t volume = 0;
        int16_t filter_mode = varonum_eval(&sequencer->filter_mode, sequencer);
        _m6581_set_modevol(sequencer->sid, (volume&15) + ((filter_mode&15)<<4));
    }

    if (sequencer->running) {    
        sequencer->frame += 1;
    }
}

#endif
/*
    Sequencer core logic. 

    Do this:
    ~~~C
    #define CHIPS_UI_IMPL
    ~~~
    before you include this file in *one* C++ file to create the
    implementation.

*/

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>
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

    var_or_number_t array;
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
#define MAX_PREVIEW_COLS 32
#define MAX_HIGHLIGHTERS 8

typedef struct {
    int value;
    int modulo;
    float color[4];
} highlighter_t;

typedef struct {
    int step;
    int offset;
    bool follow;
    int num_columns;
    char variables[MAX_PREVIEW_COLS];
    uint16_t frames[NUM_PREVIEW_ROWS];
    int16_t values[NUM_PREVIEW_ROWS][MAX_PREVIEW_COLS];
    highlighter_t highlighters[MAX_HIGHLIGHTERS];
    int num_highlighters;
} preview_t;

#define MAX_SEQUENCES   64
#define MAX_VARIABLES   26    // A-Z
#define MAX_ARRAYS      16
#define MAX_ARRAY_SIZE  16
#define MAX_VOICES      16
#define NUM_CHANNELS    3    // SID hardware channels

typedef struct {
    // time control
    bool running;
    bool muted;
    int frame;
    // sound control
    voice_t voices[MAX_VOICES];
    uint8_t num_voices;
    var_or_number_t channel_voice_params[NUM_CHANNELS];
    var_or_number_t filter_mode;
    var_or_number_t cutoff;
    var_or_number_t resonance;
    var_or_number_t volume;
    // sequences
    sequence_t sequences[MAX_SEQUENCES];
    uint8_t num_sequences;
    // arrays
    var_or_number_t arrays[MAX_ARRAYS][MAX_ARRAY_SIZE];
    uint8_t array_sizes[MAX_ARRAYS];
    uint8_t num_arrays;       
    preview_t preview;
    // current variable values
    int16_t values[MAX_VARIABLES];
    // gate states
    bool gate_states[NUM_CHANNELS];
} sequencer_t;


#define SEQUENCER_SNAPSHOT_VERSION (2)
#define SCREENSHOT_WIDTH (400)      // TODO: how to ensure it's same as framebuffer width?
#define SCREENSHOT_HEIGHT (300)
#define SCREENSHOT_SIZE_BYTES (SCREENSHOT_WIDTH * SCREENSHOT_HEIGHT)

typedef struct {
    uint32_t version;
    sequencer_t sequencer;
    uint8_t screenshot_data[SCREENSHOT_SIZE_BYTES];    // RGBA8 screenshot
} sequencer_snapshot_t;


// exported functions
int16_t floor_mod(int16_t value, int16_t mod);
void sequencer_export_data(sequencer_t* sequencer, char* buffer, int size, int words_per_line);
bool sequencer_import_data(sequencer_t* sequencer, char* buffer);
void sequencer_update_sid(sequencer_t* sequencer, m6581_t* sid);
void sequencer_update(sequencer_t* sequencer);

void sequencer_update_framebuffer(sequencer_t* sequencer, uint8_t* framebuffer, chips_display_info_t info);



#ifdef __cplusplus
}
#endif

/*-- IMPLEMENTATION ----------------------------------------------------------*/

#ifdef CHIPS_IMPL

void sequencer_init(sequencer_t* sequencer) {
    
    memset(sequencer,0,sizeof(sequencer_t));

    sequencer->frame = 0;
    sequencer->running = true;
    sequencer->muted = false;
    // nice defaults
    sequencer->volume.number = 15;
    sequencer->preview.step = 1;
    sequencer->preview.follow = true;
    sequencer->num_voices = NUM_CHANNELS;
    sequencer->channel_voice_params[0] = (var_or_number_t){.number = 1};
    sequencer->channel_voice_params[1] = (var_or_number_t){.number = 2};
    sequencer->channel_voice_params[2] = (var_or_number_t){.number = 3};
    for (int i=0;i<sequencer->num_voices;i++){
        sequencer->voices[i].waveform.number = 1;
        sequencer->voices[i].sustain.number = 15;
    }
    // add a test sequence
    sequencer->num_sequences = 4;
    sequencer->sequences[0] = (sequence_t){
        .variable = 'S',
        .count = (var_or_number_t){.variable = 'T'},
        .div1 = (var_or_number_t){.number = 10},
        .base = (var_or_number_t){.number = 0},
    };
    sequencer->sequences[1] = (sequence_t){
        .variable = 'A',
        .count = (var_or_number_t){.variable = 'S'},
        .base = (var_or_number_t){.number = 2},
    };
    // some empty arrays
    sequencer->num_arrays = 2;
    for (int i=0;i<sequencer->num_arrays;i++) {
        sequencer->array_sizes[i] = 4;
    }
    // add a column to the preview
    sequencer->preview.num_columns = 4;

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
        uint8_t var_index = (varonum->variable - 'A') % MAX_VARIABLES;
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

void update_gate_state(sequencer_t* sequencer, int channel) {
    bool old_state = sequencer->gate_states[channel];
    bool new_state = false;
    var_or_number_t* channel_voice_param = &sequencer->channel_voice_params[channel];
    int16_t voice_index = varonum_eval(channel_voice_param, sequencer)-1;
    if (voice_index < 0 || voice_index >= MAX_VOICES) {
        new_state = false;
    }
    else {
        voice_t* voice = &sequencer->voices[voice_index];
        int16_t gate_value = varonum_eval(&voice->gate, sequencer);
        new_state = (gate_value&1 != 0);
    }
    if (new_state != old_state) {
        // gate state changed
        if (new_state) {
            // gate on: reset gate time
            uint8_t gate_time_index = 'U' + channel - 'A';
            sequencer->values[gate_time_index] = 0;
            // increment gate count
            uint8_t gate_count_index = 'X' + channel - 'A';
            sequencer->values[gate_count_index] += 1;
        }
        sequencer->gate_states[channel] = new_state;
    }

}

void update_sequence(sequence_t* sequence, sequencer_t* sequencer) {
    if (sequence->variable == 0) return;    // inactive sequence
    
    int16_t count = varonum_eval(&sequence->count, sequencer);
    
    int16_t add1 = varonum_eval(&sequence->add1, sequencer);
    int16_t div1 = varonum_eval(&sequence->div1, sequencer);
    int16_t mul1 = varonum_eval(&sequence->mul1, sequencer);
    int16_t mod1 = varonum_eval(&sequence->mod1, sequencer);

    int16_t base = varonum_eval(&sequence->base, sequencer);
    
    int16_t mod2 = varonum_eval(&sequence->mod2, sequencer);
    int16_t mul2 = varonum_eval(&sequence->mul2, sequencer);
    int16_t div2 = varonum_eval(&sequence->div2, sequencer);
    int16_t add2 = varonum_eval(&sequence->add2, sequencer);

    int16_t array = varonum_eval(&sequence->array, sequencer);

    int16_t value = count; 
    
    value = value + add1;

    if (div1 != 0) {
        value = value / div1;
    }

    if (mul1 != 0) {
        value = value * mul1;
    }
    
    if (mod1 != 0) {                     // TODO: more options?
        value = floor_mod(value,mod1);
    }
    
    value = sum_digits(base, value);
    
    if (mod2 != 0) {                     // TODO: more options?
        value = floor_mod(value,mod2); 
    }
    
    if (mul2 != 0) {
        value = value * mul2;
    }
    
    if (div2 != 0) {
        value = value / div2;
    }
    
    value = value + add2;

    if (array >= 1 && array <= sequencer->num_arrays) {
        uint8_t array_size = sequencer->array_sizes[array-1];
        if (array_size > 0) {
            var_or_number_t v = sequencer->arrays[array-1][floor_mod(value, array_size)];
            value = varonum_eval(&v, sequencer);
        }
    }

    // get old sequence value
    uint8_t var_index = (sequence->variable - 'A') % MAX_VARIABLES;
    uint16_t old = sequencer->values[var_index];

    // used as voice gate or used as channel-voice? update gate states
    for (int channel=0;channel<NUM_CHANNELS;++channel){
        var_or_number_t* voice_param = &sequencer->channel_voice_params[channel];
        if (voice_param->variable == sequence->variable) {
            update_gate_state(sequencer, channel);
        }
        else 
        {
            int16_t voice_index = varonum_eval(voice_param, sequencer)-1;
            if (voice_index < 0 || voice_index >= MAX_VOICES) continue;
            voice_t* voice = &sequencer->voices[voice_index];
            if (voice->gate.variable == sequence->variable) {
                update_gate_state(sequencer, channel);        
            }
        }
    }

    // store result
    sequencer->values[var_index] = value;
}

float compute_freq(sequencer_t* sequencer, int v)       // voice v
{
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
    return note_freq(440.0, (float)semitone + (float)pitch/100);
}

void sequencer_update_sid(sequencer_t* sequencer, m6581_t* sid)
{
    if (sequencer->muted) {
        int16_t volume = 0;
        int16_t filter_mode = varonum_eval(&sequencer->filter_mode, sequencer);
        _m6581_set_modevol(sid, (volume&15) + ((filter_mode&15)<<4));
        return;
    }

    int16_t channel_filter[NUM_CHANNELS] = {0,0,0};     // TODO: keep per voice filter settings for when channel has no voice assigned

    for (int channel=0;channel<NUM_CHANNELS;++channel){
        var_or_number_t* voice_param = &sequencer->channel_voice_params[channel];
        int16_t voice_index = varonum_eval(voice_param, sequencer)-1;
        if (voice_index < 0 || voice_index >= sequencer->num_voices) {
            // close channel gate, keep all olther control bits the same
            uint8_t ctrl = sid->voice[channel].ctrl & ~(M6581_CTRL_GATE);
            _m6581_set_ctrl(&sid->voice[channel], ctrl);
            continue;
        };
        voice_t* voice = &sequencer->voices[voice_index];
    
        // ctrl
        int16_t gate = varonum_eval(&voice->gate, sequencer);
        int16_t sync = varonum_eval(&voice->sync, sequencer);
        int16_t ring = varonum_eval(&voice->ring, sequencer);
        int16_t wave = varonum_eval(&voice->waveform, sequencer);
        _m6581_set_ctrl(&sid->voice[channel], (gate&1) + ((sync&1)<<1) + ((ring&1)<<2 ) + ((wave&15)<<4));
        
        // freq
        float freq = compute_freq(sequencer, voice_index);
        int16_t sid_freq_value = freq_to_sid_value_pal(freq);
        _m6581_set_freq_hi(&sid->voice[channel], (sid_freq_value>>8));
        _m6581_set_freq_lo(&sid->voice[channel], (sid_freq_value&0xFF));

        // pulsewidth
        int16_t pulsewidth = varonum_eval(&voice->pulsewidth, sequencer);
        _m6581_set_pw_lo(&sid->voice[channel], (pulsewidth&0xFF));
        _m6581_set_pw_hi(&sid->voice[channel], (pulsewidth>>8));

        // envelope
        int16_t attack = varonum_eval(&voice->attack, sequencer);
        int16_t decay = varonum_eval(&voice->decay, sequencer);
        int16_t sustain = varonum_eval(&voice->sustain, sequencer);
        int16_t release = varonum_eval(&voice->release, sequencer);
        _m6581_set_atkdec(&sid->voice[channel], ((attack&15)<<4) + (decay&15));
        _m6581_set_susrel(&sid->voice[channel], ((sustain&15)<<4) + (release&15));

        // save filter setting for this channel
        channel_filter[channel] = varonum_eval(&voice->filter, sequencer);
    }

    int16_t cutoff = varonum_eval(&sequencer->cutoff, sequencer);
    _m6581_set_cutoff_lo(&sid->filter, (cutoff&0x7));            // bits 0-2
    _m6581_set_cutoff_hi(&sid->filter, (cutoff>>3));             // bits 3-10

    int16_t resonance = varonum_eval(&sequencer->resonance, sequencer);

    _m6581_set_resfilt(&sid->filter, 
        ((resonance&15)<<4)  + (channel_filter[0]&1) + ((channel_filter[1]&1)<<1) + ((channel_filter[2]&1)<<2));

     int16_t volume = varonum_eval(&sequencer->volume, sequencer);
     int16_t filter_mode = varonum_eval(&sequencer->filter_mode, sequencer);
    _m6581_set_modevol(sid, (volume&15) + ((filter_mode&15)<<4));
    
}

void update_variables(sequencer_t* sequencer, int frame) {

    // update gate time counters
    int16_t new_t = frame;       // narrowing
    int16_t old_t = sequencer->values['T'-'A'];
    int delta_frame = new_t - old_t;
    if (delta_frame == 1) {
        for (int channel=0;channel<NUM_CHANNELS;++channel) {
            uint8_t gate_time_index = 'U' + channel - 'A';
            sequencer->values[gate_time_index] += delta_frame; 
        }
    }
    else {
        // reset gate count/time variables when jumpign in time
        for (int channel=0;channel<NUM_CHANNELS;++channel) {
            uint8_t gate_count_index = 'X' + channel - 'A';
            sequencer->values[gate_count_index] = 0; 
            uint8_t gate_time_index = 'U' + channel - 'A';
            sequencer->values[gate_time_index] = 0; 
        }
    }

    // set frame time variable
    sequencer->values['T'-'A'] = new_t;

    // compute sequences
    for (int i=0;i<sequencer->num_sequences;++i) {
        update_sequence(&sequencer->sequences[i], sequencer);
    }
}

void update_preview(sequencer_t* sequencer)
{
    preview_t* preview = &sequencer->preview;

    // backup variable values
    int16_t backup[MAX_VARIABLES];
    memcpy(backup, sequencer->values,sizeof(backup));
    bool gate_backup[NUM_CHANNELS];
    memcpy(gate_backup, sequencer->gate_states,sizeof(gate_backup));

    int frame = preview->follow ? sequencer->frame : preview->offset;

    update_variables(sequencer, frame);
    
    for (int row=0;row<NUM_PREVIEW_ROWS;++row) {

        // save in preview
        preview->frames[row] = frame;
        for (int col=0;col<preview->num_columns;++col) {
            char var = preview->variables[col];
            // TODO: in future allow more variables
            if (var >= 'A' && var <='Z') { 
                int index = (var - 'A') % MAX_VARIABLES;
                preview->values[row][col] = sequencer->values[index];
            }
        }

        for (int step=0;step<preview->step;++step) {
            frame +=1;          
            // Note simulating every frame can get expensive for large step value! 
            // Needed for UVWXYZ and effects dependend on evaluation order.
            // note: changes sequencer variable states

            update_variables(sequencer, frame);
        }
    }

    // restore variable values
    memcpy(sequencer->values,backup,sizeof(backup));
    memcpy(sequencer->gate_states,gate_backup,sizeof(gate_backup));
}

void sequencer_update(sequencer_t* sequencer) 
{
    update_preview(sequencer);

    // update variables using frame number as input (and previous state)
    update_variables(sequencer, sequencer->frame);
        
    if (sequencer->running) {    
        sequencer->frame += 1;
    }
}

void sequencer_update_framebuffer(sequencer_t* sequencer, uint8_t* framebuffer, chips_display_info_t info) 
{
    // TODO: what would be a good visualization of the sequencer state?
    // Or just drop it?    
}

// ----------- import/export ------------

int varonum_export(var_or_number_t* varonum, char* buffer, int size) 
{
    // encode varonum in a single 16 bit value, 
    // Option 1: 1 bit to indicate type, number range limited to 15 bits, union with variable number
    //   disadvantage: processer per parameter more expensive (matters on c64)
    // Option 2: encode type separate from the number and variable in bit fields
    //    e.g  we have 42 SID parameters -> 42 bits = 7 bytes. 
    //   could be decoded in to easier to process 42 bytes on c64 at load time    
    int n = snprintf(buffer, size, "%d, %d, ",varonum->variable, varonum->number);
    assert(n>0 && size-n>0);
    return n;
}

int var_export(char variable, char* buffer, int size) 
{
    // TODO: for C64 code, could be less than a byte?
    // Now using a whole word if put on the same .word list as the rest
    int n = snprintf(buffer, size, "%d, ",variable);
    assert(n>0 && size-n>0);
    return n;
}


int export_uint8(uint8_t value, char* buffer, int size) 
{
    // TODO: we currently don't distingish 16 bit words or 8 bit bytes in the output
    // it's just list of numbers.  
    int n = snprintf(buffer, size, "%d, ",value);
    assert(n>0 && size-n>0);
    return n;
}


void sequencer_export_data(sequencer_t* sequencer, char* buffer, int size, int words_per_line)
{
    int pos = 0;

    pos += export_uint8(sequencer->num_voices, &buffer[pos],size-pos);
    for (int v=0; v<sequencer->num_voices; v++) {
        voice_t* voice = &sequencer->voices[v];
        pos += varonum_export(&voice->gate, &buffer[pos],size-pos);
        pos += varonum_export(&voice->note, &buffer[pos],size-pos);
        pos += varonum_export(&voice->scale, &buffer[pos],size-pos);
        pos += varonum_export(&voice->transpose, &buffer[pos],size-pos);
        pos += varonum_export(&voice->pitch, &buffer[pos],size-pos);
        pos += varonum_export(&voice->waveform, &buffer[pos],size-pos);
        pos += varonum_export(&voice->pulsewidth, &buffer[pos],size-pos);
        pos += varonum_export(&voice->ring, &buffer[pos],size-pos);
        pos += varonum_export(&voice->sync, &buffer[pos],size-pos);
        pos += varonum_export(&voice->attack, &buffer[pos],size-pos);
        pos += varonum_export(&voice->decay, &buffer[pos],size-pos);
        pos += varonum_export(&voice->sustain, &buffer[pos],size-pos);
        pos += varonum_export(&voice->release, &buffer[pos],size-pos);
        pos += varonum_export(&voice->filter, &buffer[pos],size-pos);
    }

    for (int channel=0; channel<NUM_CHANNELS; channel++) {
        pos += varonum_export(&sequencer->channel_voice_params[channel], &buffer[pos],size-pos);
    }

    pos += varonum_export(&sequencer->filter_mode, &buffer[pos],size-pos);
    pos += varonum_export(&sequencer->cutoff, &buffer[pos],size-pos);
    pos += varonum_export(&sequencer->resonance, &buffer[pos],size-pos);
    pos += varonum_export(&sequencer->volume, &buffer[pos],size-pos);
    
    pos += export_uint8(sequencer->num_sequences, &buffer[pos],size-pos);
    
    for (int s=0; s<sequencer->num_sequences; s++) {
        sequence_t* seq = &sequencer->sequences[s];
        pos += var_export(seq->variable, &buffer[pos],size-pos);
        pos += varonum_export(&seq->count, &buffer[pos],size-pos);
        pos += varonum_export(&seq->add1, &buffer[pos],size-pos);
        pos += varonum_export(&seq->div1, &buffer[pos],size-pos);
        pos += varonum_export(&seq->mul1, &buffer[pos],size-pos);
        pos += varonum_export(&seq->mod1, &buffer[pos],size-pos);
        pos += varonum_export(&seq->base, &buffer[pos],size-pos);
        pos += varonum_export(&seq->mod2, &buffer[pos],size-pos);
        pos += varonum_export(&seq->mul2, &buffer[pos],size-pos);
        pos += varonum_export(&seq->div2, &buffer[pos],size-pos);
        pos += varonum_export(&seq->add2, &buffer[pos],size-pos);
        pos += varonum_export(&seq->array, &buffer[pos],size-pos);
    }

    pos += export_uint8(sequencer->num_arrays, &buffer[pos],size-pos);

    for (int a=0; a<sequencer->num_arrays; a++) {
        pos += export_uint8(sequencer->array_sizes[a], &buffer[pos],size-pos);
        for (int i=0; i<sequencer->array_sizes[a]; i++) {
            pos += varonum_export(&sequencer->arrays[a][i], &buffer[pos],size-pos);
        }
    }

    
    // terminate string
    assert(pos<size);
    buffer[pos] = 0;

    // format with newlines
    int count = 0;
    pos = 0;
    while (buffer[pos]!=0){
        if (buffer[pos]==',') {
            count++;
            if (count == words_per_line) {
                count = 0;
                buffer[pos+1]='\n';
            }
        }
        pos++;
    }
}


bool varonum_import(var_or_number_t* varonum, char* buffer, int* pos) 
{
    int argsread = sscanf(&buffer[*pos], "%hhd, %hd,", &varonum->variable, &varonum->number);
    if (argsread != 2) return false;
    int count=0;
    while (buffer[*pos]!=0) {
        if (buffer[*pos]==',') count+=1;
        (*pos)++;
        if (count==2) break;
    }
    return (count==2);
}


bool var_import(char* variable, char* buffer, int* pos) 
{
    int argsread = sscanf(&buffer[*pos], "%hhd,", variable);
    if (argsread != 1) return false;
    int count=0;
    while (buffer[*pos]!=0) {
        if (buffer[*pos]==',') count+=1;
        (*pos)++;
        if (count==1) break;
    }
    return (count==1);
}

bool import_uint8(uint8_t* variable, char* buffer, int* pos) 
{
    int argsread = sscanf(&buffer[*pos], "%hhd,", variable);
    if (argsread != 1) return false;
    int count=0;
    while (buffer[*pos]!=0) {
        if (buffer[*pos]==',') count+=1;
        (*pos)++;
        if (count==1) break;
    }
    return (count==1);
}

bool sequencer_import_data(sequencer_t* sequencer, char* buffer)
{
    int pos = 0;

    if(!import_uint8(&sequencer->num_voices, buffer, &pos)) return false;
    if (sequencer->num_voices > MAX_VOICES) sequencer->num_voices = MAX_VOICES;

    for (int v=0; v<sequencer->num_voices; v++) {
        voice_t* voice = &sequencer->voices[v];
        if(!varonum_import(&voice->gate, buffer, &pos)) return false;
        if(!varonum_import(&voice->note, buffer, &pos)) return false;
        if(!varonum_import(&voice->scale, buffer, &pos)) return false;
        if(!varonum_import(&voice->transpose, buffer, &pos)) return false;
        if(!varonum_import(&voice->pitch, buffer, &pos)) return false;
        if(!varonum_import(&voice->waveform, buffer, &pos)) return false;
        if(!varonum_import(&voice->pulsewidth, buffer, &pos)) return false;
        if(!varonum_import(&voice->ring, buffer, &pos)) return false;
        if(!varonum_import(&voice->sync, buffer, &pos)) return false;
        if(!varonum_import(&voice->attack, buffer, &pos)) return false;
        if(!varonum_import(&voice->decay, buffer, &pos)) return false;
        if(!varonum_import(&voice->sustain, buffer, &pos)) return false;
        if(!varonum_import(&voice->release, buffer, &pos)) return false;
        if(!varonum_import(&voice->filter, buffer, &pos)) return false;
    }

    for (int channel=0; channel<NUM_CHANNELS; channel++) {
        if(!varonum_import(&sequencer->channel_voice_params[channel], buffer, &pos)) return false;
    }

    if(!varonum_import(&sequencer->filter_mode, buffer, &pos)) return false;
    if(!varonum_import(&sequencer->cutoff, buffer, &pos)) return false;
    if(!varonum_import(&sequencer->resonance, buffer, &pos)) return false;
    if(!varonum_import(&sequencer->volume, buffer, &pos)) return false;

    if(!import_uint8(&sequencer->num_sequences, buffer, &pos)) return false;
    if (sequencer->num_sequences > MAX_SEQUENCES) sequencer->num_sequences = MAX_SEQUENCES;
        
    for (int s=0; s<sequencer->num_sequences; s++) {
        sequence_t* seq = &sequencer->sequences[s];
        if(!var_import(&seq->variable, buffer, &pos)) return false;
        if(!varonum_import(&seq->count, buffer, &pos)) return false;
        if(!varonum_import(&seq->add1, buffer, &pos)) return false;
        if(!varonum_import(&seq->div1, buffer, &pos)) return false;
        if(!varonum_import(&seq->mul1, buffer, &pos)) return false;
        if(!varonum_import(&seq->mod1, buffer, &pos)) return false;
        if(!varonum_import(&seq->base, buffer, &pos)) return false;
        if(!varonum_import(&seq->mod2, buffer, &pos)) return false;
        if(!varonum_import(&seq->mul2, buffer, &pos)) return false;
        if(!varonum_import(&seq->div2, buffer, &pos)) return false;
        if(!varonum_import(&seq->add2, buffer, &pos)) return false;
        if(!varonum_import(&seq->array, buffer, &pos)) return false;
    }

    if(!import_uint8(&sequencer->num_arrays, buffer, &pos)) return false;
    if (sequencer->num_arrays > MAX_ARRAYS) sequencer->num_arrays = MAX_ARRAYS;
    for (int a=0; a<sequencer->num_arrays; a++) {
        if(!import_uint8(&sequencer->array_sizes[a], buffer, &pos)) return false;
        if (sequencer->array_sizes[a] > MAX_ARRAY_SIZE) sequencer->array_sizes[a] = MAX_ARRAY_SIZE;
        for (int i=0; i<sequencer->array_sizes[a]; i++) {
            if(!varonum_import(&sequencer->arrays[a][i], buffer, &pos)) return false;
        }
    }
    return true;
}

// ----------- snapshot -----------

uint32_t sequencer_save_snapshot(sequencer_t* sys, sequencer_t* dst) {
    CHIPS_ASSERT(sys && dst);
    *dst = *sys;
    return SEQUENCER_SNAPSHOT_VERSION;
}

bool sequencer_load_snapshot(sequencer_t* sys, uint32_t version, sequencer_t* src) {
    CHIPS_ASSERT(sys && src);
    if (version != SEQUENCER_SNAPSHOT_VERSION) {
        return false;
    }
    static sequencer_t im;
    im = *src;
    *sys = im;
    // TODO: whno not *sys = *src?
    return true;
}


#endif
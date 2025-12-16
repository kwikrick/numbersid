#pragma once
/*#
    # ui_parameters.h

    Visualization for numbersid sound parameters.

    Do this:
    ~~~C
    #define CHIPS_UI_IMPL
    ~~~
    before you include this file in *one* C++ file to create the
    implementation.

    Optionally provide the following macros with your own implementation

    ~~~C
    CHIPS_ASSERT(c)
    ~~~
        your own assert macro (default: assert(c))

    Include the following headers before the including the *declaration*:
        - sequencer.h
        - ui_settings.h

    Include the following headers before including the *implementation*:
        - imgui.h
        - sequencer.h
        - ui_util.h

    All strings provided to ui_parameters_init() must remain alive until
    ui_parameters_discard() is called!

    ## zlib/libpng license

    Copyright (c) 2025 Rick van der Meiden
    Copyright (c) 2018 Andre Weissflog
    
    This software is provided 'as-is', without any express or implied warranty.
    In no event will the authors be held liable for any damages arising from the
    use of this software.
    Permission is granted to anyone to use this software for any purpose,
    including commercial applications, and to alter it and redistribute it
    freely, subject to the following restrictions:
        1. The origin of this software must not be misrepresented; you must not
        claim that you wrote the original software. If you use this software in a
        product, an acknowledgment in the product documentation would be
        appreciated but is not required.
        2. Altered source versions must be plainly marked as such, and must not
        be misrepresented as being the original software.
        3. This notice may not be removed or altered from any source
        distribution.
#*/
#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/* setup parameters for ui_parameters_init()
    NOTE: all string data must remain alive until ui_parameters_discard()!
*/
typedef struct ui_parameters_desc_t {
    const char* title;          /* window title */
    sequencer_t* sequencer;      /* object to show and edit */
    int x, y;                   /* initial window position */
    int w, h;                   /* initial window size (or default size of 0) */
    bool open;                  /* initial window open state */
} ui_parameters_desc_t;

typedef struct ui_parameters_t {
    const char* title;
    sequencer_t* sequencer;
    float init_x, init_y;
    float init_w, init_h;
    bool open;
    bool last_open;
    bool valid;
} ui_parameters_t;

void ui_parameters_init(ui_parameters_t* win, const ui_parameters_desc_t* desc);
void ui_parameters_discard(ui_parameters_t* win);
void ui_parameters_draw(ui_parameters_t* win);
void ui_parameters_save_settings(ui_parameters_t* win, ui_settings_t* settings);
void ui_parameters_load_settings(ui_parameters_t* win, const ui_settings_t* settings);

#ifdef __cplusplus
} /* extern "C" */
#endif

/*-- IMPLEMENTATION (include in C++ source) ----------------------------------*/
#ifdef CHIPS_UI_IMPL
#ifndef __cplusplus
#error "implementation must be compiled as C++"
#endif
#include <string.h> /* memset */
#ifndef CHIPS_ASSERT
    #include <assert.h>
    #define CHIPS_ASSERT(c) assert(c)
#endif

// generic ui functions for varonums

void ui_varonum_to_string(var_or_number_t* varonum, char* str, int maxlen)
{
    if (varonum->variable == 0) {
        snprintf(str,maxlen,"%d",varonum->number);
    }
    else
    {
        snprintf(str,maxlen,"%c",varonum->variable);
    }
}

void ui_string_to_varonum(char* str, var_or_number_t* varonum)
{
    char first = ImToUpper(ImStrSkipBlank(str)[0]);
    if (first >= 'A' && first <= 'Z') {
        varonum->variable = first;
    }
    else
    {
        varonum->variable = 0;
        varonum->number = atoi(str);
    }
    
}


void draw_varonum(var_or_number_t* varonum, char* id_str) {
    char str[16];
    ui_varonum_to_string(varonum, str, IM_ARRAYSIZE(str));
    ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
    bool isVar = varonum->variable != 0;
    if (isVar) ImGui::PushStyleColor(ImGuiCol_FrameBg, ImGui::GetStyleColorVec4(ImGuiCol_FrameBgActive));
    bool edited = ImGui::InputText(id_str, str, IM_ARRAYSIZE(str));
    if (edited) {
        ui_string_to_varonum(str,varonum);
    }
    if (isVar) ImGui::PopStyleColor();
}

// ------- ui_parameters_t implementation -------

void ui_parameters_init(ui_parameters_t* win, const ui_parameters_desc_t* desc) {
    CHIPS_ASSERT(win && desc);
    CHIPS_ASSERT(desc->title);
    memset(win, 0, sizeof(ui_parameters_t));
    win->title = desc->title;
    win->sequencer = desc->sequencer;
    win->init_x = (float) desc->x;
    win->init_y = (float) desc->y;
    win->init_w = (float) ((desc->w == 0) ? 600 : desc->w);
    win->init_h = (float) ((desc->h == 0) ? 600 : desc->h);
    win->open = win->last_open = desc->open;
    win->valid = true;
}

void ui_parameters_discard(ui_parameters_t* win) {
    CHIPS_ASSERT(win && win->valid);
    win->valid = false;
}

void draw_voice_parameter_columns(sequencer_t* sequencer, size_t param_offset, char* id_str) {
     for (int i = 0; i < sequencer->num_voices; i++) {
        var_or_number_t* varonum = (var_or_number_t*) ((uint8_t*)(&sequencer->voices[i]) + param_offset);
        ImGui::PushID(i);
        draw_varonum(varonum, id_str);
        ImGui::PopID();
        ImGui::TableNextColumn();
    }
}

static void _ui_parameters_draw_state(ui_parameters_t* win) {

    sequencer_t* sequencer = win->sequencer;

    const float cw0 = 84.0f;
    const float cw = 64.0f;
    char str[16];       // reuse this string for conversions to/from varonum

    ImGui::PushStyleVar(ImGuiStyleVar_CellPadding, ImVec2(2,2));
    
    if (ImGui::BeginTable("##voices", sequencer->num_voices + 1, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_RowBg)) {
        ImGui::TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, cw0);
        for (int i = 0; i < sequencer->num_voices; i++) {
            char col_name[16];
            snprintf(col_name, sizeof(col_name), "Voice %d", i + 1);
            ImGui::TableSetupColumn(col_name, ImGuiTableColumnFlags_WidthFixed, cw);
        }
        ImGui::TableHeadersRow();
        ImGui::TableNextColumn();

        // row for buttons
        if (sequencer->num_voices > 0) {
            if (ImGui::Button("-")) {
                sequencer->num_voices--;
            }
        }
        ImGui::SameLine();
        if (sequencer->num_voices < MAX_VOICES) {
            if (ImGui::Button("+")) {
                sequencer->num_voices++;
            }
        }
        ImGui::TableNextColumn();
        for (int i = 0; i < sequencer->num_voices; i++) {
            ImGui::PushID(i);
            if (ImGui::ArrowButton("<", ImGuiDir_Left)) {
                    int j=floor_mod(i-1, sequencer->num_voices);
                    voice_t temp = sequencer->voices[j];
                    sequencer->voices[j] = sequencer->voices[i];
                    sequencer->voices[i] = temp;
                
            }
            ImGui::SameLine();
            if (ImGui::ArrowButton(">", ImGuiDir_Right)) {
                    int j=floor_mod(i+1, sequencer->num_voices);
                    voice_t temp = sequencer->voices[j];
                    sequencer->voices[j] = sequencer->voices[i];
                    sequencer->voices[i] = temp;
            }
            ImGui::PopID();
            ImGui::TableNextColumn();
        }
        

        //ImGui::TableNextColumn();
        ImGui::Text("GATE"); 
        ImGui::SetItemTooltip("Gate open/close; bit 0: 0=close, 1=open");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, gate), "##gate");

        ImGui::Text("NOTE");
        ImGui::SetItemTooltip("Note number; 0 = first note in scale of octave 0"); 
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, note), "##note");

        ImGui::Text("SCALE");
        ImGui::SetItemTooltip("Musical Scale; 12 bits: select semitones in one octave; 0=4095=chromatic; 2741=c-major; 1352=a-minor");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, scale), "##scale");
            
        ImGui::Text("TRANS"); 
        ImGui::SetItemTooltip("Transpose scale; number of semitones");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, transpose), "##transpose");

        ImGui::Text("PITCH"); 
        ImGui::SetItemTooltip("Tune frequency; number of cents = 1/100 semitone");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, pitch), "##pitch");

        ImGui::Text("WAVE");
        ImGui::SetItemTooltip("Waveform; bit 0=TRIANGLE; bit 1=SAW; bit 2=PULSE; bit 3=NOISE. Noise cannot be combined.");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, waveform), "##waveform");

        ImGui::Text("PULSEWIDTH"); 
        ImGui::SetItemTooltip("Pulse width; 12 bits; range 0-4095; used when WAVE bit 2 is set.");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, pulsewidth), "##pulsewidth");

        ImGui::Text("RING"); 
        ImGui::SetItemTooltip("Ring modulation; bit 0: 1=ON, 0=OFF; input from left channel");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, ring), "##ring");

        ImGui::Text("SYNC"); 
        ImGui::SetItemTooltip("Synchonisation; bit 0: 1=ON, 0=OFF; input from left channel");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, sync), "##sync");

        ImGui::Text("ATTACK");
        ImGui::SetItemTooltip("Attack time; range 0-15 (4 bits)");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, attack), "##attack");

        ImGui::Text("DECAY");
        ImGui::SetItemTooltip("Decay time; range 0-15 (4 bits)");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, decay), "##decay");

        ImGui::Text("SUSTAIN");
        ImGui::SetItemTooltip("Sustain level; range 0-15 (4 bits)");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, sustain), "##sustain");

        ImGui::Text("RELEASE");
        ImGui::SetItemTooltip("Release time; range 0-15 (4 bits)");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, release), "##release");

        ImGui::Text("FILTER");
        ImGui::SetItemTooltip("Filter enable; bit 0: 1=ON, 0=OFF");
        ImGui::TableNextColumn();
        draw_voice_parameter_columns(sequencer, offsetof(voice_t, filter), "##filter");

        ImGui::EndTable();
    }

    if (ImGui::BeginTable("##channels", 4, ImGuiTableFlags_SizingFixedFit)) {
        ImGui::TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, cw0);
        ImGui::TableSetupColumn("Channel 1", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("Channel 2", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("Channel 3", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableHeadersRow();
        ImGui::TableNextColumn();
        ImGui::Text("VOICE");
        ImGui::SetItemTooltip("Voice number (0-16) to use for this channel");
        ImGui::TableNextColumn();
        for (int i = 0; i < NUM_CHANNELS; i++) {
            ImGui::PushID(i);
            draw_varonum(&sequencer->channel_voice_params[i],"##channelvoice");
            ImGui::PopID();
            ImGui::TableNextColumn();
        }
        ImGui::EndTable();
    }

    if (ImGui::BeginTable("##filter", 2, ImGuiTableFlags_SizingFixedFit)) {
        ImGui::TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, cw0);
        ImGui::TableSetupColumn("Filter", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableHeadersRow();
        ImGui::TableNextColumn();
        
        ImGui::Text("FILTER MODE");
        ImGui::SetItemTooltip("Filters: bit 0=LOWPASS; bit 1=BANDPASS; bit 2=HIGHPASS; bit 3=Mute Channel 3");
        ImGui::TableNextColumn();
        draw_varonum(&sequencer->filter_mode, "##filtermode");
        ImGui::TableNextColumn();
        
        ImGui::Text("CUTOFF");
        ImGui::SetItemTooltip("Cutoff/center frequency: range 0-2047 (11 bits) ~ 30-12000Hz");
        ImGui::TableNextColumn();
        draw_varonum(&sequencer->cutoff, "##cutoff");
        ImGui::TableNextColumn();

        ImGui::Text("RESONANCE");
        ImGui::SetItemTooltip("Resonance strength; range 0-15 (4 bits)");
        ImGui::TableNextColumn();
        draw_varonum(&sequencer->resonance, "##resonance");
        ImGui::TableNextColumn();
        
        ImGui::Text("VOLUME");
        ImGui::SetItemTooltip("Volume; range 0-15 (4 bits)");
        ImGui::TableNextColumn();
        draw_varonum(&sequencer->volume, "##volume");
        ImGui::TableNextColumn();
        ImGui::EndTable();
    }
   
    ImGui::PopStyleVar(1);
    
}

void ui_parameters_draw(ui_parameters_t* win) {
    CHIPS_ASSERT(win && win->valid);
    ui_util_handle_window_open_dirty(&win->open, &win->last_open);
    if (!win->open) {
        return;
    }
    ImGui::SetNextWindowPos(ImVec2(win->init_x, win->init_y), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(win->init_w, win->init_h), ImGuiCond_FirstUseEver);
    if (ImGui::Begin(win->title, &win->open)) {
        ImGui::BeginChild("##sequencer_state", ImVec2(0, 0), true);
        _ui_parameters_draw_state(win);
        ImGui::EndChild();
    }
    ImGui::End();
}

void ui_parameters_save_settings(ui_parameters_t* win, ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    ui_settings_add(settings, win->title, win->open);
}

void ui_parameters_load_settings(ui_parameters_t* win, const ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    win->open = ui_settings_isopen(settings, win->title);
}
#endif /* CHIPS_UI_IMPL */

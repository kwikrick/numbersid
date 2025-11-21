#pragma once
/*#
    # ui_sequencer.h

    Visualization for numbersid sequencer.

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

    All strings provided to ui_sequencer_init() must remain alive until
    ui_sequencer_discard() is called!

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

/* setup parameters for ui_sequencer_init()
    NOTE: all string data must remain alive until ui_sequencer_discard()!
*/
typedef struct ui_sequencer_desc_t {
    const char* title;          /* window title */
    sequencer_t* sequencer;      /* object to show and edit */
    int x, y;                   /* initial window position */
    int w, h;                   /* initial window size (or default size of 0) */
    bool open;                  /* initial window open state */
} ui_sequencer_desc_t;

typedef struct ui_sequencer_t {
    const char* title;
    sequencer_t* sequencer;
    float init_x, init_y;
    float init_w, init_h;
    bool open;
    bool last_open;
    bool valid;
} ui_sequencer_t;

void ui_sequencer_init(ui_sequencer_t* win, const ui_sequencer_desc_t* desc);
void ui_sequencer_discard(ui_sequencer_t* win);
void ui_sequencer_draw(ui_sequencer_t* win);
void ui_sequencer_save_settings(ui_sequencer_t* win, ui_settings_t* settings);
void ui_sequencer_load_settings(ui_sequencer_t* win, const ui_settings_t* settings);

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


void ui_sequencer_init(ui_sequencer_t* win, const ui_sequencer_desc_t* desc) {
    CHIPS_ASSERT(win && desc);
    CHIPS_ASSERT(desc->title);
    memset(win, 0, sizeof(ui_sequencer_t));
    win->title = desc->title;
    win->sequencer = desc->sequencer;
    win->init_x = (float) desc->x;
    win->init_y = (float) desc->y;
    win->init_w = (float) ((desc->w == 0) ? 496 : desc->w);
    win->init_h = (float) ((desc->h == 0) ? 410 : desc->h);
    win->open = win->last_open = desc->open;
    win->valid = true;
}

void ui_sequencer_discard(ui_sequencer_t* win) {
    CHIPS_ASSERT(win && win->valid);
    win->valid = false;
}

static void _ui_sequencer_draw_state(ui_sequencer_t* win) {

    sequencer_t* sequencer = win->sequencer;

    const float cw0 = 84.0f;
    const float cw = 64.0f;
    char str[16];       // reuse this string for conversions to/from varonum

    ImGui::PushStyleVar(ImGuiStyleVar_CellPadding, ImVec2(2,2));

    {
        ImGui::SeparatorText("Time Control");  
        ImGui::PushItemWidth(cw0);
        ImGui::InputInt("T", &win->sequencer->frame, 1,128);
        ImGui::SameLine();
        if (ImGui::Button("Reset")) {
            sequencer->frame = 0;
        };
        ImGui::SameLine();
        ImGui::Checkbox("Run",&sequencer->running);
        ImGui::SameLine();
        ImGui::Checkbox("Mute",&sequencer->muted);
        ImGui::PopItemWidth();
    }
    
    {
        ImGui::SeparatorText("Sound Parameters");  
        if (ImGui::BeginTable("##voices", 4)) {
            ImGui::TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, cw0);
            ImGui::TableSetupColumn("Voice 1", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableSetupColumn("Voice 2", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableSetupColumn("Voice 3", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableHeadersRow();
            ImGui::TableNextColumn();
            ImGui::Text("GATE"); 
            ImGui::SetItemTooltip("Gate open/close; bit 0: 0=close, 1=open");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].gate, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##gate", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].gate);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("NOTE");
            ImGui::SetItemTooltip("Note number; 0 = first note in scale of octave 0"); 
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].note, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##note", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].note);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("SCALE");
            ImGui::SetItemTooltip("Musical Scale; 12 bits: select semitones in one octave; 0=4095=chromatic; 2741=c-major; 1352=a-minor");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].scale, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##scale", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].scale);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("TRANS"); 
            ImGui::SetItemTooltip("Transpose scale; number of semitones");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                 ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].transpose, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##transpose", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].transpose);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("PITCH"); 
            ImGui::SetItemTooltip("Tune frequency; number of cents = 1/100 semitone");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].pitch, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##pitch", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].pitch);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("WAVE");
            ImGui::SetItemTooltip("Waveform; bit 0=TRIANGLE; bit 1=SAW; bit 2=PULSE; bit 3=NOISE. Noise cannot be combined.");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].waveform, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##waveform", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].waveform);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("PULSEWIDTH"); 
            ImGui::SetItemTooltip("Pulse width; 12 bits; range 0-4095; used when WAVE bit 2 is set.");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                 ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].pulsewidth, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##pulsewidth", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].pulsewidth);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("RING"); 
            ImGui::SetItemTooltip("Ring modulation; bit 0: 1=ON, 0=OFF; input from left channel");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                 ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].ring, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##ring", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].ring);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("SYNC"); 
            ImGui::SetItemTooltip("Synchonisation; bit 0: 1=ON, 0=OFF; input from left channel");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].sync, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##sync", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].sync);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("ATTACK");
            ImGui::SetItemTooltip("Attack time; range 0-15 (4 bits)");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].attack, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##attach", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].attack);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("DECAY");
            ImGui::SetItemTooltip("Decay time; range 0-15 (4 bits)");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                 ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].decay, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##decay", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].decay);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("SUSTAIN");
            ImGui::SetItemTooltip("Sustain level; range 0-15 (4 bits)");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                 ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].sustain, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##sustain", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].sustain);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("RELEASE");
            ImGui::SetItemTooltip("Release time; range 0-15 (4 bits)");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                 ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].release, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##release", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].release);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::Text("FILTER");
            ImGui::SetItemTooltip("Filter enable; bit 0: 1=ON, 0=OFF");
            ImGui::TableNextColumn();
            for (int i = 0; i < 3; i++) {
                ImGui::PushID(i);
                ui_varonum_to_string(&win->sequencer->voices[i].filter, str, IM_ARRAYSIZE(str));
                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                bool edited = ImGui::InputText("##filter", str, IM_ARRAYSIZE(str));
                if (edited) {
                    ui_string_to_varonum(str,&win->sequencer->voices[i].filter);
                }
                ImGui::PopID();
                ImGui::TableNextColumn();
            }
            ImGui::EndTable();
        }
        if (ImGui::BeginTable("##filter", 2)) {
            ImGui::TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, cw0);
            ImGui::TableSetupColumn("Filter", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableHeadersRow();
            ImGui::TableNextColumn();
            
            ImGui::Text("FILTER MODE");
            ImGui::SetItemTooltip("Filters: bit 0=LOWPASS; bit 1=BANDPASS; bit 2=HIGHPASS; bit 3=Mute Voice 3");
            ImGui::TableNextColumn();
            ui_varonum_to_string(&win->sequencer->filter_mode, str, IM_ARRAYSIZE(str));
            ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
            if (ImGui::InputText("##filtermode", str, IM_ARRAYSIZE(str))) {
                ui_string_to_varonum(str,&win->sequencer->filter_mode);
            }
            ImGui::TableNextColumn();
            
            ImGui::Text("CUTOFF");
            ImGui::SetItemTooltip("Cutoff/center frequency: range 0-2047 (11 bits) ~ 30-12000Hz");
            ImGui::TableNextColumn();
            ui_varonum_to_string(&win->sequencer->cutoff, str, IM_ARRAYSIZE(str));
            ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
            if (ImGui::InputText("##cutoff", str, IM_ARRAYSIZE(str))) {
                ui_string_to_varonum(str,&win->sequencer->cutoff);
            }
            ImGui::TableNextColumn();

            ImGui::Text("RESONANCE");
            ImGui::SetItemTooltip("Resonance strength; range 0-15 (4 bits)");
            ImGui::TableNextColumn();
            ui_varonum_to_string(&win->sequencer->resonance, str, IM_ARRAYSIZE(str));
            ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
            if (ImGui::InputText("##resonance", str, IM_ARRAYSIZE(str))) {
                ui_string_to_varonum(str,&win->sequencer->resonance);
            }
            ImGui::TableNextColumn();
            
            ImGui::Text("VOLUME");
            ImGui::SetItemTooltip("Volume; range 0-15 (4 bits)");
            ImGui::TableNextColumn();
            ui_varonum_to_string(&win->sequencer->volume, str, IM_ARRAYSIZE(str));
            ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
            if (ImGui::InputText("##volume", str, IM_ARRAYSIZE(str))) {
                ui_string_to_varonum(str,&win->sequencer->volume);
            }
            ImGui::TableNextColumn();
            ImGui::EndTable();
        }
    }
   
    {
        ImGui::SeparatorText("Sequence Generator");
        if (ImGui::BeginTable("##sequences", 13, ImGuiTableFlags_BordersInnerH)) {
            ImGui::TableSetupColumn("##up", ImGuiTableColumnFlags_WidthFixed,16);
            ImGui::TableSetupColumn("##down", ImGuiTableColumnFlags_WidthFixed,16);
            ImGui::TableSetupColumn("VAR", ImGuiTableColumnFlags_WidthFixed, cw0);
            ImGui::TableSetupColumn("COUNT", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableSetupColumn("ADD1", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableSetupColumn("DIV1", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableSetupColumn("MUL1", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableSetupColumn("MOD1", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableSetupColumn("BASE", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableSetupColumn("MOD2", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableSetupColumn("MUL2", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableSetupColumn("DIV2", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableSetupColumn("ADD2", ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::TableHeadersRow();
            ImGui::TableNextColumn();

            for (int i = 0; i < 16; i++) {
                ImGui::PushID(i);
                sequence_t* seq = &win->sequencer->sequences[i];
                var_or_number_t* varonums[10]= {
                    &seq->count,
                    &seq->add1,
                    &seq->div1,
                    &seq->mul1,
                    &seq->mod1,
                    &seq->base,
                    &seq->mod2,
                    &seq->mul2,
                    &seq->div2,
                    &seq->add2
                };
                str[0] = seq->variable; str[1] = 0;

                if (ImGui::ArrowButton("^",ImGuiDir_Up)) 
                {
                    int j = floor_mod(i-1,NUM_SEQUENCES);
                    sequence_t seq1 = sequencer->sequences[j];  //copy
                    sequencer->sequences[j] = *seq;   // copy      
                    sequencer->sequences[i] = seq1;   // copy
                } 
                 ImGui::TableNextColumn();
                if (ImGui::ArrowButton("v",ImGuiDir_Down)) 
                {
                    int j = floor_mod(i+1,NUM_SEQUENCES);
                    sequence_t seq1 = sequencer->sequences[j];  //copy
                    sequencer->sequences[j] = *seq;   // copy      
                    sequencer->sequences[i] = seq1;   // copy
                } 
                ImGui::TableNextColumn();

                ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                if (ImGui::InputText("##var", str, IM_ARRAYSIZE(str))) {
                    char new_variable = ImToUpper(str[0]);
                    if (new_variable < 'A' || new_variable > 'Z') new_variable = 0;
                    seq->variable = new_variable;
                }

                ImGui::TableNextColumn();
                for (int col=0;col<10;++col) {
                    ImGui::PushID(col);
                    ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
                    ui_varonum_to_string(varonums[col], str, IM_ARRAYSIZE(str));
                    if (ImGui::InputText("##parameter", str, IM_ARRAYSIZE(str))) {
                        ui_string_to_varonum(str,varonums[col]);
                    }
                    ImGui::TableNextColumn();
                    ImGui::PopID();
                }
                ImGui::PopID();
            }
            ImGui::EndTable();
        }
    }

    ImGui::PopStyleVar(1);
    
}

void ui_sequencer_draw(ui_sequencer_t* win) {
    CHIPS_ASSERT(win && win->valid);
    ui_util_handle_window_open_dirty(&win->open, &win->last_open);
    if (!win->open) {
        return;
    }
    ImGui::SetNextWindowPos(ImVec2(win->init_x, win->init_y), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(win->init_w, win->init_h), ImGuiCond_FirstUseEver);
    if (ImGui::Begin(win->title, &win->open)) {
        ImGui::BeginChild("##sequencer_state", ImVec2(0, 0), true);
        _ui_sequencer_draw_state(win);
        ImGui::EndChild();
    }
    ImGui::End();
}

void ui_sequencer_save_settings(ui_sequencer_t* win, ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    ui_settings_add(settings, win->title, win->open);
}

void ui_sequencer_load_settings(ui_sequencer_t* win, const ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    win->open = ui_settings_isopen(settings, win->title);
}
#endif /* CHIPS_UI_IMPL */

#pragma once
/*#
    # ui_variables.h

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

    All strings provided to ui_variables_init() must remain alive until
    ui_variables_discard() is called!

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

/* setup parameters for ui_variables_init()
    NOTE: all string data must remain alive until ui_variables_discard()!
*/
typedef struct ui_variables_desc_t {
    const char* title;          /* window title */
    sequencer_t* sequencer;      /* object to show and edit */
    int x, y;                   /* initial window position */
    int w, h;                   /* initial window size (or default size of 0) */
    bool open;                  /* initial window open state */
} ui_variables_desc_t;

typedef struct ui_variables_t {
    const char* title;
    sequencer_t* sequencer;
    float init_x, init_y;
    float init_w, init_h;
    bool open;
    bool last_open;
    bool valid;
} ui_variables_t;

void ui_variables_init(ui_variables_t* win, const ui_variables_desc_t* desc);
void ui_variables_discard(ui_variables_t* win);
void ui_variables_draw(ui_variables_t* win);
void ui_variables_save_settings(ui_variables_t* win, ui_settings_t* settings);
void ui_variables_load_settings(ui_variables_t* win, const ui_settings_t* settings);

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


void ui_variables_init(ui_variables_t* win, const ui_variables_desc_t* desc) {
    CHIPS_ASSERT(win && desc);
    CHIPS_ASSERT(desc->title);
    memset(win, 0, sizeof(ui_variables_t));
    win->title = desc->title;
    win->sequencer = desc->sequencer;
    win->init_x = (float) desc->x;
    win->init_y = (float) desc->y;
    win->init_w = (float) ((desc->w == 0) ? 600 : desc->w);
    win->init_h = (float) ((desc->h == 0) ? 600 : desc->h);
    win->open = win->last_open = desc->open;
    win->valid = true;
}

void ui_variables_discard(ui_variables_t* win) {
    CHIPS_ASSERT(win && win->valid);
    win->valid = false;
}

static void _ui_variables_draw_state(ui_variables_t* win) {

    sequencer_t* sequencer = win->sequencer;

    const float cw = 64.0f;
    char str[16];       // reuse this string for conversions to/from varonum

    ImGui::PushStyleVar(ImGuiStyleVar_CellPadding, ImVec2(2,2));

    if (ImGui::BeginTable("##sequences", 15,ImGuiTableFlags_BordersInnerH | ImGuiTableFlags_SizingFixedFit)) {
        ImGui::TableSetupColumn("##up", ImGuiTableColumnFlags_WidthFixed,16);
        ImGui::TableSetupColumn("##down", ImGuiTableColumnFlags_WidthFixed,16);
        ImGui::TableSetupColumn("VAR", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("=", ImGuiTableColumnFlags_WidthFixed, 16);
        ImGui::TableSetupColumn("COUNT", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("ADD1", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("DIV1", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("MUL1", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("MOD1", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("BASE", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("ARRAY", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("MOD2", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("MUL2", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("DIV2", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("ADD2", ImGuiTableColumnFlags_WidthFixed, cw);

        ImGui::TableHeadersRow();
        ImGui::TableNextColumn();

        for (int i = 0; i < sequencer->num_sequences; i++) {
            ImGui::PushID(i);
            sequence_t* seq = &win->sequencer->sequences[i];
            var_or_number_t* varonums[11]= {
                &seq->count,
                &seq->add1,
                &seq->div1,
                &seq->mul1,
                &seq->mod1,
                &seq->base,
                &seq->array,
                &seq->mod2,
                &seq->mul2,
                &seq->div2,
                &seq->add2
            };
            str[0] = seq->variable; str[1] = 0;

            if (ImGui::ArrowButton("^",ImGuiDir_Up)) 
            {
                int j = floor_mod(i-1,sequencer->num_sequences);
                sequence_t seq1 = sequencer->sequences[j];  //copy
                sequencer->sequences[j] = *seq;   // copy      
                sequencer->sequences[i] = seq1;   // copy
            } 
            ImGui::TableNextColumn();

            if (ImGui::ArrowButton("v",ImGuiDir_Down)) 
            {
                int j = floor_mod(i+1,sequencer->num_sequences);
                sequence_t seq1 = sequencer->sequences[j];  //copy
                sequencer->sequences[j] = *seq;   // copy      
                sequencer->sequences[i] = seq1;   // copy
            } 
            ImGui::TableNextColumn();

            ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
            if (ImGui::InputText("##var", str, IM_ARRAYSIZE(str))) {
                char new_variable = ImToUpper(str[0]);
                // TODO: in future may want to support more variables
                if (new_variable < 'A' || new_variable > 'Z') new_variable = 0;
                seq->variable = new_variable;
            }
            ImGui::TableNextColumn();
            
            ImGui::TextUnformatted("");        //=
            ImGui::TableNextColumn();

            for (int col=0;col<11;++col) {
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

        if (sequencer->num_sequences < MAX_SEQUENCES) {
            if (ImGui::Button("+")) {
                sequencer->num_sequences++;
            }
            ImGui::SameLine();        
        }
        if (sequencer->num_sequences > 0) {
            if (ImGui::Button("-")) {
                sequencer->num_sequences--;
            }
            ImGui::SameLine();
        }
    }

    ImGui::PopStyleVar(1);
    
}

void ui_variables_draw(ui_variables_t* win) {
    CHIPS_ASSERT(win && win->valid);
    ui_util_handle_window_open_dirty(&win->open, &win->last_open);
    if (!win->open) {
        return;
    }
    ImGui::SetNextWindowPos(ImVec2(win->init_x, win->init_y), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(win->init_w, win->init_h), ImGuiCond_FirstUseEver);
    if (ImGui::Begin(win->title, &win->open)) {
        ImGui::BeginChild("##sequencer_state", ImVec2(0, 0), true);
        _ui_variables_draw_state(win);
        ImGui::EndChild();
    }
    ImGui::End();
}

void ui_variables_save_settings(ui_variables_t* win, ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    ui_settings_add(settings, win->title, win->open);
}

void ui_variables_load_settings(ui_variables_t* win, const ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    win->open = ui_settings_isopen(settings, win->title);
}
#endif /* CHIPS_UI_IMPL */

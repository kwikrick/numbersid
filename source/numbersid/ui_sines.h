#pragma once
/*#
    # ui_sines.h

    Visualization for numbersid sound sines.

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

    All strings provided to ui_sines_init() must remain alive until
    ui_sines_discard() is called!

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

/* setup sines for ui_sines_init()
    NOTE: all string data must remain alive until ui_sines_discard()!
*/
typedef struct ui_sines_desc_t {
    const char* title;          /* window title */
    sequencer_t* sequencer;      /* object to show and edit */
    int x, y;                   /* initial window position */
    int w, h;                   /* initial window size (or default size of 0) */
    bool open;                  /* initial window open state */
} ui_sines_desc_t;

typedef struct ui_sines_t {
    const char* title;
    sequencer_t* sequencer;
    float init_x, init_y;
    float init_w, init_h;
    bool open;
    bool last_open;
    bool valid;
} ui_sines_t;

void ui_sines_init(ui_sines_t* win, const ui_sines_desc_t* desc);
void ui_sines_discard(ui_sines_t* win);
void ui_sines_draw(ui_sines_t* win);
void ui_sines_save_settings(ui_sines_t* win, ui_settings_t* settings);
void ui_sines_load_settings(ui_sines_t* win, const ui_settings_t* settings);

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


// ------- ui_sines_t implementation -------

void ui_sines_init(ui_sines_t* win, const ui_sines_desc_t* desc) {
    CHIPS_ASSERT(win && desc);
    CHIPS_ASSERT(desc->title);
    memset(win, 0, sizeof(ui_sines_t));
    win->title = desc->title;
    win->sequencer = desc->sequencer;
    win->init_x = (float) desc->x;
    win->init_y = (float) desc->y;
    win->init_w = (float) ((desc->w == 0) ? 600 : desc->w);
    win->init_h = (float) ((desc->h == 0) ? 600 : desc->h);
    win->open = win->last_open = desc->open;
    win->valid = true;
}

void ui_sines_discard(ui_sines_t* win) {
    CHIPS_ASSERT(win && win->valid);
    win->valid = false;
}

void draw_sine_columns(sequencer_t* sequencer, size_t param_offset, const char* id_str) {
     for (int i = 0; i < sequencer->num_sines; i++) {
        var_or_number_t* varonum = (var_or_number_t*) ((uint8_t*)(&sequencer->sines[i]) + param_offset);
        ImGui::PushID(i);
        draw_varonum(varonum, id_str);
        ImGui::PopID();
        ImGui::TableNextColumn();
    }
}

static void _ui_sines_draw_state(ui_sines_t* win) {

    sequencer_t* sequencer = win->sequencer;

    const float cw0 = 84.0f;
    const float cw = 64.0f;
   
    ImGui::PushStyleVar(ImGuiStyleVar_CellPadding, ImVec2(2,2));
    
    if (ImGui::BeginTable("##sines", sequencer->num_sines + 1, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_RowBg)) {
        ImGui::TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, cw0);
        for (int i = 0; i < sequencer->num_sines; i++) {
            char col_name[16];
            snprintf(col_name, sizeof(col_name), "Sine %d", i + 1);
            ImGui::TableSetupColumn(col_name, ImGuiTableColumnFlags_WidthFixed, cw);
        }
        ImGui::TableHeadersRow();
        ImGui::TableNextColumn();

        // row for buttons
        if (sequencer->num_sines > 0) {
            if (ImGui::Button("-")) {
                sequencer->num_sines--;
            }
        }
        ImGui::SameLine();
        if (sequencer->num_sines < MAX_SINES) {
            if (ImGui::Button("+")) {
                sequencer->num_sines++;
            }
        }
        ImGui::TableNextColumn();
        for (int i = 0; i < sequencer->num_sines; i++) {
            ImGui::PushID(i);
            if (ImGui::ArrowButton("<", ImGuiDir_Left)) {
                    int j=floor_mod(i-1, sequencer->num_sines);
                    sine_t temp = sequencer->sines[j];
                    sequencer->sines[j] = sequencer->sines[i];
                    sequencer->sines[i] = temp;
                
            }
            ImGui::SameLine();
            if (ImGui::ArrowButton(">", ImGuiDir_Right)) {
                    int j=floor_mod(i+1, sequencer->num_sines);
                    sine_t temp = sequencer->sines[j];
                    sequencer->sines[j] = sequencer->sines[i];
                    sequencer->sines[i] = temp;
            }
            ImGui::PopID();
            ImGui::TableNextColumn();
        }
        

        //ImGui::TableNextColumn();
        ImGui::Text("FREQ"); 
        ImGui::SetItemTooltip("Frequency: 0-65536; freq/256 cycles per 256 frames");
        ImGui::TableNextColumn();
        draw_sine_columns(sequencer, offsetof(sine_t, freq), "##gate");

        ImGui::Text("AMP");
        ImGui::SetItemTooltip("Amplitude; in sceen characters; 0 - 255"); 
        ImGui::TableNextColumn();
        draw_sine_columns(sequencer, offsetof(sine_t, amplitude), "##note");

        ImGui::Text("PHASE");
        ImGui::SetItemTooltip("Phase: 0-255");
        ImGui::TableNextColumn();
        draw_sine_columns(sequencer, offsetof(sine_t, phase), "##scale");
            
        ImGui::EndTable();
    }


    if (ImGui::BeginTable("##bob", 2, ImGuiTableFlags_SizingFixedFit)) {
        ImGui::TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, cw0);
        ImGui::TableSetupColumn("BOB", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableHeadersRow();
        ImGui::TableNextColumn();
        
        ImGui::Text("COLOR");
        ImGui::SetItemTooltip("Color: 0-15");
        ImGui::TableNextColumn();
        draw_varonum(&sequencer->bob.color, "##bobcolor");
        ImGui::TableNextColumn();

        ImGui::Text("STEP");
        ImGui::SetItemTooltip("Step: 0-255 for animated character step; negative for fixed character (-1..-8)");
        ImGui::TableNextColumn();
        draw_varonum(&sequencer->bob.step, "##bobsetp");
        ImGui::TableNextColumn();
        
        ImGui::EndTable();
    }
   
    ImGui::PopStyleVar(1);
    
}

void ui_sines_draw(ui_sines_t* win) {
    CHIPS_ASSERT(win && win->valid);
    ui_util_handle_window_open_dirty(&win->open, &win->last_open);
    if (!win->open) {
        return;
    }
    ImGui::SetNextWindowPos(ImVec2(win->init_x, win->init_y), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(win->init_w, win->init_h), ImGuiCond_FirstUseEver);
    if (ImGui::Begin(win->title, &win->open)) {
        ImGui::BeginChild("##sequencer_state", ImVec2(0, 0), true);
        _ui_sines_draw_state(win);
        ImGui::EndChild();
    }
    ImGui::End();
}

void ui_sines_save_settings(ui_sines_t* win, ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    ui_settings_add(settings, win->title, win->open);
}

void ui_sines_load_settings(ui_sines_t* win, const ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    win->open = ui_settings_isopen(settings, win->title);
}
#endif /* CHIPS_UI_IMPL */

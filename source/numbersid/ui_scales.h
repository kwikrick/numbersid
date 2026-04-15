#pragma once
/*#
    # ui_scales.h

    Visualization for numbersid scales.

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

    All strings provided to ui_scales_init() must remain alive until
    ui_scales_discard() is called!

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

/* setup parameters for ui_scales_init()
    NOTE: all string data must remain alive until ui_scales_discard()!
*/
typedef struct ui_scales_desc_t {
    const char* title;          /* window title */
    sequencer_t* sequencer;      /* object to show and edit */
    int x, y;                   /* initial window position */
    int w, h;                   /* initial window size (or default size of 0) */
    bool open;                  /* initial window open state */
} ui_scales_desc_t;

typedef struct ui_scales_t {
    const char* title;
    sequencer_t* sequencer;
    float init_x, init_y;
    float init_w, init_h;
    bool open;
    bool last_open;
    bool valid;
} ui_scales_t;

void ui_scales_init(ui_scales_t* win, const ui_scales_desc_t* desc);
void ui_scales_discard(ui_scales_t* win);
void ui_scales_draw(ui_scales_t* win);
void ui_scales_save_settings(ui_scales_t* win, ui_settings_t* settings);
void ui_scales_load_settings(ui_scales_t* win, const ui_settings_t* settings);

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


void ui_scales_init(ui_scales_t* win, const ui_scales_desc_t* desc) {
    CHIPS_ASSERT(win && desc);
    CHIPS_ASSERT(desc->title);
    memset(win, 0, sizeof(ui_scales_t));
    win->title = desc->title;
    win->sequencer = desc->sequencer;
    win->init_x = (float) desc->x;
    win->init_y = (float) desc->y;
    win->init_w = (float) ((desc->w == 0) ? 600 : desc->w);
    win->init_h = (float) ((desc->h == 0) ? 600 : desc->h);
    win->open = win->last_open = desc->open;
    win->valid = true;
}

void ui_scales_discard(ui_scales_t* win) {
    CHIPS_ASSERT(win && win->valid);
    win->valid = false;
}

static void _ui_scales_draw_state(ui_scales_t* win) {

    static const char note_names[12][3] = {"C","C#","D","D#","E","F","F#","G","G#","A","A#","B"};

    sequencer_t* sequencer = win->sequencer;

    const float cw = 64.0f;
    char str[16];       // reuse this string for conversions to/from varonum

    ImGui::PushStyleVar(ImGuiStyleVar_CellPadding, ImVec2(2,2));

    if (ImGui::BeginTable("##scales", 3+SCALE_SIZE ,ImGuiTableFlags_BordersInnerH | ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_RowBg | ImGuiTableFlags_RowBg)) {
        ImGui::TableSetupColumn("##up", ImGuiTableColumnFlags_WidthFixed,16);
        ImGui::TableSetupColumn("##down", ImGuiTableColumnFlags_WidthFixed,16);
        ImGui::TableSetupColumn("SCALE", ImGuiTableColumnFlags_WidthFixed,cw);
        for (int col=0;col<SCALE_SIZE;++col) {
            ImGui::PushID(col);
            sprintf(str,note_names[col],col);
            ImGui::TableSetupColumn(str, ImGuiTableColumnFlags_WidthFixed, cw);
            ImGui::PopID();
        }
       
        ImGui::TableHeadersRow();
        ImGui::TableNextColumn();

        for (int i = 0; i < sequencer->num_scales; i++) {
            ImGui::PushID(i);

             if (ImGui::ArrowButton("^",ImGuiDir_Up)) 
            {
                int j = floor_mod(i-1,sequencer->num_scales);
                bool scale[SCALE_SIZE];
                memcpy(scale, sequencer->scales[j], sizeof(scale));
                memcpy(sequencer->scales[j], sequencer->scales[i], sizeof(scale));
                memcpy(sequencer->scales[i], scale, sizeof(scale));
            } 
            ImGui::TableNextColumn();

            if (ImGui::ArrowButton("v",ImGuiDir_Down)) 
            {
                int j = floor_mod(i+1,sequencer->num_scales);
                bool scale[SCALE_SIZE];
                memcpy(scale, sequencer->scales[j], sizeof(scale));
                memcpy(sequencer->scales[j], sequencer->scales[i], sizeof(scale));
                memcpy(sequencer->scales[i], scale, sizeof(scale));
            } 
            ImGui::TableNextColumn();
            
            ImGui::Text("#%d", i+1);
            ImGui::TableNextColumn();

            for (int col=0;col<SCALE_SIZE;++col) {
                ImGui::PushID(col);
                //draw_varonum(&sequencer->scales[i][col], "##elem");
                ImGui::Checkbox("?",&sequencer->scales[i][col]);
                ImGui::TableNextColumn();
                ImGui::PopID();
            }
            //for (int col=sequencer->scale_sizes[i];col<SCALE_SIZE;++col) {
            //    ImGui::TableNextColumn();
            //}

            ImGui::PopID();
        }
        ImGui::EndTable();

        if (sequencer->num_scales < MAX_SCALES) {
            if (ImGui::Button("+")) {
                sequencer->num_scales++;
            }
            ImGui::SameLine();        
        }
        if (sequencer->num_scales > 0) {
            if (ImGui::Button("-")) {
                sequencer->num_scales--;
            }
            ImGui::SameLine();
        }
    }

    ImGui::PopStyleVar(1);
    
}

void ui_scales_draw(ui_scales_t* win) {
    CHIPS_ASSERT(win && win->valid);
    ui_util_handle_window_open_dirty(&win->open, &win->last_open);
    if (!win->open) {
        return;
    }
    ImGui::SetNextWindowPos(ImVec2(win->init_x, win->init_y), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(win->init_w, win->init_h), ImGuiCond_FirstUseEver);
    if (ImGui::Begin(win->title, &win->open)) {
        ImGui::BeginChild("##sequencer_state", ImVec2(0, 0), true);
        _ui_scales_draw_state(win);
        ImGui::EndChild();
    }
    ImGui::End();
}

void ui_scales_save_settings(ui_scales_t* win, ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    ui_settings_add(settings, win->title, win->open);
}

void ui_scales_load_settings(ui_scales_t* win, const ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    win->open = ui_settings_isopen(settings, win->title);
}
#endif /* CHIPS_UI_IMPL */

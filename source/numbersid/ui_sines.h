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

void draw_orbit_columns(bob_t* bob, size_t param_offset, const char* id_str) {
     for (int i = 0; i < bob->num_orbits; i++) {
        var_or_number_t* varonum = (var_or_number_t*) ((uint8_t*)(&bob->orbits[i]) + param_offset);
        ImGui::PushID(i);
        draw_varonum(varonum, id_str);
        ImGui::PopID();
        ImGui::TableNextColumn();
    }
}


static void _draw_bob(bob_t* bob)
{
    ImGui::PushStyleVar(ImGuiStyleVar_CellPadding, ImVec2(2,2));
    
    const float cw0 = 84.0f;
    const float cw = 64.0f;

    if (ImGui::BeginTable("##bob", 2, ImGuiTableFlags_SizingFixedFit)) {
        ImGui::TableSetupColumn("PARAM", ImGuiTableColumnFlags_WidthFixed, cw0);
        ImGui::TableSetupColumn("VAL", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableHeadersRow();
        ImGui::TableNextColumn();
        
        ImGui::Text("COLOR");
        ImGui::SetItemTooltip("Color: 0-15");
        ImGui::TableNextColumn();
        draw_varonum(&bob->color, "##bobcolor");
        ImGui::TableNextColumn();

        ImGui::Text("STEP");
        ImGui::SetItemTooltip("Step: 0-255 for animated character step; negative for fixed character (-1..-8)");
        ImGui::TableNextColumn();
        draw_varonum(&bob->step, "##bobstep");
        ImGui::TableNextColumn();
        
        ImGui::EndTable();
    }
   
   
    if (ImGui::BeginTable("##orbits", bob->num_orbits + 1, ImGuiTableFlags_SizingFixedFit | ImGuiTableFlags_RowBg)) {
        ImGui::TableSetupColumn("", ImGuiTableColumnFlags_WidthFixed, cw0);
        for (int i = 0; i < bob->num_orbits; i++) {
            char col_name[16];
            snprintf(col_name, sizeof(col_name), "Orbit %d", i + 1);
            ImGui::TableSetupColumn(col_name, ImGuiTableColumnFlags_WidthFixed, cw);
        }
        ImGui::TableHeadersRow();
        ImGui::TableNextColumn();

        // row for buttons
        if (bob->num_orbits > 0) {
            if (ImGui::Button("-")) {
                bob->num_orbits--;
            }
        }
        ImGui::SameLine();
        if (bob->num_orbits < MAX_ORBITS_PER_BOB) {
            if (ImGui::Button("+")) {
                bob->num_orbits++;
            }
        }
        ImGui::TableNextColumn();
        for (int i = 0; i < bob->num_orbits; i++) {
            ImGui::PushID(i);
            if (ImGui::ArrowButton("<", ImGuiDir_Left)) {
                    int j=floor_mod(i-1, bob->num_orbits);
                    orbit_t temp = bob->orbits[j];
                    bob->orbits[j] = bob->orbits[i];
                    bob->orbits[i] = temp;
                
            }
            ImGui::SameLine();
            if (ImGui::ArrowButton(">", ImGuiDir_Right)) {
                    int j=floor_mod(i+1, bob->num_orbits);
                    orbit_t temp = bob->orbits[j];
                    bob->orbits[j] = bob->orbits[i];
                    bob->orbits[i] = temp;
            }
            ImGui::PopID();
            ImGui::TableNextColumn();
        }
        

        //ImGui::TableNextColumn();
        ImGui::Text("FREQ X"); 
        ImGui::SetItemTooltip("Frequency: 0-65536; freq/256 cycles per 256 frames");
        ImGui::TableNextColumn();
        draw_orbit_columns(bob, offsetof(orbit_t, freq_x), "##freq_x");

        ImGui::Text("FREQ Y"); 
        ImGui::SetItemTooltip("Frequency: 0-65536; freq/256 cycles per 256 frames");
        ImGui::TableNextColumn();
        draw_orbit_columns(bob, offsetof(orbit_t, freq_y), "##freq_y");

        ImGui::Text("AMP X");
        ImGui::SetItemTooltip("Amplitude; in sceen characters; 0 - 31"); 
        ImGui::TableNextColumn();
        draw_orbit_columns(bob, offsetof(orbit_t, amplitude_x), "##amp_x");

         ImGui::Text("AMP Y");
        ImGui::SetItemTooltip("Amplitude; in sceen characters; 0 - 31"); 
        ImGui::TableNextColumn();
        draw_orbit_columns(bob, offsetof(orbit_t, amplitude_y), "##amp_y");

        ImGui::Text("PHASE X");
        ImGui::SetItemTooltip("Phase: 0-255");
        ImGui::TableNextColumn();
        draw_orbit_columns(bob, offsetof(orbit_t, phase_x), "##phase_x");

         ImGui::Text("PHASE Y");
        ImGui::SetItemTooltip("Phase: 0-255");
        ImGui::TableNextColumn();
        draw_orbit_columns(bob, offsetof(orbit_t, phase_y), "##phase_y");
            
        ImGui::EndTable();
    }

    ImGui::PopStyleVar(1);
}

static void _ui_sines_draw_state(ui_sines_t* win) {

    sequencer_t* sequencer = win->sequencer;

    // buttons for adding/removing bob
    if (sequencer->num_bobs > 0) {
        if (ImGui::Button("-")) {
            sequencer->num_bobs--;
        }
    }
    ImGui::SameLine();
    if (sequencer->num_bobs < MAX_BOBS) {
        if (ImGui::Button("+")) {
            sequencer->num_bobs++;
        }
    }

    for (int bobnr = 0; bobnr < sequencer->num_bobs; ++bobnr) {
        char bob_name[16];
        snprintf(bob_name, sizeof(bob_name), "Bob %d", bobnr + 1);
        if (ImGui::CollapsingHeader(bob_name)) {
            _draw_bob(&sequencer->bobs[bobnr]);
        }
    }
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

#pragma once
/*#
    # ui_preview.h

    Preview window for numbersid.

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
        - ui_chip.h
        - ui_settings.h

    Include the following headers before including the *implementation*:
        - imgui.h
        - sequencer.h
        - ui_chip.h
        - ui_util.h

    All strings provided to ui_preview_init() must remain alive until
    ui_preview_discard() is called!

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

/* setup parameters for ui_preview_init()
    NOTE: all string data must remain alive until ui_preview_discard()!
*/
typedef struct ui_preview_desc_t {
    const char* title;          /* window title */
    sequencer_t* sequencer;      /* object to show and edit */
    int x, y;                   /* initial window position */
    int w, h;                   /* initial window size (or default size of 0) */
    bool open;                  /* initial window open state */
} ui_preview_desc_t;

typedef struct ui_preview_t {
    const char* title;
    sequencer_t* sequencer;
    float init_x, init_y;
    float init_w, init_h;
    bool open;
    bool last_open;
    bool valid;
} ui_preview_t;

void ui_preview_init(ui_preview_t* win, const ui_preview_desc_t* desc);
void ui_preview_discard(ui_preview_t* win);
void ui_preview_draw(ui_preview_t* win);
void ui_preview_save_settings(ui_preview_t* win, ui_settings_t* settings);
void ui_preview_load_settings(ui_preview_t* win, const ui_settings_t* settings);

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

void ui_preview_init(ui_preview_t* win, const ui_preview_desc_t* desc) {
    CHIPS_ASSERT(win && desc);
    CHIPS_ASSERT(desc->title);
    CHIPS_ASSERT(desc->sequencer);
    memset(win, 0, sizeof(ui_preview_t));
    win->title = desc->title;
    win->sequencer = desc->sequencer;
    win->init_x = (float) desc->x;
    win->init_y = (float) desc->y;
    win->init_w = (float) ((desc->w == 0) ? 496 : desc->w);
    win->init_h = (float) ((desc->h == 0) ? 410 : desc->h);
    win->open = win->last_open = desc->open;
    win->valid = true;
}

void ui_preview_discard(ui_preview_t* win) {
    CHIPS_ASSERT(win && win->valid);
    win->valid = false;
}

static void _ui_preview_draw_state(ui_preview_t* win) {

    preview_t* preview = &win->sequencer->preview;

    const float cw0 = 84.0f;
    const float cw = 64.0f;
    char str[16];       // reuse this string for conversions to/from varonum

    ImGui::PushItemWidth(cw0);
    ImGui::InputInt("Step",&preview->step);
    ImGui::InputInt("Offset",&preview->offset, 1, preview->step, preview->follow ? ImGuiInputTextFlags_ReadOnly: 0); 
    ImGui::SameLine(); ImGui::Checkbox("Follow", &preview->follow);    
    ImGui::PopItemWidth();

     if (ImGui::CollapsingHeader("Highlighters")) {
        // highlighters UI
        for (int i=0;i<preview->num_highlighters;++i) {
            highlighter_t* hl = &preview->highlighters[i];
            ImGui::PushID(i);
            ImGui::ColorEdit4("Color", (float*)&hl->color, ImGuiColorEditFlags_NoInputs | ImGuiColorEditFlags_NoLabel);
            ImGui::SameLine();
            ImGui::PushItemWidth(cw0);
            ImGui::InputInt("##Value",&hl->value);
            ImGui::SameLine();
            ImGui::Text("MOD");
            ImGui::SameLine();
            ImGui::InputInt("##Mod",&hl->modulo);
            ImGui::PopItemWidth();
            ImGui::SameLine();
            if (ImGui::Button("X")) {
                // remove highlighter
                for (int j=i;j<preview->num_highlighters-1;++j) {
                    preview->highlighters[j] = preview->highlighters[j+1];
                }
                preview->num_highlighters--;
                i--;    // stay at same index
            }
            ImGui::PopID();
        }
        if (preview->num_highlighters < MAX_HIGHLIGHTERS) {
            if (ImGui::Button("+")) {
                highlighter_t* hl = &preview->highlighters[preview->num_highlighters++];
                hl->value = 0;
                hl->modulo = 0;
                hl->color[0] =  1.0f;
                hl->color[1] =  1.0f;
                hl->color[2] =  1.0f;
                hl->color[3] =  0.25f; 
            }
        }
    }

    ImGui::PushStyleVar(ImGuiStyleVar_CellPadding, ImVec2(2,2));

    int numcols = preview->num_columns;

    if (ImGui::BeginTable("##preview", numcols+3, ImGuiTableFlags_BordersV | ImGuiTableFlags_SizingFixedFit)) {
        ImGui::TableSetupColumn("Frame", ImGuiTableColumnFlags_WidthFixed, cw);
        ImGui::TableSetupColumn("##plusmin", ImGuiTableColumnFlags_WidthFixed, 40);
        for (int col=0; col<numcols;++col) {
            ImGui::TableSetupColumn("Var", ImGuiTableColumnFlags_WidthFixed, cw);
        }
        ImGui::TableSetupColumn("##empty", ImGuiTableColumnFlags_WidthStretch);

        ImGui::TableHeadersRow();
        ImGui::TableNextColumn();

        ImGui::TableNextColumn();  // empty row in frame col

        if (preview->num_columns < MAX_PREVIEW_COLS) {
            if (ImGui::Button("+")) {
                preview->num_columns++;
            }
            ImGui::SameLine();        
        }
        if (preview->num_columns > 0) {
            if (ImGui::Button("-")) {
                preview->num_columns--;
            }
            ImGui::SameLine();
        }
        ImGui::TableNextColumn();

        for (int col=0; col<numcols;++col) {
            ImGui::PushID(col);
            str[0] = preview->variables[col];
            str[1] = 0;
            ImGui::SetNextItemWidth(-FLT_MIN); // Right-aligned
            //ImGui::PushStyleColor(ImGuiCol_FrameBg, ImVec4(0.8f,0.8f,0.0f,1.0f)); // variable color);
            if (ImGui::InputText("##var",str, IM_ARRAYSIZE(str))) {
                char new_variable = ImToUpper(str[0]);
                // TODO: in future may want to support more variables
                if (new_variable < 'A' || new_variable > 'Z') new_variable = 0;
                    preview->variables[col] = new_variable;
            }
            ImGui::TableNextColumn();
            //ImGui::PopStyleColor();
            ImGui::PopID();
        }
        ImGui::TableNextColumn();   // empty col at end

        for (int row=0;row<NUM_PREVIEW_ROWS;++row) {

            ImGui::Text("%6i", preview->frames[row]); 
            ImGui::TableNextColumn();

            ImGui::TableNextColumn();  // +-

            for (int col=0; col<numcols;++col) {
                int index = preview->variables[col] - 'A';
                if (index >= 0 && index < MAX_VARIABLES) { 
                    
                    int16_t value = preview->values[row][col];

                    // highlighting
                    float cell_bg_color_array[4] = {0.0f,0.0f,0.0f,0.0f};
                    int highlighted = 0;
                    for (int h=0;h<preview->num_highlighters;++h) {
                        highlighter_t* hl = &preview->highlighters[h];
                        if ( (hl->modulo == 0 && value == hl->value) ||
                             (hl->modulo != 0 && (value % hl->modulo) == hl->value) ) {
                            cell_bg_color_array[0] += hl->color[0];
                            cell_bg_color_array[1] += hl->color[1];
                            cell_bg_color_array[2] += hl->color[2];
                            cell_bg_color_array[3] += hl->color[3];
                            highlighted++;
                        }
                    }
                    if (highlighted > 0) {
                        // clamp alpha
                        cell_bg_color_array[0] = cell_bg_color_array[0] / (float)highlighted;
                        cell_bg_color_array[1] = cell_bg_color_array[1] / (float)highlighted;
                        cell_bg_color_array[2] = cell_bg_color_array[2] / (float)highlighted;
                        cell_bg_color_array[3] = cell_bg_color_array[3] / (float)highlighted;
                        ImU32 cell_bg_color = ImGui::GetColorU32( ImVec4(cell_bg_color_array[0],cell_bg_color_array[1],cell_bg_color_array[2],cell_bg_color_array[3]) );
                        ImGui::TableSetBgColor(ImGuiTableBgTarget_CellBg, cell_bg_color);
                    }

                    ImGui::Text("%6i",value);
                }
                else {
                    ImGui::TextUnformatted("");
                }
                ImGui::TableNextColumn();
            }
            ImGui::TableNextColumn();   // empty col at end
        }
        ImGui::EndTable();
    }

    ImGui::PopStyleVar();
    
}

void ui_preview_draw(ui_preview_t* win) {
    CHIPS_ASSERT(win && win->valid);
    ui_util_handle_window_open_dirty(&win->open, &win->last_open);
    if (!win->open) {
        return;
    }
    ImGui::SetNextWindowPos(ImVec2(win->init_x, win->init_y), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(win->init_w, win->init_h), ImGuiCond_FirstUseEver);
    if (ImGui::Begin(win->title, &win->open)) {
        ImGui::BeginChild("##preview_state", ImVec2(0, 0), true);
        _ui_preview_draw_state(win);
        ImGui::EndChild();
    }
    ImGui::End();
}

void ui_preview_save_settings(ui_preview_t* win, ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    ui_settings_add(settings, win->title, win->open);
}

void ui_preview_load_settings(ui_preview_t* win, const ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    win->open = ui_settings_isopen(settings, win->title);
}
#endif /* CHIPS_UI_IMPL */

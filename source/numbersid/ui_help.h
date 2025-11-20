#pragma once
/*#
    # ui_help.h

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

    All strings provided to ui_help_init() must remain alive until
    ui_help_discard() is called!

    ## zlib/libpng license

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
#include <sokol_fetch.h>

#ifdef __cplusplus
extern "C" {
#endif

/* setup parameters for ui_help_init()
    NOTE: all string data must remain alive until ui_help_discard()!
*/
typedef struct ui_help_desc_t {
    const char* title;          /* window title */
    int x, y;                   /* initial window position */
    int w, h;                   /* initial window size (or default size of 0) */
    bool open;                  /* initial window open state */
} ui_help_desc_t;

typedef struct ui_help_t {
    const char* title;
    float init_x, init_y;
    float init_w, init_h;
    bool open;
    bool last_open;
    bool valid;
    char* text;
} ui_help_t;

void ui_help_init(ui_help_t* win, const ui_help_desc_t* desc);
void ui_help_discard(ui_help_t* win);
void ui_help_draw(ui_help_t* win);
void ui_help_save_settings(ui_help_t* win, ui_settings_t* settings);
void ui_help_load_settings(ui_help_t* win, const ui_settings_t* settings);

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

#define HELP_TEXT_SIZE  1024*1024
static char help_text[HELP_TEXT_SIZE];
static bool help_fetch_done = false;
static bool help_fetch_ok = false;

static void help_fetch_callback (const sfetch_response_t* response)
{
    if (response->fetched) {
        help_fetch_done = true;
        help_fetch_ok = true;
        help_text[response->data.size] = 0;     // zero terminate data
    }
    else if (response->finished) {
        help_fetch_done = true;
    }
    else if (response->failed) {
        help_fetch_done = true;
    }
    else if (response->cancelled) {
        help_fetch_done = true;
    }
    else if (response->paused) {
        help_fetch_done = true;
    }
}

void ui_help_init(ui_help_t* win, const ui_help_desc_t* desc) {
    CHIPS_ASSERT(win && desc);
    CHIPS_ASSERT(desc->title);
    memset(win, 0, sizeof(ui_help_t));
    win->title = desc->title;
    win->init_x = (float) desc->x;
    win->init_y = (float) desc->y;
    win->init_w = (float) ((desc->w == 0) ? 496 : desc->w);
    win->init_h = (float) ((desc->h == 0) ? 410 : desc->h);
    win->open = win->last_open = desc->open;
    win->valid = true;

    sfetch_handle_t handle = sfetch_send((sfetch_request_t){
        .channel = 0, 
        .path = "help/help.txt",
        .callback = &help_fetch_callback,
        .buffer = (sfetch_range_t) {
            .ptr = help_text,
            .size = HELP_TEXT_SIZE
        }
    });
}

void ui_help_discard(ui_help_t* win) {
    CHIPS_ASSERT(win && win->valid);
    win->valid = false;
}

static void _ui_help_draw_state(ui_help_t* win) {

    if (help_fetch_ok) {
        ImGui::Text(help_text);
    }
    else {
        ImGui::Text("Downloading help...");
    }
}

void ui_help_draw(ui_help_t* win) {
    CHIPS_ASSERT(win && win->valid);
    ui_util_handle_window_open_dirty(&win->open, &win->last_open);
    if (!win->open) {
        return;
    }
    ImGui::SetNextWindowPos(ImVec2(win->init_x, win->init_y), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(win->init_w, win->init_h), ImGuiCond_FirstUseEver);
    if (ImGui::Begin(win->title, &win->open)) {
        ImGui::BeginChild("##preview_state", ImVec2(0, 0), true);
        _ui_help_draw_state(win);
        ImGui::EndChild();
    }
    ImGui::End();
}

void ui_help_save_settings(ui_help_t* win, ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    ui_settings_add(settings, win->title, win->open);
}

void ui_help_load_settings(ui_help_t* win, const ui_settings_t* settings) {
    CHIPS_ASSERT(win && settings);
    win->open = ui_settings_isopen(settings, win->title);
}
#endif /* CHIPS_UI_IMPL */

#pragma once
/*#
    # ui_numbersid.h

    UI for numbersid.

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

    Include the following headers (and their depenencies) before including
    ui_numbersid.h both for the declaration and implementation.

    - ui_util.h
    - ui_settings.h
    - ui_m6581.h
    - ui_audio.h
    - ui_sequencer.h
    - ui_preview.h
    - ui_data.h
    - ui_help

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

// reboot callback
typedef void (*ui_numbersid_boot_cb)(sequencer_t* seq);

// setup params for ui_numbersid_init()
typedef struct {
    sequencer_t* sequencer;     // pointer to the sequencer
    int audio_num_samples;
    float* audio_sample_buffer;
    ui_numbersid_boot_cb boot_cb; // reboot callback functions
} ui_numbersid_desc_t;

typedef struct {
    sequencer_t* sequencer;
    
    ui_numbersid_boot_cb boot_cb;
    ui_m6581_t ui_sid;
    ui_audio_t ui_audio;
    ui_sequencer_t ui_sequencer;
    ui_preview_t ui_preview;
    ui_data_t ui_data;
    ui_help_t ui_help;
} ui_numbersid_t;



void ui_numbersid_init(ui_numbersid_t* ui, const ui_numbersid_desc_t* desc);
void ui_numbersid_discard(ui_numbersid_t* ui);
void ui_numbersid_draw(ui_numbersid_t* ui);
void ui_numbersid_save_settings(ui_numbersid_t* ui, ui_settings_t* settings);
void ui_numbersid_load_settings(ui_numbersid_t* ui, const ui_settings_t* settings);

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
#ifdef __clang__
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmissing-field-initializers"
#endif

static void _ui_numbersid_draw_menu(ui_numbersid_t* ui) {
    CHIPS_ASSERT(ui && ui->sequencer);
    if (ImGui::BeginMainMenuBar()) {
        if (ImGui::BeginMenu("System")) {
            if (ImGui::MenuItem("Reboot")) {
                ui->boot_cb(ui->sequencer);
            }
            ImGui::EndMenu();
        }
        if (ImGui::BeginMenu("Windows")) {
            ImGui::MenuItem("Sequencer", 0, &ui->ui_sequencer.open);
            ImGui::MenuItem("Preview", 0, &ui->ui_preview.open);
            ImGui::MenuItem("Data", 0, &ui->ui_data.open);
            ImGui::MenuItem("SID(MOS6581)", 0, &ui->ui_sid.open);
            ImGui::MenuItem("Audio", 0, &ui->ui_audio.open);
            ImGui::MenuItem("Help", 0, &ui->ui_help.open);
            ImGui::EndMenu();
        }
        ui_util_options_menu();
        ImGui::EndMainMenuBar();
    }
}

static const ui_chip_pin_t _ui_numbersid_sid_pins[] = {
    { "D0",     0,      M6581_D0 },
    { "D1",     1,      M6581_D1 },
    { "D2",     2,      M6581_D2 },
    { "D3",     3,      M6581_D3 },
    { "D4",     4,      M6581_D4 },
    { "D5",     5,      M6581_D5 },
    { "D6",     6,      M6581_D6 },
    { "D7",     7,      M6581_D7 },
    { "A0",     8,      M6581_A0 },
    { "A1",     9,      M6581_A1 },
    { "A2",     10,     M6581_A2 },
    { "A3",     11,     M6581_A3 },
    { "CS",     13,     M6581_CS },
    { "RW",     14,     M6581_RW }
};


void ui_numbersid_init(ui_numbersid_t* ui, const ui_numbersid_desc_t* ui_desc) {
    CHIPS_ASSERT(ui && ui_desc);
    CHIPS_ASSERT(ui_desc->sequencer);
    CHIPS_ASSERT(ui_desc->boot_cb);
    ui->sequencer = ui_desc->sequencer;
    ui->boot_cb = ui_desc->boot_cb;
    int x = 20, y = 20, dx = 10, dy = 10;
    {
        ui_m6581_desc_t desc = {0};
        desc.title = "MOS 6581 (SID)";
        desc.sid = ui->sequencer->sid;
        desc.x = x;
        desc.y = y;
        UI_CHIP_INIT_DESC(&desc.chip_desc, "6581", 16, _ui_numbersid_sid_pins);
        ui_m6581_init(&ui->ui_sid, &desc);
    }
    x += dx; y += dy;
    {
        ui_audio_desc_t desc = {0};
        desc.title = "Audio Output";
        desc.sample_buffer = ui_desc->audio_sample_buffer;
        desc.num_samples = ui_desc->audio_num_samples;
        desc.x = x;
        desc.y = y;
        ui_audio_init(&ui->ui_audio, &desc);
    }
    x += dx; y += dy;
    {
        ui_sequencer_desc_t desc = {0};
        desc.title = "Sequencer";
        desc.sequencer = ui_desc->sequencer;
        desc.x = x;
        desc.y = y;
        desc.w = 900;
        desc.h = 600;
        desc.open = true;
        ui_sequencer_init(&ui->ui_sequencer, &desc);
    }
    x += dx; y += dy;
    {
        ui_preview_desc_t desc = {0};
        desc.title = "Preview";
        desc.sequencer = ui_desc->sequencer;
        desc.x = x;
        desc.y = y;
        ui_preview_init(&ui->ui_preview, &desc);
    }
     x += dx; y += dy;
    {
        ui_data_desc_t desc = {0};
        desc.title = "Data";
        desc.sequencer = ui_desc->sequencer;
        desc.x = x;
        desc.y = y;
        ui_data_init(&ui->ui_data, &desc);
    }
    x += dx; y += dy;
    {
        ui_help_desc_t desc = {0};
        desc.title = "Help";
        desc.x = x;
        desc.y = y;
        desc.w = 600;
        desc.h = 900;
        desc.open = true;
        ui_help_init(&ui->ui_help, &desc);
    }
}

void ui_numbersid_discard(ui_numbersid_t* ui) {
    CHIPS_ASSERT(ui && ui->sequencer);
    ui_m6581_discard(&ui->ui_sid);
    ui_sequencer_discard(&ui->ui_sequencer);
    ui_preview_discard(&ui->ui_preview);
    ui_data_discard(&ui->ui_data);
    ui_help_discard(&ui->ui_help);
    ui_audio_discard(&ui->ui_audio);
    //ui->sequencer = 0;  // TODO??
}

void ui_numbersid_draw(ui_numbersid_t* ui) {
    CHIPS_ASSERT(ui && ui->sequencer);
    _ui_numbersid_draw_menu(ui);
    //ui_audio_draw(&ui->ui_audio, ui->audio.sample_pos);
    ui_audio_draw(&ui->ui_audio, 0);    // TODO, I don't have the sample_pos variable here. Add it to ui_numbersid...
    ui_m6581_draw(&ui->ui_sid);
    ui_sequencer_draw(&ui->ui_sequencer);
    ui_preview_draw(&ui->ui_preview);
    ui_data_draw(&ui->ui_data);
    ui_help_draw(&ui->ui_help);
}

chips_debug_t ui_numbersid_get_debug(ui_numbersid_t* ui) {
    CHIPS_ASSERT(ui);
    chips_debug_t res = {};
    return res;
}

void ui_numbersid_save_settings(ui_numbersid_t* ui, ui_settings_t* settings) {
    CHIPS_ASSERT(ui && settings);
    ui_m6581_save_settings(&ui->ui_sid, settings);
    ui_sequencer_save_settings(&ui->ui_sequencer, settings);
    ui_preview_save_settings(&ui->ui_preview, settings);
    ui_data_save_settings(&ui->ui_data, settings);
    ui_help_save_settings(&ui->ui_help, settings);
    ui_audio_save_settings(&ui->ui_audio, settings);
}

void ui_numbersid_load_settings(ui_numbersid_t* ui, const ui_settings_t* settings) {
    CHIPS_ASSERT(ui && settings);
    ui_m6581_load_settings(&ui->ui_sid, settings);
    ui_sequencer_load_settings(&ui->ui_sequencer, settings);
    ui_preview_load_settings(&ui->ui_preview, settings);
    ui_data_load_settings(&ui->ui_data, settings);
    ui_help_load_settings(&ui->ui_help, settings);
    ui_audio_load_settings(&ui->ui_audio, settings);
}
#ifdef __clang__
#pragma clang diagnostic pop
#endif
#endif /* CHIPS_UI_IMPL */

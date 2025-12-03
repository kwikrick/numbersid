/*
    Numbersid. 
    
    A number sequenced based sequencer for the SID.

    Application code. 

    Derived from https://github.com/floooh/chips-test

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
*/

#define CHIPS_IMPL
#include "chips/chips_common.h"
#include "chips/m6581.h"
#include "chips/clk.h"

#include "common.h"
#include "sequencer.h"

#include "ui.h"
#include "ui/ui_settings.h"
#include "ui/ui_chip.h"
#include "ui/ui_audio.h"
#include "ui/ui_display.h"
#include "ui/ui_m6581.h"

#include "ui_timecontrol.h"     // TODO: need all of these here?
#include "ui_parameters.h"
#include "ui_variables.h"
#include "ui_arrays.h"
#include "ui_preview.h"
#include "ui_help.h"
#include "ui_data.h"
#include "ui/ui_snapshot.h"
#include "ui_numbersid.h"

#include <stdlib.h>

// --------------

#define C64_FREQUENCY (985248)          // clock frequency in Hz; We'll be updating the SID as if in a C64
#define MAX_AUDIO_SAMPLES (1024)        // max number of audio samples in internal sample buffer
#define DEFAULT_AUDIO_SAMPLES (1024)    // default number of samples in internal sample buffer
                                        // Note: this is quite high, but we are only updating at 60PS = 800 samples/frame
#define FFT_BUFFER_SIZE 1024            // must be  a power of two 

#define FRAMEBUFFER_WIDTH 400
#define FRAMEBUFFER_HEIGHT 300
#define FRAMEBUFFER_SIZE_BYTES (FRAMEBUFFER_WIDTH * FRAMEBUFFER_HEIGHT)

typedef struct {
    chips_audio_callback_t callback;
    int num_samples;
    int sample_pos;
    float sample_buffer[MAX_AUDIO_SAMPLES];
} audio_t;

static struct {
    uint32_t frame_time_us;
    uint32_t ticks;
    double emu_time_ms;
    audio_t audio;
    uint64_t pins;
    m6581_t sid;
    sequencer_t sequencer;
    ui_numbersid_t ui;
    //alignas(64) 
    uint8_t framebuffer[FRAMEBUFFER_SIZE_BYTES];
    sequencer_snapshot_t snapshots[UI_SNAPSHOT_MAX_SLOTS];
    double fft_buffer[FFT_BUFFER_SIZE];
    size_t fft_pos;
} state;


static void ui_draw_cb(const ui_draw_info_t* draw_info);
static void ui_save_settings_cb(ui_settings_t* settings);
static void ui_boot_cb(sequencer_t* sequencer);
static void ui_save_snapshot(size_t slot_index);
static bool ui_load_snapshot(size_t slot_index);
static void ui_load_snapshots_from_storage(void);

// audio-streaming callback
static void push_audio(const float* samples, int num_samples, void* user_data) {
    (void)user_data;
    saudio_push(samples, num_samples);
}

// TODO: this GFX framebuffer/screen stuff, not really needed 
// for my app but I need the code. I should to figure out how to 
// get ImGUI in Sokol without using the Chips code.

#define BORDER_TOP (24)
#define BORDER_LEFT (8)
#define BORDER_RIGHT (8)
#define BORDER_BOTTOM (16)
#define LOAD_DELAY_FRAMES (180)

#define RGBA8(r,g,b) (0xFF000000|(b<<16)|(g<<8)|(r))

chips_range_t palette(void) {
    static uint32_t palette_[256];
    for (int i=0;i<256;++i) {
        int r = (i & 255);
        int g = (i & 127) << 1;
        int b = (i & 63) << 2;
        palette_[i] = RGBA8(r,g,b);
    }
    return (chips_range_t){
        .ptr = palette_,
        .size = sizeof(palette_)
    };
}
chips_display_info_t numbersid_display_info() {
    chips_display_info_t res = {
        .frame = {
            .dim = {
                .width = FRAMEBUFFER_WIDTH,
                .height = FRAMEBUFFER_HEIGHT,
            },
            .bytes_per_pixel = 1,
            .buffer = {
                .ptr = state.framebuffer,
                .size = FRAMEBUFFER_SIZE_BYTES,
            }
        },
        .palette = palette()
    };
   res.screen = (chips_rect_t){
            .x = 0,
            .y = 0,
            .width = FRAMEBUFFER_WIDTH,
            .height = FRAMEBUFFER_HEIGHT
        };
   return res;
}

void app_init(void) {
    saudio_setup(&(saudio_desc){
        //int sample_rate;        // requested sample rate
        //int num_channels;       // number of channels, default: 1 (mono)
        //int buffer_frames;      // number of frames in streaming buffer
        //int packet_frames;      // number of frames in a packet (for push model)
        //int num_packets;        // number of packets in packet queue (for push model)
        .sample_rate = 48000,       // note 48Khz / 60FPS  = 800 audio frames/video frame
        .packet_frames = 64,
        .num_packets = 64,          // 64x64 = 4096 samples =~ 0.085 secs delay or 5 video frames
        .buffer_frames = 512,       // must be larger than packet_frames, but <1024 (in browser at least)
        //.logger.func = slog_func,
    });

    state.audio.callback.func = push_audio;
    state.audio.num_samples = DEFAULT_AUDIO_SAMPLES;

    m6581_init(&state.sid, &(m6581_desc_t){
        .tick_hz = C64_FREQUENCY,
        .sound_hz = 48000,
        .magnitude = 1.0f,
    });
    
    sequencer_init(&state.sequencer);
    
    // TODO: GFX is intended to diplay a (retro machine's) framebuffer. 
    // I don't think I need it, but it also handles some setup for 
    // Sokol graphics and ImGui. It call ui_draw to draw the UI. 
    gfx_init(&(gfx_desc_t){
        .disable_speaker_icon = sargs_exists("disable-speaker-icon"),
        .draw_extra_cb = ui_draw,
        .border = {
            .left = BORDER_LEFT,
            .right = BORDER_RIGHT,
            .top = BORDER_TOP,
            .bottom = BORDER_BOTTOM,
        },
        .display_info = numbersid_display_info(),
    });

    clock_init();
    prof_init();
    fs_init();         
       
    ui_init(&(ui_desc_t){
        .draw_cb = ui_draw_cb,
        .save_settings_cb = ui_save_settings_cb,
        .imgui_ini_key = "kwikrick.numbersid",          // TODO: kwikrick.numbersid
    });
    ui_numbersid_init(&state.ui, &(ui_numbersid_desc_t){
        .sequencer = &state.sequencer,
        .sid = &state.sid,
        .boot_cb = ui_boot_cb,
        .audio_sample_buffer = state.audio.sample_buffer,
        .audio_num_samples = state.audio.num_samples,
        .snapshot = {
                .load_cb = ui_load_snapshot,
                .save_cb = ui_save_snapshot,
                .empty_slot_screenshot = {
                    .texture = ui_shared_empty_snapshot_texture(),
                },
            },
    });
    ui_numbersid_load_settings(&state.ui, ui_settings());
    ui_load_snapshots_from_storage();
}

// declare for use in app_frame
static void draw_status_bar(void);

uint32_t numbersid_exec(uint32_t micro_seconds) {
    
    uint32_t num_ticks = clk_us_to_ticks(C64_FREQUENCY, micro_seconds);
    uint64_t pins = state.pins;
    
    for (uint32_t ticks = 0; ticks < num_ticks; ticks++) {
        pins = m6581_tick(&state.sid, pins);
        if (pins & M6581_SAMPLE) {
            // new audio sample ready
            state.audio.sample_buffer[state.audio.sample_pos++] = state.sid.sample;
            if (state.audio.sample_pos == state.audio.num_samples) {
                if (state.audio.callback.func) {
                    state.audio.callback.func(state.audio.sample_buffer, state.audio.num_samples, state.audio.callback.user_data);
                }
                state.audio.sample_pos = 0;
            }
            // also store sample in FFT buffer
            {
                state.fft_buffer[state.fft_pos++] = state.sid.sample;
                if (state.fft_pos >= FFT_BUFFER_SIZE) {
                    state.fft_pos = 0;
                }
            }
        }
    }

    state.pins = pins;
    return num_ticks;
}

// TODO: move to a separate fft gfx file?

#include "lamefft.h"

void update_fft_framebuffer(uint8_t* framebuffer, chips_display_info_t info) 
{
    int w = info.frame.dim.width;
    int h = info.frame.dim.height;
    
    // each frame move right
    static int x = 0;
    x = (x+1)%w;

    // copy from buffer and apply Hanning window
    double fft[FFT_BUFFER_SIZE];
    for (int i=0;i<FFT_BUFFER_SIZE;i++) {
        int index = state.fft_pos + i - FFT_BUFFER_SIZE;
        if (index >= FFT_BUFFER_SIZE) index -= FFT_BUFFER_SIZE;
        if (index < 0) index += FFT_BUFFER_SIZE;
        // Apply Hann window
        double hann = 0.5 * (1.0 - cos(2.0 * M_PI * i / (FFT_BUFFER_SIZE - 1)));
        fft[i] = state.fft_buffer[index] * hann;
    }
    
    // compute FFT on current fft buffer
    C_FFT_real(fft,FFT_BUFFER_SIZE);

    // draw FFT result into framebuffer
    const int f_start = 2;
    const int f_end = FFT_BUFFER_SIZE / 8;
    for (int y=0;y<h;y++) {
        int f = (y*(f_end-f_start))/h + f_start;
        int color = 512*log(1+fft[f])/log(1+FFT_BUFFER_SIZE);
        if (color > 255) color = 255;
        int index = y*w+x;
        framebuffer[index] = color;
    }
}

void app_frame(void) {
    
    state.frame_time_us = clock_frame_time();
    const uint64_t emu_start_time = stm_now();

    sequencer_update(&state.sequencer);

    sequencer_update_sid(&state.sequencer, &state.sid);

    //sequencer_update_framebuffer(&state.sequencer, state.framebuffer, numbersid_display_info());

    state.ticks = numbersid_exec(state.frame_time_us);

    update_fft_framebuffer(state.framebuffer, numbersid_display_info());
    
    state.emu_time_ms = stm_ms(stm_since(emu_start_time));

    gfx_draw(numbersid_display_info());
    draw_status_bar();

    fs_dowork();    // should work for both fs and sfetch
}

void app_input(const sapp_event* event) {
    // accept dropped files also when ImGui grabs input
    // if (event->type == SAPP_EVENTTYPE_FILES_DROPPED) {
    //     fs_load_dropped_file_async(FS_CHANNEL_IMAGES);
    // }
    if (ui_input(event)) {
        // input was handled by UI
        return;
    }
}

void app_cleanup(void) {
    ui_numbersid_discard(&state.ui);
    ui_discard();
    saudio_shutdown();
    gfx_shutdown();
    sargs_shutdown();
}

static void draw_status_bar(void) {
    prof_push(PROF_EMU, (float)state.emu_time_ms);
    prof_stats_t emu_stats = prof_stats(PROF_EMU);
    const float w = sapp_widthf();
    const float h = sapp_heightf();
    sdtx_canvas(w, h);
    sdtx_color3b(255, 255, 255);
    sdtx_pos(1.0f, (h / 8.0f) - 1.5f);
    sdtx_printf("frame:%.2fms emu:%.2fms (min:%.2fms max:%.2fms) ticks:%d", (float)state.frame_time_us * 0.001f, emu_stats.avg_val, emu_stats.min_val, emu_stats.max_val, state.ticks);
}

static void ui_draw_cb(const ui_draw_info_t* draw_info) {
    ui_numbersid_draw(&state.ui, &draw_info->display);
}

static void ui_save_settings_cb(ui_settings_t* settings) {
    ui_numbersid_save_settings(&state.ui, settings);
}

static void ui_boot_cb(sequencer_t* sequencer) {
    clock_init();
    sequencer_init(sequencer);
}

static void ui_update_snapshot_screenshot(size_t slot) {
    chips_display_info_t screenshot_display_info = {
        .frame = {
            .dim = {
                .width = FRAMEBUFFER_WIDTH,
                .height = FRAMEBUFFER_HEIGHT,
            },
            .bytes_per_pixel = 1,
            .buffer = {
                .ptr = state.snapshots[slot].screenshot_data,
                .size = FRAMEBUFFER_SIZE_BYTES,
            }
        },
        .palette = palette(),
        .screen = (chips_rect_t){
            .x = 0,
            .y = 0,
            .width = FRAMEBUFFER_WIDTH,
            .height = FRAMEBUFFER_HEIGHT
        }
    };

    ui_snapshot_screenshot_t screenshot = {    
        .texture = ui_create_screenshot_texture(screenshot_display_info),
        .portrait = false,
    };
    ui_snapshot_screenshot_t prev_screenshot = ui_snapshot_set_screenshot(&state.ui.snapshot, slot, screenshot);
    if (prev_screenshot.texture) {
        ui_destroy_texture(prev_screenshot.texture);
    }
}

static void ui_save_snapshot(size_t slot) {
    if (slot < UI_SNAPSHOT_MAX_SLOTS) {
        state.snapshots[slot].version = sequencer_save_snapshot(&state.sequencer, &state.snapshots[slot].sequencer);
        memcpy(state.snapshots[slot].screenshot_data, state.framebuffer, SCREENSHOT_SIZE_BYTES);
        ui_update_snapshot_screenshot(slot);
        fs_save_snapshot("sequencer", slot, (chips_range_t){ .ptr = &state.snapshots[slot], sizeof(sequencer_snapshot_t) });
    }
}

static bool ui_load_snapshot(size_t slot) {
    bool success = false;
    if ((slot < UI_SNAPSHOT_MAX_SLOTS) && (state.ui.snapshot.slots[slot].valid)) {
        success = sequencer_load_snapshot(&state.sequencer, state.snapshots[slot].version, &state.snapshots[slot].sequencer);
    }
    return success;
}

static void ui_fetch_snapshot_callback(const fs_snapshot_response_t* response) {
    assert(response);
    if (response->result != FS_RESULT_SUCCESS) {
        return;
    }
    if (response->data.size != sizeof(sequencer_snapshot_t)) {
        return;
    }
    if (((sequencer_snapshot_t*)response->data.ptr)->version != SEQUENCER_SNAPSHOT_VERSION) {
        return;
    }
    size_t snapshot_slot = response->snapshot_index;
    assert(snapshot_slot < UI_SNAPSHOT_MAX_SLOTS);
    memcpy(&state.snapshots[snapshot_slot], response->data.ptr, response->data.size);
    ui_update_snapshot_screenshot(snapshot_slot);
}

static void ui_load_snapshots_from_storage(void) {
    for (size_t snapshot_slot = 0; snapshot_slot < UI_SNAPSHOT_MAX_SLOTS; snapshot_slot++) {
        fs_load_snapshot_async("sequencer", snapshot_slot, ui_fetch_snapshot_callback);
    }
}

// ----------------------

sapp_desc sokol_main(int argc, char* argv[]) {
    sargs_setup(&(sargs_desc){
        .argc=argc,
        .argv=argv,
        .buf_size = 512 * 1024,
    });
    return (sapp_desc) {
        .init_cb = app_init,
        .frame_cb = app_frame,
        .event_cb = app_input,
        .cleanup_cb = app_cleanup,
        .width = 1920,
        .height = 1080,
        .window_title = "NUMBERSID",
        .icon.sokol_default = true,
        .enable_dragndrop = true,
        .html5_bubble_mouse_events = true,
        .html5_update_document_title = true,
        .logger.func = slog_func,
        .enable_clipboard = true,
        .clipboard_size = 1024*64
    };
}

/*
    Numbersid. 
    
    A number sequenced based sequencer for the SID.

    Application code. 

    Derived from https://github.com/floooh/chips-test
*/

#define CHIPS_IMPL
#include "chips/chips_common.h"
#include "chips/m6581.h"
#include "chips/clk.h"
#include "common.h"
#include "sequencer.h"
#if defined(CHIPS_USE_UI)
    #define UI_DBG_USE_M6502
    #include "ui.h"
    #include "ui/ui_settings.h"
    #include "ui/ui_chip.h"
    #include "ui/ui_audio.h"
    #include "ui/ui_m6581.h"
    #include "ui_sequencer.h"
    #include "ui_preview.h"
    #include "ui_numbersid.h"
#endif
#include <stdlib.h>

// --------------


#define C64_FREQUENCY (985248)          // clock frequency in Hz; We'll be updating the SID as if in a C64
#define MAX_AUDIO_SAMPLES (1024)        // max number of audio samples in internal sample buffer
#define DEFAULT_AUDIO_SAMPLES (128)     // default number of samples in internal sample buffer
#define FRAMEBUFFER_WIDTH 400
#define FRAMEBUFFER_HEIGHT 300
#define FRAMEBUFFER_SIZE_BYTES (FRAMEBUFFER_WIDTH * FRAMEBUFFER_HEIGHT)

static struct {
    uint32_t frame_time_us;
    uint32_t ticks;
    double emu_time_ms;
    struct {
        chips_audio_callback_t callback;
        int num_samples;
        int sample_pos;
        float sample_buffer[MAX_AUDIO_SAMPLES];
    } audio;
    uint64_t pins;
    m6581_t sid;
    sequencer_t sequencer;
    #ifdef CHIPS_USE_UI
        ui_numbersid_t ui;
    #endif
    //alignas(64) 
    uint8_t framebuffer[FRAMEBUFFER_SIZE_BYTES];
} state;

#ifdef CHIPS_USE_UI
static void ui_draw_cb(const ui_draw_info_t* draw_info);
static void ui_save_settings_cb(ui_settings_t* settings);
static void ui_boot_cb(sequencer_t* sequencer);

// TODO: do we need these Web callbacks?
static void web_boot(void);
static void web_reset(void);
static bool web_ready(void);
static bool web_load(chips_range_t data);
static void web_input(const char* text);
static void web_dbg_connect(void);
static void web_dbg_disconnect(void);
static void web_dbg_add_breakpoint(uint16_t addr);
static void web_dbg_remove_breakpoint(uint16_t addr);
static void web_dbg_break(void);
static void web_dbg_continue(void);
static void web_dbg_step_next(void);
static void web_dbg_step_into(void);
static void web_dbg_on_stopped(int stop_reason, uint16_t addr);
static void web_dbg_on_continued(void);
static void web_dbg_on_reboot(void);
static void web_dbg_on_reset(void);
static webapi_cpu_state_t web_dbg_cpu_state(void);
static void web_dbg_request_disassemly(uint16_t addr, int offset_lines, int num_lines, webapi_dasm_line_t* result);
static void web_dbg_read_memory(uint16_t addr, int num_bytes, uint8_t* dst_ptr);


// audio-streaming callback
static void push_audio(const float* samples, int num_samples, void* user_data) {
    (void)user_data;
    saudio_push(samples, num_samples);
}


// TODO: this framebuffer stuff, not really needed for my app
// but I need to figure out how to get ImGUI in Sokol without 
// using the Chips code.


#define BORDER_TOP (24)
#else
#define BORDER_TOP (8)
#endif
#define BORDER_LEFT (8)
#define BORDER_RIGHT (8)
#define BORDER_BOTTOM (16)
#define LOAD_DELAY_FRAMES (180)

#define _M6569_RGBA8(r,g,b) (0xFF000000|(b<<16)|(g<<8)|(r))
/* https://www.pepto.de/projects/colorvic/ */
static const uint32_t _m6569_colors[16] = {
    _M6569_RGBA8(0x00,0x00,0x00),
    _M6569_RGBA8(0xff,0xff,0xff),
    _M6569_RGBA8(0x81,0x33,0x38),
    _M6569_RGBA8(0x75,0xce,0xc8),
    _M6569_RGBA8(0x8e,0x3c,0x97),
    _M6569_RGBA8(0x56,0xac,0x4d),
    _M6569_RGBA8(0x2e,0x2c,0x9b),
    _M6569_RGBA8(0xed,0xf1,0x71),
    _M6569_RGBA8(0x8e,0x50,0x29),
    _M6569_RGBA8(0x55,0x38,0x00),
    _M6569_RGBA8(0xc4,0x6c,0x71),
    _M6569_RGBA8(0x4a,0x4a,0x4a),
    _M6569_RGBA8(0x7b,0x7b,0x7b),
    _M6569_RGBA8(0xa9,0xff,0x9f),
    _M6569_RGBA8(0x70,0x6d,0xeb),
    _M6569_RGBA8(0xb2,0xb2,0xb2),
};
chips_range_t m6569_dbg_palette(void) {
    static uint32_t dbg_palette[256];
    size_t i = 0;
    for (; i < 16; i++) {
        dbg_palette[i] = _m6569_colors[i];
    }
    for (;i < 256; i++) {
        uint32_t c = ((_m6569_colors[i&0xF] >> 2) & 0xFF3F3F3F) | 0xFF000000;
        // bad line
        if (i & 0x10) {
            c |= 0x00FF0000;
        }
        // BA pin active
        if (i & 0x20) {
            c |= 0x000000FF;
        }
        // sprite active
        if (i & 0x40) {
            c |= 0x00880088;
        }
        // interrupt active
        if (i & 0x80) {
            c |= 0x0000FF00;
        }
        dbg_palette[i] = c;
    }
    return (chips_range_t){
        .ptr = dbg_palette,
        .size = sizeof(dbg_palette)
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
        .palette = m6569_dbg_palette(),
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
        //int packet_frames;      // number of frames in a packet
        //int num_packets;        // number of packets in packet queue
        .sample_rate = 44100,
        .packet_frames = 256,     // Rick: Seems to fix stuttering for me
        .logger.func = slog_func,
    });
    
    state.audio.callback.func = push_audio;
    state.audio.num_samples = DEFAULT_AUDIO_SAMPLES;

    m6581_init(&state.sid, &(m6581_desc_t){
        .tick_hz = C64_FREQUENCY,
        .sound_hz = 44100,
        .magnitude = 1.0f,
    });
    
    sequencer_init(&state.sequencer, &state.sid);
    
    // TODO: GFX is intended to diplay a (retro machine's) framebuffer. 
    // I don't think I need it, but it also handles some setup for 
    // Sokol graphics and ImGui. It call ui_draw to draw the UI. 
    gfx_init(&(gfx_desc_t){
        .disable_speaker_icon = sargs_exists("disable-speaker-icon"),
        #ifdef CHIPS_USE_UI
        .draw_extra_cb = ui_draw,
        #endif
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
    fs_init();          // needed? Maybe for UI settings? Maybe later for load/save sequence data.  
    #ifdef CHIPS_USE_UI
        ui_init(&(ui_desc_t){
            .draw_cb = ui_draw_cb,
            .save_settings_cb = ui_save_settings_cb,
            .imgui_ini_key = "floooh.chips.numbersid",
        });
        ui_numbersid_init(&state.ui, &(ui_numbersid_desc_t){
            .sequencer = &state.sequencer,          // TODO make and use a numbersid_t object?
            .boot_cb = ui_boot_cb,
        });
        ui_numbersid_load_settings(&state.ui, ui_settings());
        // // important: initialize webapi after ui
        // webapi_init(&(webapi_desc_t){
        //     .funcs = {
        //         .boot = web_boot,
        //         .reset = web_reset,
        //         .ready = web_ready,
        //         .load = web_load,
        //         .input = web_input,
        //         .dbg_connect = web_dbg_connect,
        //         .dbg_disconnect = web_dbg_disconnect,
        //         .dbg_add_breakpoint = web_dbg_add_breakpoint,
        //         .dbg_remove_breakpoint = web_dbg_remove_breakpoint,
        //         .dbg_break = web_dbg_break,
        //         .dbg_continue = web_dbg_continue,
        //         .dbg_step_next = web_dbg_step_next,
        //         .dbg_step_into = web_dbg_step_into,
        //         .dbg_cpu_state = web_dbg_cpu_state,
        //         .dbg_request_disassembly = web_dbg_request_disassemly,
        //         .dbg_read_memory = web_dbg_read_memory,
        //     }
        //});
    #endif
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
        }
    }

    state.pins = pins;
    return num_ticks;
}

void app_frame(void) {
    
    state.frame_time_us = clock_frame_time();
    const uint64_t emu_start_time = stm_now();

    update_sequencer(&state.sequencer);

    state.ticks = numbersid_exec(state.frame_time_us);
    
    state.emu_time_ms = stm_ms(stm_since(emu_start_time));

    gfx_draw(numbersid_display_info());
    draw_status_bar();
}

void app_input(const sapp_event* event) {
    // accept dropped files also when ImGui grabs input
    if (event->type == SAPP_EVENTTYPE_FILES_DROPPED) {
        fs_load_dropped_file_async(FS_CHANNEL_IMAGES);
    }
    #ifdef CHIPS_USE_UI
    if (ui_input(event)) {
        // input was handled by UI
        return;
    }
    #endif
}

void app_cleanup(void) {
    #ifdef CHIPS_USE_UI
        ui_numbersid_discard(&state.ui);
        ui_discard();
    #endif
    saudio_shutdown();
    gfx_shutdown();
    sargs_shutdown();
}

// static void send_keybuf_input(void) {

// }

// static void handle_file_loading(void) {
    
// }

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

#if defined(CHIPS_USE_UI)
static void ui_draw_cb(const ui_draw_info_t*) {
    ui_numbersid_draw(&state.ui);
}

static void ui_save_settings_cb(ui_settings_t* settings) {
    ui_numbersid_save_settings(&state.ui, settings);
}

static void ui_boot_cb(sequencer_t*) {
    clock_init();
    // TODO: need SID too. 
    // When is this called?
    //sequencer_init(seq);
}

static void ui_update_snapshot_screenshot(size_t) {
   
}

static void ui_save_snapshot(size_t) {
   
}

static bool ui_load_snapshot(size_t) {
    return false;
}

static void ui_fetch_snapshot_callback(const fs_snapshot_response_t*) {
    
}

static void ui_load_snapshots_from_storage(void) {
    
}

// webapi wrappers
static void web_boot(void) {
    // TODO: needed? When is this called?
    clock_init();
    //c64_desc_t desc = c64_desc(state.c64.joystick_type, state.c64.c1530.valid, state.c64.c1541.valid);
    //c64_init(&state.c64, &desc);
    //ui_dbg_reboot(&state.ui.dbg);
}

static void web_reset(void) {
    //c64_reset(&state.c64);
    //ui_dbg_reset(&state.ui.dbg);
}

static void web_dbg_connect(void) {
    gfx_disable_speaker_icon();
    //state.dbg.entry_addr = 0xFFFFFFFF;
    //state.dbg.exit_addr = 0xFFFFFFFF;
    //ui_dbg_external_debugger_connected(&state.ui.dbg);
}

static void web_dbg_disconnect(void) {
    //state.dbg.entry_addr = 0xFFFFFFFF;
    //state.dbg.exit_addr = 0xFFFFFFFF;
    //ui_dbg_external_debugger_disconnected(&state.ui.dbg);
}

static bool web_ready(void) {
    return clock_frame_count_60hz() > LOAD_DELAY_FRAMES;
}

static bool web_load(chips_range_t) {
    return false;
}

static void web_input(const char* text) {
    keybuf_put(text);
}

static void web_dbg_add_breakpoint(uint16_t) {
    //ui_dbg_add_breakpoint(&state.ui.dbg, addr);
}

static void web_dbg_remove_breakpoint(uint16_t) {
    //ui_dbg_remove_breakpoint(&state.ui.dbg, addr);
}

static void web_dbg_break(void) {
    //ui_dbg_break(&state.ui.dbg);
}

static void web_dbg_continue(void) {
    //ui_dbg_continue(&state.ui.dbg, false);
}

static void web_dbg_step_next(void) {
    //ui_dbg_step_next(&state.ui.dbg);
}

static void web_dbg_step_into(void) {
    //ui_dbg_step_into(&state.ui.dbg);
}

static void web_dbg_on_stopped(int, uint16_t addr) {
    // stopping on the entry or exit breakpoints always
    // overrides the incoming stop_reason
    int webapi_stop_reason = WEBAPI_STOPREASON_UNKNOWN;
    // if (state.dbg.entry_addr == state.c64.cpu.PC) {
    //     webapi_stop_reason = WEBAPI_STOPREASON_ENTRY;
    // } else if (state.dbg.exit_addr == state.c64.cpu.PC) {
    //     webapi_stop_reason = WEBAPI_STOPREASON_EXIT;
    // } else if (stop_reason == UI_DBG_STOP_REASON_BREAK) {
    //     webapi_stop_reason = WEBAPI_STOPREASON_BREAK;
    // } else if (stop_reason == UI_DBG_STOP_REASON_STEP) {
    //     webapi_stop_reason = WEBAPI_STOPREASON_STEP;
    // } else if (stop_reason == UI_DBG_STOP_REASON_BREAKPOINT) {
    //     webapi_stop_reason = WEBAPI_STOPREASON_BREAKPOINT;
    // }
    webapi_event_stopped(webapi_stop_reason, addr);
}

static void web_dbg_on_continued(void) {
    webapi_event_continued();
}

static void web_dbg_on_reboot(void) {
    webapi_event_reboot();
}

static void web_dbg_on_reset(void) {
    webapi_event_reset();
}

static webapi_cpu_state_t web_dbg_cpu_state(void) {
    // const m6502_t* cpu = &state.c64.cpu;
    // return (webapi_cpu_state_t){
    //     .items = {
    //         [WEBAPI_CPUSTATE_TYPE] = WEBAPI_CPUTYPE_6502,
    //         [WEBAPI_CPUSTATE_6502_A] = cpu->A,
    //         [WEBAPI_CPUSTATE_6502_X] = cpu->X,
    //         [WEBAPI_CPUSTATE_6502_Y] = cpu->Y,
    //         [WEBAPI_CPUSTATE_6502_S] = cpu->S,
    //         [WEBAPI_CPUSTATE_6502_P] = cpu->P,
    //         [WEBAPI_CPUSTATE_6502_PC] = cpu->PC,
    //     }
    // };
    return (webapi_cpu_state_t){};
}

static void web_dbg_request_disassemly(uint16_t, int, int, webapi_dasm_line_t*) {
   
}

static void web_dbg_read_memory(uint16_t, int, uint8_t*) {
    
}
#endif

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
        .width = 800,
        .height = 600,
        .window_title = "NUMBERSID",
        .icon.sokol_default = true,
        .enable_dragndrop = true,
        .html5_bubble_mouse_events = true,
        .html5_update_document_title = true,
        .logger.func = slog_func,
    };
}

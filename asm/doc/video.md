
# Ideas for video.

Things to control (parameters):

Low level:

- Sprite positions, colors, block pointers

- Sprite data blocks (63 bytes per sprite, 24x21 pixels)

- Screen character data (25x40 chars)

- Screen color data (24x40 values)

- Charset data (256 x 8 x 8 pixels)

- screen number

- charset number


Likely, more high level, parameterized, graphics routines are needed 
for interesting effects at a nice framerate. 

 - filling blocks

 - copying blocks

 - drawing lines

 - scaneline based effects 

 - sprite movement patterns (e.g based on sinus frequencies) 

---

Update/calculation time:

- Real-time, 60Hz (or less)

- Pre-calculated (before start of demo)

- Background calculated (as much as can do outside raster IRQ)

- Per scanline (very unlikely to be possible) 

There could be some variables that increment more frequently that 60Hz;

 - called multiple times per frame, e.g 2, 4, 8, 16x per frame
 - called in main loop, incrementing after all sequences are updated 

---

# Arcitecture

Architecture 1: NumberSidVic

Extension of NumberSid with the VIC chip.

We need to add the VIC, and also the C64 memory. 
Maybe also the logic for memory mapping (VIA?).
Looking the the code, we need pretty much the whole
c64 system. 


Architecture 2: Number64

Number64 is an number sequece editor with a c64 emulator. The emulator 
runs a program that controls the VIC and SID, using number sequences
as input. It's input is data that is filled
 by the editor by directly writing in the emulators memory, where
 a program reads the data.  

Number64c Editor (C/Sokol):
 - ui (c++/ImGui)
 - sequencer (C/Sokol)
 - c64 emulator (C/Sokol)
     - Number64.prg  (6502 machine code)
          - fixed code
          - data (initially empty)
 - symbol (labels)
     - variable values
     - sequences (operations on variables)
     - dependencies (of parameter on variables)
     - dirty states (of variables)
     - visibility states (of variables)

Number64.asm -> Number64.prg
                 -> symbols


Number64Demo.prg
    - fixed code (same as NumberSidVic.prg in editor)
    - data (filled)


Problems:
 - Errors and bottlenecks in c64 code will prevent editor from working too.
    Or maybe that's a good thing... see problems early. 
 - Sokol c64 debugger does not ready symbols for debugging; but since i need to 
    ready them anyway for my system, maybe I can add that to the debugger
 - Performance; cannot generate code in in this system; well, not so easily.
 - The c64 code may need to pre-geneate frames, so changes in editor may
      show up only after some time. 
       
---

Architecture 3:

Just use python to generate code from formulas. 
No interactive editor.
Or semi interactive; Make editor in python, press key to run compile and run in Vice.

Advantage: 
 - less coding work than editor?
 - perhaps can do more complex formulas and analysis to generate optimal sequences 
 - sound and video though vice will be more accurate than via floops/chips. 
Disadvantge:
 - finding interesting sequecnes may be more difficult
 - Less interesting to show off? No web version. Just for the demo. 

---

# Possible NumberSid/Vic Data structures

typedef struct { 
    var_or_number_t visible;
    var_or_number_t x;
    var_or_number_t y;
    var_or_number_t color;
    var_or_number_t multicolor_mode;
    var_or_number_t expand_horizontal;
    var_or_number_t expand_vertical;
    var_or_number_t data_block_nr;
} sprite_t;

typedef struct {
    var_or_number_t border_color;
    var_or_number_t background_color0;
    var_or_number_t background_color1;
    var_or_number_t background_color2;
    var_or_number_t background_color3;
    var_or_number_t sprite_multicolor_0;
    var_or_number_t sprite_multicolor_1;   
} color_t;

typedef uint16_t bit_mode_t;
typedef uint16_t draw_mode_t;

typedef struct {
    draw_mode_t draw_mode;
                // before start of demo
                // when draw variable is true
                // continuously (fast chaging variable)
                // when x or y variables change
                // when pixel variable change
                // when all variables changed
                // 
                
    bit_mode_t bit_mode;              // how to map 16 integer bits to sprite bits
                // 1 bit monochrome
                // 2 bit multicolor
                // 16 monochrome pixels horizontal
                // 16 monochrome pixels vertical
                // 4x4 bits monochrome
                // 8x2 bits monochrome
                // 2x8 bits monochrome
                // 8 multicolor pixels horizontal
                // 8 multicolor pixels vertical
                // 2x4 multicolor pixels
                // 4x2 multicolor pixels
                // repeated over x (without changing vaiable x)
                // repeated over y (without changing vaiable x)

                
    var_or_number_t draw;         // draw only when 1 
    var_or_number_t x;            // range [0-24]
    var_or_number_t y;            // range [0-21]
    var_or_number_t pixel;        // pixel bits
    
} sprite_block_t;


#define MAX_SPRITES          7
#define MAX_SPRITE_BLOCKS   16

typedef struct {
    color_t colors;
    sprite_t sprites[MAX_SPRITES];
    sprite_block_t sprite_blocks[MAX_SPRITE_BLOCKS];
    // TODO: screen data, charset data, screen color data
} video_t;

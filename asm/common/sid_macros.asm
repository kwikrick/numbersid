//---------------------------------------------------------
// SID Play Macros
//---------------------------------------------------------

#import "common/sid_const.asm"

// Usage:
// .var music1 = LoadSid(Filename)
// PrintSid(music1) 
// WriteSid(music1)
// *=....
// start of your code...
// StartSidPlayer(music1, irq)
// somewhere your code...
// irq: SidIrqHandler() 


// Writes the music data at the memory location specified in the sid file.  
// Note: you'll probably want to specify a new memory adress (*=$xxxx) after this. 
.macro WriteSid(music) 
{
        *=music.location "Music"
        .fill music.size, music.getData(i)
}
		
// Print the music info while assembling
.macro PrintSid(music)
{
		.print ""
		.print "SID Data"
		.print "--------"
		.print "location=$"+toHexString(music.location)
		.print "init=$"+toHexString(music.init)
		.print "play=$"+toHexString(music.play)
		.print "songs="+music.songs
		.print "startSong="+music.startSong
		.print "size=$"+toHexString(music.size)
		.print "name="+music.name
		.print "author="+music.author
		.print "copyright="+music.copyright
		
		.print ""
		.print "Additional tech data"
		.print "--------------------"
		.print "header="+music.header
		.print "header version="+music.version
		.print "flags="+toBinaryString(music.flags)
		.print "speed="+toBinaryString(music.speed)
		.print "startpage="+music.startpage
		.print "pagelength="+music.pagelength
}

// Setup the Sid player: calls music.init, installs IRQ handler 
// on given raster line 
// and enabled interrupts to start playing
 
.macro StartSidPlayer(music, irq, rasterline)
{
        ldx #0
        ldy #0
        lda #music.startSong-1		// music init takes A for song number, X,Y for?
        jsr music.init
        sei							// disable interrups
        lda #<irq
        sta $0314					// set IRQ low byte
        lda #>irq
        sta $0315					// set IRQ high byte
        asl $d019					// clear VIC-II interrupt flags ?
        lda #$7b					
        sta $dc0d					// CIA 1 interrupt control register, start timer A?
        lda #$81
        sta $d01a					// VIC-II raster scan interupt enable
        lda #$1b
        sta $d011					// VIC-II show screen, 25 rows, normal vertical position 
        lda #rasterline    					// raster line for interupt
        sta $d012					// VIC-II set raster lien for for interupt 
        cli							// enable interrupts        
}

// code for the SID Irq Handler
// Note: the current IRQ handler (inside this macro) does not call
// the default handler at the end, so normal keyboard handdling is disabled. 
// it calls rti, so we can't conintue this handler either.

.macro SidIrqHandler(music)
{
        asl $d019					// clear VIC-II raster scan interrupt flag?
        //inc $d020					// next border color
        jsr music.play 
        //dec $d020					// previous border color
        pla							
        tay							// 1 byte from stack to Y
        pla
        tax                         // 1 byte from stack to X
        pla							// 1 byte from stack to A
        rti                         
}


// clear all writeable sid registers (0-24) with value 0
.macro SidReset()
{
	ldy #24
loop:
	lda #0
	sta SID_BASE,y
	dey
	bne loop
}

// set volume (can be value with # or byte adress)
// range 0-15
// Note: clears filter type!!
.macro SidSetVolumeConst(volume)
{
	lda #volume	
	and #$F
	sta SID_BASE + SID_FILTER_VOLUME
}	
		


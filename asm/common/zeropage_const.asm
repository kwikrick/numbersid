// zero page constants (& page 1, 2, 3)

#importonce

.const NDX          = $C6           // num keys in buffer
.const LSTX			= $C5			// maxtrix code of last key pressed (during last keyboard scan). $40 means no key pressed
.const ZP_FREE      = $FB           // start of free space in zero-page 
.const ZP_FREE1     = $FB           // start of free space in zero-page 
.const ZP_FREE2     = $FC           // 
.const ZP_FREE3     = $FD           // 
.const ZP_FREE4     = $FE           //  
.const ZP_FREE5     = $FF           //  



// and other (low memory) variables used by basic/kernal

.const HIBASE       = $288				// high byte of screen adress (adress/256). Used by basic / kernal print routines	

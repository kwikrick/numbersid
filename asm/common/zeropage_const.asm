// zero page constants (& page 1, 2, 3)

#importonce

.const IO_DDR      = $00			// IO data direction register; bits 0,1,2 control data direction to PLA
									//   set to 1 (default), allows program to write the PLA lines with DCR ($01)
									//   set to 0, processor will not control the PLA lines 
.const IO_DATA		= $01			// IO data register; bits 0,1,2 are PLA control data lines CHAREN, LORAM, HIRAM
.const IO_MASK_LORAM = $1    		//   LORAM (bit 0); region $A000-BFFF; set to 1 for BASIC ROM, set to 0 for RAM
.const IO_MASK_HIRAM = $2    		//   HIRAM (bit 1); region $F000-FFFF; set to 1 for KERNAL ROM; set to 0 for RAM
.const IO_MASK_CHAREN = $4    		//   CHAREN (bit 2); region $D000-DFFF;  set to 1 for IO, set to 0 for character set ROM  
									// bits 3-5 control casette

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

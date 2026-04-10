// constants used for the screen in default configuration 
// i.e. VIC chip using bank 0 and screen at $0400

#importonce

.const SCREEN       = $0400         // default screen pos
.const SPRBLK       = SCREEN+1016   // sprite blocks: 8 bytes, 1 byte per sprite, value is 64 byte increment from VIC bank start adress
.const COLRAM       = $D800

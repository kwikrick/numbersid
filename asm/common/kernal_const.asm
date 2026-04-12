// adresses of some much used kernal routines

#importonce

// kernal rom routines

.const GETKBC       = $E5B4         // kernal routine get next char from buffer (which must not be empty!), return in A 
.const PRT          = $E716         // kernal routine to print a character in A to screen, supporting control codes

// kernal jump table

.const GETIN        = $FFE4         // kernal routine to get a character from current input device 
                                    // reullt in A. 0 means no char available. Affacts A,X,Y,Flags. 

.const CHROUT       = $FFD2         // kernal routine to print a character in A to current output device (screen, printer, etc.)
                                    // Note: does not affect A,X,Y registers. Error status in byte $90.
                                    // This vector jumps to adress in $0326, hwich is typically $F1CA. 

.const PLOT         = $FFF0         // If Carry is clear: set cursor postion from register X (row = $D6) and register Y (column = $D3). 
                                    // If Carry is set, load $D6 into X and $D3 into Y register. 





#importonce

.macro StableRaster()
{

//«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»
// Raster Stabilizing Code
//«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»«»
    // A Raster Compare IRQ is triggered on cycle 0 on the current $d012 line
    // The MPU needs to finish it's current OP code before starting the Interrupt Handler,
    // meaning a 0 -> 7 cycles delay depending on OP code.
    // Then a 7 cycle delay is spendt invoking the Interrupt Handler (Push SR/PC to stack++)
    // Then 13 cycles for storing registers (pha, txa, pha, tya, pha)

    // CYCLECOUNT: [20 -> 27] cycles after Raster IRQ occurred.

    // Set up Wedge IRQ vector
    lda #<WedgeIRQ
    sta $fffe
    lda #>WedgeIRQ
    sta $ffff

    // Set the Raster IRQ to trigger on the next Raster line
    inc $d012

    // Acknowlege current Raster IRQ
    lda #$01
    sta $d019

    // Store current Stack Pointer (will be messed up when the next IRQ occurs)
    tsx

    // Allow IRQ to happen (Remeber the Interupt flag is set by the Interrupt Handler).
    cli

    // Execute NOPs untill the raster line changes and the Raster IRQ triggers
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    nop
    // Add one extra nop for 65 cycle NTSC machines

    // CYCLECOUNT: [64 -> 71]

WedgeIRQ:
    // At this point the next Raster Compare IRQ has triggered and the jitter is max 1 cycle.
    // CYCLECOUNT: [7 -> 8] (7 cycles for the interrupt handler + [0 -> 1] cycle Jitter for the NOP)

    // Restore previous Stack Pointer (ignore the last Stack Manipulation by the IRQ)
    txs

    // PAL-63  // NTSC-64    // NTSC-65
    //---------//------------//-----------
    ldx #$08   // ldx #$08   // ldx #$09
    dex        // dex        // dex
    bne *-1    // bne *-1    // bne *-1
    bit $00    // nop
               // nop

    // Check if $d012 is incremented and rectify with an aditional cycle if neccessary
    lda $d012
    cmp $d012  // <- critical instruction (ZERO-Flag will indicate if Jitter = 0 or 1)

    // CYCLECOUNT: [61 -> 62] <- Will not work if this timing is wrong

    // cmp $d012 is originally a 5 cycle instruction but due to piplining tech. the
    // 5th cycle responsible for calculating the result is executed simultaniously
    // with the next OP fetch cycle (first cycle of beq *+2).

    // Add one cycle if $d012 wasn't incremented (Jitter / ZERO-Flag = 0)
    beq *+2

    // Stable code    
 }

// 
// Possible way to use in a IRQ handler:
// 
//IRQ_Begin:
//    pha
//    txa
//    pha
//    tya
//    pha
//    :STABILIZE
//    
//    // ..xxXX[Stable Code]XXxx..
//    
//    lda #<IRQ_Begin
//    sta $fffe
//    lda #>IRQ_Begin
//    sta $ffff
//    lda #raster_line
//    sta #d012
//    lda #$01
//    sta $d019
//    pla
//    tay
//    pla
//    tax
//    pla
//    rti
// }  
// 
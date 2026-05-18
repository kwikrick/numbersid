#importonce 

// ----- with kernal
// leaves $FFFE/FFFE intact
// but updates $0315/$0315


.macro InstallRasterIRQ_WithKernal(irqhandler, rasterline)
{
        sei							// disable interrups
        lda #<irqhandler
        sta $0314					// set IRQ low byte
        lda #>irqhandler
        sta $0315					// set IRQ high byte
        asl $d019					// clear VIC-II interrupt flags ?
        lda #$7b					
        sta $dc0d					// CIA 1 interrupt control register, clear all interrupt masks
        lda #$81
        sta $d01a					// VIC-II raster scan interupt enable
        lda #$1b
        sta $d011					// VIC-II show screen, 25 rows, normal vertical position 
        lda #rasterline    					// raster line for interupt
        sta $d012					// VIC-II set raster line for for interupt 
        cli							// enable interrupts        
}

.macro RestoreRasterIRQ_WithKernal()
{
		sei
	
    	lda #0
    	sta $d01a					// disable all vic interrupts
    
    	// install default IRQ handler
    	.const default_irq_handler = $EA31
    	lda #<default_irq_handler
		sta $0314					// set IRQ low byte
		lda #>default_irq_handler
		sta $0315					// set IRQ high byte
		
		// set cia interrupt enable for timer A
		lda #129
		sta $dc0d			// CIA 1 ICR
		
		cli
}


.macro RasterIRQBegin_WithKernal()
{
		// acknowledge raster irq
		lda #$01
		sta $d019
}


.macro RasterIRQEnd_WithKernal()
{
		// POP Y,X,A and return from interrupt
		pla
		tay
		pla
		tax
		pla		
		rti
}

.macro RasterIRQDefault_WithKernal()
{
		// jump to default interrupt handler (for keyboard handling)
		jmp $EA31
}

.macro RasterIRQNext_WithKernal(irq_handler, irq_rasterline)
{
		lda #<irq_handler
        sta $0314					// set IRQ low byte
        lda #>irq_handler
        sta $0315					// set IRQ high byte
        
        lda #irq_rasterline    			
        sta $d012					// VIC-II set raster lien for for interupt 
        
		RasterIRQEnd_WithKernal()
}


// without kernal
// replaces $FFFE/FFFF

.macro InstallRasterIRQ_NoKernal(irq_handler, irq_rasterline)
{
		// set IRQ on vector used by processor, skip normal irq handler
		// note that we write to RAM here, but processor still sees kernal ROM
		sei
		lda #<irq_handler
		sta $FFFE					
		lda #>irq_handler
		sta $FFFF			
		
		// switch off KERNAL ROM
		lda #%111
		sta 0		// set data direction to 1 for tree lines CHAREN,HIRAM,LORAM 
		
		lda 1
		and #~%111		
		ora #%101				// set 101 for CHRAREN, HIRAM, LORAM
		sta 1		
		
		// disable all IRQs from CIA1 and CIA2
		lda #127					// bit 0 low means clear all interupts for which other bits are high
		sta $dc0d
		// sta CIA2_ICR
		
		// setup raster IRQ 
		asl $d019					// clear VIC-II interrupt flags?		
		lda #$81
		sta $d01a					// VIC-II raster scan interupt enable
		lda #irq_rasterline			
		sta $d012					// VIC-II set raster line for for interupt 	
		lda $d011
		and #$7F					// clear raster line high bit 							
		sta $d011
		
		// go
		cli
}

.macro RasterIRQBegin_NoKernal()
{
		// push A,X,Y	 			
		pha
		txa
		pha
		tya
		pha
		
		// acknowledge raster irq
		lda #$01
		sta $d019
}

		

.macro RasterIRQEnd_NoKernal()
{		
		// POP Y,X,A and return from interrupt
		pla
		tay
		pla
		tax
		pla		
		rti
}

.macro RasterIRQNext_NoKernal(next_irq_handler, next_irq_rasterline)
{
		// set irq rasterline 
		lda #next_irq_rasterline
		sta $d012
		
		// setup next IRQ		
		lda #<next_irq_handler
		sta $fffe
		lda #>next_irq_handler
		sta $ffff
		
		RasterIRQEnd_NoKernal()
}
	

#importonce 

// Note: don't use ZP_FREE in the IRQ handlers; numbersid will use those on main thread
// and numbersid will also use zero page up to $11 (currently).
// need 4 bytes for scroll irq handler, 6 for sinebob irq (and zero for numbersid irq currently)

.const ZP_IRQ = $16		
.const ZP_IRQ1 = $16
.const ZP_IRQ2 = $17
.const ZP_IRQ3 = $18
.const ZP_IRQ4 = $19
.const ZP_IRQ5 = $20
.const ZP_IRQ6 = $21



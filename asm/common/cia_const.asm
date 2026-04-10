// CIA registers

#importonce

// CIA1: used for reading keyboard, joystick, paddles, tape,  

.const CIA1_PORT_A			= $DC00		// port A. keyboard columns, write. Joystick 2, read. Paddles.  
.const CIA1_PORT_B			= $DC01		// port B. keyboard rows, read, joystick 1, read. Paddles. 
.const CIA1_DDR_A			= $DC02		// data direction register A (typically 255)
.const CIA1_DDR_B			= $DC03		// data direction register B (typically 0)
.const CIA1_TIMER_A_L		= $DC04		// timer A low byte, IRQ rate for keyboard, tape & serial port
.const CIA1_TIMER_A_H		= $DC05     // timer A high byte, IRQ rate for keyboard, tape & serial port
.const CIA1_TIMER_B_L		= $DC06		// timer B low byte,  used by tape & serial port
.const CIA1_TIMER_B_H		= $DC07		// timer B high byyte, used by tape & serial port
.const CIA1_TOD_TENTH		= $DC08		// not connected  
.const CIA1_TOD_SEC			= $DC09		// not connected 
.const CIA1_TOD_MIN			= $DC0A		// not connected 
.const CIA1_TOD_HOUR		= $DC0B		// not onnected
.const CIA1_SERIAL			= $DC0C		// serial port data shift register (connected to user port)
.const CIA1_ICR				= $DC0D		// interrupt control register (bit 0 & 1 = flags for timer A en B interrupt)
.const CIA1_TCRA			= $DC0E		// timer control register A (bit 0 = TA start)
.const CIA1_TCRB			= $DC0F		// timer control register B (bit 0 = TB start)


// CIA 2: controls Vic-II bank, non-maskalble interrupts, serial user port, RS-232, time of day. 

.const CIA2_PORT_A			= $DD00		// port A. Controls VIC_-II bank, Serial bus and RS-232 
											//	bits 0 and 1 control VIC-II bank, bit inverted (00=bank 3, 11=bank 0)
.const CIA2_PORT_B			= $DD01		// port B. Controls user port and rs232
.const CIA2_DDR_A			= $DD02		// data direction register A (typically 63)
.const CIA2_DDR_B			= $DD03		// data direction register B (typically 0)
.const CIA2_TIMER_A_L		= $DD04		// timer A low byte,  used by RS-232 OUT
.const CIA2_TIMER_A_H		= $DD05     // timer A high byte, used by RS-232 OUT
.const CIA2_TIMER_B_L		= $DD06		// timer B low byte,  used by RS-232 IN
.const CIA2_TIMER_B_H		= $DD07		// timer B high byyte, used by RS-232 IN
.const CIA2_TOD_TENTH		= $DD08		// time of day, tenth of seconds, BCD (low nybble values 0-9)  
.const CIA2_TOD_SEC			= $DD09		// time of day, seconds, BCD (low nybble 0-9, high nybble 0-5) 
.const CIA2_TOD_MIN			= $DD0A		// time of day, minutes, BCD (low nybble 0-9, high nybble 0-5) 
.const CIA2_TOD_HOUR		= $DD0B		// time of day, minutes, BCD (low nybble 0-9 or 0-2, bit 4 = digit 0 or 1, bit7=0(AM) or 1(PM))
.const CIA2_SERIAL			= $DD0C		// serial port data shift register (connected to user port)
.const CIA2_ICR				= $DD0D		// interrupt control register (used by RS-232)
.const CIA2_TCRA			= $DD0E		// timer control register A
.const CIA2_TCRB			= $DD0F		// timer control register B 



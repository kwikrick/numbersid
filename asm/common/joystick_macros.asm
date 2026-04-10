// joystick constants

#importonce

.const JOY_1 = $DC01
.const JOY_2 = $DC00

.const JOY_UP     	= 1;
.const JOY_DOWN     = 2;
.const JOY_LEFT     = 4;
.const JOY_RIGHT    = 8;
.const JOY_FIRE     = 16;

// loads joystick register in A, and ANDs with direction, so Z is set if direction matches.
// Affects: A, flags
// Call example: 
//    Compare_Joystick(JOY_2, JOY_UP)
//    beq do_up

.macro Compare_Joystick(joystick, direction) 
{
    lda joystick
    and #direction
}

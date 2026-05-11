// data for numbersid

/*
# freq table
def note_freq(base, semitones):
    return base*pow(2, semitones/12)
 

# for SID
def sid_value_pal(freq):
    return int(freq * 17.0309)

# SID freq table
#  with semitone 0 at base 440, +37 is the max (<65536). Low end usefulness?
for semitone in range(38-64,38):
    f=note_freq(440,semitone)
    print("{0}\t{1}\t{2}".format(semitone, f, sid_value_pal(f)))  
*/

.function note_freq(base, semitone)
{
	.return base * pow(2, semitone/12)
}

.function sid_freq_pal(freq) {
    // note: 16.40426  for NTSC
	.return floor(freq * 17.034) 
}

.for (var i=0;i<FREQ_TABLE_LENGTH;i++) {
	.var f = sid_freq_pal(note_freq(440, i+LOWEST_SEMITONE))
	//.print f
}

// table with SID frequency register values. Index 0 is the lowest semitone, and middle C (440HZ) is at index 0+lowest_semitone 

freq_table:
.fillword FREQ_TABLE_LENGTH, sid_freq_pal(note_freq(440, i+LOWEST_SEMITONE))



from itertools import count
import os
import sys


def read_line_stripped(file):
    line = file.readline()
    parts = line.split('//')
    return parts[0].strip()


class Varonum:
    def __init__(self, variable: int, number:int):
        self.variable = variable    # variable index, 0 if it's a number
        self.number = number        # an integer

    @staticmethod
    def parse(s):
        # parse string of the form "variable=number" or "number"
        # if input string first char is a non-digit, then it's a variable, otherwise it's a number
        s = s.strip()
        if len(s) == 0:
            return Varonum(0, 0)
        if s[0].isdigit():
            return Varonum(0, int(s))  
        else:
            return Varonum(ord(s[0]),0)

    def __str__(self):
        if self.variable != 0:
            return f"{chr(self.variable)}"
        else:
            return f"{self.number}"

class Voice:
    def __init__(self):
        self.gate = None
        self.note = None
        self.scale = None
        self.transpose = None
        self.pitch = None
        self.waveform = None
        self.pulsewidth = None
        self.ring = None
        self.sync = None
        self.attack = None
        self.decay = None
        self.sustain = None
        self.release = None
        self.filter = None

    @staticmethod
    def read_from(input_file):
        voice = Voice()
        voice.gate = Varonum.parse(read_line_stripped(input_file))
        voice.note = Varonum.parse(read_line_stripped(input_file))
        voice.scale = Varonum.parse(read_line_stripped(input_file))
        voice.transpose = Varonum.parse(read_line_stripped(input_file))
        voice.pitch = Varonum.parse(read_line_stripped(input_file))
        voice.waveform = Varonum.parse(read_line_stripped(input_file))
        voice.pulsewidth = Varonum.parse(read_line_stripped(input_file))
        voice.ring = Varonum.parse(read_line_stripped(input_file))
        voice.sync = Varonum.parse(read_line_stripped(input_file))
        voice.attack = Varonum.parse(read_line_stripped(input_file))
        voice.decay = Varonum.parse(read_line_stripped(input_file))
        voice.sustain = Varonum.parse(read_line_stripped(input_file))
        voice.release = Varonum.parse(read_line_stripped(input_file))
        voice.filter = Varonum.parse(read_line_stripped(input_file))
        return voice

    def __str__(self):
        s = "Voice {\n"
        s += f"  gate: {self.gate}\n"
        s += f"  note: {self.note}\n"
        s += f"  scale: {self.scale}\n"
        s += f"  transpose: {self.transpose}\n"
        s += f"  pitch: {self.pitch}\n"
        s += f"  waveform: {self.waveform}\n"
        s += f"  pulsewidth: {self.pulsewidth}\n"
        s += f"  ring: {self.ring}\n"
        s += f"  sync: {self.sync}\n"
        s += f"  attack: {self.attack}\n"
        s += f"  decay: {self.decay}\n"
        s += f"  sustain: {self.sustain}\n"
        s += f"  release: {self.release}\n"
        s += f"  filter: {self.filter}\n"
        s += "}"
        return s



class Sequence:
    def __init__(self):
        self.variable = None
        self.count = None
        self.add1 = None
        self.div1 = None
        self.mul1 = None
        self.mod1 = None
        self.base = None
        self.mod2 = None
        self.mul2 = None
        self.div2 = None
        self.add2 = None
        self.array = None
        
    @staticmethod
    def read_from(input_file):
        seq = Sequence()
        var_or_zero = read_line_stripped(input_file)
        if var_or_zero == "0":
            seq.variable = 0
        else:
            seq.variable = ord(var_or_zero[0])
        seq.count = Varonum.parse(read_line_stripped(input_file))
        seq.add1 = Varonum.parse(read_line_stripped(input_file))
        seq.div1 = Varonum.parse(read_line_stripped(input_file))
        seq.mul1 = Varonum.parse(read_line_stripped(input_file))
        seq.mod1 = Varonum.parse(read_line_stripped(input_file))
        seq.base = Varonum.parse(read_line_stripped(input_file))
        seq.mod2 = Varonum.parse(read_line_stripped(input_file))
        seq.mul2 = Varonum.parse(read_line_stripped(input_file))
        seq.div2 = Varonum.parse(read_line_stripped(input_file))
        seq.add2 = Varonum.parse(read_line_stripped(input_file))
        seq.array = Varonum.parse(read_line_stripped(input_file))
        return seq

    def __str__(self):
        s = "Sequence {\n"
        s += f"  variable: {chr(self.variable)}\n"
        s += f"  count: {self.count}\n"
        s += f"  add1: {self.add1}\n"
        s += f"  div1: {self.div1}\n"
        s += f"  mul1: {self.mul1}\n"
        s += f"  mod1: {self.mod1}\n"
        s += f"  base: {self.base}\n"
        s += f"  mod2: {self.mod2}\n"
        s += f"  mul2: {self.mul2}\n"
        s += f"  div2: {self.div2}\n"
        s += f"  add2: {self.add2}\n"
        s += f"  array: {self.array}\n"
        s += "}"
        return s


class Array:
    def __init__(self):
        self.varonums = []

    @staticmethod
    def read_from(input_file):
        arr = Array()
        size = int(read_line_stripped(input_file))
        for i in range(size):
             value = Varonum.parse(read_line_stripped(input_file))
             arr.varonums.append(value)
        return arr

    def __str__(self):
        s = "Array {\n"
        for i, varonum in enumerate(self.varonums):
            s += f"  [{i}]: {varonum}\n"
        s += "}"
        return s


class NumberSidData:
    def __init__(self):
        self.voices = []
        self.channel_voices = []
        filter_mode = None
        self.cutoff = None
        self.resonance = None
        self.volume = None
        self.sequences = []
        self.arrays = []

    def __str__(self):
        s = "NumberSidData\n"
        s += f"{len(self.voices)} voices\n"
        for i, voice in enumerate(self.voices):
            s += f"voice {i}: {voice}\n"
        s += "channel voices:\n"
        for i, channel_voice in enumerate(self.channel_voices):
            s += f"  channel {i}: {channel_voice}\n"
        s += f"filter mode: {self.filter_mode}\n"
        s += f"cutoff: {self.cutoff}\n"
        s += f"resonance: {self.resonance}\n"
        s += f"volume: {self.volume}\n"
        s += f"{len(self.sequences)} sequences\n"
        for i, seq in enumerate(self.sequences):
            s += f"sequence {i}: {seq}\n"
        s += f"{len(self.arrays)} arrays\n"
        for i, arr in enumerate(self.arrays):
            s += f"array {i}: {arr}\n"
        return s

    @staticmethod
    def read_from(input_file):
        data = NumberSidData()
        #voices
        numvoices = int(read_line_stripped(input_file))
        for i in range(numvoices):
            voice = Voice.read_from(input_file)
            data.voices.append(voice)
        # channel voices   
        for i in range(3):
            channel_voice = Varonum.parse(read_line_stripped(input_file))
            data.channel_voices.append(channel_voice)
        # filter volume
        data.filter_mode = Varonum.parse(read_line_stripped(input_file))
        data.cutoff = Varonum.parse(read_line_stripped(input_file))
        data.resonance = Varonum.parse(read_line_stripped(input_file))
        data.volume = Varonum.parse(read_line_stripped(input_file))
        # sequences
        num_sequences = int(read_line_stripped(input_file))
        for i in range(num_sequences):
            seq = Sequence.read_from(input_file)
            data.sequences.append(seq)
        # arrays        
        num_arrays = int(read_line_stripped(input_file))
        for i in range(num_arrays):
            arr = Array.read_from(input_file)
            data.arrays.append(arr)
        return data

def generate(data: NumberSidData) -> str:
    return "// generated code\n"

def main():
    if len(sys.argv) != 3:
        print("Usage: generate.py <input_file> <output_file>")
        return

    input_file_name = sys.argv[1]
    output_file_name = sys.argv[2]

    if not os.path.exists(input_file_name):
        print(f"Input file {input_file_name} does not exist.")
        return
    
    input_file = open(input_file_name, 'r')
    output_file = open(output_file_name, 'w')
    
    data = NumberSidData.read_from(input_file)

    print(data)


    code = generate(data)
    

    output_file.write(code)
    input_file.close()
    output_file.close()


if __name__ == "__main__":
     main()

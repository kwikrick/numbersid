
from itertools import count
import os
import sys

# --- misc utilities ---

def read_line_stripped(file):
    line = file.readline()
    parts = line.split('//')
    return parts[0].strip()


# --- numbersid data structures ---

class Varonum:
    def __init__(self, variable: int, number:int):
        self.variable = variable    # variable index, 0 if it's a number
        self.number = number        # an integer

    def type(self):
        return "Variable" if self.variable != 0 else "Number"
    
    def generate_sequence_evaluation(self, function, always: bool = False):
        if not always and self.type() == "Number" and self.number == 0:
            return ""
        if self.type() == "Variable":
            s = f"   {function}({self.type()},{self.variable})\n"
        else:
            s = f"   {function}({self.type()},{self.number})\n"
        return s
    
    @staticmethod
    def parse(s):
        # parse string of the form "variable=number" or "number"
        # if input string first char is a non-digit, then it's a variable, otherwise it's a number
        s = s.strip()
        if len(s) == 0:
            return Varonum(0, 0)
        if s[0].isalpha():
            return Varonum(ord(s[0]),0)
        else:
            return Varonum(0, int(s))  
        
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
        self.parameters = ["gate", "note", "scale", "transpose", "pitch", "waveform", "pulsewidth", "ring", "sync", "attack", "decay", "sustain", "release", "filter"]

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
        if not var_or_zero.isalpha():
            print(f"Warning: invalid sequence output variable: {var_or_zero}")
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
        if seq.variable==None:
            return None
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


class VariableUsage:
    def __init__(self, variable):
        self.variable = variable
        self.sequence_indices = set()         # indices of sequences that use this variable
        self.voice_parameters = set()         # use of this variable in a voice parameter (voicenr, param_name)
        self.sine_parameters = set()          # use of this variable in a sine parameter (sinenr, param_name)
        self.global_parameters = set()        # use of this variable in a global parameter (param_name)     
        #self.filter_mode = False          # use of this variable as cutoff
        #self.filter_cutoff = False       # use of this variable as frequency
        #self.filter_resonance = False          # use of this variable as volume
        #self.volume = False

class Sine:
    def __init__(self):
        self.freq  = None
        self.amplitude  = None
        self.parameters = ["freq", "amplitude"]

    @staticmethod
    def read_from(input_file):
        sine = Sine()
        sine.freq = Varonum.parse(read_line_stripped(input_file))
        sine.amplitude = Varonum.parse(read_line_stripped(input_file))
        return sine

    def __str__(self):
        s = "Sine\n"
        s += f"  freq = {self.freq}\n"
        s += f"  amplitude = {self.amplitude}\n"
        return s


class NumberSidData:
    def __init__(self):
        self.voices = []
        self.channel_voices = []
        self.filter_mode = None
        self.filter_cutoff = None
        self.filter_resonance = None
        self.volume = None
        self.sequences = []
        self.arrays = []
        self.scales = []
        self.variable_to_usage = {}
        self.global_parameter_names = ["filter_mode","filter_cutoff","filter_resonance", "volume"]
        self.sines = []
        self.bob_color_varomum = None
        self.bob_speed_varomum = None

    def map_variable_usage(self):
        for i, seq in enumerate(self.sequences):
            self.map_sequence_varonum_to_useage(seq.count, i)
            self.map_sequence_varonum_to_useage(seq.add1, i)
            self.map_sequence_varonum_to_useage(seq.mul1, i)
            self.map_sequence_varonum_to_useage(seq.div1, i)
            self.map_sequence_varonum_to_useage(seq.mod1, i)
            self.map_sequence_varonum_to_useage(seq.base, i)
            self.map_sequence_varonum_to_useage(seq.mod2, i)
            self.map_sequence_varonum_to_useage(seq.mul2, i)
            self.map_sequence_varonum_to_useage(seq.div2, i)
            self.map_sequence_varonum_to_useage(seq.add2, i)
            self.map_sequence_varonum_to_useage(seq.array, i)

        for voicenr, voice in enumerate(self.voices):
            for param_name in voice.parameters:
                param_varonum = getattr(voice, param_name)
                if param_varonum.type() == "Variable":
                    if param_varonum.variable not in self.variable_to_usage:
                        self.variable_to_usage[param_varonum.variable] = VariableUsage(param_varonum.variable)
                    self.variable_to_usage[param_varonum.variable].voice_parameters.add((voicenr, param_name))

        for param_name in self.global_parameter_names:
            self.map_filter_volume_usage(param_name)

        for sinenr, sine in enumerate(self.sines):
            for param_name in sine.parameters:
                param_varonum = getattr(sine, param_name)
                if param_varonum.type() == "Variable":
                    if param_varonum.variable not in self.variable_to_usage:
                        self.variable_to_usage[param_varonum.variable] = VariableUsage(param_varonum.variable)
                    self.variable_to_usage[param_varonum.variable].sine_parameters.add((sinenr, param_name))
        
    def map_filter_volume_usage(self, parameter_name):
        varonum = getattr(self,parameter_name)
        if varonum != None and varonum.type() == "Variable":
            variable = varonum.variable
            if variable not in self.variable_to_usage:
                self.variable_to_usage[variable] = VariableUsage(variable)
            self.variable_to_usage[variable].global_parameters.add(parameter_name)
            #setattr(self.variable_to_usage[variable], parameter_name, True)        
           
    def map_sequence_varonum_to_useage(self, varonum, seq_index):
        if varonum.variable != 0:
            if varonum.variable not in self.variable_to_usage:
                self.variable_to_usage[varonum.variable] = VariableUsage(varonum.variable)
            self.variable_to_usage[varonum.variable].sequence_indices.add(seq_index)

    def __str__(self):
        s = "NumberSidData\n"
        s += f"{len(self.voices)} voices\n"
        for i, voice in enumerate(self.voices):
            s += f"voice {i}: {voice}\n"
        s += "channel voices:\n"
        for i, channel_voice in enumerate(self.channel_voices):
            s += f"  channel {i}: {channel_voice}\n"
        s += f"filter_mode: {self.filter_mode}\n"
        s += f"filter_cutoff: {self.filter_cutoff}\n"
        s += f"filter_resonance: {self.filter_resonance}\n"
        s += f"volume: {self.volume}\n"
        s += f"{len(self.sequences)} sequences\n"
        for i, seq in enumerate(self.sequences):
            s += f"sequence {i}: {seq}\n"
        s += f"{len(self.arrays)} arrays\n"
        for i, arr in enumerate(self.arrays):
            s += f"array {i}: {arr}\n"
        s += f"{len(self.scales)} scales\n"
        for i, scale in enumerate(self.scales):
            s += f"scale {i}: {scale}\n"
        s += f"{len(self.sines)} sines\n"
        for i, sine in enumerate(self.sines):
            s += f"sine {i}: {sine}\n"
        for variable, usage in self.variable_to_usage.items():
            s += f"variable {chr(variable)} used in:"
            s += f"  sequences {usage.sequence_indices}"
            s += f"  voice parameters {usage.voice_parameters}\n"
            s += f"  sine parameters {usage.sine_parameters}\n"
            s += f"  global parameters {usage.global_parameters}\n"
            
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
        data.filter_cutoff = Varonum.parse(read_line_stripped(input_file))
        data.filter_resonance = Varonum.parse(read_line_stripped(input_file))
        data.volume = Varonum.parse(read_line_stripped(input_file))
        # sequences
        num_sequences = int(read_line_stripped(input_file))
        for i in range(num_sequences):
            seq = Sequence.read_from(input_file)
            if seq:
                data.sequences.append(seq)
        # arrays        
        num_arrays = int(read_line_stripped(input_file))
        for i in range(num_arrays):
            arr = Array.read_from(input_file)
            data.arrays.append(arr)
        # scales
        num_scales = int(read_line_stripped(input_file))
        for i in range(num_scales):
            scale = int(read_line_stripped(input_file))
            data.scales.append(scale)
        # sines parameters
        print("DEBUG read sine")
        num_sines = int(read_line_stripped(input_file))
        for i in range(num_sines):
            sine = Sine.read_from(input_file)
            data.sines.append(sine)
        # ----
        return data
    
# ------------- code generation -------------

scale_size = 64
scale_middle_index = 38

def generate_header(data: NumberSidData) -> str:
    s = "// numbersid generated header\n"
    s+=f".const NUM_SEQUENCES = {len(data.scales)}\n"
    s+=f".const NUM_SCALES = {len(data.scales)}\n"
    s+=f".const SCALE_SIZE = {scale_size}\n"
    s+=f".const SCALE_MIDDLE_INDEX = {scale_middle_index}\n"
    s+=f".const NUM_SINES = {len(data.sines)}\n"
    
    return s

def decode_scale(scale):
    semitones = [0 for i in range(scale_size)]
    if scale==0: return semitones
    # forwards pass
    semitone = 0
    index = scale_middle_index
    while index < scale_size:
        for key in range(0,12):
            if scale & (1<<key) != 0:
                semitones[index]=semitone
                index+=1
                if index >= scale_size: break
            semitone+=1
    # backward pass
    semitone = -1
    index = scale_middle_index-1
    while index >=0:
        for key in range(11,0,-1):
            if scale & (1<<key) != 0:
                semitones[index]=semitone
                index-=1
                if index < 0: break
            semitone-=1
    
    return semitones

def generate(data: NumberSidData) -> str:
    s = "// numbersid generated code\n"

    # generate code for sequences
    for i, seq in enumerate(data.sequences):
        s += f"eval_seq_{i}:\n"         # label for sequence
        s += seq.count.generate_sequence_evaluation("Load_Accumulator", True)
        s += seq.add1.generate_sequence_evaluation("Eval_Add")
        s += seq.div1.generate_sequence_evaluation("Eval_Div")
        s += seq.mul1.generate_sequence_evaluation("Eval_Mul")
        s += seq.mod1.generate_sequence_evaluation("Eval_Mod")
        s += seq.base.generate_sequence_evaluation("Eval_Base")
        s += seq.mod2.generate_sequence_evaluation("Eval_Mod")
        s += seq.mul2.generate_sequence_evaluation("Eval_Mul")
        s += seq.div2.generate_sequence_evaluation("Eval_Div")
        s += seq.add2.generate_sequence_evaluation("Eval_Add")
        s += seq.array.generate_sequence_evaluation("Eval_Array")
        if data.variable_to_usage.get(seq.variable):
            s += f"   Compare_Accumulator({seq.variable})\n"
            s += f"   beq eval_seq_{i}_finish\n"
            s += f"   Store_Accumulator({seq.variable})\n"
            s += f"   jsr variable_changed_{seq.variable}\n"
            s += f"eval_seq_{i}_finish:\n"         # label for sequence
        else:
            print(f"Warning: sequence {i} output variable {chr(seq.variable)} is not used in any voice or sequence")
            s += f"   Store_Accumulator({seq.variable})\n"
        s += "   rts\n"

    s+= "sequence_eval_count:\n"
    s+= f"  .byte {len(data.sequences)}\n"
    s+= "sequence_eval_table:\n"
    for i, seq in enumerate(data.sequences):
        s += f"  .word eval_seq_{i}-1\n"
 

    # generate code for variable_changed subroutines
    for variable, usage in data.variable_to_usage.items():
        s += f"variable_changed_{variable}:\n"
        for seq_index in usage.sequence_indices:
            s+= f"   Mark_Sequence_Dirty({seq_index})\n"
        for voice_param in usage.voice_parameters:
            s+= f"   Apply_Variable_To_Voice_Parameter({variable}, {voice_param[0]}, Voice_Param_{voice_param[1]})\n"
        for global_param in usage.global_parameters:
            s+= f"   Apply_Variable_To_Global_Parameter({variable}, {global_param})\n"
        for sine_param in usage.sine_parameters:
            s+= f"   Apply_Variable_To_Sine_Parameter({variable}, {sine_param[0]}, Sine_Param_{sine_param[1]})\n"
        s += f"   rts\n"

    # generatate code for init_voice-parameter_values:
    s += "init_voice_parameter_values:\n"
    for voicenr, voice in enumerate(data.voices):
        for paramnr, param_name in enumerate(voice.parameters):
             param_varonum = getattr(voice, param_name)
             if param_varonum.type() == "Number":
                value = param_varonum.number
                offset = (voicenr * 16 + paramnr) *2   # reserved 16 words per voice
                if value != 0:
                    s += f"   // voice {voicenr} {param_name}\n"
                    s += f"   lda #<{value}\n"
                    s += f"   sta voice_parameter_values+{offset}\n"
                    if (value > 255):
                        s += f"   lda #>{value}\n"
                        s += f"   sta voice_parameter_values+1+{offset}\n"
    s+= "   rts\n"

    #generate code for init_global_parameter_values:
    s += "init_global_parameter_values:\n"
    for param_name in data.global_parameter_names:
        param_varonum = getattr(data, param_name)
        if param_varonum and param_varonum.type() == "Number" and param_varonum.number != 0:
             value = param_varonum.number
             if value != 0:
                s += f"   // {param_name}\n"
                s += f"   lda #<{value}\n"
                s += f"   sta {param_name}_parameter_value\n"
                if (value > 255):
                    s += f"   lda #>{value}\n"
                    s += f"   sta {param_name}_parameter_value+1\n"          
    s+= "   rts\n"

    # generatate code for init_sine-parameter_values:
    s += "init_sine_parameter_values:\n"
    for sinenr, sine in enumerate(data.sines):
        for paramnr, param_name in enumerate(sine.parameters):
             param_varonum = getattr(sine, param_name)
             if param_varonum.type() == "Number":
                value = param_varonum.number
                label = f"{param_name}s"
                offset = sinenr * 2
                if value != 0:
                    s += f"   // sine {sinenr} {param_name}\n"
                    s += f"   lda #<{value}\n"
                    s += f"   sta {label}+{offset}\n"
                    if (value > 255):
                        s += f"   lda #>{value}\n"
                        s += f"   sta {label}+1+{offset}\n"
    s+= "   rts\n"

    # generate data and space for scales
    #s+=f"scales_encoded:\n"
    #if len(data.scales) > 0:
    #    for scale in data.scales:
    #        s+=f"   .word {scale}\n"
    #s+=f"scales_decoded:\n"
    #if len(data.scales) > 0:
    #    s+=f"   .fill {len(data.scales)} * SCALE_SIZE, 0\n"
    
    s+=f"scales_decoded:\n"
    for i,scale in enumerate(data.scales):
        s+=f"   // scale #{i} = {scale}\n"
        s+=f"   .byte "
        for value in decode_scale(scale):
            s+=f"{value},"
        s=s[:-1]        #remove comma at end 
        s+="\n"
    
    s+=f"scales_ptr_array:\n"
    if len(data.scales) > 0:
        for index,scale in enumerate(data.scales):
            s+=f"   .word scales_decoded + {index} * SCALE_SIZE\n"
    
    return s


# ------------- main -------------

def main():
    if len(sys.argv) != 4:
        print("Usage: generate.py <input_file> <output_file> <output_header_file>")
        return

    input_file_name = sys.argv[1]
    output_file_name = sys.argv[2]
    output_header_file_name = sys.argv[3]
    
    if not os.path.exists(input_file_name):
        print(f"Input file {input_file_name} does not exist.")
        return
    
    input_file = open(input_file_name, 'r')
    output_file = open(output_file_name, 'w')
    output_header_file = open(output_header_file_name, 'w')
    
    data = NumberSidData.read_from(input_file)
    data.map_variable_usage()
    print(data)
    code = generate(data)
    print(code)
    code_header = generate_header(data)
    print(code_header)

    
    output_file.write(code)
    output_header_file.write(code_header)
    input_file.close()
    output_file.close()


if __name__ == "__main__":
     main()

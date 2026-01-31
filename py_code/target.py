# Purpose: Assembly instruction classes and their manipulation routines.
from enum import Enum

class AsmOperandMode(Enum):
    IMM = "immediate"
    ABS = "absolute"
    RGD = "register direct"

class AsmVariable:
    def __init__(self, var_name: str, val: int):
        self.var_name = var_name
        self.val = val

    def __str__(self):
        return f"{self.val}"

class AsmRegister:
    def __init__(self, reg_num):
        self.reg_num = reg_num

    def __str__(self):
        return f"R{self.reg_num}"

class AsmOperand:
    def __init__(self, mode: AsmOperandMode, val: AsmRegister | AsmVariable | int):
        self.mode = mode
        self.val = val

    def __str__(self):
        return str(self.val)

class AsmOperator(Enum):
    ADD = "add"                 # ADD   src, Ri
    SUB = "subtract"            # SUB   src, Ri    
    MUL = "multiply"            # MUL   src, Ri
    DIV = "divide"              # DIV   src, Ri
    MVR = "move to register"    # MOV   src, Ri
    MVD = "move to destination" # MOV   Ri, dst

class AsmInst:
    """A class representing a Assembly Instruction, which is what each three-address instruction will be compiled into"""
    def __init___(self, op: AsmOperator, src: AsmOperand, dest: AsmOperand):
        self.op = op        # The operation to perform
        self.src = src      # The source from which the instruction will use as an operand
        self.dest = dest    # The destination to which the instruction will write the result

    def __str__(self):
        return f"{self.op}    {self.src}, {self.dest}"
    
class AsmInstList:
    """A list ASM instructions that represents the assembly code output"""

    def __init__(self, num_regs: int = 0):
        self.instructions = []      # The assembly instructions
        self.live_on_exit = []      # List of variables that are live on exit
        if num_regs < 0:
            raise ValueError(f"Invalid Number of Register: {num_regs}. Must allocation >= 0 registers.")
        else:
            self.num_regs = num_regs    # The number of available registers. Each must be stored back

    def __str__(self):
        string = "Assembly Instruction List:\n"
        for i, inst in enumerate(self.instructions):
            string += f"    {i}: {str(inst)}\n"
        string += "----------------------------------------"
        return string
    
    def add_inst(self, inst: AsmInst):
        self.instructions.append(inst)

    def remove_inst(self, index: int):
        """
        Removes an instruction by index from the instruction set
        """
        try:
            if 0 <= index < len(self.instructions):
                return self.instructions.pop(index)
        except IndexError:
            raise IndexError(f"Index: {index}, is out of bounds")
        
    def set_live_on_exit(self, live_var: AsmInst):
        self.live_on_exit = live_var
        
    
        
            

"""
Summary: Assembly instruction classes and their manipulation routines.
    Defines the data structures for representing target architecture
    operands, operators, instructions, and instruction lists.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: March 27, 2026
"""

from enum import Enum

class AsmOperandMode(Enum):
    """Represents the addressing mode of an assembly operand."""
    IMM = "immediate"
    ABS = "absolute"
    RGD = "register direct"

class AsmVariable:
    """Represents a named variable in assembly, stored in main memory."""
    def __init__(self, var_name: str, val: int):
        """
        Initializes an AsmVariable instance.
        Args:
            var_name: The name of the variable.
            val: The value or label associated with the variable.
        """
        self.var_name = var_name
        self.val = val

    def __str__(self):
        """
        Returns the string representation of the variable's value.
        Returns:
            str: The variable value as a string.
        """
        return f"{self.val}"

class AsmRegister:
    """Represents a CPU register identified by number."""
    def __init__(self, reg_num):
        """
        Initializes an AsmRegister instance.
        Args:
            reg_num: The register number (integer >= 0).
        """
        self.reg_num = reg_num
        self.reg_num = reg_num

    def __str__(self):
        """
        Returns the string representation of the register.
        Returns:
            str: The register in the format 'R<number>'.
        """
        return f"R{self.reg_num}"

class AsmOperand:
    """Represents an operand in an assembly instruction."""
    def __init__(self, mode: AsmOperandMode, val: AsmRegister | AsmVariable | int):
        """
        Initializes an AsmOperand instance.
        Args:
            mode: The addressing mode (immediate, absolute, or
                register direct).
            val: The operand value (an AsmRegister, AsmVariable,
                or int depending on the mode).
        """
        self.mode = mode
        self.val = val

    def __str__(self):
        """
        Returns the string representation of the operand.
        Returns:
            str: The operand value as a string.
        """
        return str(self.val)

class AsmOperator(Enum):
    """Represents the set of supported assembly operations."""
    ADD = "ADD"             # ADD   src, Ri
    SUB = "SUB"             # SUB   src, Ri    
    MUL = "MUL"             # MUL   src, Ri
    DIV = "DIV"             # DIV   src, Ri
    MVR = "MVR"             # MOV   src, Ri
    MVD = "MVD"             # MOV   Ri, dst
    
    def __str__(self):
        """
        Returns the operator mnemonic as a string.
        Returns:
            str: The assembly operator name.
        """
        return self.value

class AsmInst:
    """A class representing a Assembly Instruction, which is what each
        three-address instruction will be compiled into"""
    def __init__(self, op: AsmOperator, src: AsmOperand, dest: AsmOperand):
        """
        Initializes an AsmInst instance.
        Args:
            op: The operation to perform.
            src: The source from which the instruction will use as an operand.
            dest: The destination to which the instruction will write the result.
        """
        self.op = op
        self.src = src
        self.dest = dest

    def __str__(self):
        """
        Returns the formatted assembly instruction string.
        Returns:
            str: The instruction in the format 'OP    src, dest'.
        """
        return f"{self.op}    {self.src}, {self.dest}"
    
class AsmInstList:
    """A list ASM instructions that represents the assembly code output"""
    def __init__(self, num_regs: int = 0):
        """
        Initializes an AsmInstList instance.
        Args:
            num_regs: The number of available CPU registers. Must be
                >= 0.
        Raises:
            ValueError: If num_regs is negative.
        """
        self.instructions = []      # The assembly instructions
        self.live_on_exit = []      # List of variables that are live on exit
        if num_regs < 0:
            raise ValueError(f"Invalid Number of Register: {num_regs}. Must allocation >= 0 registers.")
        else:
            self.num_regs = num_regs    # The number of available registers. Each must be stored back

    def __str__(self):
        """
        Returns the formatted assembly listing as a string.
        Returns:
            str: All instructions, one per line, indented.
        """
        string = ""
        for i, inst in enumerate(self.instructions):
            string += f"    {str(inst)}\n"
        string += ""
        return string
    
    def add_inst(self, inst: AsmInst):
        """
        Appends an assembly instruction to the instruction list.
        Args:
            inst: The AsmInst object to add.
        Returns:
            None
        """
        self.instructions.append(inst)

    def remove_inst(self, index: int):
        """
        Removes and returns an instruction by index from the list.
        Args:
            index: The position of the instruction to remove.
        Returns:
            AsmInst: The removed instruction, or None if the index
                is out of bounds.
        Raises:
            IndexError: If the index is out of bounds.
        """
        try:
            if 0 <= index < len(self.instructions):
                return self.instructions.pop(index)
        except IndexError:
            raise IndexError(f"Index: {index}, is out of bounds")
        
    def set_live_on_exit(self, live_var: AsmInst):
        """
        Sets the list of variables that are live on exit.
        Args:
            live_var: A list of variables that are live on exit from
                the code block.
        Returns:
            None
        """
        self.live_on_exit = live_var
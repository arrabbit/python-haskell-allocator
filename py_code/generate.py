""" 
Summary: This handles all logic for generating target assembly code from the
         intermediate representation.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: February 26, 2024
"""
from target import AsmInstList, AsmInst, AsmOperator, AsmOperand, AsmOperandMode, AsmRegister, AsmVariable

def generate_assembly(ir_list, colour_map, num_regs):
    # Initialize assembly instruction list
    asm_list = AsmInstList(num_regs)
    op_map = {
        "+": AsmOperator.ADD,
        "-": AsmOperator.SUB,
        "*": AsmOperator.MUL,
        "/": AsmOperator.DIV,
    }
    # TODO loop through IR list and generate assembly instructions based on the
    # IR instruction type and operands

    return asm_list

def make_operand(value_str, colour_map):
    # Converts a string representing an operand into an AsmOperand object

    # Check for an empty string, which indicates no operand 
    if not value_str:
        return None
    
    # Check if it's an immediate value (integer)
    if value_str.isdigit() or (value_str.startswith('-') and value_str[1:].isdigit()):
        return AsmOperand(AsmOperandMode.IMMEDIATE, int(value_str))
    # If it's a variable, look up it's assigned register in the colour map
    else:
        if value_str in colour_map:
            reg_num = colour_map[value_str]
            return AsmOperand(AsmOperandMode.REGISTER, AsmRegister(reg_num))
        else:
            return AsmOperand(AsmOperandMode.VARIABLE, AsmVariable(value_str))
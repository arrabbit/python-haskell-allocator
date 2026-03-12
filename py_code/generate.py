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

def make_operand(value_str):
    # TODO convert a string representing an operand into an AsmOperand object
    # by checking if the string is a variable, register, or immediate value
    # pass

    return None #delete later
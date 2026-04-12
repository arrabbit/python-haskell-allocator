""" 
Summary: This handles all logic for generating target assembly code from the
         intermediate representation.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: February 26, 2026
"""
from target import AsmInstList, AsmInst, AsmOperator, AsmOperand, AsmOperandMode, AsmRegister, AsmVariable
def _translate_instruction(instr, colour_map, op_map):
    """
    Translates a single three-address instruction into a list of assembly
    instructions using the provided register colour map.
    Args:
        instr: A ThreeAdrInst object representing the instruction to translate.
        colour_map: A dictionary mapping variable names to assigned register
            numbers.
        op_map: A dictionary mapping IR operator strings to AsmOperator values.
    Returns:
        list: A list of AsmInst objects for the given instruction.
    """
    dest = AsmOperand(AsmOperandMode.RGD, AsmRegister(colour_map[instr.dest]))
    if instr.op in op_map:
        return [
            AsmInst(AsmOperator.MVR, make_operand(instr.src1, colour_map), dest),
            AsmInst(op_map[instr.op], make_operand(instr.src2, colour_map), dest),
        ]
    elif instr.op:  # unary negation
        return [
            AsmInst(AsmOperator.MVR, AsmOperand(AsmOperandMode.IMM, 0), dest),
            AsmInst(AsmOperator.SUB, make_operand(instr.src1, colour_map), dest),
        ]
    else:  # simple assignment
        return [AsmInst(AsmOperator.MVR, make_operand(instr.src1, colour_map), dest)]

def generate_assembly(ir_list, colour_map, num_regs):
    """
    Translates an intermediate representation instruction list into
    assembly instructions using the provided register colour map.
    Args:
        ir_list: A ThreeAdrInstList containing the intermediate
            representation instructions.
        colour_map: A dictionary mapping variable names (str) to
            assigned register numbers (int).
        num_regs: The number of available CPU registers.
    Returns:
        AsmInstList: The generated assembly instruction list.
    """
    asm = AsmInstList(num_regs)
    op_map = {
        "+": AsmOperator.ADD,
        "-": AsmOperator.SUB,
        "*": AsmOperator.MUL,
        "/": AsmOperator.DIV,
    }
    for instr in ir_list.instructions:
        for asm_instr in _translate_instruction(instr, colour_map, op_map):
            asm.add_inst(asm_instr)

    return handle_live_on_exit(ir_list, colour_map, asm)


def make_operand(value_str, colour_map):
    """
    Converts a string representing an operand into an AsmOperand object.
    Args:
        value_str: The string form of the operand (a variable name,
            integer literal, or None).
        colour_map: A dictionary mapping variable names to their
            assigned register numbers.
    Returns:
        AsmOperand: The corresponding operand object, or None if
            value_str is empty.
    """
    # Check for an empty string, which indicates no operand 
    if not value_str:
        return None
    
    # Check if it's an immediate value (integer)
    if value_str.isdigit() or (value_str.startswith('-') and value_str[1:].isdigit()):
        return AsmOperand(AsmOperandMode.IMM, int(value_str))
    # If it's a variable, look up its assigned register in the colour map
    else:
        if value_str in colour_map:
            reg_num = colour_map[value_str]
            return AsmOperand(AsmOperandMode.RGD, AsmRegister(reg_num))
        else:
            return AsmOperand(AsmOperandMode.ABS, AsmVariable(value_str, value_str))


def _make_store_inst(var, colour_map):
    """Return a MVD instruction that stores var's register value back to memory."""
    reg_num = colour_map[var]
    src = AsmOperand(AsmOperandMode.RGD, AsmRegister(reg_num))
    dst = AsmOperand(AsmOperandMode.ABS, AsmVariable(var, var))
    return AsmInst(AsmOperator.MVD, src, dst)
   
def handle_live_on_exit(ir_list, colour_map, asm_list):
    """
    Appends MVD instructions to store live-on-exit variables back
    to main memory.
    Args:
        ir_list: A ThreeAdrInstList whose live_on_exit list
            identifies variables to store.
        colour_map: A dictionary mapping variable names to their
            assigned register numbers.
        asm_list: The AsmInstList to which store instructions will
            be appended.
    Returns:
        AsmInstList: The updated assembly instruction list with
            store-back instructions appended.
    """
    for var in ir_list.live_on_exit:
        if var in colour_map:
            asm_list.add_inst(_make_store_inst(var, colour_map))
    return asm_list

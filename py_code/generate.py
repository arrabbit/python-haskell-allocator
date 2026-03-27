""" 
Summary: This handles all logic for generating target assembly code from the
         intermediate representation.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: February 26, 2024
"""
from target import AsmInstList, AsmInst, AsmOperator, AsmOperand, AsmOperandMode, AsmRegister, AsmVariable

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

    # TODO loop through IR list and generate assembly instructions based on the
    # IR instruction type and operands
    for instruction in ir_list.instructions:
        dest = AsmOperand(AsmOperandMode.RGD, AsmRegister(colour_map[instruction.dest]))
        if instruction.op in op_map:
            asm.add_inst(AsmInst(AsmOperator.MVR, make_operand(instruction.src1, colour_map), dest))
            asm.add_inst(AsmInst(op_map[instruction.op], make_operand(instruction.src2, colour_map), dest))
        elif instruction.op:
            asm.add_inst(AsmInst(AsmOperator.MVR, AsmOperand(AsmOperandMode.IMM, 0), dest))
            asm.add_inst(AsmInst(AsmOperator.SUB, make_operand(instruction.src1, colour_map), dest))
        else:
            asm.add_inst(AsmInst(AsmOperator.MVR, make_operand(instruction.src1, colour_map), dest))

    # Store variables that are live-on-exit back to main memory
    asm = handle_live_on_exit(ir_list, colour_map, asm)

    return asm

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
        
def handle_live_on_exit(ir_list, colour_map, asm_list):
    """
    Appends MOV instructions to store live-on-exit variables back
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
    for live_var in ir_list.live_on_exit:
        # Get the register it currently lives in
        if live_var in colour_map:
            reg_num = colour_map[live_var]
            src_reg = AsmOperand(AsmOperandMode.RGD, AsmRegister(reg_num))
            
            # Create memory destination
            dest_mem = AsmOperand(AsmOperandMode.ABS, AsmVariable(live_var, live_var))

            # MOV Ri, dest
            store_inst = AsmInst(AsmOperator.MVD, src_reg, dest_mem)
            asm_list.add_inst(store_inst)
    
    return asm_list
""" 
Summary: This handles all logic for generating target assembly code from the
         intermediate representation.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: February 26, 2024
"""
from target import AsmInstList, AsmInst, AsmOperator, AsmOperand, AsmOperandMode, AsmRegister, AsmVariable
from allocator import display_name

def handle_live_on_entry(ir_list, colour_map, asm_list):
    defined = set()
    live_on_entry = []
    for instruction in ir_list.instructions:
        if instruction.src1 and not instruction.src1.isdigit():
            if instruction.src1 not in defined:
                live_on_entry.append(instruction.src1)
                defined.add(instruction.src1)
        if instruction.src2 and not instruction.src2.isdigit():
            if instruction.src2 not in defined:
                live_on_entry.append(instruction.src2)
                defined.add(instruction.src2)
        if instruction.dest:
            defined.add(instruction.dest)
    for var in live_on_entry:
        if var in colour_map:
            reg_num = colour_map[var]
            src_mem = AsmOperand(AsmOperandMode.ABS, AsmVariable(display_name(var), display_name(var)))
            dest_reg = AsmOperand(AsmOperandMode.RGD, AsmRegister(reg_num))
            asm_list.add_inst(AsmInst(AsmOperator.MVR, src_mem, dest_reg))
    return asm_list


def generate_assembly(ir_list, colour_map, num_regs):
    # Initialize assembly instruction list
    asm = AsmInstList(num_regs)
    op_map = {
        "+": AsmOperator.ADD,
        "-": AsmOperator.SUB,
        "*": AsmOperator.MUL,
        "/": AsmOperator.DIV,
    }

    # TODO loop through IR list and generate assembly instructions based on the
    # IR instruction type and operands
    asm = handle_live_on_entry(ir_list, colour_map, asm)
    for instruction in ir_list.instructions:
        dest = AsmOperand(AsmOperandMode.RGD, AsmRegister(colour_map[instruction.dest]))
        if instruction.op and instruction.src2 is None:
            # Unary negation: dest = 0 - src1
            asm.add_inst(AsmInst(AsmOperator.MVR, AsmOperand(AsmOperandMode.IMM, 0), dest))
            asm.add_inst(AsmInst(AsmOperator.SUB, make_operand(instruction.src1, colour_map), dest))
        elif instruction.op in op_map:
            # Binary operation: dest = src1 op src2
            asm.add_inst(AsmInst(AsmOperator.MVR, make_operand(instruction.src1, colour_map), dest))
            asm.add_inst(AsmInst(op_map[instruction.op], make_operand(instruction.src2, colour_map), dest))
        else:
            # Simple assignment: dest = src1
            asm.add_inst(AsmInst(AsmOperator.MVR, make_operand(instruction.src1, colour_map), dest))

    # Store variables that are live-on-exit back to main memory
    asm = handle_live_on_exit(ir_list, colour_map, asm)

    return asm

def make_operand(value_str, colour_map):
    # Converts a string representing an operand into an AsmOperand object

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
    for live_var in ir_list.live_on_exit:
        # Get the register it currently lives in
        if live_var in colour_map:
            reg_num = colour_map[live_var]
            src_reg = AsmOperand(AsmOperandMode.RGD, AsmRegister(reg_num))
            
            # Create memory destination
            dest_mem = AsmOperand(AsmOperandMode.ABS, AsmVariable(display_name(live_var), display_name(live_var)))



            # MOV Ri, dest
            store_inst = AsmInst(AsmOperator.MVD, src_reg, dest_mem)
            asm_list.add_inst(store_inst)
    
    return asm_list

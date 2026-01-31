import os
import sys

current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.append(parent_dir)

from target import AsmInstList, AsmOperand, AsmOperandMode, AsmVariable, AsmRegister

def assert_class_strings():
    var = AsmVariable("a", 1)
    assert str(var) == "1", f"ERROR: Variable a = 1 should have string of '1', not {str(var)}"

    reg = AsmRegister(1)
    assert str(reg) == "R1", f"ERROR: Register 1 should have string of 'R1', not {str(var)}"

    operand = AsmOperand(AsmOperandMode.IMM, 1)
    assert str(operand) == "1", f"ERROR: Operand literal 1 should have string of '1', not {str(var)}"

    operand.mode = AsmOperandMode.RGD
    operand.val = reg
    assert str(operand) == "R1", f"ERROR: Register direct mode operand should have string of 'R1', not {str(var)}"

    operand.mode = AsmOperandMode.ABS
    operand.val = var
    assert str(operand) == "1", f"ERROR: Absolute mode operand should have string of '1', not {str(var)}"

    operand.mode = AsmOperandMode.IMM
    operand.val = 1
    assert str(operand) == "1", f"ERROR: Immediate mode operand should have string of '1', not {str(var)}"

    print("All type strings pass testing!")

if __name__ == "__main__":
    assert_class_strings()
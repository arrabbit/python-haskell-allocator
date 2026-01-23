# Purpose: dedicated strictly to the classes and support routines for
#   three-address instructions. It should not contain unrelated logic.

class ThreeAdrInst:
    """A class representing a three-address instruction in an intermediate representation (IR) module."""

    def __init__(self, dest, src1, op = None, src2 = None):
        """
        Initialize a ThreeAddrInstr instance.
        """
        self.dest = dest        # The destination variable where the result is stored
        self.src1 = src1        # The first source operand
        self.op = op            # The operation to be performed (if any)
        self.src2 = src2        # The second source operand (if any)

    def __str__(self):
        """
        Return a string representation of the three-address instruction.
        """
        if self.op and self.src2:
            # Binary operation (Ex. x = y + 1)
            return f"{self.dest} = {self.src1} {self.op} {self.src2}"
        elif self.op:
            # Unary negation (Ex. x = -y)
            return f"{self.dest} = {self.op} {self.src1}"
        else:
            # Simple assignment (Ex. x = 10)
            return f"{self.dest} = {self.src1}"
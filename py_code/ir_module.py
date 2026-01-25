""" 
Summary: dedicated strictly to the classes and support routines
    for three-address instructions. It should not contain unrelated logic.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: February 26, 2024
"""

class ThreeAdrInst:
    """A class representing a three-address instruction in an intermediate representation (IR) module."""

    def __init__(self, dest, src1, op = None, src2 = None):
        """
        Initialize a ThreeAdrInst instance.
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


class ThreeAdrInstList:
    """A class representing a list of three-address instructions."""

    def __init__(self):
        """
        Initialize an empty ThreeAdrInstList instance.
        """
        self.instructions = []  # List to hold ThreeAdrInst objects
        self.live_on_exit = []  # List of variables live on exit

    def add_instruct(self, instruction):
        """
        Add a ThreeAdrInst to the instruction list.
        """
        self.instructions.append(instruction)

    def remove_instruct(self, index):
        """
        Remove a ThreeAdrInst from the instruction list (accounting for
        duplicates by index).
        """
        if 0 <= index < len(self.instructions):
            return self.instructions.pop(index)
        return None
    
    def set_live_on_exit(self, live_vars):
        """
        Set the list of variables that are live on exit.
        """
        self.live_on_exit = live_vars

    def __print_as_str__(self):
        """
        Return a string representation of the entire instruction list.
        """
        print("Three-Address Instruction List:")
        for i, inst in enumerate(self.instructions):
            print(f"  {i}: {inst}")
        print(f"Live on exit: {', '.join(self.live_on_exit)}")
        print("----------------------------------------")
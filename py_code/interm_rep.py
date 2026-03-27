"""
Summary: Dedicated strictly to the classes and support routines for
    three-address instructions. It should not contain unrelated logic.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: February 26, 2026
"""

class ThreeAdrInst:
    """A class representing a three-address instruction in an intermediate representation (IR) module."""

    def __init__(self, dest, src1, op = None, src2 = None):
        """
        Initializes a ThreeAdrInst instance.
        Args:
            dest: The destination variable name (str) where the result
                is stored.
            src1: The first source operand (variable name or literal
                as str).
            op: The operator string ('+', '-', '*', '/') or None for
                simple assignments.
            src2: The second source operand (str) or None for unary
                and simple assignment instructions.
        """
        self.dest = dest        # The destination variable where the result is stored
        self.src1 = src1        # The first source operand
        self.op = op            # The operation to be performed (if any)
        self.src2 = src2        # The second source operand (if any)

    def __str__(self):
        """
        Returns a human-readable string representation of the
        three-address instruction.
        Returns:
            str: The instruction formatted as 'dest = src1 op src2',
                'dest = op src1', or 'dest = src1'.
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
        Initializes an empty ThreeAdrInstList with no instructions
        and no live-on-exit variables.
        """
        self.instructions = []  # List to hold ThreeAdrInst objects
        self.live_on_exit = []  # List of variables live on exit

    def add_instruct(self, instruction):
        """
        Appends a ThreeAdrInst to the instruction list.
        Args:
            instruction: The ThreeAdrInst object to add.
        Returns:
            None
        """
        self.instructions.append(instruction)

    def remove_instruct(self, index):
        """
        Removes and returns a ThreeAdrInst from the instruction list
        by index.
        Args:
            index: The position of the instruction to remove.
        Returns:
            ThreeAdrInst: The removed instruction, or None if the
                index is out of bounds.
        """
        if 0 <= index < len(self.instructions):
            return self.instructions.pop(index)
        return None
    
    def set_live_on_exit(self, live_vars):
        """
        Sets the list of variables that are live on exit from the
        code block.
        Args:
            live_vars: A list of variable name strings that are live
                on exit.
        Returns:
            None
        """
        self.live_on_exit = live_vars

    def __str__(self):
        """
        Returns a formatted string representation of the entire
        instruction list including live-on-exit variables.
        Returns:
            str: The numbered instruction list followed by the
                live-on-exit variable names.
        """
        string = "Three-Address Instruction List:\n"
        for i, inst in enumerate(self.instructions):
            string += f"  {i}: {inst}\n"
        string += f"Live on exit: {', '.join(self.live_on_exit)}\n"
        string += "----------------------------------------"
        return string
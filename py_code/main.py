"""
Summary: Main entry point for the application. Handles command-line arguments
    and orchestrates tokenization, parsing, graph construction, register
    allocation, and assembly code generation.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: February 26, 2026
"""

from tokenizer import Tokenizer
from parser import Parser
from allocator import build_interfere_graph
from generate import generate_assembly
import sys
import os

def gen_output(code_list, color, num_registers, infile_name):
    """
    Generates assembly code from the IR list and writes it to an
    output file.
    Args:
        code_list: A ThreeAdrInstList containing the parsed
            intermediate representation.
        color: A dictionary mapping variable names to assigned
            register numbers.
        num_registers: The number of available CPU registers.
    Returns:
        None
    """
    try:
        asm = generate_assembly(code_list, color, num_registers)
        print("Assembly code generated successfully.")

        out_file_path = os.path.splitext(infile_name)[0] + ".s"
        with open(out_file_path, "w") as out_file:
            out_file.write(str(asm))
        print(f"Assembly code written to '{out_file_path}' successfully.")
    except Exception as e:
        print(f"Error during assembly generation: {e}", file=sys.stderr)
        sys.exit(1)


def _validate_args(args) -> tuple:
    """Return (num_regs_str, filename) or exit with usage message."""
    if len(args) != 3:
        print("Error: Incorrect number of arguments.", file=sys.stderr)
        sys.exit(1)
    return args[1], args[2]


def _parse_num_registers(s: str) -> int:
    """Parse and validate the register count string; exit on error."""
    try:
        num = int(s)
        if num <= 0:
            print(f"Error: Input for <num_registers> must be positive. "
                  f"Given: {num}", file=sys.stderr)
            sys.exit(1)
        return num
    except ValueError:
        print(f"Error: Input for <num_registers_str> must be a valid integer. "
              f"Given: '{s}'", file=sys.stderr)
        sys.exit(1)


def _validate_input_file(path: str) -> None:
    """Exit with error if path does not point to an existing file."""
    if not os.path.isfile(path):
        print(f"Error: Input file '{path}' is invalid.", file=sys.stderr)
        sys.exit(1)


def _tokenize_and_parse(filename: str):
    """
    Run tokenizer and parser on filename; exit on any error.
    Args:
        filename: Path to the input file to tokenize and parse.
    Returns:
        ThreeAdrInstList: The parsed instruction list.
    """
    try:
        tokenizer = Tokenizer(filename)
        tokenizer.tokenize()
        print("Input tokenized successfully.")
        print(tokenizer)
    except Exception as e:
        print(f"Error during tokenization: {e}", file=sys.stderr)
        sys.exit(1)
    try:
        parser = Parser(tokenizer.tokens)
        parser.parse()
        print("Tokens parsed successfully.")
        print(parser.code_list)
    except Exception as e:
        print(f"Error during parser: {e}", file=sys.stderr)
        sys.exit(1)
    return parser.code_list


def _build_and_allocate(code_list, num_registers: int) -> dict:
    """
    Build interference graph and run register allocator; exit if no
    valid colouring exists.
    Args:
        code_list: A ThreeAdrInstList to allocate registers for.
        num_registers: The number of available CPU registers.
    Returns:
        dict: A mapping of variable names to assigned register numbers.
    """
    try:
        graph = build_interfere_graph(code_list)
        print("Interference graph built successfully.")
        print(graph)
    except Exception as e:
        print(f"Error during interference graph construction: {e}", file=sys.stderr)
        sys.exit(1)

    vars = list(graph.graph.keys())
    succ = graph.allocate_registers(num_registers, vars)
    if succ:
        print(f"Success! Nodes have been allocated to {num_registers} registers")
        print("\nRegister Coloring Table:")
        for var, reg in graph.color.items():
            print(f"  {var} -> R{reg}")
    else:
        print(f"Failure: Unable to color (allocate) nodes to {num_registers} registers.",
              file=sys.stderr)
        sys.exit(1)
    return graph.color


def main():
    """
    Main entry point. Validates command-line arguments, then
    orchestrates tokenization, parsing, interference graph
    construction, register allocation, and assembly code
    generation.
    Returns:
        None
    """
    num_registers_str, infile_name = _validate_args(sys.argv)
    num_registers = _parse_num_registers(num_registers_str)
    _validate_input_file(infile_name)
    code_list = _tokenize_and_parse(infile_name)
    color = _build_and_allocate(code_list, num_registers)
    gen_output(code_list, color, num_registers, infile_name)


if __name__ == "__main__":
    main()

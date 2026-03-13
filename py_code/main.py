""" 
Summary: This script serves as the main entry point for the application.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: February 26, 2024
"""

from tokenizer import Tokenizer
from parser import Parser
from allocator import build_interfere_graph, display_name
from generate import generate_assembly
import sys
import os

def gen_output(code_list, color, num_registers, out_file_path):
    try:
        asm = generate_assembly(code_list, color, num_registers)
        with open(out_file_path, "w") as out_file:
            out_file.write(str(asm))
    except Exception as e:
        print(f"Error during assembly generation: {e}", file=sys.stderr)
        sys.exit(1)

    return

def main():
    """
    Handles command-line arguments and initiates the tokenization process.
    """
    # Check for correct number of command-line arguments
    #       (Ex. main.py <register #> <input_file>)
    if len(sys.argv) != 3:
        print("Error: Incorrect number of arguments.", file=sys.stderr)
        sys.exit(1)
    
    num_registers_str = sys.argv[1]
    infile_name = sys.argv[2]

    # Check if the number of registers is a valid integer
    try:
        num_registers = int(num_registers_str)
        if num_registers <= 0:
            print(f"Error: Input for <num_registers> must be positive. "
                  f"Given: {num_registers}", file=sys.stderr)
            sys.exit(1)
    except ValueError:
        print(f"Error: Input for <num_registers_str> must be a valid integer. "
              f"Given: '{num_registers_str}'", file=sys.stderr)
        sys.exit(1)

    # Check if the input file is valid
    if not os.path.isfile(infile_name):
        print(f"Error: Input file '{infile_name}' is invalid.", file=sys.stderr)
        sys.exit(1)
    
    # Initialize the tokenizer and tokenize the input file
    try: #Tokenize
        tokenizer = Tokenizer(infile_name)
        tokenizer.tokenize()
        # print("Input tokenized successfully.")
        # print(tokenizer)
    except Exception as e:
        print(f"Error during tokenization: {e}", file=sys.stderr)
        sys.exit(1)
    try: #Parsing
        parser = Parser(tokenizer.tokens)
        parser.parse()
        # print("Tokens parsed successfully.")
        # print(parser.code_list)
    except Exception as e:
        print(f"Error during parser: {e}", file=sys.stderr)
        sys.exit(1)

    # Build the interference graph from the instruction list
    try:
        graph = build_interfere_graph(parser.code_list)
        # print("Interference graph built successfully.")
        print(graph)
    except Exception as e:
        print(f"Error during interference graph construction: {e}", file=sys.stderr)
        sys.exit(1)

    vars = list(graph.graph.keys())
    succ = graph.allocate_registers(num_registers, vars)
    if succ:
        print("Register Colouring Table:")
        reg_to_vars = {}
        for var, reg in graph.color.items():
            reg_to_vars.setdefault(reg, []).append(display_name(var))
        for reg in range(num_registers):
            print(f"  R{reg}: {', '.join(reg_to_vars.get(reg, []))}")

    else:
        #print(f"Failure: Unable to color (allocate) nodes to {num_registers} registers.",  file=sys.stderr)
        print(f"Failure: Unable to color (allocate) nodes to {num_registers} registers.")

        sys.exit(1)

    # Generate assembly code from the IR list and register allocation
    out_file_path = os.path.join("test_output", os.path.splitext(os.path.basename(infile_name))[0] + '.s')
    gen_output(parser.code_list, graph.color, num_registers, out_file_path)

if __name__ == "__main__":
    main()

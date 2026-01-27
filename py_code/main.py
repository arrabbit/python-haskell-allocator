""" 
Summary: This script serves as the main entry point for the application.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: February 26, 2024
"""

import sys
import os

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

    from parser_module import Tokenizer # Importing here to avoid issues if parser_module.py has test code
    
    # Initialize the tokenizer and tokenize the input file
    try:
        tokenizer = Tokenizer(infile_name)
        tokenizer.tokenize()
        print("Tokens identified: ")
        print(tokenizer)
    except Exception as e:
        print(f"Error during tokenization: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
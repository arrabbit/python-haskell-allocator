# Purpose: This script serves as the main entry point for the application. 
import sys
from parser_module import Tokenizer, Parser

def main():
    filename = "test.txt" 
    
    print(f"--- Compiling {filename} ---")

    try:
        tokenizer = Tokenizer(filename)
        tokenizer.tokenize()
        
        # Debug
        print(f"\n[Tokens Found]:")
        for t in tokenizer.tokens:
            print(f"  {t}")

        parser = Parser(tokenizer.tokens)
        ir_list = parser.parse()

        print(f"\n[Generated IR]:")
        ir_list.__print_as_str__()

    except Exception as e:
        print(f"\n[Error]: {e}")
        # Debugging
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()
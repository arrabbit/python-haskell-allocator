# Purpose: Contains the logic for reading and validating the input file. This module will import your IR module to instantiate the code sequences.

#Jordan's Idea: 2, pass tokenizer. 1st pass tokenizes every non-white space char as it's own token.
#               second pass looks at the tokens list 
from typing import List, NamedTuple
from enum import Enum
from ir_module import ThreeAdrInst, ThreeAdrInstList
import os

class TokenType(Enum):
    VAR = "variable" # each has a .name and .value attribute
    OP = "operator"
    LIT = "literal"
    EQ = "equality"
    LIV = "live"
    COL = "colon"
    COM = "comma"
    NL = "newline"
    INV = "invalid"

class Token(NamedTuple):
    type: TokenType
    value: str

    def __str__(self):
        if self.value == "\n":
            return f"({self.type.value}, \\n)"
        else:
            return f"({self.type.value}, {self.value})"

    def determine_type(char: str) -> TokenType:
        if (char == "live"):
            return TokenType.LIV
        elif (char in "+-/*"):
            return TokenType.OP
        elif (char.isnumeric()):
            return TokenType.LIT
        # checks for single char var (not t)
        elif (len(char) == 1 and char.islower() and char != "t"):
            return TokenType.VAR
        # checks for t followed by one or more int
        elif (char[0] == "t" and char[1:].isnumeric() and len(char) > 1):
            return TokenType.VAR
        elif (char == ":"):
            return TokenType.COL
        elif (char == ","):
            return TokenType.COM
        elif (char == "\n"):
            return TokenType.NL
        elif (char == "="):
            return TokenType.EQ
        else:
            raise TypeError(f"Invalid token: {char}")


class Tokenizer:
    def __init__(self, file_name: str):
        try: 
            self.file = open(file_name)
            self.tokens = [] # empty list not list of class token
        except FileNotFoundError as e:
            raise FileNotFoundError(f"Tokenize input file not found: {file_name}")

    def __str__(self):
        values = []
        for token in self.tokens:
            if type(token.value) != str:
                continue
            if token.value == "\n":
                values.append("\\n")
            else:
                values.append(token.value)
        return ", ".join(values)

    def get_string(self, curr_pos, start_char: str) -> str:
        """
        Returns an entire alphanumeric token. 
        Fixes the infinite loop at the end of the file.
        """
        result = start_char
        self.file.seek(curr_pos) # move ptr to after start_char
        
        while True:
            next_char = self.file.read(1)
           
            if not next_char:
                break

            if start_char.isdigit():
                if next_char.isdigit():
                    result += next_char
                else:
                    self.file.seek(self.file.tell() - 1)
                    break
            
            elif start_char.isalpha():
                if next_char.isalnum(): 
                    result += next_char
                else:
                    self.file.seek(self.file.tell() - 1)
                    break
            
            else:
                self.file.seek(self.file.tell() - 1)
                break
                
        return result
            
    def tokenize(self):
        while True:
            char = self.file.read(1)
            if not char:
                break
            if char == " ":
                continue
            if char.isdigit() or char.isalpha():
                var = self.get_string(self.file.tell(), char)
                self.tokens.append(Token(value=var, type=Token.determine_type(var)))
            if char in "+-/*=\n:,":
                self.tokens.append(Token(value=char, type=Token.determine_type(char)))

#moved to test block at end of file
"""tokenizer = Tokenizer("test.txt")
tokenizer.tokenize()
print(tokenizer)"""

def assert_determine_type():
    assert Token.determine_type("live").value == "live", "'live' must be of TokenType 'live'"
    assert Token.determine_type("+").value == "operator", "'+' must be of TokenType 'operator"
    assert Token.determine_type("-").value == "operator", "'-' must be of TokenType 'operator'"
    assert Token.determine_type("/").value == "operator", "'/' must be of TokenType 'operator'"
    assert Token.determine_type("*").value == "operator", "'*' must be of TokenType 'operator'"
    assert Token.determine_type("1").value == "literal", "'1' must be of TokenType 'literal'"
    assert Token.determine_type("12").value == "literal", "'12' must be of TokenType 'literal'"
    assert Token.determine_type("a").value == "variable", "'a' must be of TokenType 'variable'"
    assert Token.determine_type("t1").value == "variable", "'t1' must be of TokenType 'variable'"
    assert Token.determine_type("t12").value == "variable", "'t12' must be of TokenType 'variable'"
    assert Token.determine_type(":").value == "colon", "':' must be of TokenType 'colon'"
    assert Token.determine_type(",").value == "comma", "',' must be of TokenType 'comma'"
    assert Token.determine_type("\n").value == "newline", "'\\n' must be of TokenType 'newline'"
    assert Token.determine_type("=").value == "equality", "'=' must be of TokenType 'equality'"
    print("determine_type() passes all tests!")

#moved to test block at end of file
"""assert_determine_type()"""

# Testing code that only executes when this module is run directly (python parser_module.py)
# This code will not run when the module is imported (python main.py <register #> <input_file>)
if __name__ == "__main__":
    try:
        tokenizer = Tokenizer("test.txt")
        tokenizer.tokenize()
        print(tokenizer)

        assert_determine_type()

#test_determine_type()

class Parser:
    def __init__(self, tokens: List[Token]):
        self.tokens = tokens
        self.pos = 0
        self.ir_list = ThreeAdrInstList()

    def consume(self, expected_type=None):
        """Returns current token and moves forward. Optionally checks type."""
        if self.pos >= len(self.tokens):
            return None
        token = self.tokens[self.pos]
        if expected_type and token.type != expected_type:
            raise ValueError(f"Expected {expected_type}, got {token.type}")
        self.pos += 1
        return token

    def parse(self) -> ThreeAdrInstList:
        """
        Iterates through tokens and builds the IR list.
        """
        while self.pos < len(self.tokens):
            # Peek at the current token to decide what to do
            current_token = self.tokens[self.pos]

            if current_token.type == TokenType.VAR:
                # This is likely a standard instruction: x = ...
                self.parse_instruction()
            elif current_token.type == TokenType.LIV:
                # This is the "live : a, b" line
                self.parse_liveness()
            elif current_token.type == TokenType.NL:
                # Skip newlines
                self.consume()
            else:
                raise ValueError(f"Unexpected token at start of line: {current_token}")
        
        return self.ir_list

    def parse_instruction(self):
        # Destination Variable
        dest_token = self.consume(TokenType.VAR)
        
        # Assignment Operator (=)
        self.consume(TokenType.EQ)

        # We peek at the next token to see if it is an operator
        is_unary = False
        unary_op = None
        
        if self.pos < len(self.tokens) and self.tokens[self.pos].type == TokenType.OP:
            op_token = self.consume()
            if op_token.value == '-':
                is_unary = True
                unary_op = op_token.value
            else:
                 # Syntax error
                raise ValueError(f"Invalid unary operator: {op_token.value}")

        # First Operand (src1)
        # In x = -y, 'y' is src1. In x = y + z, 'y' is src1.
        if self.pos >= len(self.tokens):
             raise ValueError("Unexpected end of line after assignment")
             
        src1_token = self.tokens[self.pos]
        if src1_token.type not in (TokenType.VAR, TokenType.LIT):
            raise ValueError(f"Expected source operand, got {src1_token.type}")
        self.consume() # Move past src1

        # Check for Binary Operation (e.g., a = b + c)
        op_value = unary_op 
        src2_value = None

        if not is_unary and self.pos < len(self.tokens):
            next_token = self.tokens[self.pos]
            
            if next_token.type == TokenType.OP:
                # This is a binary operation: src1 OP src2
                self.consume() # consume operator
                op_value = next_token.value
                
                # Get src2
                if self.pos >= len(self.tokens):
                    raise ValueError("Expected second operand after operator")
                
                src2_token = self.tokens[self.pos]
                if src2_token.type not in (TokenType.VAR, TokenType.LIT):
                    raise ValueError("Expected variable or literal for second operand")
                src2_value = src2_token.value
                self.consume() # consume src2

        # Handle Newlines 
        if self.pos < len(self.tokens) and self.tokens[self.pos].type == TokenType.NL:
            self.consume()

        # Add to IR List
        self.ir_list.add_instruct(
            ThreeAdrInst(
                dest=dest_token.value,
                src1=src1_token.value,
                op=op_value,
                src2=src2_value
            )
        )

    def parse_liveness(self):
        self.consume(TokenType.LIV)
        self.consume(TokenType.COL)

        live_vars = []
        expect_var = True

        while self.pos < len(self.tokens):
            token = self.tokens[self.pos]

            if token.type == TokenType.NL:
                self.consume()
                break

            if expect_var:
                if token.type != TokenType.VAR:
                    raise ValueError(f"Expected variable in live list, got {token.type}")
                live_vars.append(token.value)
                self.consume()
                expect_var = False
            else:
                if token.type != TokenType.COM:
                    raise ValueError(f"Expected comma between live variables, got {token.type}")
                self.consume()
                expect_var = True

        if not live_vars:
            raise ValueError("Live statement must specify at least one variable")
        if expect_var:
            raise ValueError("Trailing comma in live statement")

        self.ir_list.set_live_on_exit(live_vars)

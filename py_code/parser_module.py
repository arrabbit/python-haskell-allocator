# Purpose: Contains the logic for reading and validating the input file. This module will import your IR module to instantiate the code sequences.

#Jordan's Idea: 2, pass tokenizer. 1st pass tokenizes every non-white space char as it's own token.
#               second pass looks at the tokens list 
from typing import List, NamedTuple
from enum import Enum
import os

class TokenType(Enum):
    VAR = "variable" # each has a .name and .value attribute
    OP = "operator"
    LIT = "literal"
    EQ = "equal"
    LIV = "live"
    COL = "colon"
    COM = "comma"
    NL = "newline"
    INV = "invalid"

class Token(NamedTuple):
    type: TokenType
    value: str

    def determine_type(char: str) -> TokenType:
        if (char == "live"):
            return TokenType.LIV
        elif (char in "+-/*"):
            return TokenType.OP
        elif (char.isnumeric()):
            return TokenType.LIT
        
        # var must be lowercase AND is either a single char (not t) or t followed by one or more int
        #elif (char.isalpha()):
         #   return TokenType.VAR

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
            self.file = open(f"py_code\{file_name}")
            self.tokens = [Token]
        except FileNotFoundError as e:
            raise FileNotFoundError(f"Tokenize input file not found: {file_name}")

    def __str__(self):
        for token in self.tokens:
            return token

    #must fix decimal bug as well as _ in variables 
    def get_string(self, curr_pos, start_char: str) -> str:
        """
        Returns an entire variable name or an entire number
        """
        self.file.seek(curr_pos) #move ptr to curr_pos
        var = start_char
        while True:
            next_char = self.file.read(1)
            # this might need to be changed because it allows a var to just be
            # 't' when it should be 't' followed by int(s)
            if start_char.isalpha():
                if not next_char.isalpha() or not (next_char.isalnum() or next_char == "_"):
                    if next_char: #if not eof
                        self.file.seek(self.file.tell() - 1) #backtrack 1 byte
                    break
                var += next_char
            elif start_char.isdigit():
                if not next_char.isdigit() and not next_char == ".":
                    if next_char: # if not eof
                        self.file.seek(self.file.tell() - 1) #backtrack 1 byte
                    break
                #---Might not need this, we can assume everything is an int---
                elif next_char == ".":
                    next_next_char = self.file.read(1)
                    if not next_next_char.isdigit():
                        self.file.close()
                        raise TypeError(f"Malformed float: .{next_next_char}")
                    self.file.seek(self.file.tell() - 1) 
                #--------------------------------------------------------------
                var += next_char
            elif next_char.isspace():
                break
        return var
            
    def tokenize(self) -> bool:
        while True:
            char = self.file.read(1)
            if not char:
                break
            if char.isspace():
                continue
            if char.isalpha() or char.isdigit():
                var = self.get_string(self.file.tell(), char)
                self.tokens.append(Token(value=var, type=Token.determine_type(var)))
        return True

tokenizer = Tokenizer("test.txt")
if tokenizer.tokenize():
    for token in tokenizer.tokens:
        print(token.value)

def test_determine_type():
    var = "="

    var_token = Token(value=var, type=Token.determine_type(var))

    print(var_token.value, var_token.type.value)

#test_determine_type()

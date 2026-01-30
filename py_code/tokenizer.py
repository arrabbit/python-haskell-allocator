from typing import NamedTuple
from enum import Enum

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

    def get_type(char: str) -> TokenType:
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
            
    def tokenize(self) -> None:
        while True:
            char = self.file.read(1)
            if not char:
                break
            if char == " ":
                continue
            if char.isdigit() or char.isalpha():
                var = self.get_string(self.file.tell(), char)
                self.tokens.append(Token(value=var, type=Token.get_type(var)))
            if char in "+-/*=\n:,":
                self.tokens.append(Token(value=char, type=Token.get_type(char)))
    

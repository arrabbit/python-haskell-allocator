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


### --- TEST DRIVERS --- ###
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

def assert_tokenize():
    return
def get_string():
    return
def assert_tokenize():
    return

# This code will not run when the module is imported (python main.py <register #> <input_file>)
if __name__ == "__main__":
    
    tokenizer = Tokenizer("test.txt")
    tokenizer.tokenize()
    print(tokenizer)

    assert_determine_type()
    

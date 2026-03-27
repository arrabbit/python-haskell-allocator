"""
Summary: Handles lexical analysis of the input file, converting raw characters
    into a sequence of typed tokens for use by the parser.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: March 27, 2026
"""

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
        """
        Returns a formatted string representation of the token.
        Returns:
            str: The token type and value as a formatted string.
        """
        if self.value == "\n":
            return f"({self.type.value}, \\n)"
        else:
            return f"({self.type.value}, {self.value})"

    def get_type(char: str) -> TokenType:
        """
        Determines the TokenType of a given string.
        Args:
            char: The string to classify (may be a single character or
                a multi-character token such as a variable name or 'live').
        Returns:
            TokenType: The corresponding token type.
        Raises:
            TypeError: If the string does not match any valid token type.
        """
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
        """
        Initializes the Tokenizer by opening the given input file.
        Args:
            file_name: The path to the input file to tokenize.
        Raises:
            FileNotFoundError: If the specified file does not exist.
        """  
        try: 
            self.file = open(file_name)
            self.tokens = [] # empty list not list of class token
        except FileNotFoundError as e:
            raise FileNotFoundError(f"Tokenize input file not found: {file_name}")

    def __str__(self):
        """
        Returns a comma-separated string of all token values.
        Returns:
            str: A string representation of the token list.
        """    
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
        Reads consecutive characters from the file to build a complete
        alphanumeric token starting from the given character.
        Args:
            curr_pos: The current file position (after start_char has
                been read).
            start_char: The first character of the token being built.
        Returns:
            str: The complete token string.
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
        """
        Reads the input file character by character and populates the
        token list. Skips whitespace and groups alphanumeric characters
        into complete tokens.
        Returns:
            None
        """
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
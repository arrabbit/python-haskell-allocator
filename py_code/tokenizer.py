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

_SINGLE_CHAR_TYPES = {
    "+": TokenType.OP,  "-": TokenType.OP,
    "*": TokenType.OP,  "/": TokenType.OP,
    ":": TokenType.COL, ",": TokenType.COM,
    "\n": TokenType.NL, "=": TokenType.EQ,
}

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
            char: The string to classify (a single character or a
                multi-character token such as a variable name or 'live').
        Returns:
            TokenType: The corresponding token type.
        Raises:
            TypeError: If the string does not match any valid token type.
        """
        if char in _SINGLE_CHAR_TYPES:
            return _SINGLE_CHAR_TYPES[char]
        if char == "live":
            return TokenType.LIV
        if char.isnumeric():
            return TokenType.LIT
        if len(char) == 1 and char.islower() and char != "t":
            return TokenType.VAR
        if char[0] == "t" and len(char) > 1 and char[1:].isnumeric():
            return TokenType.VAR
        raise TypeError(f"Invalid token: {char}")


class Tokenizer:
    def __init__(self, file_name: str):
        """
        Initializes the Tokenizer by reading the entire input file into
        a content buffer.
        Args:
            file_name: The path to the input file to tokenize.
        Raises:
            FileNotFoundError: If the specified file does not exist.
        """
        try:
            with open(file_name) as f:
                self.content = f.read()
            self.tokens = []
            self._pos = 0
        except FileNotFoundError:
            raise FileNotFoundError(f"Tokenize input file not found: {file_name}")

    def __str__(self):
        """
        Returns a comma-separated string of all token values.
        Returns:
            str: A string representation of the token list.
        """
        values = []
        for token in self.tokens:
            if not isinstance(token.value, str):
                continue
            if token.value == "\n":
                values.append("\\n")
            else:
                values.append(token.value)
        return ", ".join(values)

    def _read_digit_token(self) -> str:
        """Read consecutive digit characters from the content buffer and
        return the full literal string, advancing self._pos."""
        result = ""
        while self._pos < len(self.content) and self.content[self._pos].isdigit():
            result += self.content[self._pos]
            self._pos += 1
        return result

    def _read_alpha_token(self, start_char: str) -> str:
        """Read consecutive alphanumeric characters from the content buffer
        and return the full token string, advancing self._pos."""
        result = start_char
        while self._pos < len(self.content) and self.content[self._pos].isalnum():
            result += self.content[self._pos]
            self._pos += 1
        return result

    def get_string(self, start_char: str) -> str:
        """
        Reads consecutive characters from the content buffer to build a
        complete alphanumeric token starting from the given character.
        Args:
            start_char: The first character of the token being built.
        Returns:
            str: The complete token string.
        """
        if start_char.isdigit():
            return start_char + self._read_digit_token()
        return self._read_alpha_token(start_char)

    def tokenize(self) -> None:
        """
        Reads the content buffer character by character and populates the
        token list. Skips whitespace and groups alphanumeric characters
        into complete tokens.
        Returns:
            None
        """
        self._pos = 0
        while self._pos < len(self.content):
            char = self.content[self._pos]
            self._pos += 1
            if char == " ":
                continue
            if char.isdigit() or char.isalpha():
                var = self.get_string(char)
                self.tokens.append(Token(value=var, type=Token.get_type(var)))
            if char in "+-/*=\n:,":
                self.tokens.append(Token(value=char, type=Token.get_type(char)))

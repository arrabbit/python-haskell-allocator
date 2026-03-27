"""
Summary: The Parser. Translates tokens into three-address instructions.

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: March 27, 2026
"""

from typing import List, Optional, Tuple
from interm_rep import ThreeAdrInst, ThreeAdrInstList
from tokenizer import TokenType, Token


class Parser:
    def __init__(self, tokens: List[Token]):
        """
        Initializes the Parser with a list of tokens.
        Args:
            tokens: A list of Token objects produced by the Tokenizer.
        """
        self.tokens = tokens
        self.pos = 0
        self.code_list = ThreeAdrInstList()

    def get_next_token(self, expected_type=None):
        """
        Advances the parser position and returns the current token,
        optionally validating its type.
        Args:
            expected_type: The expected TokenType. If provided and the
                current token does not match, a ValueError is raised.  
        Returns:
            Token: The consumed token, or None if at end of input and
                no expected_type was specified.
        Raises:
            ValueError: If the current token type does not match
                expected_type, or if the end of input is reached when
                a specific type was expected.
        """
        if self.pos >= len(self.tokens):
            if expected_type:
                raise ValueError(f"Unexpected end of file. Expected {expected_type}")
            return None
        
        token = self.tokens[self.pos]

        if expected_type is not None and token.type != expected_type:
            raise ValueError(f"Expected {expected_type}, got {token.type}")
        self.pos += 1
        return token

    def peek_current_token(self):
        """
        Returns the current token without advancing the parser position.
        Returns:
            Token: The current token, or None if at end of input.
        """
        if self.pos >= len(self.tokens):
            return None
        return self.tokens[self.pos]

    def parse(self) -> ThreeAdrInstList:
        """
        Parses the full token list into a ThreeAdrInstList by delegating
        to specific handler methods based on token type.
        Returns:
            ThreeAdrInstList: The populated instruction list including
                live-on-exit variable information.
        Raises:
            ValueError: If an unexpected token is encountered.
        """
        while self.pos < len(self.tokens):
            token = self.peek_current_token()
            if token.type == TokenType.VAR:
                self.handle_math_instruction()

            elif token.type == TokenType.LIV:
                self.handle_live_statement()

            elif token.type == TokenType.NL:
                self.get_next_token() # Skip empty lines

            else:
                raise ValueError(f"Unexpected token at start of line: {token}")

        return self.code_list

    def handle_math_instruction(self):
        """
        Parses a standard assignment instruction and adds it to the
        code list. Handles binary (x = y + z), unary (x = -y), and
        simple assignment (x = 10) forms.
        Returns:
            None
        """
        dest = self.get_next_token(TokenType.VAR).value
        self.get_next_token(TokenType.EQ)

        unary_op, src1 = self._parse_first_operand()
        op, src2 = self._parse_second_operand(unary_op)
        
        # Instructions may optionally end with a newline
        if self.peek_current_token() and self.peek_current_token().type == TokenType.NL:
            self.get_next_token()

        self.code_list.add_instruct(ThreeAdrInst(dest, src1, op, src2))

    def _parse_first_operand(self) -> Tuple[Optional[str], str]:
        """
        Parses the first operand on the right-hand side of an
        assignment, handling optional unary negation.
        Returns:
           tuple: A pair (unary_op, src1) where unary_op is '-' if
                a unary minus was found (None otherwise) and src1 is
                the operand value as a string.
        Raises:
            ValueError: If the token is not a variable or literal.
        """
        unary_op = None
        current = self.peek_current_token()

        # Check for unary minus (e.g. -b) before consuming the operand
        if current and current.type == TokenType.OP and current.value == '-':
            unary_op = self.get_next_token().value

        src1_token = self.get_next_token()
        if src1_token.type not in (TokenType.VAR, TokenType.LIT):
            raise ValueError(f"Expected variable or number, got {src1_token.type}")

        return unary_op, src1_token.value

    def _parse_second_operand(self, existing_op) -> Tuple[Optional[str], Optional[str]]:
        """
        Parses the optional binary operator and second operand
        (e.g., + c). If a unary operator was already found, returns
        it without consuming further tokens.
        Args:
            existing_op: A unary operator string ('-') if one was
                already parsed, or None.
        Returns:
            tuple: A pair (operator, src2) where operator is the
                operation string and src2 is the second operand value,
                or (None, None) for simple assignments.
        Raises:
            ValueError: If an operator is found but not followed by
                a valid operand.
        """
        # Unary instructions (x = -y) cannot have a second binary operator
        if existing_op:
            return existing_op, None
        operator = None
        src2 = None
        next_tok = self.peek_current_token()
        
        if next_tok and next_tok.type == TokenType.OP:
            operator = self.get_next_token().value
            src2_token = self.get_next_token()

            if src2_token.type not in (TokenType.VAR, TokenType.LIT):
                raise ValueError("Expected second operand after operator")
            
            src2 = src2_token.value

        return operator, src2

    def handle_live_statement(self):
        """
        Parses the 'live:' line and sets the live-on-exit variables
        on the code list after performing semantic validation.
        Returns:
            None
        Raises:
            ValueError: If a listed variable was never used in the
                preceding code.
        """
        self.get_next_token(TokenType.LIV)
        self.get_next_token(TokenType.COL)
        live_vars = self._collect_variable_list()

        # Handle trailing newline
        if self.peek_current_token() and self.peek_current_token().type == TokenType.NL:
            self.get_next_token()

        # Check live variables are valid (must be variables, not literals or operators)
        self.semantic_check(live_vars)

        self.code_list.set_live_on_exit(live_vars)

    def semantic_check(self, live_vars):
        """
        Validates that every variable declared live on exit actually
        appears in the instruction list.
        Args:
            live_vars: A list of variable name strings declared as
                live on exit.
        Returns:
            None
        Raises:
            ValueError: If any variable in live_vars is not used in
                the code.
        """
        used_vars = set()
        for inst in self.code_list.instructions:
            # Add destination variable
            if inst.dest:
                used_vars.add(inst.dest)
            # Add source 1 variables (ignoring int literals)
            if inst.src1 and not inst.src1.isdigit():
                used_vars.add(inst.src1)
            # Add source 2 variables (ignoring int literals)
            if inst.src2 and not inst.src2.isdigit():
                used_vars.add(inst.src2)
        
        # Checks each live on exit variable is actually used in the code
        for var in live_vars:
            if var not in used_vars:
                raise ValueError(
                    f"Semantic error: Live variable '{var}' is not used in the code.")

        return        

    def _collect_variable_list(self) -> List[str]:
        """
        Parses a comma-separated list of variable names from the
        token stream.
        Returns:
            list: A list of variable name strings. Returns an empty
                list if no variables are present.
        """
        variables = []

        # Checks for zero instructions in input file
        token = self.peek_current_token()
        # If token is empty or not a variable ('/n'), return empty list
        if token == None or token.type != TokenType.VAR:
            return variables

        # There is at least one variable, parse and add to list
        first = self.get_next_token(TokenType.VAR)
        variables.append(first.value)

        # Continue as long as we find commas separating variables
        while True:
            token = self.peek_current_token()
            if token and token.type == TokenType.COM:
                self.get_next_token() 
                var = self.get_next_token(TokenType.VAR)
                variables.append(var.value)
            else:
                break

        return variables
    
    #Testing for live works regardly of if ther is a space between the live variables, you can put as many live variables as necessary 
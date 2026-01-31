""" 

Summary: The Parser. Translates tokens into instructions.

         Refactored for modularity and readability.

"""
from typing import List, Optional, Tuple
from interm_rep import ThreeAdrInst, ThreeAdrInstList
from tokenizer import TokenType, Token


class Parser:
    def __init__(self, tokens: List[Token]):
        self.tokens = tokens
        self.pos = 0
        self.code_list = ThreeAdrInstList()

    def get_next_token(self, expected_type=None):
        """Advances the parser and validates the current token type."""
       
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
        """Returns the current token without consuming it."""
        if self.pos >= len(self.tokens):
            return None
        return self.tokens[self.pos]

    def parse(self) -> ThreeAdrInstList:
        """Main loop: Delegates token processing to specific handlers."""
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
        """Parses a standard assignment instruction (e.g., x = y + z)."""
        dest = self.get_next_token(TokenType.VAR).value
        self.get_next_token(TokenType.EQ)

        unary_op, src1 = self._parse_first_operand()
        op, src2 = self._parse_second_operand(unary_op)
        
        # Instructions may optionally end with a newline
        if self.peek_current_token() and self.peek_current_token().type == TokenType.NL:
            self.get_next_token()

        self.code_list.add_instruct(ThreeAdrInst(dest, src1, op, src2))



    def _parse_first_operand(self) -> Tuple[Optional[str], str]:
        """Parses the first operand, handling optional unary negation."""
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
        """Parses the optional second operand (e.g., + c) for binary operations."""
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
        """Parses the live definition line (e.g., live : a, b)."""
        self.get_next_token(TokenType.LIV)
        self.get_next_token(TokenType.COL)
        live_vars = self._collect_variable_list()

        # Handle trailing newline

        if self.peek_current_token() and self.peek_current_token().type == TokenType.NL:
            self.get_next_token()

        self.code_list.set_live_on_exit(live_vars)



    def _collect_variable_list(self) -> List[str]:
        """Parses a comma-separated list of variables."""
        variables = []

        # The list must contain at least one variable
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
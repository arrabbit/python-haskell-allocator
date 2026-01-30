import os
import sys

current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.append(parent_dir)

from tokenizer import Tokenizer, Token, TokenType

def assert_get_type():
    assert Token.get_type("live").value == "live", "'live' must be of TokenType 'live'"
    assert Token.get_type("+").value == "operator", "'+' must be of TokenType 'operator"
    assert Token.get_type("-").value == "operator", "'-' must be of TokenType 'operator'"
    assert Token.get_type("/").value == "operator", "'/' must be of TokenType 'operator'"
    assert Token.get_type("*").value == "operator", "'*' must be of TokenType 'operator'"
    assert Token.get_type("1").value == "literal", "'1' must be of TokenType 'literal'"
    assert Token.get_type("12").value == "literal", "'12' must be of TokenType 'literal'"
    assert Token.get_type("a").value == "variable", "'a' must be of TokenType 'variable'"
    assert Token.get_type("t1").value == "variable", "'t1' must be of TokenType 'variable'"
    assert Token.get_type("t12").value == "variable", "'t12' must be of TokenType 'variable'"
    assert Token.get_type(":").value == "colon", "':' must be of TokenType 'colon'"
    assert Token.get_type(",").value == "comma", "',' must be of TokenType 'comma'"
    assert Token.get_type("\n").value == "newline", "'\\n' must be of TokenType 'newline'"
    assert Token.get_type("=").value == "equality", "'=' must be of TokenType 'equality'"

    try:
        actual_result = Token.get_type("t")
    except TypeError:
        if actual_result is TypeError:
            print("PASSED: 't' correctly raised TypeError")
    except Exception as e:
        print(f"FAILED: 't' raised unexpected exception: {e}")


    print("get_type() passes all tests!")



if __name__ == "__main__":
    input_file = sys.argv[1]
    tokenizer = Tokenizer(input_file)
    tokenizer.tokenize()

    assert_get_type()

    print(tokenizer)

    
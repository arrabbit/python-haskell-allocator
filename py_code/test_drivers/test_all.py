"""
Summary: Consolidated test suite for the Python register allocator.
    Covers tokenizer, IR, parser, allocator, generate, and target modules.
    Run from the py_code/ directory: python test_drivers/test_all.py

Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
Date: April 9, 2026
"""

import os
import sys

current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
sys.path.insert(0, parent_dir)

from tokenizer import TokenType, Token, Tokenizer
from interm_rep import ThreeAdrInst, ThreeAdrInstList
from parser import Parser
from allocator import InterferenceGraph, build_interfere_graph, rename_vars, process_var
from target import (AsmRegister, AsmVariable, AsmOperand, AsmOperandMode,
                    AsmOperator, AsmInst, AsmInstList)
from generate import generate_assembly, make_operand

TEST_INPUTS = os.path.join(current_dir, "test_inputs")


# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

_passed = 0
_failed = 0

def _check(name, expr):
    global _passed, _failed
    if expr:
        _passed += 1
    else:
        _failed += 1
        print(f"  FAIL: {name}")

def _check_raises(name, exc_type, fn):
    global _passed, _failed
    try:
        fn()
        _failed += 1
        print(f"  FAIL: {name} — expected {exc_type.__name__} but nothing was raised")
    except exc_type:
        _passed += 1
    except Exception as e:
        _failed += 1
        print(f"  FAIL: {name} — expected {exc_type.__name__}, got {type(e).__name__}: {e}")


# ---------------------------------------------------------------------------
# Token / Tokenizer (12 tests)
# ---------------------------------------------------------------------------

def test_token_tokentype():
    # 1
    _check("get_type('live') -> LIV", Token.get_type("live") == TokenType.LIV)
    # 2
    _check("get_type('+') -> OP", Token.get_type("+") == TokenType.OP)
    # 3
    _check("get_type('-') -> OP", Token.get_type("-") == TokenType.OP)
    # 4
    _check("get_type('*') -> OP", Token.get_type("*") == TokenType.OP)
    # 5
    _check("get_type('/') -> OP", Token.get_type("/") == TokenType.OP)
    # 6
    _check("get_type('1') -> LIT", Token.get_type("1") == TokenType.LIT)
    _check("get_type('42') -> LIT", Token.get_type("42") == TokenType.LIT)
    # 7
    _check("get_type('a') -> VAR", Token.get_type("a") == TokenType.VAR)
    _check("get_type('t1') -> VAR", Token.get_type("t1") == TokenType.VAR)
    # 8
    _check("get_type(':') -> COL", Token.get_type(":") == TokenType.COL)
    _check("get_type(',') -> COM", Token.get_type(",") == TokenType.COM)
    # 9
    _check("get_type('=') -> EQ", Token.get_type("=") == TokenType.EQ)
    _check("get_type('\\n') -> NL", Token.get_type("\n") == TokenType.NL)
    # 10 — 't' alone is not a valid variable (length 1, but reserved)
    _check_raises("get_type('t') raises TypeError", TypeError, lambda: Token.get_type("t"))
    # 11
    _check_raises("get_type('Q') raises TypeError", TypeError, lambda: Token.get_type("Q"))
    # 12 — tokenize plain.txt: non-empty, first token is VAR
    tok = Tokenizer(os.path.join(TEST_INPUTS, "plain.txt"))
    tok.tokenize()
    _check("tokenize plain.txt produces tokens", len(tok.tokens) > 0)
    _check("first token is VAR", tok.tokens[0].type == TokenType.VAR)
    # 45 — Tokenizer __str__ returns a non-empty string of token values
    tok2 = Tokenizer(os.path.join(TEST_INPUTS, "plain.txt"))
    tok2.tokenize()
    s = str(tok2)
    _check("Tokenizer __str__ is a non-empty string", isinstance(s, str) and len(s) > 0)


# ---------------------------------------------------------------------------
# ThreeAdrInst / ThreeAdrInstList (6 tests)
# ---------------------------------------------------------------------------

def test_interm_rep():
    # 13
    inst = ThreeAdrInst("a", "b", "+", "c")
    _check("binary __str__", str(inst) == "a = b + c")
    # 14
    inst2 = ThreeAdrInst("x", "y", "-")
    _check("unary __str__", str(inst2) == "x = - y")
    # 15
    inst3 = ThreeAdrInst("z", "5")
    _check("assignment __str__", str(inst3) == "z = 5")
    # 16
    lst = ThreeAdrInstList()
    lst.add_instruct(inst)
    _check("add_instruct increases length", len(lst.instructions) == 1)
    # 17
    lst.add_instruct(inst2)
    removed = lst.remove_instruct(0)
    _check("remove_instruct returns correct inst", removed is inst)
    _check("remove_instruct shrinks list", len(lst.instructions) == 1)
    # 18
    lst.set_live_on_exit(["a", "b"])
    _check("set_live_on_exit stores correctly", lst.live_on_exit == ["a", "b"])
    _check("__str__ includes live vars", "a, b" in str(lst))


# ---------------------------------------------------------------------------
# Parser (8 tests)
# ---------------------------------------------------------------------------

def _make_tokens(src: str):
    """Tokenize a source string using a temp file."""
    import tempfile
    with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
        f.write(src)
        name = f.name
    tok = Tokenizer(name)
    tok.tokenize()
    os.unlink(name)
    return tok.tokens

def test_parser():
    # 19 — binary instruction
    tokens = _make_tokens("a = b + c\nlive: a\n")
    p = Parser(tokens)
    result = p.parse()
    inst = result.instructions[0]
    _check("binary parse: dest", inst.dest == "a")
    _check("binary parse: src1", inst.src1 == "b")
    _check("binary parse: op", inst.op == "+")
    _check("binary parse: src2", inst.src2 == "c")
    # 20 — unary instruction
    tokens = _make_tokens("x = - y\nlive: x\n")
    p = Parser(tokens)
    result = p.parse()
    inst = result.instructions[0]
    _check("unary parse: op is '-'", inst.op == "-")
    _check("unary parse: src2 is None", inst.src2 is None)
    # 21 — simple assignment
    tokens = _make_tokens("z = 5\nlive: z\n")
    p = Parser(tokens)
    result = p.parse()
    inst = result.instructions[0]
    _check("assignment parse: op is None", inst.op is None)
    _check("assignment parse: src2 is None", inst.src2 is None)
    # 22 — live: a, b
    tokens = _make_tokens("a = 1\nb = 2\nlive: a, b\n")
    p = Parser(tokens)
    result = p.parse()
    _check("live vars parsed as ['a','b']", result.live_on_exit == ["a", "b"])
    # 23 — empty live list (no vars after colon)
    tokens = _make_tokens("a = 1\nlive:\n")
    p = Parser(tokens)
    result = p.parse()
    _check("empty live list -> []", result.live_on_exit == [])
    # 24 — unexpected token raises ValueError
    tokens = _make_tokens("= a + b\n")
    _check_raises("unexpected token raises ValueError", ValueError,
                  lambda: Parser(tokens).parse())
    # 25 — live var not in code raises ValueError
    tokens = _make_tokens("a = 1\nlive: b\n")
    _check_raises("unused live var raises ValueError", ValueError,
                  lambda: Parser(tokens).parse())
    # 26 — multiple instructions parsed in order
    tokens = _make_tokens("a = 1\nb = 2\nc = 3\nlive: a, b, c\n")
    p = Parser(tokens)
    result = p.parse()
    _check("three instructions parsed", len(result.instructions) == 3)
    _check("instructions in order", result.instructions[0].dest == "a"
           and result.instructions[2].dest == "c")
    # 51 — literal as second operand (a = b + 5)
    tokens = _make_tokens("a = b + 5\nlive: a\n")
    p = Parser(tokens)
    result = p.parse()
    inst = result.instructions[0]
    _check("literal src2: src2 == '5'", inst.src2 == "5")
    _check("literal src2: op == '+'", inst.op == "+")
    # 52 — invalid second operand after operator raises ValueError
    tokens = _make_tokens("a = b + +\n")
    _check_raises("invalid second operand raises ValueError", ValueError,
                  lambda: Parser(tokens).parse())


# ---------------------------------------------------------------------------
# InterferenceGraph / allocator (8 tests)
# ---------------------------------------------------------------------------

def test_allocator():
    # 27 — add_node
    g = InterferenceGraph()
    g.add_node("a")
    _check("add_node creates empty set", "a" in g.graph and g.graph["a"] == set())
    # 28 — add_node twice: no duplicate
    g.add_node("a")
    _check("add_node twice: still one entry", len(g.graph) == 1)
    # 29 — add_edge bidirectional; self-edge ignored
    g.add_edge("a", "b")
    _check("add_edge: a->b", "b" in g.graph["a"])
    _check("add_edge: b->a", "a" in g.graph["b"])
    g.add_edge("a", "a")
    _check("self-edge ignored", "a" not in g.graph["a"])
    # 30 — is_safe: True when neighbour has different register
    g2 = InterferenceGraph()
    g2.add_edge("a", "b")
    g2.color["b"] = 1
    _check("is_safe True: neighbour has reg 1, asking reg 0", g2.is_safe("a", 0))
    # 31 — is_safe: False when neighbour has same register
    _check("is_safe False: neighbour has reg 0", not g2.is_safe("a", 1))
    # 32 — allocate_registers succeeds with 2 registers on conflicting pair
    g3 = InterferenceGraph()
    g3.add_edge("a", "b")
    result = g3.allocate_registers(2, ["a", "b"])
    _check("allocate 2 regs: succeeds", result is True)
    _check("allocate 2 regs: different registers", g3.color["a"] != g3.color["b"])
    # 33 — allocate_registers fails with 1 register on conflicting pair
    g4 = InterferenceGraph()
    g4.add_edge("a", "b")
    _check("allocate 1 reg: fails", g4.allocate_registers(1, ["a", "b"]) is False)
    # 34 — build_interfere_graph on binary_parse.txt creates edges
    tok = Tokenizer(os.path.join(TEST_INPUTS, "1binary_parse.txt"))
    tok.tokenize()
    p = Parser(tok.tokens)
    code = p.parse()
    graph = build_interfere_graph(code)
    _check("build_interfere_graph: nodes exist", len(graph.graph) > 0)
    # 46 — process_var: None returns None
    _check("process_var(None) -> None", process_var(None, {}, {}) is None)
    # 47 — process_var: digit string returns unchanged
    _check("process_var('5') -> '5'", process_var("5", {}, {}) == "5")
    # 48 — InterferenceGraph.__str__ contains header and node names
    g5 = InterferenceGraph()
    g5.add_edge("x", "y")
    s = str(g5)
    _check("__str__ contains 'Interference Graph'", "Interference Graph" in s)
    _check("__str__ contains node name 'x'", "x" in s)
    # 49 — rename_vars: variable defined twice gets distinct versions
    lst_rv = ThreeAdrInstList()
    lst_rv.add_instruct(ThreeAdrInst("b", "1"))
    lst_rv.add_instruct(ThreeAdrInst("b", "2"))
    lst_rv.set_live_on_exit([])
    rename_vars(lst_rv)
    _check("rename_vars: first def -> b_0", lst_rv.instructions[0].dest == "b_0")
    _check("rename_vars: second def -> b_1", lst_rv.instructions[1].dest == "b_1")
    # 50 — rename_vars: live-on-exit variable gets renamed to active version
    lst_rv2 = ThreeAdrInstList()
    lst_rv2.add_instruct(ThreeAdrInst("a", "1"))
    lst_rv2.set_live_on_exit(["a"])
    rename_vars(lst_rv2)
    _check("rename_vars: live-on-exit 'a' renamed to 'a_0'", lst_rv2.live_on_exit == ["a_0"])


# ---------------------------------------------------------------------------
# generate_assembly (5 tests)
# ---------------------------------------------------------------------------

def _make_code_list(src: str):
    tokens = _make_tokens(src)
    p = Parser(tokens)
    return p.parse()

def test_generate():
    # 35 — binary op: MVR + arithmetic pair
    code = _make_code_list("a = b + c\nlive: a\n")
    colour_map = {"a_0": 0, "b_0": 1, "c_0": 2}
    from allocator import build_interfere_graph as _big
    # Use a manually renamed code list to match what allocator produces
    from interm_rep import ThreeAdrInst, ThreeAdrInstList
    lst = ThreeAdrInstList()
    lst.add_instruct(ThreeAdrInst("a_0", "b_0", "+", "c_0"))
    lst.set_live_on_exit(["a_0"])
    asm = generate_assembly(lst, colour_map, 3)
    ops = [i.op for i in asm.instructions]
    _check("binary: first op is MVR", ops[0] == AsmOperator.MVR)
    _check("binary: second op is ADD", ops[1] == AsmOperator.ADD)

    # 36 — unary negation: MVR #0 + SUB
    lst2 = ThreeAdrInstList()
    lst2.add_instruct(ThreeAdrInst("x_0", "y_0", "-"))
    lst2.set_live_on_exit([])
    colour_map2 = {"x_0": 0, "y_0": 1}
    asm2 = generate_assembly(lst2, colour_map2, 2)
    ops2 = [i.op for i in asm2.instructions]
    _check("unary: produces 2 instructions", len(asm2.instructions) == 2)
    _check("unary: first op is MVR", ops2[0] == AsmOperator.MVR)
    _check("unary: second op is SUB", ops2[1] == AsmOperator.SUB)

    # 37 — simple assignment: single MVR
    lst3 = ThreeAdrInstList()
    lst3.add_instruct(ThreeAdrInst("z_0", "5"))
    lst3.set_live_on_exit([])
    colour_map3 = {"z_0": 0}
    asm3 = generate_assembly(lst3, colour_map3, 1)
    _check("assignment: single MVR", len(asm3.instructions) == 1
           and asm3.instructions[0].op == AsmOperator.MVR)

    # 38 — live-on-exit appends MVD store
    lst4 = ThreeAdrInstList()
    lst4.add_instruct(ThreeAdrInst("a_0", "5"))
    lst4.set_live_on_exit(["a_0"])
    colour_map4 = {"a_0": 0}
    asm4 = generate_assembly(lst4, colour_map4, 1)
    last_op = asm4.instructions[-1].op
    _check("live-on-exit: last inst is MVD", last_op == AsmOperator.MVD)

    # 39 — make_operand modes
    _check("make_operand literal -> IMM",
           make_operand("5", {}).mode == AsmOperandMode.IMM)
    _check("make_operand register var -> RGD",
           make_operand("a", {"a": 0}).mode == AsmOperandMode.RGD)
    _check("make_operand memory var -> ABS",
           make_operand("c", {}).mode == AsmOperandMode.ABS)
    # 53 — generate_assembly with src from memory (not in colour_map) uses ABS mode
    lst5 = ThreeAdrInstList()
    lst5.add_instruct(ThreeAdrInst("a_0", "c", "+", "b_0"))
    lst5.set_live_on_exit([])
    colour_map5 = {"a_0": 0, "b_0": 1}  # 'c' is a memory variable
    asm5 = generate_assembly(lst5, colour_map5, 2)
    _check("memory src: MVR src mode is ABS",
           asm5.instructions[0].src.mode == AsmOperandMode.ABS)


# ---------------------------------------------------------------------------
# AsmInst / AsmInstList / target (5 tests)
# ---------------------------------------------------------------------------

def test_target():
    # 40
    _check("AsmRegister(0).__str__() == 'R0'", str(AsmRegister(0)) == "R0")
    # 41
    src = AsmOperand(AsmOperandMode.RGD, AsmRegister(0))
    dst = AsmOperand(AsmOperandMode.RGD, AsmRegister(1))
    inst = AsmInst(AsmOperator.ADD, src, dst)
    _check("AsmInst.__str__() format", str(inst) == "ADD    R0, R1")
    # 42
    lst = AsmInstList(2)
    lst.add_inst(inst)
    _check("add_inst increases length", len(lst.instructions) == 1)
    # 43
    src2 = AsmOperand(AsmOperandMode.IMM, 5)
    inst2 = AsmInst(AsmOperator.MVR, src2, dst)
    lst.add_inst(inst2)
    removed = lst.remove_inst(0)
    _check("remove_inst returns correct inst", removed is inst)
    # 44
    _check_raises("AsmInstList(-1) raises ValueError", ValueError,
                  lambda: AsmInstList(-1))
    # 54 — AsmVariable.__str__ returns its value label
    v = AsmVariable("myvar", "myvar")
    _check("AsmVariable.__str__ == 'myvar'", str(v) == "myvar")
    # 55 — AsmOperand with IMM mode stringifies to the integer value
    op_imm = AsmOperand(AsmOperandMode.IMM, 42)
    _check("AsmOperand IMM __str__ == '42'", str(op_imm) == "42")
    # 56 — AsmOperand with ABS mode stringifies to the variable label
    op_abs = AsmOperand(AsmOperandMode.ABS, AsmVariable("x", "x"))
    _check("AsmOperand ABS __str__ == 'x'", str(op_abs) == "x")
    # 57 — AsmInstList.__str__ contains the formatted instruction text
    lst_s = AsmInstList(1)
    src_s = AsmOperand(AsmOperandMode.IMM, 0)
    dst_s = AsmOperand(AsmOperandMode.RGD, AsmRegister(0))
    lst_s.add_inst(AsmInst(AsmOperator.MVR, src_s, dst_s))
    _check("AsmInstList __str__ contains 'MVR'", "MVR" in str(lst_s))


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

def run_all():
    print("=" * 50)
    print("Running test_all.py")
    print("=" * 50)

    print("\n--- Token / Tokenizer ---")
    test_token_tokentype()

    print("\n--- ThreeAdrInst / ThreeAdrInstList ---")
    test_interm_rep()

    print("\n--- Parser ---")
    test_parser()

    print("\n--- InterferenceGraph / allocator ---")
    test_allocator()

    print("\n--- generate_assembly ---")
    test_generate()

    print("\n--- AsmInst / AsmInstList / target ---")
    test_target()

    print("\n" + "=" * 50)
    total = _passed + _failed
    print(f"Results: {_passed}/{total} passed", end="")
    if _failed:
        print(f"  ({_failed} FAILED)")
        sys.exit(1)
    else:
        print()


if __name__ == "__main__":
    run_all()

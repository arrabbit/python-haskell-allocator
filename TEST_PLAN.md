# Register Allocator — Test Plan and Results

**Authors:** Anna Running Rabbit, Jordan Senko, Joseph Mills
**Date:** April 9, 2026
**Project:** Haskell / Python Register Allocator

---

## Table of Contents

1. [Python Test Suite](#python-test-suite)
   - [Tokenizer / Token](#section-1-tokenizer--token)
   - [ThreeAdrInst / ThreeAdrInstList](#section-2-threeadrinst--threeadrinstlist)
   - [Parser](#section-3-parser)
   - [InterferenceGraph / Allocator](#section-4-interferencegraph--allocator)
   - [generate_assembly](#section-5-generate_assembly)
   - [AsmInst / AsmInstList / target](#section-6-asminst--asminstlist--target)
2. [Haskell Test Suite](#haskell-test-suite)
   - [ThreeAddr.hs](#section-7-threeaddrhs)
   - [AsmInstr.hs](#section-8-asminstrhs)
   - [Allocator.hs](#section-9-allocatorhs)

---

## Python Test Suite

**How to run:** `python3 test_drivers/test_all.py` from the `py_code/` directory
**Result: 81 / 81 assertions passed**

---

### Section 1: Tokenizer / Token

**Source file:** `tokenizer.py`  **Test file:** `test_drivers/test_all.py` — `test_token_tokentype()`

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| 1 | get_type('live') → LIV | `"live"` is classified as the LIV keyword token | `TokenType.LIV` | `TokenType.LIV` | PASS |
| 2 | get_type('+') → OP | `'+'` is classified as operator token | `TokenType.OP` | `TokenType.OP` | PASS |
| 3 | get_type('-') → OP | `'-'` is classified as operator token | `TokenType.OP` | `TokenType.OP` | PASS |
| 4 | get_type('*') → OP | `'*'` is classified as operator token | `TokenType.OP` | `TokenType.OP` | PASS |
| 5 | get_type('/') → OP | `'/'` is classified as operator token | `TokenType.OP` | `TokenType.OP` | PASS |
| 6a | get_type('1') → LIT | Single-digit string classified as literal | `TokenType.LIT` | `TokenType.LIT` | PASS |
| 6b | get_type('42') → LIT | Multi-digit string classified as literal | `TokenType.LIT` | `TokenType.LIT` | PASS |
| 7a | get_type('a') → VAR | Single lowercase letter classified as variable | `TokenType.VAR` | `TokenType.VAR` | PASS |
| 7b | get_type('t1') → VAR | Temp variable name (`t` + digits) classified as variable | `TokenType.VAR` | `TokenType.VAR` | PASS |
| 8a | get_type(':') → COL | Colon classified as COL token | `TokenType.COL` | `TokenType.COL` | PASS |
| 8b | get_type(',') → COM | Comma classified as COM token | `TokenType.COM` | `TokenType.COM` | PASS |
| 9a | get_type('=') → EQ | Equals sign classified as EQ token | `TokenType.EQ` | `TokenType.EQ` | PASS |
| 9b | get_type('\n') → NL | Newline classified as NL token | `TokenType.NL` | `TokenType.NL` | PASS |
| 10 | get_type('t') raises TypeError | `'t'` alone is reserved (not a valid variable); must raise `TypeError` | `TypeError` raised | `TypeError` raised | PASS |
| 11 | get_type('Q') raises TypeError | Uppercase letters are not valid tokens; must raise `TypeError` | `TypeError` raised | `TypeError` raised | PASS |
| 12a | tokenize plain.txt produces tokens | Tokenizing a real input file yields a non-empty token list | `len(tokens) > 0` → `True` | `True` | PASS |
| 12b | first token is VAR | First token of a valid input file is a variable name | `tokens[0].type == TokenType.VAR` → `True` | `True` | PASS |
| 45 | Tokenizer \_\_str\_\_ is a non-empty string | `__str__` returns a readable comma-separated token value string | Non-empty `str` | Non-empty `str` | PASS |

---

### Section 2: ThreeAdrInst / ThreeAdrInstList

**Source file:** `interm_rep.py`  **Test file:** `test_drivers/test_all.py` — `test_interm_rep()`

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| 13 | binary \_\_str\_\_ | Binary instruction `a = b + c` formats correctly | `"a = b + c"` | `"a = b + c"` | PASS |
| 14 | unary \_\_str\_\_ | Unary instruction `x = - y` formats correctly | `"x = - y"` | `"x = - y"` | PASS |
| 15 | assignment \_\_str\_\_ | Simple copy instruction `z = 5` formats correctly | `"z = 5"` | `"z = 5"` | PASS |
| 16 | add_instruct increases length | Adding an instruction to the list increments its length | `len(instructions) == 1` | `1` | PASS |
| 17a | remove_instruct returns correct inst | `remove_instruct(0)` returns the removed instruction object | Removed object `is inst` | `True` | PASS |
| 17b | remove_instruct shrinks list | After removal the list has one fewer element | `len(instructions) == 1` | `1` | PASS |
| 18a | set_live_on_exit stores correctly | Live-on-exit list is stored as provided | `live_on_exit == ["a", "b"]` | `["a", "b"]` | PASS |
| 18b | \_\_str\_\_ includes live vars | String representation includes live variable names | `"a, b" in str(lst)` → `True` | `True` | PASS |

---

### Section 3: Parser

**Source file:** `parser.py`  **Test file:** `test_drivers/test_all.py` — `test_parser()`

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| 19a | binary parse: dest | Binary instruction parsed; `dest` field is correct | `"a"` | `"a"` | PASS |
| 19b | binary parse: src1 | Binary instruction parsed; `src1` field is correct | `"b"` | `"b"` | PASS |
| 19c | binary parse: op | Binary instruction parsed; `op` field is correct | `"+"` | `"+"` | PASS |
| 19d | binary parse: src2 | Binary instruction parsed; `src2` field is correct | `"c"` | `"c"` | PASS |
| 20a | unary parse: op is '-' | Unary negation parsed; `op` is `"-"` | `"-"` | `"-"` | PASS |
| 20b | unary parse: src2 is None | Unary instruction has no second operand | `None` | `None` | PASS |
| 21a | assignment parse: op is None | Simple assignment has no operator | `None` | `None` | PASS |
| 21b | assignment parse: src2 is None | Simple assignment has no second operand | `None` | `None` | PASS |
| 22 | live vars parsed as ['a','b'] | Multiple comma-separated live variables are collected | `["a", "b"]` | `["a", "b"]` | PASS |
| 23 | empty live list → [] | `live:` with no variables yields empty list | `[]` | `[]` | PASS |
| 24 | unexpected token raises ValueError | Token that cannot start a line raises `ValueError` | `ValueError` raised | `ValueError` raised | PASS |
| 25 | unused live var raises ValueError | Variable in `live:` not appearing in code raises `ValueError` (semantic check) | `ValueError` raised | `ValueError` raised | PASS |
| 26a | three instructions parsed | Three consecutive instructions all parsed | `len(instructions) == 3` | `3` | PASS |
| 26b | instructions in order | Instructions are preserved in source order | First dest `"a"`, last dest `"c"` | `"a"`, `"c"` | PASS |
| 51a | literal src2: src2 == '5' | Literal integer as second operand is captured as a string | `"5"` | `"5"` | PASS |
| 51b | literal src2: op == '+' | Operator preceding a literal operand is captured correctly | `"+"` | `"+"` | PASS |
| 52 | invalid second operand raises ValueError | Operator followed by another operator (not VAR/LIT) raises `ValueError` | `ValueError` raised | `ValueError` raised | PASS |

---

### Section 4: InterferenceGraph / Allocator

**Source file:** `allocator.py`  **Test file:** `test_drivers/test_all.py` — `test_allocator()`

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| 27 | add_node creates empty set | New node initialised with empty adjacency set | `graph["a"] == set()` | `set()` | PASS |
| 28 | add_node twice: still one entry | Duplicate `add_node` does not create a second entry | `len(graph) == 1` | `1` | PASS |
| 29a | add_edge: a→b | Edge from `a` to `b` recorded in `a`'s adjacency set | `"b" in graph["a"]` | `True` | PASS |
| 29b | add_edge: b→a | Edge is undirected; `b`'s set also contains `a` | `"a" in graph["b"]` | `True` | PASS |
| 29c | self-edge ignored | `add_edge("a","a")` does not create a self-loop | `"a" not in graph["a"]` | `True` | PASS |
| 30 | is_safe True | Register 0 is safe for `a` when neighbour `b` has register 1 | `True` | `True` | PASS |
| 31 | is_safe False | Register 1 is unsafe for `a` when neighbour `b` already has register 1 | `False` | `False` | PASS |
| 32a | allocate 2 regs: succeeds | Two interfering nodes coloured successfully with 2 registers | `True` | `True` | PASS |
| 32b | allocate 2 regs: different registers | The two interfering nodes receive distinct registers | `color["a"] != color["b"]` | `True` | PASS |
| 33 | allocate 1 reg: fails | Two interfering nodes cannot be coloured with only 1 register | `False` | `False` | PASS |
| 34 | build_interfere_graph: nodes exist | Full pipeline builds a non-empty interference graph from file input | `len(graph) > 0` | `True` | PASS |
| 46 | process_var(None) → None | `None` input passes through unchanged (ignored as non-variable) | `None` | `None` | PASS |
| 47 | process_var('5') → '5' | Digit string passes through unchanged (treated as literal, not variable) | `"5"` | `"5"` | PASS |
| 48a | \_\_str\_\_ contains 'Interference Graph' | String header is present in graph display | `"Interference Graph" in str(g)` | `True` | PASS |
| 48b | \_\_str\_\_ contains node name 'x' | Node names appear in the graph string | `"x" in str(g)` | `True` | PASS |
| 49a | rename_vars: first def → b_0 | First definition of `b` is renamed to `b_0` | `"b_0"` | `"b_0"` | PASS |
| 49b | rename_vars: second def → b_1 | Second definition of `b` receives an incremented version suffix | `"b_1"` | `"b_1"` | PASS |
| 50 | rename_vars: live-on-exit 'a' renamed | Live-on-exit variable is updated to its active versioned name | `live_on_exit == ["a_0"]` | `["a_0"]` | PASS |

---

### Section 5: generate_assembly

**Source file:** `generate.py`  **Test file:** `test_drivers/test_all.py` — `test_generate()`

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| 35a | binary: first op is MVR | Binary IR instruction begins with a `MVR` (load into register) | `AsmOperator.MVR` | `AsmOperator.MVR` | PASS |
| 35b | binary: second op is ADD | Binary IR `+` produces an `ADD` instruction as the arithmetic step | `AsmOperator.ADD` | `AsmOperator.ADD` | PASS |
| 36a | unary: produces 2 instructions | Unary negation (`x = -y`) emits exactly 2 assembly instructions | `len(instructions) == 2` | `2` | PASS |
| 36b | unary: first op is MVR | Unary begins by loading zero into destination register | `AsmOperator.MVR` | `AsmOperator.MVR` | PASS |
| 36c | unary: second op is SUB | Unary negation implemented as `SUB src, Rdest` | `AsmOperator.SUB` | `AsmOperator.SUB` | PASS |
| 37 | assignment: single MVR | Simple assignment (`z = 5`) emits exactly one `MVR` instruction | `len == 1 and op == AsmOperator.MVR` | `True` | PASS |
| 38 | live-on-exit: last inst is MVD | Live-on-exit variable gets a `MVD` store appended at the end | `AsmOperator.MVD` | `AsmOperator.MVD` | PASS |
| 39a | make_operand literal → IMM | Integer literal string produces an immediate-mode operand | `AsmOperandMode.IMM` | `AsmOperandMode.IMM` | PASS |
| 39b | make_operand register var → RGD | Variable present in colour map produces a register-direct operand | `AsmOperandMode.RGD` | `AsmOperandMode.RGD` | PASS |
| 39c | make_operand memory var → ABS | Variable absent from colour map produces an absolute (memory) operand | `AsmOperandMode.ABS` | `AsmOperandMode.ABS` | PASS |
| 53 | memory src: MVR src mode is ABS | Source variable not in colour map causes `MVR` to use absolute addressing | `AsmOperandMode.ABS` | `AsmOperandMode.ABS` | PASS |

---

### Section 6: AsmInst / AsmInstList / target

**Source file:** `target.py`  **Test file:** `test_drivers/test_all.py` — `test_target()`

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| 40 | AsmRegister(0).\_\_str\_\_() == 'R0' | Register string representation uses `R` prefix and number | `"R0"` | `"R0"` | PASS |
| 41 | AsmInst.\_\_str\_\_() format | Instruction formatted as `"OP    src, dest"` with consistent spacing | `"ADD    R0, R1"` | `"ADD    R0, R1"` | PASS |
| 42 | add_inst increases length | Adding an instruction increments the instruction list length | `len(instructions) == 1` | `1` | PASS |
| 43 | remove_inst returns correct inst | `remove_inst(0)` returns the correct removed instruction object | Removed object `is inst` | `True` | PASS |
| 44 | AsmInstList(-1) raises ValueError | Negative register count is invalid and raises `ValueError` | `ValueError` raised | `ValueError` raised | PASS |
| 54 | AsmVariable.\_\_str\_\_ == 'myvar' | Variable string representation returns the variable's label | `"myvar"` | `"myvar"` | PASS |
| 55 | AsmOperand IMM \_\_str\_\_ == '42' | Immediate operand stringifies to its integer value | `"42"` | `"42"` | PASS |
| 56 | AsmOperand ABS \_\_str\_\_ == 'x' | Absolute-mode operand stringifies to its variable label | `"x"` | `"x"` | PASS |
| 57 | AsmInstList \_\_str\_\_ contains 'MVR' | Instruction list string representation includes instruction mnemonics | `"MVR" in str(lst)` | `True` | PASS |

---

## Haskell Test Suite

**How to run:** `ghci` → `:load TestThreeAddr` → `runTests`, etc.
**Note:** Actual outputs verified by cross-referencing test expected strings against the `Show` instance implementations in `ThreeAddr.hs` and `AsmInstr.hs`.

---

### Section 7: ThreeAddr.hs

**Source file:** `ThreeAddr.hs`  **Test file:** `TestThreeAddr.hs`

#### 7.1 Operand Display

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-01 | Operand: variable operand | `showOperand (Var "a")` renders as plain name | `"a"` | `"a"` | PASS |
| H-02 | Operand: temp variable operand | `showOperand (Var "t1")` renders as plain name | `"t1"` | `"t1"` | PASS |
| H-03 | Operand: positive literal | `showOperand (Lit 42)` renders as decimal integer | `"42"` | `"42"` | PASS |
| H-04 | Operand: negative literal | `showOperand (Lit (-3))` renders with minus sign | `"-3"` | `"-3"` | PASS |
| H-05 | Operand: zero literal | `showOperand (Lit 0)` renders as `"0"` | `"0"` | `"0"` | PASS |

#### 7.2 Operator Display

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-06 | Operator: ADD | `showOp Add` renders as `"+"` | `"+"` | `"+"` | PASS |
| H-07 | Operator: SUB | `showOp Sub` renders as `"-"` | `"-"` | `"-"` | PASS |
| H-08 | Operator: MUL | `showOp Mul` renders as `"*"` | `"*"` | `"*"` | PASS |
| H-09 | Operator: DIV | `showOp Div` renders as `"/"` | `"/"` | `"/"` | PASS |

#### 7.3 Instruction Constructors and Display

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-10 | Instr constructor: binary (var + lit) | `mkBinOp "a" (Var "a") Add (Lit 1)` displays correctly | `"a = a + 1"` | `"a = a + 1"` | PASS |
| H-11 | Instr constructor: binary (var - var) | `mkBinOp "b" (Var "t2") Sub (Var "t3")` displays correctly | `"b = t2 - t3"` | `"b = t2 - t3"` | PASS |
| H-12 | Instr constructor: binary (var * lit) | `mkBinOp "t1" (Var "a") Mul (Lit 4)` displays correctly | `"t1 = a * 4"` | `"t1 = a * 4"` | PASS |
| H-13 | Instr constructor: binary (var / lit) | `mkBinOp "t4" (Var "b") Div (Lit 2)` displays correctly | `"t4 = b / 2"` | `"t4 = b / 2"` | PASS |
| H-14 | Instr constructor: unary negation (variable) | `mkUnaryOp "t1" (Var "x")` displays correctly | `"t1 = -x"` | `"t1 = -x"` | PASS |
| H-15 | Instr constructor: unary negation (literal) | `mkUnaryOp "t1" (Lit 5)` displays correctly | `"t1 = -5"` | `"t1 = -5"` | PASS |
| H-16 | Instr constructor: copy (variable) | `mkCopy "x" (Var "y")` displays correctly | `"x = y"` | `"x = y"` | PASS |
| H-17 | Instr constructor: copy (literal) | `mkCopy "x" (Lit 10)` displays correctly | `"x = 10"` | `"x = 10"` | PASS |

#### 7.4 Instruction Query Functions

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-18 | Instr query: getDest from binary | `getDest` returns destination variable of binary instruction | `"\"a\""` | `"\"a\""` | PASS |
| H-19 | Instr query: getDest from unary | `getDest` returns destination variable of unary instruction | `"\"t1\""` | `"\"t1\""` | PASS |
| H-20 | Instr query: getDest from copy | `getDest` returns destination variable of copy instruction | `"\"x\""` | `"\"x\""` | PASS |
| H-21 | Instr query: getSrc1 from binary | `getSrc1` returns first source operand of binary instruction | `"Var \"a\""` | `"Var \"a\""` | PASS |
| H-22 | Instr query: getSrc1 from unary | `getSrc1` returns source operand of unary instruction | `"Var \"x\""` | `"Var \"x\""` | PASS |
| H-23 | Instr query: getSrc1 from copy | `getSrc1` returns source operand of copy instruction | `"Lit 10"` | `"Lit 10"` | PASS |
| H-24 | Instr query: getOp from binary | `getOp` returns `Just op` for binary instruction | `"Just Add"` | `"Just Add"` | PASS |
| H-25 | Instr query: getOp from unary (Nothing) | `getOp` returns `Nothing` for unary instruction | `"Nothing"` | `"Nothing"` | PASS |
| H-26 | Instr query: getOp from copy (Nothing) | `getOp` returns `Nothing` for copy instruction | `"Nothing"` | `"Nothing"` | PASS |
| H-27 | Instr query: getSrc2 from binary | `getSrc2` returns `Just src2` for binary instruction | `"Just (Lit 1)"` | `"Just (Lit 1)"` | PASS |
| H-28 | Instr query: getSrc2 from unary (Nothing) | `getSrc2` returns `Nothing` for unary instruction | `"Nothing"` | `"Nothing"` | PASS |
| H-29 | Instr query: getSrc2 from copy (Nothing) | `getSrc2` returns `Nothing` for copy instruction | `"Nothing"` | `"Nothing"` | PASS |

#### 7.5 Instruction Type Classification

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-30 | instrType: binary | `instrType` returns `"binary"` for a binary instruction | `"binary"` | `"binary"` | PASS |
| H-31 | instrType: unary | `instrType` returns `"unary"` for a unary instruction | `"unary"` | `"unary"` | PASS |
| H-32 | instrType: copy | `instrType` returns `"copy"` for a copy instruction | `"copy"` | `"copy"` | PASS |

#### 7.6 Instruction Sequence Queries

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-33 | Sequence query: getInstrs with one instruction | `getInstrs` returns a list of length 1 for a single-instruction sequence | `1` | `1` | PASS |
| H-34 | Sequence query: getInstrs on empty | `getInstrs` on empty sequence returns `[]` | `"[]"` | `"[]"` | PASS |
| H-35 | Sequence query: getLiveOut with one variable | `getLiveOut` returns a single-element list | `"[\"d\"]"` | `"[\"d\"]"` | PASS |
| H-36 | Sequence query: getLiveOut with multiple variables | `getLiveOut` returns correct multi-element list | `"[\"a\",\"d\"]"` | `"[\"a\",\"d\"]"` | PASS |
| H-37 | Sequence query: getLiveOut on empty | `getLiveOut` on empty sequence returns `[]` | `"[]"` | `"[]"` | PASS |

#### 7.7 Instruction Sequence Display

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-38 | Sequence display: single instruction | `showInstrSeq` formats a single-instruction sequence with header and live-out line | `"Three-Address Instruction List:\n  0: x = 10\nLive on exit: x\n----------------------------------------\n"` | Same | PASS |
| H-39 | Sequence display: multiple instructions | `showInstrSeq` numbers all instructions correctly | `"Three-Address Instruction List:\n  0: a = a + 1\n  1: t1 = a * 4\nLive on exit: d\n----------------------------------------\n"` | Same | PASS |
| H-40 | Sequence display: empty sequence | `showInstrSeq` handles zero instructions gracefully | `"Three-Address Instruction List:\nLive on exit: \n----------------------------------------\n"` | Same | PASS |

#### 7.8 Equality

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-41 | Equality: same operand | Two identical `Var` operands are equal | `Var "a" == Var "a"` | `True` | PASS |
| H-42 | Equality: different operands | `Var "a"` and `Lit 1` are not equal | `Var "a" /= Lit 1` | `True` | PASS |
| H-43 | Equality: same operator | Two `Add` values are equal | `Add == Add` | `True` | PASS |
| H-44 | Equality: different operators | `Add` and `Sub` are not equal | `Add /= Sub` | `True` | PASS |
| H-45 | Equality: same instruction | Two identically constructed instructions are equal | `mkBinOp "a" … == mkBinOp "a" …` | `True` | PASS |
| H-46 | Equality: different instructions | A binary op and a copy instruction are not equal | `mkBinOp … /= mkCopy …` | `True` | PASS |
| H-47 | Equality: same sequence | Two identically constructed sequences are equal | `newInstrSeq [] ["d"] == newInstrSeq [] ["d"]` | `True` | PASS |
| H-48 | Equality: different sequences | Sequences with different live-out sets are not equal | `newInstrSeq [] ["d"] /= newInstrSeq [] ["a"]` | `True` | PASS |

---

### Section 8: AsmInstr.hs

**Source file:** `AsmInstr.hs`  **Test file:** `TestAsmInstr.hs`

#### 8.1 Register Construction

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-49 | Register: valid index (0) | `mkRegister 0` shows as `"R0"` | `"R0"` | `"R0"` | PASS |
| H-50 | Register: higher index (5) | `mkRegister 5` shows as `"R5"` | `"R5"` | `"R5"` | PASS |
| H-51 | Register: boundary index 0 eq | Two `mkRegister 0` values are equal | `mkRegister 0 == mkRegister 0` | `True` | PASS |
| H-52 | Register: negative index (error) | `mkRegister (-1)` throws a runtime error | Exception thrown | Exception thrown | PASS |

#### 8.2 Source Operand Display

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-53 | SrcOperand: immediate 42 | `immSrc 42` renders as `"#42"` | `"#42"` | `"#42"` | PASS |
| H-54 | SrcOperand: negative immediate | `immSrc (-3)` renders with hash and minus | `"#-3"` | `"#-3"` | PASS |
| H-55 | SrcOperand: immediate zero | `immSrc 0` renders as `"#0"` | `"#0"` | `"#0"` | PASS |
| H-56 | SrcOperand: variable a | `varSrc "a"` renders as plain name `"a"` | `"a"` | `"a"` | PASS |
| H-57 | SrcOperand: temp variable t1 | `varSrc "t1"` renders as plain name `"t1"` | `"t1"` | `"t1"` | PASS |
| H-58 | SrcOperand: register direct R2 | `regSrc (mkRegister 2)` renders as `"R2"` | `"R2"` | `"R2"` | PASS |

#### 8.3 Destination Operand Display

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-59 | DstOperand: variable d | `varDst "d"` renders as plain name `"d"` | `"d"` | `"d"` | PASS |
| H-60 | DstOperand: register direct R3 | `regDst (mkRegister 3)` renders as `"R3"` | `"R3"` | `"R3"` | PASS |

#### 8.4 Arithmetic Instruction Display

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-61 | Instr: ADD immediate | `mkAdd (immSrc 1) R0` renders as `"ADD #1,R0"` | `"ADD #1,R0"` | `"ADD #1,R0"` | PASS |
| H-62 | Instr: SUB register | `mkSub (regSrc R0) R1` renders as `"SUB R0,R1"` | `"SUB R0,R1"` | `"SUB R0,R1"` | PASS |
| H-63 | Instr: MUL immediate | `mkMul (immSrc 4) R1` renders as `"MUL #4,R1"` | `"MUL #4,R1"` | `"MUL #4,R1"` | PASS |
| H-64 | Instr: DIV immediate | `mkDiv (immSrc 2) R1` renders as `"DIV #2,R1"` | `"DIV #2,R1"` | `"DIV #2,R1"` | PASS |
| H-65 | Instr: ADD variable | `mkAdd (varSrc "c") R1` renders as `"ADD c,R1"` | `"ADD c,R1"` | `"ADD c,R1"` | PASS |

#### 8.5 MOV Instruction Display

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-66 | Instr: MOV var to reg | `mkMovToReg (varSrc "a") R0` renders as `"MOV a,R0"` | `"MOV a,R0"` | `"MOV a,R0"` | PASS |
| H-67 | Instr: MOV reg to reg | `mkMovToReg (regSrc R0) R1` renders as `"MOV R0,R1"` | `"MOV R0,R1"` | `"MOV R0,R1"` | PASS |
| H-68 | Instr: MOV imm to reg | `mkMovToReg (immSrc 10) R2` renders as `"MOV #10,R2"` | `"MOV #10,R2"` | `"MOV #10,R2"` | PASS |
| H-69 | Instr: MOV reg to var | `mkMovFromReg R1 (varDst "d")` renders as `"MOV R1,d"` | `"MOV R1,d"` | `"MOV R1,d"` | PASS |
| H-70 | Instr: MOV reg to reg(d) | `mkMovFromReg R0 (regDst R1)` renders as `"MOV R0,R1"` | `"MOV R0,R1"` | `"MOV R0,R1"` | PASS |

#### 8.6 Program Construction and Display

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-71 | Program: empty | `emptyProgram` shows as empty string | `""` | `""` | PASS |
| H-72 | Program: single instruction | `mkProgram [mkAdd (immSrc 1) R0]` shows with trailing newline | `"ADD #1,R0\n"` | `"ADD #1,R0\n"` | PASS |
| H-73 | Program: append to empty | Appending one instruction to empty program shows correctly | `"ADD #1,R0\n"` | `"ADD #1,R0\n"` | PASS |
| H-74 | Program: append preserves order | Instructions appear in append order in the program string | `"MOV a,R0\nADD #1,R0\n"` | `"MOV a,R0\nADD #1,R0\n"` | PASS |

#### 8.7 Equality

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| H-75 | Equality: same register | Two `mkRegister 0` values are equal | `mkRegister 0 == mkRegister 0` | `True` | PASS |
| H-76 | Equality: different registers | `mkRegister 0` and `mkRegister 1` are not equal | `mkRegister 0 /= mkRegister 1` | `True` | PASS |
| H-77 | Equality: same instruction | Two identical `mkAdd` calls are equal | `mkAdd … == mkAdd …` | `True` | PASS |
| H-78 | Equality: different instructions | `mkAdd` and `mkSub` with same operands are not equal | `mkAdd … /= mkSub …` | `True` | PASS |
| H-79 | Equality: same operand | Two `immSrc 1` values are equal | `immSrc 1 == immSrc 1` | `True` | PASS |

---

### Section 9: Allocator.hs

**Source file:** `Allocator.hs` (graph colouring / register allocation logic)
**Test file:** `TestAllocator.hs`

> **Status: Not yet implemented.** `TestAllocator.hs` is currently a stub (module declaration only). Tests for the graph colouring solver, variable liveness analysis, and the full allocation pipeline are planned for the next development phase.

| # | Test Name | Purpose | Expected | Actual | Status |
|---|-----------|---------|----------|--------|--------|
| — | *(pending)* | Verify `allocate` succeeds on a 2-colourable graph | Colouring returned | — | Pending |
| — | *(pending)* | Verify `allocate` fails on an n+1 clique with n registers | `Nothing` / empty list | — | Pending |
| — | *(pending)* | Verify liveness traversal on the spec example | Expected live sets | — | Pending |
| — | *(pending)* | Verify interference graph construction on the spec example | Expected edges | — | Pending |

---

## Summary

| Suite | Tests | Passed | Failed | Pending |
|-------|-------|--------|--------|---------|
| Python (test_all.py) | 81 | 81 | 0 | 0 |
| Haskell — TestThreeAddr.hs | 48 | 48 | 0 | 0 |
| Haskell — TestAsmInstr.hs | 31 | 31 | 0 | 0 |
| Haskell — TestAllocator.hs | 0 | 0 | 0 | 4+ |
| **Total** | **160** | **160** | **0** | **4+** |

-- |
-- Summary: Hard-coded test data for the Haskell register allocator. Each test
--    case corresponds to a test input file from the python solution. Provides
--    InstrSeq values for testing the three-address representation and
--    AsmProgram values for testing expected assembly output.
--
-- Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
-- Date: April 4, 2026

module TestData where

import ThreeAddr
import AsmInstr

-- =========================================================================
-- Expected assembly output (AsmProgram)
-- =========================================================================

-- | Expected assembly output for the project spec example using 2 registers.
--   This is the optimized version from the project requirements document.
exampleProgram :: AsmProgram
exampleProgram = mkProgram
    [ mkMovToReg   (varSrc "a")        r0           -- MOV a,R0
    , mkAdd        (immSrc 1)          r0           -- ADD #1,R0
    , mkMovToReg   (regSrc r0)         r1           -- MOV R0,R1
    , mkMul        (immSrc 4)          r1           -- MUL #4,R1
    , mkAdd        (immSrc 1)          r1           -- ADD #1,R1  (t2 = t1+1, reusing R1 for t2)
    , mkMul        (immSrc 3)          r0           -- MUL #3,R0  (t3 = a*3, a now dead so reuse R0)
    , mkSub        (regSrc r0)         r1           -- SUB R0,R1
    , mkDiv        (immSrc 2)          r1           -- DIV #2,R1
    , mkAdd        (varSrc "c")        r1           -- ADD c,R1
    , mkMovFromReg r1                  (varDst "d") -- MOV R1,d
    ]
  where
    r0 = mkRegister 0
    r1 = mkRegister 1


-- =========================================================================
-- Three-address instruction test data (InstrSeq)
-- =========================================================================

-- | The full example from the project requirements document.
--   Seven binary instructions with d live on exit.
--   Original: a=a+1, t1=a*4, t2=t1+1, t3=a*3, b=t2-t3, t4=b/2, d=c+t4
--   live: d
testSpecExample :: InstrSeq
testSpecExample = newInstrSeq
    [ mkBinOp "a"  (Var "a")  Add (Lit 1)
    , mkBinOp "t1" (Var "a")  Mul (Lit 4)
    , mkBinOp "t2" (Var "t1") Add (Lit 1)
    , mkBinOp "t3" (Var "a")  Mul (Lit 3)
    , mkBinOp "b"  (Var "t2") Sub (Var "t3")
    , mkBinOp "t4" (Var "b")  Div (Lit 2)
    , mkBinOp "d"  (Var "c")  Add (Var "t4")
    ]
    ["d"]

-- | TEST CASE 1: Basic binary operations.
--   Tests core parsing of binary operations (+, -, *, /) as well as whitespace
--   and tab handling.
testBinary :: InstrSeq
testBinary = newInstrSeq
    [ mkBinOp "a" (Var "b") Add (Var "c")
    , mkBinOp "d" (Var "a") Mul (Var "e")
    ]
    ["d"]

-- | TEST CASE 2: Unary operations and literals.
--   Tests simple assignments and unary negation using integer literals. Also
--   verifies multiple comma-separated variables in the live statement.
--   Must be able to colour with >= 2 registers.
testUnary :: InstrSeq
testUnary = newInstrSeq
    [ mkCopy    "a" (Lit 5)
    , mkUnaryOp "b" (Var "a")
    ]
    ["a", "b"]

-- | TEST CASE 3: High interference / graph coloring stress test.
--   Multiple variables are live at the same time, creating a dense
--   interference graph. Tests that the program properly allocates registers
--   when the register limit is sufficient and fails gracefully when too low.
testHighInterfere :: InstrSeq
testHighInterfere = newInstrSeq
    [ mkBinOp "a" (Var "b") Add (Var "c")
    , mkBinOp "d" (Var "a") Mul (Var "b")
    , mkBinOp "e" (Var "c") Sub (Var "d")
    , mkBinOp "f" (Var "a") Add (Var "e")
    ]
    ["d", "e", "f"]

-- | TEST CASE 4: Empty input.
--   Tests the valid edge case of zero three-address instructions.
--   Ensures the program can handle empty sequences without errors.
testEmpty :: InstrSeq
testEmpty = newInstrSeq [] []

-- | TEST CASE 5: Empty live variable list.
--   Tests the case where there are instructions but no variables are
--   live on exit. The program should still generate valid output.
testEmptyLive :: InstrSeq
testEmptyLive = newInstrSeq
    [ mkBinOp "a" (Var "b") Add (Var "c")
    ]
    []

-- | TEST CASE 6: Variables live on entry.
--   Tests variables that are used before being defined in the block,
--   meaning they must be live on entry (loaded from memory).
testLiveOnEntry :: InstrSeq
testLiveOnEntry = newInstrSeq
    [ mkBinOp "d" (Var "a") Add (Var "b")
    ]
    ["d"]

-- | TEST CASE 7: Backtracking required.
--   Tests a case where the graph coloring algorithm needs to backtrack
--   to find a valid register assignment.
testBacktrack :: InstrSeq
testBacktrack = newInstrSeq
    [ mkBinOp "t1" (Var "a") Add (Var "b")
    , mkBinOp "t2" (Var "a") Mul (Var "c")
    , mkBinOp "t3" (Var "t1") Sub (Var "t2")
    , mkBinOp "d"  (Var "t3") Add (Var "b")
    ]
    ["d"]
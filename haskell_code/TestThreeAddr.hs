-- |
-- Summary: Automated test module for ThreeAddr.hs. Runs all test cases
--   and reports pass/fail results with a summary count.
--
-- Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
-- Date: April 4, 2026

module TestThreeAddr where

import ThreeAddr
import TestUtils

-- | Runs all tests and prints results to the terminal
runTests :: IO ()
runTests = do
    putStrLn "========================================="
    putStrLn " ThreeAddr.hs - Automated Test Results"
    putStrLn "========================================="
    putStrLn ""

    -- Run all tests
    let results = runAllTests

    -- Print each result
    printAllResults results

    -- Print summary
    printSummary results

runAllTests :: [TestResult]
runAllTests =
    operandTests
    ++ operatorTests
    ++ instrConstructorTests
    ++ instrQueryTests
    ++ instrTypeTests
    ++ seqQueryTests
    ++ seqDisplayTests
    ++ equalityTests

-------------------------------------------------------
-- Operand tests
-------------------------------------------------------
operandTests :: [TestResult]
operandTests =
    [ strTest   "Operand: variable operand"
        (showOperand (Var "a"))
        "a"
    , strTest   "Operand: temp variable operand"
        (showOperand (Var "t1"))
        "t1"
    , strTest   "Operand: positive literal"
        (showOperand (Lit 42))
        "42"
    , strTest   "Operand: negative literal"
        (showOperand (Lit (-3)))
        "-3"
    , strTest   "Operand: zero literal"
        (showOperand (Lit 0))
        "0"
    ]

-------------------------------------------------------
-- Operator display tests
-------------------------------------------------------
operatorTests :: [TestResult]
operatorTests =
    [ strTest   "Operator: ADD"
        (showOp Add)
        "+"
    , strTest   "Operator: SUB"
        (showOp Sub)
        "-"
    , strTest   "Operator: MUL"
        (showOp Mul)
        "*"
    , strTest   "Operator: DIV"
        (showOp Div)
        "/"
    ]

-------------------------------------------------------
-- Instruction constructor tests
-------------------------------------------------------
instrConstructorTests :: [TestResult]
instrConstructorTests =
    [ strTest   "Instr constructor: binary (var + lit)"
        (showInstr (mkBinOp "a" (Var "a") Add (Lit 1)))
        "a = a + 1"
    , strTest   "Instr constructor: binary (var - var)"
        (showInstr (mkBinOp "b" (Var "t2") Sub (Var "t3")))
        "b = t2 - t3"
    , strTest   "Instr constructor: binary (var * lit)"
        (showInstr (mkBinOp "t1" (Var "a") Mul (Lit 4)))
        "t1 = a * 4"
    , strTest   "Instr constructor: binary (var / lit)"
        (showInstr (mkBinOp "t4" (Var "b") Div (Lit 2)))
        "t4 = b / 2"
    , strTest   "Instr constructor: unary negation (variable)"
        (showInstr (mkUnaryOp "t1" (Var "x")))
        "t1 = -x"
    , strTest   "Instr constructor: unary negation (literal)"
        (showInstr (mkUnaryOp "t1" (Lit 5)))
        "t1 = -5"
    , strTest   "Instr constructor: copy (variable)"
        (showInstr (mkCopy "x" (Var "y")))
        "x = y"
    , strTest   "Instr constructor: copy (literal)"
        (showInstr (mkCopy "x" (Lit 10)))
        "x = 10"
    ]

-------------------------------------------------------
-- Instruction query tests
-------------------------------------------------------
instrQueryTests :: [TestResult]
instrQueryTests =
    [ showTest  "Instr query: getDest from binary"
        (getDest (mkBinOp "a" (Var "a") Add (Lit 1)))
        "\"a\""
    , showTest  "Instr query: getDest from unary"
        (getDest (mkUnaryOp "t1" (Var "x")))
        "\"t1\""
    , showTest  "Instr query: getDest from copy"
        (getDest (mkCopy "x" (Lit 10)))
        "\"x\""
    , showTest  "Instr query: getSrc1 from binary"
        (getSrc1 (mkBinOp "a" (Var "a") Add (Lit 1)))
        "Var \"a\""
    , showTest  "Instr query: getSrc1 from unary"
        (getSrc1 (mkUnaryOp "t1" (Var "x")))
        "Var \"x\""
    , showTest  "Instr query: getSrc1 from copy"
        (getSrc1 (mkCopy "x" (Lit 10)))
        "Lit 10"
    , showTest  "Instr query: getOp from binary"
        (getOp (mkBinOp "a" (Var "a") Add (Lit 1)))
        "Just Add"
    , showTest  "Instr query: getOp from unary (Nothing)"
        (getOp (mkUnaryOp "t1" (Var "x")))
        "Nothing"
    , showTest  "Instr query: getOp from copy (Nothing)"
        (getOp (mkCopy "x" (Lit 10)))
        "Nothing"
    , showTest  "Instr query: getSrc2 from binary"
        (getSrc2 (mkBinOp "a" (Var "a") Add (Lit 1)))
        "Just (Lit 1)"
    , showTest  "Instr query: getSrc2 from unary (Nothing)"
        (getSrc2 (mkUnaryOp "t1" (Var "x")))
        "Nothing"
    , showTest  "Instr query: getSrc2 from copy (Nothing)"
        (getSrc2 (mkCopy "x" (Lit 10)))
        "Nothing"
    ]

-------------------------------------------------------
-- Instruction type tests
-------------------------------------------------------
instrTypeTests :: [TestResult]
instrTypeTests =
    [ strTest   "instrType: binary"
        (instrType (mkBinOp "a" (Var "a") Add (Lit 1)))
        "binary"
    , strTest   "instrType: unary"
        (instrType (mkUnaryOp "t1" (Var "x")))
        "unary"
    , strTest   "instrType: copy"
        (instrType (mkCopy "x" (Lit 10)))
        "copy"
    ]

-------------------------------------------------------
-- Sequence constructor and query tests
-------------------------------------------------------
seqQueryTests :: [TestResult]
seqQueryTests =
    [ eqTest    "Sequence query: getInstrs with one instruction"
        (length (getInstrs (newInstrSeq [mkCopy "x" (Lit 10)] ["x"])))
        1
    , showTest  "Sequence query: getInstrs on empty"
        (getInstrs (newInstrSeq [] []))
        "[]"
    , showTest  "Sequence query: getLiveOut with one variable"
        (getLiveOut (newInstrSeq [] ["d"]))
        "[\"d\"]"
    , showTest  "Sequence query: getLiveOut with multiple variables"
        (getLiveOut (newInstrSeq [] ["a", "d"]))
        "[\"a\",\"d\"]"
    , showTest  "Sequence query: getLiveOut on empty"
        (getLiveOut (newInstrSeq [] []))
        "[]"
    ]

-------------------------------------------------------
-- Sequence display tests
-------------------------------------------------------
seqDisplayTests :: [TestResult]
seqDisplayTests =
    [ strTest   "Sequence display: single instruction"
        (showInstrSeq (newInstrSeq [mkCopy "x" (Lit 10)] ["x"]))
        ("Three-Address Instruction List:\n"
         ++ "  0: x = 10\n"
         ++ "Live on exit: x\n"
         ++ "----------------------------------------\n")
    , strTest   "Sequence display: multiple instructions"
        (showInstrSeq (newInstrSeq
            [ mkBinOp "a" (Var "a") Add (Lit 1)
            , mkBinOp "t1" (Var "a") Mul (Lit 4)
            ] ["d"]))
        ("Three-Address Instruction List:\n"
         ++ "  0: a = a + 1\n"
         ++ "  1: t1 = a * 4\n"
         ++ "Live on exit: d\n"
         ++ "----------------------------------------\n")
    , strTest   "Sequence display: empty sequence"
        (showInstrSeq (newInstrSeq [] []))
        ("Three-Address Instruction List:\n"
         ++ "Live on exit: \n"
         ++ "----------------------------------------\n")
    ]

-------------------------------------------------------
-- Equality tests
-------------------------------------------------------
equalityTests :: [TestResult]
equalityTests =
    [ eqTest    "Equality: same operand"
        (Var "a")
        (Var "a")
    , notEqTest "Equality: different operands"
        (Var "a")
        (Lit 1)
    , eqTest    "Equality: same operator"
        Add
        Add
    , notEqTest "Equality: different operators"
        Add
        Sub
    , eqTest    "Equality: same instruction"
        (mkBinOp "a" (Var "a") Add (Lit 1))
        (mkBinOp "a" (Var "a") Add (Lit 1))
    , notEqTest "Equality: different instructions"
        (mkBinOp "a" (Var "a") Add (Lit 1))
        (mkCopy "a" (Var "a"))
    , eqTest    "Equality: same sequence"
        (newInstrSeq [] ["d"])
        (newInstrSeq [] ["d"])
    , notEqTest "Equality: different sequences"
        (newInstrSeq [] ["d"])
        (newInstrSeq [] ["a"])
    ]
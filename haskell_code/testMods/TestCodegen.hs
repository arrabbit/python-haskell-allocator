-- |
-- Summary: Automated test module for Codegen.hs. Tests assembly code
--   generation for all three instruction types, all four operators,
--   all source operand modes, and store-back behaviour.
--
-- Authors: Joseph Mills
-- Date: April 11, 2026

module TestMods.TestCodegen where

import Codegen   (generateCode)
import ThreeAddr (newInstrSeq, mkBinOp, mkUnaryOp, mkCopy, Operand(..), Op(..))
import TestMods.TestUtils

-------------------------------------------------------
-- All tests
-------------------------------------------------------

runTests :: IO ()
runTests = do
    putStrLn "========================================="
    putStrLn " Codegen.hs - Automated Test Results"
    putStrLn "========================================="
    putStrLn ""
    let results = runAllTests
    printAllResults results
    printSummary results

runAllTests :: [TestResult]
runAllTests =
    copyTests
    ++ unaryTests
    ++ binaryTests
    ++ storeTests
    ++ sequenceTests

-------------------------------------------------------
-- Copy instruction tests
-------------------------------------------------------

-- Copy produces one MOV instruction: MOV src, Rdest
copyTests :: [TestResult]
copyTests =
    [ showTest "Copy: literal source"
        (generateCode
            (newInstrSeq [mkCopy "a" (Lit 5)] ["a"])
            [("a", 0)])
        "MOV #5,R0\nMOV R0,a\n"

    , showTest "Copy: variable source in solution (register mode)"
        (generateCode
            (newInstrSeq [mkCopy "a" (Var "b")] ["a"])
            [("a", 0), ("b", 1)])
        "MOV R1,R0\nMOV R0,a\n"

    , showTest "Copy: variable source not in solution (memory mode)"
        (generateCode
            (newInstrSeq [mkCopy "a" (Var "c")] ["a"])
            [("a", 0)])
        "MOV c,R0\nMOV R0,a\n"
    ]

-------------------------------------------------------
-- Unary negation tests
-------------------------------------------------------

-- Unary produces two instructions: MOV #0, Rdest then SUB src, Rdest
unaryTests :: [TestResult]
unaryTests =
    [ showTest "Unary: negate variable"
        (generateCode
            (newInstrSeq [mkUnaryOp "a" (Var "b")] ["a"])
            [("a", 0), ("b", 1)])
        "MOV #0,R0\nSUB R1,R0\nMOV R0,a\n"

    , showTest "Unary: negate literal"
        (generateCode
            (newInstrSeq [mkUnaryOp "a" (Lit 3)] ["a"])
            [("a", 0)])
        "MOV #0,R0\nSUB #3,R0\nMOV R0,a\n"
    ]

-------------------------------------------------------
-- Binary instruction tests
-------------------------------------------------------

-- Binary produces two instructions: MOV src1, Rdest then OP src2, Rdest
binaryTests :: [TestResult]
binaryTests =
    [ showTest "Binary: Add two registers"
        (generateCode
            (newInstrSeq [mkBinOp "a" (Var "b") Add (Var "c")] ["a"])
            [("a", 0), ("b", 1), ("c", 2)])
        "MOV R1,R0\nADD R2,R0\nMOV R0,a\n"

    , showTest "Binary: Sub two registers"
        (generateCode
            (newInstrSeq [mkBinOp "a" (Var "b") Sub (Var "c")] ["a"])
            [("a", 0), ("b", 1), ("c", 2)])
        "MOV R1,R0\nSUB R2,R0\nMOV R0,a\n"

    , showTest "Binary: Mul two registers"
        (generateCode
            (newInstrSeq [mkBinOp "a" (Var "b") Mul (Var "c")] ["a"])
            [("a", 0), ("b", 1), ("c", 2)])
        "MOV R1,R0\nMUL R2,R0\nMOV R0,a\n"

    , showTest "Binary: Div two registers"
        (generateCode
            (newInstrSeq [mkBinOp "a" (Var "b") Div (Var "c")] ["a"])
            [("a", 0), ("b", 1), ("c", 2)])
        "MOV R1,R0\nDIV R2,R0\nMOV R0,a\n"

    , showTest "Binary: Add with literal second source"
        (generateCode
            (newInstrSeq [mkBinOp "a" (Var "b") Add (Lit 1)] ["a"])
            [("a", 0), ("b", 1)])
        "MOV R1,R0\nADD #1,R0\nMOV R0,a\n"

    , showTest "Binary: src2 variable not in solution (memory mode)"
        (generateCode
            (newInstrSeq [mkBinOp "d" (Var "c") Add (Var "t4")] ["d"])
            [("d", 0), ("t4", 1)])
        "MOV c,R0\nADD R1,R0\nMOV R0,d\n"

    , showTest "Binary: higher register indices"
        (generateCode
            (newInstrSeq [mkBinOp "a" (Var "b") Add (Var "c")] ["a"])
            [("a", 4), ("b", 5), ("c", 6)])
        "MOV R5,R4\nADD R6,R4\nMOV R4,a\n"
    ]

-------------------------------------------------------
-- Store-back instruction tests
-------------------------------------------------------

-- Variables live on exit get a MOV Rn, varname at the end
storeTests :: [TestResult]
storeTests =
    [ showTest "Store: empty live-on-exit produces no stores"
        (generateCode
            (newInstrSeq [mkBinOp "a" (Var "b") Add (Var "c")] [])
            [("a", 0), ("b", 1), ("c", 2)])
        "MOV R1,R0\nADD R2,R0\n"

    , showTest "Store: multiple live-on-exit variables"
        (generateCode
            (newInstrSeq [mkBinOp "a" (Var "b") Add (Var "c")] ["a", "b", "c"])
            [("a", 0), ("b", 1), ("c", 2)])
        "MOV R1,R0\nADD R2,R0\nMOV R0,a\nMOV R1,b\nMOV R2,c\n"

    , showTest "Store: live-on-exit variable not in solution is skipped"
        (generateCode
            (newInstrSeq [] ["x"])
            [])
        ""
    ]

-------------------------------------------------------
-- Sequence tests
-------------------------------------------------------

-- Tests multiple instructions in sequence
sequenceTests :: [TestResult]
sequenceTests =
    [ showTest "Sequence: empty instruction list"
        (generateCode
            (newInstrSeq [] [])
            [])
        ""

    , showTest "Sequence: two instructions chained"
        (generateCode
            (newInstrSeq
                [ mkBinOp "a" (Var "b") Add (Lit 1)
                , mkCopy  "d" (Var "a")
                ] ["d"])
            [("a", 0), ("b", 1), ("d", 1)])
        "MOV R1,R0\nADD #1,R0\nMOV R0,R1\nMOV R1,d\n"

    , showTest "Sequence: all instruction types together"
        (generateCode
            (newInstrSeq
                [ mkBinOp  "a" (Var "b") Add (Var "c")
                , mkUnaryOp "d" (Var "a")
                , mkCopy    "e" (Var "d")
                ] ["e"])
            [("a", 0), ("b", 1), ("c", 2), ("d", 0), ("e", 1)])
        "MOV R1,R0\nADD R2,R0\nMOV #0,R0\nSUB R0,R0\nMOV R0,R1\nMOV R1,e\n"
    ]

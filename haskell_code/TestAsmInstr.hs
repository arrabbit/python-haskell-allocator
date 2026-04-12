-- |
-- Summary: Automated test module for AsmInstr.hs. Runs all test cases and
--     reports pass/fail results with a summary count.
--
-- Authors: Anna Running Rabbit, Jordan Senko, Joseph Mills
-- Date: April 1, 2026

module TestAsmInstr where

import AsmInstr
import TestUtils

-- | Runs all tests and prints results to the terminal
runTests :: IO ()
runTests = do
    putStrLn "========================================="
    putStrLn " AsmInstr.hs - Automated Test Results"
    putStrLn "========================================="
    putStrLn "" -- empty line for spacing

    -- Run tests (excluding expected errors)
    let allResults = tests

    -- Prints each result
    printAllResults allResults

    -- Print summary
    let total = length allResults
    let passed = length (filter (\(TestResult _ b _ _) -> b) allResults)
    let failed = total - passed
    putStrLn "" -- Empty line for spacing
    putStrLn "========================================="
    putStrLn ("  TOTAL: " ++ show total
        ++ " | PASSED: " ++ show passed
        ++ " | FAILED: " ++ show failed)
    putStrLn "========================================="

-------------------------------------------------------
-- Tests
-------------------------------------------------------

tests :: [TestResult]
tests = registerTests ++ srcOpTests ++ dstOpTests
    ++ arithInstrTests ++ movInstrTests ++ programTests ++ equalTests

-- Register tests
registerTests :: [TestResult]
registerTests = 
    [ showTest "Register: valid index (0)"        (mkRegister 0)    "R0"
    , showTest "Register: higher index (5)"       (mkRegister 5)    "R5"
    , eqTest   "Register: boundary index 0 eq"    (mkRegister 0)    (mkRegister 0)]

-- Source operand tests
srcOpTests :: [TestResult]
srcOpTests =
    [ showTest "SrcOperand: immediate 42"          (immSrc 42)                "#42"
    , showTest "SrcOperand: negative immediate"    (immSrc (-3))              "#-3"
    , showTest "SrcOperand: immediate zero"        (immSrc 0)                 "#0"
    , showTest "SrcOperand: variable a"            (varSrc "a")               "a"
    , showTest "SrcOperand: temp variable t1"      (varSrc "t1")              "t1"
    , showTest "SrcOperand: register direct R2"    (regSrc (mkRegister 2))    "R2"]

-- Destination operand tests
dstOpTests :: [TestResult]
dstOpTests =
    [ showTest    "DstOperand: variable d"            (varDst "d")               "d"
    , showTest    "DstOperand: register direct R3"    (regDst (mkRegister 3))    "R3"]

-- Arithmetic instruction tests
arithInstrTests :: [TestResult]
arithInstrTests =
    [ showTest    "Instr: ADD immediate"    (mkAdd (immSrc 1) (mkRegister 0))    
        "ADD #1,R0"
    , showTest    "Instr: SUB register"     (mkSub (regSrc (mkRegister 0)) (mkRegister 1))
        "SUB R0,R1"
    , showTest    "Instr: MUL immediate"    (mkMul (immSrc 4) (mkRegister 1))
        "MUL #4,R1"
    , showTest    "Instr: DIV immediate"    (mkDiv (immSrc 2) (mkRegister 1))
        "DIV #2,R1"
    , showTest    "Instr: ADD variable"     (mkAdd (varSrc "c") (mkRegister 1))
        "ADD c,R1"]

-- MOV instruction tests
movInstrTests :: [TestResult]
movInstrTests =
    [ showTest    "Instr: MOV var to reg"
        (mkMovToReg (varSrc "a")  (mkRegister 0))
        "MOV a,R0"
    , showTest    "Instr: MOV reg to reg"
        (mkMovToReg (regSrc (mkRegister 0)) (mkRegister 1))
        "MOV R0,R1"
    , showTest    "Instr: MOV imm to reg"
        (mkMovToReg (immSrc 10) (mkRegister 2))
        "MOV #10,R2"
    , showTest    "Instr: MOV reg to var"
        (mkMovFromReg (mkRegister 1) (varDst "d"))
        "MOV R1,d"
    , showTest    "Instr: MOV reg to reg(d)"
        (mkMovFromReg (mkRegister 0) (regDst (mkRegister 1)))
        "MOV R0,R1"
    ]

-- Program tests
programTests :: [TestResult]
programTests =
    [ showTest  "Program: empty"
        emptyProgram
        ""
    , showTest  "Program: single instruction"
        (mkProgram [mkAdd (immSrc 1) (mkRegister 0)])
        "ADD #1,R0\n"
    , showTest  "Program: append to empty"
        (appendInstr emptyProgram (mkAdd (immSrc 1) (mkRegister 0)))
        "ADD #1,R0\n"
    , showTest  "Program: append preserves order"
        (appendInstr
            (appendInstr emptyProgram
                (mkMovToReg (varSrc "a") (mkRegister 0)))
            (mkAdd (immSrc 1) (mkRegister 0)))
        "MOV a,R0\nADD #1,R0\n"
    ]

-- Equality tests
equalTests :: [TestResult]
equalTests =
    [ eqTest    "Equality: same register"
        (mkRegister 0) (mkRegister 0)
    , notEqTest "Equality: different registers"
        (mkRegister 0) (mkRegister 1)
    , eqTest    "Equality: same instruction"
        (mkAdd (immSrc 1) (mkRegister 0))
        (mkAdd (immSrc 1) (mkRegister 0))
    , notEqTest "Equality: different instructions"
        (mkAdd (immSrc 1) (mkRegister 0))
        (mkSub (immSrc 1) (mkRegister 0))
    , eqTest    "Equality: same operand"
        (immSrc 1) (immSrc 1)
    ]
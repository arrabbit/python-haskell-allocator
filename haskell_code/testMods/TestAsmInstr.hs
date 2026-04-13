-- |
-- Summary: An automated test module for AsmInstr.hs. Runs a serires of tests
--          and reports pass/fail results.
--
-- Authors: Anna Running Rabbit, Jordan Senko, Joseph Mills
-- Date: April 1, 2026

module TestMods.TestAsmInstr where

import AsmInstr
import TestUtils

-- | Runs all tests and prints results to the terminal
runTests :: IO ()
runTests = do
    putStrLn "========================================="
    putStrLn " AsmInstr.hs - Automated Test Results"
    putStrLn "========================================="
    putStrLn ""

    -- Run all tests
    let allResults = runAlltests

    -- Prints each result
    printAllResults allResults

    -- Print summary
    printSummary allResults

runAlltests :: [TestResult]
runAlltests = showTests ++ instrTests ++ programTests


-------------------------------------------------------
-- Reigster/Operand tests
-------------------------------------------------------

-- | Check that registers and operands display correctly.
showTests :: [TestResult]
showTests = [showTest "Show: register 0"  -- name
             (mkRegister 0)               -- actual
             "R0"                         -- expected
    
            , showTest "Show: register 5"  -- name
              (mkRegister 5)               -- actual
              "R5"                         -- expected
            
            , showTest "Show: immediate source"  -- name
              (immSrc 42)                        -- actual
              "#42"                              -- expected
            
            , showTest "Show: variable source"  -- name
              (varSrc "a")                      -- actual
              "a"                               -- expected
            
            , showTest "Show: register source"  -- name
              (regSrc (mkRegister 1))           -- actual
              "R1"                              -- expected
            
            , showTest "Show: variable destination"  -- name
              (varDst "d")                           -- actual
              "d"]                                   -- expected

-------------------------------------------------------
-- Instruction tests
-------------------------------------------------------

instrTests :: [TestResult]
instrTests = [showTest "Instr: ADD immediate to register"  -- name
              (mkAdd (immSrc 1) (mkRegister 0))            -- actual
              "ADD #1,R0"                                  -- expected
             
             , showTest "Instr: SUB register from register"    -- name 
               (mkSub (regSrc (mkRegister 0)) (mkRegister 1))  -- actual
               "SUB R0,R1"                                     -- expected
             
             , showTest "Instr: MUL with variable source"  -- name
               (mkMul (varSrc "a") (mkRegister 2))         -- actual
               "MUL a,R2"                                  -- expected
             
             , showTest "Instr: DIV immediate"    -- name
               (mkDiv (immSrc 2) (mkRegister 1))  -- actual
               "DIV #2,R1"                        -- expected
             
             , showTest "Instr: MOV variable into register"  -- name
               (mkMovToReg (varSrc "a") (mkRegister 0))      -- actual
               "MOV a,R0"                                    -- expected
             
             , showTest "Instr: MOV register to variable"  -- name
               (mkMovFromReg (mkRegister 1) (varDst "d"))  -- actual
               "MOV R1,d"]                                 -- expected

-------------------------------------------------------
-- Program tests
-------------------------------------------------------

-- | Check that programs build and display properly.
programTests :: [TestResult]
programTests = [showTest "Program: empty program"  -- name
                emptyProgram                       -- actual
                ""                                 -- expected
    
               , showTest "Program: single instruction"         -- name
                 (mkProgram [mkAdd (immSrc 1) (mkRegister 0)])  -- actual
                 "ADD #1,R0\n"                                  -- expected
               
               , showTest "Program: append instruction"                             -- name
                 (appendInstr (mkProgram [mkMovToReg (varSrc "a") (mkRegister 0)])  -- actual
                              (mkAdd (immSrc 1) (mkRegister 0)))
                 "MOV a,R0\nADD #1,R0\n"                                            -- expected
               
               , eqTest "Program: mkProgram equals appended"                        -- name
                 (mkProgram [mkMovToReg (varSrc "a") (mkRegister 0),                
                             mkAdd (immSrc 1) (mkRegister 0)])                      -- actual
                 (appendInstr (mkProgram [mkMovToReg (varSrc "a") (mkRegister 0)])
                              (mkAdd (immSrc 1) (mkRegister 0)))]                   -- expected
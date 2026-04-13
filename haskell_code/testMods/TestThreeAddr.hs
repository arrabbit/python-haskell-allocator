-- |
-- Summary: Automated test module for ThreeAddr.hs. Runs a series of tests and
--          reports pass/fail results.
--
-- Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
-- Date: April 4, 2026

module TestMods.TestThreeAddr where

import ThreeAddr
import TestMods.TestUtils

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
runAllTests = showInstrTests ++ getterTests ++ seqTests

-------------------------------------------------------
-- Instruction tests
-------------------------------------------------------

-- | Checks that each instruction type displays correctly.
showInstrTests :: [TestResult]
showInstrTests = [strTest "showInstr: binary add"                  -- name
                  (showInstr (mkBinOp "a" (Var "a") Add (Lit 1)))  -- actual
                  "a = a + 1"                                      -- expected
                 
                 , strTest "showInstr: binary mul with temp var"     -- name
                   (showInstr (mkBinOp "t1" (Var "a") Mul (Lit 4)))  -- actual
                   "t1 = a * 4"                                      -- expected
                    
                 , strTest "showInstr: unary negation"    -- name
                   (showInstr (mkUnaryOp "b" (Var "a")))  -- actual
                   "b = -a"                               -- expected
                  
                 , strTest "showInstr: copy with literal"  -- name
                   (showInstr (mkCopy "a" (Lit 5)))        -- actual
                   "a = 5"                                 -- expected

                 , strTest "showInstr: copy with variable"  -- name
                   (showInstr (mkCopy "a" (Var "b")))       -- actual
                   "a = b"]                                 -- expected

-------------------------------------------------------
-- Getter tests
-------------------------------------------------------

-- | Checks that the getter functions pull the right parts out.
getterTests :: [TestResult]
getterTests = [strTest "getDest: binary instruction"            -- name
               (getDest (mkBinOp "a" (Var "b") Add (Var "c")))  -- actual
               "a"                                              -- expected
               
              , strTest "getDest: copy instruction"  -- name
                (getDest (mkCopy "x" (Lit 10)))      -- actual
                "x"                                  -- expected
               
              , eqTest "getSrc1: binary instruction"             -- name
                (getSrc1 (mkBinOp "a" (Var "b") Add (Var "c")))  -- actual
                (Var "b")
              
              , eqTest "getOp: binary returns Just"            -- name
                (getOp (mkBinOp "a" (Var "b") Add (Var "c")))  -- actual
                (Just Add)                                     -- expected
        
              , eqTest "getOp: copy returns Nothing"  -- name
                (getOp (mkCopy "x" (Lit 10)))         -- actual
                Nothing                               -- expected
              
              , strTest "instrType: binary"                        -- name
                (instrType (mkBinOp "a" (Var "b") Add (Var "c")))  -- actual
                "binary"                                           -- expected
              
              , strTest "instrType: unary"             -- name
                (instrType (mkUnaryOp "b" (Var "a")))  -- actual
                "unary"]                               -- expected

-------------------------------------------------------
-- InstrSeq tests
-------------------------------------------------------

-- | Checks that an InstrSeq stores and displays its contents.
seqTests :: [TestResult]
seqTests = [eqTest "getInstrs: check length"                               -- name
            (length (getInstrs (newInstrSeq [mkCopy "a" (Lit 5)] ["a"])))  -- actual
            1                                                              -- expected
    
           , eqTest "getLiveOut: single variable"                   -- name
             (getLiveOut (newInstrSeq [mkCopy "a" (Lit 5)] ["a"]))  -- actual
             ["a"]                                                  -- expected
    
           , eqTest "getLiveOut: empty list"                     -- name
             (getLiveOut (newInstrSeq [mkCopy "a" (Lit 5)] []))  -- actual
             []]                                                 -- expected
-- |
--  Summary: An automated test module for Tokenizer.hs. Runs a series of tests
--           and creates a pass/fail result report.
--
--  Authors: Anna Running Rabbit, Jordan Senko, Joseph Mills
--  Date: April 12, 2026

module TestTokenizer where

import Tokenizer
import TestUtils 

-- | Runs all tests and prints results to the terminal
runTests :: IO ()
runTests = do
    putStrLn "========================================="
    putStrLn " Tokenizer.hs - Automated Test Results"
    putStrLn "========================================="
    putStrLn ""

    -- Run all tests
    let results = runAllTests

    -- Print each result
    printAllResults results

    -- Print summary
    printSummary results

runAllTests :: [TestResult]
runAllTests = binTest ++ digitTest ++ tempVarTest ++ liveVarTest ++ oneLiveTest
              ++ empLiveTest ++ multiLnTest

-------------------------------------------------------
-- All tests
-------------------------------------------------------

-- | Simple binary equation test.
binTest :: [TestResult]
binTest = [eqTest "Tokenize: simple binary equation: "                        -- name
           (tokenize "a = b + c")                                             -- actual
           [TokVar "a", TokEq, TokVar "b", TokOp '+', TokVar "c", TokNewLn]]  -- expected

-- | Copy test with a digit.
digitTest :: [TestResult]
digitTest = [eqTest "Tokenize: copy test with a digit: "  -- name
             (tokenize "a = 5")                           -- actual
             [TokVar "a", TokEq, TokLit 5, TokNewLn]]     -- expected

-- | Temp variable test.
tempVarTest :: [TestResult]
tempVarTest = [eqTest "Tokenize: temp variable: "                                -- name
               (tokenize "t1 = a * 4")                                           -- actual
               [TokVar "t1", TokEq, TokVar "a", TokOp '*', TokLit 4, TokNewLn]]  -- expected

-- | Live variables test.
liveVarTest :: [TestResult]
liveVarTest = [eqTest "Tokenize: live variables: "                           -- name
               (tokenize "live: a, b")                                       -- actual
               [TokLive, TokCol, TokVar "a", TokCom, TokVar "b", TokNewLn]]  -- expected

-- | Single live variable test.
oneLiveTest :: [TestResult]
oneLiveTest = [eqTest "Tokenize: single live variable: "  -- name
               (tokenize "live: c")                       -- actual
               [TokLive, TokCol, TokVar "c", TokNewLn]]   -- expected

-- | Empty live line test.
empLiveTest :: [TestResult]
empLiveTest = [eqTest "Tokenize: empty live line: "  -- name
               (tokenize "live:")                    -- actual
               [TokLive, TokCol, TokNewLn]]          -- expected

-- | Multiple line input test.
multiLnTest :: [TestResult]
multiLnTest = [eqTest "tokenize: multiple line input: "                  -- name
               (tokenize "a = 5\nlive: a")                               -- actual
               [TokVar "a", TokEq, TokLit 5, TokNewLn, TokLive, TokCol,
                TokVar "a", TokNewLn]]                                   -- expected
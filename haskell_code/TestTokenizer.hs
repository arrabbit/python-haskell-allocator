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
runAllTests =

-------------------------------------------------------
-- All tests
-------------------------------------------------------

-- | Simple binary equation test.
binTest :: [TestResult]
binTest 

-- | 
digitTest :: [TestResult]
-- |
--  Summary: An automated test module for Parser.hs. Runs a series of tests
--           and creates a pass/fail result report.
--
--  Authors: Anna Running Rabbit, Jordan Senko, Joseph Mills
--  Date: April 12, 2026

module TestParser where

import Tokenizer
import Parser
import TestData
import TestUtils 

-- | Runs all tests and prints results to the terminal
runTests :: IO ()
runTests = do
    putStrLn "========================================="
    putStrLn " Parser.hs - Automated Test Results"
    putStrLn "========================================="
    putStrLn ""

    -- Run all tests
    let results = runAllTests

    -- Print each result
    printAllResults results

    -- Print summary
    printSummary results

runAllTests :: [TestResult]
runAllTests = specExTest ++ unaryTest ++ empLiveTest

-- the spec example input as a string, matches testSpecExample in TestData.hs
specExampleText :: String
specExampleText = unlines ["a = a + 1"
                           , "t1 = a * 4"
                           , "t2 = t1 + 1"
                           , "t3 = a * 3"
                           , "b = t2 - t3"
                           , "t4 = b / 2"
                           , "d = c + t4"
                           , "live: d"]

-------------------------------------------------------
-- All tests
-------------------------------------------------------

-- | Spec example test.
specExTest :: [TestResult]
specExTest = [eqTest "Parse: spec example: "      -- name
              (parse (tokenize specExampleText))  -- actual
              testSpecExample]                    -- expected

-- | Unary negation test.
unaryTest :: [TestResult]
unaryTest = [eqTest "Parse: unary negation: "                  -- name
             (parse (tokenize "a = 5\nb = -a\nlive: a, b"))  -- actual
             testUnary]                                      -- expected

-- | Empty live line test.
empLiveTest :: [TestResult]
empLiveTest = [eqTest "Parse: empty live line: "        -- name
               (parse (tokenize "a = b + c\nlive:"))  -- actual
               testEmptyLive]                         -- expected
-- |
-- Summary: Automated test module for AsmInstr.hs. Runs all test cases and
--     reports pass/fail results with a summary count/
--
-- Authors: Anna Running Rabbit, Jordan Senko, Joseph Mills
-- Date: April 1, 2026

module TestAsmInstr where

import AsmInstr
import Control.Exception (evaluate, try, SomeException)

-- | A single test case: a name, and a pass/fail results
data TestResult = TestResult String Bool

-- | Runs all tests and prints results to the terminal
runTests :: IO ()
runTests = do
    putStrLn "========================================="
    putStrLn " AsmInstr.hs - Automated Test Results"
    putStrLn "========================================="
    putStrLn "" -- empty line for spacing

    -- Run tests with no error handling necessary
    let noErrResults = runNoErrTests

    -- Run tests with error handling
    let errResults <- runNoErrTests

    let allResults = noErrResults ++ errResults

    -- Prints each result
    printAllResults allResults

    -- Print summary
    let total = length allResults
    let passed = length (filter (\(TestResult _ b) -> b) allResults)
    let failed = total - passed
    putStrLn "" -- Empty line for spacing
    putStrLn "========================================="
    putStrLn "  TOTAL: " ++ show total
        ++ " | PASSED: " ++ show passed
        ++ " | FAILED: " ++ show failed
    putStrLn "========================================="

-- | Prints a single test result as PASS or FAILED
printResult :: TestResult -> IO ()
printResult (TestResult name True) = putStrLn ("  PASS: " ++ name)
printResult (TestResult name False) = putStrLn ("  FAIL: " ++ name)

-- | Moves through list of test results and prints each
printAllResults :: [TestResult] -> IO ()
printAllResults [] = return ()
printAllResults (x:xs) = do
    printResult x
    printAllResults rs
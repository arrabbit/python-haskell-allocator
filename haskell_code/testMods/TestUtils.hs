-- |
-- Summary: Shared testing framework and utility functions for the compiler project.
--     Provides the core data types, assertion functions, and console output
--     formatting used across all automated test modules.
--
-- Authors: Anna Running Rabbit, Jordan Senko, Joseph Mills
-- Date: April 2026

module TestUtils 
    ( TestResult(..)
    , printResult
    , printAllResults
    , printSummary
    , cleanResults
    , showTest
    , strTest
    , eqTest
    , notEqTest
    , boolTest
    ) where

-- | A single test case: a name, a pass/fail boolean, actual string, expected string
data TestResult = TestResult String Bool String String

-- | Prints a single test result as PASS or FAIL
printResult :: TestResult -> IO ()
printResult (TestResult name True actual _) =
    putStrLn ("  PASS - " ++ name ++ " => " ++ cleanResults actual)
printResult (TestResult name False actual expected) = do
    putStrLn ("  FAIL - " ++ name)
    putStrLn ("        Expected: " ++ cleanResults expected)
    putStrLn ("        Actual:   " ++ cleanResults actual)

-- | Moves through list of test results and prints each sequentially
printAllResults :: [TestResult] -> IO ()
printAllResults [] = return ()
printAllResults (x:xs) = do
    printResult x
    printAllResults xs

-- | Prints a pass/fail summary count for a list of test results
printSummary :: [TestResult] -> IO ()
printSummary results = do
    let total = length results
    let passed = length (filter (\(TestResult _ b _ _) -> b) results)
    let failed = total - passed
    putStrLn ""
    putStrLn "========================================="
    putStrLn ("  TOTAL: " ++ show total
        ++ " | PASSED: " ++ show passed
        ++ " | FAILED: " ++ show failed)
    putStrLn "========================================="

-- | Replaces newline characters with the visible text '\n' for clean console output
cleanResults :: String -> String
cleanResults [] = []
cleanResults ('\n':rest) = '\\' : 'n' : cleanResults rest
cleanResults (c:rest) = c : cleanResults rest

-------------------------------------------------------
-- Helper Functions
-------------------------------------------------------

-- | Compares the 'show' output of an actual value to an expected string
showTest :: (Show a) => String -> a -> String -> TestResult
showTest name actual expected =
    TestResult name (show actual == expected) (show actual) expected

-- | Compares an actual string value directly to an expected string
strTest :: String -> String -> String -> TestResult
strTest name actual expected =
    TestResult name (actual == expected) actual expected

-- | Checks that two values of the same type are exactly equal
eqTest :: (Show a, Eq a) => String -> a -> a -> TestResult
eqTest name actual expected =
    TestResult name (actual == expected) (show actual) (show expected)

-- | Checks that two values of the same type are NOT equal
notEqTest :: (Show a, Eq a) => String -> a -> a -> TestResult
notEqTest name val1 val2 =
    TestResult name (val1 /= val2) (show val1) ("not " ++ show val2)

-- | Compares two boolean values (useful for checking if lists/solutions are null)
boolTest :: String -> Bool -> Bool -> TestResult
boolTest name actual expected =
    TestResult name (actual == expected) (show actual) (show expected)
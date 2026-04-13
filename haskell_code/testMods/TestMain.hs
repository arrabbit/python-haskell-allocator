-- Tests for Main.hs. Since Main can't be imported, we copy the two
-- pure functions here and test them directly. Integration tests run
-- the full pipeline using the other modules.
-- IO stuff (run, readInputFile, abort) is covered by manual testing.
--
-- Authors: Joseph Mills
-- Date: April 12, 2026

module TestMain where

import Data.List           (intercalate)

import Tokenizer           (tokenize)
import Parser              (parse)
import GraphBuilder        (buildGraph)
import Allocator           (allocate)
import Codegen             (generateCode)
import TestMods.TestUtils


-- | Runs all tests and prints results to the terminal
runTests :: IO ()
runTests = do
    putStrLn "========================================="
    putStrLn " Main.hs - Automated Test Results"
    putStrLn "========================================="
    putStrLn ""
    let results = runAllTests
    printAllResults results
    printSummary results

runAllTests :: [TestResult]
runAllTests = parseNumRegsTests ++ colourTableTests ++ integrationTests


-- copied from Main since we can't import it
parseNumRegs :: String -> Int
parseNumRegs numRegistersStr = case reads numRegistersStr of
    [(n, "")] | n > 0 -> n
    _                 -> error "num_regs must be a positive integer greater than zero"


parseNumRegsTests :: [TestResult]
parseNumRegsTests =
    [ eqTest "parseNumRegs: single digit"
        (parseNumRegs "3")
        3

    , eqTest "parseNumRegs: larger number"
        (parseNumRegs "10")
        10

    , eqTest "parseNumRegs: one register"
        (parseNumRegs "1")
        1
    ]


-- copied from Main since we can't import it
colourTable :: Int -> [(String, Int)] -> String
colourTable numRegisters solution =
    unlines [ "R" ++ show regNum ++ ": " ++ intercalate ", " (varsInReg regNum)
            | regNum <- [0 .. numRegisters - 1]
            , not (null (varsInReg regNum)) ]
    where
        varsInReg regNum = [ varName | (varName, reg) <- solution, reg == regNum ]


colourTableTests :: [TestResult]
colourTableTests =
    [ strTest "colourTable: one var per register"
        (colourTable 3 [("a", 0), ("b", 1), ("c", 2)])
        "R0: a\nR1: b\nR2: c\n"

    , strTest "colourTable: two vars in same register"
        (colourTable 2 [("a", 0), ("b", 0), ("c", 1)])
        "R0: a, b\nR1: c\n"

    , strTest "colourTable: unused register skipped"
        (colourTable 3 [("a", 0), ("b", 2)])
        "R0: a\nR2: b\n"

    , strTest "colourTable: empty solution"
        (colourTable 3 [])
        ""
    ]


-- full pipeline tests: tokenize -> parse -> buildGraph -> allocate
integrationTests :: [TestResult]
integrationTests =
    [ boolTest "Integration: plain input allocates with 3 registers"
        (not (null (allocate (buildGraph (parse (tokenize plainInput))) 3)))
        True

    , boolTest "Integration: plain input fails with 1 register"
        (null (allocate (buildGraph (parse (tokenize plainInput))) 1))
        True

    , boolTest "Integration: spec example allocates with 4 registers"
        (not (null (allocate (buildGraph (parse (tokenize specInput))) 4)))
        True

    , boolTest "Integration: spec example fails with 3 registers"
        (null (allocate (buildGraph (parse (tokenize specInput))) 3))
        True

    , boolTest "Integration: empty program allocates with 1 register"
        (not (null (allocate (buildGraph (parse (tokenize emptyInput))) 1)))
        True
    ]

-- 3 variables all live at the same time, need 3 registers
plainInput :: String
plainInput = unlines
    [ "a = 1"
    , "b = 2"
    , "c = 3"
    , "live: a, b, c"
    ]

-- the example from the project spec
specInput :: String
specInput = unlines
    [ "a = a + 1"
    , "t1 = a * 4"
    , "t2 = t1 + 1"
    , "t3 = a * 3"
    , "b = t2 - t3"
    , "t4 = b / 2"
    , "d = c + t4"
    , "live: d"
    ]

-- nothing but the live line
emptyInput :: String
emptyInput = "live:"

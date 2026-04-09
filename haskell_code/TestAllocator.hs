-- |
--  Summary: An automated test module for Allocator.hs. Runs a series of tests
--           and creates a pass/fail result report with a summary count.
--
--  Authors: Anna Running Rabbit, Jordan Senko, Joseph Mills
--  Date: April 9, 2026

module TestAllocator where

import Allocator
import Variable (Variable, getVarName, getAdjacent)
import InterferenceGraph (IGraph, emptyGraph, addVariable, addEdge, getVariables)
import TestUtils

-- | Runs all tests and prints results to the terminal
runTests :: IO ()
runTests = do
    putStrLn "========================================="
    putStrLn " Allocator.hs - Automated Test Results"
    putStrLn "========================================="
    putStrLn "" 

    let results = allocatorTests
    printAllResults results

    -- Print summary
    let total = length results
    let passed = length (filter (\(TestResult _ b _ _) -> b) results)
    let failed = total - passed
    putStrLn "" 
    putStrLn "========================================="
    putStrLn ("  TOTAL: " ++ show total
        ++ " | PASSED: " ++ show passed
        ++ " | FAILED: " ++ show failed)
    putStrLn "========================================="

-------------------------------------------------------
-- Test Helpers
-------------------------------------------------------

-- | Checks that every pair of interfering variables has different register assignments
isValidColouring :: IGraph -> ColourSol -> Bool
isValidColouring graph colouring =
    all checkVar (getVariables graph)
  where
    checkVar var =
        let colour = lookup (getVarName var) colouring
            adjColours = map (`lookup` colouring) (getAdjacent var)
        in all (/= colour) adjColours

-------------------------------------------------------
-- Mock Graphs for Testing
-------------------------------------------------------

-- 1. Empty Graph
graphEmpty :: IGraph
graphEmpty = emptyGraph

-- 2. Two non-interfering variables (x, y)
graphNoEdges :: IGraph
graphNoEdges = addVariable "x" (addVariable "y" emptyGraph)

-- 3. Two interfering variables (x <-> y)
graphOneEdge :: IGraph
graphOneEdge = addEdge "x" "y" emptyGraph

-- 4. Spec Example Mock Graph
-- Based on the project spec example. We add all interfering edges
-- and an isolated variable 'd' which is live on exit but doesn't conflict.
graphSpec :: IGraph
graphSpec = 
    let g1 = foldl (\g (u, v) -> addEdge u v g) emptyGraph edges
    in addVariable "d" g1
  where
    edges = [ ("a", "c"), ("a", "t1"), ("a", "t2")
            , ("c", "t1"), ("c", "t2"), ("c", "t3"), ("c", "b"), ("c", "t4")
            , ("t2", "t3") ]

-------------------------------------------------------
-- Allocator tests
-------------------------------------------------------

allocatorTests :: [TestResult]
allocatorTests =
    [ 
      -- Test 1: Empty graph, 2 registers -> Exactly one solution (the empty colouring)
      showTest "Empty graph, 2 registers" 
        (allocate graphEmpty 2) 
        "[[]]"

      -- Test 2: Two non-interfering variables, 1 register -> Solutions exist
    , boolTest "2 non-interfering vars, 1 reg (has solution)" 
        (not (null (allocate graphNoEdges 1))) 
        True

      -- Test 3: Two interfering variables, 1 register -> No solution ([])
    , showTest "2 interfering vars, 1 reg" 
        (allocate graphOneEdge 1) 
        "[]"

      -- Test 4: Two interfering variables, 2 registers -> Solutions exist
    , boolTest "2 interfering vars, 2 regs (has solution)" 
        (not (null (allocate graphOneEdge 2))) 
        True

      -- Test 4b: Verify the validity of the colouring for Test 4
    , boolTest "2 interfering vars, 2 regs (solution is valid)" 
        (isValidColouring graphOneEdge (head (allocate graphOneEdge 2))) 
        True

      -- Test 5: Spec example, 2 registers -> At least one valid colouring
    , boolTest "Spec example graph, 2 regs (has solution)" 
        (not (null (allocate graphSpec 2))) 
        True

      -- Test 5b: Verify the validity of the colouring for Spec Example
    , boolTest "Spec example graph, 2 regs (solution is valid)" 
        (isValidColouring graphSpec (head (allocate graphSpec 2))) 
        True
    ]
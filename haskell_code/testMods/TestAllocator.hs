-- |
--  Summary: An automated test module for Allocator.hs. Runs a series of tests
--           and creates a pass/fail result report.
--
--  Authors: Anna Running Rabbit, Jordan Senko, Joseph Mills
--  Date: April 9, 2026

module TestMods.TestAllocator where

import Allocator
import InterferenceGraph
import TestUtils

-- | Runs all tests and prints results to the terminal
runTests :: IO ()
runTests = do
    putStrLn "========================================="
    putStrLn " Allocator.hs - Automated Test Results"
    putStrLn "========================================="
    putStrLn "" 

    let results = runAllTests
    printAllResults results

    -- Print summary
    printSummary results

runAllTests :: [TestResult]
runAllTests = emptyTests ++ noEdgeTests ++ oneEdgeTests ++ notEnoughTests

-------------------------------------------------------
-- Test graphs
-------------------------------------------------------

-- two variables that don't interfere
graphNoEdge :: IGraph
graphNoEdge = addVariable "a" (addVariable "b" emptyGraph)

-- two variables that do interfere (a <-> b)
graphOneEdge :: IGraph
graphOneEdge = addEdge "a" "b" emptyGraph

-- three variables all interfering (a <-> b, b <-> c, a <-> c)
graphTriangle :: IGraph
graphTriangle = addEdge "a" "b" (addEdge "b" "c" (addEdge "a" "c" emptyGraph))

-------------------------------------------------------
-- All tests
-------------------------------------------------------

-- | Empty graph should give back one solution with no assignments.
emptyTests :: [TestResult]
emptyTests = [eqTest "Allocate: empty graph: "  -- name
              (allocate emptyGraph 2)           -- actual
              [[]]]                             -- expected

-- | Two variables with no edge can share the same register.
noEdgeTests :: [TestResult]
noEdgeTests = [boolTest "Allocate: no edge, 1 register"  -- name
               (not (null (allocate graphNoEdge 1)))     -- actual
               True                                      -- expected
              
              , boolTest "Allocate: no edge, 2 registers"  -- name
                (not (null (allocate graphNoEdge 2)))      -- actual
                True]                                      -- expected

-- | Two variables with an edge need at least 2 registers.
oneEdgeTests :: [TestResult]
oneEdgeTests = [boolTest "Allocate: one edge, 1 register: "  -- name
                (null (allocate graphOneEdge 1))             -- actual
                True                                         -- expected
    
               , boolTest "Allocate: one edge, 2 registers: "  -- name
                 (not (null (allocate graphOneEdge 2)))        -- actual
                 True]                                         -- expected

-- | Triangle graph needs at least 3 registers.
notEnoughTests :: [TestResult]
notEnoughTests = [boolTest "Allocate: triangle, 2 registers: "  -- name
                  (null (allocate graphTriangle 2))             -- actual
                  True                                          -- expected
    
                 , boolTest "Allocate: triangle, 3 registers: "  -- name
                   (not (null (allocate graphTriangle 3)))       -- actual
                   True]                                         -- expected
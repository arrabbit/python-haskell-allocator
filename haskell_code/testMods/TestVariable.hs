-- Tests for Variable.hs
-- Covers newVariable, getVarName, getAdjacent, addAdjacent, and Show

module TestMods.TestVariable where

import Data.List (sort)

import Variable  (Variable, newVariable, getVarName, getAdjacent, addAdjacent)
import TestMods.TestUtils (TestResult, printAllResults, printSummary,
                  eqTest, boolTest, strTest)

runTests :: IO ()
runTests = do
    putStrLn "============================"
    putStrLn " Variable.hs - Test Results"
    putStrLn "============================"
    putStrLn ""
    
    printAllResults variableTests
    printSummary variableTests

variableTests :: [TestResult]
variableTests =

    [
        -- newVariable
        eqTest "newVariable: name is stored correctly"
        (getVarName (newVariable "x")) "x",

        eqTest "newVariable: temp-style name stored correctly"
        (getVarName (newVariable "t1")) "t1",

        boolTest "newVariable: adj list starts empty"
        (null (getAdjacent (newVariable "a"))) True,

        -- getVarName
        eqTest "getVarName: returns correct name"
        (getVarName (newVariable "abc")) "abc",

        -- getAdjacent
        eqTest "getAdjacent: new var has no neighbs"
        (getAdjacent (newVariable "b")) [],

        -- addAdjacent
        eqTest "addAdjacent: single neighb is added"
        (getAdjacent (addAdjacent "y" (newVariable "x"))) ["y"],

        eqTest "addAdjacent: two neighbs stored"
        (sort (getAdjacent (addAdjacent "z" (addAdjacent "y" (newVariable "x")))))
        ["y", "z"],

        boolTest "addAdjacent: duplicate neighb not stored twice"
        (length (getAdjacent (addAdjacent "y" (addAdjacent "y" (newVariable "x")))) == 1) True,

        -- Show instance
        strTest "show: no neighbours displays as 'name: (none)'"
        (show (newVariable "a")) "a: (none)",

        strTest "show: one neighbour displays correctly"
        (show (addAdjacent "b" (newVariable "a"))) "a: b"
    ]
-- Tests for InterferenceGraph.hs.
-- Covers emptyGraph, addVariable, addEdge, getVariable, getVariables, showGraph.

module TestMods.TestIGraph where

import Data.List  (sort)
import Data.Maybe (isJust, isNothing) 

import Variable          (getVarName, getAdjacent)
import InterferenceGraph (IGraph, emptyGraph, addVariable, addEdge,
                          getVariables, getVariable, showGraph)
import TestMods.TestUtils         (TestResult, printAllResults, printSummary,
                          eqTest, boolTest, strTest)

runTests :: IO ()
runTests = do
    putStrLn "====================================="
    putStrLn " InterferenceGraph.hs - Test Results"
    putStrLn "====================================="
    putStrLn ""

    printAllResults igraphTests
    printSummary igraphTests

-- sorted variable names in a graph for order-independent checks
varNames :: IGraph -> [String]
varNames = sort . map getVarName . getVariables

-- sorted adjacency list for a named variable in a graph
adjOf :: String -> IGraph -> [String]
adjOf name graph = case getVariable name graph of
    Just v  -> sort (getAdjacent v)
    Nothing -> []

-- true if both directions of an edge exist
hasEdge :: String -> String -> IGraph -> Bool
hasEdge n1 n2 graph =
    n1 `elem` adjOf n2 graph &&
    n2 `elem` adjOf n1 graph

igraphTests:: [TestResult]
igraphTests = 
    [
        boolTest "emptyGraph: has no variables"
        (null (getVariables emptyGraph)) True,
        
        -- addVariable
        boolTest "addVariable: graph grows by one node"
        (length (getVariables (addVariable "a" emptyGraph)) == 1) True,

        boolTest "addVariable: two unique names produce two nodes"
        (length (getVariables (addVariable "b" (addVariable "a" emptyGraph))) == 2) True,

        boolTest "addVariable: duplicate name is ignored"
        (length (getVariables (addVariable "a" (addVariable "a" emptyGraph))) == 1) True,

        boolTest "addVariable: new node has empty adjacency list"
        (null (adjOf "a" (addVariable "a" emptyGraph))) True,

        -- getVariable
        boolTest "getVariable: returns Just for a present var"
        (isJust (getVariable "a" (addVariable "a" emptyGraph))) True,

        boolTest "getVariable: returns Nothing for a non-existent var"
        (isNothing (getVariable "z" (addVariable "a" emptyGraph))) True,

        boolTest "getVariable: correct var returned from graph"
        (case getVariable "b" (addVariable "b" (addVariable "a" emptyGraph)) of
            Just v  -> getVarName v == "b"
            Nothing -> False) True,

        --getVariables
        eqTest "getVariables: returns all node names"
        (varNames (addVariable "c" (addVariable "b" (addVariable "a" emptyGraph))))
        ["a", "b", "c"],

        -- addEge
        eqTest "addEdge: both variables appear as nodes"
        (varNames (addEdge "a" "b" emptyGraph)) ["a", "b"],

        boolTest "addEdge: b is in a's adjacency list"
        ("b" `elem` adjOf "a" (addEdge "a" "b" emptyGraph)) True,

        boolTest "addEdge: a is in b's adjacency list"
        ("a" `elem` adjOf "b" (addEdge "a" "b" emptyGraph)) True,

        -- three interfering variables
        boolTest "addEdge: three mutually interfering variables all connected"
        (let g = addEdge "a" "c" (addEdge "b" "c" (addEdge "a" "b" emptyGraph))
         in hasEdge "a" "b" g && hasEdge "b" "c" g && hasEdge "a" "c" g) True,

        -- showGraph
        strTest "showGraph: empty graph shows empty message"
        (showGraph emptyGraph) "   (empty graph)",

        boolTest "showGraph: non-empty graph output contains variable names"
        (let g = addEdge "a" "b" emptyGraph
         in any ("a" `elem`) (map words (lines (showGraph g)))) True
    ]
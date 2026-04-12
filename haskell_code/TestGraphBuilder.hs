-- Testing file for GraphBuilder.hs
-- buildGraph of GraphBuilder takes an InstrSeq and produces an IGraph

module TetsGraphBuilder where

import Data.List (sort)
import Data.Maybe (isJust, isNothing)

import Variable          (getVarName, getAdjacent)
import InterferenceGraph (IGraph, emptyGraph, getVariables, getVariable)
import GraphBuilder      (buildGraph)
import ThreeAddr         (Operand(..), Op(..), InstrSeq, Instr,
                          mkBinOp, mkUnaryOp, mkCopy, newInstrSeq)
import TestUtils         (TestResult, printAllResults, printSummary,
                          eqTest, boolTest)

main :: IO ()
main = do
    putStrLn "========================================="
    putStrLn " GraphBuilder.hs - Automated Test Results"
    putStrLn "========================================="
    putStrLn ""
    
    printAllResults graphBuilderTests
    printSummary graphBuilderTests

-- returns sorted names of nodes in a graph
varNames:: IGraph -> [String]
varNames = sort . map getVarName . getVariables

-- returns sorted adjacency list of a named node
adjOf:: String -> IGraph -> [String]
adjOf name graph = case getVariable name graph of
    Just v  -> sort (getAdjacent v)
    Nothing -> []

-- true if n1 and n2 appear in each other's adjacency lists
hasEdge:: String -> String -> IGraph -> Bool
hasEdge n1 n2 graph =
    n1 `elem` adjOf n2 graph &&
    n2 `elem` adjOf n1 graph

-- the seven-instruction program from the project spec example
-- used across multiple tests below
specInstrs :: [Instr]
specInstrs =
    [ mkBinOp "a"  (Var "a")  Add (Lit 1)       -- a  = a + 1
    , mkBinOp "t1" (Var "a")  Mul (Lit 4)       -- t1 = a * 4
    , mkBinOp "t2" (Var "t1") Add (Lit 1)       -- t2 = t1 + 1
    , mkBinOp "t3" (Var "a")  Mul (Lit 3)       -- t3 = a * 3
    , mkBinOp "b"  (Var "t2") Sub (Var "t3")    -- b  = t2 - t3
    , mkBinOp "t4" (Var "b")  Div (Lit 2)       -- t4 = b / 2
    , mkBinOp "d"  (Var "c")  Add (Var "t4")    -- d  = c + t4
    ]

specSeq :: InstrSeq
specSeq = newInstrSeq specInstrs ["d"]   -- d is live on exit

specGraph :: IGraph
specGraph = buildGraph specSeq

graphBuilderTests :: [TestResult]
graphBuilderTests =

    -- empty program edge cases
    [ boolTest "empty program, no live-outs: graph is empty"
        (null (getVariables (buildGraph (newInstrSeq [] [])))) True

    , boolTest "empty program, one live-out: that variable is a node"
        (isJust (getVariable "x" (buildGraph (newInstrSeq [] ["x"])))) True

    , boolTest "empty program, one live-out: no edges"
        (null (adjOf "x" (buildGraph (newInstrSeq [] ["x"])))) True

    -- two live-outs interfere because they are simultaneously live
    , boolTest "empty program, two live-outs: both variables are nodes"
        (let g = buildGraph (newInstrSeq [] ["x", "y"])
         in isJust (getVariable "x" g) && isJust (getVariable "y" g)) True

    , boolTest "empty program, two live-outs: they interfere with each other"
        (hasEdge "x" "y" (buildGraph (newInstrSeq [] ["x", "y"]))) True

    -- a variable that is defined but never used and not live-out has no node
    , boolTest "dead variable: defined but never used, not in graph"
        (isNothing (getVariable "x" (buildGraph (newInstrSeq [mkCopy "x" (Lit 1)] [])))) True

    -- Lit operands don't produce nodes
    , boolTest "literal operand: no node created for Lit"
        (null (getVariables (buildGraph (newInstrSeq [mkCopy "x" (Lit 5)] [])))) True

    -- live-out variable that isn't defined in the block still gets a node
    , boolTest "live-out not defined in block: still has a node"
        (isJust (getVariable "x" (buildGraph (newInstrSeq [] ["x"])))) True

    -- single unary instr
    , boolTest "unary instr: src variable is added as a node"
        (isJust (getVariable "a" (buildGraph (newInstrSeq [mkUnaryOp "t1" (Var "a")] ["t1"])))) True

    , boolTest "unary instr: src interferes with live-out dest"
        (hasEdge "a" "t1" (buildGraph (newInstrSeq [mkUnaryOp "t1" (Var "a")] ["t1"]))) True

    -- a variable used as both src1 and src2 produces exactly one node
    , boolTest "same variable as both sources: only one node created"
        (let g = buildGraph (newInstrSeq [mkBinOp "t1" (Var "a") Add (Var "a")] ["t1"])
         in length (filter ((== "a") . getVarName) (getVariables g)) == 1) True

    -- two-instruction chain
    , boolTest "two instrs: chain produces correct interference edges"
        (let g = buildGraph (newInstrSeq
                    [ mkBinOp "t1" (Var "a") Add (Lit 1)    -- t1 = a + 1
                    , mkBinOp "b"  (Var "t1") Mul (Lit 2)   -- b  = t1 * 2
                    ] ["b"])
         in hasEdge "t1" "b" g && hasEdge "a" "t1" g && not(hasEdge "a" "b" g)) True

    -- spec example: all eight variables
    , eqTest "spec program: all variables appear as nodes"
        (sort (varNames specGraph))
        (sort ["a", "b", "c", "d", "t1", "t2", "t3", "t4"])

    -- confirmed edges exist
    , boolTest "spec program: c interferes with d"
        (hasEdge "c" "d" specGraph) True

    , boolTest "spec program: t4 interferes with d"
        (hasEdge "t4" "d" specGraph) True

    , boolTest "spec program: b interferes with c"
        (hasEdge "b" "c" specGraph) True

    , boolTest "spec program: b interferes with t4"
        (hasEdge "b" "t4" specGraph) True

    , boolTest "spec program: t2 interferes with c"
        (hasEdge "t2" "c" specGraph) True

    , boolTest "spec program: t2 interferes with b"
        (hasEdge "t2" "b" specGraph) True

    , boolTest "spec program: t3 interferes with c"
        (hasEdge "t3" "c" specGraph) True

    , boolTest "spec program: t3 interferes with b"
        (hasEdge "t3" "b" specGraph) True

    , boolTest "spec program: t3 interferes with t2"
        (hasEdge "t3" "t2" specGraph) True

    , boolTest "spec program: a interferes with c"
        (hasEdge "a" "c" specGraph) True

    , boolTest "spec program: a interferes with t2"
        (hasEdge "a" "t2" specGraph) True

    , boolTest "spec program: a interferes with t3"
        (hasEdge "a" "t3" specGraph) True

    , boolTest "spec program: t1 interferes with c"
        (hasEdge "t1" "c" specGraph) True

    , boolTest "spec program: t1 interferes with t2"
        (hasEdge "t1" "t2" specGraph) True

    , boolTest "spec program: t1 interferes with a"
        (hasEdge "t1" "a" specGraph) True
    ]
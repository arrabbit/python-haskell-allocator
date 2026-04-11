module TestInterferenceGraph where

import Data.List  (sort)
import Data.Maybe (isJust, isNothing, fromJust)

import Variable          (Variable, newVariable, getVarName, getAdjacent, addAdjacent)
import InterferenceGraph (IGraph, emptyGraph, addVariable, addEdge,
                          getVariables, getVariable, showGraph)
import GraphBuilder      (buildGraph)
import ThreeAddr         (Operand(..), Op(..), InstrSeq,
                          mkBinOp, mkUnaryOp, mkCopy, newInstrSeq)


runTests :: [(String, Bool)] -> IO ()
runTests tests = do
    mapM_ printResult tests -- mapM_ lets us map over functions that return IO functions and ignore direct result (hence _)
    let passed = length (filter snd tests)
        total  = length tests
    putStrLn ("\n" ++ show passed ++ "/" ++ show total ++ " tests passed.")
  where
    printResult (lbl, True)  = putStrLn ("  PASS  " ++ lbl)
    printResult (lbl, False) = putStrLn ("  FAIL  " ++ lbl)

main :: IO ()
main = do
    putStrLn "=== Variable tests ==="
    runTests variableTests
    putStrLn "\n=== InterferenceGraph tests ==="
    runTests interferenceGraphTests
    putStrLn "\n=== GraphBuilder tests ==="
    runTests graphBuilderTests

-- | Sort the adjacency list of a variable for order-independent equivalence checking.
sortedAdj :: Variable -> [String]
sortedAdj = sort . getAdjacent

-- | Get sorted adjacency list of a var from a graph
adjOf :: String -> IGraph -> [String]
adjOf name graph = case getVariable name graph of
    Just v  -> sortedAdj v -- Sorted adjacency list of found var
    Nothing -> [] -- No variable in graph  

-- | True if an edge exists between n1 and n2 in a graph
hasEdge :: String -> String -> IGraph -> Bool
hasEdge n1 n1 graph = 
    n1 `elem` adjOf n2 graph && -- elem returns True if first var exists in adj graph of second var
    n2 `elem` adjOf n2 graph  

-- | Get sorted variable names of a graph.
varNames :: IGraph -> [String]
varNames = sort . map getVarName . getVariables      

----------------
-- Test Input --
----------------

-- Test instructions
testInstrs :: [ThreeAddr.Instr]
testInstrs =
    [ mkBinOp "a"  (Var "a")  Add (Lit 1),      -- a = a + 1
      mkBinOp "t1" (Var "a")  Mul (Lit 4),      -- t1 = a * 4
      mkBinOp "t2" (Var "t1") Add (Lit 1),      -- t2 = t1 + 1
      mkBinOp "t3" (Var "a")  Mul (Lit 3),      -- t3 = a * 3
      mkBinOp "b"  (Var "t2") Sub (Var "t3"),   -- b  = t2 - t3
      mkBinOp "t4" (Var "b")  Div (Lit 2),      -- t4 = b / 2
      mkBinOp "d"  (Var "c")  Add (Var "t4")    -- d  = c + t4
    ]

-- Test live list
testSeq :: InstrSeq
testSeq = newInstrSeq specInstrs ["d"] -- live: d

-- Test interference graph
testGraph :: IGraph
testGraph = buildGraph testSeq

----------------------
-- Variable Testing --
----------------------

variableTests :: [(String, Bool)]
variableTests =
    [ ("newVariable: name is stored correctly",
        getVarName (newVariable "x") == "x")

    , ("newVariable: adj list is initially empty",
        null (getAdjacent (newVariable "a")))

    , ("getVarName: returns correct name after construction",
        getVarName (newVariable "t1") == "t1")

    , ("getAdjacent: returns empty list for new variable",
        getAdjacent (newVariable "b") == [])

    , ("addAdjacent: single neighb is added",
        let v = addAdjacent "y" (newVariable "x")
        in  getAdjacent v == ["y"])

    , ("addAdjacent: multiple neighbs stored",
        let v = addAdjacent "z" (addAdjacent "y" (newVariable "x"))
        in  sort (getAdjacent v) == ["y", "z"])

    , ("addAdjacent: duplicate neighb is not added twice",
        let v = addAdjacent "y" (addAdjacent "y" (newVariable "x"))
        in  length (getAdjacent v) == 1)

    , ("addAdjacent: adding three neighbs, no duplicates",
        let v = addAdjacent "c" (addAdjacent "b" (addAdjacent "a" (newVariable "x")))
        in  sort (getAdjacent v) == ["a", "b", "c"])

    , ("addAdjacent: variable does not appear in its own adj list",
        let v = addAdjacent "x" (newVariable "x")
        in  length (filter (== "x") (getAdjacent v)) /= 1)

    , ("Show Variable: no adj shows as 'name: (none)'",
        show (newVariable "a") == "a: (none)")

    , ("Show Variable: one neighbs shows correctly",
        show (addAdjacent "b" (newVariable "a")) == "a: b")

    , ("Show Variable: multiple neighbs shows comma-separated",
        let v = addAdjacent "c" (addAdjacent "b" (newVariable "a"))
        in  show v == "a: c, b" || show v == "a: b, c")
    ]

--------------------------------
-- Interference Graph Testing --
--------------------------------

interferenceGraphTests :: [(String, Bool)]
interferenceGraphTests = 
    [
        ()
    ]

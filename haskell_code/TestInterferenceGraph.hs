module TestInterferenceGraph where

import Data.List  (sort)
import Data.Maybe (isJust, isNothing, fromJust)

import Variable          (Variable, newVariable, getVarName, getAdjacent, addAdjacent)
import InterferenceGraph (IGraph, emptyGraph, addVariable, addEdge,
                          getVariables, getVariable, showGraph)
import GraphBuilder      (buildGraph)
import ThreeAddr         (Operand(..), Op(..), InstrSeq, Instr,
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

-------------
-- Helpers --
-------------

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
hasEdge n1 n2 graph = 
    n1 `elem` adjOf n2 graph && -- elem returns True if first var exists in adj graph of second var
    n2 `elem` adjOf n2 graph  

-- | Get sorted variable names of a graph.
varNames :: IGraph -> [String]
varNames = sort . map getVarName . getVariables      

----------------
-- Test Input --
----------------
-- Used for multiple types of tests

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
testSeq = newInstrSeq testInstrs ["d"] -- live: d

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
        -- emptyGraph
        ("emtpyGraph: has no variables", 
            null (getVariables emptyGraph)
        ),

        -- addVariable
        ("addVariable: graph grows by one node", 
            length (getVariables (addVariable "a" emptyGraph)) == 1
        ),

        ("addVariable: node has correct name", 
            case getVariable "a" (addVariable "a" emptyGraph) of
                Just v -> getVarName v == "a"
                Nothing -> False
        ),

        ("addVariable: duplicate name is ignored",  
            let g = addVariable "a" (addVariable "a" emptyGraph) 
            in length (getVariables g) == 1
        ),

        ("addVariable: two unique names produce 2 nodes",
            let g = addVariable "b" (addVariable "a" emptyGraph)
            in length (getVariables g) == 2
        ),

        ("addVariable: new node has empty adj list",
            adjOf "a" (addVariable "a" emptyGraph) == []
        ),

        -- getVariable
        ("getVariable: returns Just for a present variable",
            isJust (getVariable "a" (addVariable "a" emptyGraph))
        ),

        ("getVariable: returns Nothing for an absent variable",
            isNothing (getVariable "z" (addVariable "a" emptyGraph))
        ),

        ("getVariable: correct variable is returned from multi-node graph",
            let g = addVariable "b" (addVariable "a" emptyGraph)
            in case getVariable "b" g of
                Nothing -> False
                Just var -> getVarName var == "b"
        ),

        -- getVariables
        ("getVariables: returns all nodes",
            let g = addVariable "c" (addVariable "b" (addVariable "a" emptyGraph))
            in  sort (map getVarName (getVariables g)) == ["a", "b", "c"]
        ),
        ("addEdge: both variables appear in graph",
            let g = addEdge "a" "b" emptyGraph
            in  varNames g == ["a", "b"]
        ),

        ("addEdge: a is in b's adjacency list",
            let g = addEdge "a" "b" emptyGraph
            in  "a" `elem` adjOf "b" g
        ),
        ("addEdge: b is in a's adjacency list",
            let g = addEdge "a" "b" emptyGraph
            in  "b" `elem` adjOf "a" g
        ),
        ("addEdge: edge is symmetric (hasEdge helper)",
            hasEdge "a" "b" (addEdge "a" "b" emptyGraph)
        ),
        ("addEdge: pre-existing nodes get edge added",
            let g = addEdge "a" "b"
                        (addVariable "b" (addVariable "a" emptyGraph))
            in hasEdge "a" "b" g
        ),
        ("addEdge: unrelated node is unaffected",
            let g = addEdge "a" "b" (addVariable "c" emptyGraph)
            in  adjOf "c" g == []
        ),
        ("addEdge: adding same edge twice is idempotent",
            let g = addEdge "a" "b" (addEdge "a" "b" emptyGraph)
            in  length (adjOf "a" g) == 1 && length (adjOf "b" g) == 1
        ),
        ("addEdge: three mutually-interfering variables",
            let g = addEdge "a" "c" (addEdge "b" "c" (addEdge "a" "b" emptyGraph))
            in  hasEdge "a" "b" g && hasEdge "b" "c" g && hasEdge "a" "c" g
        ),

        -- showGraph
        ("showGraph: empty graph shows empty message",
            showGraph emptyGraph == "   (empty graph)"
        ),

        ("showGraph: non-empty graph contains variable names",
            let g = addEdge "a" "b" emptyGraph
            in  "a" `elem` lines (showGraph g) ||
                any (\ l -> "a" `elem` words l) (lines (showGraph g))
        )
    ]

-------------------------
-- Graph Builder Tests --
-------------------------

graphBuilderTests :: [(String, Bool)]
graphBuilderTests = 
    [
        -- Edge Cases
        --------------------------------------------
        ("empty program, no live-outs: empty graph",
        let g = buildGraph (newInstrSeq [] [])
        in  null (getVariables g)),

        ("empty program, one live-out: one node, no edges",
        let g = buildGraph (newInstrSeq [] ["x"])
        in  varNames g == ["x"] && adjOf "x" g == []),

        ("empty program, two live-outs: both nodes, one edge",
        let g = buildGraph (newInstrSeq [] ["x", "y"])
        in  varNames g == ["x", "y"] && hasEdge "x" "y" g),

        ("empty program, three live-outs: all pairs connected",
        let g = buildGraph (newInstrSeq [] ["x", "y", "z"])
        in  hasEdge "x" "y" g && hasEdge "y" "z" g && hasEdge "x" "z" g),

        ("single copy instr, dest not live-out: only src node",
        -- x = y  ;  live: (none)
        -- y is used (last use) → added; x is dest → defined, not live above
        let g = buildGraph (newInstrSeq [mkCopy "x" (Var "y")] [])
        in  isJust (getVariable "y" g)),

        ("single copy instr from literal: no variable nodes beyond live-outs",
        -- x = 5  ;  live: (none)
        -- 5 is a Lit, not a Var; x is dest, never used → no nodes at all
        let g = buildGraph (newInstrSeq [mkCopy "x" (Lit 5)] [])
        in  null (getVariables g)),

        ("unary instr: src and dest both in graph",
        -- t1 = -a  ;  live: t1
        let g = buildGraph (newInstrSeq [mkUnaryOp "t1" (Var "a")] ["t1"])
        in  isJust (getVariable "a" g) && isJust (getVariable "t1" g)),

        ("unary instr: src interferes with live-out dest",
        -- t1 = -a  ;  live: t1
        -- When we see src 'a' it is live simultaneously with live-out 't1'
        let g = buildGraph (newInstrSeq [mkUnaryOp "t1" (Var "a")] ["t1"])
        in  hasEdge "a" "t1" g),

        -- 2-Instruction Sequences
        ----------------------------------------------------------
        ("two instrs: variable defined then used has no self-edge",
        let g = buildGraph (newInstrSeq
                    [ mkBinOp "t1" (Var "a") Add (Lit 1) -- t1 = a + 1 | t1 added to live={b} -> t1 <-> b
                    , mkBinOp "b"  (Var "t1") Mul (Lit 2) -- b = t1 * 2 | a added to live={b,t1} -> a <-> b, a <-> t1
                    ] ["b"]) -- live: b
        in  hasEdge "t1" "b" g && hasEdge "a" "t1" g && hasEdge "a" "b" g),

        ("two instrs: variable used twice shares one node",
        -- Both src1 and src2 are Var "a" so should produce exactly one node for a
        let g = buildGraph (newInstrSeq
                    [ mkBinOp "t1" (Var "a") Add (Var "a") -- t1 = a + a 
                    ] ["t1"]) -- live: t1 
        in  length (filter ((== "a") . getVarName) (getVariables g)) == 1),

        -- Full program tests
        ------------------------------------------------
        ("test program: all 8 variables appear as nodes",
        sort (varNames testGraph) == sort ["a", "b", "c", "d", "t1", "t2", "t3", "t4"]),

        -- Edges confirmed by hand-traced liveness analysis
        ("test program: c interferes with d",
        hasEdge "c" "d" testGraph),

        ("test program: t4 interferes with d",
        hasEdge "t4" "d" testGraph),

        ("test program: b interferes with c",
        hasEdge "b" "c" testGraph),

        ("test program: b interferes with t4",
        hasEdge "b" "t4" testGraph),

        ("test program: t2 interferes with c",
        hasEdge "t2" "c" testGraph),

        ("test program: t2 interferes with b",
        hasEdge "t2" "b" testGraph),

        ("test program: t3 interferes with c",
        hasEdge "t3" "c" testGraph),

        ("test program: t3 interferes with b",
        hasEdge "t3" "b" testGraph),

        ("test program: t3 interferes with t2",
        hasEdge "t3" "t2" testGraph),

        ("test program: a interferes with c",
        hasEdge "a" "c" testGraph),

        ("test program: a interferes with t2",
        hasEdge "a" "t2" testGraph),

        ("test program: a interferes with t3",
        hasEdge "a" "t3" testGraph),

        ("test program: t1 interferes with c",
        hasEdge "t1" "c" testGraph),

        ("test program: t1 interferes with t2",
        hasEdge "t1" "t2" testGraph),

        ("test program: t1 interferes with a",
        hasEdge "t1" "a" testGraph),

        -- Edges that should not exist
        ---------------------------------------------
        ("test program: a does NOT interfere with d",
        not (hasEdge "a" "d" testGraph)),

        ("test program: a does NOT interfere with b",
        not (hasEdge "a" "b" testGraph)),

        ("test program: t1 does NOT interfere with t3",
        not (hasEdge "t1" "t3" testGraph)),

        ("test program: t1 does NOT interfere with b",
        not (hasEdge "t1" "b" testGraph)),

        ("test program: t1 does NOT interfere with t4",
        hasEdge "t1" "t4" testGraph == False),

        ("test program: d has exactly 2 neighbours (c and t4)",
        sort (adjOf "d" testGraph) == ["c", "t4"]),

        ("test program: c has exactly 7 neighbours (all others except itself)",
        sort (adjOf "c" testGraph) == sort ["a", "b", "d", "t1", "t2", "t3", "t4"]),

        -- Correct Liveness
        --------------------------------------------------------------
        ("dead variable (defined, never used, not live-out): no node",
        -- x is defined but never used and not live-out -> should have no node
        let g = buildGraph (newInstrSeq [mkCopy "x" (Lit 1)] -- x = 1
                            [])                              -- live: (none)
        in  isNothing (getVariable "x" g)),

        ("live-out variable not defined in block: still has a node",
        let g = buildGraph (newInstrSeq [] ["x"]) -- live: x  (x is used by something after this block)
        in  isJust (getVariable "x" g))
    ]
module GraphBuilder (
    buildGraph
) where

import ThreeAddr            (InstrSeq, Instr, Operand(..), getInstrs, getLiveOut,
                            getDest, getSrc1, getSrc2)
import InterferenceGraph    (IGraph, emptyGraph, addVariable, addEdge, getVariables)

buildGraph:: InstrSeq -> IGraph
buildGraph instrSeq =
    let instrs          = getInstrs instrSeq
        liveOut         = getLiveOut instrSeq
        initial         = (liveOut, initialGraph liveOut)
        (_, finalGraph) = foldr processInstr initial instrs 
    in finalGraph

initialGraph :: [String] -> IGraph
initialGraph liveOut =
    let g = foldl (flip addVariable) emptyGraph liveOut
    in  foldl (\acc name -> addEdges name (filter (/= name) liveOut) acc) g liveOut

-- | Process one instruction during the backward traversal.
--   Updates the live set and interference graph according to the algorithm.
--
--   Step a: for each Var source not yet in the live set, add it and connect
--           it to every variable currently live.
--   Step b: remove the destination from the live set.
processInstr :: Instr -> ([String], IGraph) -> ([String], IGraph)
processInstr instr (liveSet, graph) =
    let dest             = getDest instr
        -- Collect Var names from source operands (ignore Lit operands)
        src1name         = varName (getSrc1 instr)
        src2name         = getSrc2 instr >>= varName
        srcNames         = [n | Just n <- [src1name, src2name]]
        -- Step a: fold over source names, adding each new one to the live set
        (liveSet', graph') = foldl addSrcVar (liveSet, graph) srcNames
        -- Step b: the dest is defined here; it is not live above this point
        liveSet''        = filter (/= dest) liveSet'
    in  (liveSet'', graph')

-- | If the variable is not already live, add it as a node, connect it to
--   every currently-live variable, and extend the live set.
--   If it is already live, the state is unchanged.
addSrcVar :: ([String], IGraph) -> String -> ([String], IGraph)
addSrcVar (liveSet, graph) name
    | name `elem` liveSet = (liveSet, graph)
    | otherwise           =
        let graph' = addEdges name liveSet (addVariable name graph)
        in  (name : liveSet, graph')

-- | Add an interference edge between @var@ and every variable in @others@.
addEdges :: String -> [String] -> IGraph -> IGraph
addEdges var others graph = foldl (\g other -> addEdge var other g) graph others

-- | Extract the variable name from a Var operand; return Nothing for a Lit.
varName :: Operand -> Maybe String
varName (Var name) = Just name
varName (Lit _)    = Nothing
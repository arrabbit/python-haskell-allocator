-- | InterferenceGraph.hs
--
--   ADT representing the interference graph for register allocation.
--   Each node is a Variable; and edge between two nodes means those two
--   variables are simultaneously live at some point in the code and so
--   cannot share a register.
--
--   Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
--   Date: April 8, 2026

module InterferenceGraph (
    IGraph,
    emptyGraph,
    addVariable,
    addEdge,
    getVariables,
    getVariable,
    showGraph
) where

import Variable (Variable, newVariable, getVarName, getAdjacent, addAdjacent)
import Data.List (find)

data IGraph = IGraph [Variable]
    deriving (Eq)

emptyGraph:: IGraph
emptyGraph = IGraph []

-- | Add a new variable node to the graph.
--   If a node with the same name already exists, the graph is unchanged.
addVariable:: String -> IGraph -> IGraph -- Adds a new variable node
addVariable name (IGraph vars)
    | any ((== name) . getVarName) vars = IGraph vars
    | otherwise                         = IGraph (newVariable name : vars)
     
-- | Record that two variables interfere with one another. Both variables are
--   added to the graph first if not not already there, then each is added to
--   the other's adjacency list.
addEdge:: String -> String -> IGraph -> IGraph
addEdge name1 name2 graph  =
    let graph'              = addVariable name1 (addVariable name2 graph) -- Graph with name 1 and 2 added
        IGraph vars'        = graph'
        updated             = map updatedVar vars'
    in IGraph updated
    where
        updatedVar v                                        -- Updates adjacency lists
            | getVarName v == name1 = addAdjacent name2 v
            | getVarName v == name2 = addAdjacent name1 v
            | otherwise             = v

-- | Return all variable nodes in the graph
getVariables :: IGraph -> [Variable]
getVariables (IGraph vars)  = vars

-- | Look up a variable node by name. Returns nothing if no such variable
--   exists in the graph
getVariable :: String -> IGraph -> Maybe Variable
getVariable name (IGraph vars) = case filter ((== name) . getVarName) vars of
    (v:_) -> Just v
    []    -> Nothing

-- | Human readable interference table: one variable per line,
--   listing its interfering neighbours
showGraph:: IGraph -> String
showGraph (IGraph vars)
    | null vars = "   (empty graph)"
    | otherwise = unlines (map show vars)

-- | Derived Show calls showGraph so printing an IGraph in GHCI
--   gives the same formatted output.
instance Show IGraph where
    show = showGraph
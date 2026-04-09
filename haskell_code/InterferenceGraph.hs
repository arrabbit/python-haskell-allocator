module InterferenceGraph (
    
) where

import Variable (Variable, newVariable, getVarName, getAdjacent, addAdjacent)

newtype IGraph = IGraph [Variable]
    deriving (Show, Eq)

emptyGraph:: IGraph
emptyGraph = IGraph []

addVariable:: String -> IGraph -> IGraph -- Adds a new variable node
addVariable name (IGraph vars)
    | any ((== name) . getVarName) vars = IGraph vars
    | otherwise                         = IGraph (newVariable name : vars)
     


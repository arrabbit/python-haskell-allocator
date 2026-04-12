module Variable (
    Variable,
    newVariable,
    getVarName,
    getAdjacent,
    addAdjacent
) where

import Data.List (nub, intercalate) -- avoid duplicate entries

data Variable = Var String [String]
    deriving (Eq)


newVariable:: String -> Variable
newVariable name = Var name []      -- Empty list is adjacent nodes

getVarName:: Variable -> String
getVarName (Var name _) = name

getAdjacent:: Variable -> [String]
getAdjacent (Var _ adj) = adj

addAdjacent:: String -> Variable -> Variable
addAdjacent neighbour (Var name adjs) = Var name (nub (neighbour : adjs))

instance Show Variable where
    show (Var name adjs)
        | null adjs = name ++ ": (none)"
        | otherwise = name ++ ": " ++ intercalate ", " adjs -- intercalate joins a list of lists inserting a separator and then flattening the list

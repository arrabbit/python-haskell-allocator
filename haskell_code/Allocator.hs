-- |
-- Summary: 
--
-- Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
-- Date: April 8, 2026

module Allocator
    (Colouring
    , allocate
    ) where 

import Variable (Variable, getVarName, getAdjacent)
import InterferenceGraph (IGraph, getVariables)

data Colouring
    = [(varName String, regNum Int)]

-- | 
allocate :: IGraph -> Int -> [Colouring]

-- | Checks if assigning a colour to the given var conflicts with any already
--   coloured neighbours.
isViable :: Int -> Variable -> Colouring -> Bool


-- |
-- Summary: The register allocator module, which takes an interference graph
--     and a number of available registers, and attempts to find a valid
--     assignment of registers to variables using graph colouring.
--
-- Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
-- Date: April 8, 2026

module Allocator
    (ColourSol
    , allocate
    ) where 

import Variable (Variable, getVarName, getAdjacent)
import InterferenceGraph (IGraph, getVariables)

-- | A colour solution which maps each variable name to a register number
type ColourSol = [(String, Int)]


-- | Attempts to colour the given interference graph using the given number of
--   registers. Returns a list of all valid colour solutions. If the list is
--   empty, no valid register allocation exists.
--
--   Parameters:
--     graph   - the interference graph to colour
--     numRegs - the number of available registers
--
--   Returns: a (lazy) list of all valid colour solutions
allocate :: IGraph -> Int -> [ColourSol]
allocate graph numRegs = distribute (getVariables graph) numRegs

-- | Helper recursive function for allocate that reucursively assigns a
--   register to each variable in the list, building up a list of all
--   colour solutions with no conflicts.
--   Note* function follows the same search pattern as the 8-queens solver
--
--   Parameters:
--     variables - the remaining variables to colour
--     numRegs   - the number of available registers
--
--   Returns: a list of all valid colour solutions for the given variables
distribute :: [Variable] -> Int -> [ColourSol]
distribute [] _ = [[]]
distribute (var:rest) numRegs =  
    [ (getVarName var, colour) : solRest   -- builds list of solutions
    | solRest <- distribute rest numRegs   -- solve the remaining variables
    , colour  <- [0 .. (numRegs - 1)]       -- try each register
    , isViable colour var solRest          -- checks for conflicts
    ]

-- | Checks if assigning the given colour to the given variable conflicts with
--   any of the variables that interfere with it.
--   
--   Parameters:
--     colour  - the register number to try
--     var     - the variable to assign it to
--     solRest - the existing colour assignments to check against
--
--   Returns: True if the assignment causes no conflicts, False otherwise
isViable :: Int -> Variable -> ColourSol -> Bool
isViable colour var solRest = all noConflict (getAdjacent var)
    -- Checks one neighbour for conflict
    where noConflict neighbour = case lookup neighbour solRest of
                                     -- If the neighbour has been coloured
                                     Just c -> c /= colour  -- checks if colours match
                                     -- If the neighbour hasn't been coloured
                                     Nothing -> True
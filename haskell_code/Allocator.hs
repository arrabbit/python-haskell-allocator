-- |
-- Summary: 
--
-- Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
-- Date: April 8, 2026

data Colouring
    = [(varName String, regNum Int)]

-- | 
allocate :: IGraph -> Int -> [Colouring]

-- | Checks if assigning a colour to the given var conflicts with any already
--   coloured neighbours.
isViable :: Int -> Variable -> Colouring -> Bool


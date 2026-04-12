-- |
-- Summary: The parsing module which takes a list of toekns from the tokenizer
--          and creates an instruction sequence (InstrSeq).
--
-- Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
-- Date: April 12, 2026
 
module Parser
    ( parse
    ) where

import Tokenizer (Token(..))
import ThreeAddr (InstrSeq, Instr, Operand(..), Op(..), mkBinOp, mkUnaryOp,
                  mkCopy, newInstrSeq, getDest)


-- | Builds the InstrSeq by spliting the tokens at the TokLive keyword parsing
--   all the instructions before it, and extracting all the live variables
--   after it.
parse :: [Token] -> InstrSeq
parse tokens = let (instrTokens, liveVars) = split tokens
                   instrs = parseAllInstrs instrTokens
               in if null (validateLive instrs liveVars)
                  then newInstrSeq instrs liveVars
                  else error ("Parser: live variable(s) not defined in code: "
                              ++ show (validateLive instrs liveVars))

-- | Separates the instruction tokens from the live variable list.
split :: [Token] -> ([[Token]],[String])
split tokens = case break (== TokLive) tokens of
                         (before, []) -> (groupInstrs before, [])
                         (before, _:rest) -> (groupInstrs before, collectVars rest)

-- | Reads the variable names seperated by a comma.
collectVars :: [Token] -> [String]
collectVars [] = []
collectVars (firstTok:rest) = case firstTok of 
                                  TokVar name -> name: parsedRest
                                  _ -> parsedRest
    where parsedRest = collectVars rest

-- | Groups the given token list into a list of sublists, where each sublist is
--   an individual instruction.
groupInstrs :: [Token] -> [[Token]]
groupInstrs [] = []
groupInstrs tokens | null line = nextGroup            -- checks if line is empty
                   | otherwise = line: nextGroup
    where (line, rest) = break (== TokNewLn) tokens   -- splits list into a pair: 
                                                      -- (pre-newLn, newLn and remaining)
          nextGroup = groupInstrs (drop 1 rest)       -- (drop 1 rest) tosses the newLn from rest

-- | Converts the list of token lists representing a single instruction into
--   an Instr list
parseAllInstrs :: [[Token]] -> [Instr]
parseAllInstrs = map parseInstr

-- | Matches each token group with the correct three-address instruction
--   pattern to create a single instruction (Instr).
--   
--   Valid instruction patterns:
--               binary: dest = src1 op src2
--       unary negation: dest = -src
--                 copy: dest = src
parseInstr :: [Token] -> Instr
-- binary
parseInstr [TokVar dest, TokEq, src1, TokOp op, src2] = mkBinOp dest
                                                        (tokToOperand src1)
                                                        (charToOp op)
                                                        (tokToOperand src2)
-- unary negation
parseInstr [TokVar dest, TokEq, TokOp '-', src] = mkUnaryOp dest
                                                  (tokToOperand src)
-- copy
parseInstr [TokVar dest, TokEq, src] = mkCopy dest (tokToOperand src)
-- else
parseInstr tokens = error ("Parser: instruction pattern not recognized: " ++
                            show tokens)

-- | Converts a given token to the correct operand.
tokToOperand :: Token -> Operand
tokToOperand (TokVar name) = Var name
tokToOperand (TokLit n) = Lit n
tokToOperand token = error ("Parser: unexpected token: " ++ show token)

-- | Converts a given character to the correct arithmetic operator.
charToOp :: Char -> Op
charToOp c | c == '+' = Add
           | c == '-' = Sub
           | c == '*' = Mul
           | c == '/' = Div
           | otherwise = error ("Parser: unknown operator: " ++ show [c])

-- | Checks that every variable declared live on exit actually appears in the
--   instruction list.
validateLive :: [Instr] -> [String] -> [String]
validateLive instrs liveVars = filter (\v -> v `notElem` definedVars) liveVars
    where definedVars = map getDest instrs
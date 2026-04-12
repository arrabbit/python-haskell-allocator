-- |
-- Summary: The tokenizer module which takes a string with the three-address
--          code and produces a list of typed tokens for use by the parser
--          module.
-- Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
-- Date: April 11, 2026

module Tokenizer
    (Token(..)  -- export Token and all its data constructors
    , tokenize
    ) where

import Data.Char

data Token = TokVar String       -- variable name
           | TokLit Int          -- integer literal
           | TokOp Char          -- arithmetic operator (+, -, *, /)
           | TokEq               -- the "=" sign
           | TokLive             -- keyword 'live'
           | TokCol              -- the ":" character
           | TokCom              -- the "," character
           | TokNewLn            -- newline character
           deriving (Show, Eq)

-- | Parses a string which represents the three-address simplified source code
--   into a list of tokens.
tokenize :: String -> [Token]
tokenize input = concatMap tokenizeLn (lines input)

-- | Tokenizes a single line of text by splitting it into words and determining
--   the correct token type for each, and appending a newline token at the end.
--   Returns a list of tokens representing the parsed contents of the given
--   line.
tokenizeLn :: String -> [Token]
tokenizeLn line = concatMap getType (words line) ++ [TokNewLn]

-- | Evaluates a given string to determine its token type by matching the
--   string to keyword 'live', key symbols (=, :, ,), mathematical operators
--   (+, -, *, /), variable names, and integer literals. Returns a list of
--   typed tokens.
getType :: String -> [Token]
getType "live" = [TokLive]
getType "live:" = [TokLive, TokCol]
getType "=" = [TokEq]
getType ":" = [TokCol]
getType "," = [TokCom]
getType [o]
    | o `elem` "+-*/" = [TokOp o]
getType ('-':rest)
    | isValidVar rest = [TokOp '-', TokVar rest]  -- handles negative variable ex. '-a'
    | isOnlyDigits rest = [TokOp '-', TokLit (read rest)] -- handles negative digit ex. '-2'
getType word
    | isValidVar word = [TokVar word]
    | isOnlyDigits word = [TokLit (read word)]
    | last word == ',' && isValidVar (init word) = [TokVar (init word), TokCom]
    | otherwise = error ("Tokenizer: invalid token: " ++ word)

-- | Evaluates a given string to determine if it is a valid variable name.
--   Returns True if the string is a valid variable name, otherwise returns
--   False.
--   
--   *Note: A valid variable name is a single lowercase letter (not 't'),
--          or 't' followed at least one digit.
isValidVar :: String -> Bool
isValidVar [c] = isAlpha c && c /= 't'                 -- single char (not 't')
isValidVar ('t':ds) = all isDigit ds && not (null ds)  -- 't' w. at least 1 digit
isValidVar _ = False

-- | Evaluates a given string to see if all characters within the string are
--   numeric digits. Returns True if all characters in the string arithmetic
--   digits, otherwise returns False.
--
--   *Note: string must have at least 1 digit to be considered all digits.
isOnlyDigits :: String -> Bool
isOnlyDigits [] = False                   -- base case: empty string so no digits
isOnlyDigits digits = all isDigit digits
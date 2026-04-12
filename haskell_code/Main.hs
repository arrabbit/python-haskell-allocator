-- |
-- Summary: Entry point for the register allocator. Reads command-line
--   arguments, validates input, runs the full allocation pipeline, and
--   writes output to stdout and to a .s assembly file.
--
--   Invocation:  gen <num_regs> <filename>
--
-- Authors: Joseph Mills
-- Date: April 10, 2026

module Main where

import System.Environment  (getArgs)
import System.IO           (hPutStrLn, stderr)
import System.Exit         (exitFailure)
import Control.Exception   (try, SomeException)
import Data.List           (intercalate)

import ThreeAddr           (InstrSeq)
import InterferenceGraph   (showGraph)
import GraphBuilder        (buildGraph)
import Allocator           (ColourSol, allocate)
import Codegen             (generateCode)

-- TODO: import Scanner (tokenize)
-- TODO: import Parser  (parse)

-- | Stub: replace body with  parse (tokenize contents)
--   once Jordan's Scanner and Parser modules are integrated.
parseInput :: String -> InstrSeq
parseInput _ = error "parseInput: Scanner/Parser not yet integrated"

-- | Program entry point. Expects exactly two arguments:
--     num_regs  - positive integer: number of available CPU registers
--     filename  - path to a readable three-address code file
main :: IO ()
main = do
    args <- getArgs
    case args of
        [nStr, path] -> validateAndRun nStr path
        _            -> abort "Usage: gen <num_regs> <filename>"

-- | Validate arguments then run the allocation pipeline.
validateAndRun :: String -> FilePath -> IO ()
validateAndRun nStr path = do
    let numRegs  = parseNumRegs nStr
    contents    <- readInputFile path
    let instrSeq  = parseInput contents
        graph     = buildGraph instrSeq
        solutions = allocate graph numRegs
    case solutions of
        []      -> putStrLn "Allocation failed: the interference graph \
                            \cannot be coloured with the available registers."
        (sol:_) -> do
            let prog    = generateCode instrSeq sol
                asmFile = path ++ ".s"
            putStr   (showGraph graph)
            putStr   (showColourTable numRegs sol)
            writeFile asmFile (show prog)

-- | Parse and validate the num_regs argument.
--   Calls error (terminates with message) if the value is not a
--   positive integer.
parseNumRegs :: String -> Int
parseNumRegs s = case reads s of
    [(n, "")] | n > 0 -> n
    _                 -> error "num_regs must be a positive integer greater than zero"

-- | Read the input file, aborting with a message on failure.
readInputFile :: FilePath -> IO String
readInputFile path = do
    result <- try (readFile path) :: IO (Either SomeException String)
    case result of
        Left  _        -> abort $ "Cannot open file: " ++ path
        Right contents -> return contents

-- | Format the register colouring table for stdout.
--   Produces one line per register that has at least one variable assigned,
--   e.g.  R0: a, t3
showColourTable :: Int -> ColourSol -> String
showColourTable numRegs sol =
    unlines [ "R" ++ show r ++ ": " ++ intercalate ", " (varsAt r)
            | r <- [0 .. numRegs - 1]
            , not (null (varsAt r)) ]
    where
        varsAt r = [ name | (name, reg) <- sol, reg == r ]

-- | Print an error message to stderr then exit with failure.
abort :: String -> IO a
abort msg = hPutStrLn stderr msg >> exitFailure

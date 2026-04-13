-- Main control for the haskell implementation of the project

-- gen <num_regs> <filename>

module Main where

import System.Environment  (getArgs)
import System.IO           (hPutStrLn, stderr)
import System.Exit         (exitFailure)
import Control.Exception   (try, SomeException)
import Data.List           (intercalate)

import Tokenizer           (tokenize)
import Parser              (parse)
import InterferenceGraph   (showGraph)
import GraphBuilder        (buildGraph)
import Allocator           (ColourSol, allocate)
import Codegen             (generateCode)


-- Makes sure we got exactly two args, then calls run.
main :: IO ()
main = do
    args <- getArgs
    case args of
        [numRegistersStr, path] -> run numRegistersStr path
        _                       -> abort "Wrong inputs use gen <num_regs> <filename>"

run :: String -> FilePath -> IO ()
run numRegistersStr path = do
    let numRegisters = parseNumRegs numRegistersStr
    contents <- readInputFile path
    let instructionSeq = parse (tokenize contents)
    let graph = buildGraph instructionSeq
    let solutions = allocate graph numRegisters
    case solutions of
        []  -> putStrLn "Register allocation failed: cannot colour the \
                \interference graph with the given number of registers."
        (solution:_)   -> do
            let asmProg = generateCode instructionSeq solution
            putStrLn "Variable Interference Table:"
            putStr   (showGraph graph)
            putStrLn "\nRegister Colouring Table:"
            putStr   (colourTable numRegisters solution)
            writeFile (path ++ ".s") (show asmProg)

colourTable :: Int -> ColourSol -> String
colourTable numRegs solution =
    unlines [ "R" ++ show regNum ++ ": " ++ intercalate ", " (varsInReg regNum)
            | regNum <- [0 .. numRegs - 1]
            , not (null (varsInReg regNum)) ]
    where
        varsInReg regNum = [ varName | (varName, reg) <- solution, reg == regNum ]

-- Prints an error message to stderr and exits.
abort :: String -> IO a
abort msg = do
    hPutStrLn stderr msg
    exitFailure

-- Parses the first argument as an integer. Errors out if it is
-- not a positive integer.
parseNumRegs :: String -> Int
parseNumRegs numRegistersStr = case reads numRegistersStr of
    [(n, "")] | n > 0 -> n
    _                 -> error "num_regs must be a positive integer greater than zero"

-- Opens and reads the input file. Exits with an error message
-- if the file can't be opened.
readInputFile :: FilePath -> IO String
readInputFile path = do
    result <- try (readFile path) :: IO (Either SomeException String)
    case result of
        Left  _        -> abort ("Cannot open file: " ++ path)
        Right contents -> return contents
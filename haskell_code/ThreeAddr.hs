-- |
-- Summary: Three-address instruction representation for the register allocator.
--
-- This module defines the input data structures for the Haskell register
-- allocator: operands, operators, individual instructions, and instruction
-- sequences (with live-on-exit variable information).
--
-- Constructors for 'InstrSeq' and 'Instr' are intentionally hidden.
-- Use 'newInstrSeq' for sequences, and 'mkBinOp', 'mkUnaryOp', 'mkCopy'
-- for instructions. Use getter functions to query instruction fields.
--
-- Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
-- Date: March 30, 2026

module ThreeAddr
  ( -- * Types
    Operand(..)
  , Op(..)
  , Instr
  , InstrSeq
    -- * Instruction constructors
  , mkBinOp
  , mkUnaryOp
  , mkCopy
    -- * Sequence constructors and queries
  , newInstrSeq
  , getInstrs
  , getLiveOut
    -- * Instruction queries
  , getDest
  , getSrc1
  , getOp
  , getSrc2
  , instrType  
    -- * Display functions
  , showOperand
  , showOp
  , showInstr
  , showInstrSeq
  ) where

import Data.List (intercalate)

-- ---------------------------------------------------------------------------
-- Core types
-- ---------------------------------------------------------------------------

-- | An operand is either a variable name (e.g. \"a\", \"t1\")
--   or an integer literal (e.g. 10).
data Operand
  = Var String   -- ^ a variable name
  | Lit Int      -- ^ an integer literal
  deriving (Show, Eq)

-- | An arithmetic operator: one of +, -, *, /.
data Op
  = Add   -- ^ addition
  | Sub   -- ^ subtraction
  | Mul   -- ^ multiplication
  | Div   -- ^ division
  deriving (Show, Eq)

-- | A single three-address instruction.
--   There are three forms:
--
--   * Binary:  @dest = src1 op src2@
--   * Unary:   @dest = -src@
--   * Copy:    @dest = src@
data Instr
  = BinOp   String Operand Op Operand  -- ^ dest = src1 op src2
  | UnaryOp String Operand             -- ^ dest = -src
  | Copy    String Operand             -- ^ dest = src
  deriving (Show, Eq)

-- | A sequence of three-address instructions together with the set of
--   variables that are live on exit from the block.
--   The internal constructor 'ISeq' is not exported; use 'newInstrSeq'.
data InstrSeq = ISeq [Instr] [String]
  deriving (Show, Eq)

-- ---------------------------------------------------------------------------
-- Instruction constructors
-- ---------------------------------------------------------------------------

-- | Build a binary three-address instruction.
--
-- >>> mkBinOp "a" (Var "a") Add (Lit 1)
-- BinOp "a" (Var "a") Add (Lit 1)
mkBinOp :: String   -- ^ destination variable
        -> Operand  -- ^ first source operand
        -> Op       -- ^ operator
        -> Operand  -- ^ second source operand
        -> Instr
mkBinOp dest src1 op src2 = BinOp dest src1 op src2

-- | Build a unary negation instruction (@dest = -src@).
--
-- >>> mkUnaryOp "t1" (Var "x")
-- UnaryOp "t1" (Var "x")
mkUnaryOp :: String   -- ^ destination variable
          -> Operand  -- ^ source operand to negate
          -> Instr
mkUnaryOp dest src = UnaryOp dest src

-- | Build a simple copy instruction (@dest = src@).
--
-- >>> mkCopy "x" (Lit 10)
-- Copy "x" (Lit 10)
mkCopy :: String   -- ^ destination variable
       -> Operand  -- ^ source operand
       -> Instr
mkCopy dest src = Copy dest src

-- ---------------------------------------------------------------------------
-- Sequence constructor and queries
-- ---------------------------------------------------------------------------

-- | Construct an instruction sequence from a list of instructions and a
--   list of variables that are live on exit.
newInstrSeq :: [Instr]   -- ^ the instruction list
            -> [String]  -- ^ variables live on exit
            -> InstrSeq
newInstrSeq instrs live = ISeq instrs live

-- | Extract the instruction list from a sequence.
getInstrs :: InstrSeq -> [Instr]
getInstrs (ISeq instrs _) = instrs

-- | Extract the live-on-exit variable list from a sequence.
getLiveOut :: InstrSeq -> [String]
getLiveOut (ISeq _ live) = live

-- ---------------------------------------------------------------------------
-- Instruction queries
-- ---------------------------------------------------------------------------

-- | Get the destination variable of an instruction.
getDest :: Instr -> String
getDest (BinOp dest _ _ _) = dest
getDest (UnaryOp dest _)   = dest
getDest (Copy dest _)      = dest

-- | Get the first source operand of an instruction.
getSrc1 :: Instr -> Operand
getSrc1 (BinOp _ src1 _ _) = src1
getSrc1 (UnaryOp _ src)    = src
getSrc1 (Copy _ src)       = src

-- | Get the operator (if any).
getOp :: Instr -> Maybe Op
getOp (BinOp _ _ op _) = Just op
getOp _                = Nothing

-- | Get the second source operand (if any).
getSrc2 :: Instr -> Maybe Operand
getSrc2 (BinOp _ _ _ src2) = Just src2
getSrc2 _                  = Nothing

-- | Returns the type of an instruction (binary, unary, or copy).
instrType :: Instr -> String
instrType (BinOp _ _ _ _) = "binary"
instrType (UnaryOp _ _)   = "unary"
instrType (Copy _ _)      = "copy"

-- ---------------------------------------------------------------------------
-- Display functions
-- ---------------------------------------------------------------------------

-- | Render an 'Operand' as a human-readable string.
--
-- >>> showOperand (Var "a")
-- "a"
-- >>> showOperand (Lit 10)
-- "10"
showOperand :: Operand -> String
showOperand (Var name) = name
showOperand (Lit n)    = show n

-- | Render an 'Op' as its source-level symbol.
--
-- >>> showOp Add
-- "+"
showOp :: Op -> String
showOp Add = "+"
showOp Sub = "-"
showOp Mul = "*"
showOp Div = "/"

-- | Render a single 'Instr' as a human-readable string.
--
-- >>> showInstr (mkBinOp "a" (Var "a") Add (Lit 1))
-- "a = a + 1"
-- >>> showInstr (mkUnaryOp "t1" (Var "x"))
-- "t1 = -x"
-- >>> showInstr (mkCopy "x" (Lit 10))
-- "x = 10"
showInstr :: Instr -> String
showInstr (BinOp dest src1 op src2) =
  dest ++ " = " ++ showOperand src1 ++ " " ++ showOp op ++ " " ++ showOperand src2
showInstr (UnaryOp dest src) =
  dest ++ " = -" ++ showOperand src
showInstr (Copy dest src) =
  dest ++ " = " ++ showOperand src

-- | Render a full 'InstrSeq' as a human-readable, numbered listing.
showInstrSeq :: InstrSeq -> String
showInstrSeq instrSeq =
  "Three-Address Instruction List:\n"
  ++ concatMap showNumbered (zip [0..] (getInstrs instrSeq))
  ++ "Live on exit: " ++ intercalate ", " (getLiveOut instrSeq) ++ "\n"
  ++ "----------------------------------------\n"
  where
    showNumbered (i, instr) = "  " ++ show (i :: Int) ++ ": " ++ showInstr instr ++ "\n"
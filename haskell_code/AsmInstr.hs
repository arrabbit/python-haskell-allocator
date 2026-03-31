-- |
-- Summary: Defines the abstract data types for representing target
--   architecture assembly instructions, operands, and programs.
--
-- Authors: Jordan Senko, Anna Running Rabbit, and Joseph Mills
-- Date: March 31, 2026

module AsmInstr
    (
        Register
        , SrcOperand
        , DstOperand
        , AluOp
        , AsmInstr
        , AsmProgram
        -- Register constructor
        , mkRegister
        -- Source operand constructors
        , immSrc
        , varSrc
        , regSrc
        -- Destination operand constructors
        , varDst
        , regDst
        -- Instruction constructors
        , mkAdd
        , mkSub
        , mkMul
        , mkDiv
        , mkMovToReg
        , mkMovFromReg
        -- Program constructors
        , emptyProgram
        , appendInstr
        , mkProgram    
    ) where

newtype Register = Register Int -- A wrapper type for Int
    deriving (Eq, Ord)

---------------------
-- CORE DATA TYPES --
---------------------

data SrcOperand
    = ImmSrc Int                -- Immediate value, (#x in ASM)
    | VarSrc String             -- Absolute mode. Named variable
    | RegSrc Register           -- Register direct mode
    deriving (Eq)

data DstOperand
    = VarDst String             -- Absolute mode. Named variable
    | RegDst Register           -- Register direct mode
    deriving (Eq)

-- Arithmetic instruction data type as they all have the same structure (src, dest-reg)
data AluOp = Add | Sub | Mul | Div
    deriving (Eq)

-- A single assembly language instruction where the two MOV variants are distinct 
-- because they have different operand structures 
-- (src -> register, and register -> dst)
data AsmInstr
    = ArithInstr AluOp SrcOperand Register  -- e.g., ADD #4, R0
    | MovToReg SrcOperand Register          -- MOV src, Ri
    | MovFromReg Register DstOperand        -- MOV Ri, dst
    deriving (Eq)

-- Type defining an AsmProgram as a list of AsmInstr's
newtype AsmProgram = AsmProgram [AsmInstr]
    deriving (Eq)

------------------
-- Constructors --
------------------

-- | Creates a register from a non-negative integer index.
--   Raises an error if the index is negative.
mkRegister :: Int -> Register
mkRegister n
    | n >= 0    = Register n 
    | otherwise = error $ "mkRegister: negative register index " ++ show n

-- | Creates an immediate-mode source operand: #x
immSrc :: Int -> SrcOperand
immSrc = ImmSrc

-- | Creates a variable (abs-mode) source operand
varSrc :: String -> SrcOperand
varSrc = VarSrc

-- | Creates a register-direct source operand
regSrc :: Register -> SrcOperand
regSrc = RegSrc

-- | Creates a variable (abs-mode) destination operand
varDst :: String -> DstOperand
varDst = VarDst

-- | Creates a register-direct destination operand
regDst :: Register -> DstOperand
regDst = RegDst

-- | Creates ADD instruction: ADD src, Ri
mkAdd :: SrcOperand -> Register -> AsmInstr
mkAdd = ArithInstr Add

-- | Creates SUB instruction: SUB src, Ri
mkSub :: SrcOperand -> Register -> AsmInstr
mkSub = ArithInstr Sub

-- | Creates MUL instruction: MUL src, Ri
mkMul :: SrcOperand -> Register -> AsmInstr
mkMul = ArithInstr Mul

-- | Creates DIV instruction: DIV src, Ri
mkDiv :: SrcOperand -> Register -> AsmInstr
mkDiv = ArithInstr Div

-- | Creates a MOV instruction: MOV src, Ri — copy source operand into register
mkMovToReg :: SrcOperand -> Register -> AsmInstr
mkMovToReg = MovToReg

-- | Creates a MOV instruction: MOV Ri, dst — copy register value to destination
mkMovFromReg :: Register -> DstOperand -> AsmInstr
mkMovFromReg = MovFromReg

-- | The empty program (no instructions yet)
emptyProgram :: AsmProgram
emptyProgram = AsmProgram []

-- | Append one instruction to the end of a program
appendInstr :: AsmProgram -> AsmInstr -> AsmProgram
appendInstr (AsmProgram instrs) instr = AsmProgram (instrs ++ [instr])

-- | Build a program from a list of instructions
mkProgram :: [AsmInstr] -> AsmProgram
mkProgram = AsmProgram

----------
-- Show --
----------

instance Show Register where
    show :: Register -> String
    show (Register n) = "R" ++ show n

instance Show SrcOperand where
    show :: SrcOperand -> String
    show (ImmSrc n) = "#" ++ show n
    show (VarSrc v) = v
    show (RegSrc r) = show r

instance Show DstOperand where
    show :: DstOperand -> String
    show (VarDst v) = v
    show (RegDst r) = show r

instance Show AluOp where
    show :: AluOp -> String
    show Add = "ADD"
    show Sub = "SUB"
    show Mul = "MUL"
    show Div = "DIV"

instance Show AsmInstr where
    show :: AsmInstr -> String
    show (ArithInstr op src reg)    = show op ++ " " ++ show src ++ "," ++ show reg
    show (MovFromReg reg dst)       = "MOV " ++ show reg ++ "," ++ show dst
    show (MovToReg src reg)         = "MOV " ++ show src ++ "," ++ show reg

instance Show AsmProgram where
    show :: AsmProgram -> String
    show (AsmProgram instrs) = foldr (\x acc -> x ++ "\n" ++ acc) "" (map show instrs)
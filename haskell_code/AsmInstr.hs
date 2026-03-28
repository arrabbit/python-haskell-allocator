module AsmInstr
    (
        Register
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
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

------------------
-- Constructors --
------------------

mkRegister :: Int -> Register
mkRegister n
    | n >= 0    = Register n 
    | otherwise = error $ "mkRegister: negative register index" ++ show n

-- Immediate source operand: #x
immSrc :: Int -> SrcOperand
immSrc = ImmSrc

-- Variable (abs-mode) source operand
varSrc :: String -> SrcOperand
varSrc = VarSrc

-- Register-direct source operand
regSrc :: Register -> SrcOperand
regSrc = RegSrc

-- Variable (abs-mode) destination operand
varDst :: String -> DstOperand
varDst = VarDst

-- Register-direct destination operand
regDst :: Register -> DstOperand
regDst = RegDst

-- ADD src,Ri
mkAdd :: SrcOperand -> Register -> AsmInstr
mkAdd = ArithInstr Add

-- SUB src,Ri
mkSub :: SrcOperand -> Register -> AsmInstr
mkSub = ArithInstr Sub

-- MUL src,Ri
mkMul :: SrcOperand -> Register -> AsmInstr
mkMul = ArithInstr Mul

-- DIV src,Ri
mkDiv :: SrcOperand -> Register -> AsmInstr
mkDiv = ArithInstr Div

-- MOV src,Ri — copy a source operand into a register
mkMovToReg :: SrcOperand -> Register -> AsmInstr
mkMovToReg = MovToReg

-- MOV Ri,dst — copy a register value to a destination
mkMovFromReg :: Register -> DstOperand -> AsmInstr
mkMovFromReg = MovFromReg

-- The empty program (no instructions yet)
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

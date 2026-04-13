-- |
-- Summary: Code generation module. Translates a three-address instruction
--   sequence into a target assembly program, given a register colouring
--   produced by the allocator.
--
-- Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
-- Date: April 9, 2026

module Codegen
    ( generateCode
    ) where

import Data.Maybe (fromJust)

import ThreeAddr  (Operand(..), Op(..), Instr, InstrSeq,
                   getDest, getSrc1, getOp, getSrc2, instrType,
                   getInstrs, getLiveOut)
import AsmInstr   (Register, SrcOperand, AsmInstr, AsmProgram,
                   mkRegister, immSrc, varSrc, regSrc, varDst,
                   mkAdd, mkSub, mkMul, mkDiv,
                   mkMovToReg, mkMovFromReg, mkProgram)
import Allocator  (ColourSol)


-- ---------------------------------------------------------------------------
-- Operand conversion
-- ---------------------------------------------------------------------------

-- | Build an assembly source operand from a three-address operand.
--   Decides whether the value lives in a register, memory, or is immediate.
--   * Literals become immediate values (#n).
--   * Variables in the colour solution become register-direct operands.
--   * Variables NOT in the colour solution live in memory (absolute mode).
buildSrcOperand :: Operand -> ColourSol -> SrcOperand
buildSrcOperand (Lit n)    _   = immSrc n
buildSrcOperand (Var name) sol = case lookup name sol of
    Just reg -> regSrc (mkRegister reg)
    Nothing  -> varSrc name


-- ---------------------------------------------------------------------------
-- Operator mapping
-- ---------------------------------------------------------------------------

-- | Translate a three-address operator to its corresponding assembly
--   instruction constructor. Each constructor has the form: SrcOperand -> Register -> AsmInstr
translateToAsmOp :: Op -> SrcOperand -> Register -> AsmInstr
translateToAsmOp Add = mkAdd
translateToAsmOp Sub = mkSub
translateToAsmOp Mul = mkMul
translateToAsmOp Div = mkDiv


-- Single-instruction translation

-- | Translate one three-address instruction to a list of assembly instructions.
--   Binary operations produce two instructions (MOV then OP);
--   unary negation produces two (MOV #0 then SUB); copies produce one (MOV).
--
--   The destination variable is always looked up in the colour solution
--   because it must have been assigned a register by the allocator.
translateToAsm :: Instr -> ColourSol -> [AsmInstr]
translateToAsm instr sol =
    case lookup (getDest instr) sol of
        Nothing      -> []   
        Just destIdx ->
            let destReg = mkRegister destIdx
                src1    = buildSrcOperand (getSrc1 instr) sol
            in case instrType instr of
                "binary" ->
                    -- a = b op c  =>  MOV b, Ra  /  OP c, Ra
                    let src2 = buildSrcOperand (fromJust (getSrc2 instr)) sol
                        op   = fromJust (getOp instr)
                    in [ mkMovToReg src1 destReg
                       , translateToAsmOp op src2 destReg ]
                "unary"  ->
                    -- a = -b  =>  MOV #0, Ra  /  SUB b, Ra
                    [ mkMovToReg (immSrc 0) destReg
                    , mkSub src1 destReg ]
                _        ->
                    -- a = b   =>  MOV b, Ra
                    [ mkMovToReg src1 destReg ]

-- Live-on-exit stores

-- | Build store-back instructions for variables that are live on exit.
--   Each such variable's register value must be written back to memory so
--   the value is available to whatever code follows this block.
--
--   Variables not in the colour solution are skipped (they were never loaded
--   into a register, so there is nothing to store back).
buildStoreInstructions :: [String] -> ColourSol -> [AsmInstr]
buildStoreInstructions liveVars sol =
    [ mkMovFromReg (mkRegister reg) (varDst name)
    | name        <- liveVars
    , Just reg    <- [lookup name sol]
    ]

-- | Generate an assembly program from a three-address instruction sequence
--   and a register colouring.
--
--   Emit assembly for every three-address instruction.
--   Append store-back instructions for variables live on exit.
generateCode :: InstrSeq -> ColourSol -> AsmProgram
generateCode instrSeq sol =
    let body   = concatMap (`translateToAsm` sol) (getInstrs instrSeq)
        stores = buildStoreInstructions (getLiveOut instrSeq) sol
    in mkProgram (body ++ stores)

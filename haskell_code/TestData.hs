-- |
-- Summary: 
--
-- Authors: Anna Running Rabbit, Jordan Senko, and Joseph Mills
-- Date: March 31, 2026

module TestData where

import AsmInstr

exampleProgram :: AsmProgram
exampleProgram = mkProgram
    [ mkMovToReg   (varSrc "a")        r0           -- MOV a,R0
    , mkAdd        (immSrc 1)          r0           -- ADD #1,R0
    , mkMovToReg   (regSrc r0)         r1           -- MOV R0,R1
    , mkMul        (immSrc 4)          r1           -- MUL #4,R1
    , mkAdd        (immSrc 1)          r1           -- ADD #1,R1  (t2 = t1+1, reusing R1 for t2)
    , mkMul        (immSrc 3)          r0           -- MUL #3,R0  (t3 = a*3, a now dead so reuse R0)
    , mkSub        (regSrc r0)         r1           -- SUB R0,R1
    , mkDiv        (immSrc 2)          r1           -- DIV #2,R1
    , mkAdd        (varSrc "c")        r1           -- ADD c,R1
    , mkMovFromReg r1                  (varDst "d") -- MOV R1,d
    ]
  where
    r0 = mkRegister 0
    r1 = mkRegister 1
# python-haskell-allocator
A dual implementation (Python &amp; Haskell) of a simple compiler register allocator. Uses graph coloring to map variables to limited registers for code generation.

## Virtual Environment Setup
Windows Implementation
1. Create venv with:
```powershell
python -m venv .venv
```
2. Activate venv with:
```powershell
.venv/Scripts/Activate.ps1
```
Macbook Implementation
1. Create venv with:
```python3 -m venv venv
```
2. Activate venv with:
``` source venv/bin/activate
```
This is a test.
## Virtual Environment Deactivation
```powershell
.venv/Scripts/deactivate.bat
```

## Haskell Solution Build Instructions


### Run Any Module
In order to run main you must enter the args and the test file path
To Run main:
    ghci Main.hs
    :set args "<numargs>" "<filename.txt>"

Example:
ghci Main.hs
ghci> :set args "4" "plain.txt"
ghci> main
To run any module, while in <u>haskell_code</u> directory, load with the
command:
    ghci <moduleName>.hs

### Test Module Instructions
To run `TestData.hs`, while in <u>haskell_code</u> directory, load with the command:
    ghci TestMods/TestData.hs
 To view three-address instruction sequences:
    ghci> putStr (showInstrSeq testSpecExample)
    ghci> putStr (showInstrSeq testBinary)
    ghci> putStr (showInstrSeq testUnary)
    ghci> putStr (showInstrSeq testEmpty)
    ghci> putStr (showInstrSeq testEmptyLive)
    ghci> putStr (showInstrSeq testLiveOnEntry)
    ghci> putStr (showInstrSeq testHighInterfere)
    ghci> putStr (showInstrSeq testBacktrack)
 To view the expected assembly output:
    ghci> putStr (show exampleProgram)
 To query individual test data:
    ghci> length (getInstrs testSpecExample)
    ghci> getLiveOut testSpecExample
    ghci> getDest (head (getInstrs testSpecExample))
 To check instruction counts:
    ghci> length (getInstrs testBinary)
    ghci> length (getInstrs testEmpty)

To run any other test module, while in <u>haskell_code</u> directory, load with
the command:
    ghci TestMod/<moduleName>.hs
    ghci> runTests


## Imperative Solution Build Instructions
### main.py
To run `main.py`, while in <u>py_code</u> directory, run command:
    python main.py `num_registers` test_drivers/test_inputs/`file_name`


##### Args:
- `num_registers`:
    The number of registers for the "compiler" to have access to
    Ex. '3'
- `file_name`:
    The name of the file you want to take as input into the compiler, including the file extension
    Ex. 'test.txt'

### Test Module Instructions
To run `test_all.py`, while in <u>py_code</u> directory, run with the command:
    python .\test_drivers\test_all.py 

### Tool Files:
To run `parser_module.py`, while in <u>py_code</u> directory, run command:
    python parser_module.py
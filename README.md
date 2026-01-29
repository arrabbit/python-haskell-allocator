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

## Build Instructions

### main.py
To run `main.py`, wile in <u>py_code</u> directory, run command:
    python main.py `num_registers` `file_name`


##### Args:
- `num_registers`:
    The number of registers for the "compiler" to have access to
- `file_name`:
    The name of the file you want to take as input into the compiler, including the file extension

### Tool Files:
To run `parser_module.py`, while in <u>py_code</u> directory, run command:
    python parser_module.py
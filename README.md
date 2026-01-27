# python-haskell-allocator
A dual implementation (Python &amp; Haskell) of a simple compiler register allocator. Uses graph coloring to map variables to limited registers for code generation.

### Virtual Environment Setup
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
### Virtual Environment Deactivation
```powershell
.venv/Scripts/deactivate.bat
```

### Build Instructions
To run main.py, in root directory run command:
    python py_code\main.py <register #> py_code\<input file name>

To run parser_module.py, in root directory run command:
    python py_code\parser_module.py
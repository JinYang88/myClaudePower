# CLI Calculator Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a command-line calculator that performs basic arithmetic operations via `calc <op> <num1> <num2>`.

**Architecture:** Pure functions in `operations.py` handle math logic; `cli.py` uses argparse subcommands to parse input and call operations; errors produce clear messages with non-zero exit codes.

**Tech Stack:** Python 3, argparse (stdlib), pytest

---

## Task 1: Project Setup

**Files:**
- Create: `pyproject.toml`
- Create: `calc/__init__.py`

**Step 1: Create pyproject.toml**

```toml
[build-system]
requires = ["setuptools>=61.0"]
build-backend = "setuptools.build_meta"

[project]
name = "calc"
version = "0.1.0"
description = "A simple CLI calculator"
requires-python = ">=3.8"

[project.scripts]
calc = "calc.cli:main"

[tool.pytest.ini_options]
testpaths = ["tests"]
```

**Step 2: Create calc package**

```bash
mkdir -p calc tests
touch calc/__init__.py
```

**Step 3: Verify setup**

Run: `python -c "import calc; print('OK')"`
Expected: `OK`

**Step 4: Commit**

```bash
git init
git add pyproject.toml calc/__init__.py
git commit -m "chore: initial project setup"
```

---

## Task 2: Operations Module - add function

**Files:**
- Create: `tests/test_operations.py`
- Create: `calc/operations.py`

**Step 1: Write the failing test**

```python
# tests/test_operations.py
from calc.operations import add

def test_add_positive_numbers():
    assert add(1, 2) == 3

def test_add_negative_numbers():
    assert add(-1, -2) == -3

def test_add_decimals():
    assert add(1.5, 2.5) == 4.0
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/test_operations.py -v`
Expected: FAIL with "ModuleNotFoundError" or "ImportError"

**Step 3: Write minimal implementation**

```python
# calc/operations.py
def add(a: float, b: float) -> float:
    return a + b
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/test_operations.py -v`
Expected: 3 passed

**Step 5: Commit**

```bash
git add calc/operations.py tests/test_operations.py
git commit -m "feat: add operation with tests"
```

---

## Task 3: Operations Module - subtract function

**Files:**
- Modify: `tests/test_operations.py`
- Modify: `calc/operations.py`

**Step 1: Write the failing test**

Append to `tests/test_operations.py`:

```python
from calc.operations import add, subtract

def test_subtract_positive_numbers():
    assert subtract(10, 3) == 7

def test_subtract_negative_result():
    assert subtract(3, 10) == -7

def test_subtract_decimals():
    assert subtract(5.5, 2.5) == 3.0
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/test_operations.py::test_subtract_positive_numbers -v`
Expected: FAIL with "ImportError: cannot import name 'subtract'"

**Step 3: Write minimal implementation**

Append to `calc/operations.py`:

```python
def subtract(a: float, b: float) -> float:
    return a - b
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/test_operations.py -v`
Expected: 6 passed

**Step 5: Commit**

```bash
git add calc/operations.py tests/test_operations.py
git commit -m "feat: subtract operation with tests"
```

---

## Task 4: Operations Module - multiply function

**Files:**
- Modify: `tests/test_operations.py`
- Modify: `calc/operations.py`

**Step 1: Write the failing test**

Append to `tests/test_operations.py`:

```python
from calc.operations import add, subtract, multiply

def test_multiply_positive_numbers():
    assert multiply(4, 5) == 20

def test_multiply_by_zero():
    assert multiply(100, 0) == 0

def test_multiply_decimals():
    assert multiply(2.5, 4) == 10.0
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/test_operations.py::test_multiply_positive_numbers -v`
Expected: FAIL with "ImportError: cannot import name 'multiply'"

**Step 3: Write minimal implementation**

Append to `calc/operations.py`:

```python
def multiply(a: float, b: float) -> float:
    return a * b
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/test_operations.py -v`
Expected: 9 passed

**Step 5: Commit**

```bash
git add calc/operations.py tests/test_operations.py
git commit -m "feat: multiply operation with tests"
```

---

## Task 5: Operations Module - divide function

**Files:**
- Modify: `tests/test_operations.py`
- Modify: `calc/operations.py`

**Step 1: Write the failing test**

Append to `tests/test_operations.py`:

```python
import pytest
from calc.operations import add, subtract, multiply, divide

def test_divide_positive_numbers():
    assert divide(10, 2) == 5.0

def test_divide_decimals():
    assert divide(7.5, 2.5) == 3.0

def test_divide_by_zero_raises():
    with pytest.raises(ValueError, match="Division by zero"):
        divide(10, 0)
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/test_operations.py::test_divide_positive_numbers -v`
Expected: FAIL with "ImportError: cannot import name 'divide'"

**Step 3: Write minimal implementation**

Append to `calc/operations.py`:

```python
def divide(a: float, b: float) -> float:
    if b == 0:
        raise ValueError("Division by zero")
    return a / b
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/test_operations.py -v`
Expected: 12 passed

**Step 5: Commit**

```bash
git add calc/operations.py tests/test_operations.py
git commit -m "feat: divide operation with zero check"
```

---

## Task 6: CLI Module - basic structure

**Files:**
- Create: `tests/test_cli.py`
- Create: `calc/cli.py`

**Step 1: Write the failing test**

```python
# tests/test_cli.py
import subprocess
import sys

def run_calc(*args):
    result = subprocess.run(
        [sys.executable, "-m", "calc.cli"] + list(args),
        capture_output=True,
        text=True
    )
    return result

def test_add_command():
    result = run_calc("add", "1", "2")
    assert result.returncode == 0
    assert result.stdout.strip() == "3.0"

def test_sub_command():
    result = run_calc("sub", "10", "3")
    assert result.returncode == 0
    assert result.stdout.strip() == "7.0"
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/test_cli.py::test_add_command -v`
Expected: FAIL with "No module named calc.cli"

**Step 3: Write minimal implementation**

```python
# calc/cli.py
import argparse
import sys
from calc.operations import add, subtract, multiply, divide

def main():
    parser = argparse.ArgumentParser(prog="calc", description="CLI Calculator")
    subparsers = parser.add_subparsers(dest="operation", required=True)

    # Add command
    add_parser = subparsers.add_parser("add", help="Add two numbers")
    add_parser.add_argument("a", type=float)
    add_parser.add_argument("b", type=float)

    # Sub command
    sub_parser = subparsers.add_parser("sub", help="Subtract two numbers")
    sub_parser.add_argument("a", type=float)
    sub_parser.add_argument("b", type=float)

    # Mul command
    mul_parser = subparsers.add_parser("mul", help="Multiply two numbers")
    mul_parser.add_argument("a", type=float)
    mul_parser.add_argument("b", type=float)

    # Div command
    div_parser = subparsers.add_parser("div", help="Divide two numbers")
    div_parser.add_argument("a", type=float)
    div_parser.add_argument("b", type=float)

    args = parser.parse_args()

    operations = {
        "add": add,
        "sub": subtract,
        "mul": multiply,
        "div": divide,
    }

    try:
        result = operations[args.operation](args.a, args.b)
        print(result)
    except ValueError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/test_cli.py -v`
Expected: 2 passed

**Step 5: Commit**

```bash
git add calc/cli.py tests/test_cli.py
git commit -m "feat: CLI with argparse subcommands"
```

---

## Task 7: CLI Tests - complete coverage

**Files:**
- Modify: `tests/test_cli.py`

**Step 1: Add remaining tests**

Append to `tests/test_cli.py`:

```python
def test_mul_command():
    result = run_calc("mul", "4", "5")
    assert result.returncode == 0
    assert result.stdout.strip() == "20.0"

def test_div_command():
    result = run_calc("div", "10", "2")
    assert result.returncode == 0
    assert result.stdout.strip() == "5.0"

def test_div_by_zero():
    result = run_calc("div", "10", "0")
    assert result.returncode == 1
    assert "Division by zero" in result.stderr

def test_invalid_number():
    result = run_calc("add", "abc", "2")
    assert result.returncode != 0

def test_help():
    result = run_calc("--help")
    assert result.returncode == 0
    assert "CLI Calculator" in result.stdout
```

**Step 2: Run all tests**

Run: `pytest tests/ -v`
Expected: All passed

**Step 3: Check coverage**

Run: `pip install pytest-cov && pytest --cov=calc --cov-report=term-missing tests/`
Expected: Coverage >= 90%

**Step 4: Commit**

```bash
git add tests/test_cli.py
git commit -m "test: complete CLI test coverage"
```

---

## Task 8: Final Verification

**Step 1: Install package locally**

```bash
pip install -e .
```

**Step 2: Test installed command**

```bash
calc add 1 2
calc sub 10 3
calc mul 4 5
calc div 10 2
calc div 10 0
calc --help
```

Expected outputs:
- `3.0`
- `7.0`
- `20.0`
- `5.0`
- `Error: Division by zero` (exit 1)
- Help message

**Step 3: Final commit**

```bash
git add -A
git commit -m "chore: complete CLI calculator implementation"
```

---

## Summary

| Task | Description | Tests |
|------|-------------|-------|
| 1 | Project setup | - |
| 2 | add() | 3 |
| 3 | subtract() | 3 |
| 4 | multiply() | 3 |
| 5 | divide() | 3 |
| 6 | CLI basic | 2 |
| 7 | CLI complete | 5 |
| 8 | Final verify | - |

**Total: 8 tasks, 19 tests, ~90%+ coverage**

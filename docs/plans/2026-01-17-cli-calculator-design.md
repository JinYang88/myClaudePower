# CLI Calculator Design

## Overview

A simple command-line calculator supporting basic arithmetic operations (add, subtract, multiply, divide).

## Requirements

- **Language**: Python 3
- **Input**: Command-line arguments (`calc <operation> <num1> <num2>`)
- **Operations**: add, sub, mul, div (binary operations only)
- **Error Handling**: Clear error messages, non-zero exit codes

## Project Structure

```
myClaudePower/
├── calc/
│   ├── __init__.py
│   ├── cli.py          # argparse entry point
│   └── operations.py   # core arithmetic logic
├── tests/
│   ├── test_cli.py
│   └── test_operations.py
├── pyproject.toml      # project config + dependencies
└── README.md
```

## Usage

```bash
calc add 1 2        # Output: 3
calc sub 10 3       # Output: 7
calc mul 4 5        # Output: 20
calc div 10 2       # Output: 5.0
calc div 10 0       # Error: Division by zero
calc --help         # Show help
```

## Core Module: operations.py

```python
def add(a: float, b: float) -> float:
    return a + b

def subtract(a: float, b: float) -> float:
    return a - b

def multiply(a: float, b: float) -> float:
    return a * b

def divide(a: float, b: float) -> float:
    if b == 0:
        raise ValueError("Division by zero")
    return a / b
```

## Error Handling

| Scenario | Behavior | Exit Code |
|----------|----------|-----------|
| Normal calculation | Output result | 0 |
| Division by zero | `Error: Division by zero` | 1 |
| Invalid number | `Error: Invalid number: xxx` | 1 |
| Unknown operation | argparse auto-handles | 2 |

## Test Coverage Requirements

- All four operations with normal inputs
- Division by zero error
- Negative and decimal number inputs
- Invalid input rejection
- CLI argument parsing

## Technical Decisions

- **argparse subcommands**: Zero dependencies, auto-generated help, standard Python pattern
- **Separate operations module**: Pure functions, easy to test in isolation
- **Float arithmetic**: Support decimal numbers by default
